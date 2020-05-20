library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.snappy_tta_imem_image.all;

entity snappy_rom_array is

  generic (
    addrw  : integer := 10;
    instrw : integer := 100);
  port (
    clock   : in  std_logic;
    en_x    : in std_logic;
    addr    : in  std_logic_vector(addrw-1 downto 0);
    dataout : out std_logic_vector(instrw-1 downto 0));
end snappy_rom_array;

architecture rtl of snappy_rom_array is

  subtype imem_index is integer range 0 to imem_array'length-1;
  constant imem : std_logic_imem_matrix(0 to imem_array'length-1) := imem_array;
  signal en_x_dummy : std_logic;

begin --rtl

  process(clock)
    variable imem_line : imem_index;
  begin -- process
    if (rising_edge(clock)) then
        if en_x = '0' then
	    imem_line := conv_integer(unsigned(addr));
	    dataout <= imem(conv_integer(imem_line));
	end if;
    end if;
  end process;

end rtl;
