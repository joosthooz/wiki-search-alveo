library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fu_streamout is
  port(
    clk           : in std_logic;
    rstx          : in std_logic;
    glock         : in std_logic;
    glockreq      : out std_logic;

    -- External signals
    data_out  : out std_logic_vector(8-1 downto 0);
    valid_out : out std_logic_vector(0 downto 0);
    ready_in  : in std_logic_vector(0 downto 0);

    -- Architectural ports
    t1_data_in    : in  std_logic_vector(8-1 downto 0);
    t1_load_in    : in  std_logic
  );
end fu_streamout;

architecture rtl of fu_streamout is
begin
  data_out <= t1_data_in;
  valid_out(0) <= t1_load_in and not glock;
  glockreq <= t1_load_in and not ready_in(0);
end architecture rtl;
