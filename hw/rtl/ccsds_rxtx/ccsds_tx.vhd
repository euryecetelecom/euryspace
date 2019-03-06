-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx
---- Version: 1.0.0
---- Description:
---- CCSDS compliant TX
-------------------------------
---- Author(s):
---- Guillaume Rembert
-------------------------------
---- Licence:
---- MIT
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;

--=============================================================================
-- Entity declaration for ccsds_tx / unitary tx external physical inputs and outputs
--=============================================================================
entity ccsds_tx is
  generic (
    constant CCSDS_TX_BITS_PER_SYMBOL: integer := 1;
    constant CCSDS_TX_BUFFER_SIZE: integer := 16; -- max number of words stored for burst write at full speed when datalinklayer is full
    constant CCSDS_TX_MODULATION_TYPE: integer := 1; -- 1=QAM/QPSK / 2=BPSK
    constant CCSDS_TX_DATA_BUS_SIZE: integer;
    constant CCSDS_TX_OVERSAMPLING_RATIO: integer := 4; -- symbols to samples over-sampling ratio
    constant CCSDS_TX_PHYS_SIG_QUANT_DEPTH : integer
  );
  port(
    -- inputs
    clk_i: in std_logic; -- transmitted samples clock
    dat_par_i: in std_logic_vector(CCSDS_TX_DATA_BUS_SIZE-1 downto 0); -- transmitted parallel data input
    dat_ser_i: in std_logic; -- transmitted serial data input
    dat_val_i: in std_logic; -- transmitted data valid input
    ena_i: in std_logic; -- system enable input
    in_sel_i: in std_logic; -- parallel / serial input selection
    rst_i: in std_logic; -- system reset input
    -- outputs
    buf_ful_o: out std_logic; -- buffer full indicator
    clk_o: out std_logic; -- output samples clock
    ena_o: out std_logic; -- enabled status indicator
    idl_o: out std_logic; -- idle data insertion indicator
    sam_i_o: out std_logic_vector(CCSDS_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- in-phased parallel complex samples
    sam_q_o: out std_logic_vector(CCSDS_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0) -- quadrature-phased parallel complex samples
  );
end ccsds_tx;

--=============================================================================
-- architecture declaration / internal connections
--=============================================================================
architecture structure of ccsds_tx is
  component ccsds_tx_manager is
    generic(
      CCSDS_TX_MANAGER_BITS_PER_SYMBOL: integer;
      CCSDS_TX_MANAGER_MODULATION_TYPE: integer;
      CCSDS_TX_MANAGER_DATA_BUS_SIZE : integer;
      CCSDS_TX_MANAGER_OVERSAMPLING_RATIO: integer
    );
    port(
      clk_i: in std_logic;
      clk_bit_o: out std_logic;
      clk_dat_o: out std_logic;
      clk_sam_o: out std_logic;
      clk_sym_o: out std_logic;
      rst_i: in std_logic;
      ena_i: in std_logic;
      ena_o: out std_logic;
      in_sel_i: in std_logic;
      dat_par_i: in std_logic_vector(CCSDS_TX_MANAGER_DATA_BUS_SIZE-1 downto 0);
      dat_ser_i: in std_logic;
      dat_val_i: in std_logic;
      dat_val_o: out std_logic;
      dat_o: out std_logic_vector(CCSDS_TX_MANAGER_DATA_BUS_SIZE-1 downto 0)
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
      dat_nxt_i: in std_logic;
      rst_i: in std_logic;
      buf_emp_o: out std_logic;
      buf_ful_o: out std_logic;
      dat_o: out std_logic_vector(CCSDS_RXTX_BUFFER_DATA_BUS_SIZE-1 downto 0);
      dat_val_o: out std_logic
    );
  end component;
  component ccsds_tx_datalink_layer is
    generic(
      CCSDS_TX_DATALINK_DATA_BUS_SIZE: integer;
      CCSDS_TX_DATALINK_CODER_DIFFERENTIAL_BITS_PER_CODEWORD: integer
    );
    port(
      clk_bit_i: in std_logic;
      clk_dat_i: in std_logic;
      rst_i: in std_logic;
      dat_val_i: in std_logic;
      dat_i: in std_logic_vector(CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);
      dat_val_o: out std_logic;
      dat_o: out std_logic_vector(CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);
      dat_nxt_o: out std_logic;
      idl_o: out std_logic
    );
  end component;
  component ccsds_tx_physical_layer is
    generic(
      CCSDS_TX_PHYSICAL_BITS_PER_SYMBOL: integer;
      CCSDS_TX_PHYSICAL_MODULATION_TYPE: integer;
      CCSDS_TX_PHYSICAL_DATA_BUS_SIZE: integer;
      CCSDS_TX_PHYSICAL_OVERSAMPLING_RATIO: integer;
      CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH: integer
    );
    port(
      clk_sam_i: in std_logic;
      clk_sym_i: in std_logic;
      rst_i: in std_logic;
      sam_i_o: out std_logic_vector(CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH-1 downto 0);
      sam_q_o: out std_logic_vector(CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH-1 downto 0);
      dat_i: in std_logic_vector(CCSDS_TX_PHYSICAL_DATA_BUS_SIZE-1 downto 0);
      dat_val_i: in std_logic
    );
  end component;

  signal wire_dat_nxt_buf: std_logic;
  signal wire_dat_val_buf: std_logic;
  signal wire_dat_val_dat: std_logic;
  signal wire_dat_val_man: std_logic;
  signal wire_dat_buf: std_logic_vector(CCSDS_TX_DATA_BUS_SIZE-1 downto 0);
  signal wire_dat_dat: std_logic_vector(CCSDS_TX_DATA_BUS_SIZE-1 downto 0);
  signal wire_dat_man: std_logic_vector(CCSDS_TX_DATA_BUS_SIZE-1 downto 0);
  signal wire_clk_dat: std_logic;
  signal wire_clk_sam: std_logic;
  signal wire_clk_sym: std_logic;
  signal wire_clk_bit: std_logic;
  signal wire_rst_man: std_logic;

begin
  tx_manager_0: ccsds_tx_manager
    generic map(
      CCSDS_TX_MANAGER_BITS_PER_SYMBOL => CCSDS_TX_BITS_PER_SYMBOL,
      CCSDS_TX_MANAGER_MODULATION_TYPE => CCSDS_TX_MODULATION_TYPE,
      CCSDS_TX_MANAGER_DATA_BUS_SIZE => CCSDS_TX_DATA_BUS_SIZE,
      CCSDS_TX_MANAGER_OVERSAMPLING_RATIO => CCSDS_TX_OVERSAMPLING_RATIO
    )
    port map(
      clk_i => clk_i,
      clk_bit_o => wire_clk_bit,
      clk_dat_o => wire_clk_dat,
      clk_sam_o => wire_clk_sam,
      clk_sym_o => wire_clk_sym,
      rst_i => rst_i,
      ena_i => ena_i,
      ena_o => ena_o,
      in_sel_i => in_sel_i,
      dat_val_i => dat_val_i,
      dat_par_i => dat_par_i,
      dat_ser_i => dat_ser_i,
      dat_val_o => wire_dat_val_man,
      dat_o => wire_dat_man
    );
  tx_buffer_0: ccsds_rxtx_buffer
    generic map(
      CCSDS_RXTX_BUFFER_DATA_BUS_SIZE => CCSDS_TX_DATA_BUS_SIZE,
      CCSDS_RXTX_BUFFER_SIZE => CCSDS_TX_BUFFER_SIZE
    )
    port map(
      clk_i => wire_clk_dat,
      rst_i => rst_i,
      dat_nxt_i => wire_dat_nxt_buf,
      dat_val_i => wire_dat_val_man,
      dat_i => wire_dat_man,
      dat_val_o => wire_dat_val_buf,
--      buf_emp_o => ,
      buf_ful_o => buf_ful_o,
      dat_o => wire_dat_buf
    );
  tx_datalink_layer_0: ccsds_tx_datalink_layer
    generic map(
      CCSDS_TX_DATALINK_DATA_BUS_SIZE => CCSDS_TX_DATA_BUS_SIZE,
      CCSDS_TX_DATALINK_CODER_DIFFERENTIAL_BITS_PER_CODEWORD => CCSDS_TX_BITS_PER_SYMBOL
    )
    port map(
      clk_dat_i => wire_clk_dat,
      clk_bit_i => wire_clk_bit,
      rst_i => rst_i,
      dat_val_i => wire_dat_val_buf,
      dat_i => wire_dat_buf,
      dat_val_o => wire_dat_val_dat,
      dat_nxt_o => wire_dat_nxt_buf,
      dat_o => wire_dat_dat,
      idl_o => idl_o
    );
  tx_physical_layer_0: ccsds_tx_physical_layer
    generic map(
      CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH => CCSDS_TX_PHYS_SIG_QUANT_DEPTH,
      CCSDS_TX_PHYSICAL_DATA_BUS_SIZE => CCSDS_TX_DATA_BUS_SIZE,
      CCSDS_TX_PHYSICAL_MODULATION_TYPE => CCSDS_TX_MODULATION_TYPE,
      CCSDS_TX_PHYSICAL_BITS_PER_SYMBOL => CCSDS_TX_BITS_PER_SYMBOL,
      CCSDS_TX_PHYSICAL_OVERSAMPLING_RATIO => CCSDS_TX_OVERSAMPLING_RATIO
    )
    port map(
      clk_sym_i => wire_clk_sym,
      clk_sam_i => wire_clk_sam,
      rst_i => rst_i,
      sam_i_o => sam_i_o,
      sam_q_o => sam_q_o,
      dat_i => wire_dat_dat,
      dat_val_i => wire_dat_val_dat
    );
    clk_o <= wire_clk_sam;
end structure;
