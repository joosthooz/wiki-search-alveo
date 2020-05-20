library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use work.tce_util.all;

entity snappy_tta_input_mux_4 is

  generic (
    BUSW_0 : integer := 32;
    BUSW_1 : integer := 32;
    BUSW_2 : integer := 32;
    BUSW_3 : integer := 32;
    DATAW : integer := 32);
  port (
    databus0 : in std_logic_vector(BUSW_0-1 downto 0);
    databus1 : in std_logic_vector(BUSW_1-1 downto 0);
    databus2 : in std_logic_vector(BUSW_2-1 downto 0);
    databus3 : in std_logic_vector(BUSW_3-1 downto 0);
    data : out std_logic_vector(DATAW-1 downto 0);
    databus_cntrl : in std_logic_vector(1 downto 0));

end snappy_tta_input_mux_4;

architecture rtl of snappy_tta_input_mux_4 is
begin

    -- If width of input bus is greater than width of output,
    -- using the LSB bits.
    -- If width of input bus is smaller than width of output,
    -- using zero extension to generate extra bits.

  sel : process (databus_cntrl, databus0, databus1, databus2, databus3)
  begin
    data <= (others => '0');
    case databus_cntrl is
      when "00" =>
        data <= tce_ext(databus0, data'length);
      when "01" =>
        data <= tce_ext(databus1, data'length);
      when "10" =>
        data <= tce_ext(databus2, data'length);
      when others =>
        data <= tce_ext(databus3, data'length);
    end case;
  end process sel;
end rtl;
