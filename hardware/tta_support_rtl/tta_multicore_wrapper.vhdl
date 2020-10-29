library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tta_wrapper_resize_pkg.all;

-- Streaming multicoretoplevel for decompression TTA ASIP.
-- Depends on the TTA wrapper to include buffers before and after 
-- the core, so we can redirect the in/output streams to multiple cores.
-- The cores that are not selected will continue to decompress from their
-- input buffers into their output buffers in the meantime.
entity tta_multicore_wrapper is
  generic (

    -- Number of decompression cores to instantiate.
    COUNT       : positive := 4
  );
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
end tta_multicore_wrapper;

architecture behavior of tta_multicore_wrapper is

  function imax(a: integer; b: integer) return integer is
  begin
    if a > b then
      return a;
    else
      return b;
    end if;
  end function;

  function log2ceil(i: natural) return natural is
    variable x, y : natural;
  begin
    x := i;
    y := 0;
    while x > 1 loop
      x := (x + 1) / 2;
      y := y + 1;
    end loop;
    return y;
  end function;

  constant COUNT_BITS : natural := imax(1, log2ceil(COUNT));

  -- I/O streams for the buffered units
  type instream is record
    valid     : std_logic;
    dvalid    : std_logic;
    data      : std_logic_vector(63 downto 0);
    cnt       : std_logic_vector(2 downto 0);
    last      : std_logic;
  end record;
  type outstream is record
    valid     : std_logic;
    dvalid    : std_logic;
    data      : std_logic_vector(63 downto 0);
    cnt       : std_logic_vector(3 downto 0);
    last      : std_logic;
  end record;


  type instream_array is array (natural range <>) of instream;
  type outstream_array is array (natural range <>) of outstream;

  -- Generic array of bits. This has the same definition as an
  -- std_logic_vector for as far as VHDL is concerned, but semantically, we use
  -- this to describe individual bits (with ascending ranges), and
  -- std_logic_vector for scalar values which require multiple bits (descending
  -- ranges).
  type std_logic_array is array (natural range <>) of std_logic;


  -- Streams for the individual units.
  signal u_in         : instream_array(0 to COUNT-1);
  signal u_in_ready   : std_logic_array(0 to COUNT-1);
  signal u_out        : outstream_array(0 to COUNT-1);
  signal u_out_ready  : std_logic_array(0 to COUNT-1);

  -- Internal copies of the handshake outputs.
  signal in_ready_i   : std_logic;
  signal out_valid_i  : std_logic;
  signal out_last_i   : std_logic;

  -- Select signals.
  signal in_sel       : unsigned(COUNT_BITS-1 downto 0) := (others => '0');
  signal out_sel      : unsigned(COUNT_BITS-1 downto 0) := (others => '0');

begin

  -- Instantiate the cores.
  core_gen: for idx in 0 to COUNT - 1 generate
  begin
    core_inst: tta_wrapper_resize

      port map (
        clk         => clk,
        reset       => reset,
        in_valid    => u_in(idx).valid,
        in_ready    => u_in_ready(idx),
        in_data     => u_in(idx).data,
        in_cnt      => u_in(idx).cnt,
        in_last     => u_in(idx).last,
        out_valid   => u_out(idx).valid,
        out_ready   => u_out_ready(idx),
        out_dvalid  => u_out(idx).dvalid,
        out_data    => u_out(idx).data,
        out_cnt     => u_out(idx).cnt,
        out_last    => u_out(idx).last
      );
  end generate;

  -- Split the input into COUNT streams in round-robin fashion. Advance to the
  -- next block when the last transfer is handshaked.
  in_split_comb_proc: process (
    in_valid, u_in_ready, in_data, in_cnt, in_last, in_sel
  ) is
  begin
    for idx in 0 to COUNT - 1 loop
      if in_sel = idx then
        u_in(idx).valid <= in_valid;
      else
        u_in(idx).valid <= '0';
      end if;
      u_in(idx).data <= in_data;
      u_in(idx).cnt  <= in_cnt;
      u_in(idx).last <= in_last;
    end loop;
    in_ready_i <= u_in_ready(to_integer(in_sel));
  end process;

  in_split_reg_proc: process (clk) is
  begin
    if rising_edge(clk) then
      if in_valid = '1' and in_ready_i = '1' and in_last = '1' then
        if in_sel = COUNT - 1 then
          in_sel <= (others => '0');
        else
          in_sel <= in_sel + 1;
        end if;
      end if;
      if reset = '1' then
        in_sel <= (others => '0');
      end if;
    end if;
  end process;

  -- Merge the COUNT output streams into one by doing the reverse operation of
  -- the input splitter.
  out_merge_comb_proc: process (u_out, out_ready, out_sel) is
  begin
    for idx in 0 to COUNT - 1 loop
      if out_sel = idx then
        u_out_ready(idx) <= out_ready;
      else
        u_out_ready(idx) <= '0';
      end if;
    end loop;
    out_valid_i <= u_out(to_integer(out_sel)).valid;
    out_dvalid  <= u_out(to_integer(out_sel)).dvalid;
    out_data    <= u_out(to_integer(out_sel)).data;
    out_cnt     <= u_out(to_integer(out_sel)).cnt;
    out_last_i  <= u_out(to_integer(out_sel)).last;
  end process;

  out_split_reg_proc: process (clk) is
  begin
    if rising_edge(clk) then
      if out_valid_i = '1' and out_ready = '1' and out_last_i = '1' then
        if out_sel = COUNT - 1 then
          out_sel <= (others => '0');
        else
          out_sel <= out_sel + 1;
        end if;
      end if;
      if reset = '1' then
        out_sel <= (others => '0');
      end if;
    end if;
  end process;

  -- Forward internal signal copies.
  in_ready <= in_ready_i;
  out_valid <= out_valid_i;
  out_last <= out_last_i;

end behavior;
