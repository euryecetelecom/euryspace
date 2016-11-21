---- Design Name: ccsds_tx_coder_differential
---- Version: 1.0.0
---- Description:
---- Word by word differential coder
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

--=============================================================================
-- Entity declaration for ccsds_tx / unitary tx differential coder inputs and outputs
--=============================================================================
entity ccsds_tx_coder_differential is
  generic(
    constant CCSDS_TX_CODER_DIFF_BITS_PER_CODEWORD: integer;
    constant CCSDS_TX_CODER_DIFF_DATA_BUS_SIZE: integer -- in bits
  );
  port(
    -- inputs
    clk_i: in std_logic;
    dat_i: in std_logic_vector(CCSDS_TX_CODER_DIFF_DATA_BUS_SIZE-1 downto 0);
    dat_val_i: in std_logic;
    rst_i: in std_logic;
    -- outputs
    dat_o: out std_logic_vector(CCSDS_TX_CODER_DIFF_DATA_BUS_SIZE-1 downto 0);
    dat_val_o: out std_logic
  );
end ccsds_tx_coder_differential;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture rtl of ccsds_tx_coder_differential is
-- internal constants
-- internal variable signals
-- components instanciation and mapping
  begin
-- presynthesis checks
     CHKCODERP0 : if (CCSDS_TX_CODER_DIFF_DATA_BUS_SIZE mod (CCSDS_TX_CODER_DIFF_BITS_PER_CODEWORD) /= 0) generate
      process
      begin
        report "ERROR: DATA BUS SIZE HAS TO BE A MULTIPLE OF BITS PER CODE WORD" severity failure;
	      wait;
      end process;
    end generate CHKCODERP0;

-- internal processing
    --=============================================================================
    -- Begin of coderdiffp
    -- Differential encode words
    --=============================================================================
    -- read: rst_i, dat_i, dat_val_i
    -- write: dat_o, dat_val_o
    -- r/w:
    CODERDIFFP: process (clk_i)
    variable prev_sym: std_logic_vector(CCSDS_TX_CODER_DIFF_BITS_PER_CODEWORD-1 downto 0) := (others => '0');
    begin
      -- on each clock rising edge
      if rising_edge(clk_i) then
        -- reset signal received
        if (rst_i = '1') then
          dat_o <= (others => '0');
          dat_val_o <= '0';
          prev_sym := (others => '0');
        else
          if (dat_val_i = '1') then
            dat_val_o <= '1';
            dat_o(CCSDS_TX_CODER_DIFF_DATA_BUS_SIZE-1 downto CCSDS_TX_CODER_DIFF_DATA_BUS_SIZE-CCSDS_TX_CODER_DIFF_BITS_PER_CODEWORD) <= prev_sym xor dat_i(CCSDS_TX_CODER_DIFF_DATA_BUS_SIZE-1 downto CCSDS_TX_CODER_DIFF_DATA_BUS_SIZE-CCSDS_TX_CODER_DIFF_BITS_PER_CODEWORD);
            for i in CCSDS_TX_CODER_DIFF_DATA_BUS_SIZE/(CCSDS_TX_CODER_DIFF_BITS_PER_CODEWORD)-1 downto 1 loop
              dat_o(i*CCSDS_TX_CODER_DIFF_BITS_PER_CODEWORD-1 downto (i-1)*CCSDS_TX_CODER_DIFF_BITS_PER_CODEWORD) <= dat_i(i*CCSDS_TX_CODER_DIFF_BITS_PER_CODEWORD-1 downto (i-1)*CCSDS_TX_CODER_DIFF_BITS_PER_CODEWORD) xor dat_i((i+1)*CCSDS_TX_CODER_DIFF_BITS_PER_CODEWORD-1 downto i*CCSDS_TX_CODER_DIFF_BITS_PER_CODEWORD);
            end loop;
            prev_sym := dat_i(CCSDS_TX_CODER_DIFF_BITS_PER_CODEWORD-1 downto 0);
          else
            dat_val_o <= '0';
          end if;
        end if;
      end if;
    end process;
end rtl;
