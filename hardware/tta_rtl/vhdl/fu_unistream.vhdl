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
    in_data     : in  std_logic_vector(32-1 downto 0);
    in_cnt      : in  std_logic_vector(1 downto 0);
    in_last     : in  std_logic_vector(0 downto 0);

    out_valid   : out std_logic_vector(0 downto 0);
    out_ready   : in  std_logic_vector(0 downto 0);
    out_dvalid  : out std_logic_vector(0 downto 0);
    out_data    : out std_logic_vector(32-1 downto 0);
    out_cnt     : out std_logic_vector(1 downto 0);
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

  constant zero_padding : std_logic_vector(31 downto 0) := (others => '0');

  type transfer_state_t is (Idle, Transfer, Copy, Last);
  signal op_state_r : transfer_state_t;

  signal in_ready_r, out_valid_r, out_dvalid_r, out_last_r : std_logic;
  signal out_data_r : std_logic_vector(32-1 downto 0);
  signal out_cnt_r : std_logic_vector(1 downto 0);

  signal read_data, read_data_r     : std_logic_vector(32-1 downto 0);
  signal read_valid, read_valid_r : std_logic;
  signal read_count, read_count_r : std_logic_vector(1 downto 0);

  signal next_byte_valid : std_logic;
  signal next_byte : std_logic_vector(7 downto 0);

  type buffer_t is array (buffer_size_c/4-1 downto 0)
                   of std_logic_vector(8-1 downto 0);
  signal buffer_0_r, buffer_1_r, buffer_2_r, buffer_3_r : buffer_t;

  signal trans_len_r              : unsigned(32-1 downto 0);
  signal copy_idx_r, copy_first_r, copy_last_r : unsigned(buffer_size_log2_c-1 downto 0);
  signal first_copy_r : std_logic;

  signal o1_data   : std_logic_vector(o1_data_in'range);
  signal o1_data_r : std_logic_vector(buffer_size_log2_c-1 downto 0);

  signal t1_data_r   : std_logic_vector(t1_data_in'range);
  signal t1_load_r   : std_logic;
  signal t1_opcode_r : std_logic_vector(t1_opcode_in'range);
  signal r1_data_r : std_logic_vector(8-1 downto 0);

  signal buffer_write_idx, buffer_read_idx_r : unsigned(buffer_size_log2_c-1 downto 0);
  signal buffer_read_valid_r : std_logic;
  signal buffer_read_data  : std_logic_vector(32-1 downto 0);

  signal read_buf_r : std_logic_vector(64-1 downto 0);
  signal read_buf_cnt_r : unsigned(4-1 downto 0);

  signal reading_stream : std_logic;
  signal repeat_len_r : unsigned(2 downto 0);


  signal buffer_read : std_logic;
  signal buffer_read_idx  : unsigned(copy_idx_r'range);
  signal buffer_0_read_idx  : unsigned(copy_idx_r'high-2 downto 0);
  signal buffer_1_read_idx  : unsigned(copy_idx_r'high-2 downto 0);
  signal buffer_2_read_idx  : unsigned(copy_idx_r'high-2 downto 0);
  signal buffer_3_read_idx  : unsigned(copy_idx_r'high-2 downto 0);


  signal buffer_0_write_idx  : unsigned(copy_idx_r'high-2 downto 0);
  signal buffer_1_write_idx  : unsigned(copy_idx_r'high-2 downto 0);
  signal buffer_2_write_idx  : unsigned(copy_idx_r'high-2 downto 0);
  signal buffer_3_write_idx  : unsigned(copy_idx_r'high-2 downto 0);

  signal buffer_0_wen  : std_logic;
  signal buffer_1_wen  : std_logic;
  signal buffer_2_wen  : std_logic;
  signal buffer_3_wen  : std_logic;

  signal buffer_0_read_data_r : std_logic_vector(7 downto 0);
  signal buffer_1_read_data_r : std_logic_vector(7 downto 0);
  signal buffer_2_read_data_r : std_logic_vector(7 downto 0);
  signal buffer_3_read_data_r : std_logic_vector(7 downto 0);


  signal buffer_0_write_data : std_logic_vector(7 downto 0);
  signal buffer_1_write_data : std_logic_vector(7 downto 0);
  signal buffer_2_write_data : std_logic_vector(7 downto 0);
  signal buffer_3_write_data : std_logic_vector(7 downto 0);

  signal rotate_r : unsigned(1 downto 0);

  signal ghdl_state_r : integer range 0 to 3;
begin

  ghdl_workaround: process(op_state_r)
  begin
    case op_state_r is
      when Idle => ghdl_state_r <= 0;
      when Transfer => ghdl_state_r <= 1;
      when Copy => ghdl_state_r <= 2;
      when Last => ghdl_state_r <= 3;
    end case;
  end process ghdl_workaround;

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
  out_cnt       <= out_cnt_r;

  r1_data_out <= r1_data_r;

  operation_logic: process(clk, rstx)
     variable first_read_idx : unsigned(copy_idx_r'range);
     variable subbuffer_idx  : unsigned(copy_idx_r'high-2 downto 0);

     variable target : integer;
     variable data : std_logic_vector(7 downto 0);

     variable truncated_len : std_logic_vector(32-1 downto 0);

     variable count : integer;
     variable repeat_data : std_logic_vector(32-1 downto 0);
     variable shift : integer;
     variable fill_bytes : integer;
  begin
    if rstx = '0' then
      op_state_r <= Idle;

      out_valid_r  <= '0';
      out_dvalid_r <= '0';
      out_last_r   <= '0';
      out_data_r   <= (others => '0');
      out_cnt_r    <= "00";
      rotate_r     <= "00";

      copy_first_r <= (others => '0');
      copy_last_r  <= (others => '0');
      trans_len_r  <= (others => '0');

      r1_data_r <= (others => '0');

      buffer_write_idx <= (others => '0');

      buffer_read_idx_r <= (others => '0');

      repeat_len_r <= (others => '0');
    elsif rising_edge(clk) then
      if out_valid_r = '1' and out_ready = "1" then
        out_valid_r <= '0';
      end if;

      reading_stream <= '0';
      case op_state_r is
        when Idle =>
          if t1_load_r = '1' and glock = '0' then
            case t1_opcode_r is
              when opc_bypass_c =>
                if unsigned(t1_data_r) > 0 then
                out_cnt_r <= t1_data_r(1 downto 0);
                truncated_len := "00" & t1_data_r(31 downto 2);
                if to_integer(unsigned(t1_data_r(1 downto 0))) = 0 then
                    trans_len_r <= unsigned(truncated_len) - 1;
                else
                    trans_len_r <= unsigned(truncated_len);
                end if;
                out_data_r <= read_buf_r(31 downto 0);
                out_valid_r <= '1';
                out_dvalid_r <= '1';
                reading_stream <= '1';
                op_state_r <= Transfer;
                end if;

              when opc_copy_c =>
                trans_len_r <= unsigned(t1_data_r);
                first_read_idx := buffer_write_idx - unsigned(o1_data_r);

                if to_integer(unsigned(o1_data_r)) < 8 then
                    repeat_len_r <= unsigned(o1_data_r(2 downto 0));
                else
                    repeat_len_r <= (others => '0');
                end if;
                first_copy_r <= '1';

                copy_first_r <= first_read_idx;
                copy_last_r <= buffer_write_idx - 1;
                buffer_read_idx_r <= first_read_idx + 4;

                out_dvalid_r <= '1';
                op_state_r <= Copy;
              when opc_end_c =>
                out_valid_r <= '1';
                out_dvalid_r <= '0';
                out_last_r <= '1';
                out_cnt_r <= "00";
                op_state_r <= Last;
              when others => -- opc_read_c
                r1_data_r <= next_byte;
                reading_stream <= '1';
            end case;
          end if;
        when Transfer =>
          if out_valid_r = '0' then
            if to_integer(read_buf_cnt_r) >= 4 then
                out_data_r <= read_buf_r(31 downto 0);
                out_cnt_r <= "00";
                out_valid_r <= '1';
                reading_stream <= '1';
                trans_len_r <= trans_len_r - 1;
            end if;
          else
            if out_ready = "1" then
              if trans_len_r = 0 then
                op_state_r <= Idle;
                out_valid_r <= '0';
              elsif to_integer(read_buf_cnt_r) >= 4 then
                out_data_r <= read_buf_r(31 downto 0);
                out_valid_r <= '1';
                reading_stream <= '1';
                out_cnt_r <= "00";

                trans_len_r <= trans_len_r - 1;
              end if;
            end if;
          end if;
        when Copy =>
          if t1_load_r = '1' and glock = '0' and t1_opcode_r = opc_read_c then
            r1_data_r <= next_byte;
            reading_stream <= '1';
          end if;
          if out_ready = "1" then
            if trans_len_r = 0 then
              out_valid_r <= '0';
              op_state_r <= Idle;
            else
              first_copy_r <= '0';

              if first_copy_r = '1' then
                repeat_data := buffer_read_data;
              else
                if repeat_len_r = "011" then
                    repeat_data := out_data_r(8-1 downto 0) &
                                   out_data_r(32-1 downto 8);
                else
                    repeat_data := out_data_r;
                end if;
              end if;
              out_valid_r <= '1';
              case repeat_len_r is
                when "000" =>
                  out_data_r <= buffer_read_data;
                  buffer_read_idx_r <= buffer_read_idx_r + 4;
                when "001" =>
                  out_data_r <= repeat_data(7 downto 0) &
                                repeat_data(7 downto 0) &
                                repeat_data(7 downto 0) &
                                repeat_data(7 downto 0);
                when "010" =>
                  out_data_r <= repeat_data(15 downto 0) &
                                repeat_data(15 downto 0);
                when "011" =>
                  out_data_r <= repeat_data(7 downto 0) &
                                repeat_data(23 downto 0);
                when "100" =>
                  out_data_r <= repeat_data;
                  buffer_read_idx_r <= buffer_read_idx_r + 4;
                when "101" =>
                  if first_copy_r = '1' then
                    out_data_r <= buffer_read_data;
                  else
                    out_data_r <= repeat_data(23 downto 0) & buffer_read_data(7 downto 0);
                  end if;
                  buffer_read_idx_r <= buffer_read_idx_r + 4;
                when "110" =>
                  if first_copy_r = '1' then
                    out_data_r <= buffer_read_data;
                  else
                    out_data_r <= repeat_data(15 downto 0) & buffer_read_data(15 downto 0);
                  end if;
                  buffer_read_idx_r <= buffer_read_idx_r + 4;
                when others => -- 111
                  if first_copy_r = '1' then
                    out_data_r <= buffer_read_data;
                  else
                    out_data_r <= repeat_data(7 downto 0) & buffer_read_data(23 downto 0) ;
                  end if;
                  buffer_read_idx_r <= buffer_read_idx_r + 4;
              end case;

              if trans_len_r >= 4 then
                out_cnt_r <= "00";
                trans_len_r <= trans_len_r - 4;
              else
                out_cnt_r <= std_logic_vector(trans_len_r(1 downto 0));
                trans_len_r <= (others => '0');
              end if;
            end if;
          end if;
        when Last =>
          if out_ready = "1" then
            out_valid_r <= '0';
            out_last_r <= '0';
            op_state_r <= Idle;
          end if;
      end case;

      if out_valid_r = '1' and out_ready = "1" then
        if buffer_0_wen = '1' then
            buffer_0_r(to_integer(buffer_0_write_idx)) <= buffer_0_write_data;
        end if;
        if buffer_1_wen = '1' then
            buffer_1_r(to_integer(buffer_1_write_idx)) <= buffer_1_write_data;
        end if;
        if buffer_2_wen = '1' then
            buffer_2_r(to_integer(buffer_2_write_idx)) <= buffer_2_write_data;
        end if;
        if buffer_3_wen = '1' then
            buffer_3_r(to_integer(buffer_3_write_idx)) <= buffer_3_write_data;
        end if;

        count := to_integer(unsigned(out_cnt_r));
        if count = 0 then
            count := 4;
        end if;
        buffer_write_idx <= buffer_write_idx + count;
      end if;

      if buffer_read = '1' then
        rotate_r <= buffer_read_idx(1 downto 0);

        -- Bypassing not needed with wider rotate
        --if buffer_0_write_idx = buffer_0_read_idx and buffer_0_wen = '1' then
        --  buffer_0_read_data_r <= buffer_0_write_data;
        --else
        --  buffer_0_read_data_r <= buffer_0_r(to_integer(buffer_0_read_idx));
        --end if;

        --if buffer_1_write_idx = buffer_1_read_idx and buffer_1_wen = '1' then
        --  buffer_1_read_data_r <= buffer_1_write_data;
        --else
        --  buffer_1_read_data_r <= buffer_1_r(to_integer(buffer_1_read_idx));
        --end if;

        --if buffer_2_write_idx = buffer_2_read_idx and buffer_2_wen = '1' then
        --  buffer_2_read_data_r <= buffer_2_write_data;
        --else
        --  buffer_2_read_data_r <= buffer_2_r(to_integer(buffer_2_read_idx));
        --end if;

        --if buffer_3_write_idx = buffer_3_read_idx and buffer_3_wen = '1' then
        --  buffer_3_read_data_r <= buffer_3_write_data;
        --else
        --  buffer_3_read_data_r <= buffer_3_r(to_integer(buffer_3_read_idx));
        --end if;

        buffer_0_read_data_r <= buffer_0_r(to_integer(buffer_0_read_idx));
        buffer_1_read_data_r <= buffer_1_r(to_integer(buffer_1_read_idx));
        buffer_2_read_data_r <= buffer_2_r(to_integer(buffer_2_read_idx));
        buffer_3_read_data_r <= buffer_3_r(to_integer(buffer_3_read_idx));
      end if;
    end if;
  end process operation_logic;

  memory_comb: process(op_state_r, t1_load_r, glock, t1_opcode_r,
                       out_ready, trans_len_r, repeat_len_r, out_valid_r,
                       buffer_read_idx, rotate_r, o1_data_r,
                       buffer_read_idx_r,
                       buffer_3_read_data_r,
                       buffer_2_read_data_r,
                       buffer_1_read_data_r,
                       buffer_0_read_data_r,
                       out_cnt_r, buffer_write_idx, out_data_r
                       )
    variable count : integer;
    variable idx : integer;
  begin

    count := to_integer(unsigned(out_cnt_r));
    idx := to_integer(buffer_write_idx(1 downto 0));
    if idx > 0 then
      buffer_0_write_idx <= buffer_write_idx(buffer_write_idx'high downto 2) + 1;
    else
      buffer_0_write_idx <= buffer_write_idx(buffer_write_idx'high downto 2);
    end if;

    if idx > 1 then
      buffer_1_write_idx <= buffer_write_idx(buffer_write_idx'high downto 2) + 1;
    else
      buffer_1_write_idx <= buffer_write_idx(buffer_write_idx'high downto 2);
    end if;

    if idx > 2 then
      buffer_2_write_idx <= buffer_write_idx(buffer_write_idx'high downto 2) + 1;
    else
      buffer_2_write_idx <= buffer_write_idx(buffer_write_idx'high downto 2);
    end if;

    buffer_3_write_idx <= buffer_write_idx(buffer_write_idx'high downto 2);

    buffer_0_wen <= '0';
    buffer_1_wen <= '0';
    buffer_2_wen <= '0';
    buffer_3_wen <= '0';

    if out_valid_r = '1' and out_ready = "1" then
        if out_cnt_r = "00" then
            buffer_0_wen <= '1';
            buffer_1_wen <= '1';
            buffer_2_wen <= '1';
            buffer_3_wen <= '1';
        end if;

        if idx = 0 or count + idx > 4 then
            buffer_0_wen <= '1';
        end if;
        if (idx <= 1 and count + idx > 1) or count + idx > 5 then
            buffer_1_wen <= '1';
        end if;
        if (idx <= 2 and count + idx > 2) or count + idx > 7 then
            buffer_2_wen <= '1';
        end if;
        if count + idx >= 3 then
            buffer_3_wen <= '1';
        end if;
    end if;

    if idx = 0 then
        buffer_0_write_data <= out_data_r(7 downto 0);
    else
        buffer_0_write_data <= out_data_r((4-idx)*8+7 downto (4-idx)*8);
    end if;

    if idx <= 1 then
        buffer_1_write_data <= out_data_r((1-idx)*8+7 downto (1-idx)*8);
    else
        buffer_1_write_data <= out_data_r((5-idx)*8+7 downto (5-idx)*8);
    end if;

    if idx /= 3 then
        buffer_2_write_data <= out_data_r((2-idx)*8+7 downto (2-idx)*8);
    else
        buffer_2_write_data <= out_data_r(3*8+7 downto 3*8);
    end if;

    buffer_3_write_data <= out_data_r((3-idx)*8+7 downto (3-idx)*8);

    if op_state_r = Idle and t1_load_r = '1' and glock = '0'
       and t1_opcode_r = opc_copy_c then
        buffer_read <= '1';
        buffer_read_idx <= buffer_write_idx - unsigned(o1_data_r);
    elsif op_state_r = Copy and out_ready = "1" and trans_len_r /= 0
          and (unsigned(repeat_len_r) = 0 or unsigned(repeat_len_r) > 4) then
        buffer_read <= '1';
        buffer_read_idx <= buffer_read_idx_r;
    else
        buffer_read <= '0';
        buffer_read_idx <= (others => '0');
    end if;

    if to_integer(buffer_read_idx(1 downto 0)) > 0 then
      buffer_0_read_idx <= buffer_read_idx(buffer_read_idx'high downto 2) + 1;
    else
      buffer_0_read_idx <= buffer_read_idx(buffer_read_idx'high downto 2);
    end if;

    if to_integer(buffer_read_idx(1 downto 0)) > 1 then
      buffer_1_read_idx <= buffer_read_idx(buffer_read_idx'high downto 2) + 1;
    else
      buffer_1_read_idx <= buffer_read_idx(buffer_read_idx'high downto 2);
    end if;

    if to_integer(buffer_read_idx(1 downto 0)) > 2 then
      buffer_2_read_idx <= buffer_read_idx(buffer_read_idx'high downto 2) + 1;
    else
      buffer_2_read_idx <= buffer_read_idx(buffer_read_idx'high downto 2);
    end if;

    buffer_3_read_idx <= buffer_read_idx(buffer_read_idx'high downto 2);

    case rotate_r is
      when "00" =>
        buffer_read_data <= buffer_3_read_data_r & buffer_2_read_data_r &
                            buffer_1_read_data_r & buffer_0_read_data_r;
      when "01" =>
        buffer_read_data <= buffer_0_read_data_r & buffer_3_read_data_r &
                            buffer_2_read_data_r & buffer_1_read_data_r;
      when "10" =>
        buffer_read_data <= buffer_1_read_data_r & buffer_0_read_data_r &
                            buffer_3_read_data_r & buffer_2_read_data_r;
      when others =>
        buffer_read_data <= buffer_2_read_data_r & buffer_1_read_data_r &
                            buffer_0_read_data_r & buffer_3_read_data_r;
    end case;
  end process memory_comb;

  next_byte_valid <= '0' when read_buf_cnt_r = 0 else '1';
  next_byte <= read_buf_r(7 downto 0);

  read_mux: process(read_valid_r, read_data_r, read_count_r, in_valid, in_data, in_cnt)
  begin
    if read_valid_r = '1' then
      read_valid <= '1';
      read_data <= read_data_r;
      read_count <= read_count_r;
    else
      read_valid <= in_valid(0);
      read_data <= in_data;
      read_count <= in_cnt;
    end if;
  end process read_mux;

  read_sync : process(clk, rstx)
    variable buffer_read : boolean;
    variable buf_offset  : integer;
    variable read_buf_new : std_logic_vector(read_buf_r'range);
    variable read_buf_padded : std_logic_vector(96-1 downto 0);
    variable bytes : integer;
  begin
    if rstx = '0' then
        read_valid_r <= '0';
        read_buf_cnt_r <= (others => '0');
        read_buf_r    <= (others => '0');
        read_data_r   <= (others => '0');
    elsif rising_edge(clk) then
        buf_offset := to_integer(read_buf_cnt_r);
        read_buf_new := read_buf_r;

        if (op_state_r = Idle or op_state_r = Copy)
           and t1_load_r = '1' and glock = '0'
           and t1_opcode_r = opc_read_c then
            buf_offset := buf_offset - 1;
            read_buf_new := X"00" & read_buf_new(64-1 downto 8);
        elsif op_state_r = Idle and t1_load_r = '1' and glock = '0'
              and t1_opcode_r = opc_bypass_c then
            bytes := to_integer(unsigned(t1_data_r(1 downto 0)));
            if bytes = 0 and unsigned(t1_data_r) > 0 then
              bytes := 4;
            end if;
            buf_offset := buf_offset - bytes;
            read_buf_padded := zero_padding & read_buf_new;
            read_buf_new := read_buf_padded(bytes*8+63 downto bytes*8);
        end if;

        if op_state_r = Transfer and (out_valid_r = '0'
           or (out_ready = "1" and trans_len_r /= 0))
            and to_integer(read_buf_cnt_r) >= 4 then
            buf_offset := buf_offset - 4;
            read_buf_new := zero_padding & read_buf_new(64-1 downto 32);
        end if;

        buffer_read := false;
        if buf_offset < 5 and read_valid = '1' then
            buffer_read := true;

            read_buf_new(buf_offset*8 + 31 downto buf_offset*8)
                := read_data;
            if read_count = "00" then
                buf_offset := buf_offset + 4;
            else
                buf_offset := buf_offset + to_integer(unsigned(read_count));
            end if;
        end if;
        read_buf_cnt_r <= to_unsigned(buf_offset, 4);
        read_buf_r <= read_buf_new;

        if in_ready_r = '1' and in_valid = "1" then
          read_data_r <= read_data;
          read_count_r <= in_cnt;
          if not buffer_read then
            in_ready_r <= '0';
            read_valid_r <= '1';
          end if;
        else
          if buffer_read or read_valid_r = '0' then
            read_valid_r <= '0';
            in_ready_r <= '1';
          end if;
        end if;
    end if;
  end process read_sync;

  lock_request: process(t1_load_r, t1_opcode_r, read_valid_r,
                        op_state_r, out_valid_r, out_ready)
  begin
    glockreq <= '0';
    if t1_load_r = '1' and op_state_r /= Idle and op_state_r /= Copy then
      glockreq <= '1';
    end if;
    if t1_load_r = '1' and op_state_r = Copy and t1_opcode_r /= opc_read_c then
      glockreq <= '1';
    end if;

    if t1_load_r = '1' and t1_opcode_r = opc_read_c and to_integer(read_buf_cnt_r) = 0 then
      glockreq <= '1';
    end if;

    if op_state_r = Idle and out_valid_r = '1' and out_ready = "0" then
      glockreq <= '1';
    end if;
  end process lock_request;

end architecture;
