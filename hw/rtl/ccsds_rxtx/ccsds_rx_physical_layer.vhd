-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rx_physical_layer
---- Version: 1.0.0
---- Description:
---- TO BE DONE
-------------------------------
---- Author(s):
---- Guillaume REMBERT
-------------------------------
---- Licence:
---- MIT
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;

--=============================================================================
-- Entity declaration for ccsds_rx_physical_layer / unitary rx physical layer
--=============================================================================
entity ccsds_rx_physical_layer is
  generic (
    CCSDS_RX_PHYSICAL_DATA_BUS_SIZE: integer := 32;
    CCSDS_RX_PHYSICAL_SIG_QUANT_DEPTH : integer := 16
  );
  port(
    -- inputs
    clk_i: in std_logic;
    rst_i: in std_logic;
    sam_i_i: in std_logic_vector(CCSDS_RX_PHYSICAL_SIG_QUANT_DEPTH-1 downto 0);
    sam_q_i: in std_logic_vector(CCSDS_RX_PHYSICAL_SIG_QUANT_DEPTH-1 downto 0);
    -- outputs
    clk_o: out std_logic;
    dat_o: out std_logic_vector(CCSDS_RX_PHYSICAL_DATA_BUS_SIZE-1 downto 0)
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
    dat_o(CCSDS_RX_PHYSICAL_DATA_BUS_SIZE-1 downto CCSDS_RX_PHYSICAL_SIG_QUANT_DEPTH) <= sam_q_i;
    dat_o(CCSDS_RX_PHYSICAL_SIG_QUANT_DEPTH-1 downto 0) <= sam_i_i;
    clk_o <= clk_i;
    --=============================================================================
    -- Begin of physicalp
    -- TEST PURPOSES / DUMMY PHYSICAL LAYER PROCESS
    --=============================================================================
    -- read: clk_i
    -- write: 
    -- r/w: 
    PHYSICALP : process (clk_i)
      begin
      end process;
end rtl;
--=============================================================================
-- architecture end
--=============================================================================
