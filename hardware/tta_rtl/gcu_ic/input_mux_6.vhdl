library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use work.tce_util.all;

entity snappy_tta_input_mux_6 is

  generic (
    BUSW_0 : integer := 32;
    BUSW_1 : integer := 32;
    BUSW_2 : integer := 32;
    BUSW_3 : integer := 32;
    BUSW_4 : integer := 32;
    BUSW_5 : integer := 32;
    DATAW : integer := 32);
  port (
    databus0 : in std_logic_vector(BUSW_0-1 downto 0);
    databus1 : in std_logic_vector(BUSW_1-1 downto 0);
    databus2 : in std_logic_vector(BUSW_2-1 downto 0);
    databus3 : in std_logic_vector(BUSW_3-1 downto 0);
    databus4 : in std_logic_vector(BUSW_4-1 downto 0);
    databus5 : in std_logic_vector(BUSW_5-1 downto 0);
    data : out std_logic_vector(DATAW-1 downto 0);
    databus_cntrl : in std_logic_vector(2 downto 0));

end snappy_tta_input_mux_6;

architecture rtl of snappy_tta_input_mux_6 is
begin

    -- If width of input bus is greater than width of output,
    -- using the LSB bits.
    -- If width of input bus is smaller than width of output,
    -- using zero extension to generate extra bits.

  sel : process (databus_cntrl, databus0, databus1, databus2, databus3, databus4, databus5)
  begin
    data <= (others => '0');
    case databus_cntrl is
      when "000" =>
        data <= tce_ext(databus0, data'length);
      when "001" =>
        data <= tce_ext(databus1, data'length);
      when "010" =>
        data <= tce_ext(databus2, data'length);
      when "011" =>
        data <= tce_ext(databus3, data'length);
      when "100" =>
        data <= tce_ext(databus4, data'length);
      when others =>
        data <= tce_ext(databus5, data'length);
    end case;
  end process sel;
end rtl;
