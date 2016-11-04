-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_coder
---- Version: 1.0.0
---- Description:
---- Implementation of standard CCSDS 131.0-B-2
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
-- Entity declaration for ccsds_tx / unitary tx coder inputs and outputs
--=============================================================================
entity ccsds_tx_coder is
  generic(
    constant CCSDS_TX_CODER_ASM_LENGTH: integer; -- Attached Synchronization Marker length / in Bytes
    constant CCSDS_TX_CODER_DATA_BUS_SIZE: integer -- in bits
  );
  port(
    -- inputs
    clk_i: in std_logic;
    dat_i: in std_logic_vector(CCSDS_TX_CODER_DATA_BUS_SIZE-1 downto 0);
    dat_val_i: in std_logic;
    rst_i: in std_logic;
    -- outputs
    dat_o: out std_logic_vector(CCSDS_TX_CODER_DATA_BUS_SIZE+CCSDS_TX_CODER_ASM_LENGTH*8-1 downto 0);
    dat_val_o: out std_logic
  );
end ccsds_tx_coder;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture structure of ccsds_tx_coder is
  component ccsds_tx_randomizer is
    generic(
      CCSDS_TX_RANDOMIZER_DATA_BUS_SIZE: integer
    );
    port(
      clk_i: in std_logic;
      dat_i: in std_logic_vector(CCSDS_TX_RANDOMIZER_DATA_BUS_SIZE-1 downto 0);
      dat_val_i: in std_logic;
      rst_i: in std_logic;
      dat_o: out std_logic_vector(CCSDS_TX_RANDOMIZER_DATA_BUS_SIZE-1 downto 0);
      dat_val_o: out std_logic
    );
  end component;
  component ccsds_tx_synchronizer is
    generic(
      CCSDS_TX_ASM_LENGTH: integer; -- Attached Synchronization Marker length / in Bytes
      CCSDS_TX_ASM_DATA_BUS_SIZE: integer -- in bits
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
  end component;
-- internal constants
-- internal variable signals
  signal wire_randomizer_dat_o: std_logic_vector(CCSDS_TX_CODER_DATA_BUS_SIZE-1 downto 0);
  signal wire_randomizer_dat_val_o: std_logic;
-- components instanciation and mapping
  begin
  tx_coder_randomizer_0: ccsds_tx_randomizer
    generic map(
      CCSDS_TX_RANDOMIZER_DATA_BUS_SIZE => CCSDS_TX_CODER_DATA_BUS_SIZE
    )
    port map(
      clk_i => clk_i,
      rst_i => rst_i,
      dat_val_i => dat_val_i,
      dat_i => dat_i,
      dat_val_o => wire_randomizer_dat_val_o,
      dat_o => wire_randomizer_dat_o
    );
  tx_coder_synchronizer_0: ccsds_tx_synchronizer
    generic map(
      CCSDS_TX_ASM_LENGTH => CCSDS_TX_CODER_ASM_LENGTH,
      CCSDS_TX_ASM_DATA_BUS_SIZE => CCSDS_TX_CODER_DATA_BUS_SIZE
    )
    port map(
      clk_i => clk_i,
      rst_i => rst_i,
      dat_val_i => wire_randomizer_dat_val_o,
      dat_i => wire_randomizer_dat_o,
      dat_val_o => dat_val_o,
      dat_o => dat_o
    );
-- presynthesis checks
-- internal processing
end structure;
