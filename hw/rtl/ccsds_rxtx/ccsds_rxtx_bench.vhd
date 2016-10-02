-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rxtx_bench
---- Version: 1.0.0
---- Description:
---- Unit level testing vhdl ressource
---- 1: generate clock signals
---- 2: generate resets signals
---- 3: generate wb read/write cycles signals
---- 4: generate rx/tx external data and samples signals
-------------------------------
---- Author(s):
---- Guillaume Rembert
-------------------------------
---- Licence:
---- MIT
-------------------------------
---- Changes list:
---- 2015/11/18: initial release
---- 2015/12/28: adding random stimuli generation
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;
library work;
use work.ccsds_rxtx_functions.all;
use work.ccsds_rxtx_parameters.all;

--=============================================================================
-- Entity declaration for ccsds_rxtx_bench - rx/tx unit test tool
--=============================================================================
entity ccsds_rxtx_bench is
  generic (
    -- subsystem instantiation
    CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH: integer := RX_PHYS_SIG_QUANT_DEPTH;
    CCSDS_RXTX_BENCH_RXTX0_RX_DATA_BUS_SIZE: integer := RX_SYSTEM_DATA_BUS_SIZE;
    CCSDS_RXTX_BENCH_RXTX0_TX_PHYS_SIG_QUANT_DEPTH: integer := TX_PHYS_SIG_QUANT_DEPTH;
    CCSDS_RXTX_BENCH_RXTX0_TX_DATA_BUS_SIZE: integer := TX_SYSTEM_DATA_BUS_SIZE;
    CCSDS_RXTX_BENCH_RXTX0_WB_ADDR_BUS_SIZE: integer := RXTX_SYSTEM_WB_ADDR_BUS_SIZE;
    CCSDS_RXTX_BENCH_RXTX0_WB_DATA_BUS_SIZE: integer := RXTX_SYSTEM_WB_DATA_BUS_SIZE;
    -- simulation/test parameters
    CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_RXTX0_RX_CLK0_PERIOD: time := 2 ns;
    CCSDS_RXTX_BENCH_RXTX0_TX_CLK0_PERIOD: time := 3 ns;
    CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION: time := 200 ns;
    CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION: time := 100 ns;
    CCSDS_RXTX_BENCH_START_WB_WAIT_DURATION: time := 500 ns
  );
end ccsds_rxtx_bench;

--=============================================================================
-- architecture declaration / internal processing
--=============================================================================
architecture behaviour of ccsds_rxtx_bench is
  component ccsds_rxtx_top is
    port(
      irq_o: out std_logic; -- interrupt request output
      -- wishbone slave bus connections
      wb_ack_o: out std_logic; -- acknowledge output / normal bus cycle termination
      wb_adr_i: in std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_WB_ADDR_BUS_SIZE-1 downto 0); -- address input array
      wb_clk_i: in std_logic; -- clock input / wb operations are always on rising edge of clk
      wb_cyc_i: in std_logic; -- cycle input / valid bus cycle in progress
      wb_dat_i: in std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_WB_DATA_BUS_SIZE-1 downto 0); -- data input array
      wb_dat_o: out std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_WB_DATA_BUS_SIZE-1 downto 0); -- data output array
      wb_err_o: out std_logic; -- error output / abnormal bus cycle termination
      wb_rst_i: in std_logic; -- reset input
      wb_rty_o: out std_logic; -- retry output / not ready - retry bus cycle
      wb_stb_i: in std_logic; -- strobe input / slave is selected
      wb_we_i: in std_logic; -- write enable input / indicates if cycle is of write or read type
      -- rx inputs
      rx_clk_i: in std_logic; -- received serial or parallel samples clock
      rx_i_samples_par_i: in std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- i samples
      rx_q_samples_par_i: in std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- q samples
      rx_if_samples_par_i: in std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- if samples
      rx_i_samples_ser_i: in std_logic; -- i samples
      rx_q_samples_ser_i: in std_logic; -- q samples
      rx_if_samples_ser_i: in std_logic; -- if samples
      -- rx outputs
      rx_clk_o: out std_logic; -- received data clock
      rx_data_par_o: out std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_DATA_BUS_SIZE-1 downto 0); -- received data parallel output
      rx_data_ser_o: out std_logic; -- received data serial output
      rx_ok_o: out std_logic; -- rx status indicator
      -- tx inputs
      tx_clk_i: in std_logic; -- direct data clock
      tx_data_par_i: in std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_TX_DATA_BUS_SIZE-1 downto 0); -- direct data parallel input
      tx_data_ser_i: in std_logic; -- direct data serial input
      tx_data_valid_i: in std_logic; -- input data valid indicator
      -- tx outputs
      tx_i_samples_par_o: out std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- i samples
      tx_q_samples_par_o: out std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- q samples
      tx_if_samples_par_o: out std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- if samples
      tx_i_samples_ser_o: out std_logic; -- i samples
      tx_q_samples_ser_o: out std_logic; -- q samples
      tx_if_samples_ser_o: out std_logic; -- if samples
      tx_samples_valid_o: out std_logic; -- output samples valid indicator
      tx_clk_o: out std_logic; -- emitted samples clock
      tx_ok_o: out std_logic -- tx status indicator
    );
  end component;
-- synthetic generated stimuli
  -- wishbone bus
  signal bench_sti_rxtx0_wb_clk0: std_logic := '0';
  signal bench_sti_rxtx0_wb_rst0: std_logic := '0';
  signal bench_sti_rxtx0_wb_adr0: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_WB_ADDR_BUS_SIZE-1 downto 0) := (others => '0');
  signal bench_sti_rxtx0_wb_cyc0: std_logic := '0';
  signal bench_sti_rxtx0_wb_dat0: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_WB_DATA_BUS_SIZE-1 downto 0) := (others => '0');
  signal bench_sti_rxtx0_wb_stb0: std_logic := '0';
  signal bench_sti_rxtx0_wb_we0: std_logic := '0';
  -- rx
  signal bench_sti_rxtx0_rx_clk0: std_logic := '0';
  signal bench_sti_rxtx0_rx_samples_par0: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0) := (others => '0');
  signal bench_sti_rxtx0_rx_samples_par1: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0) := (others => '0');
  signal bench_sti_rxtx0_rx_samples_par2: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0) := (others => '0');
  signal bench_sti_rxtx0_rx_samples_ser0: std_logic := '0';
  signal bench_sti_rxtx0_rx_samples_ser1: std_logic := '0';
  signal bench_sti_rxtx0_rx_samples_ser2: std_logic := '0';
  -- tx
  signal bench_sti_rxtx0_tx_clk0: std_logic := '0';
  signal bench_sti_rxtx0_tx_data_par0: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_TX_DATA_BUS_SIZE-1 downto 0) := (others => '0');
  signal bench_sti_rxtx0_tx_data_ser0: std_logic := '0';
  signal bench_sti_rxtx0_tx_data_valid: std_logic := '0';
-- core generated response
  signal bench_res_rxtx0_irq0: std_logic;
  -- wishbone bus
  signal bench_res_rxtx0_wb_ack0: std_logic;
  signal bench_res_rxtx0_wb_dat0: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_WB_DATA_BUS_SIZE-1 downto 0);
  signal bench_res_rxtx0_wb_err0: std_logic;
  signal bench_res_rxtx0_wb_rty0: std_logic;
  -- rx
  signal bench_res_rxtx0_rx_clk0: std_logic;
  signal bench_res_rxtx0_rx_data_par0: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_DATA_BUS_SIZE-1 downto 0);
  signal bench_res_rxtx0_rx_data_ser0: std_logic;
  signal bench_res_rxtx0_rx_ok: std_logic;
  -- tx
  signal bench_res_rxtx0_tx_clk0: std_logic;
  signal bench_res_rxtx0_tx_samples_par0: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
  signal bench_res_rxtx0_tx_samples_par1: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
  signal bench_res_rxtx0_tx_samples_par2: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
  signal bench_res_rxtx0_tx_samples_ser0: std_logic;
  signal bench_res_rxtx0_tx_samples_ser1: std_logic;
  signal bench_res_rxtx0_tx_samples_ser2: std_logic;
  signal bench_res_rxtx0_tx_samples_valid: std_logic;
  signal bench_res_rxtx0_tx_ok: std_logic;  

--=============================================================================
-- architecture begin
--=============================================================================
  begin
    -- Instance(s) of unit under test
    rxtx_001: ccsds_rxtx_top
      port map(
        irq_o => bench_res_rxtx0_irq0,
        wb_ack_o => bench_res_rxtx0_wb_ack0,
        wb_adr_i => bench_sti_rxtx0_wb_adr0,
        wb_clk_i => bench_sti_rxtx0_wb_clk0,
        wb_cyc_i => bench_sti_rxtx0_wb_cyc0,
        wb_dat_i => bench_sti_rxtx0_wb_dat0,
        wb_dat_o => bench_res_rxtx0_wb_dat0,
        wb_err_o => bench_res_rxtx0_wb_err0,
        wb_rst_i => bench_sti_rxtx0_wb_rst0,
        wb_rty_o => bench_res_rxtx0_wb_rty0,
        wb_stb_i => bench_sti_rxtx0_wb_stb0,
        wb_we_i => bench_sti_rxtx0_wb_we0,
        rx_clk_i => bench_sti_rxtx0_rx_clk0,
        rx_i_samples_par_i => bench_sti_rxtx0_rx_samples_par0,
        rx_q_samples_par_i => bench_sti_rxtx0_rx_samples_par1,
        rx_if_samples_par_i => bench_sti_rxtx0_rx_samples_par2,
        rx_i_samples_ser_i => bench_sti_rxtx0_rx_samples_ser0,
        rx_q_samples_ser_i => bench_sti_rxtx0_rx_samples_ser1,
        rx_if_samples_ser_i => bench_sti_rxtx0_rx_samples_ser2,
        rx_clk_o => bench_res_rxtx0_rx_clk0,
        rx_data_par_o => bench_res_rxtx0_rx_data_par0,
        rx_data_ser_o => bench_res_rxtx0_rx_data_ser0,
        rx_ok_o => bench_res_rxtx0_rx_ok,
        tx_clk_i => bench_sti_rxtx0_tx_clk0,
        tx_data_par_i => bench_sti_rxtx0_tx_data_par0,
        tx_data_ser_i => bench_sti_rxtx0_tx_data_ser0,
        tx_data_valid_i => bench_sti_rxtx0_tx_data_valid,
        tx_i_samples_par_o => bench_res_rxtx0_tx_samples_par0,
        tx_q_samples_par_o => bench_res_rxtx0_tx_samples_par1,
        tx_if_samples_par_o => bench_res_rxtx0_tx_samples_par2,
        tx_i_samples_ser_o => bench_res_rxtx0_tx_samples_ser0,
        tx_q_samples_ser_o => bench_res_rxtx0_tx_samples_ser1,
        tx_if_samples_ser_o => bench_res_rxtx0_tx_samples_ser2,
        tx_samples_valid_o => bench_res_rxtx0_tx_samples_valid,
        tx_clk_o => bench_res_rxtx0_tx_clk0,
        tx_ok_o => bench_res_rxtx0_tx_ok
      );
    --=============================================================================
    -- Begin of bench_sti_rxtx0_wb_clk0p
    -- bench_sti_rxtx0_wb_clk0 generation
    --=============================================================================
    -- read: 
    -- write: bench_sti_rxtx0_wb_clk0
    -- r/w: 
    BENCH_STI_RXTX0_WB_CLK0P : process
      begin
        bench_sti_rxtx0_wb_clk0 <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD/2;
        bench_sti_rxtx0_wb_clk0 <= '0';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_rxtx0_rx_clk0p
    -- bench_sti_rxtx0_rx_clk0 generation
    --=============================================================================
    -- read: 
    -- write: bench_sti_rxtx0_rx_clk0
    -- r/w: 
    BENCH_STI_RXTX0_RX_CLK0P : process
      begin
        bench_sti_rxtx0_rx_clk0 <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_RX_CLK0_PERIOD/2;
        bench_sti_rxtx0_rx_clk0 <= '0';
        wait for CCSDS_RXTX_BENCH_RXTX0_RX_CLK0_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_rxtx0_tx_clk0p
    -- bench_sti_rxtx0_tx_clk0 generation
    --=============================================================================
    -- read: 
    -- write: bench_sti_rxtx0_tx_clk0
    -- r/w: 
    BENCH_STI_RXTX0_TX_CLK0P : process
      begin
        bench_sti_rxtx0_tx_clk0 <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_TX_CLK0_PERIOD/2;
        bench_sti_rxtx0_tx_clk0 <= '0';
        wait for CCSDS_RXTX_BENCH_RXTX0_TX_CLK0_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_rxtx0_tx_datap
    -- bench_sti_rxtx0_tx_data generation / aligned with bench_sti_rxtx0_tx_clk0
    --=============================================================================
    -- read: 
    -- write: bench_sti_rxtx0_tx_data_ser0, bench_sti_rxtx0_tx_data_par0
    -- r/w: 
    BENCH_STI_RXTX0_TX_DATAP : process
      variable seed1, seed2 : positive := 1;
      variable random : std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_TX_DATA_BUS_SIZE-1 downto 0);
      begin
        simGetRandomBitVector(CCSDS_RXTX_BENCH_RXTX0_TX_DATA_BUS_SIZE,seed1,seed2,random);
        bench_sti_rxtx0_tx_data_ser0 <= random(0);
        bench_sti_rxtx0_tx_data_par0 <= random;
        wait for CCSDS_RXTX_BENCH_RXTX0_TX_CLK0_PERIOD*1;
      end process;
    --=============================================================================
    -- Begin of bench_sti_rxtx0_rx_samplesp
    -- bench_sti_rxtx0_rx_samples generation / aligned with bench_sti_rxtx0_rx_clk0 signal
    --=============================================================================
    -- read: 
    -- write: bench_sti_rxtx0_rx_samples_par0, bench_sti_rxtx0_rx_samples_par1, bench_sti_rxtx0_rx_samples_par2, bench_sti_rxtx0_rx_samples_ser0, bench_sti_rxtx0_rx_samples_ser1, bench_sti_rxtx0_rx_samples_ser2
    -- r/w: 
    BENCH_STI_RXTX0_RX_SAMPLES0P : process
      variable seed1, seed2 : positive := 1;
      variable random1 : std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      variable random2 : std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      variable random3 : std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      begin
        simGetRandomBitVector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH,seed1,seed2,random1);
        simGetRandomBitVector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH,seed1,seed2,random2);
        simGetRandomBitVector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH,seed1,seed2,random3);
        bench_sti_rxtx0_rx_samples_par0 <= random1;
        bench_sti_rxtx0_rx_samples_par1 <= random2;
        bench_sti_rxtx0_rx_samples_par2 <= random3;
        bench_sti_rxtx0_rx_samples_ser0 <= random1(0);
        bench_sti_rxtx0_rx_samples_ser1 <= random2(0);
        bench_sti_rxtx0_rx_samples_ser2 <= random3(0);
        wait for CCSDS_RXTX_BENCH_RXTX0_RX_CLK0_PERIOD*1;
      end process;
    --=============================================================================
    -- Begin of resetp
    -- generation of reset pulses
    --=============================================================================
    -- read: 
    -- write: bench_sti_rxtx0_wb_rst0
    -- r/w: 
    RESETP : process
      begin
        -- let the system free run
        wait for CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION;
        report "RESETP: Sending reset signal" severity note;
        -- send reset signals
        bench_sti_rxtx0_wb_rst0 <= '1';
        -- wait for some time
        wait for CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION;
        report "RESETP: Reset signal sent" severity note;
        -- stop reset signals
        bench_sti_rxtx0_wb_rst0 <= '0';
        -- do nothing
        wait;
      end process;
    --=============================================================================
    -- Begin of wbrwp
    -- generation of master wb read / write cycles / aligned with clk0
    --=============================================================================
    -- read: bench_res_rxtx0_wb_ack0, bench_res_rxtx0_wb_err0, bench_res_rxtx0_wb_rty0
    -- write: bench_sti_rxtx0_wb_adr0, bench_sti_rxtx0_wb_cyc0, bench_sti_rxtx0_wb_stb0, bench_sti_rxtx0_wb_we0
    -- r/w: 
    WBRWP : process
      begin
        -- let the system free run and reset
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION + CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION + CCSDS_RXTX_BENCH_START_WB_WAIT_DURATION);
        report "WBRWP: Starting WB bus tests" severity note;
        bench_sti_rxtx0_wb_we0 <= '0';
        -- start a basic rx read cycle
        bench_sti_rxtx0_wb_adr0 <= "0000";
        bench_sti_rxtx0_wb_cyc0 <= '1';
        bench_sti_rxtx0_wb_stb0 <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*2;
        if (bench_res_rxtx0_wb_ack0 = '1') or (bench_res_rxtx0_wb_err0 = '1') or (bench_res_rxtx0_wb_rty0 = '1') then
          bench_sti_rxtx0_wb_cyc0 <= '0';
          bench_sti_rxtx0_wb_stb0 <= '0';
          bench_sti_rxtx0_wb_we0 <= '0';
          bench_sti_rxtx0_wb_dat0 <= (others => '0');
          bench_sti_rxtx0_wb_adr0 <= "0000";
          report "WBRWP: OK - Basic RX read cycle success" severity note;
        else
          report "WBRWP: KO - Basic RX read cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*10;
        -- start an error rx read cycle
        bench_sti_rxtx0_wb_adr0 <= "0001";
        bench_sti_rxtx0_wb_cyc0 <= '1';
        bench_sti_rxtx0_wb_stb0 <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*2;
        if (bench_res_rxtx0_wb_ack0 = '1') or (bench_res_rxtx0_wb_err0 = '1') or (bench_res_rxtx0_wb_rty0 = '1') then
          bench_sti_rxtx0_wb_cyc0 <= '0';
          bench_sti_rxtx0_wb_stb0 <= '0';
          bench_sti_rxtx0_wb_we0 <= '0';
          bench_sti_rxtx0_wb_dat0 <= (others => '0');
          bench_sti_rxtx0_wb_adr0 <= "0000";
          report "WBRWP: OK - Basic RX error read cycle success" severity note;
        else
          report "WBRWP: KO - Basic RX error read cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*10;
        -- start a basic configuration write cycle -> enable internal wb data use for tx
        bench_sti_rxtx0_wb_we0 <= '1';
        bench_sti_rxtx0_wb_adr0 <= "0010";
        bench_sti_rxtx0_wb_dat0 <= "00000000000000000000000000000001";
        bench_sti_rxtx0_wb_cyc0 <= '1';
        bench_sti_rxtx0_wb_stb0 <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*2;
        if (bench_res_rxtx0_wb_ack0 = '1') or (bench_res_rxtx0_wb_err0 = '1') or (bench_res_rxtx0_wb_rty0 = '1') then
          bench_sti_rxtx0_wb_cyc0 <= '0';
          bench_sti_rxtx0_wb_stb0 <= '0';
          bench_sti_rxtx0_wb_we0 <= '0';
          bench_sti_rxtx0_wb_dat0 <= (others => '0');
          bench_sti_rxtx0_wb_adr0 <= "0000";
          report "WBRWP: OK - Basic configuration write cycle success" severity note;
        else
          report "WBRWP: KO - Basic configuration write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*10;
        -- start a basic tx write cycle
        bench_sti_rxtx0_wb_we0 <= '1';
        bench_sti_rxtx0_wb_adr0 <= "0000";
        bench_sti_rxtx0_wb_dat0 <= "10101010101010001010111010101010";
        bench_sti_rxtx0_wb_cyc0 <= '1';
        bench_sti_rxtx0_wb_stb0 <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*2;
        if (bench_res_rxtx0_wb_ack0 = '1') or (bench_res_rxtx0_wb_err0 = '1') or (bench_res_rxtx0_wb_rty0 = '1') then
          bench_sti_rxtx0_wb_cyc0 <= '0';
          bench_sti_rxtx0_wb_stb0 <= '0';
          bench_sti_rxtx0_wb_we0 <= '0';
          bench_sti_rxtx0_wb_dat0 <= (others => '0');
          bench_sti_rxtx0_wb_adr0 <= "0000";
          report "WBRWP: OK - Basic TX write cycle success" severity note;
        else
          report "WBRWP: KO - Basic TX write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*10;
        -- start an error basic tx write cycle (unknown address)
        bench_sti_rxtx0_wb_we0 <= '1';
        bench_sti_rxtx0_wb_adr0 <= "0011";
        bench_sti_rxtx0_wb_dat0 <= "10101010101010001010111010101010";
        bench_sti_rxtx0_wb_cyc0 <= '1';
        bench_sti_rxtx0_wb_stb0 <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*2;
        if (bench_res_rxtx0_wb_ack0 = '1') or (bench_res_rxtx0_wb_err0 = '1') or (bench_res_rxtx0_wb_rty0 = '1') then
          bench_sti_rxtx0_wb_cyc0 <= '0';
          bench_sti_rxtx0_wb_stb0 <= '0';
          bench_sti_rxtx0_wb_we0 <= '0';
          bench_sti_rxtx0_wb_dat0 <= (others => '0');
          report "WBRWP: OK - Basic error write cycle success" severity note;
        else
          report "WBRWP: KO - Basic error write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*10;
        -- start a basic tx write cycle - send data
        bench_sti_rxtx0_wb_we0 <= '1';
        bench_sti_rxtx0_wb_adr0 <= "0000";
        bench_sti_rxtx0_wb_dat0 <= "10001010101011111110111010101000";
        bench_sti_rxtx0_wb_cyc0 <= '1';
        bench_sti_rxtx0_wb_stb0 <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*2;
        if (bench_res_rxtx0_wb_ack0 = '1') or (bench_res_rxtx0_wb_err0 = '1') or (bench_res_rxtx0_wb_rty0 = '1') then
          bench_sti_rxtx0_wb_cyc0 <= '0';
          bench_sti_rxtx0_wb_stb0 <= '0';
          bench_sti_rxtx0_wb_we0 <= '0';
          bench_sti_rxtx0_wb_dat0 <= (others => '0');
          bench_sti_rxtx0_wb_adr0 <= "0000";
          report "WBRWP: OK - Basic TX write cycle success" severity note;
        else
          report "WBRWP: KO - Basic TX write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*10;
        -- start a basic configuration write cycle -> disable rx
        bench_sti_rxtx0_wb_we0 <= '1';
        bench_sti_rxtx0_wb_adr0 <= "0001";
        bench_sti_rxtx0_wb_dat0 <= (others => '0');
        bench_sti_rxtx0_wb_cyc0 <= '1';
        bench_sti_rxtx0_wb_stb0 <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*2;
        if (bench_res_rxtx0_wb_ack0 = '1') or (bench_res_rxtx0_wb_err0 = '1') or (bench_res_rxtx0_wb_rty0 = '1') then
          bench_sti_rxtx0_wb_cyc0 <= '0';
          bench_sti_rxtx0_wb_stb0 <= '0';
          bench_sti_rxtx0_wb_we0 <= '0';
          bench_sti_rxtx0_wb_dat0 <= (others => '0');
          bench_sti_rxtx0_wb_adr0 <= "0000";
          report "WBRWP: OK - Basic configuration write cycle success (RX disabled)" severity note;
        else
          report "WBRWP: KO - Basic configuration write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*10;
        -- start a basic configuration write cycle -> disable tx
        bench_sti_rxtx0_wb_we0 <= '1';
        bench_sti_rxtx0_wb_adr0 <= "0010";
        bench_sti_rxtx0_wb_dat0 <= (others => '0');
        bench_sti_rxtx0_wb_cyc0 <= '1';
        bench_sti_rxtx0_wb_stb0 <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*2;
        if (bench_res_rxtx0_wb_ack0 = '1') or (bench_res_rxtx0_wb_err0 = '1') or (bench_res_rxtx0_wb_rty0 = '1') then
          bench_sti_rxtx0_wb_cyc0 <= '0';
          bench_sti_rxtx0_wb_stb0 <= '0';
          bench_sti_rxtx0_wb_we0 <= '0';
          bench_sti_rxtx0_wb_dat0 <= (others => '0');
          bench_sti_rxtx0_wb_adr0 <= "0000";
          report "WBRWP: OK - Basic configuration write cycle success (TX disabled)" severity note;
        else
          report "WBRWP: KO - Basic configuration write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*10;
        -- start a basic configuration write cycle -> enable tx
        bench_sti_rxtx0_wb_we0 <= '1';
        bench_sti_rxtx0_wb_adr0 <= "0010";
        bench_sti_rxtx0_wb_dat0 <= "00000000000000000000000000000001";
        bench_sti_rxtx0_wb_cyc0 <= '1';
        bench_sti_rxtx0_wb_stb0 <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*2;
        if (bench_res_rxtx0_wb_ack0 = '1') or (bench_res_rxtx0_wb_err0 = '1') or (bench_res_rxtx0_wb_rty0 = '1') then
          bench_sti_rxtx0_wb_cyc0 <= '0';
          bench_sti_rxtx0_wb_stb0 <= '0';
          bench_sti_rxtx0_wb_we0 <= '0';
          bench_sti_rxtx0_wb_dat0 <= (others => '0');
          bench_sti_rxtx0_wb_adr0 <= "0000";
          report "WBRWP: OK - Basic configuration write cycle success (TX enabled)" severity note;
        else
          report "WBRWP: KO - Basic configuration write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*1;
        -- start a basic tx write cycle
        bench_sti_rxtx0_wb_we0 <= '1';
        bench_sti_rxtx0_wb_adr0 <= "0000";
        bench_sti_rxtx0_wb_dat0 <= "11101010101010001010111010101111";
        bench_sti_rxtx0_wb_cyc0 <= '1';
        bench_sti_rxtx0_wb_stb0 <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*2;
        if (bench_res_rxtx0_wb_ack0 = '1') or (bench_res_rxtx0_wb_err0 = '1') or (bench_res_rxtx0_wb_rty0 = '1') then
          bench_sti_rxtx0_wb_cyc0 <= '0';
          bench_sti_rxtx0_wb_stb0 <= '0';
          bench_sti_rxtx0_wb_we0 <= '0';
          bench_sti_rxtx0_wb_dat0 <= (others => '0');
          bench_sti_rxtx0_wb_adr0 <= "0000";
          report "WBRWP: OK - Basic TX write cycle success" severity note;
        else
          report "WBRWP: KO - Basic TX write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*1;
        -- start a basic tx write cycle
        bench_sti_rxtx0_wb_we0 <= '1';
        bench_sti_rxtx0_wb_adr0 <= "0000";
        bench_sti_rxtx0_wb_dat0 <= "10101011101010001010111010101011";
        bench_sti_rxtx0_wb_cyc0 <= '1';
        bench_sti_rxtx0_wb_stb0 <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*2;
        if (bench_res_rxtx0_wb_ack0 = '1') or (bench_res_rxtx0_wb_err0 = '1') or (bench_res_rxtx0_wb_rty0 = '1') then
          bench_sti_rxtx0_wb_cyc0 <= '0';
          bench_sti_rxtx0_wb_stb0 <= '0';
          bench_sti_rxtx0_wb_we0 <= '0';
          bench_sti_rxtx0_wb_dat0 <= (others => '0');
          bench_sti_rxtx0_wb_adr0 <= "0000";
          report "WBRWP: OK - Basic TX write cycle success" severity note;
        else
          report "WBRWP: KO - Basic TX write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*1;
        -- start a basic tx write cycle
        bench_sti_rxtx0_wb_we0 <= '1';
        bench_sti_rxtx0_wb_adr0 <= "0000";
        bench_sti_rxtx0_wb_dat0 <= "10101010101011111010111010101010";
        bench_sti_rxtx0_wb_cyc0 <= '1';
        bench_sti_rxtx0_wb_stb0 <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*2;
        if (bench_res_rxtx0_wb_ack0 = '1') or (bench_res_rxtx0_wb_err0 = '1') or (bench_res_rxtx0_wb_rty0 = '1') then
          bench_sti_rxtx0_wb_cyc0 <= '0';
          bench_sti_rxtx0_wb_stb0 <= '0';
          bench_sti_rxtx0_wb_we0 <= '0';
          bench_sti_rxtx0_wb_dat0 <= (others => '0');
          bench_sti_rxtx0_wb_adr0 <= "0000";
          report "WBRWP: OK - Basic TX write cycle success" severity note;
        else
          report "WBRWP: KO - Basic TX write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*1;
        -- start a basic tx write cycle
        bench_sti_rxtx0_wb_we0 <= '1';
        bench_sti_rxtx0_wb_adr0 <= "0000";
        bench_sti_rxtx0_wb_dat0 <= "10111010101010001010111010101011";
        bench_sti_rxtx0_wb_cyc0 <= '1';
        bench_sti_rxtx0_wb_stb0 <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*2;
        if (bench_res_rxtx0_wb_ack0 = '1') or (bench_res_rxtx0_wb_err0 = '1') or (bench_res_rxtx0_wb_rty0 = '1') then
          bench_sti_rxtx0_wb_cyc0 <= '0';
          bench_sti_rxtx0_wb_stb0 <= '0';
          bench_sti_rxtx0_wb_we0 <= '0';
          bench_sti_rxtx0_wb_dat0 <= (others => '0');
          bench_sti_rxtx0_wb_adr0 <= "0000";
          report "WBRWP: OK - Basic TX write cycle success" severity note;
        else
          report "WBRWP: KO - Basic TX write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*25;
        -- start a basic tx write cycle
        bench_sti_rxtx0_wb_we0 <= '1';
        bench_sti_rxtx0_wb_adr0 <= "0000";
        bench_sti_rxtx0_wb_dat0 <= "10101010101010001011111110101010";
        bench_sti_rxtx0_wb_cyc0 <= '1';
        bench_sti_rxtx0_wb_stb0 <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*2;
        if (bench_res_rxtx0_wb_ack0 = '1') or (bench_res_rxtx0_wb_err0 = '1') or (bench_res_rxtx0_wb_rty0 = '1') then
          bench_sti_rxtx0_wb_cyc0 <= '0';
          bench_sti_rxtx0_wb_stb0 <= '0';
          bench_sti_rxtx0_wb_we0 <= '0';
          bench_sti_rxtx0_wb_dat0 <= (others => '0');
          bench_sti_rxtx0_wb_adr0 <= "0000";
          report "WBRWP: OK - Basic TX write cycle success" severity note;
        else
          report "WBRWP: KO - Basic TX write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*1;
        -- start a basic tx write cycle
        bench_sti_rxtx0_wb_we0 <= '1';
        bench_sti_rxtx0_wb_adr0 <= "0000";
        bench_sti_rxtx0_wb_dat0 <= "11111011111010101011111110101110";
        bench_sti_rxtx0_wb_cyc0 <= '1';
        bench_sti_rxtx0_wb_stb0 <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*2;
        if (bench_res_rxtx0_wb_ack0 = '1') or (bench_res_rxtx0_wb_err0 = '1') or (bench_res_rxtx0_wb_rty0 = '1') then
          bench_sti_rxtx0_wb_cyc0 <= '0';
          bench_sti_rxtx0_wb_stb0 <= '0';
          bench_sti_rxtx0_wb_we0 <= '0';
          bench_sti_rxtx0_wb_dat0 <= (others => '0');
          bench_sti_rxtx0_wb_adr0 <= "0000";
          report "WBRWP: OK - Basic TX write cycle success" severity note;
        else
          report "WBRWP: KO - Basic TX write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*1;
        -- start a basic tx write cycle
        bench_sti_rxtx0_wb_we0 <= '1';
        bench_sti_rxtx0_wb_adr0 <= "0000";
        bench_sti_rxtx0_wb_dat0 <= "10111011111010101011111110101010";
        bench_sti_rxtx0_wb_cyc0 <= '1';
        bench_sti_rxtx0_wb_stb0 <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*2;
        if (bench_res_rxtx0_wb_ack0 = '1') or (bench_res_rxtx0_wb_err0 = '1') or (bench_res_rxtx0_wb_rty0 = '1') then
          bench_sti_rxtx0_wb_cyc0 <= '0';
          bench_sti_rxtx0_wb_stb0 <= '0';
          bench_sti_rxtx0_wb_we0 <= '0';
          bench_sti_rxtx0_wb_dat0 <= (others => '0');
          bench_sti_rxtx0_wb_adr0 <= "0000";
          report "WBRWP: OK - Basic TX write cycle success" severity note;
        else
          report "WBRWP: KO - Basic TX write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*1;
        -- start a basic tx write cycle
        bench_sti_rxtx0_wb_we0 <= '1';
        bench_sti_rxtx0_wb_adr0 <= "0000";
        bench_sti_rxtx0_wb_dat0 <= "10111011111010001011111111101010";
        bench_sti_rxtx0_wb_cyc0 <= '1';
        bench_sti_rxtx0_wb_stb0 <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*2;
        if (bench_res_rxtx0_wb_ack0 = '1') or (bench_res_rxtx0_wb_err0 = '1') or (bench_res_rxtx0_wb_rty0 = '1') then
          bench_sti_rxtx0_wb_cyc0 <= '0';
          bench_sti_rxtx0_wb_stb0 <= '0';
          bench_sti_rxtx0_wb_we0 <= '0';
          bench_sti_rxtx0_wb_dat0 <= (others => '0');
          bench_sti_rxtx0_wb_adr0 <= "0000";
          report "WBRWP: OK - Basic TX write cycle success" severity note;
        else
          report "WBRWP: KO - Basic TX write cycle fail" severity warning;
        end if;
        wait;
      end process;
end behaviour;
--=============================================================================
-- architecture end
--=============================================================================
