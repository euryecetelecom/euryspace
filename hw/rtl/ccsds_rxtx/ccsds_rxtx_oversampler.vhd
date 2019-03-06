-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rxtx_oversampler
---- Version: 1.0.0
---- Description:
---- Insert OSR-1 '0' between symbols
-------------------------------
---- Author(s):
---- Guillaume REMBERT
-------------------------------
---- Licence:
---- MIT
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;

--=============================================================================
-- Entity declaration for ccsds_tx / unitary rxtx oversampler inputs and outputs
--=============================================================================
entity ccsds_rxtx_oversampler is
  generic(
    constant CCSDS_RXTX_OVERSAMPLER_OVERSAMPLING_RATIO: integer := 4;
    constant CCSDS_RXTX_OVERSAMPLER_SYMBOL_DEPHASING: boolean := false;
    constant CCSDS_RXTX_OVERSAMPLER_SIG_QUANT_DEPTH: integer
  );
  port(
    -- inputs
    clk_i: in std_logic;
    rst_i: in std_logic;
    sam_i: in std_logic_vector(CCSDS_RXTX_OVERSAMPLER_SIG_QUANT_DEPTH-1 downto 0);
    sam_val_i: in std_logic;
    -- outputs
    sam_o: out std_logic_vector(CCSDS_RXTX_OVERSAMPLER_SIG_QUANT_DEPTH-1 downto 0);
    sam_val_o: out std_logic
  );
end ccsds_rxtx_oversampler;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture structure of ccsds_rxtx_oversampler is
-- internal constants
-- internal variable signals
-- components instanciation and mapping
  begin
-- presynthesis checks
     CHKOVERSAMPLERP0 : if (CCSDS_RXTX_OVERSAMPLER_OVERSAMPLING_RATIO mod 2 /= 0) generate
      process
      begin
        report "ERROR: OVERSAMPLING RATIO HAS TO BE A MULTIPLE OF 2" severity failure;
	      wait;
      end process;
    end generate CHKOVERSAMPLERP0;
     CHKOVERSAMPLERP1 : if (CCSDS_RXTX_OVERSAMPLER_OVERSAMPLING_RATIO = 0) generate
      process
      begin
        report "ERROR: OVERSAMPLING RATIO CANNOT BE 0" severity failure;
	      wait;
      end process;
    end generate CHKOVERSAMPLERP1;
-- internal processing
    --=============================================================================
    -- Begin of osrp
    -- Insert all 0 samples
    --=============================================================================
    -- read: rst_i, sam_i
    -- write: sam_o
    -- r/w:
    OSRP: process (clk_i)
    variable samples_counter: integer range 0 to CCSDS_RXTX_OVERSAMPLER_OVERSAMPLING_RATIO-1 := CCSDS_RXTX_OVERSAMPLER_OVERSAMPLING_RATIO-1;
    begin
      -- on each clock rising edge
      if rising_edge(clk_i) then
        -- reset signal received
        if (rst_i = '1') then
          sam_o <= (others => '0');
          samples_counter := CCSDS_RXTX_OVERSAMPLER_OVERSAMPLING_RATIO-1;
        else
          if (sam_val_i = '1') then
            sam_val_o <= '1';
            if (CCSDS_RXTX_OVERSAMPLER_SYMBOL_DEPHASING = true) then
              if (samples_counter <= 0) then
                sam_o <= (others => '0');
                samples_counter := CCSDS_RXTX_OVERSAMPLER_OVERSAMPLING_RATIO-1;
              else
                if (samples_counter = CCSDS_RXTX_OVERSAMPLER_OVERSAMPLING_RATIO/2) then
                  sam_o <= sam_i;
                else
                  sam_o <= (others => '0');
                end if;
                samples_counter := samples_counter - 1;
              end if;
            else
              if (samples_counter <= 0) then
                sam_o <= sam_i;
                samples_counter := CCSDS_RXTX_OVERSAMPLER_OVERSAMPLING_RATIO-1;
              else
                sam_o <= (others => '0');
                samples_counter := samples_counter - 1;
              end if;
            end if;
          else
            sam_val_o <= '0';
          end if;
        end if;
      end if;
    end process;
end structure;
