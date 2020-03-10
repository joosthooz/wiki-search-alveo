library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fu_unistream is
  port(
    clk           : in std_logic;
    rstx          : in std_logic;
    glock         : in std_logic;
    glockreq      : out std_logic;

    -- External signals
    in_valid    : in  std_logic_vector(0 downto 0);
    in_ready    : out std_logic_vector(0 downto 0);
    in_data     : in  std_logic_vector(8-1 downto 0);
    in_cnt      : in  std_logic_vector(0 downto 0);
    in_last     : in  std_logic_vector(0 downto 0);

    out_valid   : out std_logic_vector(0 downto 0);
    out_ready   : in  std_logic_vector(0 downto 0);
    out_dvalid  : out std_logic_vector(0 downto 0);
    out_data    : out std_logic_vector(8-1 downto 0);
    out_cnt     : out std_logic_vector(0 downto 0);
    out_last    : out std_logic_vector(0 downto 0);

    -- Architectural ports
    t1_data_in    : in  std_logic_vector(32-1 downto 0);
    t1_load_in    : in  std_logic;
    t1_opcode_in  : in std_logic_vector(2-1 downto 0);
    o1_data_in    : in std_logic_vector(32-1 downto 0);
    o1_load_in    : in std_logic;

    r1_data_out   : out std_logic_vector(8-1 downto 0)
  );
end fu_unistream;

architecture rtl of fu_unistream is
  constant buffer_size_log2_c : integer := 16;
  constant buffer_size_c : integer := 2**buffer_size_log2_c;

  constant opc_bypass_c : std_logic_vector(1 downto 0) := "00";
  constant opc_copy_c : std_logic_vector(1 downto 0) := "01";
  constant opc_end_c : std_logic_vector(1 downto 0) := "10";
  constant opc_read_c : std_logic_vector(1 downto 0) := "11";

  type transfer_state_t is (Idle, Transfer, Copy, Last);
  signal op_state_r : transfer_state_t;

  signal in_ready_r, out_valid_r, out_dvalid_r, out_last_r : std_logic;
  signal out_data_r : std_logic_vector(8-1 downto 0);
  signal out_cnt_r : std_logic;

  signal read_data, read_data_r     : std_logic_vector(8-1 downto 0);
  signal read_valid, read_valid_r : std_logic;

  type buffer_t is array (buffer_size_c-1 downto 0)
                   of std_logic_vector(8-1 downto 0);
  signal buffer_r : buffer_t;

  signal trans_len_r              : unsigned(32-1 downto 0);
  signal copy_idx_r, copy_first_r, copy_last_r : unsigned(buffer_size_log2_c-1 downto 0);
  signal single_byte_copy_r : std_logic;

  signal o1_data   : std_logic_vector(o1_data_in'range);
  signal o1_data_r : std_logic_vector(buffer_size_log2_c-1 downto 0);

  signal t1_data_r   : std_logic_vector(t1_data_in'range);
  signal t1_load_r   : std_logic;
  signal t1_opcode_r : std_logic_vector(t1_opcode_in'range);
  signal r1_data_r : std_logic_vector(8-1 downto 0);

  signal buffer_write_idx, buffer_read_idx : unsigned(buffer_size_log2_c-1 downto 0);
  signal buffer_read_valid_r : std_logic;
  signal buffer_read_data_r  : std_logic_vector(8-1 downto 0);
begin
  shadow_regs : process(clk, rstx)
  begin
    if rstx = '0' then
      t1_data_r <= (others => '0');
      o1_data_r <= (others => '0');
      t1_load_r <= '0';
    elsif rising_edge(clk) then
      if glock = '0' then
        if o1_load_in = '1' then
          o1_data_r <= o1_data_in(buffer_size_log2_c-1 downto 0);
        end if;
      
        t1_load_r <= t1_load_in;
        if t1_load_in = '1' then
          t1_opcode_r <= t1_opcode_in;
          t1_data_r <= t1_data_in;
        end if;
      end if;
    end if;
  end process shadow_regs;

  in_ready(0)   <= in_ready_r;
  out_valid(0)  <= out_valid_r;
  out_dvalid(0) <= out_dvalid_r;
  out_last(0)   <= out_last_r;
  out_data      <= out_data_r;
  out_cnt(0)    <= out_cnt_r;

  r1_data_out <= r1_data_r;
  
  operation_logic: process(clk, rstx)
     variable first_read_idx : unsigned(copy_idx_r'range);
     variable stream_read : boolean;

     variable buffer_read : boolean;
     variable buffer_idx  : unsigned(copy_idx_r'range);
  begin
    if rstx = '0' then
      op_state_r <= Idle;

      in_ready_r   <= '0';
      out_valid_r  <= '0';
      out_dvalid_r <= '0';
      out_last_r   <= '0';
      out_data_r   <= (others => '0');
      out_cnt_r    <= '0';

      copy_first_r <= (others => '0');
      copy_last_r  <= (others => '0');
      trans_len_r  <= (others => '0');

      read_data_r <= (others => '0');
      read_valid_r <= '0';

      r1_data_r <= (others => '0');

      buffer_write_idx <= (others => '0');

      buffer_read_data_r <= (others => '0');
      buffer_read_idx <= (others => '0');
      single_byte_copy_r <= '0';
    elsif rising_edge(clk) then
      if out_valid_r = '1' and out_ready = "1" then
	out_valid_r <= '0';
      end if;


      buffer_read := false;
      stream_read := false;
      case op_state_r is
	when Idle =>
	  if t1_load_r = '1' and glock = '0' then
            case t1_opcode_r is
	      when opc_bypass_c =>
		trans_len_r <= unsigned(t1_data_r) - 1;
		out_data_r <= read_data;
		out_valid_r <= read_valid;
		out_dvalid_r <= '1';
		out_cnt_r <= '1';
		stream_read := true;
		op_state_r <= Transfer;

	      when opc_copy_c =>
		trans_len_r <= unsigned(t1_data_r);
		first_read_idx := buffer_write_idx - unsigned(o1_data_r);
		
		copy_first_r <= first_read_idx;
	        copy_last_r <= buffer_write_idx;
		buffer_read_idx <= first_read_idx + 1;
		if unsigned(o1_data_r) = 1 then
                    single_byte_copy_r <= '0';
		else
		    single_byte_copy_r <= '1';
		end if;

		buffer_read := true;
		buffer_idx  := first_read_idx;

		out_dvalid_r <= '1';
		out_cnt_r    <= '1';
	        
		op_state_r <= Copy;
	      when opc_end_c =>
		out_valid_r <= '1';
		out_dvalid_r <= '0';
		out_last_r <= '1';
		out_cnt_r <= '0';
		op_state_r <= Last;
	      when others => -- opc_read_c
	        r1_data_r <= read_data;
		stream_read := true;
	    end case;
	  end if;
        when Transfer =>
	  if out_valid_r = '0' then
	    out_data_r <= read_data;
	    out_valid_r <= read_valid;
	    stream_read := true;
	  else
	    if out_ready = "1" then
	      if trans_len_r = 0 then
	        op_state_r <= Idle;
	        out_valid_r <= '0';
	      else
	        out_data_r <= read_data;
		out_valid_r <= read_valid;
		stream_read := true;
		
		trans_len_r <= trans_len_r - 1;
	      end if;
            end if;
          end if;
        when Copy =>
	  if out_ready = "1" then
	    if trans_len_r = 0 then
	      out_valid_r <= '0';
	      op_state_r <= Idle;
            else
	      out_valid_r <= '1';
	      out_data_r <= buffer_read_data_r;

	      if single_byte_copy_r = '1' then
		buffer_read := true;
		buffer_idx := buffer_read_idx;
	        buffer_read_idx <= buffer_read_idx + 1;
	      end if;
	      trans_len_r <= trans_len_r - 1;
	    end if;
	  end if;   
	when Last =>
	  if out_ready = "1" then
	    out_valid_r <= '0';
	    out_last_r <= '0';
	    op_state_r <= Idle;
          end if;
      end case;

      if in_ready_r = '1' and in_valid = "1" then
	read_data_r <= read_data;
	if not stream_read then
	  in_ready_r <= '0';
	  read_valid_r <= '1';
	end if;
      else
	if stream_read or read_valid_r = '0' then
          read_valid_r <= '0';
	  in_ready_r <= '1';
        end if;
      end if;

      if out_valid_r = '1' and out_ready = "1" then
	buffer_r(to_integer(buffer_write_idx)) <= out_data_r;
        buffer_write_idx <= buffer_write_idx + 1;
      end if;

      if buffer_read then
        buffer_read_data_r <= buffer_r(to_integer(buffer_idx));
      end if;
    end if;
  end process operation_logic;

  read_mux: process(read_valid_r, read_data_r, in_valid, in_data)
  begin
    if read_valid_r = '1' then
      read_valid <= '1';
      read_data <= read_data_r;
    else
      read_valid <= in_valid(0);
      read_data <= in_data;
    end if;
  end process read_mux;

  lock_request: process(t1_load_r, op_state_r, out_valid_r, out_ready)
  begin
    glockreq <= '0';
    -- TODO: can read buffer while copy is is progress
    if t1_load_r = '1' and op_state_r /= Idle then
      glockreq <= '1';
    end if;

    if op_state_r = Idle and out_valid_r = '1' and out_ready = "0" then
      glockreq <= '1';
    end if;
  end process lock_request;

end architecture;
