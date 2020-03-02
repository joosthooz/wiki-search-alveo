library work;
use work.snappy_tta_imem_mau.all;

package snappy_tta_globals is
  -- address width of the instruction memory
  constant IMEMADDRWIDTH : positive := 10;
  -- width of the instruction memory in MAUs
  constant IMEMWIDTHINMAUS : positive := 1;
  -- width of instruction fetch block.
  constant IMEMDATAWIDTH : positive := IMEMWIDTHINMAUS*IMEMMAUWIDTH;
  -- clock period
  constant PERIOD : time := 10 ns;
  -- number of busses.
  constant BUSTRACE_WIDTH : positive := 288;
  -- number of cores
  constant CORECOUNT : positive := 1;
  -- instruction width
  constant INSTRUCTIONWIDTH : positive := 107;
end snappy_tta_globals;
