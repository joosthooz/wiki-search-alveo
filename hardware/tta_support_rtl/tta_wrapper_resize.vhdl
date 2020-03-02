library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tta_wrapper_resize is
  port (
    clk, reset  : in std_logic;
    in_valid    : in  std_logic;
    in_ready    : out std_logic;
    in_data     : in  std_logic_vector(255 downto 0);
    in_cnt      : in  std_logic_vector(4 downto 0);
    in_last     : in  std_logic;

    out_valid   : out std_logic;
    out_ready   : in  std_logic;
    out_dvalid  : out std_logic;
    out_data    : out std_logic_vector(255 downto 0);
    out_cnt     : out std_logic_vector(4 downto 0);
    out_last    : out std_logic
  );
end entity tta_wrapper_resize;

architecture rtl of tta_wrapper_resize is
    signal narrow_in_valid, narrow_in_ready, narrow_in_last,
           narrow_out_valid, narrow_out_ready, narrow_out_dvalid, narrow_out_last : std_logic;
    signal narrow_in_cnt, narrow_out_cnt : std_logic_vector(0 downto 0);
    signal narrow_in_data, narrow_out_data : std_logic_vector(8-1 downto 0);
begin


  down_gearbox : entity work.StreamGearbox
  generic map (
    ELEMENT_WIDTH => 8,
    IN_COUNT_MAX => 32,
    IN_COUNT_WIDTH => 5,

    OUT_COUNT_MAX  => 1,
    OUT_COUNT_WIDTH => 1
  ) port map(
    clk => clk, reset => reset,
    
    in_valid => in_valid,
    in_ready => in_ready, 
    in_data  => in_data,
    in_count => in_cnt,
    in_last  => in_last,

    -- Output stream.
    out_valid => narrow_in_valid, 
    out_ready => narrow_in_ready,
    out_data  => narrow_in_data,
    out_count => narrow_in_cnt,
    out_last => narrow_in_last
   );

  up_reshaper : entity work.StreamReshaper
  generic map (
    ELEMENT_WIDTH => 8,
    IN_COUNT_MAX => 1,
    IN_COUNT_WIDTH => 1,

    OUT_COUNT_MAX  => 32,
    OUT_COUNT_WIDTH => 5
  ) port map(
    clk => clk, reset => reset,
    
    din_valid => narrow_out_valid,
    din_ready => narrow_out_ready,
    din_dvalid => narrow_out_dvalid,
    din_data  => narrow_out_data,
    din_count => narrow_out_cnt,
    din_last  => narrow_out_last,

    error_strobe => open,
    cin_valid => open,
    cin_ready => open,
    cin_dvalid => open,
    cin_count => open,
    cin_last => open,
    cin_ctrl => open,

    -- Output stream.
    out_valid => out_valid,
    out_ready => out_ready, 
    out_dvalid => out_dvalid,
    out_data  => out_data,
    out_count => out_cnt,
    out_last => out_last,
    out_ctrl => open
   );

   tta_core: entity work.tta_wrapper
   port map (
     clk => clk, reset => reset,
     in_valid => narrow_in_valid,
     in_ready => narrow_in_ready,
     in_data => narrow_in_data,
     in_cnt => narrow_in_cnt,
     in_last => narrow_in_last,
     
     out_valid => narrow_out_valid,
     out_ready => narrow_out_ready,
     out_dvalid => narrow_out_dvalid,
     out_data => narrow_out_data,
     out_cnt => narrow_out_cnt,
     out_last => narrow_out_last
   );
end architecture rtl;
