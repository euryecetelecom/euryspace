-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_physical_layer
---- Version: 1.0.0
---- Description:
---- TO BE DONE
-------------------------------
---- Author(s):
---- Guillaume REMBERT
-------------------------------
---- Licence:
---- MIT
-------------------------------
---- Changes list:
---- 2015/11/17: initial release
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;

-- unitary tx physical layer
entity ccsds_tx_physical_layer is
  generic (
    constant CCSDS_TX_PHYSICAL_BITS_PER_SYMBOL: integer;
    constant CCSDS_TX_PHYSICAL_MODULATION_TYPE: integer;
    constant CCSDS_TX_PHYSICAL_DATA_BUS_SIZE: integer;
    constant CCSDS_TX_PHYSICAL_OVERSAMPLING_RATIO: integer;
    constant CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH : integer
  );
  port(
    -- inputs
    clk_sam_i: in std_logic;
    clk_sym_i: in std_logic;
    dat_i: in std_logic_vector(CCSDS_TX_PHYSICAL_DATA_BUS_SIZE-1 downto 0);
    dat_val_i: in std_logic;
    rst_i: in std_logic;
    -- outputs
    sam_i_o: out std_logic_vector(CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH-1 downto 0);
    sam_q_o: out std_logic_vector(CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH-1 downto 0)
  );
end ccsds_tx_physical_layer;

-- internal processing
architecture rtl of ccsds_tx_physical_layer is
  component ccsds_tx_mapper is
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
      sym_val_o: out std_logic;
      sym_i_o: out std_logic_vector(CCSDS_TX_MAPPER_BITS_PER_SYMBOL-1 downto 0);
      sym_q_o: out std_logic_vector(CCSDS_TX_MAPPER_BITS_PER_SYMBOL-1 downto 0)
    );
  end component;
  component ccsds_tx_filter is
    generic(
      CCSDS_TX_FILTER_OVERSAMPLING_RATIO: integer;
      CCSDS_TX_FILTER_SIG_QUANT_DEPTH: integer;
      CCSDS_TX_FILTER_MODULATION_TYPE: integer;
      CCSDS_TX_FILTER_BITS_PER_SYMBOL: integer
    );
    port(
      clk_i: in std_logic;
      sym_val_i: in std_logic;
      sym_i_i: in std_logic_vector(CCSDS_TX_FILTER_BITS_PER_SYMBOL-1 downto 0);
      sym_q_i: in std_logic_vector(CCSDS_TX_FILTER_BITS_PER_SYMBOL-1 downto 0);
      rst_i: in std_logic;
      sam_i_o: out std_logic_vector(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-1 downto 0);
      sam_q_o: out std_logic_vector(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-1 downto 0);
      sam_val_o: out std_logic
    );
  end component;
  
  signal wire_sym_i: std_logic_vector(CCSDS_TX_PHYSICAL_BITS_PER_SYMBOL-1 downto 0);
  signal wire_sym_q: std_logic_vector(CCSDS_TX_PHYSICAL_BITS_PER_SYMBOL-1 downto 0);
  signal wire_sym_val: std_logic;
  signal wire_sam_val: std_logic;
  
  begin
  tx_mapper_0: ccsds_tx_mapper
    generic map(
      CCSDS_TX_MAPPER_BITS_PER_SYMBOL => CCSDS_TX_PHYSICAL_BITS_PER_SYMBOL,
      CCSDS_TX_MAPPER_MODULATION_TYPE => CCSDS_TX_PHYSICAL_MODULATION_TYPE,
      CCSDS_TX_MAPPER_DATA_BUS_SIZE => CCSDS_TX_PHYSICAL_DATA_BUS_SIZE
    )
    port map(
      clk_i => clk_sym_i,
      dat_i => dat_i,
      dat_val_i => dat_val_i,
      rst_i => rst_i,
      sym_i_o => wire_sym_i,
      sym_q_o => wire_sym_q,
      sym_val_o => wire_sym_val
    );
  tx_filter_0: ccsds_tx_filter
    generic map(
      CCSDS_TX_FILTER_OVERSAMPLING_RATIO => CCSDS_TX_PHYSICAL_OVERSAMPLING_RATIO,
      CCSDS_TX_FILTER_MODULATION_TYPE => CCSDS_TX_PHYSICAL_MODULATION_TYPE,
      CCSDS_TX_FILTER_SIG_QUANT_DEPTH => CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH,
      CCSDS_TX_FILTER_BITS_PER_SYMBOL => CCSDS_TX_PHYSICAL_BITS_PER_SYMBOL
    )
    port map(
      clk_i => clk_sam_i,
      sym_i_i => wire_sym_i,
      sym_q_i => wire_sym_q,
      sym_val_i => wire_sym_val,
      rst_i => rst_i,
      sam_val_o => wire_sam_val,
      sam_i_o => sam_i_o,
      sam_q_o => sam_q_o
    );
end rtl;
