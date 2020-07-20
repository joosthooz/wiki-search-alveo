library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.ext;
use IEEE.std_logic_arith.sxt;
use work.snappy_tta_globals.all;
use work.tce_util.all;

entity snappy_tta_interconn is

  port (
    clk : in std_logic;
    rstx : in std_logic;
    glock : in std_logic;
    socket_lsu_i1_data : out std_logic_vector(31 downto 0);
    socket_lsu_i1_bus_cntrl : in std_logic_vector(0 downto 0);
    socket_lsu_i2_data : out std_logic_vector(11 downto 0);
    socket_lsu_i2_bus_cntrl : in std_logic_vector(0 downto 0);
    socket_RF_i1_data : out std_logic_vector(31 downto 0);
    socket_RF_i1_bus_cntrl : in std_logic_vector(1 downto 0);
    socket_gcu_i1_data : out std_logic_vector(IMEMADDRWIDTH-1 downto 0);
    socket_gcu_i1_bus_cntrl : in std_logic_vector(0 downto 0);
    socket_gcu_i2_data : out std_logic_vector(IMEMADDRWIDTH-1 downto 0);
    socket_gcu_i2_bus_cntrl : in std_logic_vector(0 downto 0);
    socket_ALU_i1_data : out std_logic_vector(31 downto 0);
    socket_ALU_i1_bus_cntrl : in std_logic_vector(2 downto 0);
    socket_ALU_i2_data : out std_logic_vector(31 downto 0);
    socket_ALU_i2_bus_cntrl : in std_logic_vector(2 downto 0);
    socket_Streamout_i1_data : out std_logic_vector(31 downto 0);
    socket_Streamout_i1_bus_cntrl : in std_logic_vector(1 downto 0);
    socket_ALU2_i1_data : out std_logic_vector(31 downto 0);
    socket_ALU2_i1_bus_cntrl : in std_logic_vector(2 downto 0);
    socket_ALU2_i2_data : out std_logic_vector(31 downto 0);
    socket_ALU2_i2_bus_cntrl : in std_logic_vector(2 downto 0);
    socket_ALU_i1_1_data : out std_logic_vector(31 downto 0);
    socket_ALU_i1_1_bus_cntrl : in std_logic_vector(2 downto 0);
    socket_ALU_i1_2_data : out std_logic_vector(31 downto 0);
    socket_ALU_i1_2_bus_cntrl : in std_logic_vector(2 downto 0);
    socket_Streamout_i1_1_1_data : out std_logic_vector(31 downto 0);
    socket_Streamout_i1_1_1_bus_cntrl : in std_logic_vector(0 downto 0);
    socket_gcu_o1_1_data : out std_logic_vector(31 downto 0);
    socket_gcu_o1_1_bus_cntrl : in std_logic_vector(2 downto 0);
    socket_gcu_o1_1_1_data : out std_logic_vector(31 downto 0);
    socket_gcu_o1_1_1_bus_cntrl : in std_logic_vector(2 downto 0);
    GCU_LSU_mux_ctrl_in : in std_logic_vector(3 downto 0);
    GCU_LSU_data_0_in : in std_logic_vector(31 downto 0);
    GCU_LSU_data_1_in : in std_logic_vector(31 downto 0);
    GCU_LSU_data_2_in : in std_logic_vector(IMEMADDRWIDTH-1 downto 0);
    GCU_LSU_data_3_in : in std_logic_vector(31 downto 0);
    GCU_LSU_data_4_in : in std_logic_vector(31 downto 0);
    GCU_LSU_data_5_in : in std_logic_vector(7 downto 0);
    GCU_LSU_data_6_in : in std_logic_vector(31 downto 0);
    GCU_LSU_data_7_in : in std_logic_vector(31 downto 0);
    PARAM_mux_ctrl_in : in std_logic_vector(1 downto 0);
    PARAM_data_0_in : in std_logic_vector(31 downto 0);
    PARAM_data_1_in : in std_logic_vector(31 downto 0);
    PARAM_data_2_in : in std_logic_vector(7 downto 0);
    B1_mux_ctrl_in : in std_logic_vector(0 downto 0);
    B1_data_0_in : in std_logic_vector(31 downto 0);
    B2_mux_ctrl_in : in std_logic_vector(0 downto 0);
    B2_data_0_in : in std_logic_vector(31 downto 0);
    B3_mux_ctrl_in : in std_logic_vector(0 downto 0);
    B3_data_0_in : in std_logic_vector(31 downto 0);
    B4_mux_ctrl_in : in std_logic_vector(2 downto 0);
    B4_data_0_in : in std_logic_vector(IMEMADDRWIDTH-1 downto 0);
    B4_data_1_in : in std_logic_vector(31 downto 0);
    B4_data_2_in : in std_logic_vector(31 downto 0);
    B4_data_3_in : in std_logic_vector(7 downto 0);
    B4_data_4_in : in std_logic_vector(31 downto 0);
    B4_data_5_in : in std_logic_vector(31 downto 0);
    B3_1_1_mux_ctrl_in : in std_logic_vector(1 downto 0);
    B3_1_1_data_0_in : in std_logic_vector(31 downto 0);
    B3_1_1_data_1_in : in std_logic_vector(31 downto 0);
    B3_1_1_data_2_in : in std_logic_vector(31 downto 0);
    B3_1_2_mux_ctrl_in : in std_logic_vector(0 downto 0);
    B3_1_2_data_0_in : in std_logic_vector(31 downto 0);
    B3_1_2_data_1_in : in std_logic_vector(31 downto 0);
    simm_GCU_LSU : in std_logic_vector(31 downto 0);
    simm_cntrl_GCU_LSU : in std_logic_vector(0 downto 0);
    simm_PARAM : in std_logic_vector(31 downto 0);
    simm_cntrl_PARAM : in std_logic_vector(0 downto 0);
    simm_B1 : in std_logic_vector(31 downto 0);
    simm_cntrl_B1 : in std_logic_vector(0 downto 0);
    simm_B2 : in std_logic_vector(31 downto 0);
    simm_cntrl_B2 : in std_logic_vector(0 downto 0);
    simm_B3 : in std_logic_vector(2 downto 0);
    simm_cntrl_B3 : in std_logic_vector(0 downto 0);
    simm_B3_1_1 : in std_logic_vector(31 downto 0);
    simm_cntrl_B3_1_1 : in std_logic_vector(0 downto 0));

end snappy_tta_interconn;

architecture comb_andor of snappy_tta_interconn is

  signal databus_GCU_LSU : std_logic_vector(31 downto 0);
  signal databus_PARAM : std_logic_vector(31 downto 0);
  signal databus_B1 : std_logic_vector(31 downto 0);
  signal databus_B2 : std_logic_vector(31 downto 0);
  signal databus_B3 : std_logic_vector(31 downto 0);
  signal databus_B4 : std_logic_vector(31 downto 0);
  signal databus_B3_1_1 : std_logic_vector(31 downto 0);
  signal databus_B3_1_2 : std_logic_vector(31 downto 0);

  component snappy_tta_input_mux_2 is
    generic (
      BUSW_0 : integer := 32;
      BUSW_1 : integer := 32;
      DATAW : integer := 32);
    port (
      databus0 : in std_logic_vector(BUSW_0-1 downto 0);
      databus1 : in std_logic_vector(BUSW_1-1 downto 0);
      data : out std_logic_vector(DATAW-1 downto 0);
      databus_cntrl : in std_logic_vector(0 downto 0));
  end component;

  component snappy_tta_input_mux_4 is
    generic (
      BUSW_0 : integer := 32;
      BUSW_1 : integer := 32;
      BUSW_2 : integer := 32;
      BUSW_3 : integer := 32;
      DATAW : integer := 32);
    port (
      databus0 : in std_logic_vector(BUSW_0-1 downto 0);
      databus1 : in std_logic_vector(BUSW_1-1 downto 0);
      databus2 : in std_logic_vector(BUSW_2-1 downto 0);
      databus3 : in std_logic_vector(BUSW_3-1 downto 0);
      data : out std_logic_vector(DATAW-1 downto 0);
      databus_cntrl : in std_logic_vector(1 downto 0));
  end component;

  component snappy_tta_input_mux_6 is
    generic (
      BUSW_0 : integer := 32;
      BUSW_1 : integer := 32;
      BUSW_2 : integer := 32;
      BUSW_3 : integer := 32;
      BUSW_4 : integer := 32;
      BUSW_5 : integer := 32;
      DATAW : integer := 32);
    port (
      databus0 : in std_logic_vector(BUSW_0-1 downto 0);
      databus1 : in std_logic_vector(BUSW_1-1 downto 0);
      databus2 : in std_logic_vector(BUSW_2-1 downto 0);
      databus3 : in std_logic_vector(BUSW_3-1 downto 0);
      databus4 : in std_logic_vector(BUSW_4-1 downto 0);
      databus5 : in std_logic_vector(BUSW_5-1 downto 0);
      data : out std_logic_vector(DATAW-1 downto 0);
      databus_cntrl : in std_logic_vector(2 downto 0));
  end component;

  component snappy_tta_input_mux_7 is
    generic (
      BUSW_0 : integer := 32;
      BUSW_1 : integer := 32;
      BUSW_2 : integer := 32;
      BUSW_3 : integer := 32;
      BUSW_4 : integer := 32;
      BUSW_5 : integer := 32;
      BUSW_6 : integer := 32;
      DATAW : integer := 32);
    port (
      databus0 : in std_logic_vector(BUSW_0-1 downto 0);
      databus1 : in std_logic_vector(BUSW_1-1 downto 0);
      databus2 : in std_logic_vector(BUSW_2-1 downto 0);
      databus3 : in std_logic_vector(BUSW_3-1 downto 0);
      databus4 : in std_logic_vector(BUSW_4-1 downto 0);
      databus5 : in std_logic_vector(BUSW_5-1 downto 0);
      databus6 : in std_logic_vector(BUSW_6-1 downto 0);
      data : out std_logic_vector(DATAW-1 downto 0);
      databus_cntrl : in std_logic_vector(2 downto 0));
  end component;

  component snappy_tta_input_mux_8 is
    generic (
      BUSW_0 : integer := 32;
      BUSW_1 : integer := 32;
      BUSW_2 : integer := 32;
      BUSW_3 : integer := 32;
      BUSW_4 : integer := 32;
      BUSW_5 : integer := 32;
      BUSW_6 : integer := 32;
      BUSW_7 : integer := 32;
      DATAW : integer := 32);
    port (
      databus0 : in std_logic_vector(BUSW_0-1 downto 0);
      databus1 : in std_logic_vector(BUSW_1-1 downto 0);
      databus2 : in std_logic_vector(BUSW_2-1 downto 0);
      databus3 : in std_logic_vector(BUSW_3-1 downto 0);
      databus4 : in std_logic_vector(BUSW_4-1 downto 0);
      databus5 : in std_logic_vector(BUSW_5-1 downto 0);
      databus6 : in std_logic_vector(BUSW_6-1 downto 0);
      databus7 : in std_logic_vector(BUSW_7-1 downto 0);
      data : out std_logic_vector(DATAW-1 downto 0);
      databus_cntrl : in std_logic_vector(2 downto 0));
  end component;

  component snappy_tta_input_mux_9 is
    generic (
      BUSW_0 : integer := 32;
      BUSW_1 : integer := 32;
      BUSW_2 : integer := 32;
      BUSW_3 : integer := 32;
      BUSW_4 : integer := 32;
      BUSW_5 : integer := 32;
      BUSW_6 : integer := 32;
      BUSW_7 : integer := 32;
      BUSW_8 : integer := 32;
      DATAW : integer := 32);
    port (
      databus0 : in std_logic_vector(BUSW_0-1 downto 0);
      databus1 : in std_logic_vector(BUSW_1-1 downto 0);
      databus2 : in std_logic_vector(BUSW_2-1 downto 0);
      databus3 : in std_logic_vector(BUSW_3-1 downto 0);
      databus4 : in std_logic_vector(BUSW_4-1 downto 0);
      databus5 : in std_logic_vector(BUSW_5-1 downto 0);
      databus6 : in std_logic_vector(BUSW_6-1 downto 0);
      databus7 : in std_logic_vector(BUSW_7-1 downto 0);
      databus8 : in std_logic_vector(BUSW_8-1 downto 0);
      data : out std_logic_vector(DATAW-1 downto 0);
      databus_cntrl : in std_logic_vector(3 downto 0));
  end component;


begin -- comb_andor

  ALU2_i1 : snappy_tta_input_mux_6
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      BUSW_2 => 32,
      BUSW_3 => 32,
      BUSW_4 => 32,
      BUSW_5 => 32,
      DATAW => 32)
    port map (
      databus0 => databus_PARAM,
      databus1 => databus_B1,
      databus2 => databus_B3,
      databus3 => databus_B3_1_1,
      databus4 => databus_B2,
      databus5 => databus_B3_1_2,
      data => socket_ALU2_i1_data,
      databus_cntrl => socket_ALU2_i1_bus_cntrl);

  ALU2_i2 : snappy_tta_input_mux_6
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      BUSW_2 => 32,
      BUSW_3 => 32,
      BUSW_4 => 32,
      BUSW_5 => 32,
      DATAW => 32)
    port map (
      databus0 => databus_PARAM,
      databus1 => databus_B2,
      databus2 => databus_B3,
      databus3 => databus_B3_1_2,
      databus4 => databus_B1,
      databus5 => databus_B3_1_1,
      data => socket_ALU2_i2_data,
      databus_cntrl => socket_ALU2_i2_bus_cntrl);

  ALU_i1 : snappy_tta_input_mux_7
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      BUSW_2 => 32,
      BUSW_3 => 32,
      BUSW_4 => 32,
      BUSW_5 => 32,
      BUSW_6 => 32,
      DATAW => 32)
    port map (
      databus0 => databus_B1,
      databus1 => databus_B2,
      databus2 => databus_B3,
      databus3 => databus_GCU_LSU,
      databus4 => databus_B3_1_1,
      databus5 => databus_PARAM,
      databus6 => databus_B3_1_2,
      data => socket_ALU_i1_data,
      databus_cntrl => socket_ALU_i1_bus_cntrl);

  ALU_i1_1 : snappy_tta_input_mux_6
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      BUSW_2 => 32,
      BUSW_3 => 32,
      BUSW_4 => 32,
      BUSW_5 => 32,
      DATAW => 32)
    port map (
      databus0 => databus_PARAM,
      databus1 => databus_B1,
      databus2 => databus_B2,
      databus3 => databus_B3_1_1,
      databus4 => databus_B3,
      databus5 => databus_B3_1_2,
      data => socket_ALU_i1_1_data,
      databus_cntrl => socket_ALU_i1_1_bus_cntrl);

  ALU_i1_2 : snappy_tta_input_mux_6
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      BUSW_2 => 32,
      BUSW_3 => 32,
      BUSW_4 => 32,
      BUSW_5 => 32,
      DATAW => 32)
    port map (
      databus0 => databus_B1,
      databus1 => databus_B3,
      databus2 => databus_B3_1_2,
      databus3 => databus_B2,
      databus4 => databus_PARAM,
      databus5 => databus_B3_1_1,
      data => socket_ALU_i1_2_data,
      databus_cntrl => socket_ALU_i1_2_bus_cntrl);

  ALU_i2 : snappy_tta_input_mux_6
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      BUSW_2 => 32,
      BUSW_3 => 32,
      BUSW_4 => 32,
      BUSW_5 => 32,
      DATAW => 32)
    port map (
      databus0 => databus_PARAM,
      databus1 => databus_B1,
      databus2 => databus_B2,
      databus3 => databus_GCU_LSU,
      databus4 => databus_B3_1_2,
      databus5 => databus_B3_1_1,
      data => socket_ALU_i2_data,
      databus_cntrl => socket_ALU_i2_bus_cntrl);

  RF_i1 : snappy_tta_input_mux_4
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      BUSW_2 => 32,
      BUSW_3 => 32,
      DATAW => 32)
    port map (
      databus0 => databus_B3_1_2,
      databus1 => databus_B3_1_1,
      databus2 => databus_B4,
      databus3 => databus_GCU_LSU,
      data => socket_RF_i1_data,
      databus_cntrl => socket_RF_i1_bus_cntrl);

  Streamout_i1 : snappy_tta_input_mux_4
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      BUSW_2 => 32,
      BUSW_3 => 32,
      DATAW => 32)
    port map (
      databus0 => databus_B3_1_2,
      databus1 => databus_B3,
      databus2 => databus_GCU_LSU,
      databus3 => databus_B3_1_1,
      data => socket_Streamout_i1_data,
      databus_cntrl => socket_Streamout_i1_bus_cntrl);

  Streamout_i1_1_1 : snappy_tta_input_mux_2
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      DATAW => 32)
    port map (
      databus0 => databus_B3_1_1,
      databus1 => databus_B2,
      data => socket_Streamout_i1_1_1_data,
      databus_cntrl => socket_Streamout_i1_1_1_bus_cntrl);

  gcu_i1 : snappy_tta_input_mux_2
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      DATAW => IMEMADDRWIDTH)
    port map (
      databus0 => databus_GCU_LSU,
      databus1 => databus_B3_1_2,
      data => socket_gcu_i1_data,
      databus_cntrl => socket_gcu_i1_bus_cntrl);

  gcu_i2 : snappy_tta_input_mux_2
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      DATAW => IMEMADDRWIDTH)
    port map (
      databus0 => databus_GCU_LSU,
      databus1 => databus_B3_1_1,
      data => socket_gcu_i2_data,
      databus_cntrl => socket_gcu_i2_bus_cntrl);

  gcu_o1_1 : snappy_tta_input_mux_8
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      BUSW_2 => 32,
      BUSW_3 => 32,
      BUSW_4 => 32,
      BUSW_5 => 32,
      BUSW_6 => 32,
      BUSW_7 => 32,
      DATAW => 32)
    port map (
      databus0 => databus_GCU_LSU,
      databus1 => databus_B4,
      databus2 => databus_PARAM,
      databus3 => databus_B1,
      databus4 => databus_B2,
      databus5 => databus_B3,
      databus6 => databus_B3_1_1,
      databus7 => databus_B3_1_2,
      data => socket_gcu_o1_1_data,
      databus_cntrl => socket_gcu_o1_1_bus_cntrl);

  gcu_o1_1_1 : snappy_tta_input_mux_8
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      BUSW_2 => 32,
      BUSW_3 => 32,
      BUSW_4 => 32,
      BUSW_5 => 32,
      BUSW_6 => 32,
      BUSW_7 => 32,
      DATAW => 32)
    port map (
      databus0 => databus_GCU_LSU,
      databus1 => databus_B4,
      databus2 => databus_PARAM,
      databus3 => databus_B1,
      databus4 => databus_B2,
      databus5 => databus_B3,
      databus6 => databus_B3_1_1,
      databus7 => databus_B3_1_2,
      data => socket_gcu_o1_1_1_data,
      databus_cntrl => socket_gcu_o1_1_1_bus_cntrl);

  lsu_i1 : snappy_tta_input_mux_2
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      DATAW => 32)
    port map (
      databus0 => databus_B3_1_1,
      databus1 => databus_GCU_LSU,
      data => socket_lsu_i1_data,
      databus_cntrl => socket_lsu_i1_bus_cntrl);

  lsu_i2 : snappy_tta_input_mux_2
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      DATAW => 12)
    port map (
      databus0 => databus_B3_1_2,
      databus1 => databus_GCU_LSU,
      data => socket_lsu_i2_data,
      databus_cntrl => socket_lsu_i2_bus_cntrl);

  GCU_LSU_bus_mux_inst : snappy_tta_input_mux_9
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      BUSW_2 => IMEMADDRWIDTH,
      BUSW_3 => 32,
      BUSW_4 => 32,
      BUSW_5 => 8,
      BUSW_6 => 32,
      BUSW_7 => 32,
      BUSW_8 => 32,
      DATAW => 32)
    port map (
      databus0 => GCU_LSU_data_0_in,
      databus1 => GCU_LSU_data_1_in,
      databus2 => GCU_LSU_data_2_in,
      databus3 => GCU_LSU_data_3_in,
      databus4 => GCU_LSU_data_4_in,
      databus5 => GCU_LSU_data_5_in,
      databus6 => GCU_LSU_data_6_in,
      databus7 => GCU_LSU_data_7_in,
      databus8 => simm_GCU_LSU,
      data => databus_GCU_LSU,
      databus_cntrl => GCU_LSU_mux_ctrl_in);

  PARAM_bus_mux_inst : snappy_tta_input_mux_4
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      BUSW_2 => 8,
      BUSW_3 => 32,
      DATAW => 32)
    port map (
      databus0 => PARAM_data_0_in,
      databus1 => PARAM_data_1_in,
      databus2 => PARAM_data_2_in,
      databus3 => simm_PARAM,
      data => databus_PARAM,
      databus_cntrl => PARAM_mux_ctrl_in);

  B1_bus_mux_inst : snappy_tta_input_mux_2
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      DATAW => 32)
    port map (
      databus0 => B1_data_0_in,
      databus1 => simm_B1,
      data => databus_B1,
      databus_cntrl => B1_mux_ctrl_in);

  B2_bus_mux_inst : snappy_tta_input_mux_2
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      DATAW => 32)
    port map (
      databus0 => B2_data_0_in,
      databus1 => simm_B2,
      data => databus_B2,
      databus_cntrl => B2_mux_ctrl_in);

  B3_bus_mux_inst : snappy_tta_input_mux_2
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 3,
      DATAW => 32)
    port map (
      databus0 => B3_data_0_in,
      databus1 => simm_B3,
      data => databus_B3,
      databus_cntrl => B3_mux_ctrl_in);

  B4_bus_mux_inst : snappy_tta_input_mux_6
    generic map (
      BUSW_0 => IMEMADDRWIDTH,
      BUSW_1 => 32,
      BUSW_2 => 32,
      BUSW_3 => 8,
      BUSW_4 => 32,
      BUSW_5 => 32,
      DATAW => 32)
    port map (
      databus0 => B4_data_0_in,
      databus1 => B4_data_1_in,
      databus2 => B4_data_2_in,
      databus3 => B4_data_3_in,
      databus4 => B4_data_4_in,
      databus5 => B4_data_5_in,
      data => databus_B4,
      databus_cntrl => B4_mux_ctrl_in);

  B3_1_1_bus_mux_inst : snappy_tta_input_mux_4
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      BUSW_2 => 32,
      BUSW_3 => 32,
      DATAW => 32)
    port map (
      databus0 => B3_1_1_data_0_in,
      databus1 => B3_1_1_data_1_in,
      databus2 => B3_1_1_data_2_in,
      databus3 => simm_B3_1_1,
      data => databus_B3_1_1,
      databus_cntrl => B3_1_1_mux_ctrl_in);

  B3_1_2_bus_mux_inst : snappy_tta_input_mux_2
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      DATAW => 32)
    port map (
      databus0 => B3_1_2_data_0_in,
      databus1 => B3_1_2_data_1_in,
      data => databus_B3_1_2,
      databus_cntrl => B3_1_2_mux_ctrl_in);


end comb_andor;
