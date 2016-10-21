-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rx_physical_layer
---- Version: 1.0.0
---- Description:
---- TO BE DONE
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

--=============================================================================
-- Entity declaration for ccsds_rx_physical_layer / unitary rx physical layer
--=============================================================================
entity ccsds_rx_physical_layer is
  generic (
    CCSDS_RX_PHYSICAL_SIG_QUANT_DEPTH : integer := 16;
    CCSDS_RX_PHYSICAL_DATA_BUS_SIZE: integer := 32
  );
  port(
    clk_i: in std_logic;
    clk_o: out std_logic;
    rst_i: in std_logic;
    i_samples_i: in std_logic_vector(CCSDS_RX_PHYSICAL_SIG_QUANT_DEPTH-1 downto 0);
    q_samples_i: in std_logic_vector(CCSDS_RX_PHYSICAL_SIG_QUANT_DEPTH-1 downto 0);
    data_o: out std_logic_vector(CCSDS_RX_PHYSICAL_DATA_BUS_SIZE-1 downto 0)
  );
end ccsds_rx_physical_layer;

--=============================================================================
-- architecture declaration / internal processing
--=============================================================================
architecture rtl of ccsds_rx_physical_layer is
--=============================================================================
-- architecture begin
--=============================================================================
  begin
    data_o(CCSDS_RX_PHYSICAL_DATA_BUS_SIZE-1 downto CCSDS_RX_PHYSICAL_SIG_QUANT_DEPTH) <= q_samples_i;
    data_o(CCSDS_RX_PHYSICAL_SIG_QUANT_DEPTH-1 downto 0) <= i_samples_i;
    clk_o <= clk_i;
    --=============================================================================
    -- Begin of physicalp
    -- TEST PURPOSES / DUMMY PHYSICAL LAYER PROCESS
    --=============================================================================
    -- read: clk_i
    -- write: 
    -- r/w: 
    PHYSICALP : process (clk_i, i_samples_i, q_samples_i)
      begin
      end process;
end rtl;
--=============================================================================
-- architecture end
--=============================================================================
