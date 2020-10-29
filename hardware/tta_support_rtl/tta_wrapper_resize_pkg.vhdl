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
end component tta_wrapper_resize;

component tta_multicore_wrapper is
  port (
    clk         : in  std_logic;
    reset       : in  std_logic;

    -- Compressed input stream. 
    -- The input stream must be normalized; that is, all 8 bytes must be valid
    -- for all but the last transfer, and the last transfer must contain at
    -- least one byte. The number of valid bytes is indicated by cnt; 8 valid
    -- bytes is represented as 0 (implicit MSB). The LSB of the first transfer
    -- corresponds to the first byte in the chunk. This is compatible with the
    -- stream library components in vhlib.
    in_valid    : in  std_logic;
    in_ready    : out std_logic;
    in_data     : in  std_logic_vector(63 downto 0);
    in_cnt      : in  std_logic_vector(2 downto 0);
    in_last     : in  std_logic;

    -- Decompressed output stream. This stream is normalized. The dvalid signal
    -- is used for the special case of a zero-length packet; a single transfer
    -- with last high, dvalid low, cnt zero, and unspecified data is produced
    -- in this case. Otherwise, dvalid is always high.
    out_valid   : out std_logic;
    out_ready   : in  std_logic;
    out_dvalid  : out std_logic;
    out_data    : out std_logic_vector(63 downto 0);
    out_cnt     : out std_logic_vector(3 downto 0);
    out_last    : out std_logic

  );
end component tta_multicore_wrapper;
end package;
