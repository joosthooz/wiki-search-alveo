library IEEE;
use IEEE.std_logic_1164.all;

package snappy_tta_gcu_opcodes is
  constant IFE_BEQ : natural := 0;
  constant IFE_BGE : natural := 1;
  constant IFE_BGEU : natural := 2;
  constant IFE_BGT : natural := 3;
  constant IFE_BGTU : natural := 4;
  constant IFE_BLE : natural := 5;
  constant IFE_BLEU : natural := 6;
  constant IFE_BLT : natural := 7;
  constant IFE_BLTU : natural := 8;
  constant IFE_BNE : natural := 9;
  constant IFE_BNZ1 : natural := 10;
  constant IFE_BZ1 : natural := 11;
  constant IFE_CALL : natural := 12;
  constant IFE_JUMP : natural := 13;
end snappy_tta_gcu_opcodes;
