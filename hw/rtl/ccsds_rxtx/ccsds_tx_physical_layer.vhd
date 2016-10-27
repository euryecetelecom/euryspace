-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_physical_layer
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
---- Changes list:
---- 2015/11/17: initial release
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;

-- unitary tx physical layer
entity ccsds_tx_physical_layer is
  generic (
    CCSDS_TX_PHYSICAL_DATA_BUS_SIZE: integer := 32;
    CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH : integer := 16
  );
  port(
    -- inputs
    clk_i: in std_logic;
    dat_i: in std_logic_vector(CCSDS_TX_PHYSICAL_DATA_BUS_SIZE-1 downto 0);
    dat_val_i: in std_logic;
    rst_i: in std_logic;
    -- outputs
    clk_o: out std_logic;
    sam_i_o: out std_logic_vector(CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH-1 downto 0);
    sam_q_o: out std_logic_vector(CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH-1 downto 0)
  );
end ccsds_tx_physical_layer;

-- internal processing
architecture rtl of ccsds_tx_physical_layer is
  begin
  -- TEMPORARY NO CHANGE / DUMMY PHYSICAL LAYER
    PHYSICALP : process (clk_i)
      begin
      clk_o <= clk_i;
      if rising_edge(clk_i) then
        if (rst_i = '1') then
          sam_i_o <= (others => '0');
          sam_q_o <= (others => '0');
        else
          sam_i_o <= dat_i(CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH-1 downto 0);
          sam_q_o <= dat_i(CCSDS_TX_PHYSICAL_DATA_BUS_SIZE-1 downto CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH);
        end if;
      end if;
      end process;
end rtl;
