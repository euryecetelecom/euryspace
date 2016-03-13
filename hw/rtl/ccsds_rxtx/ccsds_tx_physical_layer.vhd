-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_physical_layer
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

-- unitary tx physical layer
entity ccsds_tx_physical_layer is
  generic (
    CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH : integer := 16;
    CCSDS_TX_PHYSICAL_DATA_BUS_SIZE: integer := 32
  );
  port(
    clk_i: in std_logic;
    clk_o: out std_logic;
    rst_i: in std_logic;
    samples_valid_o: out std_logic;
    i_samples_par_o: out std_logic_vector(CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH-1 downto 0);
    q_samples_par_o: out std_logic_vector(CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH-1 downto 0);
    if_samples_par_o: out std_logic_vector(CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH-1 downto 0);
    i_samples_ser_o: out std_logic;
    q_samples_ser_o: out std_logic;
    if_samples_ser_o: out std_logic;
    data_valid_i: in std_logic;
    data_par_i: in std_logic_vector(CCSDS_TX_PHYSICAL_DATA_BUS_SIZE-1 downto 0);
    data_ser_i: in std_logic
  );
end ccsds_tx_physical_layer;

-- internal processing
architecture rtl of ccsds_tx_physical_layer is
  begin
  -- TEMPORARY NO CHANGE / DUMMY PHYSICAL LAYER
    PHYSICALP : process (clk_i, data_par_i, data_ser_i)
      begin
        clk_o <= clk_i;
        samples_valid_o <= data_valid_i;
        i_samples_par_o <= data_par_i(CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH-1 downto 0);
        q_samples_par_o <= data_par_i(CCSDS_TX_PHYSICAL_DATA_BUS_SIZE-1 downto CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH);
        if_samples_par_o <= data_par_i(CCSDS_TX_PHYSICAL_DATA_BUS_SIZE-5 downto CCSDS_TX_PHYSICAL_SIG_QUANT_DEPTH-4);
        if_samples_ser_o <= data_par_i(0);
        i_samples_ser_o <= data_par_i(0);
        q_samples_ser_o <= data_par_i(0);
      end process;
end rtl;
