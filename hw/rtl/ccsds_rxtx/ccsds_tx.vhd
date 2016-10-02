-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx
---- Version: 1.0.0
---- Description:
---- TO BE DONE
-------------------------------
---- Author(s):
---- Guillaume Rembert
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

-- unitary tx external physical inputs and outputs
entity ccsds_tx is
  generic (
    CCSDS_TX_PHYS_SIG_QUANT_DEPTH : integer := 16;
    CCSDS_TX_DATA_OUTPUT_TYPE: integer := 0;
    CCSDS_TX_DATA_INPUT_TYPE: integer := 0;
    CCSDS_TX_DATA_BUFFER_SIZE: integer := 256;
    CCSDS_TX_DATA_BUS_SIZE: integer := 32
  );
  port(
    rst_i: in std_logic; -- system reset input
    ena_i: in std_logic; -- system enable input
    clk_i: in std_logic; -- transmitted data clock
    data_valid_i: in std_logic; -- transmitted data valid input
    data_par_i: in std_logic_vector(CCSDS_TX_DATA_BUS_SIZE-1 downto 0); -- transmitted parallel data input
    data_ser_i: in std_logic; -- transmitted serial data input
    clk_o: out std_logic; -- output samples clock
    samples_valid_o: out std_logic; 
    i_samples_par_o: out std_logic_vector(CCSDS_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
    q_samples_par_o: out std_logic_vector(CCSDS_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
    if_samples_par_o: out std_logic_vector(CCSDS_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
    i_samples_ser_o: out std_logic;
    q_samples_ser_o: out std_logic;
    if_samples_ser_o: out std_logic;
    buf_full_o: out std_logic
  );
end ccsds_tx;

architecture structure of ccsds_tx is
  component ccsds_tx_datalink_layer is
    generic(
      CCSDS_TX_DATALINK_DATA_BUS_SIZE : integer;
      CCSDS_TX_DATALINK_BUFFER_SIZE : integer
    );
    port(
      clk_i: in std_logic;
      clk_o: out std_logic;
      rst_i: in std_logic;
      data_valid_i: in std_logic;
      data_par_i: in std_logic_vector(CCSDS_TX_DATA_BUS_SIZE-1 downto 0);
      data_ser_i: in std_logic;
      data_valid_o: out std_logic;
      data_par_o: out std_logic_vector(CCSDS_TX_DATA_BUS_SIZE-1 downto 0);
      data_ser_o: out std_logic;
      buf_full_o: out std_logic
    );
  end component;
  component ccsds_tx_physical_layer is
    generic(
      CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH : integer;
      CCSDS_TX_PHYSICAL_DATA_BUS_SIZE : integer
    );
    port(
      clk_i: in std_logic;
      clk_o: out std_logic;
      rst_i: in std_logic;
      samples_valid_o: out std_logic;
      i_samples_par_o: out std_logic_vector(CCSDS_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      q_samples_par_o: out std_logic_vector(CCSDS_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      if_samples_par_o: out std_logic_vector(CCSDS_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      i_samples_ser_o: out std_logic;
      q_samples_ser_o: out std_logic;
      if_samples_ser_o: out std_logic;
      data_valid_i: in std_logic;
      data_par_i: in std_logic_vector(CCSDS_TX_DATA_BUS_SIZE-1 downto 0);
      data_ser_i: in std_logic
    );
  end component;

  signal wire_data_valid_m: std_logic;
  signal wire_data_par_m: std_logic_vector(CCSDS_TX_DATA_BUS_SIZE-1 downto 0);
  signal wire_data_ser_m: std_logic;
  signal wire_clk_i: std_logic;
  signal wire_clk_m: std_logic;

begin
  tx_datalink_layer_1: ccsds_tx_datalink_layer
    generic map(
      CCSDS_TX_DATALINK_DATA_BUS_SIZE => CCSDS_TX_DATA_BUS_SIZE,
      CCSDS_TX_DATALINK_BUFFER_SIZE => CCSDS_TX_DATA_BUFFER_SIZE
    )
    port map(
      clk_i => wire_clk_i,
      clk_o => wire_clk_m,
      rst_i => rst_i,
      data_valid_i => data_valid_i,
      data_par_i => data_par_i,
      data_ser_i => data_ser_i,
      data_valid_o => wire_data_valid_m,
      data_par_o => wire_data_par_m,
      data_ser_o => wire_data_ser_m,
      buf_full_o => buf_full_o
    );
  tx_physical_layer_1: ccsds_tx_physical_layer
    generic map(
      CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH => CCSDS_TX_PHYS_SIG_QUANT_DEPTH,
      CCSDS_TX_PHYSICAL_DATA_BUS_SIZE => CCSDS_TX_DATA_BUS_SIZE
    )
    port map(
      clk_i => wire_clk_m,
      clk_o => clk_o,
      rst_i => rst_i,
      samples_valid_o => samples_valid_o,
      i_samples_par_o => i_samples_par_o,
      q_samples_par_o => q_samples_par_o,
      if_samples_par_o => if_samples_par_o,
      i_samples_ser_o => i_samples_ser_o,
      q_samples_ser_o => q_samples_ser_o,
      if_samples_ser_o => if_samples_ser_o,
      data_valid_i => wire_data_valid_m,
      data_par_i => wire_data_par_m,
      data_ser_i => wire_data_ser_m
    );
    --=============================================================================
    -- Begin of enablep
    -- Enable/disable clk forwarding
    --=============================================================================
    -- read: clk_i, ena_i
    -- write: wire_clk_i
    -- r/w: 
    ENABLEP : process (clk_i, ena_i)
      begin
        if (ena_i = '1') then
          wire_clk_i <= clk_i;
        else
          wire_clk_i <= '0';
        end if;
      end process;
end structure;

