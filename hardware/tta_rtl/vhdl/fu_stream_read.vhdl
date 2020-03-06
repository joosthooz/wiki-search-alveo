library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fu_stream_read is
  port(
    clk           : in std_logic;
    rstx          : in std_logic;
    glock         : in std_logic;

    -- External signals
    data_in       : in std_logic_vector(8-1 downto 0);
    data_valid_in : in std_logic_vector(0 downto 0);

    -- Architectural ports
    t1_data_in    : in  std_logic_vector(32-1 downto 0);
    t1_load_in    : in  std_logic;
    o1_data_in    : in std_logic_vector(32-1 downto 0);
    o1_load_in    : in std_logic;

    r1_data_out   : out std_logic_vector(8-1 downto 0)
  );
end fu_stream_read;

architecture rtl of fu_stream_read is
  constant buffer_size_log2_c : integer := 16;
  constant buffer_size_c : integer := 2**buffer_size_log2_c;

  type buffer_t is array (buffer_size_c-1 downto 0)
                   of std_logic_vector(8-1 downto 0);
  signal buffer_r : buffer_t;

  signal o1_data, o1_data_r : std_logic_vector(o1_data_in'range);

  signal t1_data_r : std_logic_vector(t1_data_in'range);
  signal t1_load_r : std_logic;

  signal result_r : std_logic_vector(8-1 downto 0);
  signal buffer_write_idx, buffer_read_idx : unsigned(buffer_size_log2_c-1 downto 0);

  signal current_copy_id_r : std_logic_vector(o1_data_in'range);
  signal current_idx_r, current_start_idx_r, current_end_idx_r : unsigned(buffer_size_log2_c-1 downto 0);
begin
   buffer_read_idx <= buffer_write_idx - unsigned(t1_data_r(buffer_read_idx'range));

  shadow_regs : process(clk, rstx)
  begin

    if rstx = '0' then
      t1_data_r <= (others => '0');
      o1_data_r <= (others => '0');
      t1_load_r <= '0';
    elsif rising_edge(clk) then
      if glock = '0' then
        if o1_load_in = '1' then
          o1_data_r <= o1_data_in;
        end if;
      
        t1_load_r <= t1_load_in;
        if t1_load_in = '1' then
          t1_data_r <= t1_data_in;
        end if;
      end if;
    end if;
  end process shadow_regs;

  operation_logic : process(clk, rstx)
  begin
    if rstx = '0' then
      result_r <= (others => '0');
      buffer_write_idx <= (others => '0');

      current_copy_id_r <= (others => '0');
      current_start_idx_r <= (others => '0');
      current_end_idx_r   <= (others => '0');
      current_idx_r    <= (others => '0');
    elsif rising_edge(clk) then
      if glock = '0' and t1_load_r = '1' then
	if current_copy_id_r = o1_data_r then
	  result_r <= buffer_r(to_integer(current_idx_r));
	  if current_idx_r = current_end_idx_r then
            current_idx_r <= current_start_idx_r;
	  else
	    current_idx_r <= current_idx_r + 1;
	  end if;
	else
          result_r <= buffer_r(to_integer(buffer_read_idx));
	  current_start_idx_r <= buffer_read_idx;
	  current_end_idx_r <= buffer_write_idx - 1;
	  if to_integer(unsigned(t1_data_r)) = 1 then
            current_idx_r <= buffer_read_idx;
          else
	    current_idx_r <= buffer_read_idx + 1;
	  end if;
	  current_copy_id_r <= o1_data_r;
	end if;
	
      end if;

      if data_valid_in(0) = '1' then
        buffer_r(to_integer(buffer_write_idx)) <= data_in;
	buffer_write_idx <= buffer_write_idx + 1;
      end if;
    end if;
  end process operation_logic;

  r1_data_out <= result_r;
end architecture rtl;
