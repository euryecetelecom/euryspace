-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_mapper_symbols_samples
---- Version: 1.0.0
---- Description:
---- Map symbols to their sample value depending on quantization depth
-------------------------------
---- Author(s):
---- Guillaume REMBERT
-------------------------------
---- Licence:
---- MIT
-------------------------------
---- Changes list:
---- 2016/11/18: initial release
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--=============================================================================
-- Entity declaration for ccsds_tx / unitary tx bits to symbols mapper inputs and outputs
--=============================================================================
entity ccsds_tx_mapper_symbols_samples is
  generic(
    constant CCSDS_TX_MAPPER_TARGET_SNR: real; -- in dB
    constant CCSDS_TX_MAPPER_BITS_PER_SYMBOL: integer; -- in bits
    constant CCSDS_TX_MAPPER_QUANTIZATION_DEPTH: integer -- in bits
  );
  port(
    -- inputs
    clk_i: in std_logic;
    rst_i: in std_logic;
    sym_i: in std_logic_vector(CCSDS_TX_MAPPER_BITS_PER_SYMBOL-1 downto 0);
    sym_val_i: in std_logic;
    -- outputs
    sam_val_o: out std_logic;
    sam_o: out std_logic_vector(CCSDS_TX_MAPPER_QUANTIZATION_DEPTH-1 downto 0)
  );
end ccsds_tx_mapper_symbols_samples;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture rtl of ccsds_tx_mapper_symbols_samples is
-- internal constants
  constant QUANTIZATION_SNR: real := 6.02*real(CCSDS_TX_MAPPER_QUANTIZATION_DEPTH);
  constant REQUIRED_SNR: real := real(2 + 2*CCSDS_TX_MAPPER_BITS_PER_SYMBOL) + CCSDS_TX_MAPPER_TARGET_SNR;
  constant SYMBOL_STEP: real := real(2**(CCSDS_TX_MAPPER_QUANTIZATION_DEPTH-CCSDS_TX_MAPPER_BITS_PER_SYMBOL)-1);
-- internal variable signals
  type samples_array is array(2**(CCSDS_TX_MAPPER_BITS_PER_SYMBOL)-1 downto 0) of std_logic_vector(CCSDS_TX_MAPPER_QUANTIZATION_DEPTH-1 downto 0);
  signal symbols_values: samples_array;
-- components instanciation and mapping
  begin
    SYMBOLS_VALUES_GENERATOR: for symbol_counter in 0 to 2**(CCSDS_TX_MAPPER_BITS_PER_SYMBOL-1)-1 generate
      symbols_values(2**(CCSDS_TX_MAPPER_BITS_PER_SYMBOL-1)+symbol_counter) <= std_logic_vector(to_signed(integer(real(symbol_counter+1) * SYMBOL_STEP),CCSDS_TX_MAPPER_QUANTIZATION_DEPTH));
      symbols_values(2**(CCSDS_TX_MAPPER_BITS_PER_SYMBOL-1)-symbol_counter-1) <= std_logic_vector(to_signed(integer(-(1.0) * real(symbol_counter+1) * SYMBOL_STEP),CCSDS_TX_MAPPER_QUANTIZATION_DEPTH));
    end generate SYMBOLS_VALUES_GENERATOR;
-- presynthesis checks
  -- Check SNR level requested is respected
  -- Signal SNR > crest factor modulated signal + SNR requested from configuration
  -- QAMCrestFactor, dB # 2 + 2 * NumberOfBitsPerSymbol
  -- QuantizedSignal SNR, dB # 6.02 * QuantizationDepth
     CHKMAPPERP0 : if (QUANTIZATION_SNR < REQUIRED_SNR) generate
      process
      begin
        report "ERROR: INCREASE QUANTIZATION DEPTH - QUANTIZATION SNR = " & real'image(QUANTIZATION_SNR) & " dB - REQUIRED SNR = " & real'image(REQUIRED_SNR) severity failure;
	      wait;
      end process;
    end generate CHKMAPPERP0;
-- internal processing
    --=============================================================================
    -- Begin of mapperp
    -- Map symbols to samples
    --=============================================================================
    -- read: rst_i, sym_i, sym_val_i
    -- write: sam_val_o, sam_o
    -- r/w:
    MAPPERP: process (clk_i)
    begin
      -- on each clock rising edge
      if rising_edge(clk_i) then
        -- reset signal received
        if (rst_i = '1') then
          sam_o <= (others => '0');
          sam_val_o <= '0';
        else
          if (sym_val_i = '1') then
            sam_o <= symbols_values(to_integer(unsigned(sym_i)));
            sam_val_o <= '1';
          else
            sam_val_o <= '0';
          end if;
        end if;
      end if;
    end process;
end rtl;
