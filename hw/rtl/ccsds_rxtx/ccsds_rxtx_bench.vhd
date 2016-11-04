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
---- 2016/10/25: adding framer sub-component test ressources + CRC checks
---- 2016/10/27: adding serdes sub-component test ressources
---- 2016/10/30: framer tests improvements
---- 2016/11/04: adding lfsr sub-component test ressources
-------------------------------
--TODO: functions for sub-components interactions and checks (wb_read, wb_write, buffer_read, ...)

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
    -- BUFFER
    CCSDS_RXTX_BENCH_BUFFER0_DATA_BUS_SIZE : integer := 32;
    CCSDS_RXTX_BENCH_BUFFER0_SIZE : integer := 16;
    -- CRC
    CCSDS_RXTX_BENCH_CRC0_DATA: std_logic_vector := x"313233343536373839";
    CCSDS_RXTX_BENCH_CRC0_INPUT_BYTES_REFLECTED: boolean := false;
    CCSDS_RXTX_BENCH_CRC0_INPUT_REFLECTED: boolean := false;
    CCSDS_RXTX_BENCH_CRC0_LENGTH: integer := 2;
    CCSDS_RXTX_BENCH_CRC0_OUTPUT_REFLECTED: boolean := false;
    CCSDS_RXTX_BENCH_CRC0_POLYNOMIAL: std_logic_vector := x"1021";
    CCSDS_RXTX_BENCH_CRC0_POLYNOMIAL_REFLECTED: boolean := false;
    CCSDS_RXTX_BENCH_CRC0_RESULT: std_logic_vector := x"e5cc";
    CCSDS_RXTX_BENCH_CRC0_SEED: std_logic_vector := x"ffff";
    CCSDS_RXTX_BENCH_CRC0_XOR: std_logic_vector := x"0000";
    -- FRAMER
    CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE: integer := 32;
    CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH: integer := 24;
    CCSDS_RXTX_BENCH_FRAMER0_FOOTER_LENGTH: integer := 2;
    CCSDS_RXTX_BENCH_FRAMER0_HEADER_LENGTH: integer := 6;
    CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO: integer := 2;
    -- LFSR
		CCSDS_RXTX_BENCH_LFSR0_RESULT: std_logic_vector := "1111111101001000000011101100000010011010";
		CCSDS_RXTX_BENCH_LFSR0_MEMORY_SIZE: integer := 8;
		CCSDS_RXTX_BENCH_LFSR0_MODE: std_logic := '0';
		CCSDS_RXTX_BENCH_LFSR0_POLYNOMIAL: std_logic_vector	:= x"A9";
		CCSDS_RXTX_BENCH_LFSR0_SEED: std_logic_vector	:= x"FF";
    -- SERDES
    CCSDS_RXTX_BENCH_SERDES0_DEPTH: integer := 32;
    -- simulation/test parameters
    CCSDS_RXTX_BENCH_BUFFER0_CLK_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_CRC0_CLK_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_CRC0_RANDOM_DATA_BUS_SIZE: integer:= 8; -- in Bytes
    CCSDS_RXTX_BENCH_CRC0_RANDOM_CHECK_NUMBER: integer:= 25;
    CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_FRAMER0_FRAME_NUMBER: integer := 25;
    CCSDS_RXTX_BENCH_LFSR0_CLK_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD: time := 20 ns;
    CCSDS_RXTX_BENCH_RXTX0_WB_TX_WRITE_CYCLE_NUMBER: integer := 1000;
    CCSDS_RXTX_BENCH_RXTX0_RX_CLK_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_RXTX0_TX_CLK_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_SEED: integer := 123456789;
    CCSDS_RXTX_BENCH_SERDES0_CLK_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_SERDES0_CYCLES_NUMBER: integer := 25;
    CCSDS_RXTX_BENCH_START_BUFFER_WAIT_DURATION: time := 1500 ns;
    CCSDS_RXTX_BENCH_START_CRC_WAIT_DURATION: time := 1500 ns;
    CCSDS_RXTX_BENCH_START_FRAMER_WAIT_DURATION: time := 1500 ns;
    CCSDS_RXTX_BENCH_START_LFSR_WAIT_DURATION: time := 1500 ns;
    CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION: time := 1000 ns;
    CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION: time := 500 ns;
    CCSDS_RXTX_BENCH_START_SERDES_WAIT_DURATION: time := 1500 ns;
    CCSDS_RXTX_BENCH_START_WB_WAIT_DURATION: time := 1500 ns
  );
end ccsds_rxtx_bench;

--=============================================================================
-- architecture declaration / internal processing
--=============================================================================
architecture behaviour of ccsds_rxtx_bench is
  component ccsds_rxtx_top is
    port(
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
      rx_sam_i_i: in std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      rx_sam_q_i: in std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      rx_ena_o: out std_logic;
      rx_irq_o: out std_logic;
      tx_clk_i: in std_logic;
      tx_dat_ser_i: in std_logic;
      tx_sam_i_o: out std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      tx_sam_q_o: out std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      tx_clk_o: out std_logic;
      tx_ena_o: out std_logic
    );
  end component;
  component ccsds_rxtx_buffer is
    generic(
      constant CCSDS_RXTX_BUFFER_DATA_BUS_SIZE : integer;
      constant CCSDS_RXTX_BUFFER_SIZE : integer
    );
    port(
      clk_i: in std_logic;
      dat_i: in std_logic_vector(CCSDS_RXTX_BUFFER_DATA_BUS_SIZE-1 downto 0);
      dat_val_i: in std_logic;
      nxt_dat_i: in std_logic;
      rst_i: in std_logic;
      buf_emp_o: out std_logic;
      buf_ful_o: out std_logic;
      dat_o: out std_logic_vector(CCSDS_RXTX_BUFFER_DATA_BUS_SIZE-1 downto 0);
      dat_val_o: out std_logic
    );
  end component;
  component ccsds_rxtx_crc is
  generic(
    constant CCSDS_RXTX_CRC_DATA_LENGTH: integer;
    constant CCSDS_RXTX_CRC_FINAL_XOR: std_logic_vector;
    constant CCSDS_RXTX_CRC_INPUT_BYTES_REFLECTED: boolean;
    constant CCSDS_RXTX_CRC_INPUT_REFLECTED: boolean;
    constant CCSDS_RXTX_CRC_LENGTH: integer;
    constant CCSDS_RXTX_CRC_OUTPUT_REFLECTED: boolean;
    constant CCSDS_RXTX_CRC_POLYNOMIAL: std_logic_vector;
    constant CCSDS_RXTX_CRC_POLYNOMIAL_REFLECTED: boolean;
    constant CCSDS_RXTX_CRC_SEED: std_logic_vector
  );
  port(
    clk_i: in std_logic;
    dat_i: in std_logic_vector(CCSDS_RXTX_CRC_DATA_LENGTH*8-1 downto 0);
    nxt_i: in std_logic;
    pad_dat_i: in std_logic_vector(CCSDS_RXTX_CRC_LENGTH*8-1 downto 0);
    pad_dat_val_i: in std_logic;
    rst_i: in std_logic;
    crc_o: out std_logic_vector(CCSDS_RXTX_CRC_LENGTH*8-1 downto 0);
    dat_o: out std_logic_vector(CCSDS_RXTX_CRC_DATA_LENGTH*8-1 downto 0);
    bus_o: out std_logic;
    dat_val_o: out std_logic
  );
  end component;
  component ccsds_tx_framer is
    generic (
      constant CCSDS_TX_FRAMER_HEADER_LENGTH: integer;
      constant CCSDS_TX_FRAMER_FOOTER_LENGTH: integer;
      constant CCSDS_TX_FRAMER_DATA_LENGTH: integer;
      constant CCSDS_TX_FRAMER_DATA_BUS_SIZE: integer;
      constant CCSDS_TX_FRAMER_PARALLELISM_MAX_RATIO: integer
    );
    port(
      clk_i: in std_logic;
      rst_i: in std_logic;
      dat_i: in std_logic_vector(CCSDS_TX_FRAMER_DATA_BUS_SIZE-1 downto 0);
      dat_val_i: in std_logic;
      dat_o: out std_logic_vector((CCSDS_TX_FRAMER_HEADER_LENGTH+CCSDS_TX_FRAMER_FOOTER_LENGTH+CCSDS_TX_FRAMER_DATA_LENGTH)*8-1 downto 0);
      dat_val_o: out std_logic
    );
  end component;
  component ccsds_rxtx_lfsr is
    generic(
      CCSDS_RXTX_LFSR_DATA_BUS_SIZE: integer;
      CCSDS_RXTX_LFSR_MEMORY_SIZE: integer;
		  CCSDS_RXTX_LFSR_MODE: std_logic;
		  CCSDS_RXTX_LFSR_POLYNOMIAL: std_logic_vector;
		  CCSDS_RXTX_LFSR_SEED: std_logic_vector
    );
    port(
      clk_i: in std_logic;
      rst_i: in std_logic;
      dat_o: out std_logic_vector(CCSDS_RXTX_LFSR_DATA_BUS_SIZE-1 downto 0);
      dat_val_o: out std_logic
    );
  end component;
  component ccsds_rxtx_serdes is
    generic (
      constant CCSDS_RXTX_SERDES_DEPTH : integer
    );
    port(
      clk_i: in std_logic;
      dat_par_i: in std_logic_vector(CCSDS_RXTX_SERDES_DEPTH-1 downto 0);
      dat_par_val_i: in std_logic;
      dat_ser_i: in std_logic;
      dat_ser_val_i: in std_logic;
      rst_i: in std_logic;
      bus_o: out std_logic;
      dat_par_o: out std_logic_vector(CCSDS_RXTX_SERDES_DEPTH-1 downto 0);
      dat_par_val_o: out std_logic;
      dat_ser_o: out std_logic;
      dat_ser_val_o: out std_logic
    );
  end component;

-- internal variables
  signal bench_ena_buffer0_random_data: std_logic := '0';
  signal bench_ena_crc0_random_data: std_logic := '0';
  signal bench_ena_framer0_random_data: std_logic := '0';
  signal bench_ena_rxtx0_random_data: std_logic := '0';
  signal bench_ena_serdes0_random_data: std_logic := '0';

-- synthetic generated stimuli
--NB: un-initialized on purposes - to allow observation of components default behaviour
  -- wishbone bus
  signal bench_sti_rxtx0_wb_clk: std_logic;
  signal bench_sti_rxtx0_wb_rst: std_logic;
  signal bench_sti_rxtx0_wb_adr: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_WB_ADDR_BUS_SIZE-1 downto 0);
  signal bench_sti_rxtx0_wb_cyc: std_logic;
  signal bench_sti_rxtx0_wb_dat: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_WB_DATA_BUS_SIZE-1 downto 0);
  signal bench_sti_rxtx0_wb_random_dat: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_WB_DATA_BUS_SIZE-1 downto 0);
  signal bench_sti_rxtx0_wb_stb: std_logic;
  signal bench_sti_rxtx0_wb_we: std_logic;
  -- rx
  signal bench_sti_rxtx0_rx_clk: std_logic;
  signal bench_sti_rxtx0_rx_data_next: std_logic;
  signal bench_sti_rxtx0_rx_samples_i: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
  signal bench_sti_rxtx0_rx_samples_q: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
  -- tx
  signal bench_sti_rxtx0_tx_clk: std_logic;
  signal bench_sti_rxtx0_tx_data_ser: std_logic;
  -- buffer
  signal bench_sti_buffer0_clk: std_logic;
  signal bench_sti_buffer0_rst: std_logic;
  signal bench_sti_buffer0_next_data: std_logic;
  signal bench_sti_buffer0_data: std_logic_vector(CCSDS_RXTX_BENCH_BUFFER0_DATA_BUS_SIZE-1 downto 0);
  signal bench_sti_buffer0_data_valid: std_logic;
  -- crc
  signal bench_sti_crc0_clk: std_logic;
  signal bench_sti_crc0_rst: std_logic;
  signal bench_sti_crc0_nxt: std_logic;
  signal bench_sti_crc0_data: std_logic_vector(CCSDS_RXTX_BENCH_CRC0_DATA'length-1 downto 0);
  signal bench_sti_crc0_padding_data_valid: std_logic;
  signal bench_sti_crc0_check_nxt: std_logic;
  signal bench_sti_crc0_check_data: std_logic_vector(CCSDS_RXTX_BENCH_CRC0_RANDOM_DATA_BUS_SIZE*8-1 downto 0);
  signal bench_sti_crc0_check_padding_data: std_logic_vector(CCSDS_RXTX_BENCH_CRC0_LENGTH*8-1 downto 0);
  signal bench_sti_crc0_check_padding_data_valid: std_logic;
  signal bench_sti_crc0_random_nxt: std_logic;
  signal bench_sti_crc0_random_data: std_logic_vector(CCSDS_RXTX_BENCH_CRC0_RANDOM_DATA_BUS_SIZE*8-1 downto 0);
  signal bench_sti_crc0_random_padding_data_valid: std_logic;
  -- framer
  signal bench_sti_framer0_clk: std_logic;
  signal bench_sti_framer0_rst: std_logic;
  signal bench_sti_framer0_data_valid: std_logic;
  signal bench_sti_framer0_data: std_logic_vector(CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE-1 downto 0);
  -- lfsr
  signal bench_sti_lfsr0_clk: std_logic;
  signal bench_sti_lfsr0_rst: std_logic;
  -- serdes
  signal bench_sti_serdes0_clk: std_logic;
  signal bench_sti_serdes0_rst: std_logic;
  signal bench_sti_serdes0_data_par_valid: std_logic;
  signal bench_sti_serdes0_data_par: std_logic_vector(CCSDS_RXTX_BENCH_SERDES0_DEPTH-1 downto 0);
  signal bench_sti_serdes0_data_ser_valid: std_logic;
  signal bench_sti_serdes0_data_ser: std_logic;
-- core generated response
  -- wishbone bus
  signal bench_res_rxtx0_wb_ack: std_logic;
  signal bench_res_rxtx0_wb_dat: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_WB_DATA_BUS_SIZE-1 downto 0);
  signal bench_res_rxtx0_wb_err: std_logic;
  signal bench_res_rxtx0_wb_rty: std_logic;
  -- rx
  signal bench_res_rxtx0_rx_ena: std_logic;
  signal bench_res_rxtx0_rx_irq: std_logic;
  -- tx
  signal bench_res_rxtx0_tx_clk: std_logic;
  signal bench_res_rxtx0_tx_samples_i: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
  signal bench_res_rxtx0_tx_samples_q: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
  signal bench_res_rxtx0_tx_ena: std_logic;
  -- buffer
  signal bench_res_buffer0_buffer_empty: std_logic;
  signal bench_res_buffer0_buffer_full: std_logic;
  signal bench_res_buffer0_data: std_logic_vector(CCSDS_RXTX_BENCH_BUFFER0_DATA_BUS_SIZE-1 downto 0);
  signal bench_res_buffer0_data_valid: std_logic;
  -- crc
  signal bench_res_crc0_busy: std_logic;
  signal bench_res_crc0_crc: std_logic_vector(CCSDS_RXTX_BENCH_CRC0_LENGTH*8-1 downto 0);
  signal bench_res_crc0_data: std_logic_vector(CCSDS_RXTX_BENCH_CRC0_DATA'length-1 downto 0);
  signal bench_res_crc0_data_valid: std_logic;
  signal bench_res_crc0_check_busy: std_logic;
  signal bench_res_crc0_check_crc: std_logic_vector(CCSDS_RXTX_BENCH_CRC0_LENGTH*8-1 downto 0);
  signal bench_res_crc0_check_data: std_logic_vector(CCSDS_RXTX_BENCH_CRC0_RANDOM_DATA_BUS_SIZE*8-1 downto 0);
  signal bench_res_crc0_check_data_valid: std_logic;
  signal bench_res_crc0_random_busy: std_logic;
  signal bench_res_crc0_random_crc: std_logic_vector(CCSDS_RXTX_BENCH_CRC0_LENGTH*8-1 downto 0);
  signal bench_res_crc0_random_data: std_logic_vector(CCSDS_RXTX_BENCH_CRC0_RANDOM_DATA_BUS_SIZE*8-1 downto 0);
  signal bench_res_crc0_random_data_valid: std_logic;
  -- framer
  signal bench_res_framer0_data_valid: std_logic;
  signal bench_res_framer0_data: std_logic_vector((CCSDS_RXTX_BENCH_FRAMER0_HEADER_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_FOOTER_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH)*8-1 downto 0);
  -- lfsr
  signal bench_res_lfsr0_data_valid: std_logic;
  signal bench_res_lfsr0_data: std_logic_vector(CCSDS_RXTX_BENCH_LFSR0_RESULT'length-1 downto 0);
  -- serdes
  signal bench_res_serdes0_busy: std_logic;
  signal bench_res_serdes0_data_par: std_logic_vector(CCSDS_RXTX_BENCH_SERDES0_DEPTH-1 downto 0);
  signal bench_res_serdes0_data_par_valid: std_logic;
  signal bench_res_serdes0_data_ser: std_logic;
  signal bench_res_serdes0_data_ser_valid: std_logic;

--=============================================================================
-- architecture begin
--=============================================================================
  begin
    -- Instance(s) of unit under test
    rxtx_001: ccsds_rxtx_top
      port map(
        wb_ack_o => bench_res_rxtx0_wb_ack,
        wb_adr_i => bench_sti_rxtx0_wb_adr,
        wb_clk_i => bench_sti_rxtx0_wb_clk,
        wb_cyc_i => bench_sti_rxtx0_wb_cyc,
        wb_dat_i => bench_sti_rxtx0_wb_dat,
        wb_dat_o => bench_res_rxtx0_wb_dat,
        wb_err_o => bench_res_rxtx0_wb_err,
        wb_rst_i => bench_sti_rxtx0_wb_rst,
        wb_rty_o => bench_res_rxtx0_wb_rty,
        wb_stb_i => bench_sti_rxtx0_wb_stb,
        wb_we_i => bench_sti_rxtx0_wb_we,
        rx_clk_i => bench_sti_rxtx0_rx_clk,
        rx_sam_i_i => bench_sti_rxtx0_rx_samples_i,
        rx_sam_q_i => bench_sti_rxtx0_rx_samples_q,
        rx_irq_o => bench_res_rxtx0_rx_irq,
        rx_ena_o => bench_res_rxtx0_rx_ena,
        tx_clk_i => bench_sti_rxtx0_tx_clk,
        tx_dat_ser_i => bench_sti_rxtx0_tx_data_ser,
        tx_sam_i_o => bench_res_rxtx0_tx_samples_i,
        tx_sam_q_o => bench_res_rxtx0_tx_samples_q,
        tx_clk_o => bench_res_rxtx0_tx_clk,
        tx_ena_o => bench_res_rxtx0_tx_ena
      );
    -- Instance(s) of sub-components under test
    buffer_001: ccsds_rxtx_buffer
      generic map(
        CCSDS_RXTX_BUFFER_DATA_BUS_SIZE => CCSDS_RXTX_BENCH_BUFFER0_DATA_BUS_SIZE,
        CCSDS_RXTX_BUFFER_SIZE => CCSDS_RXTX_BENCH_BUFFER0_SIZE
      )
      port map(
        clk_i => bench_sti_buffer0_clk,
        rst_i => bench_sti_buffer0_rst,
        dat_val_i => bench_sti_buffer0_data_valid,
        dat_i => bench_sti_buffer0_data,
        dat_val_o => bench_res_buffer0_data_valid,
        buf_emp_o => bench_res_buffer0_buffer_empty,
        buf_ful_o => bench_res_buffer0_buffer_full,
        nxt_dat_i => bench_sti_buffer0_next_data,
        dat_o => bench_res_buffer0_data
      );
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
        clk_i => bench_sti_crc0_clk,
        rst_i => bench_sti_crc0_rst,
        nxt_i => bench_sti_crc0_nxt,
        bus_o => bench_res_crc0_busy,
        dat_i => bench_sti_crc0_data,
        pad_dat_i => (others => '0'),
        pad_dat_val_i => bench_sti_crc0_padding_data_valid,
        crc_o => bench_res_crc0_crc,
        dat_o => bench_res_crc0_data,
        dat_val_o => bench_res_crc0_data_valid
      );
    crc_random_001: ccsds_rxtx_crc
      generic map(
        CCSDS_RXTX_CRC_DATA_LENGTH => CCSDS_RXTX_BENCH_CRC0_RANDOM_DATA_BUS_SIZE,
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
        clk_i => bench_sti_crc0_clk,
        rst_i => bench_sti_crc0_rst,
        nxt_i => bench_sti_crc0_random_nxt,
        bus_o => bench_res_crc0_random_busy,
        dat_i => bench_sti_crc0_random_data,
        pad_dat_i => (others => '0'),
        pad_dat_val_i => bench_sti_crc0_random_padding_data_valid,
        crc_o => bench_res_crc0_random_crc,
        dat_o => bench_res_crc0_random_data,
        dat_val_o => bench_res_crc0_random_data_valid
      );
    crc_checker_001: ccsds_rxtx_crc
      generic map(
        CCSDS_RXTX_CRC_DATA_LENGTH => CCSDS_RXTX_BENCH_CRC0_RANDOM_DATA_BUS_SIZE,
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
        clk_i => bench_sti_crc0_clk,
        rst_i => bench_sti_crc0_rst,
        nxt_i => bench_sti_crc0_check_nxt,
        bus_o => bench_res_crc0_check_busy,
        dat_i => bench_sti_crc0_check_data,
        pad_dat_val_i => bench_sti_crc0_check_padding_data_valid,
        pad_dat_i => bench_sti_crc0_check_padding_data,
        crc_o => bench_res_crc0_check_crc,
        dat_o => bench_res_crc0_check_data,
        dat_val_o => bench_res_crc0_check_data_valid
      );
    framer_001 : ccsds_tx_framer
      generic map (
        CCSDS_TX_FRAMER_HEADER_LENGTH => CCSDS_RXTX_BENCH_FRAMER0_HEADER_LENGTH,
        CCSDS_TX_FRAMER_FOOTER_LENGTH => CCSDS_RXTX_BENCH_FRAMER0_FOOTER_LENGTH,
        CCSDS_TX_FRAMER_DATA_LENGTH => CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH,
        CCSDS_TX_FRAMER_DATA_BUS_SIZE => CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE,
        CCSDS_TX_FRAMER_PARALLELISM_MAX_RATIO => CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO
      )
      port map(
        clk_i => bench_sti_framer0_clk,
        rst_i => bench_sti_framer0_rst,
        dat_val_i => bench_sti_framer0_data_valid,
        dat_i => bench_sti_framer0_data,
        dat_val_o => bench_res_framer0_data_valid,
        dat_o => bench_res_framer0_data
      );
    lfsr_001: ccsds_rxtx_lfsr
      generic map(
        CCSDS_RXTX_LFSR_DATA_BUS_SIZE => CCSDS_RXTX_BENCH_LFSR0_RESULT'length,
        CCSDS_RXTX_LFSR_MEMORY_SIZE => CCSDS_RXTX_BENCH_LFSR0_MEMORY_SIZE,
		    CCSDS_RXTX_LFSR_MODE => CCSDS_RXTX_BENCH_LFSR0_MODE,
		    CCSDS_RXTX_LFSR_POLYNOMIAL => CCSDS_RXTX_BENCH_LFSR0_POLYNOMIAL,
		    CCSDS_RXTX_LFSR_SEED => CCSDS_RXTX_BENCH_LFSR0_SEED
      )
      port map(
        clk_i => bench_sti_lfsr0_clk,
        rst_i => bench_sti_lfsr0_rst,
        dat_val_o => bench_res_lfsr0_data_valid,
        dat_o => bench_res_lfsr0_data
      );
    serdes_001: ccsds_rxtx_serdes
      generic map(
        CCSDS_RXTX_SERDES_DEPTH => CCSDS_RXTX_BENCH_SERDES0_DEPTH
      )
      port map(
        clk_i => bench_sti_serdes0_clk,
        dat_par_i => bench_sti_serdes0_data_par,
        dat_par_val_i => bench_sti_serdes0_data_par_valid,
        dat_ser_i => bench_sti_serdes0_data_ser,
        dat_ser_val_i => bench_sti_serdes0_data_ser_valid,
        rst_i => bench_sti_serdes0_rst,
        bus_o => bench_res_serdes0_busy,
        dat_par_o => bench_res_serdes0_data_par,
        dat_par_val_o => bench_res_serdes0_data_par_valid,
        dat_ser_o => bench_res_serdes0_data_ser,
        dat_ser_val_o => bench_res_serdes0_data_ser_valid
      );

    --=============================================================================
    -- Begin of bench_sti_rxtx0_wb_clkp
    -- bench_sti_rxtx0_wb_clk generation
    --=============================================================================
    -- read: 
    -- write: bench_sti_rxtx0_wb_clk
    -- r/w: 
    BENCH_STI_RXTX0_WB_CLKP : process
      begin
        bench_sti_rxtx0_wb_clk <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD/2;
        bench_sti_rxtx0_wb_clk <= '0';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_rxtx0_rx_clkp
    -- bench_sti_rxtx0_rx_clk generation
    --=============================================================================
    -- read: 
    -- write: bench_sti_rxtx0_rx_clk
    -- r/w: 
    BENCH_STI_RXTX0_RX_CLKP : process
      begin
        bench_sti_rxtx0_rx_clk <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_RX_CLK_PERIOD/2;
        bench_sti_rxtx0_rx_clk <= '0';
        wait for CCSDS_RXTX_BENCH_RXTX0_RX_CLK_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_rxtx0_tx_clkp
    -- bench_sti_rxtx0_tx_clk generation
    --=============================================================================
    -- read: 
    -- write: bench_sti_rxtx0_tx_clk
    -- r/w: 
    BENCH_STI_RXTX0_TX_CLKP : process
      begin
        bench_sti_rxtx0_tx_clk <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_TX_CLK_PERIOD/2;
        bench_sti_rxtx0_tx_clk <= '0';
        wait for CCSDS_RXTX_BENCH_RXTX0_TX_CLK_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_buffer0_clkp
    -- bench_sti_buffer0_clk generation
    --=============================================================================
    -- read: 
    -- write: bench_sti_buffer0_clk
    -- r/w: 
    BENCH_STI_BUFFER0_CLKP : process
      begin
        bench_sti_buffer0_clk <= '1';
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK_PERIOD/2;
        bench_sti_buffer0_clk <= '0';
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_crc0_clkp
    -- bench_sti_crc0_clk generation
    --=============================================================================
    -- read: 
    -- write: bench_sti_crc0_clk
    -- r/w: 
    BENCH_STI_CRC0_CLKP : process
      begin
        bench_sti_crc0_clk <= '1';
        wait for CCSDS_RXTX_BENCH_CRC0_CLK_PERIOD/2;
        bench_sti_crc0_clk <= '0';
        wait for CCSDS_RXTX_BENCH_CRC0_CLK_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_framer0_clkp
    -- bench_sti_framer0_clk generation
    --=============================================================================
    -- read: 
    -- write: bench_sti_framer0_clk
    -- r/w: 
    BENCH_STI_FRAMER0_CLKP : process
      begin
        bench_sti_framer0_clk <= '1';
        wait for CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD/2;
        bench_sti_framer0_clk <= '0';
        wait for CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_lfsr0_clkp
    -- bench_sti_lfsr0_clk generation
    --=============================================================================
    -- read: 
    -- write: bench_sti_lfsr0_clk
    -- r/w: 
    BENCH_STI_LFSR0_CLKP : process
      begin
        bench_sti_lfsr0_clk <= '1';
        wait for CCSDS_RXTX_BENCH_LFSR0_CLK_PERIOD/2;
        bench_sti_lfsr0_clk <= '0';
        wait for CCSDS_RXTX_BENCH_LFSR0_CLK_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_serdes0_clkp
    -- bench_sti_serdes0_clk generation
    --=============================================================================
    -- read: 
    -- write: bench_sti_serdes0_clk
    -- r/w: 
    BENCH_STI_SERDES0_CLKP : process
      begin
        bench_sti_serdes0_clk <= '1';
        wait for CCSDS_RXTX_BENCH_SERDES0_CLK_PERIOD/2;
        bench_sti_serdes0_clk <= '0';
        wait for CCSDS_RXTX_BENCH_SERDES0_CLK_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_rxtx0_tx_datap
    -- bench_sti_rxtx0_tx_data generation / dephased from 1/2 clk with bench_sti_rxtx0_tx_clk
    --=============================================================================
    -- read: 
    -- write: bench_sti_rxtx0_tx_data_ser0
    -- r/w: 
    BENCH_STI_RXTX0_TX_DATAP : process
      variable seed1, seed2 : positive := CCSDS_RXTX_BENCH_SEED;
      variable random : std_logic_vector(1 downto 0);
      begin
        wait for CCSDS_RXTX_BENCH_RXTX0_TX_CLK_PERIOD/2;
        if (bench_ena_rxtx0_random_data = '1') then
          sim_generate_random_std_logic_vector(2,seed1,seed2,random);
          sim_generate_random_std_logic_vector(2,seed1,seed2,random);
          bench_sti_rxtx0_tx_data_ser <= random(0);
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_TX_CLK_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_buffer0_datap
    -- bench_sti_buffer0_data generation / dephased from 1/2 clk with bench_sti_buffer0_clk
    --=============================================================================
    -- read: bench_ena_buffer0_random_data
    -- write: bench_sti_buffer0_data
    -- r/w: 
    BENCH_STI_BUFFER0_DATAP : process
      variable seed1, seed2 : positive := CCSDS_RXTX_BENCH_SEED;
      variable random : std_logic_vector(CCSDS_RXTX_BENCH_BUFFER0_DATA_BUS_SIZE-1 downto 0);
      begin
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK_PERIOD/2;
        if (bench_ena_buffer0_random_data = '1') then
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_BUFFER0_DATA_BUS_SIZE,seed1,seed2,random);
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_BUFFER0_DATA_BUS_SIZE,seed1,seed2,random);
          bench_sti_buffer0_data <= random;
        end if;
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_crc0_datap
    -- bench_sti_crc0_random_data generation / dephased from 1/2 clk with bench_sti_crc0_clk
    --=============================================================================
    -- read: bench_ena_crc0_random_data
    -- write: bench_sti_crc0_random_data
    -- r/w: 
    BENCH_STI_CRC0_DATAP : process
      variable seed1, seed2 : positive := CCSDS_RXTX_BENCH_SEED;
      variable random : std_logic_vector(CCSDS_RXTX_BENCH_CRC0_RANDOM_DATA_BUS_SIZE*8-1 downto 0);
      begin
        wait for CCSDS_RXTX_BENCH_CRC0_CLK_PERIOD/2;
        if (bench_ena_crc0_random_data = '1') then
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_CRC0_RANDOM_DATA_BUS_SIZE*8,seed1,seed2,random);
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_CRC0_RANDOM_DATA_BUS_SIZE*8,seed1,seed2,random);
          bench_sti_crc0_random_data <= random;
        end if;
        wait for CCSDS_RXTX_BENCH_CRC0_CLK_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_framer0_datap
    -- bench_sti_framer0_data generation / dephased from 1/2 clk with bench_sti_datalinklayer0_clk
    --=============================================================================
    -- read: bench_ena_framer0_random_data
    -- write: bench_sti_framer0_data
    -- r/w: 
    BENCH_STI_FRAMER0_DATAP : process
      variable seed1, seed2 : positive := CCSDS_RXTX_BENCH_SEED;
      variable random : std_logic_vector(CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE-1 downto 0);
      begin
        wait for CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD/2;
        if (bench_ena_framer0_random_data = '1') then
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE,seed1,seed2,random);
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE,seed1,seed2,random);
          bench_sti_framer0_data <= random;
        end if;
        wait for CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_serdes0_datap
    -- bench_sti_serdes0_data generation / dephased from 1/2 clk with bench_sti_serdes0_clk
    --=============================================================================
    -- read: bench_ena_serdes0_random_data
    -- write: bench_sti_serdes0_data_par, bench_sti_serdes0_data_ser
    -- r/w: 
    BENCH_STI_SERDES0_DATAP : process
      variable seed1, seed2 : positive := CCSDS_RXTX_BENCH_SEED;
      variable random : std_logic_vector(CCSDS_RXTX_BENCH_SERDES0_DEPTH-1 downto 0);
      begin
        wait for CCSDS_RXTX_BENCH_SERDES0_CLK_PERIOD/2;
        if (bench_ena_serdes0_random_data = '1') then
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_SERDES0_DEPTH,seed1,seed2,random);
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_SERDES0_DEPTH,seed1,seed2,random);
          bench_sti_serdes0_data_par <= random;
          bench_sti_serdes0_data_ser <= random(0);
        end if;
        wait for CCSDS_RXTX_BENCH_SERDES0_CLK_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_rxtx0_rx_samplesp
    -- bench_sti_rxtx0_rx_samples generation / dephased from 1/2 clk with bench_sti_rxtx0_rx_clk signal
    --=============================================================================
    -- read: bench_ena_rxtx0_random_data
    -- write: bench_sti_rxtx0_rx_samples_i, bench_sti_rxtx0_rx_samples_q
    -- r/w: 
    BENCH_STI_RXTX0_RX_SAMPLESP : process
      variable seed1, seed2 : positive := CCSDS_RXTX_BENCH_SEED;
      variable random1 : std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      variable random2 : std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      begin
        wait for CCSDS_RXTX_BENCH_RXTX0_RX_CLK_PERIOD/2;
        if (bench_ena_rxtx0_random_data = '1') then
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH,seed1,seed2,random1);
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH,seed2,seed1,random2);
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH,seed1,seed2,random1);
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH,seed2,seed1,random2);
          bench_sti_rxtx0_rx_samples_i <= random1;
          bench_sti_rxtx0_rx_samples_q <= random2;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_RX_CLK_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_rxtx0_wb_datap
    -- bench_sti_rxtx0_wb_random_dat generation / dephased from 1/2 clk with bench_sti_rxtx0_wb_clk signal
    --=============================================================================
    -- read: bench_ena_rxtx0_random_data
    -- write: bench_sti_rxtx0_wb_random_dat0
    -- r/w: 
    BENCH_STI_RXTX0_WB_DATP : process
      variable seed1, seed2 : positive := CCSDS_RXTX_BENCH_SEED;
      variable random1 : std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_WB_DATA_BUS_SIZE-1 downto 0);
      begin
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD/2;
        if (bench_ena_rxtx0_random_data = '1') then
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_WB_DATA_BUS_SIZE,seed1,seed2,random1);
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_WB_DATA_BUS_SIZE,seed1,seed2,random1);
          bench_sti_rxtx0_wb_random_dat <= random1;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bufferrwp
    -- generation of buffer subsystem read-write unit-tests
    --=============================================================================
    -- read: bench_res_buffer0_buffer_empty, bench_res_buffer0_buffer_full, bench_res_buffer0_data, bench_res_buffer0_data_valid
    -- write: bench_sti_buffer0_data_valid, bench_sti_buffer0_next_data, bench_ena_buffer0_random_data
    -- r/w: 
    BUFFERRWP : process
      type buffer_array is array (CCSDS_RXTX_BENCH_BUFFER0_SIZE downto 0) of std_logic_vector(CCSDS_RXTX_BENCH_BUFFER0_DATA_BUS_SIZE-1 downto 0);
      variable buffer_expected_stored_data: buffer_array := (others => (others => '0'));
      variable buffer_content_ok: std_logic := '1';
      begin
      -- let the system free run
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2);
      -- default state tests:
        -- check buffer is empty
        if (bench_res_buffer0_buffer_empty = '1') then
          report "BUFFERRWP: OK - Default state - Buffer is empty" severity note;
        else
          report "BUFFERRWP: KO - Default state - Buffer is not empty" severity warning;
        end if;
        -- check buffer is not full
        if (bench_res_buffer0_buffer_full = '0')then
          report "BUFFERRWP: OK - Default state - Buffer is not full" severity note;
        else
          report "BUFFERRWP: KO - Default state - Buffer is full" severity warning;
        end if;
      -- let the system reset
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2 + CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION + CCSDS_RXTX_BENCH_START_BUFFER_WAIT_DURATION);
      -- initial state tests:
        -- check buffer is empty
        if (bench_res_buffer0_buffer_empty = '1') then
          report "BUFFERRWP: OK - Initial state - Buffer is empty" severity note;
        else
          report "BUFFERRWP: KO - Initial state - Buffer is not empty" severity warning;
        end if;
        -- check buffer is not full
        if (bench_res_buffer0_buffer_full = '0')then
          report "BUFFERRWP: OK - Initial state - Buffer is not full" severity note;
        else
          report "BUFFERRWP: KO - Initial state - Buffer is full" severity warning;
        end if;
      -- behaviour tests:
        report "BUFFERRWP: START BUFFER READ-WRITE TESTS" severity note;
        -- ask for data
        bench_sti_buffer0_next_data <= '1';
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK_PERIOD;
        if (bench_res_buffer0_data_valid = '0') then
          report "BUFFERRWP: OK - No data came out with an empty buffer" severity note;
        else
          report "BUFFERRWP: KO - Data came out - buffer is empty / incoherent" severity warning;
        end if;
        bench_sti_buffer0_next_data <= '0';
        bench_ena_buffer0_random_data <= '1';
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK_PERIOD;
        -- store data
        bench_sti_buffer0_data_valid <= '1';
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK_PERIOD/2;
        buffer_expected_stored_data(0) := bench_sti_buffer0_data;
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK_PERIOD/2;
        bench_sti_buffer0_data_valid <= '0';
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK_PERIOD;
        if (bench_res_buffer0_buffer_empty = '0') then
          report "BUFFERRWP: OK - Buffer is not empty" severity note;
        else
          report "BUFFERRWP: KO - Buffer should not be empty" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK_PERIOD;
        -- get data
        bench_sti_buffer0_next_data <= '1';
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK_PERIOD;
        bench_sti_buffer0_next_data <= '0';
        if (bench_res_buffer0_data_valid = '1') then
          report "BUFFERRWP: OK - Data valid signal received" severity note;
        else
          report "BUFFERRWP: KO - Data valid signal not received" severity warning;
        end if;
        if (bench_res_buffer0_data = buffer_expected_stored_data(0)) then
          report "BUFFERRWP: OK - Received value is equal to previously stored value" severity note;
        else
          report "BUFFERRWP: KO - Received value is different from previously stored value" severity warning;
          report "Received value:" severity note;
          for i in 0 to bench_res_buffer0_data'length-1 loop
            report std_logic'image(bench_res_buffer0_data(i));
          end loop;
          report "Expected value:" severity note;
          for i in 0 to buffer_expected_stored_data(0)'length-1 loop
            report std_logic'image(buffer_expected_stored_data(0)(i));
          end loop;
        end if;
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK_PERIOD;
        if (bench_res_buffer0_buffer_empty = '1') then
          report "BUFFERRWP: OK - Buffer is empty after reading value" severity note;
        else
          report "BUFFERRWP: KO - Buffer is not empty" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK_PERIOD;
        -- store lot of data / make the buffer full
        bench_sti_buffer0_data_valid <= '1';
        for i in 0 to CCSDS_RXTX_BENCH_BUFFER0_SIZE loop
          wait for CCSDS_RXTX_BENCH_BUFFER0_CLK_PERIOD/2;
          buffer_expected_stored_data(i) := bench_sti_buffer0_data;
          wait for CCSDS_RXTX_BENCH_BUFFER0_CLK_PERIOD/2;
          if (bench_res_buffer0_buffer_full = '1') then
            if (i < CCSDS_RXTX_BENCH_BUFFER0_SIZE) then
              report "BUFFERRWP: KO - Buffer is full too early - loop: " & integer'image(i) & " value of the buffer array" severity warning;
            else
              report "BUFFERRWP: OK - Buffer is full after all write operations" severity note;
            end if;
          else
            if (i = CCSDS_RXTX_BENCH_BUFFER0_SIZE) then
              report "BUFFERRWP: KO - Buffer is not full after all write operations" severity note;
            end if;
          end if;
        end loop;
        bench_sti_buffer0_data_valid <= '0';
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK_PERIOD;
        bench_ena_buffer0_random_data <= '0';
        -- read all data / make the buffer empty
        bench_sti_buffer0_next_data <= '1';
        for i in 0 to CCSDS_RXTX_BENCH_BUFFER0_SIZE loop
          wait for CCSDS_RXTX_BENCH_BUFFER0_CLK_PERIOD;
          if (buffer_expected_stored_data(i) /= bench_res_buffer0_data) then
            if (i < CCSDS_RXTX_BENCH_BUFFER0_SIZE) then
              report "BUFFERRWP: KO - Received value is different from previously stored value - loop: " & integer'image(i) severity warning;
              buffer_content_ok := '0';
            end if;
          end if;
          if (i = CCSDS_RXTX_BENCH_BUFFER0_SIZE) and (buffer_content_ok = '1') then
            report "BUFFERRWP: OK - Received values are all equal to previously stored values" severity note;
          end if;
          if (bench_res_buffer0_data_valid = '0') then
            if (i < CCSDS_RXTX_BENCH_BUFFER0_SIZE) then
              report "BUFFERRWP: KO - Data valid signal not received - loop: " & integer'image(i) severity warning;
            end if;
          end if;
          if (bench_res_buffer0_buffer_empty = '1') then
            if (i < CCSDS_RXTX_BENCH_BUFFER0_SIZE) then
              report "BUFFERRWP: KO - Data empty signal received too early - loop: " & integer'image(i) severity warning;
            else
              report "BUFFERRWP: OK - Buffer is empty after all read operations" severity note;
            end if;
          else
            if (i = CCSDS_RXTX_BENCH_BUFFER0_SIZE) then
              report "BUFFERRWP: KO - Buffer is not empty after all read operations" severity warning;
            end if;
          end if;
        end loop;
        bench_sti_buffer0_next_data <= '0';
      -- final state tests:
        -- check buffer is empty
        if (bench_res_buffer0_buffer_empty = '1') then
          report "BUFFERRWP: OK - Final state - Buffer is empty" severity note;
        else
          report "BUFFERRWP: KO - Final state - Buffer is not empty" severity warning;
        end if;
        -- check buffer is not full
        if (bench_res_buffer0_buffer_full = '0')then
          report "BUFFERRWP: OK - Final state - Buffer is not full" severity note;
        else
          report "BUFFERRWP: KO - Final state - Buffer is full" severity warning;
        end if;
        report "BUFFERRWP: END BUFFER READ-WRITE TESTS" severity note;
      -- do nothing
        wait;
      end process;
    --=============================================================================
    -- Begin of crcp
    -- generation of crc subsystem unit-tests
    --=============================================================================
    -- read: bench_res_crc0_data, bench_res_crc0_data_valid
    -- write: bench_sti_crc0_nxt, bench_sti_crc0_data, bench_ena_crc0_random_data
    -- r/w: 
    CRCP : process
      variable crc_random_data_sent: std_logic_vector(CCSDS_RXTX_BENCH_CRC0_RANDOM_DATA_BUS_SIZE*8-1 downto 0) := (others => '0');
      variable crc_random_data_crc: std_logic_vector(CCSDS_RXTX_BENCH_CRC0_LENGTH*8-1 downto 0) := (others => '1');
      variable crc_random_data_crc_check: std_logic_vector(CCSDS_RXTX_BENCH_CRC0_LENGTH*8-1 downto 0) := (others => '0');
      variable crc_check_ok: std_logic := '1';
      begin
      -- let the system free run
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2);
      -- default state tests:
        if (bench_res_crc0_data_valid = '1') then
          report "CRCP: KO - Default state - CRC output data is valid" severity warning;
        else
          report "CRCP: OK - Default state - CRC output data is not valid" severity note;
        end if;
      -- let the system reset
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2 + CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION + CCSDS_RXTX_BENCH_START_CRC_WAIT_DURATION);
      -- initial state tests:
        if (bench_res_crc0_data_valid = '1') then
          report "CRCP: KO - Initial state - CRC output data is valid" severity warning;
        else
          report "CRCP: OK - Initial state - CRC output data is not valid" severity note;
        end if;
      -- behaviour tests:
        report "CRCP: START CRC COMPUTATION TESTS" severity note;
        -- present crc test data
        bench_sti_crc0_data <= CCSDS_RXTX_BENCH_CRC0_DATA;
        -- no specific padding done
        bench_sti_crc0_padding_data_valid <= '0';
        -- send next crc signal
        bench_sti_crc0_nxt <= '1';
        -- wait for one clk
        wait for CCSDS_RXTX_BENCH_CRC0_CLK_PERIOD;
        -- stop next signal
        bench_sti_crc0_nxt <= '0';
        -- remove crc test data
        bench_sti_crc0_data <= (others => '0');
        if (bench_res_crc0_busy = '0') then
          report "CRCP: KO - CRC is not busy" severity warning;
        end if;
        -- wait for result
        wait for CCSDS_RXTX_BENCH_CRC0_CLK_PERIOD*(CCSDS_RXTX_BENCH_CRC0_DATA'length+CCSDS_RXTX_BENCH_CRC0_LENGTH*8+1);
        if (bench_res_crc0_crc = CCSDS_RXTX_BENCH_CRC0_RESULT) and (bench_res_crc0_data_valid = '1') and (bench_res_crc0_data = CCSDS_RXTX_BENCH_CRC0_DATA) then
          report "CRCP: OK - Output CRC is conform to expectations" severity note;
        else
          report "CRCP: KO - Output CRC is different from expectations" severity warning;
          report "Received value:" severity note;
          for i in 0 to bench_res_crc0_data'length-1 loop
            report std_logic'image(bench_res_crc0_data(i));
          end loop;
          report "Expected value:" severity note;
          for i in 0 to CCSDS_RXTX_BENCH_CRC0_RESULT'length-1 loop
            report std_logic'image(CCSDS_RXTX_BENCH_CRC0_RESULT(i));
          end loop;
        end if;
        bench_ena_crc0_random_data <= '1';
        wait for CCSDS_RXTX_BENCH_CRC0_CLK_PERIOD;
        for crc_current_check in 0 to CCSDS_RXTX_BENCH_CRC0_RANDOM_CHECK_NUMBER-1 loop
          -- present crc random data + store associated crc
          -- send next crc signal
          bench_sti_crc0_random_nxt <= '1';
          -- no specific padding done
          bench_sti_crc0_random_padding_data_valid <= '0';
          -- wait for one clk and store random data sent
          wait for CCSDS_RXTX_BENCH_CRC0_CLK_PERIOD/2;
          crc_random_data_sent := bench_sti_crc0_random_data;
          wait for CCSDS_RXTX_BENCH_CRC0_CLK_PERIOD/2;
          -- stop next signal
          bench_ena_crc0_random_data <= '0';
          bench_sti_crc0_random_nxt <= '0';
          if (bench_res_crc0_random_busy = '0') then
            report "CRCP: KO - random data CRC is not busy" severity warning;
          end if;
          -- wait for result
          wait for CCSDS_RXTX_BENCH_CRC0_CLK_PERIOD*(CCSDS_RXTX_BENCH_CRC0_RANDOM_DATA_BUS_SIZE*8+CCSDS_RXTX_BENCH_CRC0_LENGTH*8+1);
          if (bench_res_crc0_random_data_valid = '1') then
            -- store crc
            crc_random_data_crc := bench_res_crc0_random_crc;
          else
            report "CRCP: KO - random data output CRC is not valid" severity warning;
          end if;
          -- present crc random data
          bench_sti_crc0_check_data <= crc_random_data_sent;
          -- present crc as padding value
          bench_sti_crc0_check_padding_data <= crc_random_data_crc;
          bench_sti_crc0_check_padding_data_valid <= '1';
          -- send next crc signal
          bench_sti_crc0_check_nxt <= '1';
          -- wait for one clk
          wait for CCSDS_RXTX_BENCH_CRC0_CLK_PERIOD;
          -- stop next signal
          bench_sti_crc0_check_nxt <= '0';
          -- stop padding signal
          bench_sti_crc0_check_padding_data_valid <= '0';
          if (bench_res_crc0_check_busy = '0') then
            report "CRCP: KO - Random data checker CRC is not busy" severity warning;
          end if;
          -- wait for result
          wait for CCSDS_RXTX_BENCH_CRC0_CLK_PERIOD*(CCSDS_RXTX_BENCH_CRC0_RANDOM_DATA_BUS_SIZE*8+CCSDS_RXTX_BENCH_CRC0_LENGTH*8+1);
          if (bench_res_crc0_check_data_valid = '1') then
            -- check output crc resulting is null
            if (bench_res_crc0_check_crc = crc_random_data_crc_check) and (bench_res_crc0_check_data = crc_random_data_sent) then
              if (crc_current_check = CCSDS_RXTX_BENCH_CRC0_RANDOM_CHECK_NUMBER-1) and (crc_check_ok = '1') then
                report "CRCP: OK - Random data checker output CRCs are all null" severity note;
              end if;
            else
              crc_check_ok := '0';
              report "CRCP: KO - Random data checker output CRC is not null - loop " & integer'image(crc_current_check) severity warning;
              report "Received value:" severity warning;
              for i in 0 to bench_res_crc0_check_data'length-1 loop
                report std_logic'image(bench_res_crc0_check_data(i)) severity warning;
              end loop;
            end if;
          else
            report "CRCP: KO - Output CRC checker is not valid" severity warning;
          end if;
          bench_ena_crc0_random_data <= '1';
          wait for CCSDS_RXTX_BENCH_CRC0_CLK_PERIOD;
        end loop;
        bench_ena_crc0_random_data <= '0';
        wait for CCSDS_RXTX_BENCH_CRC0_CLK_PERIOD;
      -- final state tests:
        if (bench_res_crc0_data_valid = '1') then
          report "CRCP: KO - Final state - CRC output data is valid" severity warning;
        else
          report "CRCP: OK - Final state - CRC output data is not valid" severity note;
        end if;
        report "CRCP: END CRC COMPUTATION TESTS" severity note;
        -- do nothing
        wait;
      end process;
    --=============================================================================
    -- Begin of framerp
    -- generation of framer subsystem unit-tests
    --=============================================================================
    -- read: bench_res_framer0_data0, bench_res_framer0_data_valid0
    -- write: bench_ena_framer0_random_data
    -- r/w: 
    FRAMERP : process
      type data_array is array (CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH*8/CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE-1 downto 0) of std_logic_vector(CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE-1 downto 0);
      type frame_array is array (CCSDS_RXTX_BENCH_FRAMER0_FRAME_NUMBER-1 downto 0) of data_array;
      variable framer_expected_data: frame_array := (others => (others => (others => '0')));
      variable frame_content_ok: std_logic := '1';
      variable nb_data: integer;
      variable FRAME_OUTPUT_CYCLES_REQUIRED: integer;
      variable FRAME_PROCESSING_CYCLES_REQUIRED: integer := (CCSDS_RXTX_BENCH_FRAMER0_HEADER_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_FOOTER_LENGTH)*8+1;
      constant FRAME_ACQUISITION_CYCLES: integer := (CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH*8-CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE)*CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO/CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE + 1;
      constant FRAME_REPETITION_CYCLES: integer := CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH*8*CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO/CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE;
      constant FRAME_ACQUISITION_CYCLES_IDLE: integer := FRAME_REPETITION_CYCLES - FRAME_ACQUISITION_CYCLES;
      begin
        if (CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH*8 = CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE) and (CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO = 1) then
          FRAME_OUTPUT_CYCLES_REQUIRED := (CCSDS_RXTX_BENCH_FRAMER0_HEADER_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_FOOTER_LENGTH)*8+6;
        else
          FRAME_OUTPUT_CYCLES_REQUIRED := (CCSDS_RXTX_BENCH_FRAMER0_HEADER_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_FOOTER_LENGTH)*8+5;
        end if;
      -- let the system free run
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2);
      -- default state tests:
      -- let the system reset
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2 + CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION + CCSDS_RXTX_BENCH_START_FRAMER_WAIT_DURATION);
        report "FRAMERP: START FRAMER TESTS" severity note;
      -- initial state tests:
        bench_ena_framer0_random_data <= '1';
        -- check output data is valid and idle only data found
        if ((CCSDS_RXTX_BENCH_START_FRAMER_WAIT_DURATION/CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD) < FRAME_OUTPUT_CYCLES_REQUIRED) then
          wait for (FRAME_OUTPUT_CYCLES_REQUIRED+1 - ((CCSDS_RXTX_BENCH_START_FRAMER_WAIT_DURATION/CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD) mod FRAME_OUTPUT_CYCLES_REQUIRED))*CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD;
        else
          wait for (FRAME_REPETITION_CYCLES+1 - (((CCSDS_RXTX_BENCH_START_FRAMER_WAIT_DURATION/CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD) - FRAME_OUTPUT_CYCLES_REQUIRED) mod (FRAME_REPETITION_CYCLES)))*CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD;
        end if;
        if bench_res_framer0_data_valid = '1' then
          if (bench_res_framer0_data((CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_FOOTER_LENGTH)*8+10 downto (CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_FOOTER_LENGTH)*8) = "11111111110") then
            report "FRAMERP: OK - Default state - Output frame is valid and Only Idle Data flag found" severity note;
          else
            report "FRAMERP: KO - Default state - Output frame is valid without sent data - Only Idle Flag not found" severity warning;
          end if;
        else
          report "FRAMERP: KO - Default state - Output frame is not valid without sent data" severity warning;
        end if;
      -- behaviour tests:
        -- align the end of data to the beginning of a new frame processing cycle
        wait for CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD*(FRAME_REPETITION_CYCLES - (FRAME_OUTPUT_CYCLES_REQUIRED mod FRAME_REPETITION_CYCLES) + FRAME_ACQUISITION_CYCLES_IDLE);
        -- send data for 1 frame
        for i in 0 to (CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH*8/CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE)-1 loop
          bench_sti_framer0_data_valid <= '1';
          wait for CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD/2;
          framer_expected_data(0)(i) := bench_sti_framer0_data;
          wait for CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD/2;
          if (i /= (CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH*8/CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE)-1) then
            if (CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO /= 1) then
              bench_sti_framer0_data_valid <= '0';
              wait for (CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO-1)*CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD;
            end if;
          end if;
        end loop;
        bench_sti_framer0_data_valid <= '0';
        bench_ena_framer0_random_data <= '0';
        -- wait for footer to be processed
        wait for CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD*(FRAME_PROCESSING_CYCLES_REQUIRED+4);
        if bench_res_framer0_data_valid = '0' then
          report "FRAMERP: KO - Output frame is not ready in time" severity warning;
        else
          report "FRAMERP: OK - Output frame is ready in time" severity note;
          -- check frame content is coherent with sent data
          for i in 0 to (CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH*8/CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE)-1 loop
            if (bench_res_framer0_data((CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_FOOTER_LENGTH)*8-CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE*i-1 downto (CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_FOOTER_LENGTH)*8-CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE*(i+1)) /= framer_expected_data(0)(i)) then
              report "FRAMERP: KO - Output frame content is not equal to sent data - loop: " & integer'image(i) severity warning;
              frame_content_ok := '0';
            else
              if (i = (CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH*8/CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE)-1) and (frame_content_ok = '1') then
                report "FRAMERP: OK - Output frame is equal to sent data" severity note;
              end if;
            end if;
          end loop;
        end if;
      -- send data every CCSDS_TX_FRAMER_PARALLELISM_MAX_RATIO clk during CCSDS_RXTX_BENCH_FRAMER0_FRAME_NUMBER*frame_processing time, store sent data for first frame and check output frame content
        bench_ena_framer0_random_data <= '1';
        -- align the end of data to the beginning of a new frame processing cycle
        wait for CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD*(FRAME_REPETITION_CYCLES - (FRAME_OUTPUT_CYCLES_REQUIRED mod FRAME_REPETITION_CYCLES) + FRAME_ACQUISITION_CYCLES_IDLE);
        frame_content_ok := '1';
        for f in 0 to (CCSDS_RXTX_BENCH_FRAMER0_FRAME_NUMBER-1) loop
          for i in 0 to (CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH*8/CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE)-1 loop
            bench_sti_framer0_data_valid <= '1';
            wait for CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD/2;
            framer_expected_data(f)(i) := bench_sti_framer0_data;
            wait for CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD/2;
            if (CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO /= 1) then
              bench_sti_framer0_data_valid <= '0';
              wait for (CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO-1)*CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD;
            end if;
          end loop;
          -- waiting for footer to be processed
          for data_packet in 0 to ((FRAME_PROCESSING_CYCLES_REQUIRED-1)/CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO)-1 loop
            bench_sti_framer0_data_valid <= '1';
            wait for CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD;
            if (data_packet /= ((FRAME_PROCESSING_CYCLES_REQUIRED-1)/CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO-1))  then
              if (CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO /= 1) then
                bench_sti_framer0_data_valid <= '0';
                wait for (CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO-1)*CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD;
              end if;
            end if;
          end loop;
          if (CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO /= 1) then
            bench_sti_framer0_data_valid <= '0';
          end if;
          wait for 5*CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD;
          if bench_res_framer0_data_valid = '0' then
            report "FRAMERP: KO - Output frame is not ready in time - frame loop: " & integer'image(f) severity warning;
          else
            -- check frame content is coherent with sent data
            for i in 0 to (CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH*8/CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE)-1 loop
              if (bench_res_framer0_data((CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_FOOTER_LENGTH)*8-CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE*i-1 downto (CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_FOOTER_LENGTH)*8-CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE*(i+1)) /= framer_expected_data(f)(i)) then
                report "FRAMERP: KO - Output frame content is not equal to sent data - frame loop: " & integer'image(f) & " - data loop: " & integer'image(i) severity warning;
                frame_content_ok := '0';
              else
                if (i = (CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH*8/CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE)-1) and (f = (CCSDS_RXTX_BENCH_FRAMER0_FRAME_NUMBER-1)) and (frame_content_ok = '1') then
                  report "FRAMERP: OK - Received output frames are all equal to sent data" severity note;
                end if;
              end if;
            end loop;
          end if;
          if (f /= (CCSDS_RXTX_BENCH_FRAMER0_FRAME_NUMBER-1)) then
            -- fill current frame to start with new one
            if ((((CCSDS_RXTX_BENCH_FRAMER0_HEADER_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_FOOTER_LENGTH)*8) mod FRAME_REPETITION_CYCLES) /= 0) then
              nb_data := (FRAME_REPETITION_CYCLES - (((CCSDS_RXTX_BENCH_FRAMER0_HEADER_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_FOOTER_LENGTH)*8) mod FRAME_REPETITION_CYCLES))/CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO;
              for i in 0 to nb_data-1 loop
                bench_sti_framer0_data_valid <= '1';
                wait for CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD;
                if (CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO /= 1) then
                  bench_sti_framer0_data_valid <= '0';
                  wait for (CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO-1)*CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD;
                end if;
              end loop;
              -- align the end of data to the beginning of a new frame processing cycle
              wait for CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD*(2*FRAME_REPETITION_CYCLES - (FRAME_OUTPUT_CYCLES_REQUIRED mod FRAME_REPETITION_CYCLES) + FRAME_ACQUISITION_CYCLES_IDLE - nb_data*CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO);
            else
              -- align the end of data to the beginning of a new frame processing cycle
              wait for CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD*(FRAME_REPETITION_CYCLES - (FRAME_OUTPUT_CYCLES_REQUIRED mod FRAME_REPETITION_CYCLES) + FRAME_ACQUISITION_CYCLES_IDLE);            
            end if;
          end if;
        end loop;
        bench_sti_framer0_data_valid <= '0';
        bench_ena_framer0_random_data <= '0';
        -- wait for last frame to be processed and presented
        wait for CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD*(FRAME_REPETITION_CYCLES*(((FRAME_PROCESSING_CYCLES_REQUIRED+1)/FRAME_REPETITION_CYCLES)+4));
      -- final state tests:
        if bench_res_framer0_data_valid = '1' then
          if (bench_res_framer0_data((CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_FOOTER_LENGTH)*8+10 downto (CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_FOOTER_LENGTH)*8) = "11111111110") then
            report "FRAMERP: OK - Final state - Output frame is valid and Only Idle Data flag found" severity note;
          else
            report "FRAMERP: KO - Final state - Output frame is valid without sent data - Only Idle Flag not found" severity warning;
          end if;
        else
          report "FRAMERP: KO - Final state - Output frame is not valid without sent data" severity warning;
        end if;
        report "FRAMERP: END FRAMER TESTS" severity note;
      -- do nothing
        wait;
      end process;
    --=============================================================================
    -- Begin of lfsrp
    -- generation of lfsr subsystem read-write unit-tests
    --=============================================================================
    -- read: 
    -- write: 
    -- r/w: 
    LFSRP : process
      begin
      -- let the system free run
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2);
      -- default state tests:
      -- let the system reset
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2 + CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION + CCSDS_RXTX_BENCH_START_LFSR_WAIT_DURATION);
      -- initial state tests:
      -- behaviour tests:
        report "LFSRP: START LFSR TESTS" severity note;
        wait for (CCSDS_RXTX_BENCH_LFSR0_RESULT'length)*CCSDS_RXTX_BENCH_LFSR0_CLK_PERIOD;
        if (bench_res_lfsr0_data_valid = '1') then
          report "LFSRP: OK - LFSR output is valid" severity note;
          if (bench_res_lfsr0_data = CCSDS_RXTX_BENCH_LFSR0_RESULT) then
            report "LFSRP: OK - LFSR output is equal to expected output" severity note;
          else
            report "LFSRP: KO - LFSR output is different from expected output" severity warning;
          end if;
        else
          report "LFSRP: KO - LFSR output is not valid" severity warning;
        end if;
      -- final state tests:
        report "LFSRP: END LFSR TESTS" severity note;
      -- do nothing
        wait;
      end process;
    --=============================================================================
    -- Begin of serdesp
    -- generation of serdes subsystem unit-tests
    --=============================================================================
    -- read: bench_res_serdes0_data_par_valid, bench_res_serdes0_data_par, bench_res_serdes0_data_ser, bench_res_serdes0_data_ser_valid, bench_res_serdes0_busy
    -- write: bench_sti_serdes0_data_par_valid, bench_sti_serdes0_data_ser_valid, bench_ena_serdes0_random_data
    -- r/w: 
    SERDESP : process
      variable serdes_expected_output: std_logic_vector(CCSDS_RXTX_BENCH_SERDES0_DEPTH-1 downto 0) := (others => '0');
      variable serdes_ok: std_logic := '1';
      begin
      -- let the system free run
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2);
      -- default state tests:
        -- check serdes is not valid
        if (bench_res_serdes0_data_par_valid = '0') then
          report "SERDESP: OK - Default state - Serdes parallel output is not valid" severity note;
        else
          report "SERDESP: KO - Default state - Serdes parallel output is valid" severity warning;
        end if;
        if (bench_res_serdes0_data_ser_valid = '0') then
          report "SERDESP: OK - Default state - Serdes serial output is not valid" severity note;
        else
          report "SERDESP: KO - Default state - Serdes serial output is valid" severity warning;
        end if;
        if (bench_res_serdes0_busy = '0') then
          report "SERDESP: OK - Default state - Serdes is not busy" severity note;
        else
          report "SERDESP: KO - Default state - Serdes is busy" severity warning;
        end if;
      -- let the system reset
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2 + CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION + CCSDS_RXTX_BENCH_START_SERDES_WAIT_DURATION);
      -- initial state tests:
        -- check serdes is not valid
        if (bench_res_serdes0_data_par_valid = '0') then
          report "SERDESP: OK - Initial state - Serdes parallel output is not valid" severity note;
        else
          report "SERDESP: KO - Initial state - Serdes parallel output is valid" severity warning;
        end if;
        if (bench_res_serdes0_data_ser_valid = '0') then
          report "SERDESP: OK - Initial state - Serdes serial output is not valid" severity note;
        else
          report "SERDESP: KO - Initial state - Serdes serial output is valid" severity warning;
        end if;
        if (bench_res_serdes0_busy = '0') then
          report "SERDESP: OK - Initial state - Serdes is not busy" severity note;
        else
          report "SERDESP: KO - Initial state - Serdes is busy" severity warning;
        end if;
      -- behaviour tests:
        report "SERDESP: START SERDES TESTS" severity note;
        bench_ena_serdes0_random_data <= '1';
        wait for CCSDS_RXTX_BENCH_SERDES0_CLK_PERIOD;
        -- test par2ser
        -- signal valid parallel data input
        bench_sti_serdes0_data_par_valid <= '1';
        wait for CCSDS_RXTX_BENCH_SERDES0_CLK_PERIOD/2;
        serdes_expected_output := bench_sti_serdes0_data_par;
        wait for CCSDS_RXTX_BENCH_SERDES0_CLK_PERIOD/2;
        bench_sti_serdes0_data_par_valid <= '0';
        for bit_pointer in (CCSDS_RXTX_BENCH_SERDES0_DEPTH-1) downto 0 loop
          if (bench_res_serdes0_busy = '0') then
            report "SERDESP: KO - Serdes is not busy" severity warning;
          else
            if (bench_res_serdes0_data_ser_valid = '1') then
              if (bench_res_serdes0_data_ser /= serdes_expected_output(bit_pointer)) then
                serdes_ok := '0';
                report "SERDESP: KO - Serdes serialized output data doesn't match expected output - cycle " & integer'image(bit_pointer) severity warning;
                report "Expected value: " & std_logic'image(serdes_expected_output(bit_pointer)) severity warning;
                report "Received value: " & std_logic'image(bench_res_serdes0_data_ser) severity warning;
              else
                if (serdes_ok = '1') and (bit_pointer = 0) then
                  report "SERDESP: OK - Serdes serialized output data match expected output" severity note;
                end if;
              end if;
            else
              report "SERDESP: KO - Serdes serialized output data is not valid" severity warning;
            end if;
          end if;
          wait for CCSDS_RXTX_BENCH_SERDES0_CLK_PERIOD;
        end loop;
        -- test ser2par
        -- signal valid serial data input
        serdes_expected_output := (others => '0');
        bench_sti_serdes0_data_ser_valid <= '1';
        for bit_pointer in (CCSDS_RXTX_BENCH_SERDES0_DEPTH-1) downto 0 loop
          wait for CCSDS_RXTX_BENCH_SERDES0_CLK_PERIOD/2;
          serdes_expected_output(bit_pointer) := bench_sti_serdes0_data_ser;
          wait for CCSDS_RXTX_BENCH_SERDES0_CLK_PERIOD/2;
        end loop;
        bench_sti_serdes0_data_ser_valid <= '0';
        bench_ena_serdes0_random_data <= '0';
        if (bench_res_serdes0_data_par_valid = '1') then
          report "SERDESP: OK - Serdes parallelized output data is valid" severity note;
          if (bench_res_serdes0_data_par = serdes_expected_output) then
            report "SERDESP: OK - Serdes parallelized output data match expected output" severity note;
          else
            report "SERDESP: KO - Serdes parallelized output data doesn't match expected output" severity warning;
            report "Expected value:" severity warning;
            for bit_pointer in 0 to CCSDS_RXTX_BENCH_SERDES0_DEPTH-1 loop
              report std_logic'image(serdes_expected_output(bit_pointer)) severity warning;
            end loop;
            report "Received value:" severity warning;
            for bit_pointer in 0 to CCSDS_RXTX_BENCH_SERDES0_DEPTH-1 loop
              report std_logic'image(bench_res_serdes0_data_par(bit_pointer)) severity warning;
            end loop;
          end if;
        else
          report "SERDESP: KO - Serdes parallelized output data is not valid" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_SERDES0_CLK_PERIOD;
--TODO: TEST SER2PAR + PAR2SER SIMULTANEOUSLY
        -- many par2ser cycles
        bench_ena_serdes0_random_data <= '1';
        serdes_expected_output := (others => '0');
        serdes_ok := '1';
        for cycle_number in 0 to CCSDS_RXTX_BENCH_SERDES0_CYCLES_NUMBER-1 loop
          for bit_pointer in (CCSDS_RXTX_BENCH_SERDES0_DEPTH-1) downto 0 loop
            if (bit_pointer = (CCSDS_RXTX_BENCH_SERDES0_DEPTH-1)) then
              -- signal valid parallel data input
              bench_sti_serdes0_data_par_valid <= '1';
              wait for CCSDS_RXTX_BENCH_SERDES0_CLK_PERIOD/2;
              serdes_expected_output := bench_sti_serdes0_data_par;
              wait for CCSDS_RXTX_BENCH_SERDES0_CLK_PERIOD/2;
              bench_sti_serdes0_data_par_valid <= '0';
            else
              wait for CCSDS_RXTX_BENCH_SERDES0_CLK_PERIOD;
            end if;
            if (bench_res_serdes0_busy = '0') then
              report "SERDESP: KO - Serdes is not busy" severity warning;
            else
              if (bench_res_serdes0_data_ser_valid = '1') then
                if (bench_res_serdes0_data_ser /= serdes_expected_output(bit_pointer)) then
                  serdes_ok := '0';
                  report "SERDESP: KO - Serdes serialized output data doesn't match expected output - cycle " & integer'image(bit_pointer) severity warning;
                  report "Expected value: " & std_logic'image(serdes_expected_output(bit_pointer)) severity warning;
                  report "Received value: " & std_logic'image(bench_res_serdes0_data_ser) severity warning;
                else
                  if (serdes_ok = '1') and (bit_pointer = 0) and (cycle_number = (CCSDS_RXTX_BENCH_SERDES0_CYCLES_NUMBER-1)) then
                    report "SERDESP: OK - All serdes serialized output data match expected outputs" severity note;
                  end if;
                end if;
              else
                report "SERDESP: KO - Serdes serialized output data is not valid" severity warning;
              end if;
            end if;
          end loop;
        end loop;
        -- many par2ser cycles
        serdes_expected_output := (others => '0');
        serdes_ok := '1';
        for cycle_number in 0 to CCSDS_RXTX_BENCH_SERDES0_CYCLES_NUMBER-1 loop
          -- signal valid serial data input
          bench_sti_serdes0_data_ser_valid <= '1';
          for bit_pointer in (CCSDS_RXTX_BENCH_SERDES0_DEPTH-1) downto 0 loop
            wait for CCSDS_RXTX_BENCH_SERDES0_CLK_PERIOD/2;
            serdes_expected_output(bit_pointer) := bench_sti_serdes0_data_ser;
            wait for CCSDS_RXTX_BENCH_SERDES0_CLK_PERIOD/2;
          end loop;
          if (bench_res_serdes0_data_par_valid = '1') then
            if (bench_res_serdes0_data_par = serdes_expected_output) then
              if (cycle_number = (CCSDS_RXTX_BENCH_SERDES0_CYCLES_NUMBER-1)) and (serdes_ok = '1') then
                report "SERDESP: OK - All serdes parallelized output data match expected outputs" severity note;
              end if;
            else
              serdes_ok := '0';
              report "SERDESP: KO - Serdes parallelized output data doesn't match expected output" severity warning;
              report "Expected value:" severity warning;
              for bit_pointer in 0 to CCSDS_RXTX_BENCH_SERDES0_DEPTH-1 loop
                report std_logic'image(serdes_expected_output(bit_pointer)) severity warning;
              end loop;
              report "Received value:" severity warning;
              for bit_pointer in 0 to CCSDS_RXTX_BENCH_SERDES0_DEPTH-1 loop
                report std_logic'image(bench_res_serdes0_data_par(bit_pointer)) severity warning;
              end loop;
            end if;
          else
            report "SERDESP: KO - Serdes parallelized output data is not valid" severity warning;
          end if;
        end loop;
        bench_sti_serdes0_data_ser_valid <= '0';
        bench_ena_serdes0_random_data <= '0';
        wait for CCSDS_RXTX_BENCH_SERDES0_CLK_PERIOD;
      -- final state tests:
        -- check serdes is not valid
        if (bench_res_serdes0_data_par_valid = '0') then
          report "SERDESP: OK - Final state - Serdes parallel output is not valid" severity note;
        else
          report "SERDESP: KO - Final state - Serdes parallel output is valid" severity warning;
        end if;
        if (bench_res_serdes0_data_ser_valid = '0') then
          report "SERDESP: OK - Final state - Serdes serial output is not valid" severity note;
        else
          report "SERDESP: KO - Final state - Serdes serial output is valid" severity warning;
        end if;
        if (bench_res_serdes0_busy = '0') then
          report "SERDESP: OK - Final state - Serdes is not busy" severity note;
        else
          report "SERDESP: KO - Final state - Serdes is busy" severity warning;
        end if;
        report "SERDESP: END SERDES TESTS" severity note;
      -- do nothing
        wait;
      end process;
    --=============================================================================
    -- Begin of resetp
    -- generation of reset pulses
    --=============================================================================
    -- read: 
    -- write: bench_sti_rxtx0_wb_rst, bench_sti_crc0_rst, bench_sti_buffer0_rst, bench_sti_framer0_rst
    -- r/w: 
    RESETP : process
      begin
        -- let the system free run
        wait for CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION;
        report "RESETP: START RESET SIGNAL TEST" severity note;
        -- send reset signals
        bench_sti_rxtx0_wb_rst <= '1';
        bench_sti_crc0_rst <= '1';
        bench_sti_buffer0_rst <= '1';
        bench_sti_framer0_rst <= '1';
        bench_sti_lfsr0_rst <= '1';
        -- wait for some time
        wait for CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION;
        report "RESETP: END RESET SIGNAL TEST" severity note;
        -- stop reset signals
        bench_sti_rxtx0_wb_rst <= '0';
        bench_sti_crc0_rst <= '0';
        bench_sti_buffer0_rst <= '0';
        bench_sti_framer0_rst <= '0';
        bench_sti_lfsr0_rst <= '0';
        -- do nothing
        wait;
      end process;
    --=============================================================================
    -- Begin of wbrwp
    -- generation of master wb read / write cycles / aligned with clk0
    --=============================================================================
    -- read: bench_res_rxtx0_wb_ack0, bench_res_rxtx0_wb_err0, bench_res_rxtx0_wb_rty0, bench_sti_rxtx0_wb_random_dat0
    -- write: bench_sti_rxtx0_wb_adr0, bench_sti_rxtx0_wb_cyc0, bench_sti_rxtx0_wb_stb0, bench_sti_rxtx0_wb_we0, bench_sti_rxtx0_wb_dat0, bench_ena_rxtx0_random_data
    -- r/w: 
    WBRWP : process
      begin
      -- let the system free run
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2);
      -- default state tests:
        if (bench_res_rxtx0_wb_ack = '0') then
          report "WBRWP: OK - Default state - ACK not enabled" severity note;
        else
          report "WBRWP: OK - Default state - ACK enabled" severity warning;
        end if;
        if (bench_res_rxtx0_wb_err = '0') then
          report "WBRWP: OK - Default state - ERR not enabled" severity note;
        else
          report "WBRWP: OK - Default state - ERR enabled" severity warning;
        end if;
        if (bench_res_rxtx0_wb_rty = '0') then
          report "WBRWP: OK - Default state - RTY not enabled" severity note;
        else
          report "WBRWP: OK - Default state - RTY enabled" severity warning;
        end if;
      -- let the system reset
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2 + CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION + CCSDS_RXTX_BENCH_START_WB_WAIT_DURATION);
      -- initial state tests:
        if (bench_res_rxtx0_wb_ack = '0') then
          report "WBRWP: OK - Initial state - ACK not enabled" severity note;
        else
          report "WBRWP: OK - Initial state - ACK enabled" severity warning;
        end if;
        if (bench_res_rxtx0_wb_err = '0') then
          report "WBRWP: OK - Initial state - ERR not enabled" severity note;
        else
          report "WBRWP: OK - Initial state - ERR enabled" severity warning;
        end if;
        if (bench_res_rxtx0_wb_rty = '0') then
          report "WBRWP: OK - Initial state - RTY not enabled" severity note;
        else
          report "WBRWP: OK - Initial state - RTY enabled" severity warning;
        end if;
      -- behaviour tests:
        report "WBRWP: START WISHBONE BUS READ-WRITE TESTS" severity note;
        bench_ena_rxtx0_random_data <= '1';
        bench_sti_rxtx0_wb_we <= '0';
        -- start a basic rx read cycle
        bench_sti_rxtx0_wb_adr <= "0000";
        bench_sti_rxtx0_wb_cyc <= '1';
        bench_sti_rxtx0_wb_stb <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD*1.5;
        if (bench_res_rxtx0_wb_ack = '1') and (bench_res_rxtx0_wb_err = '0') and (bench_res_rxtx0_wb_rty = '0') then
          report "WBRWP: OK - RX read cycle success" severity note;
        else
          report "WBRWP: KO - RX read cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD/2;
        bench_sti_rxtx0_wb_cyc <= '0';
        bench_sti_rxtx0_wb_stb <= '0';
        bench_sti_rxtx0_wb_we <= '0';
        bench_sti_rxtx0_wb_dat <= (others => '0');
        bench_sti_rxtx0_wb_adr <= "0000";
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD*10;
        -- start an error read cycle
        bench_sti_rxtx0_wb_adr <= "0001";
        bench_sti_rxtx0_wb_cyc <= '1';
        bench_sti_rxtx0_wb_stb <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD*1.5;
        if (bench_res_rxtx0_wb_ack = '0') and (bench_res_rxtx0_wb_err = '1') and (bench_res_rxtx0_wb_rty = '1') then
          report "WBRWP: OK - Error read cycle success" severity note;
        else
          report "WBRWP: KO - Error read cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD/2;
        bench_sti_rxtx0_wb_cyc <= '0';
        bench_sti_rxtx0_wb_stb <= '0';
        bench_sti_rxtx0_wb_we <= '0';
        bench_sti_rxtx0_wb_dat <= (others => '0');
        bench_sti_rxtx0_wb_adr <= "0000";
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD*10;
        -- start a basic configuration write cycle -> disable rx
        bench_sti_rxtx0_wb_we <= '1';
        bench_sti_rxtx0_wb_adr <= "0001";
        bench_sti_rxtx0_wb_dat <= (others => '0');
        bench_sti_rxtx0_wb_cyc <= '1';
        bench_sti_rxtx0_wb_stb <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD*1.5;
        if (bench_res_rxtx0_wb_ack = '1') and (bench_res_rxtx0_wb_err = '0') and (bench_res_rxtx0_wb_rty = '0') then
          report "WBRWP: OK - RXTX configuration write cycle success (RX disabled)" severity note;
        else
          report "WBRWP: KO - RXTX configuration write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD/2;
        bench_sti_rxtx0_wb_cyc <= '0';
        bench_sti_rxtx0_wb_stb <= '0';
        bench_sti_rxtx0_wb_we <= '0';
        bench_sti_rxtx0_wb_dat <= (others => '0');
        bench_sti_rxtx0_wb_adr <= "0000";
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD*10;
        -- start a basic configuration write cycle -> disable tx
        bench_sti_rxtx0_wb_we <= '1';
        bench_sti_rxtx0_wb_adr <= "0010";
        bench_sti_rxtx0_wb_dat <= (others => '0');
        bench_sti_rxtx0_wb_cyc <= '1';
        bench_sti_rxtx0_wb_stb <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD*1.5;
        if (bench_res_rxtx0_wb_ack = '1') and (bench_res_rxtx0_wb_err = '0') and (bench_res_rxtx0_wb_rty = '0') then
          report "WBRWP: OK - RXTX configuration write cycle success (TX disabled)" severity note;
        else
          report "WBRWP: KO - RXTX configuration write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD/2;
        bench_sti_rxtx0_wb_cyc <= '0';
        bench_sti_rxtx0_wb_stb <= '0';
        bench_sti_rxtx0_wb_we <= '0';
        bench_sti_rxtx0_wb_dat <= (others => '0');
        bench_sti_rxtx0_wb_adr <= "0000";
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD*10;
        -- start a basic configuration write cycle -> enable tx + enable internal wb data use for tx
        bench_sti_rxtx0_wb_we <= '1';
        bench_sti_rxtx0_wb_adr <= "0010";
        bench_sti_rxtx0_wb_dat <= "00000000000000000000000000000001";
        bench_sti_rxtx0_wb_cyc <= '1';
        bench_sti_rxtx0_wb_stb <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD*1.5;
        if (bench_res_rxtx0_wb_ack = '1') and (bench_res_rxtx0_wb_err = '0') and (bench_res_rxtx0_wb_rty = '0') then
          report "WBRWP: OK - RXTX configuration write cycle success (TX enabled + internal WB data use)" severity note;
        else
          report "WBRWP: KO - RXTX configuration write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD/2;
        bench_sti_rxtx0_wb_cyc <= '0';
        bench_sti_rxtx0_wb_stb <= '0';
        bench_sti_rxtx0_wb_we <= '0';
        bench_sti_rxtx0_wb_dat <= (others => '0');
        bench_sti_rxtx0_wb_adr <= "0000";
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD*10;
        -- start a basic tx write cycle
        bench_sti_rxtx0_wb_we <= '1';
        bench_sti_rxtx0_wb_adr <= "0000";
        bench_sti_rxtx0_wb_dat <= bench_sti_rxtx0_wb_random_dat;
        bench_sti_rxtx0_wb_cyc <= '1';
        bench_sti_rxtx0_wb_stb <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD*1.5;
        if (bench_res_rxtx0_wb_ack = '1') and (bench_res_rxtx0_wb_err = '0') and (bench_res_rxtx0_wb_rty = '0') then
          report "WBRWP: OK - TX write cycle success" severity note;
        else
          report "WBRWP: KO - TX write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD/2;
        bench_sti_rxtx0_wb_cyc <= '0';
        bench_sti_rxtx0_wb_stb <= '0';
        bench_sti_rxtx0_wb_we <= '0';
        bench_sti_rxtx0_wb_dat <= (others => '0');
        bench_sti_rxtx0_wb_adr <= "0000";
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD*10;
        -- start an error basic tx write cycle (unknown address)
        bench_sti_rxtx0_wb_we <= '1';
        bench_sti_rxtx0_wb_adr <= "0011";
        bench_sti_rxtx0_wb_dat <= bench_sti_rxtx0_wb_random_dat;
        bench_sti_rxtx0_wb_cyc <= '1';
        bench_sti_rxtx0_wb_stb <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD*1.5;
        if (bench_res_rxtx0_wb_ack = '0') and (bench_res_rxtx0_wb_err = '1') and (bench_res_rxtx0_wb_rty = '1') then
          report "WBRWP: OK - Error write cycle success" severity note;
        else
          report "WBRWP: KO - Error write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD/2;
        bench_sti_rxtx0_wb_cyc <= '0';
        bench_sti_rxtx0_wb_stb <= '0';
        bench_sti_rxtx0_wb_we <= '0';
        bench_sti_rxtx0_wb_dat <= (others => '0');
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD*10;
        -- start many tx write cycle
        for i in 0 to CCSDS_RXTX_BENCH_RXTX0_WB_TX_WRITE_CYCLE_NUMBER-1 loop
          bench_sti_rxtx0_wb_we <= '1';
          bench_sti_rxtx0_wb_adr <= "0000";
          bench_sti_rxtx0_wb_dat <= bench_sti_rxtx0_wb_random_dat;
          bench_sti_rxtx0_wb_cyc <= '1';
          bench_sti_rxtx0_wb_stb <= '1';
          wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD*1.5;
          if (bench_res_rxtx0_wb_ack = '0') or (bench_res_rxtx0_wb_err = '1') or (bench_res_rxtx0_wb_rty = '1') then
            report "WBRWP: KO - TX write cycle fail: ACK=" & std_logic'image(bench_res_rxtx0_wb_ack) & " ERR=" & std_logic'image(bench_res_rxtx0_wb_err) & " RTY=" & std_logic'image(bench_res_rxtx0_wb_rty) severity warning;
          else
            if (i = CCSDS_RXTX_BENCH_RXTX0_WB_TX_WRITE_CYCLE_NUMBER-1) then
              report "WBRWP: OK - Many TX write cycles terminated with success" severity note;
            end if;
          end if;
          wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD/2;
        end loop;
        bench_sti_rxtx0_wb_cyc <= '0';
        bench_sti_rxtx0_wb_stb <= '0';
        bench_sti_rxtx0_wb_we <= '0';
        bench_sti_rxtx0_wb_dat <= (others => '0');
        bench_sti_rxtx0_wb_adr <= "0000";
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD*10;
        -- start a basic configuration write cycle -> enable tx + external serial data activation
        bench_sti_rxtx0_wb_we <= '1';
        bench_sti_rxtx0_wb_adr <= "0010";
        bench_sti_rxtx0_wb_dat <= "00000000000000000000000000000011";
        bench_sti_rxtx0_wb_cyc <= '1';
        bench_sti_rxtx0_wb_stb <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD*1.5;
        if (bench_res_rxtx0_wb_ack = '1') and (bench_res_rxtx0_wb_err = '0') and (bench_res_rxtx0_wb_rty = '0') then
          report "WBRWP: OK - Basic configuration write cycle success (TX enabled + external serial data input activated)" severity note;
        else
          report "WBRWP: KO - Basic configuration write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD/2;
        bench_sti_rxtx0_wb_cyc <= '0';
        bench_sti_rxtx0_wb_stb <= '0';
        bench_sti_rxtx0_wb_we <= '0';
        bench_sti_rxtx0_wb_dat <= (others => '0');
        bench_sti_rxtx0_wb_adr <= "0000";
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD;
      -- final state tests:
        if (bench_res_rxtx0_wb_ack = '0') then
          report "WBRWP: OK - Final state - ACK not enabled" severity note;
        else
          report "WBRWP: OK - Final state - ACK enabled" severity warning;
        end if;
        if (bench_res_rxtx0_wb_err = '0') then
          report "WBRWP: OK - Final state - ERR not enabled" severity note;
        else
          report "WBRWP: OK - Final state - ERR enabled" severity warning;
        end if;
        if (bench_res_rxtx0_wb_rty = '0') then
          report "WBRWP: OK - Final state - RTY not enabled" severity note;
        else
          report "WBRWP: OK - Final state - RTY enabled" severity warning;
        end if;
        report "WBRWP: END WISHBONE BUS READ-WRITE TESTS" severity note;
--        bench_ena_rxtx0_random_data <= '0';
        wait;
      end process;
end behaviour;
--=============================================================================
-- architecture end
--=============================================================================
