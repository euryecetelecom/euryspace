-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rx_datalink_layer
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

-- unitary rx datalink layer
entity ccsds_rx_datalink_layer is
  generic (
    CCSDS_RX_DATALINK_DATA_BUS_SIZE: integer := 32
  );
  port(
    -- inputs
    clk_i: in std_logic;
    dat_i: in std_logic_vector(CCSDS_RX_DATALINK_DATA_BUS_SIZE-1 downto 0);
    rst_i: in std_logic;
    -- outputs
    buf_bit_ful_o: out std_logic;
    buf_dat_ful_o: out std_logic;
    buf_fra_ful_o: out std_logic;
    dat_o: out std_logic_vector(CCSDS_RX_DATALINK_DATA_BUS_SIZE-1 downto 0)
  );
end ccsds_rx_datalink_layer;

-- internal processing
architecture rtl of ccsds_rx_datalink_layer is
-- TEMPORARY NO CHANGE / DUMMY LINKLAYER

  begin
    dat_o <= dat_i;
    buf_dat_ful_o <= '0';
    buf_fra_ful_o <= '0';
    buf_bit_ful_o <= '0';
  
    DATALINKP : process (clk_i, dat_i)
    begin
    end process;
end rtl;
