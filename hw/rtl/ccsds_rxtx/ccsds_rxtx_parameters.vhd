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
  constant RX_SYSTEM_AUTO_ENABLED: boolean := true;--Automatic activation of RX at startup
-- TX CONFIGURATION
  constant TX_SYSTEM_AUTO_ENABLED: boolean := true;--Automatic activation of TX at startup
  constant TX_SYSTEM_AUTO_EXTERNAL: boolean := false;--Automatic configuration of TX to use external clock and data
-- LAYERS CONFIGURATION
  -- APPLICATION LAYER
  -- PRESENTATION LAYER
  -- SESSION LAYER
  -- TRANSPORT LAYER
  -- NETWORK LAYER
  -- DATALINK LAYER
  -- PHYSICAL LAYER
  constant TX_PHYS_SIG_QUANT_DEPTH: integer := 8;-- DIGITAL PROCESSING QUANTIFICATION DEPTH IN BITS NUMBER
  constant RX_PHYS_SIG_QUANT_DEPTH: integer := 16;-- DIGITAL PROCESSING QUANTIFICATION DEPTH IN BITS NUMBER
end ccsds_rxtx_parameters;
