library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use work.tce_util.all;
use work.snappy_tta_globals.all;
use work.snappy_tta_imem_mau.all;
use work.snappy_tta_params.all;

entity snappy_tta is

  generic (
    core_id : integer := 0);

  port (
    clk : in std_logic;
    rstx : in std_logic;
    busy : in std_logic;
    imem_en_x : out std_logic;
    imem_addr : out std_logic_vector(IMEMADDRWIDTH-1 downto 0);
    imem_data : in std_logic_vector(IMEMWIDTHINMAUS*IMEMMAUWIDTH-1 downto 0);
    locked : out std_logic;
    fu_Stream_fu_in_valid : in std_logic_vector(0 downto 0);
    fu_Stream_fu_in_ready : out std_logic_vector(0 downto 0);
    fu_Stream_fu_in_data : in std_logic_vector(7 downto 0);
    fu_Stream_fu_in_cnt : in std_logic_vector(0 downto 0);
    fu_Stream_fu_in_last : in std_logic_vector(0 downto 0);
    fu_Stream_fu_out_valid : out std_logic_vector(0 downto 0);
    fu_Stream_fu_out_ready : in std_logic_vector(0 downto 0);
    fu_Stream_fu_out_dvalid : out std_logic_vector(0 downto 0);
    fu_Stream_fu_out_data : out std_logic_vector(7 downto 0);
    fu_Stream_fu_out_cnt : out std_logic_vector(0 downto 0);
    fu_Stream_fu_out_last : out std_logic_vector(0 downto 0);
    fu_LSU_avalid_out : out std_logic_vector(0 downto 0);
    fu_LSU_aready_in : in std_logic_vector(0 downto 0);
    fu_LSU_aaddr_out : out std_logic_vector(fu_LSU_addrw_g-2-1 downto 0);
    fu_LSU_awren_out : out std_logic_vector(0 downto 0);
    fu_LSU_astrb_out : out std_logic_vector(3 downto 0);
    fu_LSU_adata_out : out std_logic_vector(31 downto 0);
    fu_LSU_rvalid_in : in std_logic_vector(0 downto 0);
    fu_LSU_rready_out : out std_logic_vector(0 downto 0);
    fu_LSU_rdata_in : in std_logic_vector(31 downto 0);
    db_tta_nreset : in std_logic;
    db_lockcnt : out std_logic_vector(63 downto 0);
    db_cyclecnt : out std_logic_vector(63 downto 0);
    db_pc : out std_logic_vector(IMEMADDRWIDTH-1 downto 0);
    db_lockrq : in std_logic);

end snappy_tta;

architecture structural of snappy_tta is

  signal decomp_fetch_en_wire : std_logic;
  signal decomp_lock_wire : std_logic;
  signal decomp_fetchblock_wire : std_logic_vector(IMEMWIDTHINMAUS*IMEMMAUWIDTH-1 downto 0);
  signal decomp_instructionword_wire : std_logic_vector(INSTRUCTIONWIDTH-1 downto 0);
  signal decomp_glock_wire : std_logic;
  signal decomp_lock_r_wire : std_logic;
  signal fu_LSU_t1_address_in_wire : std_logic_vector(11 downto 0);
  signal fu_LSU_t1_load_in_wire : std_logic;
  signal fu_LSU_r1_data_out_wire : std_logic_vector(31 downto 0);
  signal fu_LSU_o1_data_in_wire : std_logic_vector(31 downto 0);
  signal fu_LSU_o1_load_in_wire : std_logic;
  signal fu_LSU_t1_opcode_in_wire : std_logic_vector(2 downto 0);
  signal fu_LSU_glock_in_wire : std_logic;
  signal fu_LSU_glockreq_out_wire : std_logic;
  signal fu_Stream_fu_t1_data_in_wire : std_logic_vector(31 downto 0);
  signal fu_Stream_fu_t1_load_in_wire : std_logic;
  signal fu_Stream_fu_o1_data_in_wire : std_logic_vector(31 downto 0);
  signal fu_Stream_fu_o1_load_in_wire : std_logic;
  signal fu_Stream_fu_r1_data_out_wire : std_logic_vector(7 downto 0);
  signal fu_Stream_fu_t1_opcode_in_wire : std_logic_vector(1 downto 0);
  signal fu_Stream_fu_glock_wire : std_logic;
  signal fu_Stream_fu_glockreq_wire : std_logic;
  signal fu_alu2_generated_glock_in_wire : std_logic;
  signal fu_alu2_generated_operation_in_wire : std_logic_vector(3-1 downto 0);
  signal fu_alu2_generated_glockreq_out_wire : std_logic;
  signal fu_alu2_generated_data_P1_in_wire : std_logic_vector(32-1 downto 0);
  signal fu_alu2_generated_load_P1_in_wire : std_logic;
  signal fu_alu2_generated_data_P2_in_wire : std_logic_vector(32-1 downto 0);
  signal fu_alu2_generated_load_P2_in_wire : std_logic;
  signal fu_alu2_generated_data_P3_out_wire : std_logic_vector(32-1 downto 0);
  signal fu_alu_1_1_generated_glock_in_wire : std_logic;
  signal fu_alu_1_1_generated_operation_in_wire : std_logic_vector(4-1 downto 0);
  signal fu_alu_1_1_generated_glockreq_out_wire : std_logic;
  signal fu_alu_1_1_generated_data_in1t_in_wire : std_logic_vector(32-1 downto 0);
  signal fu_alu_1_1_generated_load_in1t_in_wire : std_logic;
  signal fu_alu_1_1_generated_data_out1_out_wire : std_logic_vector(32-1 downto 0);
  signal fu_alu_1_1_generated_data_in2_in_wire : std_logic_vector(32-1 downto 0);
  signal fu_alu_1_1_generated_load_in2_in_wire : std_logic;
  signal fu_alu_1_generated_glock_in_wire : std_logic;
  signal fu_alu_1_generated_operation_in_wire : std_logic_vector(4-1 downto 0);
  signal fu_alu_1_generated_glockreq_out_wire : std_logic;
  signal fu_alu_1_generated_data_in1t_in_wire : std_logic_vector(32-1 downto 0);
  signal fu_alu_1_generated_load_in1t_in_wire : std_logic;
  signal fu_alu_1_generated_data_out1_out_wire : std_logic_vector(32-1 downto 0);
  signal fu_alu_1_generated_data_in2_in_wire : std_logic_vector(32-1 downto 0);
  signal fu_alu_1_generated_load_in2_in_wire : std_logic;
  signal ic_glock_wire : std_logic;
  signal ic_socket_lsu_i1_data_wire : std_logic_vector(31 downto 0);
  signal ic_socket_lsu_i1_bus_cntrl_wire : std_logic_vector(0 downto 0);
  signal ic_socket_lsu_i2_data_wire : std_logic_vector(11 downto 0);
  signal ic_socket_lsu_i2_bus_cntrl_wire : std_logic_vector(0 downto 0);
  signal ic_socket_RF_i1_data_wire : std_logic_vector(31 downto 0);
  signal ic_socket_RF_i1_bus_cntrl_wire : std_logic_vector(1 downto 0);
  signal ic_socket_gcu_i1_data_wire : std_logic_vector(IMEMADDRWIDTH-1 downto 0);
  signal ic_socket_gcu_i1_bus_cntrl_wire : std_logic_vector(0 downto 0);
  signal ic_socket_gcu_i2_data_wire : std_logic_vector(IMEMADDRWIDTH-1 downto 0);
  signal ic_socket_gcu_i2_bus_cntrl_wire : std_logic_vector(0 downto 0);
  signal ic_socket_ALU_i1_data_wire : std_logic_vector(31 downto 0);
  signal ic_socket_ALU_i1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal ic_socket_ALU_i2_data_wire : std_logic_vector(31 downto 0);
  signal ic_socket_ALU_i2_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal ic_socket_Streamout_i1_data_wire : std_logic_vector(31 downto 0);
  signal ic_socket_Streamout_i1_bus_cntrl_wire : std_logic_vector(1 downto 0);
  signal ic_socket_ALU2_i1_data_wire : std_logic_vector(31 downto 0);
  signal ic_socket_ALU2_i1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal ic_socket_ALU2_i2_data_wire : std_logic_vector(31 downto 0);
  signal ic_socket_ALU2_i2_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal ic_socket_ALU_i1_1_data_wire : std_logic_vector(31 downto 0);
  signal ic_socket_ALU_i1_1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal ic_socket_ALU_i1_2_data_wire : std_logic_vector(31 downto 0);
  signal ic_socket_ALU_i1_2_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal ic_socket_Streamout_i1_1_1_data_wire : std_logic_vector(31 downto 0);
  signal ic_socket_Streamout_i1_1_1_bus_cntrl_wire : std_logic_vector(0 downto 0);
  signal ic_socket_gcu_o1_1_data_wire : std_logic_vector(31 downto 0);
  signal ic_socket_gcu_o1_1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal ic_socket_gcu_o1_1_1_data_wire : std_logic_vector(31 downto 0);
  signal ic_socket_gcu_o1_1_1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal ic_GCU_LSU_mux_ctrl_in_wire : std_logic_vector(3 downto 0);
  signal ic_GCU_LSU_data_0_in_wire : std_logic_vector(31 downto 0);
  signal ic_GCU_LSU_data_1_in_wire : std_logic_vector(31 downto 0);
  signal ic_GCU_LSU_data_2_in_wire : std_logic_vector(IMEMADDRWIDTH-1 downto 0);
  signal ic_GCU_LSU_data_3_in_wire : std_logic_vector(32-1 downto 0);
  signal ic_GCU_LSU_data_4_in_wire : std_logic_vector(31 downto 0);
  signal ic_GCU_LSU_data_5_in_wire : std_logic_vector(7 downto 0);
  signal ic_GCU_LSU_data_6_in_wire : std_logic_vector(32-1 downto 0);
  signal ic_GCU_LSU_data_7_in_wire : std_logic_vector(32-1 downto 0);
  signal ic_PARAM_mux_ctrl_in_wire : std_logic_vector(1 downto 0);
  signal ic_PARAM_data_0_in_wire : std_logic_vector(31 downto 0);
  signal ic_PARAM_data_1_in_wire : std_logic_vector(31 downto 0);
  signal ic_PARAM_data_2_in_wire : std_logic_vector(7 downto 0);
  signal ic_B1_mux_ctrl_in_wire : std_logic_vector(0 downto 0);
  signal ic_B1_data_0_in_wire : std_logic_vector(32-1 downto 0);
  signal ic_B2_mux_ctrl_in_wire : std_logic_vector(0 downto 0);
  signal ic_B2_data_0_in_wire : std_logic_vector(32-1 downto 0);
  signal ic_B3_mux_ctrl_in_wire : std_logic_vector(0 downto 0);
  signal ic_B3_data_0_in_wire : std_logic_vector(32-1 downto 0);
  signal ic_B4_mux_ctrl_in_wire : std_logic_vector(2 downto 0);
  signal ic_B4_data_0_in_wire : std_logic_vector(IMEMADDRWIDTH-1 downto 0);
  signal ic_B4_data_1_in_wire : std_logic_vector(32-1 downto 0);
  signal ic_B4_data_2_in_wire : std_logic_vector(31 downto 0);
  signal ic_B4_data_3_in_wire : std_logic_vector(7 downto 0);
  signal ic_B4_data_4_in_wire : std_logic_vector(32-1 downto 0);
  signal ic_B4_data_5_in_wire : std_logic_vector(32-1 downto 0);
  signal ic_B3_1_1_mux_ctrl_in_wire : std_logic_vector(1 downto 0);
  signal ic_B3_1_1_data_0_in_wire : std_logic_vector(31 downto 0);
  signal ic_B3_1_1_data_1_in_wire : std_logic_vector(31 downto 0);
  signal ic_B3_1_1_data_2_in_wire : std_logic_vector(31 downto 0);
  signal ic_B3_1_2_mux_ctrl_in_wire : std_logic_vector(0 downto 0);
  signal ic_B3_1_2_data_0_in_wire : std_logic_vector(31 downto 0);
  signal ic_B3_1_2_data_1_in_wire : std_logic_vector(31 downto 0);
  signal ic_simm_GCU_LSU_wire : std_logic_vector(31 downto 0);
  signal ic_simm_cntrl_GCU_LSU_wire : std_logic_vector(0 downto 0);
  signal ic_simm_PARAM_wire : std_logic_vector(31 downto 0);
  signal ic_simm_cntrl_PARAM_wire : std_logic_vector(0 downto 0);
  signal ic_simm_B1_wire : std_logic_vector(31 downto 0);
  signal ic_simm_cntrl_B1_wire : std_logic_vector(0 downto 0);
  signal ic_simm_B2_wire : std_logic_vector(31 downto 0);
  signal ic_simm_cntrl_B2_wire : std_logic_vector(0 downto 0);
  signal ic_simm_B3_wire : std_logic_vector(2 downto 0);
  signal ic_simm_cntrl_B3_wire : std_logic_vector(0 downto 0);
  signal ic_simm_B3_1_1_wire : std_logic_vector(31 downto 0);
  signal ic_simm_cntrl_B3_1_1_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_instructionword_wire : std_logic_vector(INSTRUCTIONWIDTH-1 downto 0);
  signal inst_decoder_pc_load_wire : std_logic;
  signal inst_decoder_ra_load_wire : std_logic;
  signal inst_decoder_pc_opcode_wire : std_logic_vector(3 downto 0);
  signal inst_decoder_lock_wire : std_logic;
  signal inst_decoder_lock_r_wire : std_logic;
  signal inst_decoder_simm_GCU_LSU_wire : std_logic_vector(31 downto 0);
  signal inst_decoder_simm_PARAM_wire : std_logic_vector(31 downto 0);
  signal inst_decoder_simm_B1_wire : std_logic_vector(31 downto 0);
  signal inst_decoder_simm_B2_wire : std_logic_vector(31 downto 0);
  signal inst_decoder_simm_B3_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_simm_B3_1_1_wire : std_logic_vector(31 downto 0);
  signal inst_decoder_socket_lsu_i1_bus_cntrl_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_socket_lsu_i2_bus_cntrl_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_socket_RF_i1_bus_cntrl_wire : std_logic_vector(1 downto 0);
  signal inst_decoder_socket_gcu_i1_bus_cntrl_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_socket_gcu_i2_bus_cntrl_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_socket_ALU_i1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_socket_ALU_i2_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_socket_Streamout_i1_bus_cntrl_wire : std_logic_vector(1 downto 0);
  signal inst_decoder_socket_ALU2_i1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_socket_ALU2_i2_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_socket_ALU_i1_1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_socket_ALU_i1_2_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_socket_Streamout_i1_1_1_bus_cntrl_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_socket_gcu_o1_1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_socket_gcu_o1_1_1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_GCU_LSU_src_sel_wire : std_logic_vector(3 downto 0);
  signal inst_decoder_PARAM_src_sel_wire : std_logic_vector(1 downto 0);
  signal inst_decoder_B1_src_sel_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_B2_src_sel_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_B3_src_sel_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_B4_src_sel_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_B3_1_1_src_sel_wire : std_logic_vector(1 downto 0);
  signal inst_decoder_B3_1_2_src_sel_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_fu_Stream_fu_t1_load_wire : std_logic;
  signal inst_decoder_fu_Stream_fu_o1_load_wire : std_logic;
  signal inst_decoder_fu_Stream_fu_opc_wire : std_logic_vector(1 downto 0);
  signal inst_decoder_fu_ALU2_P1_load_wire : std_logic;
  signal inst_decoder_fu_ALU2_P2_load_wire : std_logic;
  signal inst_decoder_fu_ALU2_opc_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_fu_ALU_1_in1t_load_wire : std_logic;
  signal inst_decoder_fu_ALU_1_in2_load_wire : std_logic;
  signal inst_decoder_fu_ALU_1_opc_wire : std_logic_vector(3 downto 0);
  signal inst_decoder_fu_LSU_in1t_load_wire : std_logic;
  signal inst_decoder_fu_LSU_in2_load_wire : std_logic;
  signal inst_decoder_fu_LSU_opc_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_fu_ALU_1_1_in1t_load_wire : std_logic;
  signal inst_decoder_fu_ALU_1_1_in2_load_wire : std_logic;
  signal inst_decoder_fu_ALU_1_1_opc_wire : std_logic_vector(3 downto 0);
  signal inst_decoder_fu_gcu_cond_load_wire : std_logic;
  signal inst_decoder_fu_gcu_comp_load_wire : std_logic;
  signal inst_decoder_rf_RF_wr_load_wire : std_logic;
  signal inst_decoder_rf_RF_wr_opc_wire : std_logic_vector(4 downto 0);
  signal inst_decoder_rf_RF_rd_load_wire : std_logic;
  signal inst_decoder_rf_RF_rd_opc_wire : std_logic_vector(4 downto 0);
  signal inst_decoder_rf_RF_rd2_load_wire : std_logic;
  signal inst_decoder_rf_RF_rd2_opc_wire : std_logic_vector(4 downto 0);
  signal inst_decoder_iu_IU_1x32_r0_read_load_wire : std_logic;
  signal inst_decoder_iu_IU_1x32_r0_read_opc_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_iu_IU_1x32_write_wire : std_logic_vector(31 downto 0);
  signal inst_decoder_iu_IU_1x32_write_load_wire : std_logic;
  signal inst_decoder_iu_IU_1x32_write_opc_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_lock_req_wire : std_logic_vector(5 downto 0);
  signal inst_decoder_glock_wire : std_logic_vector(7 downto 0);
  signal inst_fetch_ra_out_wire : std_logic_vector(IMEMADDRWIDTH-1 downto 0);
  signal inst_fetch_ra_in_wire : std_logic_vector(IMEMADDRWIDTH-1 downto 0);
  signal inst_fetch_pc_in_wire : std_logic_vector(IMEMADDRWIDTH-1 downto 0);
  signal inst_fetch_pc_load_wire : std_logic;
  signal inst_fetch_ra_load_wire : std_logic;
  signal inst_fetch_pc_opcode_wire : std_logic_vector(3 downto 0);
  signal inst_fetch_fetch_en_wire : std_logic;
  signal inst_fetch_glock_wire : std_logic;
  signal inst_fetch_fetchblock_wire : std_logic_vector(IMEMWIDTHINMAUS*IMEMMAUWIDTH-1 downto 0);
  signal inst_fetch_cond_in_wire : std_logic_vector(32-1 downto 0);
  signal inst_fetch_cond_load_wire : std_logic;
  signal inst_fetch_comp_data_wire : std_logic_vector(32-1 downto 0);
  signal inst_fetch_comp_load_wire : std_logic;
  signal iu_IU_1x32_data_rd_out_wire : std_logic_vector(31 downto 0);
  signal iu_IU_1x32_load_rd_in_wire : std_logic;
  signal iu_IU_1x32_addr_rd_in_wire : std_logic_vector(0 downto 0);
  signal iu_IU_1x32_data_wr_in_wire : std_logic_vector(31 downto 0);
  signal iu_IU_1x32_load_wr_in_wire : std_logic;
  signal iu_IU_1x32_addr_wr_in_wire : std_logic_vector(0 downto 0);
  signal iu_IU_1x32_glock_in_wire : std_logic;
  signal rf_RF_data_rd_a_out_wire : std_logic_vector(31 downto 0);
  signal rf_RF_load_rd_a_in_wire : std_logic;
  signal rf_RF_addr_rd_a_in_wire : std_logic_vector(4 downto 0);
  signal rf_RF_data_rd_b_out_wire : std_logic_vector(31 downto 0);
  signal rf_RF_load_rd_b_in_wire : std_logic;
  signal rf_RF_addr_rd_b_in_wire : std_logic_vector(4 downto 0);
  signal rf_RF_data_wr_in_wire : std_logic_vector(31 downto 0);
  signal rf_RF_load_wr_in_wire : std_logic;
  signal rf_RF_addr_wr_in_wire : std_logic_vector(4 downto 0);
  signal rf_RF_glock_in_wire : std_logic;
  signal ground_signal : std_logic_vector(0 downto 0);

  component snappy_tta_ifetch is
    generic (
      debug_logic_g : boolean;
      bypass_pc_register : boolean);
    port (
      clk : in std_logic;
      rstx : in std_logic;
      ra_out : out std_logic_vector(IMEMADDRWIDTH-1 downto 0);
      ra_in : in std_logic_vector(IMEMADDRWIDTH-1 downto 0);
      busy : in std_logic;
      imem_en_x : out std_logic;
      imem_addr : out std_logic_vector(IMEMADDRWIDTH-1 downto 0);
      imem_data : in std_logic_vector(IMEMWIDTHINMAUS*IMEMMAUWIDTH-1 downto 0);
      pc_in : in std_logic_vector(IMEMADDRWIDTH-1 downto 0);
      pc_load : in std_logic;
      ra_load : in std_logic;
      pc_opcode : in std_logic_vector(4-1 downto 0);
      fetch_en : in std_logic;
      glock : out std_logic;
      fetchblock : out std_logic_vector(IMEMWIDTHINMAUS*IMEMMAUWIDTH-1 downto 0);
      cond_in : in std_logic_vector(32-1 downto 0);
      cond_load : in std_logic;
      comp_data : in std_logic_vector(32-1 downto 0);
      comp_load : in std_logic;
      db_rstx : in std_logic;
      db_lockreq : in std_logic;
      db_cyclecnt : out std_logic_vector(64-1 downto 0);
      db_lockcnt : out std_logic_vector(64-1 downto 0);
      db_pc : out std_logic_vector(IMEMADDRWIDTH-1 downto 0));
  end component;

  component snappy_tta_decompressor is
    port (
      fetch_en : out std_logic;
      lock : in std_logic;
      fetchblock : in std_logic_vector(IMEMWIDTHINMAUS*IMEMMAUWIDTH-1 downto 0);
      clk : in std_logic;
      rstx : in std_logic;
      instructionword : out std_logic_vector(INSTRUCTIONWIDTH-1 downto 0);
      glock : out std_logic;
      lock_r : in std_logic);
  end component;

  component snappy_tta_decoder is
    port (
      instructionword : in std_logic_vector(INSTRUCTIONWIDTH-1 downto 0);
      pc_load : out std_logic;
      ra_load : out std_logic;
      pc_opcode : out std_logic_vector(4-1 downto 0);
      lock : in std_logic;
      lock_r : out std_logic;
      clk : in std_logic;
      rstx : in std_logic;
      locked : out std_logic;
      simm_GCU_LSU : out std_logic_vector(32-1 downto 0);
      simm_PARAM : out std_logic_vector(32-1 downto 0);
      simm_B1 : out std_logic_vector(32-1 downto 0);
      simm_B2 : out std_logic_vector(32-1 downto 0);
      simm_B3 : out std_logic_vector(3-1 downto 0);
      simm_B3_1_1 : out std_logic_vector(32-1 downto 0);
      socket_lsu_i1_bus_cntrl : out std_logic_vector(1-1 downto 0);
      socket_lsu_i2_bus_cntrl : out std_logic_vector(1-1 downto 0);
      socket_RF_i1_bus_cntrl : out std_logic_vector(2-1 downto 0);
      socket_gcu_i1_bus_cntrl : out std_logic_vector(1-1 downto 0);
      socket_gcu_i2_bus_cntrl : out std_logic_vector(1-1 downto 0);
      socket_ALU_i1_bus_cntrl : out std_logic_vector(3-1 downto 0);
      socket_ALU_i2_bus_cntrl : out std_logic_vector(3-1 downto 0);
      socket_Streamout_i1_bus_cntrl : out std_logic_vector(2-1 downto 0);
      socket_ALU2_i1_bus_cntrl : out std_logic_vector(3-1 downto 0);
      socket_ALU2_i2_bus_cntrl : out std_logic_vector(3-1 downto 0);
      socket_ALU_i1_1_bus_cntrl : out std_logic_vector(3-1 downto 0);
      socket_ALU_i1_2_bus_cntrl : out std_logic_vector(3-1 downto 0);
      socket_Streamout_i1_1_1_bus_cntrl : out std_logic_vector(1-1 downto 0);
      socket_gcu_o1_1_bus_cntrl : out std_logic_vector(3-1 downto 0);
      socket_gcu_o1_1_1_bus_cntrl : out std_logic_vector(3-1 downto 0);
      GCU_LSU_src_sel : out std_logic_vector(4-1 downto 0);
      PARAM_src_sel : out std_logic_vector(2-1 downto 0);
      B1_src_sel : out std_logic_vector(1-1 downto 0);
      B2_src_sel : out std_logic_vector(1-1 downto 0);
      B3_src_sel : out std_logic_vector(1-1 downto 0);
      B4_src_sel : out std_logic_vector(3-1 downto 0);
      B3_1_1_src_sel : out std_logic_vector(2-1 downto 0);
      B3_1_2_src_sel : out std_logic_vector(1-1 downto 0);
      fu_Stream_fu_t1_load : out std_logic;
      fu_Stream_fu_o1_load : out std_logic;
      fu_Stream_fu_opc : out std_logic_vector(2-1 downto 0);
      fu_ALU2_P1_load : out std_logic;
      fu_ALU2_P2_load : out std_logic;
      fu_ALU2_opc : out std_logic_vector(3-1 downto 0);
      fu_ALU_1_in1t_load : out std_logic;
      fu_ALU_1_in2_load : out std_logic;
      fu_ALU_1_opc : out std_logic_vector(4-1 downto 0);
      fu_LSU_in1t_load : out std_logic;
      fu_LSU_in2_load : out std_logic;
      fu_LSU_opc : out std_logic_vector(3-1 downto 0);
      fu_ALU_1_1_in1t_load : out std_logic;
      fu_ALU_1_1_in2_load : out std_logic;
      fu_ALU_1_1_opc : out std_logic_vector(4-1 downto 0);
      fu_gcu_cond_load : out std_logic;
      fu_gcu_comp_load : out std_logic;
      rf_RF_wr_load : out std_logic;
      rf_RF_wr_opc : out std_logic_vector(5-1 downto 0);
      rf_RF_rd_load : out std_logic;
      rf_RF_rd_opc : out std_logic_vector(5-1 downto 0);
      rf_RF_rd2_load : out std_logic;
      rf_RF_rd2_opc : out std_logic_vector(5-1 downto 0);
      iu_IU_1x32_r0_read_load : out std_logic;
      iu_IU_1x32_r0_read_opc : out std_logic_vector(0 downto 0);
      iu_IU_1x32_write : out std_logic_vector(32-1 downto 0);
      iu_IU_1x32_write_load : out std_logic;
      iu_IU_1x32_write_opc : out std_logic_vector(0 downto 0);
      lock_req : in std_logic_vector(6-1 downto 0);
      glock : out std_logic_vector(8-1 downto 0);
      db_tta_nreset : in std_logic);
  end component;

  component fu_alu2 is
    port (
      clk : in std_logic;
      rstx : in std_logic;
      glock_in : in std_logic;
      operation_in : in std_logic_vector(3-1 downto 0);
      glockreq_out : out std_logic;
      data_P1_in : in std_logic_vector(32-1 downto 0);
      load_P1_in : in std_logic;
      data_P2_in : in std_logic_vector(32-1 downto 0);
      load_P2_in : in std_logic;
      data_P3_out : out std_logic_vector(32-1 downto 0));
  end component;

  component fu_alu_1 is
    port (
      clk : in std_logic;
      rstx : in std_logic;
      glock_in : in std_logic;
      operation_in : in std_logic_vector(4-1 downto 0);
      glockreq_out : out std_logic;
      data_in1t_in : in std_logic_vector(32-1 downto 0);
      load_in1t_in : in std_logic;
      data_out1_out : out std_logic_vector(32-1 downto 0);
      data_in2_in : in std_logic_vector(32-1 downto 0);
      load_in2_in : in std_logic);
  end component;

  component fu_alu_1_1 is
    port (
      clk : in std_logic;
      rstx : in std_logic;
      glock_in : in std_logic;
      operation_in : in std_logic_vector(4-1 downto 0);
      glockreq_out : out std_logic;
      data_in1t_in : in std_logic_vector(32-1 downto 0);
      load_in1t_in : in std_logic;
      data_out1_out : out std_logic_vector(32-1 downto 0);
      data_in2_in : in std_logic_vector(32-1 downto 0);
      load_in2_in : in std_logic);
  end component;

  component fu_unistream is
    port (
      t1_data_in : in std_logic_vector(32-1 downto 0);
      t1_load_in : in std_logic;
      o1_data_in : in std_logic_vector(32-1 downto 0);
      o1_load_in : in std_logic;
      r1_data_out : out std_logic_vector(8-1 downto 0);
      t1_opcode_in : in std_logic_vector(2-1 downto 0);
      in_valid : in std_logic_vector(1-1 downto 0);
      in_ready : out std_logic_vector(1-1 downto 0);
      in_data : in std_logic_vector(8-1 downto 0);
      in_cnt : in std_logic_vector(1-1 downto 0);
      in_last : in std_logic_vector(1-1 downto 0);
      out_valid : out std_logic_vector(1-1 downto 0);
      out_ready : in std_logic_vector(1-1 downto 0);
      out_dvalid : out std_logic_vector(1-1 downto 0);
      out_data : out std_logic_vector(8-1 downto 0);
      out_cnt : out std_logic_vector(1-1 downto 0);
      out_last : out std_logic_vector(1-1 downto 0);
      clk : in std_logic;
      rstx : in std_logic;
      glock : in std_logic;
      glockreq : out std_logic);
  end component;

  component fu_lsu_32b_slim is
    generic (
      addrw_g : integer;
      register_bypass_g : integer;
      little_endian_g : integer);
    port (
      t1_address_in : in std_logic_vector(addrw_g-1 downto 0);
      t1_load_in : in std_logic;
      r1_data_out : out std_logic_vector(32-1 downto 0);
      o1_data_in : in std_logic_vector(32-1 downto 0);
      o1_load_in : in std_logic;
      t1_opcode_in : in std_logic_vector(3-1 downto 0);
      avalid_out : out std_logic_vector(1-1 downto 0);
      aready_in : in std_logic_vector(1-1 downto 0);
      aaddr_out : out std_logic_vector(addrw_g-2-1 downto 0);
      awren_out : out std_logic_vector(1-1 downto 0);
      astrb_out : out std_logic_vector(4-1 downto 0);
      adata_out : out std_logic_vector(32-1 downto 0);
      rvalid_in : in std_logic_vector(1-1 downto 0);
      rready_out : out std_logic_vector(1-1 downto 0);
      rdata_in : in std_logic_vector(32-1 downto 0);
      clk : in std_logic;
      rstx : in std_logic;
      glock_in : in std_logic;
      glockreq_out : out std_logic);
  end component;

  component s7_rf_1wr_2rd is
    generic (
      width_g : integer;
      depth_g : integer);
    port (
      data_rd_a_out : out std_logic_vector(width_g-1 downto 0);
      load_rd_a_in : in std_logic;
      addr_rd_a_in : in std_logic_vector(bit_width(depth_g)-1 downto 0);
      data_rd_b_out : out std_logic_vector(width_g-1 downto 0);
      load_rd_b_in : in std_logic;
      addr_rd_b_in : in std_logic_vector(bit_width(depth_g)-1 downto 0);
      data_wr_in : in std_logic_vector(width_g-1 downto 0);
      load_wr_in : in std_logic;
      addr_wr_in : in std_logic_vector(bit_width(depth_g)-1 downto 0);
      clk : in std_logic;
      rstx : in std_logic;
      glock_in : in std_logic);
  end component;

  component s7_rf_1wr_1rd is
    generic (
      width_g : integer;
      depth_g : integer);
    port (
      data_rd_out : out std_logic_vector(width_g-1 downto 0);
      load_rd_in : in std_logic;
      addr_rd_in : in std_logic_vector(bit_width(depth_g)-1 downto 0);
      data_wr_in : in std_logic_vector(width_g-1 downto 0);
      load_wr_in : in std_logic;
      addr_wr_in : in std_logic_vector(bit_width(depth_g)-1 downto 0);
      clk : in std_logic;
      rstx : in std_logic;
      glock_in : in std_logic);
  end component;

  component snappy_tta_interconn is
    port (
      clk : in std_logic;
      rstx : in std_logic;
      glock : in std_logic;
      socket_lsu_i1_data : out std_logic_vector(32-1 downto 0);
      socket_lsu_i1_bus_cntrl : in std_logic_vector(1-1 downto 0);
      socket_lsu_i2_data : out std_logic_vector(12-1 downto 0);
      socket_lsu_i2_bus_cntrl : in std_logic_vector(1-1 downto 0);
      socket_RF_i1_data : out std_logic_vector(32-1 downto 0);
      socket_RF_i1_bus_cntrl : in std_logic_vector(2-1 downto 0);
      socket_gcu_i1_data : out std_logic_vector(IMEMADDRWIDTH-1 downto 0);
      socket_gcu_i1_bus_cntrl : in std_logic_vector(1-1 downto 0);
      socket_gcu_i2_data : out std_logic_vector(IMEMADDRWIDTH-1 downto 0);
      socket_gcu_i2_bus_cntrl : in std_logic_vector(1-1 downto 0);
      socket_ALU_i1_data : out std_logic_vector(32-1 downto 0);
      socket_ALU_i1_bus_cntrl : in std_logic_vector(3-1 downto 0);
      socket_ALU_i2_data : out std_logic_vector(32-1 downto 0);
      socket_ALU_i2_bus_cntrl : in std_logic_vector(3-1 downto 0);
      socket_Streamout_i1_data : out std_logic_vector(32-1 downto 0);
      socket_Streamout_i1_bus_cntrl : in std_logic_vector(2-1 downto 0);
      socket_ALU2_i1_data : out std_logic_vector(32-1 downto 0);
      socket_ALU2_i1_bus_cntrl : in std_logic_vector(3-1 downto 0);
      socket_ALU2_i2_data : out std_logic_vector(32-1 downto 0);
      socket_ALU2_i2_bus_cntrl : in std_logic_vector(3-1 downto 0);
      socket_ALU_i1_1_data : out std_logic_vector(32-1 downto 0);
      socket_ALU_i1_1_bus_cntrl : in std_logic_vector(3-1 downto 0);
      socket_ALU_i1_2_data : out std_logic_vector(32-1 downto 0);
      socket_ALU_i1_2_bus_cntrl : in std_logic_vector(3-1 downto 0);
      socket_Streamout_i1_1_1_data : out std_logic_vector(32-1 downto 0);
      socket_Streamout_i1_1_1_bus_cntrl : in std_logic_vector(1-1 downto 0);
      socket_gcu_o1_1_data : out std_logic_vector(32-1 downto 0);
      socket_gcu_o1_1_bus_cntrl : in std_logic_vector(3-1 downto 0);
      socket_gcu_o1_1_1_data : out std_logic_vector(32-1 downto 0);
      socket_gcu_o1_1_1_bus_cntrl : in std_logic_vector(3-1 downto 0);
      GCU_LSU_mux_ctrl_in : in std_logic_vector(4-1 downto 0);
      GCU_LSU_data_0_in : in std_logic_vector(32-1 downto 0);
      GCU_LSU_data_1_in : in std_logic_vector(32-1 downto 0);
      GCU_LSU_data_2_in : in std_logic_vector(IMEMADDRWIDTH-1 downto 0);
      GCU_LSU_data_3_in : in std_logic_vector(32-1 downto 0);
      GCU_LSU_data_4_in : in std_logic_vector(32-1 downto 0);
      GCU_LSU_data_5_in : in std_logic_vector(8-1 downto 0);
      GCU_LSU_data_6_in : in std_logic_vector(32-1 downto 0);
      GCU_LSU_data_7_in : in std_logic_vector(32-1 downto 0);
      PARAM_mux_ctrl_in : in std_logic_vector(2-1 downto 0);
      PARAM_data_0_in : in std_logic_vector(32-1 downto 0);
      PARAM_data_1_in : in std_logic_vector(32-1 downto 0);
      PARAM_data_2_in : in std_logic_vector(8-1 downto 0);
      B1_mux_ctrl_in : in std_logic_vector(1-1 downto 0);
      B1_data_0_in : in std_logic_vector(32-1 downto 0);
      B2_mux_ctrl_in : in std_logic_vector(1-1 downto 0);
      B2_data_0_in : in std_logic_vector(32-1 downto 0);
      B3_mux_ctrl_in : in std_logic_vector(1-1 downto 0);
      B3_data_0_in : in std_logic_vector(32-1 downto 0);
      B4_mux_ctrl_in : in std_logic_vector(3-1 downto 0);
      B4_data_0_in : in std_logic_vector(IMEMADDRWIDTH-1 downto 0);
      B4_data_1_in : in std_logic_vector(32-1 downto 0);
      B4_data_2_in : in std_logic_vector(32-1 downto 0);
      B4_data_3_in : in std_logic_vector(8-1 downto 0);
      B4_data_4_in : in std_logic_vector(32-1 downto 0);
      B4_data_5_in : in std_logic_vector(32-1 downto 0);
      B3_1_1_mux_ctrl_in : in std_logic_vector(2-1 downto 0);
      B3_1_1_data_0_in : in std_logic_vector(32-1 downto 0);
      B3_1_1_data_1_in : in std_logic_vector(32-1 downto 0);
      B3_1_1_data_2_in : in std_logic_vector(32-1 downto 0);
      B3_1_2_mux_ctrl_in : in std_logic_vector(1-1 downto 0);
      B3_1_2_data_0_in : in std_logic_vector(32-1 downto 0);
      B3_1_2_data_1_in : in std_logic_vector(32-1 downto 0);
      simm_GCU_LSU : in std_logic_vector(32-1 downto 0);
      simm_cntrl_GCU_LSU : in std_logic_vector(1-1 downto 0);
      simm_PARAM : in std_logic_vector(32-1 downto 0);
      simm_cntrl_PARAM : in std_logic_vector(1-1 downto 0);
      simm_B1 : in std_logic_vector(32-1 downto 0);
      simm_cntrl_B1 : in std_logic_vector(1-1 downto 0);
      simm_B2 : in std_logic_vector(32-1 downto 0);
      simm_cntrl_B2 : in std_logic_vector(1-1 downto 0);
      simm_B3 : in std_logic_vector(3-1 downto 0);
      simm_cntrl_B3 : in std_logic_vector(1-1 downto 0);
      simm_B3_1_1 : in std_logic_vector(32-1 downto 0);
      simm_cntrl_B3_1_1 : in std_logic_vector(1-1 downto 0));
  end component;


begin

  ic_GCU_LSU_data_2_in_wire <= inst_fetch_ra_out_wire;
  ic_B4_data_0_in_wire <= inst_fetch_ra_out_wire;
  inst_fetch_ra_in_wire <= ic_socket_gcu_i2_data_wire;
  inst_fetch_pc_in_wire <= ic_socket_gcu_i1_data_wire;
  inst_fetch_pc_load_wire <= inst_decoder_pc_load_wire;
  inst_fetch_ra_load_wire <= inst_decoder_ra_load_wire;
  inst_fetch_pc_opcode_wire <= inst_decoder_pc_opcode_wire;
  inst_fetch_fetch_en_wire <= decomp_fetch_en_wire;
  decomp_lock_wire <= inst_fetch_glock_wire;
  decomp_fetchblock_wire <= inst_fetch_fetchblock_wire;
  inst_fetch_cond_in_wire <= ic_socket_gcu_o1_1_data_wire;
  inst_fetch_cond_load_wire <= inst_decoder_fu_gcu_cond_load_wire;
  inst_fetch_comp_data_wire <= ic_socket_gcu_o1_1_1_data_wire;
  inst_fetch_comp_load_wire <= inst_decoder_fu_gcu_comp_load_wire;
  inst_decoder_instructionword_wire <= decomp_instructionword_wire;
  inst_decoder_lock_wire <= decomp_glock_wire;
  decomp_lock_r_wire <= inst_decoder_lock_r_wire;
  ic_simm_GCU_LSU_wire <= inst_decoder_simm_GCU_LSU_wire;
  ic_simm_PARAM_wire <= inst_decoder_simm_PARAM_wire;
  ic_simm_B1_wire <= inst_decoder_simm_B1_wire;
  ic_simm_B2_wire <= inst_decoder_simm_B2_wire;
  ic_simm_B3_wire <= inst_decoder_simm_B3_wire;
  ic_simm_B3_1_1_wire <= inst_decoder_simm_B3_1_1_wire;
  ic_socket_lsu_i1_bus_cntrl_wire <= inst_decoder_socket_lsu_i1_bus_cntrl_wire;
  ic_socket_lsu_i2_bus_cntrl_wire <= inst_decoder_socket_lsu_i2_bus_cntrl_wire;
  ic_socket_RF_i1_bus_cntrl_wire <= inst_decoder_socket_RF_i1_bus_cntrl_wire;
  ic_socket_gcu_i1_bus_cntrl_wire <= inst_decoder_socket_gcu_i1_bus_cntrl_wire;
  ic_socket_gcu_i2_bus_cntrl_wire <= inst_decoder_socket_gcu_i2_bus_cntrl_wire;
  ic_socket_ALU_i1_bus_cntrl_wire <= inst_decoder_socket_ALU_i1_bus_cntrl_wire;
  ic_socket_ALU_i2_bus_cntrl_wire <= inst_decoder_socket_ALU_i2_bus_cntrl_wire;
  ic_socket_Streamout_i1_bus_cntrl_wire <= inst_decoder_socket_Streamout_i1_bus_cntrl_wire;
  ic_socket_ALU2_i1_bus_cntrl_wire <= inst_decoder_socket_ALU2_i1_bus_cntrl_wire;
  ic_socket_ALU2_i2_bus_cntrl_wire <= inst_decoder_socket_ALU2_i2_bus_cntrl_wire;
  ic_socket_ALU_i1_1_bus_cntrl_wire <= inst_decoder_socket_ALU_i1_1_bus_cntrl_wire;
  ic_socket_ALU_i1_2_bus_cntrl_wire <= inst_decoder_socket_ALU_i1_2_bus_cntrl_wire;
  ic_socket_Streamout_i1_1_1_bus_cntrl_wire <= inst_decoder_socket_Streamout_i1_1_1_bus_cntrl_wire;
  ic_socket_gcu_o1_1_bus_cntrl_wire <= inst_decoder_socket_gcu_o1_1_bus_cntrl_wire;
  ic_socket_gcu_o1_1_1_bus_cntrl_wire <= inst_decoder_socket_gcu_o1_1_1_bus_cntrl_wire;
  ic_GCU_LSU_mux_ctrl_in_wire <= inst_decoder_GCU_LSU_src_sel_wire;
  ic_PARAM_mux_ctrl_in_wire <= inst_decoder_PARAM_src_sel_wire;
  ic_B1_mux_ctrl_in_wire <= inst_decoder_B1_src_sel_wire;
  ic_B2_mux_ctrl_in_wire <= inst_decoder_B2_src_sel_wire;
  ic_B3_mux_ctrl_in_wire <= inst_decoder_B3_src_sel_wire;
  ic_B4_mux_ctrl_in_wire <= inst_decoder_B4_src_sel_wire;
  ic_B3_1_1_mux_ctrl_in_wire <= inst_decoder_B3_1_1_src_sel_wire;
  ic_B3_1_2_mux_ctrl_in_wire <= inst_decoder_B3_1_2_src_sel_wire;
  fu_Stream_fu_t1_load_in_wire <= inst_decoder_fu_Stream_fu_t1_load_wire;
  fu_Stream_fu_o1_load_in_wire <= inst_decoder_fu_Stream_fu_o1_load_wire;
  fu_Stream_fu_t1_opcode_in_wire <= inst_decoder_fu_Stream_fu_opc_wire;
  fu_alu2_generated_load_P1_in_wire <= inst_decoder_fu_ALU2_P1_load_wire;
  fu_alu2_generated_load_P2_in_wire <= inst_decoder_fu_ALU2_P2_load_wire;
  fu_alu2_generated_operation_in_wire <= inst_decoder_fu_ALU2_opc_wire;
  fu_alu_1_generated_load_in1t_in_wire <= inst_decoder_fu_ALU_1_in1t_load_wire;
  fu_alu_1_generated_load_in2_in_wire <= inst_decoder_fu_ALU_1_in2_load_wire;
  fu_alu_1_generated_operation_in_wire <= inst_decoder_fu_ALU_1_opc_wire;
  fu_LSU_t1_load_in_wire <= inst_decoder_fu_LSU_in1t_load_wire;
  fu_LSU_o1_load_in_wire <= inst_decoder_fu_LSU_in2_load_wire;
  fu_LSU_t1_opcode_in_wire <= inst_decoder_fu_LSU_opc_wire;
  fu_alu_1_1_generated_load_in1t_in_wire <= inst_decoder_fu_ALU_1_1_in1t_load_wire;
  fu_alu_1_1_generated_load_in2_in_wire <= inst_decoder_fu_ALU_1_1_in2_load_wire;
  fu_alu_1_1_generated_operation_in_wire <= inst_decoder_fu_ALU_1_1_opc_wire;
  rf_RF_load_wr_in_wire <= inst_decoder_rf_RF_wr_load_wire;
  rf_RF_addr_wr_in_wire <= inst_decoder_rf_RF_wr_opc_wire;
  rf_RF_load_rd_a_in_wire <= inst_decoder_rf_RF_rd_load_wire;
  rf_RF_addr_rd_a_in_wire <= inst_decoder_rf_RF_rd_opc_wire;
  rf_RF_load_rd_b_in_wire <= inst_decoder_rf_RF_rd2_load_wire;
  rf_RF_addr_rd_b_in_wire <= inst_decoder_rf_RF_rd2_opc_wire;
  iu_IU_1x32_load_rd_in_wire <= inst_decoder_iu_IU_1x32_r0_read_load_wire;
  iu_IU_1x32_addr_rd_in_wire <= inst_decoder_iu_IU_1x32_r0_read_opc_wire;
  iu_IU_1x32_data_wr_in_wire <= inst_decoder_iu_IU_1x32_write_wire;
  iu_IU_1x32_load_wr_in_wire <= inst_decoder_iu_IU_1x32_write_load_wire;
  iu_IU_1x32_addr_wr_in_wire <= inst_decoder_iu_IU_1x32_write_opc_wire;
  inst_decoder_lock_req_wire(0) <= fu_Stream_fu_glockreq_wire;
  inst_decoder_lock_req_wire(1) <= fu_alu2_generated_glockreq_out_wire;
  inst_decoder_lock_req_wire(2) <= fu_alu_1_generated_glockreq_out_wire;
  inst_decoder_lock_req_wire(3) <= fu_LSU_glockreq_out_wire;
  inst_decoder_lock_req_wire(4) <= fu_alu_1_1_generated_glockreq_out_wire;
  inst_decoder_lock_req_wire(5) <= db_lockrq;
  fu_Stream_fu_glock_wire <= inst_decoder_glock_wire(0);
  fu_alu2_generated_glock_in_wire <= inst_decoder_glock_wire(1);
  fu_alu_1_generated_glock_in_wire <= inst_decoder_glock_wire(2);
  fu_LSU_glock_in_wire <= inst_decoder_glock_wire(3);
  fu_alu_1_1_generated_glock_in_wire <= inst_decoder_glock_wire(4);
  rf_RF_glock_in_wire <= inst_decoder_glock_wire(5);
  iu_IU_1x32_glock_in_wire <= inst_decoder_glock_wire(6);
  ic_glock_wire <= inst_decoder_glock_wire(7);
  fu_alu2_generated_data_P1_in_wire <= ic_socket_ALU2_i1_data_wire;
  fu_alu2_generated_data_P2_in_wire <= ic_socket_ALU2_i2_data_wire;
  ic_GCU_LSU_data_6_in_wire <= fu_alu2_generated_data_P3_out_wire;
  ic_B1_data_0_in_wire <= fu_alu2_generated_data_P3_out_wire;
  ic_B4_data_4_in_wire <= fu_alu2_generated_data_P3_out_wire;
  fu_alu_1_generated_data_in1t_in_wire <= ic_socket_ALU_i1_1_data_wire;
  ic_GCU_LSU_data_7_in_wire <= fu_alu_1_generated_data_out1_out_wire;
  ic_B2_data_0_in_wire <= fu_alu_1_generated_data_out1_out_wire;
  ic_B4_data_5_in_wire <= fu_alu_1_generated_data_out1_out_wire;
  fu_alu_1_generated_data_in2_in_wire <= ic_socket_ALU_i1_2_data_wire;
  fu_alu_1_1_generated_data_in1t_in_wire <= ic_socket_ALU_i1_data_wire;
  ic_GCU_LSU_data_3_in_wire <= fu_alu_1_1_generated_data_out1_out_wire;
  ic_B3_data_0_in_wire <= fu_alu_1_1_generated_data_out1_out_wire;
  ic_B4_data_1_in_wire <= fu_alu_1_1_generated_data_out1_out_wire;
  fu_alu_1_1_generated_data_in2_in_wire <= ic_socket_ALU_i2_data_wire;
  fu_Stream_fu_t1_data_in_wire <= ic_socket_Streamout_i1_data_wire;
  fu_Stream_fu_o1_data_in_wire <= ic_socket_Streamout_i1_1_1_data_wire;
  ic_GCU_LSU_data_5_in_wire <= fu_Stream_fu_r1_data_out_wire;
  ic_PARAM_data_2_in_wire <= fu_Stream_fu_r1_data_out_wire;
  ic_B4_data_3_in_wire <= fu_Stream_fu_r1_data_out_wire;
  fu_LSU_t1_address_in_wire <= ic_socket_lsu_i2_data_wire;
  ic_GCU_LSU_data_0_in_wire <= fu_LSU_r1_data_out_wire;
  fu_LSU_o1_data_in_wire <= ic_socket_lsu_i1_data_wire;
  ic_GCU_LSU_data_1_in_wire <= rf_RF_data_rd_a_out_wire;
  ic_PARAM_data_0_in_wire <= rf_RF_data_rd_a_out_wire;
  ic_B3_1_1_data_0_in_wire <= rf_RF_data_rd_a_out_wire;
  ic_B3_1_2_data_0_in_wire <= rf_RF_data_rd_a_out_wire;
  ic_GCU_LSU_data_4_in_wire <= rf_RF_data_rd_b_out_wire;
  ic_PARAM_data_1_in_wire <= rf_RF_data_rd_b_out_wire;
  ic_B3_1_1_data_2_in_wire <= rf_RF_data_rd_b_out_wire;
  ic_B3_1_2_data_1_in_wire <= rf_RF_data_rd_b_out_wire;
  rf_RF_data_wr_in_wire <= ic_socket_RF_i1_data_wire;
  ic_B4_data_2_in_wire <= iu_IU_1x32_data_rd_out_wire;
  ic_B3_1_1_data_1_in_wire <= iu_IU_1x32_data_rd_out_wire;
  ground_signal <= (others => '0');

  inst_fetch : snappy_tta_ifetch
    generic map (
      debug_logic_g => true,
      bypass_pc_register => true)
    port map (
      clk => clk,
      rstx => rstx,
      ra_out => inst_fetch_ra_out_wire,
      ra_in => inst_fetch_ra_in_wire,
      busy => busy,
      imem_en_x => imem_en_x,
      imem_addr => imem_addr,
      imem_data => imem_data,
      pc_in => inst_fetch_pc_in_wire,
      pc_load => inst_fetch_pc_load_wire,
      ra_load => inst_fetch_ra_load_wire,
      pc_opcode => inst_fetch_pc_opcode_wire,
      fetch_en => inst_fetch_fetch_en_wire,
      glock => inst_fetch_glock_wire,
      fetchblock => inst_fetch_fetchblock_wire,
      cond_in => inst_fetch_cond_in_wire,
      cond_load => inst_fetch_cond_load_wire,
      comp_data => inst_fetch_comp_data_wire,
      comp_load => inst_fetch_comp_load_wire,
      db_rstx => db_tta_nreset,
      db_lockreq => db_lockrq,
      db_cyclecnt => db_cyclecnt,
      db_lockcnt => db_lockcnt,
      db_pc => db_pc);

  decomp : snappy_tta_decompressor
    port map (
      fetch_en => decomp_fetch_en_wire,
      lock => decomp_lock_wire,
      fetchblock => decomp_fetchblock_wire,
      clk => clk,
      rstx => rstx,
      instructionword => decomp_instructionword_wire,
      glock => decomp_glock_wire,
      lock_r => decomp_lock_r_wire);

  inst_decoder : snappy_tta_decoder
    port map (
      instructionword => inst_decoder_instructionword_wire,
      pc_load => inst_decoder_pc_load_wire,
      ra_load => inst_decoder_ra_load_wire,
      pc_opcode => inst_decoder_pc_opcode_wire,
      lock => inst_decoder_lock_wire,
      lock_r => inst_decoder_lock_r_wire,
      clk => clk,
      rstx => rstx,
      locked => locked,
      simm_GCU_LSU => inst_decoder_simm_GCU_LSU_wire,
      simm_PARAM => inst_decoder_simm_PARAM_wire,
      simm_B1 => inst_decoder_simm_B1_wire,
      simm_B2 => inst_decoder_simm_B2_wire,
      simm_B3 => inst_decoder_simm_B3_wire,
      simm_B3_1_1 => inst_decoder_simm_B3_1_1_wire,
      socket_lsu_i1_bus_cntrl => inst_decoder_socket_lsu_i1_bus_cntrl_wire,
      socket_lsu_i2_bus_cntrl => inst_decoder_socket_lsu_i2_bus_cntrl_wire,
      socket_RF_i1_bus_cntrl => inst_decoder_socket_RF_i1_bus_cntrl_wire,
      socket_gcu_i1_bus_cntrl => inst_decoder_socket_gcu_i1_bus_cntrl_wire,
      socket_gcu_i2_bus_cntrl => inst_decoder_socket_gcu_i2_bus_cntrl_wire,
      socket_ALU_i1_bus_cntrl => inst_decoder_socket_ALU_i1_bus_cntrl_wire,
      socket_ALU_i2_bus_cntrl => inst_decoder_socket_ALU_i2_bus_cntrl_wire,
      socket_Streamout_i1_bus_cntrl => inst_decoder_socket_Streamout_i1_bus_cntrl_wire,
      socket_ALU2_i1_bus_cntrl => inst_decoder_socket_ALU2_i1_bus_cntrl_wire,
      socket_ALU2_i2_bus_cntrl => inst_decoder_socket_ALU2_i2_bus_cntrl_wire,
      socket_ALU_i1_1_bus_cntrl => inst_decoder_socket_ALU_i1_1_bus_cntrl_wire,
      socket_ALU_i1_2_bus_cntrl => inst_decoder_socket_ALU_i1_2_bus_cntrl_wire,
      socket_Streamout_i1_1_1_bus_cntrl => inst_decoder_socket_Streamout_i1_1_1_bus_cntrl_wire,
      socket_gcu_o1_1_bus_cntrl => inst_decoder_socket_gcu_o1_1_bus_cntrl_wire,
      socket_gcu_o1_1_1_bus_cntrl => inst_decoder_socket_gcu_o1_1_1_bus_cntrl_wire,
      GCU_LSU_src_sel => inst_decoder_GCU_LSU_src_sel_wire,
      PARAM_src_sel => inst_decoder_PARAM_src_sel_wire,
      B1_src_sel => inst_decoder_B1_src_sel_wire,
      B2_src_sel => inst_decoder_B2_src_sel_wire,
      B3_src_sel => inst_decoder_B3_src_sel_wire,
      B4_src_sel => inst_decoder_B4_src_sel_wire,
      B3_1_1_src_sel => inst_decoder_B3_1_1_src_sel_wire,
      B3_1_2_src_sel => inst_decoder_B3_1_2_src_sel_wire,
      fu_Stream_fu_t1_load => inst_decoder_fu_Stream_fu_t1_load_wire,
      fu_Stream_fu_o1_load => inst_decoder_fu_Stream_fu_o1_load_wire,
      fu_Stream_fu_opc => inst_decoder_fu_Stream_fu_opc_wire,
      fu_ALU2_P1_load => inst_decoder_fu_ALU2_P1_load_wire,
      fu_ALU2_P2_load => inst_decoder_fu_ALU2_P2_load_wire,
      fu_ALU2_opc => inst_decoder_fu_ALU2_opc_wire,
      fu_ALU_1_in1t_load => inst_decoder_fu_ALU_1_in1t_load_wire,
      fu_ALU_1_in2_load => inst_decoder_fu_ALU_1_in2_load_wire,
      fu_ALU_1_opc => inst_decoder_fu_ALU_1_opc_wire,
      fu_LSU_in1t_load => inst_decoder_fu_LSU_in1t_load_wire,
      fu_LSU_in2_load => inst_decoder_fu_LSU_in2_load_wire,
      fu_LSU_opc => inst_decoder_fu_LSU_opc_wire,
      fu_ALU_1_1_in1t_load => inst_decoder_fu_ALU_1_1_in1t_load_wire,
      fu_ALU_1_1_in2_load => inst_decoder_fu_ALU_1_1_in2_load_wire,
      fu_ALU_1_1_opc => inst_decoder_fu_ALU_1_1_opc_wire,
      fu_gcu_cond_load => inst_decoder_fu_gcu_cond_load_wire,
      fu_gcu_comp_load => inst_decoder_fu_gcu_comp_load_wire,
      rf_RF_wr_load => inst_decoder_rf_RF_wr_load_wire,
      rf_RF_wr_opc => inst_decoder_rf_RF_wr_opc_wire,
      rf_RF_rd_load => inst_decoder_rf_RF_rd_load_wire,
      rf_RF_rd_opc => inst_decoder_rf_RF_rd_opc_wire,
      rf_RF_rd2_load => inst_decoder_rf_RF_rd2_load_wire,
      rf_RF_rd2_opc => inst_decoder_rf_RF_rd2_opc_wire,
      iu_IU_1x32_r0_read_load => inst_decoder_iu_IU_1x32_r0_read_load_wire,
      iu_IU_1x32_r0_read_opc => inst_decoder_iu_IU_1x32_r0_read_opc_wire,
      iu_IU_1x32_write => inst_decoder_iu_IU_1x32_write_wire,
      iu_IU_1x32_write_load => inst_decoder_iu_IU_1x32_write_load_wire,
      iu_IU_1x32_write_opc => inst_decoder_iu_IU_1x32_write_opc_wire,
      lock_req => inst_decoder_lock_req_wire,
      glock => inst_decoder_glock_wire,
      db_tta_nreset => db_tta_nreset);

  fu_alu2_generated : fu_alu2
    port map (
      clk => clk,
      rstx => rstx,
      glock_in => fu_alu2_generated_glock_in_wire,
      operation_in => fu_alu2_generated_operation_in_wire,
      glockreq_out => fu_alu2_generated_glockreq_out_wire,
      data_P1_in => fu_alu2_generated_data_P1_in_wire,
      load_P1_in => fu_alu2_generated_load_P1_in_wire,
      data_P2_in => fu_alu2_generated_data_P2_in_wire,
      load_P2_in => fu_alu2_generated_load_P2_in_wire,
      data_P3_out => fu_alu2_generated_data_P3_out_wire);

  fu_alu_1_generated : fu_alu_1
    port map (
      clk => clk,
      rstx => rstx,
      glock_in => fu_alu_1_generated_glock_in_wire,
      operation_in => fu_alu_1_generated_operation_in_wire,
      glockreq_out => fu_alu_1_generated_glockreq_out_wire,
      data_in1t_in => fu_alu_1_generated_data_in1t_in_wire,
      load_in1t_in => fu_alu_1_generated_load_in1t_in_wire,
      data_out1_out => fu_alu_1_generated_data_out1_out_wire,
      data_in2_in => fu_alu_1_generated_data_in2_in_wire,
      load_in2_in => fu_alu_1_generated_load_in2_in_wire);

  fu_alu_1_1_generated : fu_alu_1_1
    port map (
      clk => clk,
      rstx => rstx,
      glock_in => fu_alu_1_1_generated_glock_in_wire,
      operation_in => fu_alu_1_1_generated_operation_in_wire,
      glockreq_out => fu_alu_1_1_generated_glockreq_out_wire,
      data_in1t_in => fu_alu_1_1_generated_data_in1t_in_wire,
      load_in1t_in => fu_alu_1_1_generated_load_in1t_in_wire,
      data_out1_out => fu_alu_1_1_generated_data_out1_out_wire,
      data_in2_in => fu_alu_1_1_generated_data_in2_in_wire,
      load_in2_in => fu_alu_1_1_generated_load_in2_in_wire);

  fu_Stream_fu : fu_unistream
    port map (
      t1_data_in => fu_Stream_fu_t1_data_in_wire,
      t1_load_in => fu_Stream_fu_t1_load_in_wire,
      o1_data_in => fu_Stream_fu_o1_data_in_wire,
      o1_load_in => fu_Stream_fu_o1_load_in_wire,
      r1_data_out => fu_Stream_fu_r1_data_out_wire,
      t1_opcode_in => fu_Stream_fu_t1_opcode_in_wire,
      in_valid => fu_Stream_fu_in_valid,
      in_ready => fu_Stream_fu_in_ready,
      in_data => fu_Stream_fu_in_data,
      in_cnt => fu_Stream_fu_in_cnt,
      in_last => fu_Stream_fu_in_last,
      out_valid => fu_Stream_fu_out_valid,
      out_ready => fu_Stream_fu_out_ready,
      out_dvalid => fu_Stream_fu_out_dvalid,
      out_data => fu_Stream_fu_out_data,
      out_cnt => fu_Stream_fu_out_cnt,
      out_last => fu_Stream_fu_out_last,
      clk => clk,
      rstx => rstx,
      glock => fu_Stream_fu_glock_wire,
      glockreq => fu_Stream_fu_glockreq_wire);

  fu_LSU : fu_lsu_32b_slim
    generic map (
      addrw_g => fu_LSU_addrw_g,
      register_bypass_g => 2,
      little_endian_g => 1)
    port map (
      t1_address_in => fu_LSU_t1_address_in_wire,
      t1_load_in => fu_LSU_t1_load_in_wire,
      r1_data_out => fu_LSU_r1_data_out_wire,
      o1_data_in => fu_LSU_o1_data_in_wire,
      o1_load_in => fu_LSU_o1_load_in_wire,
      t1_opcode_in => fu_LSU_t1_opcode_in_wire,
      avalid_out => fu_LSU_avalid_out,
      aready_in => fu_LSU_aready_in,
      aaddr_out => fu_LSU_aaddr_out,
      awren_out => fu_LSU_awren_out,
      astrb_out => fu_LSU_astrb_out,
      adata_out => fu_LSU_adata_out,
      rvalid_in => fu_LSU_rvalid_in,
      rready_out => fu_LSU_rready_out,
      rdata_in => fu_LSU_rdata_in,
      clk => clk,
      rstx => rstx,
      glock_in => fu_LSU_glock_in_wire,
      glockreq_out => fu_LSU_glockreq_out_wire);

  rf_RF : s7_rf_1wr_2rd
    generic map (
      width_g => 32,
      depth_g => 32)
    port map (
      data_rd_a_out => rf_RF_data_rd_a_out_wire,
      load_rd_a_in => rf_RF_load_rd_a_in_wire,
      addr_rd_a_in => rf_RF_addr_rd_a_in_wire,
      data_rd_b_out => rf_RF_data_rd_b_out_wire,
      load_rd_b_in => rf_RF_load_rd_b_in_wire,
      addr_rd_b_in => rf_RF_addr_rd_b_in_wire,
      data_wr_in => rf_RF_data_wr_in_wire,
      load_wr_in => rf_RF_load_wr_in_wire,
      addr_wr_in => rf_RF_addr_wr_in_wire,
      clk => clk,
      rstx => rstx,
      glock_in => rf_RF_glock_in_wire);

  iu_IU_1x32 : s7_rf_1wr_1rd
    generic map (
      width_g => 32,
      depth_g => 1)
    port map (
      data_rd_out => iu_IU_1x32_data_rd_out_wire,
      load_rd_in => iu_IU_1x32_load_rd_in_wire,
      addr_rd_in => iu_IU_1x32_addr_rd_in_wire,
      data_wr_in => iu_IU_1x32_data_wr_in_wire,
      load_wr_in => iu_IU_1x32_load_wr_in_wire,
      addr_wr_in => iu_IU_1x32_addr_wr_in_wire,
      clk => clk,
      rstx => rstx,
      glock_in => iu_IU_1x32_glock_in_wire);

  ic : snappy_tta_interconn
    port map (
      clk => clk,
      rstx => rstx,
      glock => ic_glock_wire,
      socket_lsu_i1_data => ic_socket_lsu_i1_data_wire,
      socket_lsu_i1_bus_cntrl => ic_socket_lsu_i1_bus_cntrl_wire,
      socket_lsu_i2_data => ic_socket_lsu_i2_data_wire,
      socket_lsu_i2_bus_cntrl => ic_socket_lsu_i2_bus_cntrl_wire,
      socket_RF_i1_data => ic_socket_RF_i1_data_wire,
      socket_RF_i1_bus_cntrl => ic_socket_RF_i1_bus_cntrl_wire,
      socket_gcu_i1_data => ic_socket_gcu_i1_data_wire,
      socket_gcu_i1_bus_cntrl => ic_socket_gcu_i1_bus_cntrl_wire,
      socket_gcu_i2_data => ic_socket_gcu_i2_data_wire,
      socket_gcu_i2_bus_cntrl => ic_socket_gcu_i2_bus_cntrl_wire,
      socket_ALU_i1_data => ic_socket_ALU_i1_data_wire,
      socket_ALU_i1_bus_cntrl => ic_socket_ALU_i1_bus_cntrl_wire,
      socket_ALU_i2_data => ic_socket_ALU_i2_data_wire,
      socket_ALU_i2_bus_cntrl => ic_socket_ALU_i2_bus_cntrl_wire,
      socket_Streamout_i1_data => ic_socket_Streamout_i1_data_wire,
      socket_Streamout_i1_bus_cntrl => ic_socket_Streamout_i1_bus_cntrl_wire,
      socket_ALU2_i1_data => ic_socket_ALU2_i1_data_wire,
      socket_ALU2_i1_bus_cntrl => ic_socket_ALU2_i1_bus_cntrl_wire,
      socket_ALU2_i2_data => ic_socket_ALU2_i2_data_wire,
      socket_ALU2_i2_bus_cntrl => ic_socket_ALU2_i2_bus_cntrl_wire,
      socket_ALU_i1_1_data => ic_socket_ALU_i1_1_data_wire,
      socket_ALU_i1_1_bus_cntrl => ic_socket_ALU_i1_1_bus_cntrl_wire,
      socket_ALU_i1_2_data => ic_socket_ALU_i1_2_data_wire,
      socket_ALU_i1_2_bus_cntrl => ic_socket_ALU_i1_2_bus_cntrl_wire,
      socket_Streamout_i1_1_1_data => ic_socket_Streamout_i1_1_1_data_wire,
      socket_Streamout_i1_1_1_bus_cntrl => ic_socket_Streamout_i1_1_1_bus_cntrl_wire,
      socket_gcu_o1_1_data => ic_socket_gcu_o1_1_data_wire,
      socket_gcu_o1_1_bus_cntrl => ic_socket_gcu_o1_1_bus_cntrl_wire,
      socket_gcu_o1_1_1_data => ic_socket_gcu_o1_1_1_data_wire,
      socket_gcu_o1_1_1_bus_cntrl => ic_socket_gcu_o1_1_1_bus_cntrl_wire,
      GCU_LSU_mux_ctrl_in => ic_GCU_LSU_mux_ctrl_in_wire,
      GCU_LSU_data_0_in => ic_GCU_LSU_data_0_in_wire,
      GCU_LSU_data_1_in => ic_GCU_LSU_data_1_in_wire,
      GCU_LSU_data_2_in => ic_GCU_LSU_data_2_in_wire,
      GCU_LSU_data_3_in => ic_GCU_LSU_data_3_in_wire,
      GCU_LSU_data_4_in => ic_GCU_LSU_data_4_in_wire,
      GCU_LSU_data_5_in => ic_GCU_LSU_data_5_in_wire,
      GCU_LSU_data_6_in => ic_GCU_LSU_data_6_in_wire,
      GCU_LSU_data_7_in => ic_GCU_LSU_data_7_in_wire,
      PARAM_mux_ctrl_in => ic_PARAM_mux_ctrl_in_wire,
      PARAM_data_0_in => ic_PARAM_data_0_in_wire,
      PARAM_data_1_in => ic_PARAM_data_1_in_wire,
      PARAM_data_2_in => ic_PARAM_data_2_in_wire,
      B1_mux_ctrl_in => ic_B1_mux_ctrl_in_wire,
      B1_data_0_in => ic_B1_data_0_in_wire,
      B2_mux_ctrl_in => ic_B2_mux_ctrl_in_wire,
      B2_data_0_in => ic_B2_data_0_in_wire,
      B3_mux_ctrl_in => ic_B3_mux_ctrl_in_wire,
      B3_data_0_in => ic_B3_data_0_in_wire,
      B4_mux_ctrl_in => ic_B4_mux_ctrl_in_wire,
      B4_data_0_in => ic_B4_data_0_in_wire,
      B4_data_1_in => ic_B4_data_1_in_wire,
      B4_data_2_in => ic_B4_data_2_in_wire,
      B4_data_3_in => ic_B4_data_3_in_wire,
      B4_data_4_in => ic_B4_data_4_in_wire,
      B4_data_5_in => ic_B4_data_5_in_wire,
      B3_1_1_mux_ctrl_in => ic_B3_1_1_mux_ctrl_in_wire,
      B3_1_1_data_0_in => ic_B3_1_1_data_0_in_wire,
      B3_1_1_data_1_in => ic_B3_1_1_data_1_in_wire,
      B3_1_1_data_2_in => ic_B3_1_1_data_2_in_wire,
      B3_1_2_mux_ctrl_in => ic_B3_1_2_mux_ctrl_in_wire,
      B3_1_2_data_0_in => ic_B3_1_2_data_0_in_wire,
      B3_1_2_data_1_in => ic_B3_1_2_data_1_in_wire,
      simm_GCU_LSU => ic_simm_GCU_LSU_wire,
      simm_cntrl_GCU_LSU => ic_simm_cntrl_GCU_LSU_wire,
      simm_PARAM => ic_simm_PARAM_wire,
      simm_cntrl_PARAM => ic_simm_cntrl_PARAM_wire,
      simm_B1 => ic_simm_B1_wire,
      simm_cntrl_B1 => ic_simm_cntrl_B1_wire,
      simm_B2 => ic_simm_B2_wire,
      simm_cntrl_B2 => ic_simm_cntrl_B2_wire,
      simm_B3 => ic_simm_B3_wire,
      simm_cntrl_B3 => ic_simm_cntrl_B3_wire,
      simm_B3_1_1 => ic_simm_B3_1_1_wire,
      simm_cntrl_B3_1_1 => ic_simm_cntrl_B3_1_1_wire);

end structural;
