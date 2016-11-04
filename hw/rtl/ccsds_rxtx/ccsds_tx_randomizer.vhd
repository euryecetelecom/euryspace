-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_randomizer
---- Version: 1.0.0
---- Description:
---- Randomize input data with LFSR output sequence
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
-- Entity declaration for ccsds_tx / unitary tx randomizer inputs and outputs
--=============================================================================
entity ccsds_tx_randomizer is
  generic(
    constant CCSDS_TX_RANDOMIZER_DATA_BUS_SIZE: integer -- in bits
  );
  port(
    -- inputs
    clk_i: in std_logic;
    dat_i: in std_logic_vector(CCSDS_TX_RANDOMIZER_DATA_BUS_SIZE-1 downto 0);
    dat_val_i: in std_logic;
    rst_i: in std_logic;
    -- outputs
    dat_o: out std_logic_vector(CCSDS_TX_RANDOMIZER_DATA_BUS_SIZE-1 downto 0);
    dat_val_o: out std_logic
  );
end ccsds_tx_randomizer;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture structure of ccsds_tx_randomizer is
  component ccsds_rxtx_lfsr is
    generic(
      CCSDS_RXTX_LFSR_DATA_BUS_SIZE: integer
    );
    port(
      clk_i: in std_logic;
      rst_i: in std_logic;
      dat_o: out std_logic_vector(CCSDS_RXTX_LFSR_DATA_BUS_SIZE-1 downto 0);
      dat_val_o: out std_logic
    );
  end component;
-- internal constants
-- internal variable signals
  signal randomizer_sequence: std_logic_vector(CCSDS_TX_RANDOMIZER_DATA_BUS_SIZE-1 downto 0);
  signal wire_lfsr_valid: std_logic;
-- components instanciation and mapping
  begin
  tx_randomizer_lfsr: ccsds_rxtx_lfsr
    generic map(
      CCSDS_RXTX_LFSR_DATA_BUS_SIZE => CCSDS_TX_RANDOMIZER_DATA_BUS_SIZE
    )
    port map(
      clk_i => clk_i,
      rst_i => rst_i,
      dat_val_o => wire_lfsr_valid,
      dat_o => randomizer_sequence
    );
    
-- presynthesis checks
-- internal processing
    --=============================================================================
    -- Begin of randp
    -- Randomize data using LFSR register
    --=============================================================================
    -- read: rst_i, dat_val_i, dat_i, randomizer_sequence, wire_lfsr_valid
    -- write: dat_o, dat_val_o
    -- r/w: 
    RANDP: process (clk_i)
    begin
      -- on each clock rising edge
      if rising_edge(clk_i) then
        -- reset signal received
        if (rst_i = '1') then
          dat_o <= (others => '0');
          dat_val_o <= '0';
        else
          if (dat_val_i = '1') and (wire_lfsr_valid = '1') then
            dat_val_o <= '1';
            dat_o <= dat_i xor randomizer_sequence;
          else
            dat_val_o <= '0';
          end if;
        end if;
      end if;
    end process;
end structure;
