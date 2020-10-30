library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.Stream_pkg.all;

entity tta_wrapper_resize is
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

architecture rtl of tta_wrapper_resize is
    signal narrow_in_valid, narrow_in_ready, narrow_in_last,
           narrow_out_valid, narrow_out_ready, narrow_out_dvalid, narrow_out_last : std_logic;
    signal narrow_in_cnt, narrow_out_cnt : std_logic_vector(1 downto 0);
    signal narrow_in_data, narrow_out_data : std_logic_vector(32-1 downto 0);


    signal ififo2tta_all : std_logic_vector(67 downto 0); -- last, cnt(3), data
    signal tta2ofifo_all : std_logic_vector(69 downto 0); --dvalid, last, cnt(4), data
    signal out_all : std_logic_vector(69 downto 0);
    signal ififo2tta_data : std_logic_vector(63 downto 0);
    signal tta2ofifo_data : std_logic_vector(63 downto 0);
    signal ififo2tta_cnt : std_logic_vector(2 downto 0);
    signal tta2ofifo_cnt : std_logic_vector(3 downto 0);
    signal ififo2tta_ready : std_logic;
    signal tta2ofifo_ready : std_logic;
    signal ififo2tta_valid : std_logic;
    signal tta2ofifo_valid : std_logic;
    signal ififo2tta_last : std_logic;
    signal tta2ofifo_last : std_logic;
    signal tta2ofifo_dvalid : std_logic;
begin

  --FIFOs at the in and output so that multiple instances can operate concurrently
  input_FIFO: StreamFIFO
    generic map (
      DEPTH_LOG2  => 13,
      DATA_WIDTH  => 64 + 3 + 1,
      RAM_CONFIG  => "URAM"
    )
    port map (
      in_clk    => clk,
      in_reset  => reset,
      in_valid  => in_valid,
      in_ready  => in_ready,
      in_data   => in_last & in_cnt & in_data,

      out_clk   => clk,
      out_reset => reset,

      out_valid => ififo2tta_valid,
      out_ready => ififo2tta_ready,
      out_data  => ififo2tta_all
    );
  ififo2tta_last <= ififo2tta_all(67);
  ififo2tta_cnt  <= ififo2tta_all(66 downto 64);
  ififo2tta_data <= ififo2tta_all(63 downto 0);

  output_FIFO: StreamFIFO
    generic map (
      DEPTH_LOG2  => 13,
      DATA_WIDTH  => 64 + 4 + 1 + 1
    )
    port map (
      in_clk    => clk,
      in_reset  => reset,
      in_valid  => tta2ofifo_valid,
      in_ready  => tta2ofifo_ready,
      in_data   => tta2ofifo_all,

      out_clk   => clk,
      out_reset => reset,

      out_valid => out_valid,
      out_ready => out_ready,
      out_data  => out_all
    );
  tta2ofifo_all <= tta2ofifo_dvalid & tta2ofifo_last & tta2ofifo_cnt & tta2ofifo_data;
  out_dvalid <= out_all(69);
  out_last <= out_all(68);
  out_cnt  <= out_all(67 downto 64);
  out_data <= out_all(63 downto 0);

  down_gearbox : entity work.StreamGearbox
  generic map (
    ELEMENT_WIDTH => 8,
    IN_COUNT_MAX => 8,
    IN_COUNT_WIDTH => 3,

    OUT_COUNT_MAX  => 4,
    OUT_COUNT_WIDTH => 2
  ) port map(
    clk => clk, reset => reset,
    
    in_valid => ififo2tta_valid,
    in_ready => ififo2tta_ready, 
    in_data  => ififo2tta_data,
    in_count => ififo2tta_cnt,
    in_last  => ififo2tta_last,

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
    IN_COUNT_MAX => 4,
    IN_COUNT_WIDTH => 2,

    OUT_COUNT_MAX  => 8,
    OUT_COUNT_WIDTH => 4
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
    out_valid => tta2ofifo_valid,
    out_ready => tta2ofifo_ready, 
    out_dvalid => tta2ofifo_dvalid,
    out_data  => tta2ofifo_data,
    out_count => tta2ofifo_cnt,
    out_last => tta2ofifo_last,
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
