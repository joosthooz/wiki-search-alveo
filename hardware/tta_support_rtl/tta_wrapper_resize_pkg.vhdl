library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package tta_wrapper_resize_pkg is
component tta_wrapper_resize is
  port (
    clk, reset  : in std_logic;
    in_valid    : in  std_logic;
    in_ready    : out std_logic;
    in_data     : in  std_logic_vector(63 downto 0);
    in_cnt      : in  std_logic_vector(2 downto 0);
    in_last     : in  std_logic;

    out_valid   : out std_logic;
    out_ready   : in  std_logic;
    out_dvalid  : out std_logic;
    out_data    : out std_logic_vector(63 downto 0);
    out_cnt     : out std_logic_vector(3 downto 0);
    out_last    : out std_logic
  );
end entity tta_wrapper_resize;
end package;
