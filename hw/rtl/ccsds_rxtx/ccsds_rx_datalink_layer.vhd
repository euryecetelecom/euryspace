-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rx_datalink_layer
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

-- unitary rx datalink layer
entity ccsds_rx_datalink_layer is
  generic (
    CCSDS_RX_DATALINK_DATA_BUS_SIZE: integer := 32
  );
  port(
    clk_i: in std_logic;
    clk_o: out std_logic;
    rst_i: in std_logic;
    data_par_i: in std_logic_vector(CCSDS_RX_DATALINK_DATA_BUS_SIZE-1 downto 0);
    data_ser_i: in std_logic;
    data_par_o: out std_logic_vector(CCSDS_RX_DATALINK_DATA_BUS_SIZE-1 downto 0);
    data_ser_o: out std_logic
  );
end ccsds_rx_datalink_layer;

-- internal processing
architecture rtl of ccsds_rx_datalink_layer is
  begin
-- TEMPORARY NO CHANGE / DUMMY LINKLAYER
    DATALINKP : process (clk_i, data_par_i, data_ser_i)
    begin
      data_par_o <= data_par_i;
      data_ser_o <= data_ser_i;
      clk_o <= clk_i;
    end process;
end rtl;
