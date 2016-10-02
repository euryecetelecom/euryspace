-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rxtx_parameters
---- Version: 1.0.0
---- Description:
---- Project / design specific parameters
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

package ccsds_rxtx_parameters is
-- SYSTEM CONFIGURATION
  constant RXTX_SYSTEM_WB_DATA_BUS_SIZE: integer := 32;-- Wishbone slave data bus size
  constant RXTX_SYSTEM_WB_ADDR_BUS_SIZE: integer := 4;-- Wishbone slave address bus size
-- RX CONFIGURATION
  constant RX_SYSTEM_AUTO_ENABLED: std_logic := '1';--Automatic activation of RX at startup
  constant RX_SYSTEM_AUTO_EXTERNAL: std_logic := '0';--Automatic configuration of RX to use external clock and data
  constant RX_SYSTEM_DATA_BUS_SIZE: integer := 32;-- RX parallel input data bus size
  constant RX_SYSTEM_DATA_INPUT_TYPE: integer := 0;-- RX ext samples input type (0=serial i&q, 1=serial if, 2=parallel i&Q, 3=parallel if)
  constant RX_SYSTEM_DATA_OUTPUT_TYPE: integer := 0;-- RX ext data output type (0=serial, 1=parallel)
  constant RX_SYSTEM_DATA_DEFAULT_DATA: std_logic_vector(31 downto 0) := "01000000000000000000000000000010";
-- TX CONFIGURATION
  constant TX_SYSTEM_AUTO_ENABLED: std_logic := '1';--Automatic activation of TX at startup
  constant TX_SYSTEM_AUTO_EXTERNAL: std_logic := '0';--Automatic configuration of RX to use external clock and data
  constant TX_SYSTEM_DATA_BUS_SIZE: integer := 32;-- TX parallel input data bus size (bits)
  constant TX_SYSTEM_DATA_BUFFER_SIZE: integer := 256;--TX parallel input data words buffer size (words of TX_SYSTEM_DATA_BUS_SIZE bits)
  constant TX_SYSTEM_DATA_INPUT_TYPE: integer := 0;-- TX ext input data type (0=serial, 1=parallel)
  constant TX_SYSTEM_DATA_OUTPUT_TYPE: integer := 0;-- TX ext output samples type (0= serial i&q, 1=serial if, 2=parallel i&Q, 3=parallel if)  
  constant TX_SYSTEM_DATA_DEFAULT_DATA: std_logic_vector(31 downto 0) := (others => '1');
-- LAYERS CONFIGURATION
  -- APPLICATION LAYER
  -- PRESENTATION LAYER
  -- SESSION LAYER
  -- TRANSPORT LAYER
  -- NETWORK LAYER
  -- DATALINK LAYER
  constant TX_DATALINK_FRAME_LENGTH: integer := 32; -- datagram data size (Bytes)
  constant TX_DATALINK_HEADER_LENGTH: integer := 5; -- datagram header length (Bytes)
  constant TX_DATALINK_FOOTER_SIZE: integer := 2; -- datagram footer length (Bytes)
-- CCSDS HEADERS
  constant TX_DATALINK_CCSDS_HEADERS_ENABLE: boolean := true;
  constant TX_DATALINK_CCSDS_HEADERS_SPACECRAFT_ID: std_logic_vector(9 downto 0) := "1000000001"; 	-- INITIAL SPACECRAFT ID (SPECIFIC WORD / 10 BITS)
  constant TX_DATALINK_CCSDS_HEADERS_FRAME_INIT_NUM: std_logic_vector(18 downto 0) := (others => '0');	-- INITIAL FRAME NUMBER (INTEGER / MAX 19 BITS VALUE)
  constant TX_DATALINK_CCSDS_HEADERS_JAM_PAYLOAD: std_logic_vector(10 downto 0) := "11000000011"; 	-- JAM PAYLOAD (SPECIFIC WORD / 11 BITS)
  constant TX_DATALINK_CCSDS_ASM_SEQUENCE : std_logic_vector(31 downto 0) := "00011010110011111111110000011101"; -- TRAINING SEQUENCE (FOR SYNCHRONIZATION PURPOSES)
  -- PHYSICAL LAYER
  constant TX_PHYS_SIG_QUANT_DEPTH: integer := 16;-- DIGITAL PROCESSING QUANTIFICATION DEPTH IN BITS NUMBER
  constant RX_PHYS_SIG_QUANT_DEPTH: integer := 16;-- DIGITAL PROCESSING QUANTIFICATION DEPTH IN BITS NUMBER
	--constant TX_PHYSICAL_SIGNAL_MODULATION_MAPPING : integer := 2;	-- I&Q MODULATION MAPPING (2^PHYSICAL_MODULATION-PSK)
	--constant TX_PHYSICAL_SIGNAL_OSR : integer := 8; 		-- OSR VALUE
end ccsds_rxtx_parameters;
