-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rxtx_lfsr
---- Version: 1.0.0
---- Description:
---- Linear Feedback Shift Register
---- Input: none
---- Timing requirements: CCSDS_RXTX_LFSR_DATA_BUS_SIZE+1 clock cycles for valid output data
---- Output: dat_val_o <= "1" / dat_o <= "LFSRSEQUENCE"
---- Ressources requirements: TODO
-------------------------------
---- Author(s):
---- Guillaume REMBERT
-------------------------------
---- Licence:
---- MIT
-------------------------------
-- Test ressources:
-- GNURADIO GLFSR block

-- CCSDS parameters
-- Width = 8
-- Mode = Fibonacci ('0')
-- Polynomial = x"A9"
-- Seed = x"FF"
-- Result = "1111111101001000000011101100000010011010"

-- Width = 8
-- Mode = Galois ('1')
-- Polynomial = x"A9"
-- Seed = x"FF"
-- Result = "101001011011000001011000110110"

-- libraries used
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--=============================================================================
-- Entity declaration for ccsds_tx / unitary tx randomizer inputs and outputs
--=============================================================================
entity ccsds_rxtx_lfsr is
  generic(
    constant CCSDS_RXTX_LFSR_DATA_BUS_SIZE: integer; -- in bits
		constant CCSDS_RXTX_LFSR_MEMORY_SIZE: integer range 2 to 256 := 8; -- in bits
		constant CCSDS_RXTX_LFSR_MODE: std_logic := '0'; -- 0: Fibonacci / 1: Galois
		constant CCSDS_RXTX_LFSR_POLYNOMIAL: std_logic_vector	:= x"A9"; -- Polynomial / MSB <=> lower polynome (needs to be '1')
		constant CCSDS_RXTX_LFSR_SEED: std_logic_vector	:= x"FF"		-- Initial Value
  );
  port(
    -- inputs
    clk_i: in std_logic;
    rst_i: in std_logic;
    -- outputs
    dat_o: out std_logic_vector(CCSDS_RXTX_LFSR_DATA_BUS_SIZE-1 downto 0);
    dat_val_o: out std_logic
  );
end ccsds_rxtx_lfsr;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture structure of ccsds_rxtx_lfsr is

-- internal constants
-- internal variable signals
	signal lfsr_memory: std_logic_vector(CCSDS_RXTX_LFSR_MEMORY_SIZE-1 downto 0) := CCSDS_RXTX_LFSR_SEED;
-- components instanciation and mapping
  begin

-- presynthesis checks
	  CHKLFSRP0 : if CCSDS_RXTX_LFSR_POLYNOMIAL'length /= CCSDS_RXTX_LFSR_MEMORY_SIZE generate
		  process
		  begin
			  report "ERROR: LFSR_POLYNOMIAL LENGTH MUST BE EQUAL TO MEMORY SIZE (SHORTENED VERSION / DON'T PUT MANDATORY HIGHER POLYNOME '1')" severity failure;
			  wait;
		  end process;
	  end generate CHKLFSRP0;
	  CHKLFSRP1 : if CCSDS_RXTX_LFSR_MEMORY_SIZE <= 1 generate
		  process
		  begin
			  report "ERROR: LFSR_MEMORY_SIZE MUST BE BIGGER THAN 1" severity failure;
			  wait;
		  end process;
	  end generate CHKLFSRP1;
	  CHKLFSRP2 : if CCSDS_RXTX_LFSR_SEED'length /= CCSDS_RXTX_LFSR_MEMORY_SIZE generate
		  process
		  begin
			  report "ERROR: LFSR_SEED LENGTH MUST BE EQUAL TO LFSR_MEMORY_SIZE" severity failure;
			  wait;
		  end process;
	  end generate CHKLFSRP2;
    CHKLFSRP3 : if CCSDS_RXTX_LFSR_POLYNOMIAL(CCSDS_RXTX_LFSR_MEMORY_SIZE-1) = '0' generate
      process
      begin
        report "ERROR: LFSR POLYNOMIAL MSB MUST BE EQUAL TO 1" severity failure;
        wait;
      end process;
    end generate CHKLFSRP3;

-- internal processing
    --=============================================================================
    -- Begin of crcp
    -- Compute CRC based on input data
    --=============================================================================
    -- read: rst_i
    -- write: dat_o, dat_val_o
    -- r/w: lfsr_memory
    LFSRP: process (clk_i)
    variable output_pointer: integer range -1 to (CCSDS_RXTX_LFSR_DATA_BUS_SIZE-1) := CCSDS_RXTX_LFSR_DATA_BUS_SIZE-1;
    variable feedback_register: std_logic := '0';
    begin
      -- on each clock rising edge
      if rising_edge(clk_i) then
        -- reset signal received
        if (rst_i = '1') then
          lfsr_memory <= CCSDS_RXTX_LFSR_SEED;
          dat_o <= (others => '0');
          dat_val_o <= '0';
          output_pointer := CCSDS_RXTX_LFSR_DATA_BUS_SIZE-1;
          feedback_register := '0';
        else
          -- generation is finished
          if (output_pointer = -1) then
            dat_val_o <= '1';
          -- generating sequence
          else
            dat_val_o <= '0';
            -- Fibonacci
            if (CCSDS_RXTX_LFSR_MODE = '0') then
              dat_o(output_pointer) <= lfsr_memory(CCSDS_RXTX_LFSR_MEMORY_SIZE-1);
              output_pointer := output_pointer - 1;
              feedback_register := lfsr_memory(CCSDS_RXTX_LFSR_MEMORY_SIZE-1);
              for i in 0 to CCSDS_RXTX_LFSR_MEMORY_SIZE-2 loop
                if (CCSDS_RXTX_LFSR_POLYNOMIAL(i) = '1') then
                  feedback_register := feedback_register xor lfsr_memory(i);
                end if;
              end loop;
              lfsr_memory <= std_logic_vector(resize(unsigned(lfsr_memory),CCSDS_RXTX_LFSR_MEMORY_SIZE-1)) & feedback_register;
            -- Galois
            else
              dat_o(output_pointer) <= lfsr_memory(CCSDS_RXTX_LFSR_MEMORY_SIZE-1);
              output_pointer := output_pointer - 1;
              lfsr_memory(0) <= lfsr_memory(CCSDS_RXTX_LFSR_MEMORY_SIZE-1);
              for i in 1 to CCSDS_RXTX_LFSR_MEMORY_SIZE-1 loop
                if (CCSDS_RXTX_LFSR_POLYNOMIAL(i) = '1') then
                  lfsr_memory(i) <= lfsr_memory(i-1) xor lfsr_memory(CCSDS_RXTX_LFSR_MEMORY_SIZE-1);
                else
                  lfsr_memory(i) <= lfsr_memory(i-1);
                end if;
              end loop;
            end if;
          end if;
        end if;
      end if;
    end process;
end structure;
