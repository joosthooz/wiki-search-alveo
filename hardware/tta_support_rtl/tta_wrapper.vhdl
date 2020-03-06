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
    signal tta_out_data, tta_in_data : std_logic_vector(8-1 downto 0);
    signal tta_out_valid, tta_in_valid : std_logic;
    signal tta_out_ready, tta_in_ready : std_logic;
    signal tta_read_data_valid : std_logic;

    signal out_valid_r : std_logic;

    signal imem_en_x : std_logic;
    signal imem_addr : std_logic_vector(IMEMADDRWIDTH-1 downto 0);
    signal imem_data : std_logic_vector(IMEMWIDTHINMAUS*IMEMMAUWIDTH-1 downto 0);

    signal rstx, restart_r, tta_nreset : std_logic;

    signal data_avalid, data_aready, data_awren : std_logic;
    signal data_aaddr : std_logic_vector(fu_LSU_addrw_g-2 - 1 downto 0);
    signal data_astrb : std_logic_vector(4-1 downto 0);
    signal data_adata, data_rdata : std_logic_vector(32-1 downto 0);
    signal data_rvalid, data_rready : std_logic;
    
    signal done_r, last_transmitted_r, read_all_r : std_logic;
begin
    rstx <= not reset;

    monitor: process(clk)
    begin
      if rising_edge(clk) then
	if rstx = '0' or restart_r = '1' then
          done_r <= '0';
	  read_all_r <= '0';
	else
          if data_aaddr = "1111111111" and data_awren = '1' and data_avalid = '1' then
            done_r <= '1';
	  end if;

	  if in_valid = '1' and in_last = '1' and tta_in_ready = '1' then
            read_all_r <= '0';
	  end if;
        end if;
      end if;
    end process monitor;

    streamout: process(clk)
    begin
      if rising_edge(clk) then
	if rstx = '0' then
	  out_data <= (others => '0');
	  out_valid_r <= '0';
          restart_r <= '0';
	  last_transmitted_r <= '0';
        else
	  if done_r = '0' then
	    restart_r <= '0';
	  end if;

	  if restart_r = '1' then
	      out_valid_r <= '0';
	  elsif last_transmitted_r = '0' then
            if done_r = '1' and tta_out_valid = '0' then
              out_valid_r <= '1';
	      out_dvalid <= '0';
              out_cnt <= "0";
              out_last <= '1';

	      last_transmitted_r <= '1';
            else
	      out_valid_r <= tta_out_valid;
	      out_dvalid <= '1';
	      out_cnt <= "1";
	      out_last <= '0';
              
	      if out_valid_r = '1' and out_ready = '1' then
	        out_valid_r <= '0';
	      end if;
	
	      if tta_out_valid = '1' and tta_out_ready = '1' then
                out_valid_r <= '1';
		out_data <= tta_out_data;
	      end if;
	    end if;
          elsif out_ready = '1' then
	    restart_r <= '1';
	    last_transmitted_r <= '0';
	    out_valid_r <= '0';
	  end if;
	end if;
      end if;
    end process streamout;

    out_valid <= out_valid_r;
    tta_out_ready <= out_ready or not out_valid_r;
    
    streamin: process(read_all_r, tta_in_ready, in_valid, in_data)
    begin
	if read_all_r = '1' then
	   tta_in_valid <= '1';
	   tta_in_data <= (others => '0');
	   in_ready <= '0';
	else
           tta_in_valid <= in_valid;
	   tta_in_data <= in_data;
           in_ready <= tta_in_ready;
	end if;
    end process streamin;

    tta_read_data_valid <= tta_out_valid and tta_out_ready;
    tta_nreset <= not restart_r;
    core : entity work.snappy_tta
    port map (
	clk => clk,
	rstx => rstx,
	busy => '0',

	imem_en_x => imem_en_x,
	imem_addr => imem_addr,
	imem_data => imem_data,

	locked => open,

	fu_Streamout_instance_data_out => tta_out_data,
	fu_Streamout_instance_valid_out(0) => tta_out_valid,
	fu_streamout_instance_ready_in(0) => tta_out_ready,

	fu_Streamin_instance_data_in => tta_in_data,
	fu_Streamin_instance_valid_in(0) => tta_in_valid,
	fu_Streamin_instance_ready_out(0) => tta_in_ready,

	fu_Streamout_read_data_in => tta_out_data,
	fu_Streamout_read_data_valid_in(0) => tta_read_data_valid,

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
