-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_mapper
---- Version: 1.0.0
---- Description:
---- Implementation of standard CCSDS 401.0-B
-------------------------------
---- Author(s):
---- Guillaume REMBERT
-------------------------------
---- Licence:
---- MIT
-------------------------------
---- Changes list:
---- 2016/11/05: initial release
---- 2016/11/17: added differential coder
-------------------------------
--TODO: Gray coder

-- libraries used
library ieee;
use ieee.std_logic_1164.all;

--=============================================================================
-- Entity declaration for ccsds_tx / unitary tx mapper inputs and outputs
--=============================================================================
entity ccsds_tx_mapper is
  generic(
    constant CCSDS_TX_MAPPER_BITS_PER_SYMBOL: integer := 1; -- For QAM - 1 bit/symbol <=> QPSK/4-QAM - 2 bits/symbol <=> 16-QAM - 3 bits/symbol <=> 64-QAM - ... - N bits/symbol <=> 2^(N*2)-QAM
    constant CCSDS_TX_MAPPER_GRAY_CODER: std_logic := '1'; -- Gray coder activation
    constant CCSDS_TX_MAPPER_MODULATION_TYPE: integer := 1; -- 1=QPSK/QAM - 2=BPSK
    constant CCSDS_TX_MAPPER_DATA_BUS_SIZE: integer -- in bits
  );
  port(
    -- inputs
    clk_i: in std_logic;
    dat_i: in std_logic_vector(CCSDS_TX_MAPPER_DATA_BUS_SIZE-1 downto 0);
    dat_val_i: in std_logic;
    rst_i: in std_logic;
    -- outputs
    sym_val_o: out std_logic;
    sym_i_o: out std_logic_vector(CCSDS_TX_MAPPER_BITS_PER_SYMBOL-1 downto 0);
    sym_q_o: out std_logic_vector(CCSDS_TX_MAPPER_BITS_PER_SYMBOL-1 downto 0)
  );
end ccsds_tx_mapper;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture structure of ccsds_tx_mapper is
-- internal constants
  constant MAPPER_SYMBOL_NUMBER_PER_CHANNEL: integer := CCSDS_TX_MAPPER_DATA_BUS_SIZE*CCSDS_TX_MAPPER_MODULATION_TYPE/(2*CCSDS_TX_MAPPER_BITS_PER_SYMBOL);
-- internal variable signals
-- components instanciation and mapping
  begin
-- presynthesis checks
     CHKMAPPERP0 : if (CCSDS_TX_MAPPER_DATA_BUS_SIZE mod (CCSDS_TX_MAPPER_BITS_PER_SYMBOL*2*CCSDS_TX_MAPPER_MODULATION_TYPE) /= 0) generate
      process
      begin
        report "ERROR: DATA BUS SIZE HAS TO BE A MULTIPLE OF 2*BITS PER SYMBOLS (EXCEPT FOR BPSK MODULATION)" severity failure;
	      wait;
      end process;
    end generate CHKMAPPERP0;
     CHKMAPPERP1: if (CCSDS_TX_MAPPER_BITS_PER_SYMBOL /= 1) and (CCSDS_TX_MAPPER_MODULATION_TYPE = 2) generate
      process
      begin
        report "ERROR: BPSK MODULATION REQUIRES 1 BIT PER SYMBOL" severity failure;
	      wait;
      end process;
    end generate CHKMAPPERP1;
     CHKMAPPERP2 : if (CCSDS_TX_MAPPER_MODULATION_TYPE /= 1) and (CCSDS_TX_MAPPER_MODULATION_TYPE /= 2) generate
      process
      begin
        report "ERROR: UNKNOWN MODULATION TYPE - 1=QPSK/QAM / 2=BPSK" severity failure;
	      wait;
      end process;
    end generate CHKMAPPERP2;
-- internal processing
    --=============================================================================
    -- Begin of mapperp
    -- Map bits to symbols
    --=============================================================================
    -- read: rst_i, dat_i, dat_val_i
    -- write: sym_i_o, sym_q_o
    -- r/w:
    MAPPERP: process (clk_i)
    variable symbol_counter: integer range 1 to MAPPER_SYMBOL_NUMBER_PER_CHANNEL := MAPPER_SYMBOL_NUMBER_PER_CHANNEL;
    begin
      -- on each clock rising edge
      if rising_edge(clk_i) then
        -- reset signal received
        if (rst_i = '1') then
          sym_i_o <= (others => '0');
          sym_q_o <= (others => '0');
          symbol_counter := MAPPER_SYMBOL_NUMBER_PER_CHANNEL;
          sym_val_o <= '0';
        else
          if (dat_val_i = '1') then
            sym_val_o <= '1';
            -- BPSK mapping
            if (CCSDS_TX_MAPPER_BITS_PER_SYMBOL = 1) and (CCSDS_TX_MAPPER_MODULATION_TYPE = 2) then
              sym_q_o(0) <= '0';
              sym_i_o(0) <= dat_i(symbol_counter-1);
            -- QPSK/QAM mapping
            else
              sym_i_o <= dat_i(symbol_counter*CCSDS_TX_MAPPER_BITS_PER_SYMBOL*2-1 downto symbol_counter*2*CCSDS_TX_MAPPER_BITS_PER_SYMBOL-CCSDS_TX_MAPPER_BITS_PER_SYMBOL);
              sym_q_o <= dat_i(symbol_counter*2*CCSDS_TX_MAPPER_BITS_PER_SYMBOL-CCSDS_TX_MAPPER_BITS_PER_SYMBOL-1 downto symbol_counter*2*CCSDS_TX_MAPPER_BITS_PER_SYMBOL-2*CCSDS_TX_MAPPER_BITS_PER_SYMBOL);
            end if;
            if (symbol_counter = 1) then
              symbol_counter := MAPPER_SYMBOL_NUMBER_PER_CHANNEL;
            else
              symbol_counter := symbol_counter - 1;
            end if;
          else
            sym_val_o <= '0';
          end if;
        end if;
      end if;
    end process;
end structure;
