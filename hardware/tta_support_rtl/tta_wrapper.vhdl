library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use work.tce_util.all;
use work.snappy_tta_globals.all;
use work.snappy_tta_imem_mau.all;
use work.snappy_tta_params.all;

entity tta_wrapper is
    port (
        clk, reset : in std_logic;

        in_valid    : in  std_logic;
        in_ready    : out std_logic;
        in_data     : in  std_logic_vector(8-1 downto 0);
        in_cnt      : in  std_logic_vector(0 downto 0);
        in_last     : in  std_logic;

        out_valid   : out std_logic;
        out_ready   : in  std_logic;
        out_dvalid  : out std_logic;
        out_data    : out std_logic_vector(8-1 downto 0);
        out_cnt     : out std_logic_vector(0 downto 0);
        out_last    : out std_logic
    );
end entity tta_wrapper;

architecture structural of tta_wrapper is
    signal imem_en_x : std_logic;
    signal imem_addr : std_logic_vector(IMEMADDRWIDTH-1 downto 0);
    signal imem_data : std_logic_vector(IMEMWIDTHINMAUS*IMEMMAUWIDTH-1 downto 0);

    signal rstx, restart_r, tta_nreset : std_logic;

    signal data_avalid, data_aready, data_awren : std_logic;
    signal data_aaddr : std_logic_vector(fu_LSU_addrw_g-2 - 1 downto 0);
    signal data_astrb : std_logic_vector(4-1 downto 0);
    signal data_adata, data_rdata : std_logic_vector(32-1 downto 0);
    signal data_rvalid, data_rready : std_logic;
    
    signal last_transmitted_r, read_all_r : std_logic;
begin
    rstx <= not reset;

    tta_nreset <= '1';
    core : entity work.snappy_tta
    port map (
	clk => clk,
	rstx => rstx,
	busy => '0',

	imem_en_x => imem_en_x,
	imem_addr => imem_addr,
	imem_data => imem_data,

	locked => open,

	fu_Stream_fu_in_valid(0) => in_valid,
	fu_Stream_fu_in_ready(0) => in_ready,
        fu_Stream_fu_in_data     => in_data,
        fu_Stream_fu_in_cnt      => in_cnt,
        fu_Stream_fu_in_last(0)  => in_last,

        fu_Stream_fu_out_valid(0)  => out_valid,
        fu_Stream_fu_out_ready(0)  => out_ready,
        fu_Stream_fu_out_dvalid(0) => out_dvalid,
        fu_Stream_fu_out_data      => out_data,
        fu_Stream_fu_out_cnt       => out_cnt,
        fu_Stream_fu_out_last(0)   => out_last,

	fu_LSU_avalid_out(0) => data_avalid,
	fu_LSU_aready_in(0) => data_aready,
	fu_LSU_aaddr_out => data_aaddr,
	fu_LSU_awren_out(0) => data_awren,
	fu_LSU_astrb_out => data_astrb,
	fu_LSU_adata_out => data_adata,
	fu_LSU_rvalid_in(0) => data_rvalid,
	fu_LSU_rready_out(0) => data_rready,
	fu_LSU_rdata_in => data_rdata,

	db_tta_nreset => tta_nreset,
	db_lockcnt => open,
	db_cyclecnt => open,
	db_pc => open,
	db_lockrq => '0'
    );

    imem : entity work.snappy_rom_array
    generic map (
	addrw => IMEMADDRWIDTH,
	instrw => IMEMWIDTHINMAUS*IMEMMAUWIDTH
    ) port map (
	clock => clk,
	en_x => imem_en_x,
	addr => imem_addr,
	dataout => imem_data
    );

    dmem : entity work.xilinx_blockram
    generic map (
	addrw_g => fu_LSU_addrw_g - 2,
	dataw_g => 32
    ) port map (
	clk => clk,
	rstx => rstx,

	avalid_in => data_avalid,
	aready_out => data_aready,
	aaddr_in  => data_aaddr,
	awren_in => data_awren,
	astrb_in => data_astrb,
	adata_in => data_adata,

	rvalid_out => data_rvalid,
	rready_in => data_rready,
	rdata_out => data_rdata
    );

end architecture structural;
