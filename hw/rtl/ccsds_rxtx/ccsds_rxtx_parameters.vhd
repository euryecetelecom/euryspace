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
---- 2016/10/20: rework / remove non-systems parameters / each component has his own parameters set at proper level
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;

package ccsds_rxtx_parameters is
-- SYSTEM CONFIGURATION
  constant RXTX_SYSTEM_WB_DATA_BUS_SIZE: integer := 32;-- Wishbone slave data bus size (bits)
  constant RXTX_SYSTEM_WB_ADDR_BUS_SIZE: integer := 4;-- Wishbone slave address bus size (bits)
-- RX CONFIGURATION
  constant RX_SYSTEM_AUTO_ENABLED: std_logic := '1';--Automatic activation of RX at startup
-- TX CONFIGURATION
  constant TX_SYSTEM_AUTO_ENABLED: std_logic := '1';--Automatic activation of TX at startup
  constant TX_SYSTEM_AUTO_EXTERNAL: std_logic := '0';--Automatic configuration of RX to use external clock and data
  constant TX_SYSTEM_DATA_BUFFER_SIZE: integer := 64;--TX parallel input data words buffer size (words of RXTX_SYSTEM_WB_DATA_BUS_SIZE bits)
-- LAYERS CONFIGURATION
  -- APPLICATION LAYER
  -- PRESENTATION LAYER
  -- SESSION LAYER
  -- TRANSPORT LAYER
  -- NETWORK LAYER
  -- DATALINK LAYER
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
