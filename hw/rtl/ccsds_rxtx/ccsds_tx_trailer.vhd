-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_trailer
---- Version: 1.0.0
---- Description:
---- TBD
-------------------------------
---- Author(s):
---- Guillaume REMBERT, guillaume.rembert@euryecetelecom.com
-------------------------------
---- Licence:
---- MIT
-------------------------------
---- Changes list:
---- 2016/02/28: initial release
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;

-- unitary tx trailer
entity ccsds_tx_trailer is
  generic(
    CCSDS_TX_TRAILER_DATA_BUS_SIZE : integer := 32; -- in bits
    CCSDS_TX_TRAILER_SIZE: integer := 2 -- in Bytes
  );
  port(
    clk_i: in std_logic;
    rst_i: in std_logic;
    data_i: in std_logic_vector(CCSDS_TX_TRAILER_DATA_BUS_SIZE-1 downto 0);
    data_valid_i: in std_logic;
    data_o: out std_logic_vector(CCSDS_TX_TRAILER_SIZE*8-1 downto 0);
    data_valid_o: out std_logic
  );
end ccsds_tx_trailer;


-- internal processing
architecture rtl of ccsds_tx_trailer is
  begin
  -- TEMPORARY NO CHANGE / DUMMY PHYSICAL LAYER
    TRAILERP : process (clk_i)
      begin
        data_o <= (others => '1');
        data_valid_o <= '1';
      end process;
end rtl;




