-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_header
---- Version: 1.0.0
---- Description:
---- TBD
-------------------------------
---- Author(s):
---- Guillaume REMBERT
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

-- unitary tx header
entity ccsds_tx_header is
  generic(
    CCSDS_TX_HEADER_SIZE: integer := 6 -- in Bytes
--    CCSDS_TX_HEADER_TFVN_LENGTH: integer := 19;	-- TRANSFER FRAME VERSION NUMBER LENGTH (BITS)
--    CCSDS_TX_HEADER_TFVN_DEFAULT_VALUE: std_logic_vector := "0000000000000000000"; -- TRANSFER FRAME VERSION NUMBER DEFAULT VALUE (TFVN_LENGTH SIZE)
--    CCSDS_TX_HEADER_SCID_LENGTH: integer := 10; -- SPACECRAFT IDENTIFIER LENGTH (BITS)
--    CCSDS_TX_HEADER_SCID_DEFAULT_VALUE: std_logic_vector := "1111111111"; -- SPACECRAFT IDENTIFIER DEFAULT VALUE (SCID_LENGTH SIZE)
--    CCSDS_TX_HEADER_VCID_LENGTH: integer := 11; -- VIRTUAL CHANNEL IDENTIFIER LENGTH (BITS)
--    CCSDS_TX_HEADER_VCID_DEFAULT_VALUE	: std_logic_vector	:= "00000000000" -- VIRTUAL CHANNEL IDENTIFIER DEFAULT VALUE (VCID_LENGTH SIZE)
  );
  port(
    clk_i: in std_logic;
    rst_i: in std_logic;
    nxt_i: in std_logic;
    data_o: out std_logic_vector(CCSDS_TX_HEADER_SIZE*8-1 downto 0);
    data_valid_o: out std_logic
  );
end ccsds_tx_header;

-- internal processing
architecture rtl of ccsds_tx_header is
  begin
  -- TEMPORARY NO CHANGE / DUMMY PHYSICAL LAYER
    HEADERP : process (clk_i)
      begin
        data_o <= (others => '1');
        data_valid_o <= '1';
      end process;
end rtl;



