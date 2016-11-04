-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_datalink_layer
---- Version: 1.0.0
---- Description:
---- TM (TeleMetry) Space Data Link Protocol
-------------------------------
---- Author(s):
---- Guillaume REMBERT
-------------------------------
---- Licence:
---- MIT
-------------------------------
---- Changes list:
---- 2015/11/17: initial release
---- 2016/10/21: rework based on TX final architecture
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

--=============================================================================
-- Entity declaration for ccsds_tx / unitary tx datalink layer inputs and outputs
--=============================================================================
entity ccsds_tx_datalink_layer is
  generic (
    constant CCSDS_TX_DATALINK_ASM_LENGTH: integer := 4; -- Attached Synchronization Marker length / in Bytes
    constant CCSDS_TX_DATALINK_DATA_BUS_SIZE: integer := 32; -- in bits
    constant CCSDS_TX_DATALINK_DATA_LENGTH: integer := 24; -- datagram data size (Bytes) / (has to be a multiple of CCSDS_TX_DATALINK_DATA_BUS_SIZE)
    constant CCSDS_TX_DATALINK_FOOTER_LENGTH: integer := 2; -- datagram footer length (Bytes)
    constant CCSDS_TX_DATALINK_HEADER_LENGTH: integer := 6 -- datagram header length (Bytes)
  );
  port(
    -- inputs
    clk_i: in std_logic;
    dat_i: in std_logic_vector(CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);
    dat_val_i: in std_logic;
    rst_i: in std_logic;
    -- outputs
    buf_bit_ful_o: out std_logic;
    buf_dat_ful_o: out std_logic;
    buf_fra_ful_o: out std_logic;
    dat_o: out std_logic_vector(CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);
    dat_val_o: out std_logic
  );
end ccsds_tx_datalink_layer;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture structure of ccsds_tx_datalink_layer is
  component ccsds_tx_framer is
    generic(
      CCSDS_TX_FRAMER_DATA_BUS_SIZE : integer;
      CCSDS_TX_FRAMER_DATA_LENGTH : integer;
      CCSDS_TX_FRAMER_FOOTER_LENGTH : integer;
      CCSDS_TX_FRAMER_HEADER_LENGTH : integer
    );
    port(
      clk_i: in std_logic;
      rst_i: in std_logic;
      dat_i: in std_logic_vector(CCSDS_TX_FRAMER_DATA_BUS_SIZE-1 downto 0);
      dat_val_i: in std_logic;
      dat_o: out std_logic_vector((CCSDS_TX_FRAMER_DATA_LENGTH+CCSDS_TX_FRAMER_HEADER_LENGTH+CCSDS_TX_FRAMER_FOOTER_LENGTH)*8-1 downto 0);
      dat_val_o: out std_logic
    );
  end component;
  component ccsds_tx_coder is
    generic(
      CCSDS_TX_CODER_DATA_BUS_SIZE : integer;
      CCSDS_TX_CODER_ASM_LENGTH: integer
    );
    port(
      clk_i: in std_logic;
      dat_i: in std_logic_vector(CCSDS_TX_CODER_DATA_BUS_SIZE-1 downto 0);
      dat_val_i: in std_logic;
      rst_i: in std_logic;
      dat_o: out std_logic_vector(CCSDS_TX_CODER_DATA_BUS_SIZE+CCSDS_TX_CODER_ASM_LENGTH*8-1 downto 0);
      dat_val_o: out std_logic
    );
  end component;

-- internal constants

-- interconnection signals
  signal wire_framer_data: std_logic_vector((CCSDS_TX_DATALINK_DATA_LENGTH+CCSDS_TX_DATALINK_HEADER_LENGTH+CCSDS_TX_DATALINK_FOOTER_LENGTH)*8-1 downto 0);
  signal wire_framer_data_valid: std_logic;
  signal wire_coder_data: std_logic_vector((CCSDS_TX_DATALINK_DATA_LENGTH+CCSDS_TX_DATALINK_HEADER_LENGTH+CCSDS_TX_DATALINK_FOOTER_LENGTH+CCSDS_TX_DATALINK_ASM_LENGTH)*8-1 downto 0);
  signal wire_coder_data_valid: std_logic;

-- components instanciation and mapping
  begin

  tx_datalink_framer_0: ccsds_tx_framer
    generic map(
      CCSDS_TX_FRAMER_HEADER_LENGTH => CCSDS_TX_DATALINK_HEADER_LENGTH,
      CCSDS_TX_FRAMER_DATA_LENGTH => CCSDS_TX_DATALINK_DATA_LENGTH,
      CCSDS_TX_FRAMER_FOOTER_LENGTH => CCSDS_TX_DATALINK_FOOTER_LENGTH,
      CCSDS_TX_FRAMER_DATA_BUS_SIZE => CCSDS_TX_DATALINK_DATA_BUS_SIZE
    )
    port map(
      clk_i => clk_i,
      rst_i => rst_i,
      dat_val_i => dat_val_i,
      dat_i => dat_i,
      dat_val_o => wire_framer_data_valid,
      dat_o => wire_framer_data
    );
  tx_datalink_coder_0: ccsds_tx_coder
    generic map(
      CCSDS_TX_CODER_ASM_LENGTH => CCSDS_TX_DATALINK_ASM_LENGTH,
      CCSDS_TX_CODER_DATA_BUS_SIZE => (CCSDS_TX_DATALINK_DATA_LENGTH+CCSDS_TX_DATALINK_HEADER_LENGTH+CCSDS_TX_DATALINK_FOOTER_LENGTH)*8
    )
    port map(
      clk_i => clk_i,
      dat_i => wire_framer_data,
      dat_val_i => wire_framer_data_valid,
      rst_i => rst_i,
      dat_val_o => wire_coder_data_valid,
      dat_o => wire_coder_data
    );
    
  buf_dat_ful_o <= '0';
  dat_val_o <= wire_coder_data_valid;
  dat_o <= wire_coder_data(CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);
-- internal processing

end structure;
