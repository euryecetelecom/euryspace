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
    CCSDS_TX_PHYS_SIG_QUANT_DEPTH : integer;
    CCSDS_TX_DATA_BUS_SIZE: integer
  );
  port(
    rst_i: in std_logic; -- system reset input
    ena_i: in std_logic; -- system enable input
    clk_i: in std_logic; -- transmitted data clock
    input_sel_i: in std_logic; -- parallel / serial input selection
    data_valid_i: in std_logic; -- transmitted data valid input
    data_par_i: in std_logic_vector(CCSDS_TX_DATA_BUS_SIZE-1 downto 0); -- transmitted parallel data input
    data_ser_i: in std_logic; -- transmitted serial data input
    clk_o: out std_logic; -- output samples clock
    i_samples_o: out std_logic_vector(CCSDS_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- in-phased parallel complex samples
    q_samples_o: out std_logic_vector(CCSDS_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- quadrature-phased parallel complex samples
    data_buffer_full_o: out std_logic; -- data buffer status indicator
    frames_buffer_full_o: out std_logic; -- frames buffer status indicator
    bits_buffer_full_o: out std_logic; -- bits buffer status indicator
    enabled_o: out std_logic -- enabled status indicator
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
      enabled_o: out std_logic;
      input_sel_i: in std_logic;
      data_par_i: in std_logic_vector(CCSDS_TX_MANAGER_DATA_BUS_SIZE-1 downto 0);
      data_ser_i: in std_logic;
      data_valid_i: in std_logic;
      data_valid_o: out std_logic;
      data_o: out std_logic_vector(CCSDS_TX_MANAGER_DATA_BUS_SIZE-1 downto 0)
    );
  end component;
  component ccsds_tx_datalink_layer is
    generic(
      CCSDS_TX_DATALINK_DATA_BUS_SIZE : integer
    );
    port(
      clk_i: in std_logic;
      rst_i: in std_logic;
      data_valid_i: in std_logic;
      data_i: in std_logic_vector(CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);
      data_valid_o: out std_logic;
      data_o: out std_logic_vector(CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);
      data_buffer_full_o: out std_logic;
      frames_buffer_full_o: out std_logic;
      bits_buffer_full_o: out std_logic
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
      i_samples_o: out std_logic_vector(CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH-1 downto 0);
      q_samples_o: out std_logic_vector(CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH-1 downto 0);
      data_valid_i: in std_logic;
      data_i: in std_logic_vector(CCSDS_TX_PHYSICAL_DATA_BUS_SIZE-1 downto 0)
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
      enabled_o => enabled_o,
      input_sel_i => input_sel_i,
      data_valid_i => data_valid_i,
      data_par_i => data_par_i,
      data_ser_i => data_ser_i,
      data_valid_o => wire_data_valid_m,
      data_o => wire_data_m
    );
  tx_datalink_layer_1: ccsds_tx_datalink_layer
    generic map(
      CCSDS_TX_DATALINK_DATA_BUS_SIZE => CCSDS_TX_DATA_BUS_SIZE
    )
    port map(
      clk_i => wire_clk_m,
      rst_i => rst_i,
      data_valid_i => wire_data_valid_m,
      data_i => wire_data_m,
      data_valid_o => wire_data_valid_d,
      data_o => wire_data_d,
      data_buffer_full_o => data_buffer_full_o,
      frames_buffer_full_o => frames_buffer_full_o,
      bits_buffer_full_o => bits_buffer_full_o
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
      i_samples_o => i_samples_o,
      q_samples_o => q_samples_o,
      data_valid_i => wire_data_valid_d,
      data_i => wire_data_d
    );
end structure;

