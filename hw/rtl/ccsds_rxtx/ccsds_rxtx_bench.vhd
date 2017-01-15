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
---- 6: store signals results as ASCII files
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
---- 2016/11/05: adding mapper sub-component test ressources
---- 2016/11/08: adding srrc + filter sub-components test ressources
---- 2016/11/18: adding differential coder + symbols to samples mapper sub-components test ressources
---- 2016/11/20: adding files output for samples to allow external software analysis
---- 2017/15/01: adding convolutional coder
-------------------------------
--TODO: functions for sub-components interactions and checks (wb_read, wb_write, buffer_read, ...)

-- To convert hexa ASCII encoded output files (hex) to binary files (raw wav) : xxd -r -p samples.hex > samples.wav
-- To change endianness: xxd -r -p samples.hex | dd conv=swab of=samples.wav

-- libraries used
library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
library work;
use work.ccsds_rxtx_functions.all;
use work.ccsds_rxtx_parameters.all;
use work.ccsds_rxtx_types.all;

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
    CCSDS_RXTX_BENCH_RXTX0_WB_WRITE_CYCLES_MAX: integer := 8;
    -- sub-systems parameters
    -- BUFFER
    CCSDS_RXTX_BENCH_BUFFER0_DATA_BUS_SIZE : integer := 32;
    CCSDS_RXTX_BENCH_BUFFER0_SIZE : integer := 16;
    -- CODER DIFFERENTIAL
    CCSDS_RXTX_BENCH_CODER_DIFF0_BITS_PER_CODEWORD: integer := 4;
    CCSDS_RXTX_BENCH_CODER_DIFF0_DATA_BUS_SIZE: integer := 32;
    -- CODER CONVOLUTIONAL
--TODO: 2 TESTS / ONE STATIC WITH PREDIFINED INPUT/ OUTPUT + ONE DYNAMIC WITH RANDOM DATA
    CCSDS_RXTX_BENCH_CODER_CONV0_CONNEXION_VECTORS: std_logic_vector_array := ("1111001", "1011011");
    CCSDS_RXTX_BENCH_CODER_CONV0_CONSTRAINT_SIZE: integer := 7;
    CCSDS_RXTX_BENCH_CODER_CONV0_DATA_BUS_SIZE: integer := 8; --255
    CCSDS_RXTX_BENCH_CODER_CONV0_OPERATING_MODE: integer := 1;
    CCSDS_RXTX_BENCH_CODER_CONV0_OUTPUT_INVERSION: boolean_array := (false, true);
    CCSDS_RXTX_BENCH_CODER_CONV0_RATE_OUTPUT: integer := 2;
    CCSDS_RXTX_BENCH_CODER_CONV0_SEED: std_logic_vector := "000000";
    CCSDS_RXTX_BENCH_CODER_CONV0_INPUT: std_logic_vector := "10000000";
    CCSDS_RXTX_BENCH_CODER_CONV0_OUTPUT: std_logic_vector := "1011101001001001";
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
    -- FILTER
    CCSDS_RXTX_BENCH_FILTER0_MAPPER_DATA_BUS_SIZE: integer := 32;
    CCSDS_RXTX_BENCH_FILTER0_OFFSET_IQ: boolean := true;
    CCSDS_RXTX_BENCH_FILTER0_OVERSAMPLING_RATIO: integer := 4;
    CCSDS_RXTX_BENCH_FILTER0_ROLL_OFF: real := 0.5;
    CCSDS_RXTX_BENCH_FILTER0_SIG_QUANT_DEPTH: integer := 8;
    CCSDS_RXTX_BENCH_FILTER0_TARGET_SNR: real := 40.0;
    CCSDS_RXTX_BENCH_FILTER0_BITS_PER_SYMBOL: integer := 1;
    CCSDS_RXTX_BENCH_FILTER0_MODULATION_TYPE: integer := 1;
    -- FRAMER
    CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE: integer := 32;
    CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH: integer := 24;
    CCSDS_RXTX_BENCH_FRAMER0_FOOTER_LENGTH: integer := 2;
    CCSDS_RXTX_BENCH_FRAMER0_HEADER_LENGTH: integer := 6;
    CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO: integer := 8;
    -- LFSR
		CCSDS_RXTX_BENCH_LFSR0_RESULT: std_logic_vector := "1111111101001000000011101100000010011010";
		CCSDS_RXTX_BENCH_LFSR0_MEMORY_SIZE: integer := 8;
		CCSDS_RXTX_BENCH_LFSR0_MODE: std_logic := '0';
		CCSDS_RXTX_BENCH_LFSR0_POLYNOMIAL: std_logic_vector	:= x"A9";
		CCSDS_RXTX_BENCH_LFSR0_SEED: std_logic_vector	:= x"FF";
		-- MAPPER BITS SYMBOLS
		CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_BITS_PER_SYMBOL: integer := 2;
		CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_DATA_BUS_SIZE: integer := 32;
    CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_MODULATION_TYPE: integer := 1;
		-- MAPPER SYMBOLS SAMPLES
		CCSDS_RXTX_BENCH_MAPPER_SYMBOLS_SAMPLES0_BITS_PER_SYMBOL: integer := 3;
		CCSDS_RXTX_BENCH_MAPPER_SYMBOLS_SAMPLES0_QUANTIZATION_DEPTH: integer := 8;
    CCSDS_RXTX_BENCH_MAPPER_SYMBOLS_SAMPLES0_TARGET_SNR: real := 40.0;
    -- SERDES
    CCSDS_RXTX_BENCH_SERDES0_DEPTH: integer := 32;
    -- SRRC
    CCSDS_RXTX_BENCH_SRRC0_APODIZATION_WINDOW_TYPE: integer := 1;
    CCSDS_RXTX_BENCH_SRRC0_OVERSAMPLING_RATIO: integer := 8;
    CCSDS_RXTX_BENCH_SRRC0_ROLL_OFF: real := 0.5;
    CCSDS_RXTX_BENCH_SRRC0_SIG_QUANT_DEPTH: integer := 16;
    -- simulation/test parameters
    CCSDS_RXTX_BENCH_BUFFER0_CLK_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_CODER_CONV0_CLK_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_CODER_CONV0_WORDS_NUMBER: integer := 1000;
    CCSDS_RXTX_BENCH_CODER_DIFF0_CLK_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_CODER_DIFF0_WORDS_NUMBER: integer := 1000;
    CCSDS_RXTX_BENCH_CRC0_CLK_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_CRC0_RANDOM_DATA_BUS_SIZE: integer:= 8;
    CCSDS_RXTX_BENCH_CRC0_RANDOM_CHECK_NUMBER: integer:= 25;
    CCSDS_RXTX_BENCH_FILTER0_CLK_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_FILTER0_SYMBOL_WORDS_NUMBER: integer := 1000;
    CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_FRAMER0_FRAME_NUMBER: integer := 25;
    CCSDS_RXTX_BENCH_LFSR0_CLK_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_CLK_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_WORDS_NUMBER: integer := 1000;
    CCSDS_RXTX_BENCH_MAPPER_SYMBOLS_SAMPLES0_CLK_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_MAPPER_SYMBOLS_SAMPLES0_WORDS_NUMBER: integer := 1000;
    CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD: time := 20 ns;
    CCSDS_RXTX_BENCH_RXTX0_WB_TX_WRITE_CYCLE_NUMBER: integer := 5000;
    CCSDS_RXTX_BENCH_RXTX0_WB_TX_OVERFLOW: boolean := true;
    CCSDS_RXTX_BENCH_SEED: integer := 123456789;
    CCSDS_RXTX_BENCH_SERDES0_CLK_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_SERDES0_CYCLES_NUMBER: integer := 25;
    CCSDS_RXTX_BENCH_SRRC0_CLK_PERIOD: time := 10 ns;
    CCSDS_RXTX_BENCH_START_BUFFER_WAIT_DURATION: time := 2000 ns;
    CCSDS_RXTX_BENCH_START_CODER_CONV_WAIT_DURATION: time := 2000 ns;
    CCSDS_RXTX_BENCH_START_CODER_DIFF_WAIT_DURATION: time := 2000 ns;
    CCSDS_RXTX_BENCH_START_CRC_WAIT_DURATION: time := 2000 ns;
    CCSDS_RXTX_BENCH_START_FILTER_WAIT_DURATION: time := 2000 ns;
    CCSDS_RXTX_BENCH_START_FRAMER_WAIT_DURATION: time := 2000 ns;
    CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION: time := 2000 ns;
    CCSDS_RXTX_BENCH_START_LFSR_WAIT_DURATION: time := 2000 ns;
    CCSDS_RXTX_BENCH_START_MAPPER_BITS_SYMBOLS_WAIT_DURATION: time := 2000 ns;
    CCSDS_RXTX_BENCH_START_MAPPER_SYMBOLS_SAMPLES_WAIT_DURATION: time := 2000 ns;
    CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION: time := 400 ns;
    CCSDS_RXTX_BENCH_START_SERDES_WAIT_DURATION: time := 2000 ns;
    CCSDS_RXTX_BENCH_START_SRRC_WAIT_DURATION: time := 2000 ns;
    CCSDS_RXTX_BENCH_START_WB_WAIT_DURATION: time := 1600 ns;
    CCSDS_RXTX_BENCH_OUTPUT_SIGNALS_ENABLE: boolean := true;
    CCSDS_RXTX_BENCH_OUTPUT_SIGNALS_FILES_NAME: string := "samples"
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
      tx_buf_ful_o: out std_logic;
      tx_idl_o: out std_logic;
      tx_sam_i_o: out std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      tx_sam_q_o: out std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      tx_clk_o: out std_logic;
      tx_ena_o: out std_logic
    );
  end component;
  component ccsds_rxtx_buffer is
    generic(
      CCSDS_RXTX_BUFFER_DATA_BUS_SIZE : integer;
      CCSDS_RXTX_BUFFER_SIZE : integer
    );
    port(
      clk_i: in std_logic;
      dat_i: in std_logic_vector(CCSDS_RXTX_BUFFER_DATA_BUS_SIZE-1 downto 0);
      dat_val_i: in std_logic;
      dat_nxt_i: in std_logic;
      rst_i: in std_logic;
      buf_emp_o: out std_logic;
      buf_ful_o: out std_logic;
      dat_o: out std_logic_vector(CCSDS_RXTX_BUFFER_DATA_BUS_SIZE-1 downto 0);
      dat_val_o: out std_logic
    );
  end component;
  component ccsds_tx_coder_convolutional is
  generic(
    CCSDS_TX_CODER_CONV_CONNEXION_VECTORS: std_logic_vector_array;
    CCSDS_TX_CODER_CONV_CONSTRAINT_SIZE: integer;
    CCSDS_TX_CODER_CONV_DATA_BUS_SIZE: integer;
    CCSDS_TX_CODER_CONV_OPERATING_MODE: integer;
    CCSDS_TX_CODER_CONV_OUTPUT_INVERSION: boolean_array;
    CCSDS_TX_CODER_CONV_RATE_OUTPUT: integer;
    CCSDS_TX_CODER_CONV_SEED: std_logic_vector
  );
  port(
    clk_i: in std_logic;
    dat_i: in std_logic_vector(CCSDS_TX_CODER_CONV_DATA_BUS_SIZE-1 downto 0);
    dat_val_i: in std_logic;
    rst_i: in std_logic;
    bus_o: out std_logic;
    dat_o: out std_logic_vector(CCSDS_TX_CODER_CONV_DATA_BUS_SIZE*CCSDS_TX_CODER_CONV_RATE_OUTPUT-1 downto 0);
    dat_val_o: out std_logic
  );
  end component;
  component ccsds_tx_coder_differential is
    generic(
      CCSDS_TX_CODER_DIFF_BITS_PER_CODEWORD: integer;
      CCSDS_TX_CODER_DIFF_DATA_BUS_SIZE: integer
    );
    port(
      clk_i: in std_logic;
      dat_i: in std_logic_vector(CCSDS_TX_CODER_DIFF_DATA_BUS_SIZE-1 downto 0);
      dat_val_i: in std_logic;
      rst_i: in std_logic;
      dat_o: out std_logic_vector(CCSDS_TX_CODER_DIFF_DATA_BUS_SIZE-1 downto 0);
      dat_val_o: out std_logic
    );
  end component;
  component ccsds_rxtx_crc is
    generic(
      CCSDS_RXTX_CRC_DATA_LENGTH: integer;
      CCSDS_RXTX_CRC_FINAL_XOR: std_logic_vector;
      CCSDS_RXTX_CRC_INPUT_BYTES_REFLECTED: boolean;
      CCSDS_RXTX_CRC_INPUT_REFLECTED: boolean;
      CCSDS_RXTX_CRC_LENGTH: integer;
      CCSDS_RXTX_CRC_OUTPUT_REFLECTED: boolean;
      CCSDS_RXTX_CRC_POLYNOMIAL: std_logic_vector;
      CCSDS_RXTX_CRC_POLYNOMIAL_REFLECTED: boolean;
      CCSDS_RXTX_CRC_SEED: std_logic_vector
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
  component ccsds_tx_filter is
    generic(
      CCSDS_TX_FILTER_OFFSET_IQ: boolean;
      CCSDS_TX_FILTER_OVERSAMPLING_RATIO: integer;
      CCSDS_TX_FILTER_SIG_QUANT_DEPTH: integer;
      CCSDS_TX_FILTER_MODULATION_TYPE: integer;
      CCSDS_TX_FILTER_TARGET_SNR: real;
      CCSDS_TX_FILTER_BITS_PER_SYMBOL: integer
    );
    port(
      clk_i: in std_logic;
      rst_i: in std_logic;
      sym_i_i: in std_logic_vector(CCSDS_TX_FILTER_BITS_PER_SYMBOL-1 downto 0);
      sym_q_i: in std_logic_vector(CCSDS_TX_FILTER_BITS_PER_SYMBOL-1 downto 0);
      sym_val_i: in std_logic;
      sam_i_o: out std_logic_vector(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-1 downto 0);
      sam_q_o: out std_logic_vector(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-1 downto 0);
      sam_val_o: out std_logic
    );
  end component;
  component ccsds_tx_framer is
    generic (
      CCSDS_TX_FRAMER_HEADER_LENGTH: integer;
      CCSDS_TX_FRAMER_FOOTER_LENGTH: integer;
      CCSDS_TX_FRAMER_DATA_LENGTH: integer;
      CCSDS_TX_FRAMER_DATA_BUS_SIZE: integer;
      CCSDS_TX_FRAMER_PARALLELISM_MAX_RATIO: integer
    );
    port(
      clk_i: in std_logic;
      rst_i: in std_logic;
      dat_i: in std_logic_vector(CCSDS_TX_FRAMER_DATA_BUS_SIZE-1 downto 0);
      dat_val_i: in std_logic;
      dat_o: out std_logic_vector((CCSDS_TX_FRAMER_HEADER_LENGTH+CCSDS_TX_FRAMER_FOOTER_LENGTH+CCSDS_TX_FRAMER_DATA_LENGTH)*8-1 downto 0);
      dat_val_o: out std_logic;
      dat_nxt_o: out std_logic;
      idl_o: out std_logic
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
  component ccsds_tx_mapper_bits_symbols is
    generic(
      CCSDS_TX_MAPPER_DATA_BUS_SIZE: integer;
      CCSDS_TX_MAPPER_MODULATION_TYPE: integer;
      CCSDS_TX_MAPPER_BITS_PER_SYMBOL: integer
    );
    port(
      clk_i: in std_logic;
      dat_i: in std_logic_vector(CCSDS_TX_MAPPER_DATA_BUS_SIZE-1 downto 0);
      dat_val_i: in std_logic;
      rst_i: in std_logic;
      sym_i_o: out std_logic_vector(CCSDS_TX_MAPPER_BITS_PER_SYMBOL-1 downto 0);
      sym_q_o: out std_logic_vector(CCSDS_TX_MAPPER_BITS_PER_SYMBOL-1 downto 0);
      sym_val_o: out std_logic
    );
  end component;
  component ccsds_tx_mapper_symbols_samples is
    generic(
      CCSDS_TX_MAPPER_TARGET_SNR: real;
      CCSDS_TX_MAPPER_BITS_PER_SYMBOL: integer;
      CCSDS_TX_MAPPER_QUANTIZATION_DEPTH: integer
    );
    port(
      clk_i: in std_logic;
      rst_i: in std_logic;
      sym_i: in std_logic_vector(CCSDS_TX_MAPPER_BITS_PER_SYMBOL-1 downto 0);
      sym_val_i: in std_logic;
      sam_val_o: out std_logic;
      sam_o: out std_logic_vector(CCSDS_TX_MAPPER_QUANTIZATION_DEPTH-1 downto 0)
    );
  end component;
  component ccsds_rxtx_serdes is
    generic (
      CCSDS_RXTX_SERDES_DEPTH : integer
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
  component ccsds_rxtx_srrc is
    generic(
      CCSDS_RXTX_SRRC_APODIZATION_WINDOW_TYPE: integer;
      CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO: integer;
      CCSDS_RXTX_SRRC_ROLL_OFF: real;
      CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH: integer
    );
    port(
      clk_i: in std_logic;
      rst_i: in std_logic;
      sam_i: in std_logic_vector(CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH-1 downto 0);
      sam_val_i: in std_logic;
      sam_o: out std_logic_vector(CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH-1 downto 0);
      sam_val_o: out std_logic
    );
  end component;

-- internal constants
  constant CCSDS_RXTX_BENCH_FILTER0_MAPPER_CLK_PERIOD: time := CCSDS_RXTX_BENCH_FILTER0_CLK_PERIOD*CCSDS_RXTX_BENCH_FILTER0_OVERSAMPLING_RATIO;
  constant CCSDS_RXTX_BENCH_FILTER0_MAPPER_DATA_CLK_PERIOD: time := CCSDS_RXTX_BENCH_FILTER0_MAPPER_CLK_PERIOD * CCSDS_RXTX_BENCH_FILTER0_MAPPER_DATA_BUS_SIZE * CCSDS_RXTX_BENCH_FILTER0_MODULATION_TYPE / (CCSDS_RXTX_BENCH_FILTER0_BITS_PER_SYMBOL * 2);
  constant CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_DATA_CLK_PERIOD: time := CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_CLK_PERIOD * CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_DATA_BUS_SIZE * CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_MODULATION_TYPE / (CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_BITS_PER_SYMBOL * 2);
  constant CCSDS_RXTX_BENCH_RXTX0_TX_CLK_PERIOD: time := CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD/8;
  constant CCSDS_RXTX_BENCH_RXTX0_RX_CLK_PERIOD: time := CCSDS_RXTX_BENCH_RXTX0_TX_CLK_PERIOD;
-- internal variables
  signal bench_ena_buffer0_random_data: std_logic := '0';
  signal bench_ena_coder_conv0_random_data: std_logic := '0';
  signal bench_ena_coder_diff0_random_data: std_logic := '0';
  signal bench_ena_crc0_random_data: std_logic := '0';
  signal bench_ena_filter0_random_data: std_logic := '0';
  signal bench_ena_framer0_random_data: std_logic := '0';
  signal bench_ena_mapper_bits_symbols0_random_data: std_logic := '0';
  signal bench_ena_mapper_symbols_samples0_random_data: std_logic := '0';
  signal bench_ena_rxtx0_random_data: std_logic := '0';
  signal bench_ena_serdes0_random_data: std_logic := '0';
  
  file CCSDS_RXTX_BENCH_FILTER0_OUTPUT_CSV_IQ_FILE: text open write_mode is out CCSDS_RXTX_BENCH_OUTPUT_SIGNALS_FILES_NAME & "_filter0_iq.csv";
  file CCSDS_RXTX_BENCH_FILTER0_OUTPUT_HEX_IQ_FILE: text open write_mode is out CCSDS_RXTX_BENCH_OUTPUT_SIGNALS_FILES_NAME & "_filter0_iq.hex";
  file CCSDS_RXTX_BENCH_FILTER0_OUTPUT_HEX_I_FILE: text open write_mode is out CCSDS_RXTX_BENCH_OUTPUT_SIGNALS_FILES_NAME & "_filter0_i.hex";
  file CCSDS_RXTX_BENCH_FILTER0_OUTPUT_HEX_Q_FILE: text open write_mode is out CCSDS_RXTX_BENCH_OUTPUT_SIGNALS_FILES_NAME & "_filter0_q.hex";
  file CCSDS_RXTX_BENCH_SRRC0_OUTPUT_HEX_FILE: text open write_mode is out CCSDS_RXTX_BENCH_OUTPUT_SIGNALS_FILES_NAME & "_srrc0.hex";

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
  -- coder convolutional
  signal bench_sti_coder_conv0_clk: std_logic;
  signal bench_sti_coder_conv0_rst: std_logic;
  signal bench_sti_coder_conv0_dat: std_logic_vector(CCSDS_RXTX_BENCH_CODER_CONV0_DATA_BUS_SIZE-1 downto 0);
  signal bench_sti_coder_conv0_dat_val: std_logic;
  -- coder differential
  signal bench_sti_coder_diff0_clk: std_logic;
  signal bench_sti_coder_diff0_rst: std_logic;
  signal bench_sti_coder_diff0_dat: std_logic_vector(CCSDS_RXTX_BENCH_CODER_DIFF0_DATA_BUS_SIZE-1 downto 0);
  signal bench_sti_coder_diff0_dat_val: std_logic;
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
  -- filter
  signal bench_sti_filter0_clk: std_logic;
  signal bench_sti_filter0_rst: std_logic;
  signal bench_sti_filter0_sym_i: std_logic_vector(CCSDS_RXTX_BENCH_FILTER0_BITS_PER_SYMBOL-1 downto 0);
  signal bench_sti_filter0_sym_q: std_logic_vector(CCSDS_RXTX_BENCH_FILTER0_BITS_PER_SYMBOL-1 downto 0);
  signal bench_sti_filter0_sym_val: std_logic;
  signal bench_sti_filter0_mapper_data: std_logic_vector(CCSDS_RXTX_BENCH_FILTER0_MAPPER_DATA_BUS_SIZE-1 downto 0);
  signal bench_sti_filter0_mapper_clk: std_logic;
  signal bench_sti_filter0_mapper_dat_val: std_logic;
  -- framer
  signal bench_sti_framer0_clk: std_logic;
  signal bench_sti_framer0_rst: std_logic;
  signal bench_sti_framer0_data_valid: std_logic;
  signal bench_sti_framer0_data: std_logic_vector(CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE-1 downto 0);
  -- lfsr
  signal bench_sti_lfsr0_clk: std_logic;
  signal bench_sti_lfsr0_rst: std_logic;
  -- mapper bits symbols
  signal bench_sti_mapper_bits_symbols0_clk: std_logic;
  signal bench_sti_mapper_bits_symbols0_rst: std_logic;
  signal bench_sti_mapper_bits_symbols0_data: std_logic_vector(CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_DATA_BUS_SIZE-1 downto 0);
  signal bench_sti_mapper_bits_symbols0_dat_val: std_logic;
  -- mapper symbols samples
  signal bench_sti_mapper_symbols_samples0_clk: std_logic;
  signal bench_sti_mapper_symbols_samples0_rst: std_logic;
  signal bench_sti_mapper_symbols_samples0_sym: std_logic_vector(CCSDS_RXTX_BENCH_MAPPER_SYMBOLS_SAMPLES0_BITS_PER_SYMBOL-1 downto 0);
  signal bench_sti_mapper_symbols_samples0_sym_val: std_logic;
  -- serdes
  signal bench_sti_serdes0_clk: std_logic;
  signal bench_sti_serdes0_rst: std_logic;
  signal bench_sti_serdes0_data_par_valid: std_logic;
  signal bench_sti_serdes0_data_par: std_logic_vector(CCSDS_RXTX_BENCH_SERDES0_DEPTH-1 downto 0);
  signal bench_sti_serdes0_data_ser_valid: std_logic;
  signal bench_sti_serdes0_data_ser: std_logic;
  -- srrc
  signal bench_sti_srrc0_clk: std_logic;
  signal bench_sti_srrc0_rst: std_logic;
  signal bench_sti_srrc0_sam: std_logic_vector(CCSDS_RXTX_BENCH_SRRC0_SIG_QUANT_DEPTH-1 downto 0);
  signal bench_sti_srrc0_sam_val: std_logic;
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
  signal bench_res_rxtx0_tx_buf_ful: std_logic;  
  signal bench_res_rxtx0_tx_idl: std_logic;
  signal bench_res_rxtx0_tx_samples_i: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
  signal bench_res_rxtx0_tx_samples_q: std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
  signal bench_res_rxtx0_tx_ena: std_logic;
  -- buffer
  signal bench_res_buffer0_buffer_empty: std_logic;
  signal bench_res_buffer0_buffer_full: std_logic;
  signal bench_res_buffer0_data: std_logic_vector(CCSDS_RXTX_BENCH_BUFFER0_DATA_BUS_SIZE-1 downto 0);
  signal bench_res_buffer0_data_valid: std_logic;
  -- coder convolutional
  signal bench_res_coder_conv0_dat: std_logic_vector(CCSDS_RXTX_BENCH_CODER_CONV0_DATA_BUS_SIZE*CCSDS_RXTX_BENCH_CODER_CONV0_RATE_OUTPUT-1 downto 0);
  signal bench_res_coder_conv0_dat_val: std_logic;
  signal bench_res_coder_conv0_bus: std_logic;
  -- coder differential
  signal bench_res_coder_diff0_dat: std_logic_vector(CCSDS_RXTX_BENCH_CODER_DIFF0_DATA_BUS_SIZE-1 downto 0);
  signal bench_res_coder_diff0_dat_val: std_logic;
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
  -- filter
  signal bench_res_filter0_sam_i: std_logic_vector(CCSDS_RXTX_BENCH_FILTER0_SIG_QUANT_DEPTH-1 downto 0);
  signal bench_res_filter0_sam_q: std_logic_vector(CCSDS_RXTX_BENCH_FILTER0_SIG_QUANT_DEPTH-1 downto 0);
  signal bench_res_filter0_sam_val: std_logic;
  signal bench_res_filter0_srrc_sam_i: std_logic_vector(CCSDS_RXTX_BENCH_FILTER0_SIG_QUANT_DEPTH-1 downto 0);
  signal bench_res_filter0_srrc_sam_q: std_logic_vector(CCSDS_RXTX_BENCH_FILTER0_SIG_QUANT_DEPTH-1 downto 0);
  signal bench_res_filter0_srrc_sam_i_val: std_logic;
  signal bench_res_filter0_srrc_sam_q_val: std_logic;
  -- framer
  signal bench_res_framer0_data_valid: std_logic;
  signal bench_res_framer0_dat_nxt: std_logic;
  signal bench_res_framer0_idl: std_logic;
  signal bench_res_framer0_data: std_logic_vector((CCSDS_RXTX_BENCH_FRAMER0_HEADER_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_FOOTER_LENGTH+CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH)*8-1 downto 0);
  -- lfsr
  signal bench_res_lfsr0_data_valid: std_logic;
  signal bench_res_lfsr0_data: std_logic_vector(CCSDS_RXTX_BENCH_LFSR0_RESULT'length-1 downto 0);
  -- mapper bits symbols
  signal bench_res_mapper_bits_symbols0_sym_i: std_logic_vector(CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_BITS_PER_SYMBOL-1 downto 0);
  signal bench_res_mapper_bits_symbols0_sym_q: std_logic_vector(CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_BITS_PER_SYMBOL-1 downto 0);
  signal bench_res_mapper_bits_symbols0_sym_val: std_logic;
  -- mapper symbols samples
  signal bench_res_mapper_symbols_samples0_sam: std_logic_vector(CCSDS_RXTX_BENCH_MAPPER_SYMBOLS_SAMPLES0_QUANTIZATION_DEPTH-1 downto 0);
  signal bench_res_mapper_symbols_samples0_sam_val: std_logic;
  -- serdes
  signal bench_res_serdes0_busy: std_logic;
  signal bench_res_serdes0_data_par: std_logic_vector(CCSDS_RXTX_BENCH_SERDES0_DEPTH-1 downto 0);
  signal bench_res_serdes0_data_par_valid: std_logic;
  signal bench_res_serdes0_data_ser: std_logic;
  signal bench_res_serdes0_data_ser_valid: std_logic;
  -- srrc
  signal bench_res_srrc0_sam: std_logic_vector(CCSDS_RXTX_BENCH_SRRC0_SIG_QUANT_DEPTH-1 downto 0);
  signal bench_res_srrc0_sam_val: std_logic;
  signal bench_res_srrc1_sam: std_logic_vector(CCSDS_RXTX_BENCH_SRRC0_SIG_QUANT_DEPTH-1 downto 0);
  signal bench_res_srrc1_sam_val: std_logic;

--=============================================================================
-- architecture begin
--=============================================================================
  begin
    -- Instance(s) of unit under test
    rxtx_000: ccsds_rxtx_top
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
        tx_buf_ful_o => bench_res_rxtx0_tx_buf_ful,
        tx_idl_o => bench_res_rxtx0_tx_idl,
        tx_ena_o => bench_res_rxtx0_tx_ena
      );
    -- Instance(s) of sub-components under test
    buffer_000: ccsds_rxtx_buffer
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
        dat_nxt_i => bench_sti_buffer0_next_data,
        dat_o => bench_res_buffer0_data
      );
    coder_convolutionial_000: ccsds_tx_coder_convolutional
      generic map(
        CCSDS_TX_CODER_CONV_CONNEXION_VECTORS => CCSDS_RXTX_BENCH_CODER_CONV0_CONNEXION_VECTORS,
        CCSDS_TX_CODER_CONV_CONSTRAINT_SIZE => CCSDS_RXTX_BENCH_CODER_CONV0_CONSTRAINT_SIZE,
        CCSDS_TX_CODER_CONV_DATA_BUS_SIZE => CCSDS_RXTX_BENCH_CODER_CONV0_DATA_BUS_SIZE,
        CCSDS_TX_CODER_CONV_OPERATING_MODE => CCSDS_RXTX_BENCH_CODER_CONV0_OPERATING_MODE,
        CCSDS_TX_CODER_CONV_OUTPUT_INVERSION => CCSDS_RXTX_BENCH_CODER_CONV0_OUTPUT_INVERSION,
        CCSDS_TX_CODER_CONV_RATE_OUTPUT => CCSDS_RXTX_BENCH_CODER_CONV0_RATE_OUTPUT,
        CCSDS_TX_CODER_CONV_SEED => CCSDS_RXTX_BENCH_CODER_CONV0_SEED
      )
      port map(
        clk_i => bench_sti_coder_conv0_clk,
        rst_i => bench_sti_coder_conv0_rst,
        dat_val_i => bench_sti_coder_conv0_dat_val,
        dat_i => bench_sti_coder_conv0_dat,
        bus_o => bench_res_coder_conv0_bus,
        dat_val_o => bench_res_coder_conv0_dat_val,
        dat_o => bench_res_coder_conv0_dat
      );
    coder_differential_000: ccsds_tx_coder_differential
      generic map(
        CCSDS_TX_CODER_DIFF_BITS_PER_CODEWORD => CCSDS_RXTX_BENCH_CODER_DIFF0_BITS_PER_CODEWORD,
        CCSDS_TX_CODER_DIFF_DATA_BUS_SIZE => CCSDS_RXTX_BENCH_CODER_DIFF0_DATA_BUS_SIZE
      )
      port map(
        clk_i => bench_sti_coder_diff0_clk,
        rst_i => bench_sti_coder_diff0_rst,
        dat_val_i => bench_sti_coder_diff0_dat_val,
        dat_i => bench_sti_coder_diff0_dat,
        dat_val_o => bench_res_coder_diff0_dat_val,
        dat_o => bench_res_coder_diff0_dat
      );
    crc_000: ccsds_rxtx_crc
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
    crc_001: ccsds_rxtx_crc
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
    crc_002: ccsds_rxtx_crc
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
    filter000: ccsds_tx_filter
      generic map(
        CCSDS_TX_FILTER_OVERSAMPLING_RATIO => CCSDS_RXTX_BENCH_FILTER0_OVERSAMPLING_RATIO,
        CCSDS_TX_FILTER_OFFSET_IQ => CCSDS_RXTX_BENCH_FILTER0_OFFSET_IQ,
        CCSDS_TX_FILTER_SIG_QUANT_DEPTH => CCSDS_RXTX_BENCH_FILTER0_SIG_QUANT_DEPTH,
        CCSDS_TX_FILTER_MODULATION_TYPE => CCSDS_RXTX_BENCH_FILTER0_MODULATION_TYPE,
        CCSDS_TX_FILTER_TARGET_SNR => CCSDS_RXTX_BENCH_FILTER0_TARGET_SNR,
        CCSDS_TX_FILTER_BITS_PER_SYMBOL => CCSDS_RXTX_BENCH_FILTER0_BITS_PER_SYMBOL
      )
      port map(
        clk_i => bench_sti_filter0_clk,
        sym_i_i => bench_sti_filter0_sym_i,
        sym_q_i => bench_sti_filter0_sym_q,
        sym_val_i => bench_sti_filter0_sym_val,
        rst_i => bench_sti_filter0_rst,
        sam_val_o => bench_res_filter0_sam_val,
        sam_i_o => bench_res_filter0_sam_i,
        sam_q_o => bench_res_filter0_sam_q
      );
    framer_000: ccsds_tx_framer
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
        dat_o => bench_res_framer0_data,
        dat_nxt_o => bench_res_framer0_dat_nxt,
        idl_o => bench_res_framer0_idl
      );
    lfsr_000: ccsds_rxtx_lfsr
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
    mapper_bits_symbols_000: ccsds_tx_mapper_bits_symbols
      generic map(
        CCSDS_TX_MAPPER_DATA_BUS_SIZE => CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_DATA_BUS_SIZE,
        CCSDS_TX_MAPPER_MODULATION_TYPE => CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_MODULATION_TYPE,
        CCSDS_TX_MAPPER_BITS_PER_SYMBOL => CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_BITS_PER_SYMBOL
      )
      port map(
        clk_i => bench_sti_mapper_bits_symbols0_clk,
        dat_i => bench_sti_mapper_bits_symbols0_data,
        dat_val_i => bench_sti_mapper_bits_symbols0_dat_val,
        rst_i => bench_sti_mapper_bits_symbols0_rst,
        sym_i_o => bench_res_mapper_bits_symbols0_sym_i,
        sym_q_o => bench_res_mapper_bits_symbols0_sym_q,
        sym_val_o => bench_res_mapper_bits_symbols0_sym_val
      );
    mapper_bits_symbols_001: ccsds_tx_mapper_bits_symbols
      generic map(
        CCSDS_TX_MAPPER_DATA_BUS_SIZE => CCSDS_RXTX_BENCH_FILTER0_MAPPER_DATA_BUS_SIZE,
        CCSDS_TX_MAPPER_MODULATION_TYPE => CCSDS_RXTX_BENCH_FILTER0_MODULATION_TYPE,
        CCSDS_TX_MAPPER_BITS_PER_SYMBOL => CCSDS_RXTX_BENCH_FILTER0_BITS_PER_SYMBOL
      )
      port map(
        clk_i => bench_sti_filter0_mapper_clk,
        dat_i => bench_sti_filter0_mapper_data,
        dat_val_i => bench_sti_filter0_mapper_dat_val,
        rst_i => bench_sti_filter0_rst,
        sym_i_o => bench_sti_filter0_sym_i,
        sym_q_o => bench_sti_filter0_sym_q,
        sym_val_o => bench_sti_filter0_sym_val
      );
    mapper_symbols_samples_000: ccsds_tx_mapper_symbols_samples
      generic map(
        CCSDS_TX_MAPPER_QUANTIZATION_DEPTH => CCSDS_RXTX_BENCH_MAPPER_SYMBOLS_SAMPLES0_QUANTIZATION_DEPTH,
        CCSDS_TX_MAPPER_TARGET_SNR => CCSDS_RXTX_BENCH_MAPPER_SYMBOLS_SAMPLES0_TARGET_SNR,
        CCSDS_TX_MAPPER_BITS_PER_SYMBOL => CCSDS_RXTX_BENCH_MAPPER_SYMBOLS_SAMPLES0_BITS_PER_SYMBOL
      )
      port map(
        clk_i => bench_sti_mapper_symbols_samples0_clk,
        sym_i => bench_sti_mapper_symbols_samples0_sym,
        sym_val_i => bench_sti_mapper_symbols_samples0_sym_val,
        rst_i => bench_sti_mapper_symbols_samples0_rst,
        sam_o => bench_res_mapper_symbols_samples0_sam,
        sam_val_o => bench_res_mapper_symbols_samples0_sam_val
      );
    serdes_000: ccsds_rxtx_serdes
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
    srrc_000: ccsds_rxtx_srrc
      generic map(
        CCSDS_RXTX_SRRC_APODIZATION_WINDOW_TYPE => CCSDS_RXTX_BENCH_SRRC0_APODIZATION_WINDOW_TYPE,
        CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO => CCSDS_RXTX_BENCH_SRRC0_OVERSAMPLING_RATIO,
        CCSDS_RXTX_SRRC_ROLL_OFF => CCSDS_RXTX_BENCH_SRRC0_ROLL_OFF,
        CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH => CCSDS_RXTX_BENCH_SRRC0_SIG_QUANT_DEPTH
      )
      port map(
        clk_i => bench_sti_srrc0_clk,
        sam_i => bench_sti_srrc0_sam,
        sam_val_i => bench_sti_srrc0_sam_val,
        rst_i => bench_sti_srrc0_rst,
        sam_o => bench_res_srrc0_sam,
        sam_val_o => bench_res_srrc0_sam_val
      );
    srrc_001: ccsds_rxtx_srrc
      generic map(
        CCSDS_RXTX_SRRC_APODIZATION_WINDOW_TYPE => CCSDS_RXTX_BENCH_SRRC0_APODIZATION_WINDOW_TYPE,
        CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO => CCSDS_RXTX_BENCH_SRRC0_OVERSAMPLING_RATIO,
        CCSDS_RXTX_SRRC_ROLL_OFF => CCSDS_RXTX_BENCH_SRRC0_ROLL_OFF,
        CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH => CCSDS_RXTX_BENCH_SRRC0_SIG_QUANT_DEPTH
      )
      port map(
        clk_i => bench_sti_srrc0_clk,
        sam_i => bench_res_srrc0_sam,
        sam_val_i => bench_res_srrc0_sam_val,
        rst_i => bench_sti_srrc0_rst,
        sam_o => bench_res_srrc1_sam,
        sam_val_o => bench_res_srrc1_sam_val
      );
    srrc_002: ccsds_rxtx_srrc
      generic map(
        CCSDS_RXTX_SRRC_APODIZATION_WINDOW_TYPE => 1,
        CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO => CCSDS_RXTX_BENCH_FILTER0_OVERSAMPLING_RATIO,
        CCSDS_RXTX_SRRC_ROLL_OFF => CCSDS_RXTX_BENCH_FILTER0_ROLL_OFF,
        CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH => CCSDS_RXTX_BENCH_FILTER0_SIG_QUANT_DEPTH
      )
      port map(
        clk_i => bench_sti_filter0_clk,
        sam_i => bench_res_filter0_sam_i,
        sam_val_i => bench_res_filter0_sam_val,
        rst_i => bench_sti_filter0_rst,
        sam_o => bench_res_filter0_srrc_sam_i,
        sam_val_o => bench_res_filter0_srrc_sam_i_val
      );
    srrc_003: ccsds_rxtx_srrc
      generic map(
        CCSDS_RXTX_SRRC_APODIZATION_WINDOW_TYPE => 1,
        CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO => CCSDS_RXTX_BENCH_FILTER0_OVERSAMPLING_RATIO,
        CCSDS_RXTX_SRRC_ROLL_OFF => CCSDS_RXTX_BENCH_FILTER0_ROLL_OFF,
        CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH => CCSDS_RXTX_BENCH_FILTER0_SIG_QUANT_DEPTH
      )
      port map(
        clk_i => bench_sti_filter0_clk,
        sam_i => bench_res_filter0_sam_q,
        sam_val_i => bench_res_filter0_sam_val,
        rst_i => bench_sti_filter0_rst,
        sam_o => bench_res_filter0_srrc_sam_q,
        sam_val_o => bench_res_filter0_srrc_sam_q_val
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
    -- Begin of bench_sti_coder_conv0_clk
    -- bench_sti_coder_conv0_clk generation
    --=============================================================================
    -- read: 
    -- write: bench_sti_coder_conv0_clk
    -- r/w: 
    BENCH_STI_CODER_CONV0_CLKP : process
      begin
        bench_sti_coder_conv0_clk <= '1';
        wait for CCSDS_RXTX_BENCH_CODER_CONV0_CLK_PERIOD/2;
        bench_sti_coder_conv0_clk <= '0';
        wait for CCSDS_RXTX_BENCH_CODER_CONV0_CLK_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_coder_diff0_clk
    -- bench_sti_coder_diff0_clk generation
    --=============================================================================
    -- read: 
    -- write: bench_sti_coder_diff0_clk
    -- r/w: 
    BENCH_STI_CODER_DIFF0_CLKP : process
      begin
        bench_sti_coder_diff0_clk <= '1';
        wait for CCSDS_RXTX_BENCH_CODER_DIFF0_CLK_PERIOD/2;
        bench_sti_coder_diff0_clk <= '0';
        wait for CCSDS_RXTX_BENCH_CODER_DIFF0_CLK_PERIOD/2;
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
    -- Begin of bench_sti_filter0_clkp
    -- bench_sti_filter0_clk generation
    --=============================================================================
    -- read: 
    -- write: bench_sti_filter0_clk
    -- r/w: 
    BENCH_STI_FILTER0_CLKP : process
      begin
        bench_sti_filter0_clk <= '1';
        wait for CCSDS_RXTX_BENCH_FILTER0_CLK_PERIOD/2;
        bench_sti_filter0_clk <= '0';
        wait for CCSDS_RXTX_BENCH_FILTER0_CLK_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_filter0_mapper_clkp
    -- bench_sti_filter0_mapper_clk generation
    --=============================================================================
    -- read: 
    -- write: bench_sti_filter0_mapper_clk
    -- r/w: 
    BENCH_STI_FILTER0_MAPPER_CLKP : process
      begin
        bench_sti_filter0_mapper_clk <= '1';
        wait for CCSDS_RXTX_BENCH_FILTER0_MAPPER_CLK_PERIOD/2;
        bench_sti_filter0_mapper_clk <= '0';
        wait for CCSDS_RXTX_BENCH_FILTER0_MAPPER_CLK_PERIOD/2;
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
    -- Begin of bench_sti_mapper_bits_symbols0_clkp
    -- bench_sti_mapper_bits_symbols0_clk generation
    --=============================================================================
    -- read: 
    -- write: bench_sti_mapper_bits_symbols0_clk
    -- r/w: 
    BENCH_STI_MAPPER_BITS_SYMBOLS0_CLKP : process
      begin
        bench_sti_mapper_bits_symbols0_clk <= '1';
        wait for CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_CLK_PERIOD/2;
        bench_sti_mapper_bits_symbols0_clk <= '0';
        wait for CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_CLK_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_mapper_symbols_samples0_clkp
    -- bench_sti_mapper_symbols_samples0_clk generation
    --=============================================================================
    -- read: 
    -- write: bench_sti_mapper_symbols_samples0_clk
    -- r/w: 
    BENCH_STI_MAPPER_SYMBOLS_SAMPLES0_CLKP : process
      begin
        bench_sti_mapper_symbols_samples0_clk <= '1';
        wait for CCSDS_RXTX_BENCH_MAPPER_SYMBOLS_SAMPLES0_CLK_PERIOD/2;
        bench_sti_mapper_symbols_samples0_clk <= '0';
        wait for CCSDS_RXTX_BENCH_MAPPER_SYMBOLS_SAMPLES0_CLK_PERIOD/2;
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
    -- Begin of bench_sti_srrc0_clkp
    -- bench_sti_srrc0_clk generation
    --=============================================================================
    -- read: 
    -- write: bench_sti_srrc0_clk
    -- r/w: 
    BENCH_STI_SRRC0_CLKP : process
      begin
        bench_sti_srrc0_clk <= '1';
        wait for CCSDS_RXTX_BENCH_SRRC0_CLK_PERIOD/2;
        bench_sti_srrc0_clk <= '0';
        wait for CCSDS_RXTX_BENCH_SRRC0_CLK_PERIOD/2;
      end process;
    --=============================================================================
    -- Begin of bench_sti_rxtx0_tx_datap
    -- bench_sti_rxtx0_tx_data generation / dephased from 1/2 clk with bench_sti_rxtx0_tx_clk
    --=============================================================================
    -- read: 
    -- write: bench_sti_rxtx0_tx_data_ser0
    -- r/w: 
    BENCH_STI_RXTX0_TX_DATAP : process
      variable seed1 : positive := CCSDS_RXTX_BENCH_SEED;
      variable seed2 : positive := CCSDS_RXTX_BENCH_SEED*2;
      variable random : std_logic_vector(1 downto 0);
      begin
        if (bench_ena_rxtx0_random_data = '1') then
          sim_generate_random_std_logic_vector(2,seed1,seed2,random);
          bench_sti_rxtx0_tx_data_ser <= random(0);
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_TX_CLK_PERIOD;
      end process;
    --=============================================================================
    -- Begin of bench_sti_buffer0_datap
    -- bench_sti_buffer0_data generation
    --=============================================================================
    -- read: bench_ena_buffer0_random_data
    -- write: bench_sti_buffer0_data
    -- r/w: 
    BENCH_STI_BUFFER0_DATAP : process
      variable seed1 : positive := CCSDS_RXTX_BENCH_SEED;
      variable seed2 : positive := CCSDS_RXTX_BENCH_SEED*2;
      variable random : std_logic_vector(CCSDS_RXTX_BENCH_BUFFER0_DATA_BUS_SIZE-1 downto 0);
      begin
        if (bench_ena_buffer0_random_data = '1') then
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_BUFFER0_DATA_BUS_SIZE,seed1,seed2,random);
          bench_sti_buffer0_data <= random;
        end if;
        wait for CCSDS_RXTX_BENCH_BUFFER0_CLK_PERIOD;
      end process;
    --=============================================================================
    -- Begin of bench_sti_coder_conv0_datap
    -- bench_sti_coder_conv0_random_data generation
    --=============================================================================
    -- read: bench_ena_coder_conv0_random_data
    -- write: bench_sti_coder_conv0_dat
    -- r/w: 
    BENCH_STI_CODER_CONV0_DATAP : process
      variable seed1 : positive := CCSDS_RXTX_BENCH_SEED;
      variable seed2 : positive := CCSDS_RXTX_BENCH_SEED*2;
      variable random : std_logic_vector(CCSDS_RXTX_BENCH_CODER_CONV0_DATA_BUS_SIZE-1 downto 0);
      begin
--        if (bench_ena_coder_conv0_random_data = '1') then
--          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_CODER_CONV0_DATA_BUS_SIZE,seed1,seed2,random);
--          bench_sti_coder_conv0_dat <= random;
--        end if;
--        wait for CCSDS_RXTX_BENCH_CODER_CONV0_CLK_PERIOD;
          bench_sti_coder_conv0_dat <= CCSDS_RXTX_BENCH_CODER_CONV0_INPUT;
          wait;
      end process;
    --=============================================================================
    -- Begin of bench_sti_coder_diff0_datap
    -- bench_sti_coder_diff0_random_data generation
    --=============================================================================
    -- read: bench_ena_coder_diff0_random_data
    -- write: bench_sti_coder_diff0_dat
    -- r/w: 
    BENCH_STI_CODER_DIFF0_DATAP : process
      variable seed1 : positive := CCSDS_RXTX_BENCH_SEED;
      variable seed2 : positive := CCSDS_RXTX_BENCH_SEED*2;
      variable random : std_logic_vector(CCSDS_RXTX_BENCH_CODER_DIFF0_DATA_BUS_SIZE-1 downto 0);
      begin
        if (bench_ena_coder_diff0_random_data = '1') then
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_CODER_DIFF0_DATA_BUS_SIZE,seed1,seed2,random);
          bench_sti_coder_diff0_dat <= random;
        end if;
        wait for CCSDS_RXTX_BENCH_CODER_DIFF0_CLK_PERIOD;
      end process;
    --=============================================================================
    -- Begin of bench_sti_crc0_datap
    -- bench_sti_crc0_random_data generation
    --=============================================================================
    -- read: bench_ena_crc0_random_data
    -- write: bench_sti_crc0_random_data
    -- r/w: 
    BENCH_STI_CRC0_DATAP : process
      variable seed1 : positive := CCSDS_RXTX_BENCH_SEED;
      variable seed2 : positive := CCSDS_RXTX_BENCH_SEED*2;
      variable random : std_logic_vector(CCSDS_RXTX_BENCH_CRC0_RANDOM_DATA_BUS_SIZE*8-1 downto 0);
      begin
        if (bench_ena_crc0_random_data = '1') then
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_CRC0_RANDOM_DATA_BUS_SIZE*8,seed1,seed2,random);
          bench_sti_crc0_random_data <= random;
        end if;
        wait for CCSDS_RXTX_BENCH_CRC0_CLK_PERIOD;
      end process;
    --=============================================================================
    -- Begin of bench_sti_filter0_datap
    -- bench_sti_filter0_mapper_data generation
    --=============================================================================
    -- read: bench_ena_filter0_random_data
    -- write: bench_sti_filter0_mapper_data
    -- r/w: 
    BENCH_STI_FILTER0_DATAP : process
      variable seed1 : positive := CCSDS_RXTX_BENCH_SEED;
      variable seed2 : positive := CCSDS_RXTX_BENCH_SEED*2;
      variable random : std_logic_vector(CCSDS_RXTX_BENCH_FILTER0_MAPPER_DATA_BUS_SIZE-1 downto 0);
      begin
        if (bench_ena_filter0_random_data = '1') then
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_FILTER0_MAPPER_DATA_BUS_SIZE,seed1,seed2,random);
          bench_sti_filter0_mapper_data <= random;
        end if;
        wait for CCSDS_RXTX_BENCH_FILTER0_MAPPER_DATA_CLK_PERIOD;
      end process;
    --=============================================================================
    -- Begin of bench_sti_framer0_datap
    -- bench_sti_framer0_data generation
    --=============================================================================
    -- read: bench_ena_framer0_random_data
    -- write: bench_sti_framer0_data
    -- r/w: 
    BENCH_STI_FRAMER0_DATAP : process
      variable seed1 : positive := CCSDS_RXTX_BENCH_SEED;
      variable seed2 : positive := CCSDS_RXTX_BENCH_SEED*2;
      variable random : std_logic_vector(CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE-1 downto 0);
      begin
        if (bench_ena_framer0_random_data = '1') then
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE,seed1,seed2,random);
          bench_sti_framer0_data <= random;
        end if;
        wait for CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD;
      end process;
    --=============================================================================
    -- Begin of bench_sti_mapper_bits_symbols0_datap
    -- bench_sti_mapper_bits_symbols0_data generation
    --=============================================================================
    -- read: bench_ena_mapper_bits_symbols0_random_data
    -- write: bench_sti_mapper_bits_symbols0_data
    -- r/w: 
    BENCH_STI_MAPPER_BITS_SYMBOLS0_DATAP : process
      variable seed1 : positive := CCSDS_RXTX_BENCH_SEED;
      variable seed2 : positive := CCSDS_RXTX_BENCH_SEED*2;
      variable random : std_logic_vector(CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_DATA_BUS_SIZE-1 downto 0);
      begin
        if (bench_ena_mapper_bits_symbols0_random_data = '1') then
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_DATA_BUS_SIZE,seed1,seed2,random);
          bench_sti_mapper_bits_symbols0_data <= random;
        end if;
        wait for CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_DATA_CLK_PERIOD;
      end process;
    --=============================================================================
    -- Begin of bench_sti_mapper_symbols_samples0_datap
    -- bench_sti_mapper_symbols_samples0_data generation
    --=============================================================================
    -- read: bench_ena_mapper_symbols_samples0_random_data
    -- write: bench_sti_mapper_symbols_samples0_data
    -- r/w: 
    BENCH_STI_MAPPER_SYMBOLS_SAMPLES0_DATAP : process
      variable seed1 : positive := CCSDS_RXTX_BENCH_SEED;
      variable seed2 : positive := CCSDS_RXTX_BENCH_SEED*2;
      variable random : std_logic_vector(CCSDS_RXTX_BENCH_MAPPER_SYMBOLS_SAMPLES0_BITS_PER_SYMBOL-1 downto 0);
      begin
        if (bench_ena_mapper_symbols_samples0_random_data = '1') then
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_MAPPER_SYMBOLS_SAMPLES0_BITS_PER_SYMBOL,seed1,seed2,random);
          bench_sti_mapper_symbols_samples0_sym <= random;
        end if;
        wait for CCSDS_RXTX_BENCH_MAPPER_SYMBOLS_SAMPLES0_CLK_PERIOD;
      end process;
    --=============================================================================
    -- Begin of bench_sti_serdes0_datap
    -- bench_sti_serdes0_data generation
    --=============================================================================
    -- read: bench_ena_serdes0_random_data
    -- write: bench_sti_serdes0_data_par, bench_sti_serdes0_data_ser
    -- r/w: 
    BENCH_STI_SERDES0_DATAP : process
      variable seed1 : positive := CCSDS_RXTX_BENCH_SEED;
      variable seed2 : positive := CCSDS_RXTX_BENCH_SEED*2;
      variable random : std_logic_vector(CCSDS_RXTX_BENCH_SERDES0_DEPTH-1 downto 0);
      begin
        if (bench_ena_serdes0_random_data = '1') then
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_SERDES0_DEPTH,seed1,seed2,random);
          bench_sti_serdes0_data_par <= random;
          bench_sti_serdes0_data_ser <= random(0);
        end if;
        wait for CCSDS_RXTX_BENCH_SERDES0_CLK_PERIOD;
      end process;
    --=============================================================================
    -- Begin of bench_sti_rxtx0_rx_samplesp
    -- bench_sti_rxtx0_rx_samples generation
    --=============================================================================
    -- read: bench_ena_rxtx0_random_data
    -- write: bench_sti_rxtx0_rx_samples_i, bench_sti_rxtx0_rx_samples_q
    -- r/w: 
    BENCH_STI_RXTX0_RX_SAMPLESP : process
      variable seed1 : positive := CCSDS_RXTX_BENCH_SEED;
      variable seed2 : positive := CCSDS_RXTX_BENCH_SEED*2;
      variable random1 : std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      variable random2 : std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      begin
        if (bench_ena_rxtx0_random_data = '1') then
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH,seed1,seed2,random1);
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_RX_PHYS_SIG_QUANT_DEPTH,seed2,seed1,random2);
          bench_sti_rxtx0_rx_samples_i <= random1;
          bench_sti_rxtx0_rx_samples_q <= random2;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_RX_CLK_PERIOD;
      end process;
    --=============================================================================
    -- Begin of bench_sti_rxtx0_wb_datap
    -- bench_sti_rxtx0_wb_random_dat generation
    --=============================================================================
    -- read: bench_ena_rxtx0_random_data
    -- write: bench_sti_rxtx0_wb_random_dat0
    -- r/w: 
    BENCH_STI_RXTX0_WB_DATP : process
      variable seed1 : positive := CCSDS_RXTX_BENCH_SEED;
      variable seed2 : positive := CCSDS_RXTX_BENCH_SEED*2;
      variable random1 : std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_WB_DATA_BUS_SIZE-1 downto 0);
      begin
        if (bench_ena_rxtx0_random_data = '1') then
          sim_generate_random_std_logic_vector(CCSDS_RXTX_BENCH_RXTX0_WB_DATA_BUS_SIZE,seed1,seed2,random1);
          bench_sti_rxtx0_wb_random_dat <= random1;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD;
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
    -- Begin of coderconvp
    -- generation of coder convolutional subsystem unit-tests
    --=============================================================================
    -- read: bench_res_coder_conv0_dat, bench_res_coder_conv0_dat_val, bench_res_coder_conv0_bus
    -- write: bench_ena_coder_conv0_random_data, bench_sti_coder_conv0_dat_val
    -- r/w: 
    CODERCONVP : process
    begin
      -- let the system free run
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2);
      -- default state tests:
        if (bench_res_coder_conv0_dat_val = '1') then
          report "CODERCONVP: KO - Default state - Convolutional coder output data is valid" severity warning;
        else
          report "CODERCONVP: OK - Default state - Convolutional coder output data is not valid" severity note;
        end if;
      -- let the system reset
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2 + CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION + CCSDS_RXTX_BENCH_START_CODER_CONV_WAIT_DURATION);
      -- initial state tests:
        if (bench_res_coder_conv0_dat_val = '1') then
          report "CODERCONVP: KO - Initial state - Convolutional coder output data is valid" severity warning;
        else
          report "CODERCONVP: OK - Initial state - Convolutional coder output data is not valid" severity note;
        end if;
      -- behaviour tests:
        report "CODERCONVP: START CONVOLUTIONAL CODER TESTS" severity note;
        bench_ena_coder_conv0_random_data <= '1';
        wait for CCSDS_RXTX_BENCH_CODER_CONV0_CLK_PERIOD;
        for coder_current_check in 0 to CCSDS_RXTX_BENCH_CODER_CONV0_WORDS_NUMBER-1 loop
          for coder_current_bit in 0 to CCSDS_RXTX_BENCH_CODER_CONV0_DATA_BUS_SIZE loop
            if (coder_current_bit = 0) then
              bench_sti_coder_conv0_dat_val <= '1';
            else
              bench_sti_coder_conv0_dat_val <= '0';
            end if;
            wait for CCSDS_RXTX_BENCH_CODER_CONV0_CLK_PERIOD;
          end loop;
          if (bench_res_coder_conv0_dat_val = '0') then
            report "CODERCONVP: KO - Convolutional coder output data is not valid" severity warning;
          else
            if (bench_res_coder_conv0_dat = CCSDS_RXTX_BENCH_CODER_CONV0_OUTPUT) then
              report "CODERCONVP: OK - Convolutional coder output data match" severity note;
            else
              report "CODERCONVP: KO - Convolutional coder output data doesn't match" severity warning;
            end if;
          end if;
        end loop;
        bench_ena_coder_conv0_random_data <= '0';
        wait for CCSDS_RXTX_BENCH_CODER_CONV0_CLK_PERIOD;
      -- final state tests:
        if (bench_res_coder_conv0_dat_val = '1') then
          report "CODERCONVP: KO - Final state - Convolutional coder output data is valid" severity warning;
        else
          report "CODERCONVP: OK - Final state - Convolutional coder output data is not valid" severity note;
        end if;
        report "CODERCONVP: END CONVOLUTIONAL CODER TESTS" severity note;
      -- do nothing
        wait;
    end process;
    --=============================================================================
    -- Begin of coderdiffp
    -- generation of coder differential subsystem unit-tests
    --=============================================================================
    -- read: bench_res_coder_diff0_dat, bench_res_coder_diff0_dat_val
    -- write: bench_ena_coder_diff0_random_data, bench_sti_coder_diff0_dat_val
    -- r/w: 
    CODERDIFFP : process
    begin
      -- let the system free run
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2);
      -- default state tests:
        if (bench_res_coder_diff0_dat_val = '1') then
          report "CODERDIFFP: KO - Default state - Differential coder output data is valid" severity warning;
        else
          report "CODERDIFFP: OK - Default state - Differential coder output data is not valid" severity note;
        end if;
      -- let the system reset
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2 + CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION + CCSDS_RXTX_BENCH_START_CODER_DIFF_WAIT_DURATION);
      -- initial state tests:
        if (bench_res_coder_diff0_dat_val = '1') then
          report "CODERDIFFP: KO - Initial state - Differential coder output data is valid" severity warning;
        else
          report "CODERDIFFP: OK - Initial state - Differential coder output data is not valid" severity note;
        end if;
      -- behaviour tests:
        report "CODERDIFFP: START DIFFERENTIAL CODER TESTS" severity note;
        bench_ena_coder_diff0_random_data <= '1';
        wait for CCSDS_RXTX_BENCH_CODER_DIFF0_CLK_PERIOD;
        bench_sti_coder_diff0_dat_val <= '1';
        wait for CCSDS_RXTX_BENCH_CODER_DIFF0_CLK_PERIOD*CCSDS_RXTX_BENCH_CODER_DIFF0_WORDS_NUMBER;
        bench_sti_coder_diff0_dat_val <= '0';
        bench_ena_coder_diff0_random_data <= '0';
        wait for CCSDS_RXTX_BENCH_CODER_DIFF0_CLK_PERIOD;
      -- final state tests:
        if (bench_res_coder_diff0_dat_val = '1') then
          report "CODERDIFFP: KO - Final state - Differential coder output data is valid" severity warning;
        else
          report "CODERDIFFP: OK - Final state - Differential coder output data is not valid" severity note;
        end if;
        report "CODERDIFFP: END DIFFERENTIAL CODER TESTS" severity note;
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
    -- Begin of filterp
    -- generation of filter subsystem unit-tests
    --=============================================================================
    -- read:
    -- write:
    -- r/w:
    FILTERP : process
      variable samples_csv_output: line;
      variable samples_hex_output: line;
      variable samples_hex_i_output: line;
      variable samples_hex_q_output: line;
      begin
      -- let the system free run
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2);
      -- default state tests:
      if (bench_res_filter0_sam_val = '0') then
        report "FILTERP: OK - Default state - Output samples are not valid" severity note;
      else
        report "FILTERP: KO - Default state - Output samples are valid" severity warning;
      end if;
      -- let the system reset
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2 + CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION + CCSDS_RXTX_BENCH_START_FILTER_WAIT_DURATION);
      -- initial state tests:
      -- default state tests:
      if (bench_res_filter0_sam_val = '0') then
        report "FILTERP: OK - Initial state - Output samples are not valid" severity note;
      else
        report "FILTERP: KO - Initial state - Output samples are valid" severity warning;
      end if;
      -- behaviour tests:
        report "FILTERP: START FILTER TESTS" severity note;
        if (CCSDS_RXTX_BENCH_OUTPUT_SIGNALS_ENABLE = true) then
          write(samples_csv_output, string'("I samples;Q samples - quantized on " & integer'image(CCSDS_RXTX_BENCH_FILTER0_SIG_QUANT_DEPTH) & " bits / Big-Endian (MSB first) ASCII hexa coded"));
          writeline(CCSDS_RXTX_BENCH_FILTER0_OUTPUT_CSV_IQ_FILE, samples_csv_output);
        end if;
        bench_ena_filter0_random_data <= '1';
        wait for CCSDS_RXTX_BENCH_FILTER0_MAPPER_DATA_CLK_PERIOD;
        bench_sti_filter0_mapper_dat_val <= '1';
        wait for CCSDS_RXTX_BENCH_FILTER0_BITS_PER_SYMBOL*CCSDS_RXTX_BENCH_FILTER0_MAPPER_DATA_CLK_PERIOD*CCSDS_RXTX_BENCH_FILTER0_BITS_PER_SYMBOL/CCSDS_RXTX_BENCH_FILTER0_MODULATION_TYPE;
        if (CCSDS_RXTX_BENCH_OUTPUT_SIGNALS_ENABLE = true) then
          for i in 0 to 200 loop
            wait for CCSDS_RXTX_BENCH_FILTER0_CLK_PERIOD;
            if (bench_res_filter0_sam_val = '1') then
              write(samples_csv_output, convert_std_logic_vector_to_hexa_ascii(bench_res_filter0_sam_i) & ";");
              write(samples_csv_output, convert_std_logic_vector_to_hexa_ascii(bench_res_filter0_sam_q));
              write(samples_hex_output, convert_std_logic_vector_to_hexa_ascii(bench_res_filter0_sam_i));
              write(samples_hex_output, convert_std_logic_vector_to_hexa_ascii(bench_res_filter0_sam_q));
              writeline(CCSDS_RXTX_BENCH_FILTER0_OUTPUT_CSV_IQ_FILE, samples_csv_output);
              writeline(CCSDS_RXTX_BENCH_FILTER0_OUTPUT_HEX_IQ_FILE, samples_hex_output);
              write(samples_hex_i_output, convert_std_logic_vector_to_hexa_ascii(bench_res_filter0_sam_i));
              write(samples_hex_q_output, convert_std_logic_vector_to_hexa_ascii(bench_res_filter0_sam_q));
              writeline(CCSDS_RXTX_BENCH_FILTER0_OUTPUT_HEX_I_FILE, samples_hex_i_output);
              writeline(CCSDS_RXTX_BENCH_FILTER0_OUTPUT_HEX_Q_FILE, samples_hex_q_output);
            else
              report "FILTERP: KO - Output samples are not valid" severity warning;
            end if;
          end loop;
        else
          wait for 200*CCSDS_RXTX_BENCH_FILTER0_CLK_PERIOD;
        end if;
        if (bench_res_filter0_sam_val = '1') then
          report "FILTERP: OK - Output samples are valid" severity note;
        else
          report "FILTERP: KO - Output samples are not valid" severity warning;
        end if;
        if (CCSDS_RXTX_BENCH_OUTPUT_SIGNALS_ENABLE = true) then
          for i in 0 to CCSDS_RXTX_BENCH_FILTER0_SYMBOL_WORDS_NUMBER-1 loop
            for j in 0 to CCSDS_RXTX_BENCH_FILTER0_MAPPER_CLK_PERIOD/CCSDS_RXTX_BENCH_FILTER0_CLK_PERIOD-1 loop
              wait for CCSDS_RXTX_BENCH_FILTER0_CLK_PERIOD;
              if (bench_res_filter0_sam_val = '1') then
                write(samples_csv_output, convert_std_logic_vector_to_hexa_ascii(bench_res_filter0_sam_i) & ";");
                write(samples_csv_output, convert_std_logic_vector_to_hexa_ascii(bench_res_filter0_sam_q));
                write(samples_hex_output, convert_std_logic_vector_to_hexa_ascii(bench_res_filter0_sam_i));
                write(samples_hex_output, convert_std_logic_vector_to_hexa_ascii(bench_res_filter0_sam_q));
                writeline(CCSDS_RXTX_BENCH_FILTER0_OUTPUT_CSV_IQ_FILE, samples_csv_output);
                writeline(CCSDS_RXTX_BENCH_FILTER0_OUTPUT_HEX_IQ_FILE, samples_hex_output);
                write(samples_hex_i_output, convert_std_logic_vector_to_hexa_ascii(bench_res_filter0_sam_i));
                write(samples_hex_q_output, convert_std_logic_vector_to_hexa_ascii(bench_res_filter0_sam_q));
                writeline(CCSDS_RXTX_BENCH_FILTER0_OUTPUT_HEX_I_FILE, samples_hex_i_output);
                writeline(CCSDS_RXTX_BENCH_FILTER0_OUTPUT_HEX_Q_FILE, samples_hex_q_output);
              else
                report "FILTERP: KO - Output samples are not valid" severity warning;
              end if;
            end loop;
          end loop;
        else
          wait for CCSDS_RXTX_BENCH_FILTER0_MAPPER_CLK_PERIOD*CCSDS_RXTX_BENCH_FILTER0_SYMBOL_WORDS_NUMBER;
        end if;
        bench_sti_filter0_mapper_dat_val <= '0';
        bench_ena_filter0_random_data <= '0';
        wait for CCSDS_RXTX_BENCH_FILTER0_MAPPER_CLK_PERIOD*12;
      -- final state tests:
        if (bench_res_filter0_sam_val = '0') then
          report "FILTERP: OK - Final state - Output samples are not valid" severity note;
        else
          report "FILTERP: KO - Final state - Output samples are valid" severity warning;
        end if;
        report "FILTERP: END FILTER TESTS" severity note;
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
            report "FRAMERP: OK - Initial state - Output frame is valid and Only Idle Data flag found" severity note;
          else
            report "FRAMERP: KO - Initial state - Output frame is valid without sent data - Only Idle Flag not found" severity warning;
          end if;
        else
          report "FRAMERP: KO - Initial state - Output frame is not valid without sent data" severity warning;
        end if;
        if (bench_res_framer0_dat_nxt = '0') then
          report "FRAMERP: KO - Initial state - Next data not requested" severity warning;
        else
          report "FRAMERP: OK - Initial state - Next data requested" severity note;
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
        -- wait for last frame to be processed and presented
        wait for CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD*(FRAME_REPETITION_CYCLES*(((FRAME_PROCESSING_CYCLES_REQUIRED+1)/FRAME_REPETITION_CYCLES)+4));
        -- send data continuously to test full-speed / overflow behaviour
        bench_sti_framer0_data_valid <= '1';
        wait for (CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO*CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO*CCSDS_RXTX_BENCH_FRAMER0_DATA_LENGTH*8/CCSDS_RXTX_BENCH_FRAMER0_DATA_BUS_SIZE)*CCSDS_RXTX_BENCH_FRAMER0_CLK_PERIOD;
        if (CCSDS_RXTX_BENCH_FRAMER0_PARALLELISM_MAX_RATIO /= 1) then
          if (bench_res_framer0_dat_nxt = '0') then
            report "FRAMERP: OK - Overflow stop next data request" severity note;
          else
            report "FRAMERP: KO - Overflow doesn't stop next data request" severity warning;
          end if;
        else
          if (bench_res_framer0_dat_nxt = '1') then
            report "FRAMERP: OK - Full speed doesn't stop next data request" severity note;
          else
            report "FRAMERP: KO - Full speed stop next data request" severity warning;
          end if;
        end if;
        bench_sti_framer0_data_valid <= '0';
        bench_ena_framer0_random_data <= '0';
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
        if (bench_res_framer0_dat_nxt = '0') then
          report "FRAMERP: KO - Final state - Next data not requested" severity warning;
        else
          report "FRAMERP: OK - Final state - Next data requested" severity note;
        end if;
        report "FRAMERP: END FRAMER TESTS" severity note;
      -- do nothing
        wait;
      end process;
    --=============================================================================
    -- Begin of lfsrp
    -- generation of lfsr subsystem unit-tests
    --=============================================================================
    -- read: bench_res_lfsr0_data, bench_res_lfsr0_data_valid
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
    -- Begin of mapperbitssymbolsp
    -- generation of mapper subsystem unit-tests
    --=============================================================================
    -- read: 
    -- write: bench_sti_mapper_bits_symbols0_dat_val, bench_sti_mapper_bits_symbols0_dat_val
    -- r/w: 
    MAPPERBITSSYMBOLSP : process
      begin
      -- let the system free run
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2);
      -- default state tests:
        if (bench_res_mapper_bits_symbols0_sym_val = '1') then
          report "MAPPERBITSSYMBOLSP: KO - Default state - Mapper output data is valid" severity warning;
        else
          report "MAPPERBITSSYMBOLSP: OK - Default state - Mapper output data is not valid" severity note;
        end if;
      -- let the system reset
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2 + CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION + CCSDS_RXTX_BENCH_START_MAPPER_BITS_SYMBOLS_WAIT_DURATION);
      -- initial state tests:
        if (bench_res_mapper_bits_symbols0_sym_val = '1') then
          report "MAPPERBITSSYMBOLSP: KO - Initial state - Mapper output data is valid" severity warning;
        else
          report "MAPPERBITSSYMBOLSP: OK - Initial state - Mapper output data is not valid" severity note;
        end if;
      -- behaviour tests:
        report "MAPPERBITSSYMBOLSP: START BITS TO SYMBOLS MAPPER TESTS" severity note;
        bench_ena_mapper_bits_symbols0_random_data <= '1';
        wait for CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_DATA_CLK_PERIOD;
        bench_sti_mapper_bits_symbols0_dat_val <= '1';
        wait for CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_DATA_CLK_PERIOD*CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_DATA_BUS_SIZE/CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_BITS_PER_SYMBOL*CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_WORDS_NUMBER;
        bench_sti_mapper_bits_symbols0_dat_val <= '0';
        bench_ena_mapper_bits_symbols0_random_data <= '0';
        wait for CCSDS_RXTX_BENCH_MAPPER_BITS_SYMBOLS0_DATA_CLK_PERIOD;
      -- final state tests:
        if (bench_res_mapper_bits_symbols0_sym_val = '1') then
          report "MAPPERBITSSYMBOLSP: KO - Final state - Mapper output data is valid" severity warning;
        else
          report "MAPPERBITSSYMBOLSP: OK - Final state - Mapper output data is not valid" severity note;
        end if;
        report "MAPPERBITSSYMBOLSP: END BITS TO SYMBOLS MAPPER TESTS" severity note;
      -- do nothing
        wait;
      end process;
    --=============================================================================
    -- Begin of mappersymbolssamplesp
    -- generation of mapper subsystem unit-tests
    --=============================================================================
    -- read: 
    -- write: bench_sti_mapper_bits_symbols0_dat_val, bench_sti_mapper_bits_symbols0_dat_val
    -- r/w: 
    MAPPERSYMBOLSSAMPLESP : process
      begin
      -- let the system free run
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2);
      -- default state tests:
        if (bench_res_mapper_symbols_samples0_sam_val = '1') then
          report "MAPPERSYMBOLSSAMPLESP: KO - Default state - Mapper output data is valid" severity warning;
        else
          report "MAPPERSYMBOLSSAMPLESP: OK - Default state - Mapper output data is not valid" severity note;
        end if;
      -- let the system reset
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2 + CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION + CCSDS_RXTX_BENCH_START_MAPPER_SYMBOLS_SAMPLES_WAIT_DURATION);
      -- initial state tests:
        if (bench_res_mapper_symbols_samples0_sam_val = '1') then
          report "MAPPERSYMBOLSSAMPLESP: KO - Initial state - Mapper output data is valid" severity warning;
        else
          report "MAPPERSYMBOLSSAMPLESP: OK - Initial state - Mapper output data is not valid" severity note;
        end if;
      -- behaviour tests:
        report "MAPPERSYMBOLSSAMPLESP: START SYMBOLS TO SAMPLES MAPPER TESTS" severity note;
        bench_ena_mapper_symbols_samples0_random_data <= '1';
        wait for CCSDS_RXTX_BENCH_MAPPER_SYMBOLS_SAMPLES0_CLK_PERIOD;
        bench_sti_mapper_symbols_samples0_sym_val <= '1';
        wait for CCSDS_RXTX_BENCH_MAPPER_SYMBOLS_SAMPLES0_CLK_PERIOD*CCSDS_RXTX_BENCH_MAPPER_SYMBOLS_SAMPLES0_WORDS_NUMBER;
        bench_sti_mapper_symbols_samples0_sym_val <= '0';
        bench_ena_mapper_symbols_samples0_random_data <= '0';
        wait for CCSDS_RXTX_BENCH_MAPPER_SYMBOLS_SAMPLES0_CLK_PERIOD;
      -- final state tests:
        if (bench_res_mapper_symbols_samples0_sam_val = '1') then
          report "MAPPERSYMBOLSSAMPLESP: KO - Final state - Mapper output data is valid" severity warning;
        else
          report "MAPPERSYMBOLSSAMPLESP: OK - Final state - Mapper output data is not valid" severity note;
        end if;
        report "MAPPERSYMBOLSSAMPLESP: END SYMBOLS TO SAMPLES MAPPER TESTS" severity note;
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
    -- Begin of srrcp
    -- generation of SRRC subsystem unit-tests
    --=============================================================================
    -- read: 
    -- write: 
    -- r/w: 
    SRRCP : process
    constant srrc_zero: std_logic_vector(CCSDS_RXTX_BENCH_SRRC0_SIG_QUANT_DEPTH-1 downto 0) := (others => '0');
    variable samples_hex_output: line;
      begin
      -- let the system free run
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2);
      -- default state tests:
        if (bench_res_srrc0_sam_val = '0') then
          report "SRRCP: OK - Default state - SRRC samples are not valid" severity note;
        else
          report "SRRCP: KO - Default state - SRRC samples are valid" severity warning;
        end if;
      -- let the system reset
        wait for (CCSDS_RXTX_BENCH_START_FREE_RUN_DURATION/2 + CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION + CCSDS_RXTX_BENCH_START_SRRC_WAIT_DURATION);
      -- initial state tests:
        if (bench_res_srrc0_sam_val = '0') then
          report "SRRCP: OK - Initial state - SRRC samples are not valid" severity note;
        else
          report "SRRCP: KO - Initial state - SRRC samples are valid" severity warning;
        end if;
        if (bench_res_srrc0_sam = srrc_zero) then
          report "SRRCP: OK - Initial state - SRRC samples are null" severity note;
        else
          report "SRRCP: KO - Initial state - SRRC samples are not null" severity warning;
        end if;
      -- behaviour tests:
        report "SRRCP: START SRRC TESTS" severity note;
        bench_sti_srrc0_sam(CCSDS_RXTX_BENCH_SRRC0_SIG_QUANT_DEPTH-1) <= '0';
        bench_sti_srrc0_sam(CCSDS_RXTX_BENCH_SRRC0_SIG_QUANT_DEPTH-2 downto 0) <= (others => '1');
        bench_sti_srrc0_sam_val <= '1';
        wait for CCSDS_RXTX_BENCH_SRRC0_CLK_PERIOD;
        bench_sti_srrc0_sam <= (others => '0');
        if (CCSDS_RXTX_BENCH_OUTPUT_SIGNALS_ENABLE = true) then
          for i in 0 to 400 loop
            wait for CCSDS_RXTX_BENCH_SRRC0_CLK_PERIOD;
            if (bench_res_srrc0_sam_val = '1') then
              write(samples_hex_output, convert_std_logic_vector_to_hexa_ascii(bench_res_srrc0_sam));
              writeline(CCSDS_RXTX_BENCH_SRRC0_OUTPUT_HEX_FILE, samples_hex_output);
            else
              report "SRRCP: KO - SRRC samples are not valid" severity warning;
            end if;
          end loop;
        else
          wait for 400*CCSDS_RXTX_BENCH_SRRC0_CLK_PERIOD;
        end if;
        bench_sti_srrc0_sam(0) <= '1';
        wait for CCSDS_RXTX_BENCH_SRRC0_CLK_PERIOD;
        bench_sti_srrc0_sam <= (others => '0');
        if (CCSDS_RXTX_BENCH_OUTPUT_SIGNALS_ENABLE = true) then
          for i in 0 to 400 loop
            wait for CCSDS_RXTX_BENCH_SRRC0_CLK_PERIOD;
            if (bench_res_srrc0_sam_val = '1') then
              write(samples_hex_output, convert_std_logic_vector_to_hexa_ascii(bench_res_srrc0_sam));
              writeline(CCSDS_RXTX_BENCH_SRRC0_OUTPUT_HEX_FILE, samples_hex_output);
            else
              report "SRRCP: KO - SRRC samples are not valid" severity warning;
            end if;
          end loop;
        else
          wait for 400*CCSDS_RXTX_BENCH_SRRC0_CLK_PERIOD;
        end if;
        bench_sti_srrc0_sam(CCSDS_RXTX_BENCH_SRRC0_SIG_QUANT_DEPTH-1) <= '1';
        bench_sti_srrc0_sam(CCSDS_RXTX_BENCH_SRRC0_SIG_QUANT_DEPTH-2 downto 0) <= (others => '0');
        wait for CCSDS_RXTX_BENCH_SRRC0_CLK_PERIOD;
        bench_sti_srrc0_sam <= (others => '0');
        if (CCSDS_RXTX_BENCH_OUTPUT_SIGNALS_ENABLE = true) then
          for i in 0 to 400 loop
            wait for CCSDS_RXTX_BENCH_SRRC0_CLK_PERIOD;
            if (bench_res_srrc0_sam_val = '1') then
              write(samples_hex_output, convert_std_logic_vector_to_hexa_ascii(bench_res_srrc0_sam));
              writeline(CCSDS_RXTX_BENCH_SRRC0_OUTPUT_HEX_FILE, samples_hex_output);
            else
              report "SRRCP: KO - SRRC samples are not valid" severity warning;
            end if;
          end loop;
        else
          wait for 400*CCSDS_RXTX_BENCH_SRRC0_CLK_PERIOD;
        end if;
        bench_sti_srrc0_sam_val <= '0';
      -- final state tests:
        if (bench_res_srrc0_sam_val = '0') then
          report "SRRCP: OK - Final state - SRRC samples are not valid" severity note;
        else
          report "SRRCP: KO - Final state - SRRC samples are valid" severity warning;
        end if;
        if (bench_res_srrc0_sam = srrc_zero) then
          report "SRRCP: OK - Final state - SRRC samples are null" severity note;
        else
          report "SRRCP: KO - Final state - SRRC samples are not null" severity warning;
        end if;
        report "SRRCP: END SRRC TESTS" severity note;
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
        bench_sti_coder_conv0_rst <= '1';
        bench_sti_coder_diff0_rst <= '1';
        bench_sti_crc0_rst <= '1';
        bench_sti_buffer0_rst <= '1';
        bench_sti_filter0_rst <= '1';
        bench_sti_framer0_rst <= '1';
        bench_sti_lfsr0_rst <= '1';
        bench_sti_mapper_bits_symbols0_rst <= '1';
        bench_sti_srrc0_rst <= '1';
        -- wait for some time
        wait for CCSDS_RXTX_BENCH_START_RESET_SIG_DURATION;
        report "RESETP: END RESET SIGNAL TEST" severity note;
        -- stop reset signals
        bench_sti_rxtx0_wb_rst <= '0';
        bench_sti_coder_conv0_rst <= '0';
        bench_sti_coder_diff0_rst <= '0';
        bench_sti_crc0_rst <= '0';
        bench_sti_buffer0_rst <= '0';
        bench_sti_filter0_rst <= '0';
        bench_sti_framer0_rst <= '0';
        bench_sti_lfsr0_rst <= '0';
        bench_sti_mapper_bits_symbols0_rst <= '0';
        bench_sti_srrc0_rst <= '0';
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
    variable output_done: boolean := false;
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
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD;
        -- start a basic rx read cycle
        bench_sti_rxtx0_wb_we <= '0';
        bench_sti_rxtx0_wb_adr <= "0000";
        bench_sti_rxtx0_wb_cyc <= '1';
        bench_sti_rxtx0_wb_stb <= '1';
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD;
        if (bench_res_rxtx0_wb_ack = '1') and (bench_res_rxtx0_wb_err = '0') and (bench_res_rxtx0_wb_rty = '0') then
          report "WBRWP: OK - RX read cycle success" severity note;
        else
          report "WBRWP: KO - RX read cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD;
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
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD;
        if (bench_res_rxtx0_wb_ack = '0') and (bench_res_rxtx0_wb_err = '1') and (bench_res_rxtx0_wb_rty = '1') then
          report "WBRWP: OK - Error read cycle success" severity note;
        else
          report "WBRWP: KO - Error read cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD;
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
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD;
        if (bench_res_rxtx0_wb_ack = '1') and (bench_res_rxtx0_wb_err = '0') and (bench_res_rxtx0_wb_rty = '0') then
          report "WBRWP: OK - RXTX configuration write cycle success (RX disabled)" severity note;
        else
          report "WBRWP: KO - RXTX configuration write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD;
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
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD;
        if (bench_res_rxtx0_wb_ack = '1') and (bench_res_rxtx0_wb_err = '0') and (bench_res_rxtx0_wb_rty = '0') then
          report "WBRWP: OK - RXTX configuration write cycle success (TX disabled)" severity note;
        else
          report "WBRWP: KO - RXTX configuration write cycle fail" severity warning;
        end if;
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
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD;
        if (bench_res_rxtx0_wb_ack = '1') and (bench_res_rxtx0_wb_err = '0') and (bench_res_rxtx0_wb_rty = '0') then
          report "WBRWP: OK - RXTX configuration write cycle success (TX enabled + internal WB data use)" severity note;
        else
          report "WBRWP: KO - RXTX configuration write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD;
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
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD;
        if (bench_res_rxtx0_wb_ack = '1') and (bench_res_rxtx0_wb_err = '0') and (bench_res_rxtx0_wb_rty = '0') then
          report "WBRWP: OK - TX write cycle success" severity note;
        else
          report "WBRWP: KO - TX write cycle fail" severity warning;
        end if;
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
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD;
        if (bench_res_rxtx0_wb_ack = '0') and (bench_res_rxtx0_wb_err = '1') and (bench_res_rxtx0_wb_rty = '1') then
          report "WBRWP: OK - Error write cycle success" severity note;
        else
          report "WBRWP: KO - Error write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD;
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
          wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD;
          bench_sti_rxtx0_wb_we <= '0';
          bench_sti_rxtx0_wb_adr <= "0000";
          bench_sti_rxtx0_wb_dat <= (others => '0');
          bench_sti_rxtx0_wb_cyc <= '0';
          bench_sti_rxtx0_wb_stb <= '0';
          if (bench_res_rxtx0_wb_ack = '0') or (bench_res_rxtx0_wb_err = '1') or (bench_res_rxtx0_wb_rty = '1') then
            if (CCSDS_RXTX_BENCH_RXTX0_WB_TX_OVERFLOW = true) then
              if (output_done = false) then
                output_done := true;
                report "WBRWP: OK - Many TX write cycles overflow appears after " & integer'image(i) & " WB write cycles (" & integer'image(i*CCSDS_RXTX_BENCH_RXTX0_WB_DATA_BUS_SIZE) & " bits max burst)" severity note;
              end if;
            else
              report "WBRWP: KO - TX write cycle fail: ACK=" & std_logic'image(bench_res_rxtx0_wb_ack) & " ERR=" & std_logic'image(bench_res_rxtx0_wb_err) & " RTY=" & std_logic'image(bench_res_rxtx0_wb_rty) severity warning;
            end if;
          else
            if (i = CCSDS_RXTX_BENCH_RXTX0_WB_TX_WRITE_CYCLE_NUMBER-1) then
              report "WBRWP: OK - Many TX write cycles terminated with success" severity note;
            end if;
          end if;
          if (CCSDS_RXTX_BENCH_RXTX0_WB_TX_OVERFLOW = true) then
            wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD;          
          else
            wait for (CCSDS_RXTX_BENCH_RXTX0_WB_WRITE_CYCLES_MAX-1)*CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD*2 + CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD;
          end if;
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
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD;
        if (bench_res_rxtx0_wb_ack = '1') and (bench_res_rxtx0_wb_err = '0') and (bench_res_rxtx0_wb_rty = '0') then
          report "WBRWP: OK - Basic configuration write cycle success (TX enabled + external serial data input activated)" severity note;
        else
          report "WBRWP: KO - Basic configuration write cycle fail" severity warning;
        end if;
        wait for CCSDS_RXTX_BENCH_RXTX0_WB_CLK_PERIOD;
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
