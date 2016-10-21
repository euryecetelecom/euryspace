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
--FIXME: Framer is too slow vs external input data from TX (input perfs = 1 bit / clk vs CRC perfs = (HEADER/NbDataBitsByFrame + 1) bits / clk)

-- libraries used
library ieee;
use ieee.std_logic_1164.all;

--=============================================================================
-- Entity declaration for ccsds_tx / unitary tx datalink layer inputs and outputs
--=============================================================================
entity ccsds_tx_datalink_layer is
  generic (
    CCSDS_TX_DATALINK_DATA_BUFFER_SIZE: integer := 64;
    CCSDS_TX_DATALINK_FRAMES_BUFFER_SIZE: integer := 16;
    CCSDS_TX_DATALINK_BITS_BUFFER_SIZE: integer := 4096;
    CCSDS_TX_DATALINK_HEADER_LENGTH: integer := 6; -- datagram header length (Bytes)
    CCSDS_TX_DATALINK_FOOTER_LENGTH: integer := 2; -- datagram footer length (Bytes)
    CCSDS_TX_DATALINK_DATA_LENGTH: integer := 120; -- datagram data size (Bytes) / (has to be a multiple of CCSDS_TX_DATALINK_DATA_BUS_SIZE)
    CCSDS_TX_DATALINK_DATA_BUS_SIZE: integer := 32
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
  component ccsds_tx_framer is
    generic(
      CCSDS_TX_FRAMER_HEADER_LENGTH : integer;
      CCSDS_TX_FRAMER_DATA_LENGTH : integer;
      CCSDS_TX_FRAMER_FOOTER_LENGTH : integer;
      CCSDS_TX_FRAMER_DATA_BUS_SIZE : integer
    );
    port(
      clk_i: in std_logic;
      clk_o: out std_logic;
      rst_i: in std_logic;
      next_data_o: out std_logic;
      data_i: in std_logic_vector(CCSDS_TX_FRAMER_DATA_BUS_SIZE-1 downto 0);
      data_valid_i: in std_logic;
      data_o: out std_logic_vector((CCSDS_TX_FRAMER_DATA_LENGTH+CCSDS_TX_FRAMER_HEADER_LENGTH+CCSDS_TX_FRAMER_FOOTER_LENGTH)*8-1 downto 0);
      data_valid_o: out std_logic
    );
  end component;

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
      data_valid_i => data_valid_i,
      data_i => data_i,
      data_valid_o => wire_data_buffer_data_valid,
      buffer_empty_o => wire_data_buffer_empty,
      buffer_full_o => wire_data_buffer_full,
      next_data_i => wire_data_buffer_next_data,
      data_o => wire_data_buffer_data
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
      data_valid_i => wire_data_buffer_data_valid,
      data_i => wire_data_buffer_data,
      data_valid_o => wire_framer_data_valid,
      next_data_o => wire_data_buffer_next_data,
      data_o => wire_framer_data
    );

  tx_datalink_frames_buffer_0: ccsds_rxtx_buffer
    generic map(
      CCSDS_RXTX_BUFFER_DATA_BUS_SIZE => (CCSDS_TX_DATALINK_DATA_LENGTH+CCSDS_TX_DATALINK_HEADER_LENGTH+CCSDS_TX_DATALINK_FOOTER_LENGTH)*8,
      CCSDS_RXTX_BUFFER_SIZE => CCSDS_TX_DATALINK_FRAMES_BUFFER_SIZE
    )
    port map(
      clk_i => clk_i,
      rst_i => rst_i,
      data_valid_i => wire_framer_data_valid,
      data_i => wire_framer_data,
      data_valid_o => data_valid_o,
      buffer_empty_o => wire_frames_buffer_empty,
      buffer_full_o => wire_frames_buffer_full,
      next_data_i => wire_frames_buffer_next_data,
      data_o => wire_frames_buffer_data
    );

  data_buffer_full_o <= wire_data_buffer_full;
  data_o <= wire_frames_buffer_data(CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);

-- internal processing
    
    --=============================================================================
    -- Begin of datalinkp
    -- DESCRIPTION TBD
    --=============================================================================
    -- read: 
    -- write: 
    -- r/w: 
    DATALINKP : process (clk_i)
    begin
    end process;
end structure;
