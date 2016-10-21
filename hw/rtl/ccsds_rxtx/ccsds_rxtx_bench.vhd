-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rxtx_bench
---- Version: 1.0.0
---- Description:
---- Unit level + sub-components testing vhdl ressource
---- 1: generate clock signals
---- 2: generate resets signals
---- 3: generate wb read/write cycles signals
---- 4: generate rx/tx external data and samples signals
---- 5: generate test sequences for sub-components
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
---- 2016/10/19: adding sub-components (CRC + buffer) test ressources
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
    -- system parameters
    CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH: integer := RX_PHYS_SIG_QUANT_DEPTH;
    CCSDS_RXTX_BENCH_RXTX0_TX_PHYS_SIG_QUANT_DEPTH: integer := TX_PHYS_SIG_QUANT_DEPTH;
    CCSDS_RXTX_BENCH_RXTX0_WB_ADDR_BUS_SIZE: integer := RXTX_SYSTEM_WB_ADDR_BUS_SIZE;
    CCSDS_RXTX_BENCH_RXTX0_WB_DATA_BUS_SIZE: integer := RXTX_SYSTEM_WB_DATA_BUS_SIZE;
    -- sub-systems parameters
    --CRC
    CCSDS_RXTX_BENCH_CRC0_DATA: std_logic_vector := x"313233343536373839";
    CCSDS_RXTX_BENCH_CRC0_RESULT: std_logic_vector := x"e5cc";
    CCSDS_RXTX_BENCH_CRC0_LENGTH: integer := 2;
    CCSDS_RXTX_BENCH_CRC0_POLYNOMIAL: std_logic_vector := x"1021";
    CCSDS_RXTX_BENCH_CRC0_SEED: std_logic_vector := x"ffff";
    CCSDS_RXTX_BENCH_CRC0_XOR: std_logic_vector := x"0000";
    CCSDS_RXTX_BENCH_CRC0_OUTPUT_REFLECTED: std_logic := '0';
    CCSDS_RXTX_BENCH_CRC0_INPUT_REFLECTED: std_logic := '0';
    CCSDS_RXTX_BENCH_CRC0_INPUT_BYTES_REFLECTED: std_logic := '0';
    CCSDS_RXTX_BENCH_CRC0_POLYNOMIAL_REFLECTED: std_logic := '0';
    --BUFFER
    CCSDS_RXTX_BENCH_BUFFER0_DATA_BUS_SIZE : integer := 32;
    CCSDS_RXTX_BENCH_BUFFER0_SIZE : integer := 256;
    -- simulation/test parameters
    CCSDS_RXTX_BENCH_SEED: integer := 1;
    CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_RXTX0_RX_CLK0_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_RXTX0_TX_CLK0_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_CRC0_CLK0_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_BUFFER0_CLK0_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION: time := 1000 ns;
    CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION: time := 1000 ns;
    CCSDS_RXTX_BENCH_START_WB_WAIT_DURATION: time := 1000 ns;
    CCSDS_RXTX_BENCH_START_CRC_WAIT_DURATION: time := 3000 ns;
    CCSDS_RXTX_BENCH_START_BUFFER_WAIT_DURATION: time := 8000 ns
  );
end ccsds_rxtx_bench;

--=============================================================================
-- architecture declaration / internal processing
--=============================================================================
architecture behaviour of ccsds_rxtx_bench is
  component ccsds_rxtx_top is
    port(
      irq_o: out std_logic;
      wb_ack_o: out std_logic;
      wb_adr_i: in std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_WB_ADDR_BUS_SIZE-1 downto 0);
      wb_clk_i: in std_logic;
      wb_cyc_i: in std_logic;
      wb_dat_i: in std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_WB_DATA_BUS_SIZE-1 downto 0);
      wb_dat_o: out std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_WB_DATA_BUS_SIZE-1 downto 0);
      wb_err_o: out std_logic;
      wb_rst_i: in std_logic;
      wb_rty_o: out std_logic;
      wb_stb_i: in std_logic;
      wb_we_i: in std_logic;
      rx_clk_i: in std_logic;
      rx_i_samples_i: in std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      rx_q_samples_i: in std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      rx_enabled_o: out std_logic;
      tx_clk_i: in std_logic;
      tx_data_ser_i: in std_logic;
      tx_i_samples_o: out std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      tx_q_samples_o: out std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      tx_clk_o: out std_logic;
      tx_enabled_o: out std_logic
    );
  end component;
  component ccsds_rxtx_crc is
  generic(
    CCSDS_RXTX_CRC_LENGTH: integer;
    CCSDS_RXTX_CRC_DATA_LENGTH: integer;
    CCSDS_RXTX_CRC_POLYNOMIAL: std_logic_vector;
    CCSDS_RXTX_CRC_SEED: std_logic_vector;
    CCSDS_RXTX_CRC_OUTPUT_REFLECTED: std_logic;
    CCSDS_RXTX_CRC_INPUT_REFLECTED: std_logic;
    CCSDS_RXTX_CRC_INPUT_BYTES_REFLECTED: std_logic;
    CCSDS_RXTX_CRC_POLYNOMIAL_REFLECTED: std_logic;
    CCSDS_RXTX_CRC_FINAL_XOR: std_logic_vector
  );
  port(
    clk_i: in std_logic;
    rst_i: in std_logic;
    nxt_i: in std_logic;
    busy_o: out std_logic;
    data_i: in std_logic_vector(CCSDS_RXTX_CRC_DATA_LENGTH*8-1 downto 0);
    data_o: out std_logic_vector(CCSDS_RXTX_CRC_LENGTH*8-1 downto 0);
    data_valid_o: out std_logic
  );
  end component;
  component ccsds_rxtx_buffer is
    generic(
      CCSDS_RXTX_BUFFER_DATA_BUS_SIZE : integer;
      CCSDS_RXTX_BUFFER_SIZE : integer
    );
    port(
      clk_i: in std_logic;
      rst_i: in std_logic;
      buffer_empty_o: out std_logic;
      buffer_full_o: out std_logic;
      next_data_i: in std_logic;
      data_i: in std_logic_vector(CCSDS_RXTX_BUFFER_DATA_BUS_SIZE-1 downto 0);
      data_valid_i: in std_logic;
      data_o: out std_logic_vector(CCSDS_RXTX_BUFFER_DATA_BUS_SIZE-1 downto 0);
      data_valid_o: out std_logic
    );
  end component;

-- synthetic generated stimuli
--NB: un-initialized on purposes - to allow observation of components default behaviour
  -- wishbone bus
  signal bench_sti_rxtx0_wb_clk0: std_logic;
  signal bench_sti_rxtx0_wb_rst0: std_logic;
  signal bench_sti_rxtx0_wb_adr0: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_WB_ADDR_BUS_SIZE-1 downto 0);
  signal bench_sti_rxtx0_wb_cyc0: std_logic;
  signal bench_sti_rxtx0_wb_dat0: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_WB_DATA_BUS_SIZE-1 downto 0);
  signal bench_sti_rxtx0_wb_stb0: std_logic;
  signal bench_sti_rxtx0_wb_we0: std_logic;
  -- rx
  signal bench_sti_rxtx0_rx_clk0: std_logic;
  signal bench_sti_rxtx0_rx_data_next0: std_logic;
  signal bench_sti_rxtx0_rx_samples_par0: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
  signal bench_sti_rxtx0_rx_samples_par1: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
  -- tx
  signal bench_sti_rxtx0_tx_clk0: std_logic;
  signal bench_sti_rxtx0_tx_data_ser0: std_logic;
  -- crc
  signal bench_sti_crc0_clk0: std_logic;
  signal bench_sti_crc0_rst0: std_logic;
  signal bench_sti_crc0_nxt0: std_logic;
  signal bench_sti_crc0_data0: std_logic_vector(CCSDS_RXTX_BENCH_CRC0_DATA'length-1 downto 0);
  -- buffer
  signal bench_sti_buffer0_clk0: std_logic;
  signal bench_sti_buffer0_rst0: std_logic;
  signal bench_sti_buffer0_next_data0: std_logic;
  signal bench_sti_buffer0_data0: std_logic_vector(CCSDS_RXTX_BENCH_BUFFER0_DATA_BUS_SIZE-1 downto 0);
  signal bench_sti_buffer0_data_valid0: std_logic;
-- core generated response
  signal bench_res_rxtx0_irq0: std_logic;
  -- wishbone bus
  signal bench_res_rxtx0_wb_ack0: std_logic;
  signal bench_res_rxtx0_wb_dat0: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_WB_DATA_BUS_SIZE-1 downto 0);
  signal bench_res_rxtx0_wb_err0: std_logic;
  signal bench_res_rxtx0_wb_rty0: std_logic;
  -- rx
  signal bench_res_rxtx0_rx_enabled0: std_logic;
  -- tx
  signal bench_res_rxtx0_tx_clk0: std_logic;
  signal bench_res_rxtx0_tx_samples_par0: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
  signal bench_res_rxtx0_tx_samples_par1: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
  signal bench_res_rxtx0_tx_enabled0: std_logic;
  -- crc
  signal bench_res_crc0_busy0: std_logic;
  signal bench_res_crc0_data0: std_logic_vector(CCSDS_RXTX_BENCH_CRC0_LENGTH*8-1 downto 0);
  signal bench_res_crc0_data_valid0: std_logic;
  -- buffer
  signal bench_res_buffer0_buffer_empty0: std_logic;
  signal bench_res_buffer0_buffer_full0: std_logic;
  signal bench_res_buffer0_data0: std_logic_vector(CCSDS_RXTX_BENCH_BUFFER0_DATA_BUS_SIZE-1 downto 0);
  signal bench_res_buffer0_data_valid0: std_logic;

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
        rx_i_samples_i => bench_sti_rxtx0_rx_samples_par0,
        rx_q_samples_i => bench_sti_rxtx0_rx_samples_par1,
        rx_enabled_o => bench_res_rxtx0_rx_enabled0,
        tx_clk_i => bench_sti_rxtx0_tx_clk0,
        tx_data_ser_i => bench_sti_rxtx0_tx_data_ser0,
        tx_i_samples_o => bench_res_rxtx0_tx_samples_par0,
        tx_q_samples_o => bench_res_rxtx0_tx_samples_par1,
        tx_clk_o => bench_res_rxtx0_tx_clk0,
        tx_enabled_o => bench_res_rxtx0_tx_enabled0
      );
    -- Instance(s) of sub-components under test
    crc_001: ccsds_rxtx_crc
      generic map(
        CCSDS_RXTX_CRC_DATA_LENGTH => CCSDS_RXTX_BENCH_CRC0_DATA'length/8,
        CCSDS_RXTX_CRC_LENGTH => CCSDS_RXTX_BENCH_CRC0_LENGTH,
        CCSDS_RXTX_CRC_POLYNOMIAL => CCSDS_RXTX_BENCH_CRC0_POLYNOMIAL,
        CCSDS_RXTX_CRC_SEED => CCSDS_RXTX_BENCH_CRC0_SEED,
        CCSDS_RXTX_CRC_INPUT_REFLECTED => CCSDS_RXTX_BENCH_CRC0_INPUT_REFLECTED,
        CCSDS_RXTX_CRC_INPUT_BYTES_REFLECTED => CCSDS_RXTX_BENCH_CRC0_INPUT_BYTES_REFLECTED,
        CCSDS_RXTX_CRC_OUTPUT_REFLECTED => CCSDS_RXTX_BENCH_CRC0_OUTPUT_REFLECTED,
        CCSDS_RXTX_CRC_POLYNOMIAL_REFLECTED => CCSDS_RXTX_BENCH_CRC0_POLYNOMIAL_REFLECTED,
        CCSDS_RXTX_CRC_FINAL_XOR => CCSDS_RXTX_BENCH_CRC0_XOR
      )
      port map(
        clk_i => bench_sti_crc0_clk0,
        rst_i => bench_sti_crc0_rst0,
        nxt_i => bench_sti_crc0_nxt0,
        busy_o => bench_res_crc0_busy0,
        data_i => bench_sti_crc0_data0,
        data_o => bench_res_crc0_data0,
        data_valid_o => bench_res_crc0_data_valid0
      );
    buffer_001: ccsds_rxtx_buffer
      generic map(
        CCSDS_RXTX_BUFFER_DATA_BUS_SIZE => CCSDS_RXTX_BENCH_BUFFER0_DATA_BUS_SIZE,
        CCSDS_RXTX_BUFFER_SIZE => CCSDS_RXTX_BENCH_BUFFER0_SIZE
      )
      port map(
        clk_i => bench_sti_buffer0_clk0,
        rst_i => bench_sti_buffer0_rst0,
        data_valid_i => bench_sti_buffer0_data_valid0,
        data_i => bench_sti_buffer0_data0,
        data_valid_o => bench_res_buffer0_data_valid0,
        buffer_empty_o => bench_res_buffer0_buffer_empty0,
        buffer_full_o => bench_res_buffer0_buffer_full0,
        next_data_i => bench_sti_buffer0_next_data0,
        data_o => bench_res_buffer0_data0
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
    -- Begin of bench_sti_crc0_clk0p
    -- bench_sti_crc0_clk0 generation
    --=============================================================================
    -- read: 
    -- write: bench_sti_crc0_clk0
    -- r/w: 
    BENCH_STI_CRC0_CLK0P : process
      begin
        bench_sti_crc0_clk0 <= '1';
        wait for CCSDS_RXTX_BENCH_CRC0_CLK0_PERIOD/2;
        bench_sti_crc0_clk0 <= '0';
        wait for CCSDS_RXTX_BENCH_CRC0_CLK0_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_buffer0_clk0p
    -- bench_sti_buffer0_clk0 generation
    --=============================================================================
    -- read: 
    -- write: bench_sti_buffer0_clk0
    -- r/w: 
    BENCH_STI_BUFFER0_CLK0P : process
      begin
        bench_sti_buffer0_clk0 <= '1';
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK0_PERIOD/2;
        bench_sti_buffer0_clk0 <= '0';
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK0_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_rxtx0_tx_datap
    -- bench_sti_rxtx0_tx_data generation / dephased from 1/2 clk with bench_sti_rxtx0_tx_clk0
    --=============================================================================
    -- read: 
    -- write: bench_sti_rxtx0_tx_data_ser0
    -- r/w: 
    BENCH_STI_RXTX0_TX_DATAP : process
      variable seed1, seed2 : positive := CCSDS_RXTX_BENCH_SEED;
      variable random : std_logic_vector(1 downto 0);
      begin
        wait for CCSDS_RXTX_BENCH_RXTX0_TX_CLK0_PERIOD/2;
        sim_generate_random_std_logic_vector(2,seed1,seed2,random);
        bench_sti_rxtx0_tx_data_ser0 <= random(0);
        wait for CCSDS_RXTX_BENCH_RXTX0_TX_CLK0_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_buffer0_datap
    -- bench_sti_buffer0_data0 generation / dephased from 1/2 clk with bench_sti_buffer0_clk0
    --=============================================================================
    -- read: 
    -- write: bench_sti_buffer0_data0
    -- r/w: 
    BENCH_STI_BUFFER0_DATAP : process
      variable seed1, seed2 : positive := CCSDS_RXTX_BENCH_SEED;
      variable random : std_logic_vector(CCSDS_RXTX_BENCH_BUFFER0_DATA_BUS_SIZE-1 downto 0);
      begin
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK0_PERIOD/2;
        sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_BUFFER0_DATA_BUS_SIZE,seed1,seed2,random);
        bench_sti_buffer0_data0 <= random;
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK0_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_rxtx0_rx_samplesp
    -- bench_sti_rxtx0_rx_samples generation / dephased from 1/2 clk with bench_sti_rxtx0_rx_clk0 signal
    --=============================================================================
    -- read: 
    -- write: bench_sti_rxtx0_rx_samples_par0, bench_sti_rxtx0_rx_samples_par1
    -- r/w: 
    BENCH_STI_RXTX0_RX_SAMPLES0P : process
      variable seed1, seed2 : positive := CCSDS_RXTX_BENCH_SEED;
      variable random1 : std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      variable random2 : std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      begin
        wait for CCSDS_RXTX_BENCH_RXTX0_RX_CLK0_PERIOD/2;
        sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH,seed1,seed2,random1);
        sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH,seed2,seed1,random2);
        bench_sti_rxtx0_rx_samples_par0 <= random1;
        bench_sti_rxtx0_rx_samples_par1 <= random2;
        wait for CCSDS_RXTX_BENCH_RXTX0_RX_CLK0_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of crcp
    -- generation of crc subsystem unit-tests
    --=============================================================================
    -- read: bench_res_crc0_data0, bench_res_crc0_data_valid0
    -- write: bench_sti_crc0_nxt0, bench_sti_crc0_data0
    -- r/w: 
    CRCP : process
      begin
        -- let the system free run
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION + CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION + CCSDS_RXTX_BENCH_START_CRC_WAIT_DURATION);
        report "CRCP: START CRC COMPUTATION TESTS" severity note;
        -- present crc test data
        bench_sti_crc0_data0 <= CCSDS_RXTX_BENCH_CRC0_DATA;
        -- send next crc signal
        bench_sti_crc0_nxt0 <= '1';
        -- wait for one clk
        wait for CCSDS_RXTX_BENCH_CRC0_CLK0_PERIOD;
        report "CRCP: Next signal sent" severity note;
        -- stop next signal
        bench_sti_crc0_nxt0 <= '0';
        -- remove crc test data
        bench_sti_crc0_data0 <= (others => '0');
        -- wait for result
        wait for CCSDS_RXTX_BENCH_CRC0_CLK0_PERIOD*(CCSDS_RXTX_BENCH_CRC0_DATA'length+CCSDS_RXTX_BENCH_CRC0_LENGTH*8+1);
        if (bench_res_crc0_data0 = CCSDS_RXTX_BENCH_CRC0_RESULT) and (bench_res_crc0_data_valid0 = '1') then
          report "CRCP: OK - Output CRC is conform to expectations" severity note;
        else
          report "CRCP: KO - Output CRC is not equals to expectations" severity warning;
          report "Received value:" severity note;
          for i in 0 to bench_res_crc0_data0'length-1 loop
            report std_logic'image(bench_res_crc0_data0(i));
          end loop;
          report "Expected value:" severity note;
          for i in 0 to CCSDS_RXTX_BENCH_CRC0_RESULT'length-1 loop
            report std_logic'image(CCSDS_RXTX_BENCH_CRC0_RESULT(i));
          end loop;
        end if;
        report "CRCP: END CRC COMPUTATION TESTS" severity note;
        -- do nothing
        wait;
      end process;
    --=============================================================================
    -- Begin of bufferp
    -- generation of buffer subsystem unit-tests
    --=============================================================================
    -- read: bench_res_buffer0_buffer_empty0, bench_res_buffer0_buffer_full0, bench_res_buffer0_data0, bench_res_buffer0_data_valid0
    -- write: bench_sti_buffer0_data_valid0, bench_sti_buffer0_next_data0
    -- r/w: 
    BUFFERP : process
      type buffer_array is array (CCSDS_RXTX_BENCH_BUFFER0_SIZE downto 0) of std_logic_vector(CCSDS_RXTX_BENCH_BUFFER0_DATA_BUS_SIZE-1 downto 0);
      variable buffer_expected_stored_data: buffer_array := (others => (others => '0'));
      begin
        -- let the system free run
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION + CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION + CCSDS_RXTX_BENCH_START_BUFFER_WAIT_DURATION + CCSDS_RXTX_BENCH_BUFFER0_CLK0_PERIOD/2);
        report "BUFFERP: START BUFFER READ-WRITE TESTS" severity note;
        -- check buffer is empty
        if (bench_res_buffer0_buffer_empty0 = '1') then
          report "BUFFERP: OK - Buffer is empty" severity note;
        else
          report "BUFFERP: KO - Buffer is not empty" severity warning;
        end if;
        -- check buffer is not full
        if (bench_res_buffer0_buffer_full0 = '0')then
          report "BUFFERP: OK - Buffer is not full" severity note;
        else
          report "BUFFERP: KO - Buffer is full" severity warning;
        end if;
        -- ask for data
        bench_sti_buffer0_next_data0 <= '1';
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK0_PERIOD;
        if (bench_res_buffer0_data_valid0 = '0') then
          report "BUFFERP: OK - No data came out with an empty buffer" severity note;
        else
          report "BUFFERP: KO - Data came out - buffer is empty / incoherent" severity warning;
        end if;
        bench_sti_buffer0_next_data0 <= '0';
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK0_PERIOD;
        -- store data
        bench_sti_buffer0_data_valid0 <= '1';
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK0_PERIOD/2;
        buffer_expected_stored_data(0) := bench_sti_buffer0_data0;
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK0_PERIOD/2;
        bench_sti_buffer0_data_valid0 <= '0';
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK0_PERIOD;
        if (bench_res_buffer0_buffer_empty0 = '0') then
          report "BUFFERP: OK - Buffer is not empty" severity note;
        else
          report "BUFFERP: KO - Buffer should not be empty" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK0_PERIOD;
        -- get data
        bench_sti_buffer0_next_data0 <= '1';
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK0_PERIOD;
        bench_sti_buffer0_next_data0 <= '0';
        if (bench_res_buffer0_data_valid0 = '1') then
          report "BUFFERP: OK - Buffer data valid signal received" severity note;
        else
          report "BUFFERP: KO - Buffer data valid signal not received" severity warning;
        end if;
        if (bench_res_buffer0_data0 = buffer_expected_stored_data(0)) then
          report "BUFFERP: OK - Received value is equal to from previously stored value" severity note;
        else
          report "BUFFERP: KO - Received value is different from previously stored value" severity warning;
          report "Received value:" severity note;
          for i in 0 to bench_res_buffer0_data0'length-1 loop
            report std_logic'image(bench_res_buffer0_data0(i));
          end loop;
          report "Expected value:" severity note;
          for i in 0 to buffer_expected_stored_data(0)'length-1 loop
            report std_logic'image(buffer_expected_stored_data(0)(i));
          end loop;
        end if;
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK0_PERIOD;
        if (bench_res_buffer0_buffer_empty0 = '1') then
          report "BUFFERP: OK - Buffer is empty after reading value" severity note;
        else
          report "BUFFERP: KO - Buffer is not empty" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK0_PERIOD;
        -- store lot of data / make the buffer full
        bench_sti_buffer0_data_valid0 <= '1';
        for i in 0 to CCSDS_RXTX_BENCH_BUFFER0_SIZE loop
          wait for CCSDS_RXTX_BENCH_BUFFER0_CLK0_PERIOD/2;
          buffer_expected_stored_data(i) := bench_sti_buffer0_data0;
          wait for CCSDS_RXTX_BENCH_BUFFER0_CLK0_PERIOD/2;
          if (bench_res_buffer0_buffer_full0 = '1') then
            if (i < CCSDS_RXTX_BENCH_BUFFER0_SIZE) then
              report "BUFFERP: KO - Buffer is full too early - loop: " & integer'image(i) & " value of the buffer array" severity warning;
            else
              report "BUFFERP: OK - Buffer is full after all write operations" severity note;
            end if;
          else
            if (i = CCSDS_RXTX_BENCH_BUFFER0_SIZE) then
              report "BUFFERP: KO - Buffer is not full after all write operations" severity note;
            end if;
          end if;
        end loop;
        bench_sti_buffer0_data_valid0 <= '0';
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK0_PERIOD;
        -- read all data / make the buffer empty
        bench_sti_buffer0_next_data0 <= '1';
        for i in 0 to CCSDS_RXTX_BENCH_BUFFER0_SIZE loop
          wait for CCSDS_RXTX_BENCH_BUFFER0_CLK0_PERIOD;
          if (buffer_expected_stored_data(i) /= bench_res_buffer0_data0) then
            if (i < CCSDS_RXTX_BENCH_BUFFER0_SIZE) then
              report "BUFFERP: KO - Buffer received value is different from previously stored value - loop: " & integer'image(i) severity warning;
            end if;
          end if;
          if (bench_res_buffer0_data_valid0 = '0') then
            if (i < CCSDS_RXTX_BENCH_BUFFER0_SIZE) then
              report "BUFFERP: KO - Buffer data valid signal not received - loop: " & integer'image(i) severity warning;
            end if;
          end if;
          if (bench_res_buffer0_buffer_empty0 = '1') then
            if (i < CCSDS_RXTX_BENCH_BUFFER0_SIZE) then
              report "BUFFERP: KO - Buffer data empty signal received too early - loop: " & integer'image(i) severity warning;
            else
              report "BUFFERP: OK - Buffer is empty after all read operations" severity note;
            end if;
          else
            if (i = CCSDS_RXTX_BENCH_BUFFER0_SIZE) then
              report "BUFFERP: KO - Buffer is not empty after all read operations" severity warning;
            end if;
          end if;
        end loop;
        bench_sti_buffer0_data_valid0 <= '0';
        report "BUFFERP: END BUFFER READ-WRITE TESTS" severity note;
        -- do nothing
        wait;
      end process;
    --=============================================================================
    -- Begin of resetp
    -- generation of reset pulses
    --=============================================================================
    -- read: 
    -- write: bench_sti_rxtx0_wb_rst0, bench_sti_crc0_rst0
    -- r/w: 
    RESETP : process
      begin
        -- let the system free run
        wait for CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION;
        report "RESETP: START RESET SIGNAL TEST" severity note;
        -- send reset signals
        bench_sti_rxtx0_wb_rst0 <= '1';
        bench_sti_crc0_rst0 <= '1';
        bench_sti_buffer0_rst0 <= '1';
        -- wait for some time
        wait for CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION;
        report "RESETP: END RESET SIGNAL TEST" severity note;
        -- stop reset signals
        bench_sti_rxtx0_wb_rst0 <= '0';
        bench_sti_crc0_rst0 <= '0';
        bench_sti_buffer0_rst0 <= '0';
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
        report "WBRWP: START WISHBONE BUS READ-WRITE TESTS" severity note;
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
        -- start a basic configuration write cycle -> enable tx + external serial data activation
        bench_sti_rxtx0_wb_we0 <= '1';
        bench_sti_rxtx0_wb_adr0 <= "0010";
        bench_sti_rxtx0_wb_dat0 <= "00000000000000000000000000000011";
        bench_sti_rxtx0_wb_cyc0 <= '1';
        bench_sti_rxtx0_wb_stb0 <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK0_PERIOD*2;
        if (bench_res_rxtx0_wb_ack0 = '1') or (bench_res_rxtx0_wb_err0 = '1') or (bench_res_rxtx0_wb_rty0 = '1') then
          bench_sti_rxtx0_wb_cyc0 <= '0';
          bench_sti_rxtx0_wb_stb0 <= '0';
          bench_sti_rxtx0_wb_we0 <= '0';
          bench_sti_rxtx0_wb_dat0 <= (others => '0');
          bench_sti_rxtx0_wb_adr0 <= "0000";
          report "WBRWP: OK - Basic configuration write cycle success (TX enabled + external serial data input activated)" severity note;
        else
          report "WBRWP: KO - Basic configuration write cycle fail" severity warning;
        end if;
        report "WBRWP: END WISHBONE BUS READ-WRITE TESTS" severity note;
        wait;
      end process;
end behaviour;
--=============================================================================
-- architecture end
--=============================================================================
