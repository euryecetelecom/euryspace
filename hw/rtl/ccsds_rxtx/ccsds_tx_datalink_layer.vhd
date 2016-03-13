-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_datalink_layer
---- Version: 1.0.0
---- Description:
---- Receive and store datagram from data_par_i and data_ser_i when data_valid_i = '1'
-------------------------------
---- Author(s):
---- Guillaume REMBERT, guillaume.rembert@euryecetelecom.com
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

-- unitary tx datalink layer
entity ccsds_tx_datalink_layer is
  generic (
    CCSDS_TX_DATALINK_BUFFER_SIZE: integer := 256; -- number of words stored max
    CCSDS_TX_DATALINK_HEADER_SIZE: integer := 6;
    CCSDS_TX_DATALINK_TRAILER_SIZE: integer := 2;
    CCSDS_TX_DATALINK_DATA_SIZE: integer := 10;
    CCSDS_TX_DATALINK_DATA_BUS_SIZE: integer := 32
  );
  port(
    clk_i: in std_logic;
    clk_o: out std_logic;
    rst_i: in std_logic;
    data_valid_i: in std_logic;
    data_par_i: in std_logic_vector(CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);
    data_ser_i: in std_logic;
    data_valid_o: out std_logic;
    data_par_o: out std_logic_vector(CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);
    data_ser_o: out std_logic;
    buf_full_o: out std_logic
  );
end ccsds_tx_datalink_layer;

-- internal components
architecture structure of ccsds_tx_datalink_layer is
  component ccsds_rxtx_buffer is
    generic(
      CCSDS_RXTX_BUFFER_DATA_BUS_SIZE : integer;
      CCSDS_RXTX_BUFFER_SIZE : integer
    );
    port(
      clk_i: in std_logic;
      clk_o: out std_logic;
      rst_i: in std_logic;
      buf_empty_o: out std_logic;
      buf_full_o: out std_logic;
      next_data_i: in std_logic;
      data_i: in std_logic_vector(CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);
      data_valid_i: in std_logic;
      data_o: out std_logic_vector(CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);
      data_valid_o: out std_logic
    );
  end component;
  component ccsds_tx_framer is
    generic(
      CCSDS_TX_FRAMER_HEADER_SIZE : integer;
      CCSDS_TX_FRAMER_DATA_SIZE : integer;
      CCSDS_TX_FRAMER_TRAILER_SIZE : integer;
      CCSDS_TX_FRAMER_DATA_BUS_SIZE : integer
    );
    port(
      clk_i: in std_logic;
      clk_o: out std_logic;
      rst_i: in std_logic;
      buf_empty_i: in std_logic;
      next_data_o: out std_logic;
      data_i: in std_logic_vector(CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);
      data_valid_i: in std_logic;
      data_o: out std_logic_vector(CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);
      data_valid_o: out std_logic
    );
  end component;

-- interconnection signals
  signal wire_data_par_m: std_logic_vector(CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);
  signal wire_data_valid_m: std_logic;
  signal wire_clk_m: std_logic;
  signal wire_buf_empty_m: std_logic;
  signal wire_buf_full_m: std_logic;  
  signal wire_next_data_m: std_logic;

-- components instanciation and mapping
  begin
  tx_datalink_buffer_0: ccsds_rxtx_buffer
    generic map(
      CCSDS_RXTX_BUFFER_DATA_BUS_SIZE => CCSDS_TX_DATALINK_DATA_BUS_SIZE,
      CCSDS_RXTX_BUFFER_SIZE => CCSDS_TX_DATALINK_BUFFER_SIZE
    )
    port map(
      clk_i => clk_i,
      clk_o => wire_clk_m,
      rst_i => rst_i,
      data_valid_i => data_valid_i,
      data_i => data_par_i,
      data_valid_o => wire_data_valid_m,
      buf_empty_o => wire_buf_empty_m,
      buf_full_o => wire_buf_full_m,
      next_data_i => wire_next_data_m,
      data_o => wire_data_par_m
    );
    
  tx_datalink_framer_0: ccsds_tx_framer
    generic map(
      CCSDS_TX_FRAMER_HEADER_SIZE => CCSDS_TX_DATALINK_HEADER_SIZE,
      CCSDS_TX_FRAMER_DATA_SIZE => CCSDS_TX_DATALINK_DATA_SIZE,
      CCSDS_TX_FRAMER_TRAILER_SIZE => CCSDS_TX_DATALINK_TRAILER_SIZE,
      CCSDS_TX_FRAMER_DATA_BUS_SIZE => CCSDS_TX_DATALINK_DATA_BUS_SIZE
    )
    port map(
      clk_i => wire_clk_m,
      clk_o => clk_o,
      rst_i => rst_i,
      data_valid_i => wire_data_valid_m,
      data_i => wire_data_par_m,
      data_valid_o => data_valid_o,
      buf_empty_i => wire_buf_empty_m,
      next_data_o => wire_next_data_m,
      data_o => data_par_o
    );
    
  --tx_datalink_streamer_0
    --channel coding: read solomon+interleaver+codeur convolutif
    
    buf_full_o <= wire_buf_full_m;

-- TEMPORARY NO CHANGE / DUMMY DATALINKLAYER
--   DATALINKP : process (clk_i, data_par_i, data_ser_i)
--   begin
      
 --     data_par_o <= data_par_i;
 --     data_ser_o <= data_ser_i;
 --     data_valid_o <= data_valid_i;
 --     clk_o <= clk_i;
--   end process;
end structure;
