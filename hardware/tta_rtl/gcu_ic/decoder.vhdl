library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use work.snappy_tta_globals.all;
use work.snappy_tta_gcu_opcodes.all;
use work.tce_util.all;

entity snappy_tta_decoder is

  port (
    instructionword : in std_logic_vector(INSTRUCTIONWIDTH-1 downto 0);
    pc_load : out std_logic;
    ra_load : out std_logic;
    pc_opcode : out std_logic_vector(0 downto 0);
    lock : in std_logic;
    lock_r : out std_logic;
    clk : in std_logic;
    rstx : in std_logic;
    locked : out std_logic;
    simm_GCU_LSU : out std_logic_vector(31 downto 0);
    simm_PARAM : out std_logic_vector(31 downto 0);
    simm_B1 : out std_logic_vector(31 downto 0);
    simm_B2 : out std_logic_vector(31 downto 0);
    simm_B3 : out std_logic_vector(2 downto 0);
    simm_B4 : out std_logic_vector(31 downto 0);
    socket_lsu_i1_bus_cntrl : out std_logic_vector(0 downto 0);
    socket_lsu_i2_bus_cntrl : out std_logic_vector(0 downto 0);
    socket_RF_i1_bus_cntrl : out std_logic_vector(1 downto 0);
    socket_bool_i1_bus_cntrl : out std_logic_vector(2 downto 0);
    socket_gcu_i1_bus_cntrl : out std_logic_vector(0 downto 0);
    socket_gcu_i2_bus_cntrl : out std_logic_vector(0 downto 0);
    socket_ALU_i1_bus_cntrl : out std_logic_vector(2 downto 0);
    socket_ALU_i2_bus_cntrl : out std_logic_vector(2 downto 0);
    socket_Streamout_i1_bus_cntrl : out std_logic_vector(1 downto 0);
    socket_Streamin_i1_bus_cntrl : out std_logic_vector(1 downto 0);
    socket_ALU2_i1_bus_cntrl : out std_logic_vector(2 downto 0);
    socket_ALU2_i2_bus_cntrl : out std_logic_vector(2 downto 0);
    socket_Streamout_i1_1_bus_cntrl : out std_logic_vector(2 downto 0);
    socket_ALU_i1_1_bus_cntrl : out std_logic_vector(2 downto 0);
    socket_ALU_i1_2_bus_cntrl : out std_logic_vector(2 downto 0);
    socket_Streamout_i1_1_1_bus_cntrl : out std_logic_vector(2 downto 0);
    GCU_LSU_src_sel : out std_logic_vector(2 downto 0);
    PARAM_src_sel : out std_logic_vector(0 downto 0);
    B1_src_sel : out std_logic_vector(0 downto 0);
    B2_src_sel : out std_logic_vector(0 downto 0);
    B3_src_sel : out std_logic_vector(0 downto 0);
    B4_src_sel : out std_logic_vector(3 downto 0);
    B4_1_src_sel : out std_logic_vector(0 downto 0);
    B3_1_1_src_sel : out std_logic_vector(0 downto 0);
    fu_Streamout_P1_load : out std_logic;
    fu_Streamin_P1_load : out std_logic;
    fu_ALU2_P1_load : out std_logic;
    fu_ALU2_P2_load : out std_logic;
    fu_ALU2_opc : out std_logic_vector(1 downto 0);
    fu_Streamout_read_P1_load : out std_logic;
    fu_Streamout_read_P3_load : out std_logic;
    fu_ALU_1_in1t_load : out std_logic;
    fu_ALU_1_in2_load : out std_logic;
    fu_ALU_1_opc : out std_logic_vector(3 downto 0);
    fu_LSU_in1t_load : out std_logic;
    fu_LSU_in2_load : out std_logic;
    fu_LSU_opc : out std_logic_vector(2 downto 0);
    fu_ALU_1_1_in1t_load : out std_logic;
    fu_ALU_1_1_in2_load : out std_logic;
    fu_ALU_1_1_opc : out std_logic_vector(3 downto 0);
    rf_RF_wr_load : out std_logic;
    rf_RF_wr_opc : out std_logic_vector(4 downto 0);
    rf_RF_rd_load : out std_logic;
    rf_RF_rd_opc : out std_logic_vector(4 downto 0);
    rf_RF_rd2_load : out std_logic;
    rf_RF_rd2_opc : out std_logic_vector(4 downto 0);
    rf_BOOL_wr_load : out std_logic;
    rf_BOOL_wr_opc : out std_logic_vector(0 downto 0);
    rf_BOOL_rd_load : out std_logic;
    rf_BOOL_rd_opc : out std_logic_vector(0 downto 0);
    iu_IU_1x32_r0_read_load : out std_logic;
    iu_IU_1x32_r0_read_opc : out std_logic_vector(0 downto 0);
    iu_IU_1x32_write : out std_logic_vector(31 downto 0);
    iu_IU_1x32_write_load : out std_logic;
    iu_IU_1x32_write_opc : out std_logic_vector(0 downto 0);
    rf_guard_BOOL_0 : in std_logic;
    lock_req : in std_logic_vector(6 downto 0);
    glock : out std_logic_vector(10 downto 0);
    db_tta_nreset : in std_logic);

end snappy_tta_decoder;

architecture rtl_andor of snappy_tta_decoder is

  -- signals for source, destination and guard fields
  signal move_GCU_LSU : std_logic_vector(20 downto 0);
  signal src_GCU_LSU : std_logic_vector(12 downto 0);
  signal dst_GCU_LSU : std_logic_vector(5 downto 0);
  signal grd_GCU_LSU : std_logic_vector(1 downto 0);
  signal move_PARAM : std_logic_vector(11 downto 0);
  signal src_PARAM : std_logic_vector(3 downto 0);
  signal dst_PARAM : std_logic_vector(5 downto 0);
  signal grd_PARAM : std_logic_vector(1 downto 0);
  signal move_B1 : std_logic_vector(11 downto 0);
  signal src_B1 : std_logic_vector(5 downto 0);
  signal dst_B1 : std_logic_vector(5 downto 0);
  signal move_B2 : std_logic_vector(9 downto 0);
  signal src_B2 : std_logic_vector(3 downto 0);
  signal dst_B2 : std_logic_vector(5 downto 0);
  signal move_B3 : std_logic_vector(9 downto 0);
  signal src_B3 : std_logic_vector(3 downto 0);
  signal dst_B3 : std_logic_vector(5 downto 0);
  signal move_B4 : std_logic_vector(13 downto 0);
  signal src_B4 : std_logic_vector(8 downto 0);
  signal dst_B4 : std_logic_vector(4 downto 0);
  signal move_B4_1 : std_logic_vector(1 downto 0);
  signal src_B4_1 : std_logic_vector(0 downto 0);
  signal move_B3_1_1 : std_logic_vector(12 downto 0);
  signal src_B3_1_1 : std_logic_vector(5 downto 0);
  signal dst_B3_1_1 : std_logic_vector(6 downto 0);
  signal move_B3_1_2 : std_logic_vector(11 downto 0);
  signal src_B3_1_2 : std_logic_vector(4 downto 0);
  signal dst_B3_1_2 : std_logic_vector(6 downto 0);

  -- signals for dedicated immediate slots

  -- signal for long immediate tag
  signal limm_tag : std_logic_vector(0 downto 0);

  -- squash signals
  signal squash_GCU_LSU : std_logic;
  signal squash_PARAM : std_logic;
  signal squash_B1 : std_logic;
  signal squash_B2 : std_logic;
  signal squash_B3 : std_logic;
  signal squash_B4 : std_logic;
  signal squash_B4_1 : std_logic;
  signal squash_B3_1_1 : std_logic;
  signal squash_B3_1_2 : std_logic;

  -- socket control signals
  signal socket_lsu_i1_bus_cntrl_reg : std_logic_vector(0 downto 0);
  signal socket_lsu_o1_bus_cntrl_reg : std_logic_vector(0 downto 0);
  signal socket_lsu_i2_bus_cntrl_reg : std_logic_vector(0 downto 0);
  signal socket_RF_i1_bus_cntrl_reg : std_logic_vector(1 downto 0);
  signal socket_RF_o1_bus_cntrl_reg : std_logic_vector(0 downto 0);
  signal socket_bool_i1_bus_cntrl_reg : std_logic_vector(2 downto 0);
  signal socket_bool_o1_bus_cntrl_reg : std_logic_vector(0 downto 0);
  signal socket_gcu_i1_bus_cntrl_reg : std_logic_vector(0 downto 0);
  signal socket_gcu_i2_bus_cntrl_reg : std_logic_vector(0 downto 0);
  signal socket_gcu_o1_bus_cntrl_reg : std_logic_vector(1 downto 0);
  signal socket_ALU_i1_bus_cntrl_reg : std_logic_vector(2 downto 0);
  signal socket_ALU_i2_bus_cntrl_reg : std_logic_vector(2 downto 0);
  signal socket_ALU_o1_bus_cntrl_reg : std_logic_vector(2 downto 0);
  signal socket_IMM_rd_bus_cntrl_reg : std_logic_vector(1 downto 0);
  signal socket_RF_o1_2_bus_cntrl_reg : std_logic_vector(0 downto 0);
  signal socket_Streamout_i1_bus_cntrl_reg : std_logic_vector(1 downto 0);
  signal socket_Streamin_i1_bus_cntrl_reg : std_logic_vector(1 downto 0);
  signal socket_Streamin_o1_bus_cntrl_reg : std_logic_vector(3 downto 0);
  signal socket_ALU2_i1_bus_cntrl_reg : std_logic_vector(2 downto 0);
  signal socket_ALU2_i2_bus_cntrl_reg : std_logic_vector(2 downto 0);
  signal socket_ALU2_o1_bus_cntrl_reg : std_logic_vector(1 downto 0);
  signal socket_Streamout_i1_1_bus_cntrl_reg : std_logic_vector(2 downto 0);
  signal socket_Streamout_o2_1_bus_cntrl_reg : std_logic_vector(1 downto 0);
  signal socket_ALU2_o1_1_bus_cntrl_reg : std_logic_vector(2 downto 0);
  signal socket_ALU_i1_1_bus_cntrl_reg : std_logic_vector(2 downto 0);
  signal socket_ALU_i1_2_bus_cntrl_reg : std_logic_vector(2 downto 0);
  signal socket_Streamout_i1_1_1_bus_cntrl_reg : std_logic_vector(2 downto 0);
  signal simm_GCU_LSU_reg : std_logic_vector(31 downto 0);
  signal GCU_LSU_src_sel_reg : std_logic_vector(2 downto 0);
  signal simm_PARAM_reg : std_logic_vector(31 downto 0);
  signal PARAM_src_sel_reg : std_logic_vector(0 downto 0);
  signal simm_B1_reg : std_logic_vector(31 downto 0);
  signal B1_src_sel_reg : std_logic_vector(0 downto 0);
  signal simm_B2_reg : std_logic_vector(31 downto 0);
  signal B2_src_sel_reg : std_logic_vector(0 downto 0);
  signal simm_B3_reg : std_logic_vector(2 downto 0);
  signal B3_src_sel_reg : std_logic_vector(0 downto 0);
  signal simm_B4_reg : std_logic_vector(31 downto 0);
  signal B4_src_sel_reg : std_logic_vector(3 downto 0);
  signal B4_1_src_sel_reg : std_logic_vector(0 downto 0);
  signal B3_1_1_src_sel_reg : std_logic_vector(0 downto 0);

  -- FU control signals
  signal fu_Streamout_P1_load_reg : std_logic;
  signal fu_Streamin_P1_load_reg : std_logic;
  signal fu_ALU2_P1_load_reg : std_logic;
  signal fu_ALU2_P2_load_reg : std_logic;
  signal fu_ALU2_opc_reg : std_logic_vector(1 downto 0);
  signal fu_Streamout_read_P1_load_reg : std_logic;
  signal fu_Streamout_read_P3_load_reg : std_logic;
  signal fu_ALU_1_in1t_load_reg : std_logic;
  signal fu_ALU_1_in2_load_reg : std_logic;
  signal fu_ALU_1_opc_reg : std_logic_vector(3 downto 0);
  signal fu_LSU_in1t_load_reg : std_logic;
  signal fu_LSU_in2_load_reg : std_logic;
  signal fu_LSU_opc_reg : std_logic_vector(2 downto 0);
  signal fu_ALU_1_1_in1t_load_reg : std_logic;
  signal fu_ALU_1_1_in2_load_reg : std_logic;
  signal fu_ALU_1_1_opc_reg : std_logic_vector(3 downto 0);
  signal fu_gcu_pc_load_reg : std_logic;
  signal fu_gcu_ra_load_reg : std_logic;
  signal fu_gcu_opc_reg : std_logic_vector(0 downto 0);

  -- RF control signals
  signal rf_RF_wr_load_reg : std_logic;
  signal rf_RF_wr_opc_reg : std_logic_vector(4 downto 0);
  signal rf_RF_rd_load_reg : std_logic;
  signal rf_RF_rd_opc_reg : std_logic_vector(4 downto 0);
  signal rf_RF_rd2_load_reg : std_logic;
  signal rf_RF_rd2_opc_reg : std_logic_vector(4 downto 0);
  signal rf_BOOL_wr_load_reg : std_logic;
  signal rf_BOOL_wr_opc_reg : std_logic_vector(0 downto 0);
  signal rf_BOOL_rd_load_reg : std_logic;
  signal rf_BOOL_rd_opc_reg : std_logic_vector(0 downto 0);

  signal merged_glock_req : std_logic;
  signal pre_decode_merged_glock : std_logic;
  signal post_decode_merged_glock : std_logic;
  signal post_decode_merged_glock_r : std_logic;

  signal decode_fill_lock_reg : std_logic;
begin

  -- dismembering of instruction
  process (instructionword)
  begin --process
    move_GCU_LSU <= instructionword(21-1 downto 0);
    src_GCU_LSU <= instructionword(18 downto 6);
    dst_GCU_LSU <= instructionword(5 downto 0);
    grd_GCU_LSU <= instructionword(20 downto 19);
    move_PARAM <= instructionword(33-1 downto 21);
    src_PARAM <= instructionword(30 downto 27);
    dst_PARAM <= instructionword(26 downto 21);
    grd_PARAM <= instructionword(32 downto 31);
    move_B1 <= instructionword(45-1 downto 33);
    src_B1 <= instructionword(44 downto 39);
    dst_B1 <= instructionword(38 downto 33);
    move_B2 <= instructionword(55-1 downto 45);
    src_B2 <= instructionword(54 downto 51);
    dst_B2 <= instructionword(50 downto 45);
    move_B3 <= instructionword(65-1 downto 55);
    src_B3 <= instructionword(64 downto 61);
    dst_B3 <= instructionword(60 downto 55);
    move_B4 <= instructionword(79-1 downto 65);
    src_B4 <= instructionword(78 downto 70);
    dst_B4 <= instructionword(69 downto 65);
    move_B4_1 <= instructionword(81-1 downto 79);
    src_B4_1 <= instructionword(79 downto 79);
    move_B3_1_1 <= instructionword(94-1 downto 81);
    src_B3_1_1 <= instructionword(93 downto 88);
    dst_B3_1_1 <= instructionword(87 downto 81);
    move_B3_1_2 <= instructionword(106-1 downto 94);
    src_B3_1_2 <= instructionword(105 downto 101);
    dst_B3_1_2 <= instructionword(100 downto 94);

    limm_tag <= instructionword(106 downto 106);
  end process;

  -- map control registers to outputs
  fu_Streamout_P1_load <= fu_Streamout_P1_load_reg;

  fu_Streamin_P1_load <= fu_Streamin_P1_load_reg;

  fu_ALU2_P1_load <= fu_ALU2_P1_load_reg;
  fu_ALU2_P2_load <= fu_ALU2_P2_load_reg;
  fu_ALU2_opc <= fu_ALU2_opc_reg;

  fu_Streamout_read_P1_load <= fu_Streamout_read_P1_load_reg;
  fu_Streamout_read_P3_load <= fu_Streamout_read_P3_load_reg;

  fu_ALU_1_in1t_load <= fu_ALU_1_in1t_load_reg;
  fu_ALU_1_in2_load <= fu_ALU_1_in2_load_reg;
  fu_ALU_1_opc <= fu_ALU_1_opc_reg;

  fu_LSU_in1t_load <= fu_LSU_in1t_load_reg;
  fu_LSU_in2_load <= fu_LSU_in2_load_reg;
  fu_LSU_opc <= fu_LSU_opc_reg;

  fu_ALU_1_1_in1t_load <= fu_ALU_1_1_in1t_load_reg;
  fu_ALU_1_1_in2_load <= fu_ALU_1_1_in2_load_reg;
  fu_ALU_1_1_opc <= fu_ALU_1_1_opc_reg;

  ra_load <= fu_gcu_ra_load_reg;
  pc_load <= fu_gcu_pc_load_reg;
  pc_opcode <= fu_gcu_opc_reg;
  rf_RF_wr_load <= rf_RF_wr_load_reg;
  rf_RF_wr_opc <= rf_RF_wr_opc_reg;
  rf_RF_rd_load <= rf_RF_rd_load_reg;
  rf_RF_rd_opc <= rf_RF_rd_opc_reg;
  rf_RF_rd2_load <= rf_RF_rd2_load_reg;
  rf_RF_rd2_opc <= rf_RF_rd2_opc_reg;
  rf_BOOL_wr_load <= rf_BOOL_wr_load_reg;
  rf_BOOL_wr_opc <= rf_BOOL_wr_opc_reg;
  rf_BOOL_rd_load <= rf_BOOL_rd_load_reg;
  rf_BOOL_rd_opc <= rf_BOOL_rd_opc_reg;
  iu_IU_1x32_r0_read_opc <= "0";
  iu_IU_1x32_write_opc <= "0";
  socket_lsu_i1_bus_cntrl <= socket_lsu_i1_bus_cntrl_reg;
  socket_lsu_i2_bus_cntrl <= socket_lsu_i2_bus_cntrl_reg;
  socket_RF_i1_bus_cntrl <= socket_RF_i1_bus_cntrl_reg;
  socket_bool_i1_bus_cntrl <= socket_bool_i1_bus_cntrl_reg;
  socket_gcu_i1_bus_cntrl <= socket_gcu_i1_bus_cntrl_reg;
  socket_gcu_i2_bus_cntrl <= socket_gcu_i2_bus_cntrl_reg;
  socket_ALU_i1_bus_cntrl <= socket_ALU_i1_bus_cntrl_reg;
  socket_ALU_i2_bus_cntrl <= socket_ALU_i2_bus_cntrl_reg;
  socket_Streamout_i1_bus_cntrl <= socket_Streamout_i1_bus_cntrl_reg;
  socket_Streamin_i1_bus_cntrl <= socket_Streamin_i1_bus_cntrl_reg;
  socket_ALU2_i1_bus_cntrl <= socket_ALU2_i1_bus_cntrl_reg;
  socket_ALU2_i2_bus_cntrl <= socket_ALU2_i2_bus_cntrl_reg;
  socket_Streamout_i1_1_bus_cntrl <= socket_Streamout_i1_1_bus_cntrl_reg;
  socket_ALU_i1_1_bus_cntrl <= socket_ALU_i1_1_bus_cntrl_reg;
  socket_ALU_i1_2_bus_cntrl <= socket_ALU_i1_2_bus_cntrl_reg;
  socket_Streamout_i1_1_1_bus_cntrl <= socket_Streamout_i1_1_1_bus_cntrl_reg;
  GCU_LSU_src_sel <= GCU_LSU_src_sel_reg;
  PARAM_src_sel <= PARAM_src_sel_reg;
  B1_src_sel <= B1_src_sel_reg;
  B2_src_sel <= B2_src_sel_reg;
  B3_src_sel <= B3_src_sel_reg;
  B4_src_sel <= B4_src_sel_reg;
  B4_1_src_sel <= B4_1_src_sel_reg;
  B3_1_1_src_sel <= B3_1_1_src_sel_reg;
  simm_GCU_LSU <= simm_GCU_LSU_reg;
  simm_PARAM <= simm_PARAM_reg;
  simm_B1 <= simm_B1_reg;
  simm_B2 <= simm_B2_reg;
  simm_B3 <= simm_B3_reg;
  simm_B4 <= simm_B4_reg;

  -- generate signal squash_GCU_LSU
  process (grd_GCU_LSU, limm_tag, move_GCU_LSU, rf_guard_BOOL_0)
    variable sel : integer;
  begin --process
    if (conv_integer(unsigned(limm_tag)) = 1) then
      squash_GCU_LSU <= '1';
    -- squash by move NOP encoding
    elsif (conv_integer(unsigned(move_GCU_LSU(20 downto 19))) = 3) then
      squash_GCU_LSU <= '1';
    else
      sel := conv_integer(unsigned(grd_GCU_LSU));
      case sel is
        when 1 =>
          squash_GCU_LSU <= not rf_guard_BOOL_0;
        when 2 =>
          squash_GCU_LSU <= rf_guard_BOOL_0;
        when others =>
          squash_GCU_LSU <= '0';
      end case;
    end if;
  end process;

  -- generate signal squash_PARAM
  process (grd_PARAM, limm_tag, move_PARAM, rf_guard_BOOL_0)
    variable sel : integer;
  begin --process
    if (conv_integer(unsigned(limm_tag)) = 1) then
      squash_PARAM <= '1';
    -- squash by move NOP encoding
    elsif (conv_integer(unsigned(move_PARAM(11 downto 10))) = 3) then
      squash_PARAM <= '1';
    else
      sel := conv_integer(unsigned(grd_PARAM));
      case sel is
        when 1 =>
          squash_PARAM <= not rf_guard_BOOL_0;
        when 2 =>
          squash_PARAM <= rf_guard_BOOL_0;
        when others =>
          squash_PARAM <= '0';
      end case;
    end if;
  end process;

  -- generate signal squash_B1
  process (limm_tag, move_B1)
  begin --process
    if (conv_integer(unsigned(limm_tag)) = 1) then
      squash_B1 <= '1';
    -- squash by move NOP encoding
    elsif (conv_integer(unsigned(move_B1(11 downto 10))) = 3) then
      squash_B1 <= '1';
    else
      squash_B1 <= '0';
    end if;
  end process;

  -- generate signal squash_B2
  process (move_B2)
  begin --process
    -- squash by move NOP encoding
    if (conv_integer(unsigned(move_B2(9 downto 8))) = 3) then
      squash_B2 <= '1';
    else
      squash_B2 <= '0';
    end if;
  end process;

  -- generate signal squash_B3
  process (move_B3)
  begin --process
    -- squash by move NOP encoding
    if (conv_integer(unsigned(move_B3(9 downto 8))) = 3) then
      squash_B3 <= '1';
    else
      squash_B3 <= '0';
    end if;
  end process;

  -- generate signal squash_B4
  process (move_B4)
  begin --process
    -- squash by move NOP encoding
    if (conv_integer(unsigned(move_B4(13 downto 9))) = 17) then
      squash_B4 <= '1';
    else
      squash_B4 <= '0';
    end if;
  end process;

  -- generate signal squash_B4_1
  process (move_B4_1)
  begin --process
    -- squash by move NOP encoding
    if (move_B4_1(1) = '1') then
      squash_B4_1 <= '1';
    else
      squash_B4_1 <= '0';
    end if;
  end process;

  -- generate signal squash_B3_1_1
  process (move_B3_1_1)
  begin --process
    -- squash by move NOP encoding
    if (conv_integer(unsigned(move_B3_1_1(12 downto 11))) = 3) then
      squash_B3_1_1 <= '1';
    else
      squash_B3_1_1 <= '0';
    end if;
  end process;

  -- generate signal squash_B3_1_2
  process (move_B3_1_2)
  begin --process
    -- squash by move NOP encoding
    if (conv_integer(unsigned(move_B3_1_2(6 downto 2))) = 27) then
      squash_B3_1_2 <= '1';
    else
      squash_B3_1_2 <= '0';
    end if;
  end process;


  --long immediate write process
  process (clk, rstx)
  begin --process
    if (rstx = '0') then
      iu_IU_1x32_write_load <= '0';
      iu_IU_1x32_write <= (others => '0');
    elsif (clk'event and clk = '1') then
      if pre_decode_merged_glock = '0' then
        if (conv_integer(unsigned(limm_tag)) = 0) then
          iu_IU_1x32_write_load <= '0';
          iu_IU_1x32_write(31 downto 0) <= tce_sxt("0", 32);
        else
          iu_IU_1x32_write(31 downto 22) <= tce_sxt(instructionword(30 downto 21), 10);
          iu_IU_1x32_write(21 downto 10) <= instructionword(11 downto 0);
          iu_IU_1x32_write(9 downto 0) <= instructionword(42 downto 33);
          iu_IU_1x32_write_load <= '1';
        end if;
      end if;
    end if;
  end process;


  -- main decoding process
  process (clk, rstx)
  begin
    if (rstx = '0') then
      socket_lsu_i1_bus_cntrl_reg <= (others => '0');
      socket_lsu_o1_bus_cntrl_reg <= (others => '0');
      socket_lsu_i2_bus_cntrl_reg <= (others => '0');
      socket_RF_i1_bus_cntrl_reg <= (others => '0');
      socket_RF_o1_bus_cntrl_reg <= (others => '0');
      socket_bool_i1_bus_cntrl_reg <= (others => '0');
      socket_bool_o1_bus_cntrl_reg <= (others => '0');
      socket_gcu_i1_bus_cntrl_reg <= (others => '0');
      socket_gcu_i2_bus_cntrl_reg <= (others => '0');
      socket_gcu_o1_bus_cntrl_reg <= (others => '0');
      socket_ALU_i1_bus_cntrl_reg <= (others => '0');
      socket_ALU_i2_bus_cntrl_reg <= (others => '0');
      socket_ALU_o1_bus_cntrl_reg <= (others => '0');
      socket_IMM_rd_bus_cntrl_reg <= (others => '0');
      socket_RF_o1_2_bus_cntrl_reg <= (others => '0');
      socket_Streamout_i1_bus_cntrl_reg <= (others => '0');
      socket_Streamin_i1_bus_cntrl_reg <= (others => '0');
      socket_Streamin_o1_bus_cntrl_reg <= (others => '0');
      socket_ALU2_i1_bus_cntrl_reg <= (others => '0');
      socket_ALU2_i2_bus_cntrl_reg <= (others => '0');
      socket_ALU2_o1_bus_cntrl_reg <= (others => '0');
      socket_Streamout_i1_1_bus_cntrl_reg <= (others => '0');
      socket_Streamout_o2_1_bus_cntrl_reg <= (others => '0');
      socket_ALU2_o1_1_bus_cntrl_reg <= (others => '0');
      socket_ALU_i1_1_bus_cntrl_reg <= (others => '0');
      socket_ALU_i1_2_bus_cntrl_reg <= (others => '0');
      socket_Streamout_i1_1_1_bus_cntrl_reg <= (others => '0');
      simm_GCU_LSU_reg <= (others => '0');
      GCU_LSU_src_sel_reg <= (others => '0');
      simm_PARAM_reg <= (others => '0');
      PARAM_src_sel_reg <= (others => '0');
      simm_B1_reg <= (others => '0');
      B1_src_sel_reg <= (others => '0');
      simm_B2_reg <= (others => '0');
      B2_src_sel_reg <= (others => '0');
      simm_B3_reg <= (others => '0');
      B3_src_sel_reg <= (others => '0');
      simm_B4_reg <= (others => '0');
      B4_src_sel_reg <= (others => '0');
      B4_1_src_sel_reg <= (others => '0');
      B3_1_1_src_sel_reg <= (others => '0');
      fu_ALU2_opc_reg <= (others => '0');
      fu_ALU_1_opc_reg <= (others => '0');
      fu_LSU_opc_reg <= (others => '0');
      fu_ALU_1_1_opc_reg <= (others => '0');
      fu_gcu_opc_reg <= (others => '0');
      rf_RF_wr_opc_reg <= (others => '0');
      rf_RF_rd_opc_reg <= (others => '0');
      rf_RF_rd2_opc_reg <= (others => '0');
      rf_BOOL_wr_opc_reg <= (others => '0');
      rf_BOOL_rd_opc_reg <= (others => '0');

      fu_Streamout_P1_load_reg <= '0';
      fu_Streamin_P1_load_reg <= '0';
      fu_ALU2_P1_load_reg <= '0';
      fu_ALU2_P2_load_reg <= '0';
      fu_Streamout_read_P1_load_reg <= '0';
      fu_Streamout_read_P3_load_reg <= '0';
      fu_ALU_1_in1t_load_reg <= '0';
      fu_ALU_1_in2_load_reg <= '0';
      fu_LSU_in1t_load_reg <= '0';
      fu_LSU_in2_load_reg <= '0';
      fu_ALU_1_1_in1t_load_reg <= '0';
      fu_ALU_1_1_in2_load_reg <= '0';
      fu_gcu_pc_load_reg <= '0';
      fu_gcu_ra_load_reg <= '0';
      rf_RF_wr_load_reg <= '0';
      rf_RF_rd_load_reg <= '0';
      rf_RF_rd2_load_reg <= '0';
      rf_BOOL_wr_load_reg <= '0';
      rf_BOOL_rd_load_reg <= '0';
      iu_IU_1x32_r0_read_load <= '0';


    elsif (clk'event and clk = '1') then -- rising clock edge
      if (db_tta_nreset = '0') then
      socket_lsu_i1_bus_cntrl_reg <= (others => '0');
      socket_lsu_o1_bus_cntrl_reg <= (others => '0');
      socket_lsu_i2_bus_cntrl_reg <= (others => '0');
      socket_RF_i1_bus_cntrl_reg <= (others => '0');
      socket_RF_o1_bus_cntrl_reg <= (others => '0');
      socket_bool_i1_bus_cntrl_reg <= (others => '0');
      socket_bool_o1_bus_cntrl_reg <= (others => '0');
      socket_gcu_i1_bus_cntrl_reg <= (others => '0');
      socket_gcu_i2_bus_cntrl_reg <= (others => '0');
      socket_gcu_o1_bus_cntrl_reg <= (others => '0');
      socket_ALU_i1_bus_cntrl_reg <= (others => '0');
      socket_ALU_i2_bus_cntrl_reg <= (others => '0');
      socket_ALU_o1_bus_cntrl_reg <= (others => '0');
      socket_IMM_rd_bus_cntrl_reg <= (others => '0');
      socket_RF_o1_2_bus_cntrl_reg <= (others => '0');
      socket_Streamout_i1_bus_cntrl_reg <= (others => '0');
      socket_Streamin_i1_bus_cntrl_reg <= (others => '0');
      socket_Streamin_o1_bus_cntrl_reg <= (others => '0');
      socket_ALU2_i1_bus_cntrl_reg <= (others => '0');
      socket_ALU2_i2_bus_cntrl_reg <= (others => '0');
      socket_ALU2_o1_bus_cntrl_reg <= (others => '0');
      socket_Streamout_i1_1_bus_cntrl_reg <= (others => '0');
      socket_Streamout_o2_1_bus_cntrl_reg <= (others => '0');
      socket_ALU2_o1_1_bus_cntrl_reg <= (others => '0');
      socket_ALU_i1_1_bus_cntrl_reg <= (others => '0');
      socket_ALU_i1_2_bus_cntrl_reg <= (others => '0');
      socket_Streamout_i1_1_1_bus_cntrl_reg <= (others => '0');
      simm_GCU_LSU_reg <= (others => '0');
      GCU_LSU_src_sel_reg <= (others => '0');
      simm_PARAM_reg <= (others => '0');
      PARAM_src_sel_reg <= (others => '0');
      simm_B1_reg <= (others => '0');
      B1_src_sel_reg <= (others => '0');
      simm_B2_reg <= (others => '0');
      B2_src_sel_reg <= (others => '0');
      simm_B3_reg <= (others => '0');
      B3_src_sel_reg <= (others => '0');
      simm_B4_reg <= (others => '0');
      B4_src_sel_reg <= (others => '0');
      B4_1_src_sel_reg <= (others => '0');
      B3_1_1_src_sel_reg <= (others => '0');
      fu_ALU2_opc_reg <= (others => '0');
      fu_ALU_1_opc_reg <= (others => '0');
      fu_LSU_opc_reg <= (others => '0');
      fu_ALU_1_1_opc_reg <= (others => '0');
      fu_gcu_opc_reg <= (others => '0');
      rf_RF_wr_opc_reg <= (others => '0');
      rf_RF_rd_opc_reg <= (others => '0');
      rf_RF_rd2_opc_reg <= (others => '0');
      rf_BOOL_wr_opc_reg <= (others => '0');
      rf_BOOL_rd_opc_reg <= (others => '0');

      fu_Streamout_P1_load_reg <= '0';
      fu_Streamin_P1_load_reg <= '0';
      fu_ALU2_P1_load_reg <= '0';
      fu_ALU2_P2_load_reg <= '0';
      fu_Streamout_read_P1_load_reg <= '0';
      fu_Streamout_read_P3_load_reg <= '0';
      fu_ALU_1_in1t_load_reg <= '0';
      fu_ALU_1_in2_load_reg <= '0';
      fu_LSU_in1t_load_reg <= '0';
      fu_LSU_in2_load_reg <= '0';
      fu_ALU_1_1_in1t_load_reg <= '0';
      fu_ALU_1_1_in2_load_reg <= '0';
      fu_gcu_pc_load_reg <= '0';
      fu_gcu_ra_load_reg <= '0';
      rf_RF_wr_load_reg <= '0';
      rf_RF_rd_load_reg <= '0';
      rf_RF_rd2_load_reg <= '0';
      rf_BOOL_wr_load_reg <= '0';
      rf_BOOL_rd_load_reg <= '0';
      iu_IU_1x32_r0_read_load <= '0';

      elsif (pre_decode_merged_glock = '0') then

        -- bus control signals for output mux
        if (squash_GCU_LSU = '0' and conv_integer(unsigned(src_GCU_LSU(12 downto 9))) = 8) then
          GCU_LSU_src_sel_reg <= std_logic_vector(conv_unsigned(0, GCU_LSU_src_sel_reg'length));
        elsif (squash_GCU_LSU = '0' and conv_integer(unsigned(src_GCU_LSU(12 downto 9))) = 9) then
          GCU_LSU_src_sel_reg <= std_logic_vector(conv_unsigned(1, GCU_LSU_src_sel_reg'length));
        elsif (squash_GCU_LSU = '0' and conv_integer(unsigned(src_GCU_LSU(12 downto 9))) = 10) then
          GCU_LSU_src_sel_reg <= std_logic_vector(conv_unsigned(2, GCU_LSU_src_sel_reg'length));
        elsif (squash_GCU_LSU = '0' and conv_integer(unsigned(src_GCU_LSU(12 downto 9))) = 11) then
          GCU_LSU_src_sel_reg <= std_logic_vector(conv_unsigned(3, GCU_LSU_src_sel_reg'length));
        elsif (squash_GCU_LSU = '0' and conv_integer(unsigned(src_GCU_LSU(12 downto 9))) = 12) then
          GCU_LSU_src_sel_reg <= std_logic_vector(conv_unsigned(4, GCU_LSU_src_sel_reg'length));
        elsif (squash_GCU_LSU = '0' and conv_integer(unsigned(src_GCU_LSU(12 downto 12))) = 0) then
          GCU_LSU_src_sel_reg <= std_logic_vector(conv_unsigned(5, GCU_LSU_src_sel_reg'length));
        end if;
        if (squash_GCU_LSU = '0' and conv_integer(unsigned(src_GCU_LSU(12 downto 12))) = 0) then
        simm_GCU_LSU_reg <= tce_sxt(src_GCU_LSU(11 downto 0), simm_GCU_LSU_reg'length);
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(src_PARAM(3 downto 3))) = 1) then
          PARAM_src_sel_reg <= std_logic_vector(conv_unsigned(0, PARAM_src_sel_reg'length));
        elsif (squash_PARAM = '0' and conv_integer(unsigned(src_PARAM(3 downto 3))) = 0) then
          PARAM_src_sel_reg <= std_logic_vector(conv_unsigned(1, PARAM_src_sel_reg'length));
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(src_PARAM(3 downto 3))) = 0) then
        simm_PARAM_reg <= tce_sxt(src_PARAM(2 downto 0), simm_PARAM_reg'length);
        end if;
        if (squash_B1 = '0' and conv_integer(unsigned(src_B1(5 downto 4))) = 2) then
          B1_src_sel_reg <= std_logic_vector(conv_unsigned(0, B1_src_sel_reg'length));
        elsif (squash_B1 = '0' and conv_integer(unsigned(src_B1(5 downto 5))) = 0) then
          B1_src_sel_reg <= std_logic_vector(conv_unsigned(1, B1_src_sel_reg'length));
        end if;
        if (squash_B1 = '0' and conv_integer(unsigned(src_B1(5 downto 5))) = 0) then
        simm_B1_reg <= tce_sxt(src_B1(4 downto 0), simm_B1_reg'length);
        end if;
        if (squash_B2 = '0' and conv_integer(unsigned(src_B2(3 downto 2))) = 2) then
          B2_src_sel_reg <= std_logic_vector(conv_unsigned(0, B2_src_sel_reg'length));
        elsif (squash_B2 = '0' and conv_integer(unsigned(src_B2(3 downto 3))) = 0) then
          B2_src_sel_reg <= std_logic_vector(conv_unsigned(1, B2_src_sel_reg'length));
        end if;
        if (squash_B2 = '0' and conv_integer(unsigned(src_B2(3 downto 3))) = 0) then
        simm_B2_reg <= tce_sxt(src_B2(2 downto 0), simm_B2_reg'length);
        end if;
        if (squash_B3 = '0' and conv_integer(unsigned(src_B3(3 downto 2))) = 2) then
          B3_src_sel_reg <= std_logic_vector(conv_unsigned(0, B3_src_sel_reg'length));
        elsif (squash_B3 = '0' and conv_integer(unsigned(src_B3(3 downto 3))) = 0) then
          B3_src_sel_reg <= std_logic_vector(conv_unsigned(1, B3_src_sel_reg'length));
        end if;
        if (squash_B3 = '0' and conv_integer(unsigned(src_B3(3 downto 3))) = 0) then
        simm_B3_reg <= tce_ext(src_B3(2 downto 0), simm_B3_reg'length);
        end if;
        if (squash_B4 = '0' and conv_integer(unsigned(src_B4(8 downto 4))) = 16) then
          B4_src_sel_reg <= std_logic_vector(conv_unsigned(0, B4_src_sel_reg'length));
        elsif (squash_B4 = '0' and conv_integer(unsigned(src_B4(8 downto 5))) = 9) then
          B4_src_sel_reg <= std_logic_vector(conv_unsigned(1, B4_src_sel_reg'length));
        elsif (squash_B4 = '0' and conv_integer(unsigned(src_B4(8 downto 5))) = 10) then
          B4_src_sel_reg <= std_logic_vector(conv_unsigned(2, B4_src_sel_reg'length));
        elsif (squash_B4 = '0' and conv_integer(unsigned(src_B4(8 downto 5))) = 11) then
          B4_src_sel_reg <= std_logic_vector(conv_unsigned(3, B4_src_sel_reg'length));
        elsif (squash_B4 = '0' and conv_integer(unsigned(src_B4(8 downto 5))) = 12) then
          B4_src_sel_reg <= std_logic_vector(conv_unsigned(4, B4_src_sel_reg'length));
        elsif (squash_B4 = '0' and conv_integer(unsigned(src_B4(8 downto 5))) = 13) then
          B4_src_sel_reg <= std_logic_vector(conv_unsigned(5, B4_src_sel_reg'length));
        elsif (squash_B4 = '0' and conv_integer(unsigned(src_B4(8 downto 5))) = 14) then
          B4_src_sel_reg <= std_logic_vector(conv_unsigned(6, B4_src_sel_reg'length));
        elsif (squash_B4 = '0' and conv_integer(unsigned(src_B4(8 downto 5))) = 15) then
          B4_src_sel_reg <= std_logic_vector(conv_unsigned(7, B4_src_sel_reg'length));
        elsif (squash_B4 = '0' and conv_integer(unsigned(src_B4(8 downto 8))) = 0) then
          B4_src_sel_reg <= std_logic_vector(conv_unsigned(8, B4_src_sel_reg'length));
        end if;
        if (squash_B4 = '0' and conv_integer(unsigned(src_B4(8 downto 8))) = 0) then
        simm_B4_reg <= tce_sxt(src_B4(7 downto 0), simm_B4_reg'length);
        end if;
        if (squash_B4_1 = '0' and conv_integer(unsigned(src_B4_1(0 downto 0))) = 0) then
          B4_1_src_sel_reg <= std_logic_vector(conv_unsigned(0, B4_1_src_sel_reg'length));
        elsif (squash_B4_1 = '0' and conv_integer(unsigned(src_B4_1(0 downto 0))) = 1) then
          B4_1_src_sel_reg <= std_logic_vector(conv_unsigned(1, B4_1_src_sel_reg'length));
        end if;
        if (squash_B3_1_1 = '0' and conv_integer(unsigned(src_B3_1_1(5 downto 4))) = 2) then
          B3_1_1_src_sel_reg <= std_logic_vector(conv_unsigned(0, B3_1_1_src_sel_reg'length));
        elsif (squash_B3_1_1 = '0' and conv_integer(unsigned(src_B3_1_1(5 downto 5))) = 0) then
          B3_1_1_src_sel_reg <= std_logic_vector(conv_unsigned(1, B3_1_1_src_sel_reg'length));
        end if;
        -- data control signals for output sockets connected to FUs
        -- control signals for RF read ports
        if (squash_B3_1_2 = '0' and true and true) then
          rf_RF_rd_load_reg <= '1';
          rf_RF_rd_opc_reg <= tce_ext(src_B3_1_2(4 downto 0), rf_RF_rd_opc_reg'length);
        else
          rf_RF_rd_load_reg <= '0';
        end if;
        if (squash_B3_1_1 = '0' and conv_integer(unsigned(src_B3_1_1(5 downto 5))) = 0 and true) then
          rf_RF_rd2_load_reg <= '1';
          rf_RF_rd2_opc_reg <= tce_ext(src_B3_1_1(4 downto 0), rf_RF_rd2_opc_reg'length);
        else
          rf_RF_rd2_load_reg <= '0';
        end if;
        if (squash_B4 = '0' and conv_integer(unsigned(src_B4(8 downto 4))) = 16 and true) then
          rf_BOOL_rd_load_reg <= '1';
          rf_BOOL_rd_opc_reg <= tce_ext(src_B4(0 downto 0), rf_BOOL_rd_opc_reg'length);
        else
          rf_BOOL_rd_load_reg <= '0';
        end if;

        --control signals for IU read ports
        -- control signals for IU read ports
        if (squash_B4 = '0' and conv_integer(unsigned(src_B4(8 downto 5))) = 11) then
          iu_IU_1x32_r0_read_load <= '1';
        elsif (squash_B3_1_1 = '0' and conv_integer(unsigned(src_B3_1_1(5 downto 4))) = 2) then
          iu_IU_1x32_r0_read_load <= '1';
        else
          iu_IU_1x32_r0_read_load <= '0';
        end if;

        -- control signals for FU inputs
        if (squash_B4_1 = '0' and true) then
          fu_Streamout_P1_load_reg <= '1';
          socket_Streamout_i1_bus_cntrl_reg <= conv_std_logic_vector(0, socket_Streamout_i1_bus_cntrl_reg'length);
        elsif (squash_B3_1_1 = '0' and conv_integer(unsigned(dst_B3_1_1(6 downto 2))) = 21) then
          fu_Streamout_P1_load_reg <= '1';
          socket_Streamout_i1_bus_cntrl_reg <= conv_std_logic_vector(1, socket_Streamout_i1_bus_cntrl_reg'length);
        elsif (squash_B3_1_2 = '0' and conv_integer(unsigned(dst_B3_1_2(6 downto 2))) = 22) then
          fu_Streamout_P1_load_reg <= '1';
          socket_Streamout_i1_bus_cntrl_reg <= conv_std_logic_vector(2, socket_Streamout_i1_bus_cntrl_reg'length);
        else
          fu_Streamout_P1_load_reg <= '0';
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(dst_PARAM(5 downto 2))) = 10) then
          fu_Streamin_P1_load_reg <= '1';
          socket_Streamin_i1_bus_cntrl_reg <= conv_std_logic_vector(0, socket_Streamin_i1_bus_cntrl_reg'length);
        elsif (squash_B2 = '0' and conv_integer(unsigned(dst_B2(5 downto 2))) = 11) then
          fu_Streamin_P1_load_reg <= '1';
          socket_Streamin_i1_bus_cntrl_reg <= conv_std_logic_vector(1, socket_Streamin_i1_bus_cntrl_reg'length);
        elsif (squash_B3 = '0' and conv_integer(unsigned(dst_B3(5 downto 2))) = 11) then
          fu_Streamin_P1_load_reg <= '1';
          socket_Streamin_i1_bus_cntrl_reg <= conv_std_logic_vector(2, socket_Streamin_i1_bus_cntrl_reg'length);
        else
          fu_Streamin_P1_load_reg <= '0';
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(dst_PARAM(5 downto 2))) = 8) then
          fu_ALU2_P1_load_reg <= '1';
          fu_ALU2_opc_reg <= dst_PARAM(1 downto 0);
          socket_ALU2_i1_bus_cntrl_reg <= conv_std_logic_vector(0, socket_ALU2_i1_bus_cntrl_reg'length);
        elsif (squash_B1 = '0' and conv_integer(unsigned(dst_B1(5 downto 2))) = 8) then
          fu_ALU2_P1_load_reg <= '1';
          fu_ALU2_opc_reg <= dst_B1(1 downto 0);
          socket_ALU2_i1_bus_cntrl_reg <= conv_std_logic_vector(1, socket_ALU2_i1_bus_cntrl_reg'length);
        elsif (squash_B2 = '0' and conv_integer(unsigned(dst_B2(5 downto 2))) = 8) then
          fu_ALU2_P1_load_reg <= '1';
          fu_ALU2_opc_reg <= dst_B2(1 downto 0);
          socket_ALU2_i1_bus_cntrl_reg <= conv_std_logic_vector(2, socket_ALU2_i1_bus_cntrl_reg'length);
        elsif (squash_B3 = '0' and conv_integer(unsigned(dst_B3(5 downto 2))) = 8) then
          fu_ALU2_P1_load_reg <= '1';
          fu_ALU2_opc_reg <= dst_B3(1 downto 0);
          socket_ALU2_i1_bus_cntrl_reg <= conv_std_logic_vector(3, socket_ALU2_i1_bus_cntrl_reg'length);
        elsif (squash_B3_1_1 = '0' and conv_integer(unsigned(dst_B3_1_1(6 downto 2))) = 16) then
          fu_ALU2_P1_load_reg <= '1';
          fu_ALU2_opc_reg <= dst_B3_1_1(1 downto 0);
          socket_ALU2_i1_bus_cntrl_reg <= conv_std_logic_vector(4, socket_ALU2_i1_bus_cntrl_reg'length);
        elsif (squash_B3_1_2 = '0' and conv_integer(unsigned(dst_B3_1_2(6 downto 2))) = 18) then
          fu_ALU2_P1_load_reg <= '1';
          fu_ALU2_opc_reg <= dst_B3_1_2(1 downto 0);
          socket_ALU2_i1_bus_cntrl_reg <= conv_std_logic_vector(5, socket_ALU2_i1_bus_cntrl_reg'length);
        else
          fu_ALU2_P1_load_reg <= '0';
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(dst_PARAM(5 downto 2))) = 11) then
          fu_ALU2_P2_load_reg <= '1';
          socket_ALU2_i2_bus_cntrl_reg <= conv_std_logic_vector(0, socket_ALU2_i2_bus_cntrl_reg'length);
        elsif (squash_B1 = '0' and conv_integer(unsigned(dst_B1(5 downto 2))) = 11) then
          fu_ALU2_P2_load_reg <= '1';
          socket_ALU2_i2_bus_cntrl_reg <= conv_std_logic_vector(5, socket_ALU2_i2_bus_cntrl_reg'length);
        elsif (squash_B2 = '0' and conv_integer(unsigned(dst_B2(5 downto 2))) = 12) then
          fu_ALU2_P2_load_reg <= '1';
          socket_ALU2_i2_bus_cntrl_reg <= conv_std_logic_vector(1, socket_ALU2_i2_bus_cntrl_reg'length);
        elsif (squash_B3 = '0' and conv_integer(unsigned(dst_B3(5 downto 2))) = 12) then
          fu_ALU2_P2_load_reg <= '1';
          socket_ALU2_i2_bus_cntrl_reg <= conv_std_logic_vector(2, socket_ALU2_i2_bus_cntrl_reg'length);
        elsif (squash_B3_1_1 = '0' and conv_integer(unsigned(dst_B3_1_1(6 downto 2))) = 22) then
          fu_ALU2_P2_load_reg <= '1';
          socket_ALU2_i2_bus_cntrl_reg <= conv_std_logic_vector(3, socket_ALU2_i2_bus_cntrl_reg'length);
        elsif (squash_B3_1_2 = '0' and conv_integer(unsigned(dst_B3_1_2(6 downto 2))) = 23) then
          fu_ALU2_P2_load_reg <= '1';
          socket_ALU2_i2_bus_cntrl_reg <= conv_std_logic_vector(4, socket_ALU2_i2_bus_cntrl_reg'length);
        else
          fu_ALU2_P2_load_reg <= '0';
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(dst_PARAM(5 downto 2))) = 12) then
          fu_Streamout_read_P1_load_reg <= '1';
          socket_Streamout_i1_1_bus_cntrl_reg <= conv_std_logic_vector(0, socket_Streamout_i1_1_bus_cntrl_reg'length);
        elsif (squash_B1 = '0' and conv_integer(unsigned(dst_B1(5 downto 2))) = 12) then
          fu_Streamout_read_P1_load_reg <= '1';
          socket_Streamout_i1_1_bus_cntrl_reg <= conv_std_logic_vector(1, socket_Streamout_i1_1_bus_cntrl_reg'length);
        elsif (squash_B2 = '0' and conv_integer(unsigned(dst_B2(5 downto 2))) = 13) then
          fu_Streamout_read_P1_load_reg <= '1';
          socket_Streamout_i1_1_bus_cntrl_reg <= conv_std_logic_vector(2, socket_Streamout_i1_1_bus_cntrl_reg'length);
        elsif (squash_B3 = '0' and conv_integer(unsigned(dst_B3(5 downto 2))) = 13) then
          fu_Streamout_read_P1_load_reg <= '1';
          socket_Streamout_i1_1_bus_cntrl_reg <= conv_std_logic_vector(3, socket_Streamout_i1_1_bus_cntrl_reg'length);
        elsif (squash_B3_1_1 = '0' and conv_integer(unsigned(dst_B3_1_1(6 downto 2))) = 23) then
          fu_Streamout_read_P1_load_reg <= '1';
          socket_Streamout_i1_1_bus_cntrl_reg <= conv_std_logic_vector(4, socket_Streamout_i1_1_bus_cntrl_reg'length);
        elsif (squash_B3_1_2 = '0' and conv_integer(unsigned(dst_B3_1_2(6 downto 2))) = 24) then
          fu_Streamout_read_P1_load_reg <= '1';
          socket_Streamout_i1_1_bus_cntrl_reg <= conv_std_logic_vector(5, socket_Streamout_i1_1_bus_cntrl_reg'length);
        else
          fu_Streamout_read_P1_load_reg <= '0';
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(dst_PARAM(5 downto 2))) = 14) then
          fu_Streamout_read_P3_load_reg <= '1';
          socket_Streamout_i1_1_1_bus_cntrl_reg <= conv_std_logic_vector(0, socket_Streamout_i1_1_1_bus_cntrl_reg'length);
        elsif (squash_B1 = '0' and conv_integer(unsigned(dst_B1(5 downto 2))) = 14) then
          fu_Streamout_read_P3_load_reg <= '1';
          socket_Streamout_i1_1_1_bus_cntrl_reg <= conv_std_logic_vector(1, socket_Streamout_i1_1_1_bus_cntrl_reg'length);
        elsif (squash_B2 = '0' and conv_integer(unsigned(dst_B2(5 downto 2))) = 15) then
          fu_Streamout_read_P3_load_reg <= '1';
          socket_Streamout_i1_1_1_bus_cntrl_reg <= conv_std_logic_vector(2, socket_Streamout_i1_1_1_bus_cntrl_reg'length);
        elsif (squash_B3 = '0' and conv_integer(unsigned(dst_B3(5 downto 2))) = 15) then
          fu_Streamout_read_P3_load_reg <= '1';
          socket_Streamout_i1_1_1_bus_cntrl_reg <= conv_std_logic_vector(3, socket_Streamout_i1_1_1_bus_cntrl_reg'length);
        elsif (squash_B3_1_1 = '0' and conv_integer(unsigned(dst_B3_1_1(6 downto 2))) = 25) then
          fu_Streamout_read_P3_load_reg <= '1';
          socket_Streamout_i1_1_1_bus_cntrl_reg <= conv_std_logic_vector(5, socket_Streamout_i1_1_1_bus_cntrl_reg'length);
        elsif (squash_B3_1_2 = '0' and conv_integer(unsigned(dst_B3_1_2(6 downto 2))) = 26) then
          fu_Streamout_read_P3_load_reg <= '1';
          socket_Streamout_i1_1_1_bus_cntrl_reg <= conv_std_logic_vector(4, socket_Streamout_i1_1_1_bus_cntrl_reg'length);
        else
          fu_Streamout_read_P3_load_reg <= '0';
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(dst_PARAM(5 downto 4))) = 1) then
          fu_ALU_1_in1t_load_reg <= '1';
          fu_ALU_1_opc_reg <= dst_PARAM(3 downto 0);
          socket_ALU_i1_1_bus_cntrl_reg <= conv_std_logic_vector(0, socket_ALU_i1_1_bus_cntrl_reg'length);
        elsif (squash_B1 = '0' and conv_integer(unsigned(dst_B1(5 downto 4))) = 1) then
          fu_ALU_1_in1t_load_reg <= '1';
          fu_ALU_1_opc_reg <= dst_B1(3 downto 0);
          socket_ALU_i1_1_bus_cntrl_reg <= conv_std_logic_vector(1, socket_ALU_i1_1_bus_cntrl_reg'length);
        elsif (squash_B2 = '0' and conv_integer(unsigned(dst_B2(5 downto 4))) = 1) then
          fu_ALU_1_in1t_load_reg <= '1';
          fu_ALU_1_opc_reg <= dst_B2(3 downto 0);
          socket_ALU_i1_1_bus_cntrl_reg <= conv_std_logic_vector(2, socket_ALU_i1_1_bus_cntrl_reg'length);
        elsif (squash_B3 = '0' and conv_integer(unsigned(dst_B3(5 downto 4))) = 1) then
          fu_ALU_1_in1t_load_reg <= '1';
          fu_ALU_1_opc_reg <= dst_B3(3 downto 0);
          socket_ALU_i1_1_bus_cntrl_reg <= conv_std_logic_vector(3, socket_ALU_i1_1_bus_cntrl_reg'length);
        elsif (squash_B3_1_1 = '0' and conv_integer(unsigned(dst_B3_1_1(6 downto 4))) = 3) then
          fu_ALU_1_in1t_load_reg <= '1';
          fu_ALU_1_opc_reg <= dst_B3_1_1(3 downto 0);
          socket_ALU_i1_1_bus_cntrl_reg <= conv_std_logic_vector(4, socket_ALU_i1_1_bus_cntrl_reg'length);
        elsif (squash_B3_1_2 = '0' and conv_integer(unsigned(dst_B3_1_2(6 downto 4))) = 3) then
          fu_ALU_1_in1t_load_reg <= '1';
          fu_ALU_1_opc_reg <= dst_B3_1_2(3 downto 0);
          socket_ALU_i1_1_bus_cntrl_reg <= conv_std_logic_vector(5, socket_ALU_i1_1_bus_cntrl_reg'length);
        else
          fu_ALU_1_in1t_load_reg <= '0';
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(dst_PARAM(5 downto 2))) = 13) then
          fu_ALU_1_in2_load_reg <= '1';
          socket_ALU_i1_2_bus_cntrl_reg <= conv_std_logic_vector(0, socket_ALU_i1_2_bus_cntrl_reg'length);
        elsif (squash_B1 = '0' and conv_integer(unsigned(dst_B1(5 downto 2))) = 13) then
          fu_ALU_1_in2_load_reg <= '1';
          socket_ALU_i1_2_bus_cntrl_reg <= conv_std_logic_vector(1, socket_ALU_i1_2_bus_cntrl_reg'length);
        elsif (squash_B2 = '0' and conv_integer(unsigned(dst_B2(5 downto 2))) = 14) then
          fu_ALU_1_in2_load_reg <= '1';
          socket_ALU_i1_2_bus_cntrl_reg <= conv_std_logic_vector(5, socket_ALU_i1_2_bus_cntrl_reg'length);
        elsif (squash_B3 = '0' and conv_integer(unsigned(dst_B3(5 downto 2))) = 14) then
          fu_ALU_1_in2_load_reg <= '1';
          socket_ALU_i1_2_bus_cntrl_reg <= conv_std_logic_vector(2, socket_ALU_i1_2_bus_cntrl_reg'length);
        elsif (squash_B3_1_1 = '0' and conv_integer(unsigned(dst_B3_1_1(6 downto 2))) = 24) then
          fu_ALU_1_in2_load_reg <= '1';
          socket_ALU_i1_2_bus_cntrl_reg <= conv_std_logic_vector(3, socket_ALU_i1_2_bus_cntrl_reg'length);
        elsif (squash_B3_1_2 = '0' and conv_integer(unsigned(dst_B3_1_2(6 downto 2))) = 25) then
          fu_ALU_1_in2_load_reg <= '1';
          socket_ALU_i1_2_bus_cntrl_reg <= conv_std_logic_vector(4, socket_ALU_i1_2_bus_cntrl_reg'length);
        else
          fu_ALU_1_in2_load_reg <= '0';
        end if;
        if (squash_GCU_LSU = '0' and conv_integer(unsigned(dst_GCU_LSU(5 downto 3))) = 6) then
          fu_LSU_in1t_load_reg <= '1';
          fu_LSU_opc_reg <= dst_GCU_LSU(2 downto 0);
          socket_lsu_i2_bus_cntrl_reg <= conv_std_logic_vector(1, socket_lsu_i2_bus_cntrl_reg'length);
        elsif (squash_B3_1_2 = '0' and conv_integer(unsigned(dst_B3_1_2(6 downto 3))) = 8) then
          fu_LSU_in1t_load_reg <= '1';
          fu_LSU_opc_reg <= dst_B3_1_2(2 downto 0);
          socket_lsu_i2_bus_cntrl_reg <= conv_std_logic_vector(0, socket_lsu_i2_bus_cntrl_reg'length);
        else
          fu_LSU_in1t_load_reg <= '0';
        end if;
        if (squash_GCU_LSU = '0' and conv_integer(unsigned(dst_GCU_LSU(5 downto 1))) = 29) then
          fu_LSU_in2_load_reg <= '1';
          socket_lsu_i1_bus_cntrl_reg <= conv_std_logic_vector(1, socket_lsu_i1_bus_cntrl_reg'length);
        elsif (squash_B3_1_1 = '0' and conv_integer(unsigned(dst_B3_1_1(6 downto 2))) = 18) then
          fu_LSU_in2_load_reg <= '1';
          socket_lsu_i1_bus_cntrl_reg <= conv_std_logic_vector(0, socket_lsu_i1_bus_cntrl_reg'length);
        else
          fu_LSU_in2_load_reg <= '0';
        end if;
        if (squash_GCU_LSU = '0' and conv_integer(unsigned(dst_GCU_LSU(5 downto 4))) = 2) then
          fu_ALU_1_1_in1t_load_reg <= '1';
          fu_ALU_1_1_opc_reg <= dst_GCU_LSU(3 downto 0);
          socket_ALU_i1_bus_cntrl_reg <= conv_std_logic_vector(3, socket_ALU_i1_bus_cntrl_reg'length);
        elsif (squash_PARAM = '0' and conv_integer(unsigned(dst_PARAM(5 downto 4))) = 0) then
          fu_ALU_1_1_in1t_load_reg <= '1';
          fu_ALU_1_1_opc_reg <= dst_PARAM(3 downto 0);
          socket_ALU_i1_bus_cntrl_reg <= conv_std_logic_vector(6, socket_ALU_i1_bus_cntrl_reg'length);
        elsif (squash_B1 = '0' and conv_integer(unsigned(dst_B1(5 downto 4))) = 0) then
          fu_ALU_1_1_in1t_load_reg <= '1';
          fu_ALU_1_1_opc_reg <= dst_B1(3 downto 0);
          socket_ALU_i1_bus_cntrl_reg <= conv_std_logic_vector(0, socket_ALU_i1_bus_cntrl_reg'length);
        elsif (squash_B2 = '0' and conv_integer(unsigned(dst_B2(5 downto 4))) = 0) then
          fu_ALU_1_1_in1t_load_reg <= '1';
          fu_ALU_1_1_opc_reg <= dst_B2(3 downto 0);
          socket_ALU_i1_bus_cntrl_reg <= conv_std_logic_vector(1, socket_ALU_i1_bus_cntrl_reg'length);
        elsif (squash_B3 = '0' and conv_integer(unsigned(dst_B3(5 downto 4))) = 0) then
          fu_ALU_1_1_in1t_load_reg <= '1';
          fu_ALU_1_1_opc_reg <= dst_B3(3 downto 0);
          socket_ALU_i1_bus_cntrl_reg <= conv_std_logic_vector(2, socket_ALU_i1_bus_cntrl_reg'length);
        elsif (squash_B3_1_1 = '0' and conv_integer(unsigned(dst_B3_1_1(6 downto 4))) = 2) then
          fu_ALU_1_1_in1t_load_reg <= '1';
          fu_ALU_1_1_opc_reg <= dst_B3_1_1(3 downto 0);
          socket_ALU_i1_bus_cntrl_reg <= conv_std_logic_vector(5, socket_ALU_i1_bus_cntrl_reg'length);
        elsif (squash_B3_1_2 = '0' and conv_integer(unsigned(dst_B3_1_2(6 downto 4))) = 2) then
          fu_ALU_1_1_in1t_load_reg <= '1';
          fu_ALU_1_1_opc_reg <= dst_B3_1_2(3 downto 0);
          socket_ALU_i1_bus_cntrl_reg <= conv_std_logic_vector(4, socket_ALU_i1_bus_cntrl_reg'length);
        else
          fu_ALU_1_1_in1t_load_reg <= '0';
        end if;
        if (squash_GCU_LSU = '0' and conv_integer(unsigned(dst_GCU_LSU(5 downto 1))) = 31) then
          fu_ALU_1_1_in2_load_reg <= '1';
          socket_ALU_i2_bus_cntrl_reg <= conv_std_logic_vector(3, socket_ALU_i2_bus_cntrl_reg'length);
        elsif (squash_PARAM = '0' and conv_integer(unsigned(dst_PARAM(5 downto 2))) = 9) then
          fu_ALU_1_1_in2_load_reg <= '1';
          socket_ALU_i2_bus_cntrl_reg <= conv_std_logic_vector(0, socket_ALU_i2_bus_cntrl_reg'length);
        elsif (squash_B1 = '0' and conv_integer(unsigned(dst_B1(5 downto 2))) = 10) then
          fu_ALU_1_1_in2_load_reg <= '1';
          socket_ALU_i2_bus_cntrl_reg <= conv_std_logic_vector(1, socket_ALU_i2_bus_cntrl_reg'length);
        elsif (squash_B2 = '0' and conv_integer(unsigned(dst_B2(5 downto 2))) = 10) then
          fu_ALU_1_1_in2_load_reg <= '1';
          socket_ALU_i2_bus_cntrl_reg <= conv_std_logic_vector(2, socket_ALU_i2_bus_cntrl_reg'length);
        elsif (squash_B3 = '0' and conv_integer(unsigned(dst_B3(5 downto 2))) = 10) then
          fu_ALU_1_1_in2_load_reg <= '1';
          socket_ALU_i2_bus_cntrl_reg <= conv_std_logic_vector(6, socket_ALU_i2_bus_cntrl_reg'length);
        elsif (squash_B3_1_1 = '0' and conv_integer(unsigned(dst_B3_1_1(6 downto 2))) = 20) then
          fu_ALU_1_1_in2_load_reg <= '1';
          socket_ALU_i2_bus_cntrl_reg <= conv_std_logic_vector(5, socket_ALU_i2_bus_cntrl_reg'length);
        elsif (squash_B3_1_2 = '0' and conv_integer(unsigned(dst_B3_1_2(6 downto 2))) = 21) then
          fu_ALU_1_1_in2_load_reg <= '1';
          socket_ALU_i2_bus_cntrl_reg <= conv_std_logic_vector(4, socket_ALU_i2_bus_cntrl_reg'length);
        else
          fu_ALU_1_1_in2_load_reg <= '0';
        end if;
        if (squash_GCU_LSU = '0' and conv_integer(unsigned(dst_GCU_LSU(5 downto 1))) = 28) then
          fu_gcu_pc_load_reg <= '1';
          fu_gcu_opc_reg <= dst_GCU_LSU(0 downto 0);
          socket_gcu_i1_bus_cntrl_reg <= conv_std_logic_vector(0, socket_gcu_i1_bus_cntrl_reg'length);
        elsif (squash_B3_1_2 = '0' and conv_integer(unsigned(dst_B3_1_2(6 downto 2))) = 20) then
          fu_gcu_pc_load_reg <= '1';
          fu_gcu_opc_reg <= dst_B3_1_2(0 downto 0);
          socket_gcu_i1_bus_cntrl_reg <= conv_std_logic_vector(1, socket_gcu_i1_bus_cntrl_reg'length);
        else
          fu_gcu_pc_load_reg <= '0';
        end if;
        if (squash_GCU_LSU = '0' and conv_integer(unsigned(dst_GCU_LSU(5 downto 1))) = 30) then
          fu_gcu_ra_load_reg <= '1';
          socket_gcu_i2_bus_cntrl_reg <= conv_std_logic_vector(0, socket_gcu_i2_bus_cntrl_reg'length);
        elsif (squash_B3_1_1 = '0' and conv_integer(unsigned(dst_B3_1_1(6 downto 2))) = 19) then
          fu_gcu_ra_load_reg <= '1';
          socket_gcu_i2_bus_cntrl_reg <= conv_std_logic_vector(1, socket_gcu_i2_bus_cntrl_reg'length);
        else
          fu_gcu_ra_load_reg <= '0';
        end if;
        -- control signals for RF inputs
        if (squash_GCU_LSU = '0' and conv_integer(unsigned(dst_GCU_LSU(5 downto 5))) = 0 and true) then
          rf_RF_wr_load_reg <= '1';
          rf_RF_wr_opc_reg <= dst_GCU_LSU(4 downto 0);
          socket_RF_i1_bus_cntrl_reg <= conv_std_logic_vector(3, socket_RF_i1_bus_cntrl_reg'length);
        elsif (squash_B4 = '0' and true and true) then
          rf_RF_wr_load_reg <= '1';
          rf_RF_wr_opc_reg <= dst_B4(4 downto 0);
          socket_RF_i1_bus_cntrl_reg <= conv_std_logic_vector(0, socket_RF_i1_bus_cntrl_reg'length);
        elsif (squash_B3_1_1 = '0' and conv_integer(unsigned(dst_B3_1_1(6 downto 5))) = 0 and true) then
          rf_RF_wr_load_reg <= '1';
          rf_RF_wr_opc_reg <= dst_B3_1_1(4 downto 0);
          socket_RF_i1_bus_cntrl_reg <= conv_std_logic_vector(1, socket_RF_i1_bus_cntrl_reg'length);
        elsif (squash_B3_1_2 = '0' and conv_integer(unsigned(dst_B3_1_2(6 downto 5))) = 0 and true) then
          rf_RF_wr_load_reg <= '1';
          rf_RF_wr_opc_reg <= dst_B3_1_2(4 downto 0);
          socket_RF_i1_bus_cntrl_reg <= conv_std_logic_vector(2, socket_RF_i1_bus_cntrl_reg'length);
        else
          rf_RF_wr_load_reg <= '0';
        end if;
        if (squash_B1 = '0' and conv_integer(unsigned(dst_B1(5 downto 2))) = 9 and true) then
          rf_BOOL_wr_load_reg <= '1';
          rf_BOOL_wr_opc_reg <= dst_B1(0 downto 0);
          socket_bool_i1_bus_cntrl_reg <= conv_std_logic_vector(0, socket_bool_i1_bus_cntrl_reg'length);
        elsif (squash_B2 = '0' and conv_integer(unsigned(dst_B2(5 downto 2))) = 9 and true) then
          rf_BOOL_wr_load_reg <= '1';
          rf_BOOL_wr_opc_reg <= dst_B2(0 downto 0);
          socket_bool_i1_bus_cntrl_reg <= conv_std_logic_vector(1, socket_bool_i1_bus_cntrl_reg'length);
        elsif (squash_B3 = '0' and conv_integer(unsigned(dst_B3(5 downto 2))) = 9 and true) then
          rf_BOOL_wr_load_reg <= '1';
          rf_BOOL_wr_opc_reg <= dst_B3(0 downto 0);
          socket_bool_i1_bus_cntrl_reg <= conv_std_logic_vector(2, socket_bool_i1_bus_cntrl_reg'length);
        elsif (squash_B3_1_1 = '0' and conv_integer(unsigned(dst_B3_1_1(6 downto 2))) = 17 and true) then
          rf_BOOL_wr_load_reg <= '1';
          rf_BOOL_wr_opc_reg <= dst_B3_1_1(0 downto 0);
          socket_bool_i1_bus_cntrl_reg <= conv_std_logic_vector(3, socket_bool_i1_bus_cntrl_reg'length);
        elsif (squash_B3_1_2 = '0' and conv_integer(unsigned(dst_B3_1_2(6 downto 2))) = 19 and true) then
          rf_BOOL_wr_load_reg <= '1';
          rf_BOOL_wr_opc_reg <= dst_B3_1_2(0 downto 0);
          socket_bool_i1_bus_cntrl_reg <= conv_std_logic_vector(4, socket_bool_i1_bus_cntrl_reg'length);
        else
          rf_BOOL_wr_load_reg <= '0';
        end if;
      end if;
    end if;
  end process;

  lock_reg_proc : process (clk, rstx)
  begin
    if (rstx = '0') then
      -- Locked during active reset      post_decode_merged_glock_r <= '1';
    elsif (clk'event and clk = '1') then
      post_decode_merged_glock_r <= post_decode_merged_glock;
    end if;
  end process lock_reg_proc;

  lock_r <= merged_glock_req;
  merged_glock_req <= lock_req(0) or lock_req(1) or lock_req(2) or lock_req(3) or lock_req(4) or lock_req(5) or lock_req(6);
  pre_decode_merged_glock <= lock or merged_glock_req;
  post_decode_merged_glock <= pre_decode_merged_glock or decode_fill_lock_reg;
  locked <= post_decode_merged_glock_r;
  glock(0) <= post_decode_merged_glock; -- to Streamout
  glock(1) <= post_decode_merged_glock; -- to Streamin
  glock(2) <= post_decode_merged_glock; -- to ALU2
  glock(3) <= post_decode_merged_glock; -- to Streamout_read
  glock(4) <= post_decode_merged_glock; -- to ALU_1
  glock(5) <= post_decode_merged_glock; -- to LSU
  glock(6) <= post_decode_merged_glock; -- to ALU_1_1
  glock(7) <= post_decode_merged_glock; -- to RF
  glock(8) <= post_decode_merged_glock; -- to BOOL
  glock(9) <= post_decode_merged_glock; -- to IU_1x32
  glock(10) <= post_decode_merged_glock;

  decode_pipeline_fill_lock: process (clk, rstx)
  begin
    if rstx = '0' then
      decode_fill_lock_reg <= '1';
    elsif clk'event and clk = '1' then
      if lock = '0' then
        decode_fill_lock_reg <= '0';
      end if;
    end if;
  end process decode_pipeline_fill_lock;

end rtl_andor;
