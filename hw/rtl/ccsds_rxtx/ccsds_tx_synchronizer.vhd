-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_synchronizer
---- Version: 1.0.0
---- Description:
---- Add an Attached Synchronization Marker to an input frame
-------------------------------
---- Author(s):
---- Guillaume REMBERT
-------------------------------
---- Licence:
---- MIT
-------------------------------
---- Changes list:
---- 2016/11/05: initial release
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;

--=============================================================================
-- Entity declaration for ccsds_tx / unitary tx synchronizer inputs and outputs
--=============================================================================
entity ccsds_tx_synchronizer is
  generic(
    constant CCSDS_TX_ASM_LENGTH: integer := 4; -- Attached Synchronization Marker length / in Bytes
    constant CCSDS_TX_ASM_PATTERN: std_logic_vector := "00011010110011111111110000011101"; -- ASM Pattern used
    constant CCSDS_TX_ASM_DATA_BUS_SIZE: integer -- in bits
  );
  port(
    -- inputs
    clk_i: in std_logic;
    dat_i: in std_logic_vector(CCSDS_TX_ASM_DATA_BUS_SIZE-1 downto 0);
    dat_val_i: in std_logic;
    rst_i: in std_logic;
    -- outputs
    dat_o: out std_logic_vector(CCSDS_TX_ASM_DATA_BUS_SIZE+CCSDS_TX_ASM_LENGTH*8-1 downto 0);
    dat_val_o: out std_logic
  );
end ccsds_tx_synchronizer;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture structure of ccsds_tx_synchronizer is

-- internal constants
-- internal variable signals
-- components instanciation and mapping
  begin
-- presynthesis checks
    CHKSYNCHRONIZERP0 : if ((CCSDS_TX_ASM_LENGTH*8) /= CCSDS_TX_ASM_PATTERN'length) generate
      process
      begin
        report "ERROR: SYNCHRONIZER ASM LENGTH IS DIFFERENT FROM PATTERN SIZE" severity failure;
        wait;
      end process;
    end generate CHKSYNCHRONIZERP0;
-- internal processing
    dat_o(CCSDS_TX_ASM_DATA_BUS_SIZE+CCSDS_TX_ASM_LENGTH*8-1 downto CCSDS_TX_ASM_DATA_BUS_SIZE) <= CCSDS_TX_ASM_PATTERN;
    dat_o(CCSDS_TX_ASM_DATA_BUS_SIZE-1 downto 0) <= dat_i;
    dat_val_o <= dat_val_i;
end structure;
