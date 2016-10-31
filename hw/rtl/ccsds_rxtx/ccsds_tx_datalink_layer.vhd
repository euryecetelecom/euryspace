-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_datalink_layer
---- Version: 1.0.0
---- Description:
---- TBD
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
  component ccsds_rxtx_buffer is
    generic(
      CCSDS_RXTX_BUFFER_DATA_BUS_SIZE : integer;
      CCSDS_RXTX_BUFFER_SIZE : integer
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
      dat_val_o: out std_logic;
      nxt_dat_o: out std_logic
    );
  end component;

-- internal constants
  constant CCSDS_TX_DATALINK_DATA_BUFFER_SIZE: integer := 2;--CCSDS_TX_DATALINK_DATA_LENGTH*8/CCSDS_TX_DATALINK_DATA_BUS_SIZE; --TO BE TESTED WITH SMALL PAYLOAD / --2 without frame stuffing
  constant CCSDS_TX_DATALINK_FRAMES_BUFFER_SIZE: integer := 16;
  constant CCSDS_TX_DATALINK_BITS_BUFFER_SIZE: integer := 4096;

-- interconnection signals
  signal wire_data_buffer_data: std_logic_vector(CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);
  signal wire_data_buffer_data_valid: std_logic;
  signal wire_data_buffer_empty: std_logic;
  signal wire_data_buffer_full: std_logic;
  signal wire_data_buffer_next_data: std_logic;
  signal wire_framer_data: std_logic_vector((CCSDS_TX_DATALINK_DATA_LENGTH+CCSDS_TX_DATALINK_HEADER_LENGTH+CCSDS_TX_DATALINK_FOOTER_LENGTH)*8-1 downto 0);
  signal wire_framer_data_valid: std_logic;
  signal wire_frames_buffer_empty: std_logic;
  signal wire_frames_buffer_full: std_logic;
  signal wire_frames_buffer_next_data: std_logic := '1';
  signal wire_frames_buffer_data: std_logic_vector((CCSDS_TX_DATALINK_DATA_LENGTH+CCSDS_TX_DATALINK_HEADER_LENGTH+CCSDS_TX_DATALINK_FOOTER_LENGTH)*8-1 downto 0);

-- components instanciation and mapping
  begin
  tx_datalink_data_buffer_0: ccsds_rxtx_buffer
    generic map(
      CCSDS_RXTX_BUFFER_DATA_BUS_SIZE => CCSDS_TX_DATALINK_DATA_BUS_SIZE,
      CCSDS_RXTX_BUFFER_SIZE => CCSDS_TX_DATALINK_DATA_BUFFER_SIZE
    )
    port map(
      clk_i => clk_i,
      rst_i => rst_i,
      dat_val_i => dat_val_i,
      dat_i => dat_i,
      dat_val_o => wire_data_buffer_data_valid,
      buf_emp_o => wire_data_buffer_empty,
      buf_ful_o => wire_data_buffer_full,
      nxt_dat_i => wire_data_buffer_next_data,
      dat_o => wire_data_buffer_data
    );
   
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
      dat_val_i => wire_data_buffer_data_valid,
      dat_i => wire_data_buffer_data,
      dat_val_o => wire_framer_data_valid,
      nxt_dat_o => wire_data_buffer_next_data,
      dat_o => wire_framer_data
    );

  tx_datalink_frames_buffer_0: ccsds_rxtx_buffer
    generic map(
      CCSDS_RXTX_BUFFER_DATA_BUS_SIZE => (CCSDS_TX_DATALINK_DATA_LENGTH+CCSDS_TX_DATALINK_HEADER_LENGTH+CCSDS_TX_DATALINK_FOOTER_LENGTH)*8,
      CCSDS_RXTX_BUFFER_SIZE => CCSDS_TX_DATALINK_FRAMES_BUFFER_SIZE
    )
    port map(
      clk_i => clk_i,
      rst_i => rst_i,
      dat_val_i => wire_framer_data_valid,
      dat_i => wire_framer_data,
      dat_val_o => dat_val_o,
      buf_emp_o => wire_frames_buffer_empty,
      buf_ful_o => wire_frames_buffer_full,
      nxt_dat_i => wire_frames_buffer_next_data,
      dat_o => wire_frames_buffer_data
    );

  buf_dat_ful_o <= wire_data_buffer_full;
  dat_o <= wire_frames_buffer_data(CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);

-- internal processing

--  constant TX_DATALINK_CCSDS_ASM_SEQUENCE : std_logic_vector(31 downto 0) := "00011010110011111111110000011101"; -- TRAINING SEQUENCE (FOR SYNCHRONIZATION PURPOSES)

end structure;
