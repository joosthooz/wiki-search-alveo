library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity testbench is end entity testbench;

architecture tb of testbench is
    signal stream_data_out, stream_data_in : std_logic_vector(8-1 downto 0);
    signal stream_valid_out, stream_valid_in, stream_ready_out, stream_ready_in : std_logic;
    signal stream_dvalid_out : std_logic;
    signal clk, rstx, reset, done : std_logic;
    signal write_idx : integer;
    type character_file is file of character;
begin
    clk_gen : process
    begin
        rstx <= '0';
	clk <= '0';
	for i in 0 to 3 loop
	  wait for 5 ns;
        end loop;
	rstx <= '1';
	while done /= '1' loop
	    wait for 5 ns;
	    clk <= not clk;
	end loop;
	wait;
    end process;

    stream_in: process(clk, rstx)
        FILE input : character_file; 
        variable data : character;
	variable fstatus : file_open_status;
    begin
        if rstx = '0' then
            stream_valid_in <= '0';
	    file_open(fstatus, input, "../Streamin.in", READ_MODE);
        elsif rising_edge(clk) then
            if not endfile(input) then
                if stream_valid_in = '0' or stream_ready_out = '1' then
                    read(input, data);
                    stream_data_in <= std_logic_vector(to_unsigned(character'pos(data), 8));
                    stream_valid_in <= '1';
                end if;
            else
                stream_valid_in <= '0';
            end if;
        end if;
    end process;

    stream_out : process(clk, rstx)
        FILE output : character_file;
        variable data : character;
	variable fstatus : file_open_status;
    begin
        if rstx = '0' then
	    write_idx <= 0;
            stream_ready_in <= '0';
            file_open(fstatus, output, "../Streamout.out", WRITE_MODE); 
        elsif rising_edge(clk) then
            stream_ready_in <= '1';
            if stream_valid_out = '1' and stream_dvalid_out = '1' then
                data := character'val(to_integer(unsigned(stream_data_out)));
                write(output, data);
		write_idx <= write_idx + 1;
            end if;
        end if;

    end process;

    reset <= not rstx;
    tta : entity work.tta_wrapper
    port map (
       clk => clk, reset => reset,
       
       in_valid => stream_valid_in,
       in_ready => stream_ready_out,
       in_data  => stream_data_in,
       in_cnt   => "1",
       in_last  => '0',

       out_valid => stream_valid_out,
       out_ready => stream_ready_in,
       out_dvalid => stream_dvalid_out,
       out_data => stream_data_out,
       out_cnt => open,
       out_last => done
    );

end architecture;
