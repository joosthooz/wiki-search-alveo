library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fu_streamin is
  port(
    clk           : in std_logic;
    rstx          : in std_logic;
    glock         : in std_logic;
    glockreq      : out std_logic;

    -- External signals
    data_in   : in std_logic_vector(8-1 downto 0);
    valid_in  : in std_logic_vector(0 downto 0);
    ready_out : out std_logic_vector(0 downto 0);

    -- Architectural ports
    t1_data_in    : in  std_logic_vector(32-1 downto 0);
    t1_load_in    : in  std_logic;
    r1_data_out   : out std_logic_vector(8-1 downto 0)
  );
end fu_streamin;

architecture rtl of fu_streamin is
    signal live_request_r : std_logic;
begin
  operation_logic : process(clk, rstx)
  begin
    if rstx = '0' then
      live_request_r <= '0';
      r1_data_out <= (others => '0');
    elsif rising_edge(clk) then
      if glock = '0' and t1_load_in = '1' then
	if valid_in = "1" then
            r1_data_out <= data_in;
	else
	    live_request_r <= '1';
	end if;
      end if;

      if live_request_r = '1' and valid_in = "1" then
        live_request_r <= '0';
	r1_data_out <= data_in;
      end if;
    end if;
  end process operation_logic;

  ready_out(0) <= (t1_load_in and not glock) or live_request_r;
  glockreq <= live_request_r;
end architecture rtl;
