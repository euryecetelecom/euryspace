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
---- 2016/10/19: rework
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;

--=============================================================================
-- Entity declaration for ccsds_tx / unitary tx external physical inputs and outputs
--=============================================================================
entity ccsds_tx is
  generic (
    CCSDS_TX_DATA_BUS_SIZE: integer;
    CCSDS_TX_PHYS_SIG_QUANT_DEPTH : integer
  );
  port(
    -- inputs
    clk_i: in std_logic; -- transmitted data clock
    dat_par_i: in std_logic_vector(CCSDS_TX_DATA_BUS_SIZE-1 downto 0); -- transmitted parallel data input
    dat_ser_i: in std_logic; -- transmitted serial data input
    dat_val_i: in std_logic; -- transmitted data valid input
    ena_i: in std_logic; -- system enable input
    in_sel_i: in std_logic; -- parallel / serial input selection
    rst_i: in std_logic; -- system reset input
    -- outputs
    buf_bit_ful_o: out std_logic; -- bits buffer status indicator
    buf_dat_ful_o: out std_logic; -- data buffer status indicator
    buf_fra_ful_o: out std_logic; -- frames buffer status indicator
    clk_o: out std_logic; -- output samples clock
    ena_o: out std_logic; -- enabled status indicator
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
      CCSDS_TX_MANAGER_DATA_BUS_SIZE : integer
    );
    port(
      clk_i: in std_logic;
      clk_o: out std_logic;
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
  component ccsds_tx_datalink_layer is
    generic(
      CCSDS_TX_DATALINK_DATA_BUS_SIZE : integer
    );
    port(
      clk_i: in std_logic;
      rst_i: in std_logic;
      dat_val_i: in std_logic;
      dat_i: in std_logic_vector(CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);
      dat_val_o: out std_logic;
      dat_o: out std_logic_vector(CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);
      buf_dat_ful_o: out std_logic;
      buf_fra_ful_o: out std_logic;
      buf_bit_ful_o: out std_logic
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
      sam_i_o: out std_logic_vector(CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH-1 downto 0);
      sam_q_o: out std_logic_vector(CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH-1 downto 0);
      dat_val_i: in std_logic;
      dat_i: in std_logic_vector(CCSDS_TX_PHYSICAL_DATA_BUS_SIZE-1 downto 0)
    );
  end component;

  signal wire_data_valid_m: std_logic;
  signal wire_data_valid_d: std_logic;
  signal wire_data_m: std_logic_vector(CCSDS_TX_DATA_BUS_SIZE-1 downto 0);
  signal wire_data_d: std_logic_vector(CCSDS_TX_DATA_BUS_SIZE-1 downto 0);
  signal wire_clk_m: std_logic;
  signal wire_rst_m: std_logic;

begin
  tx_manager_1: ccsds_tx_manager
    generic map(
      CCSDS_TX_MANAGER_DATA_BUS_SIZE => CCSDS_TX_DATA_BUS_SIZE
    )
    port map(
      clk_i => clk_i,
      clk_o => wire_clk_m,
      rst_i => rst_i,
      ena_i => ena_i,
      ena_o => ena_o,
      in_sel_i => in_sel_i,
      dat_val_i => dat_val_i,
      dat_par_i => dat_par_i,
      dat_ser_i => dat_ser_i,
      dat_val_o => wire_data_valid_m,
      dat_o => wire_data_m
    );
  tx_datalink_layer_1: ccsds_tx_datalink_layer
    generic map(
      CCSDS_TX_DATALINK_DATA_BUS_SIZE => CCSDS_TX_DATA_BUS_SIZE
    )
    port map(
      clk_i => wire_clk_m,
      rst_i => rst_i,
      dat_val_i => wire_data_valid_m,
      dat_i => wire_data_m,
      dat_val_o => wire_data_valid_d,
      dat_o => wire_data_d,
      buf_dat_ful_o => buf_dat_ful_o,
      buf_fra_ful_o => buf_fra_ful_o,
      buf_bit_ful_o => buf_bit_ful_o
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
      sam_i_o => sam_i_o,
      sam_q_o => sam_q_o,
      dat_val_i => wire_data_valid_d,
      dat_i => wire_data_d
    );
end structure;

