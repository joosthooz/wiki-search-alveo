library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.numeric_std.all;

entity sim_stream is
  port (
    clk        : in  std_logic;
    rstx       : in  std_logic;
    
    stream_data_in : in std_logic_vector(8-1 downto 0);
    stream_data_valid_in : in std_logic;
    stream_data_ready_out : out std_logic;
        
    stream_data_out : out std_logic_vector(8-1 downto 0);
    stream_data_valid_out : out std_logic;
    stream_data_ready_in : in std_logic
  );
end sim_stream;

architecture simulation of sim_stream is
    type std_logic_vector_file is file of std_logic_vector(8-1 downto 0);

    signal output_valid : std_logic;
begin

    stream_data_valid_out <= output_valid;
    stream_in: process(clk, rstx)
	variable input : std_logic_vector_file open READ_MODE is "Streamin.in";	
	variable data  : std_logic_vector(8-1 downto 0);
    begin
	if rstx = '0' then
            output_valid <= '0';        
        elsif rising_edge(clk) then
	    if not endfile(input) then
		if output_valid = '0' or stream_data_ready_out = '1' then
		    read(input, data);
	            stream_data_out <= data;
		    output_valid <= '1';
		end if;
	    else
		output_valid <= '0';
	    end if;
        end if;
    end process;

    stream_out : process(clk, rstx)
        variable output : std_logic_vector_file open WRITE_MODE is "Streamout.out";
	variable data : std_logic_vector(8-1 downto 0);
    begin
        if rstx = '0' then
	    stream_data_ready_out <= '0';
	elsif rising_edge(clk) then
            stream_data_ready_out <= '1';
	    if stream_data_valid_in = '1' then
                data := stream_data_in;
		write(output, data);
	    end if;
	end if;

    end process;

end architecture;

