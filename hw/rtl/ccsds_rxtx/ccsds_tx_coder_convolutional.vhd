---- Design Name: ccsds_tx_coder_convolutional
---- Version: 1.0.0
---- Description:
---- Convolutional coder
-------------------------------
---- Author(s):
---- Guillaume REMBERT
-------------------------------
---- Licence:
---- MIT
-------------------------------
-- TODO: puncturation + input rate /= 1

-- libraries used
library ieee;
use ieee.std_logic_1164.all;
use work.ccsds_rxtx_functions.all;
use work.ccsds_rxtx_types.all;

--=============================================================================
-- Entity declaration for ccsds_tx / unitary tx convolutional coder inputs and outputs
--=============================================================================
entity ccsds_tx_coder_convolutional is
  generic(
    constant CCSDS_TX_CODER_CONV_CONNEXION_VECTORS: std_logic_vector_array := ("1111001", "1011011");
    constant CCSDS_TX_CODER_CONV_CONSTRAINT_SIZE: integer := 7; -- in bits
    constant CCSDS_TX_CODER_CONV_DATA_BUS_SIZE: integer; -- in bits
    constant CCSDS_TX_CODER_CONV_OPERATING_MODE: integer := 1; -- 0=streaming / 1=truncated (reset state when new frame) //TODO: terminated trellis + tailbiting
    constant CCSDS_TX_CODER_CONV_OUTPUT_INVERSION: boolean_array := (false, true);
    constant CCSDS_TX_CODER_CONV_RATE_OUTPUT: integer := 2; -- in bits/operation
    constant CCSDS_TX_CODER_CONV_SEED: std_logic_vector := "000000"
  );
  port(
    -- inputs
    clk_i: in std_logic;
    dat_i: in std_logic_vector(CCSDS_TX_CODER_CONV_DATA_BUS_SIZE-1 downto 0);
    dat_val_i: in std_logic;
    rst_i: in std_logic;
    -- outputs
    bus_o: out std_logic;
    dat_o: out std_logic_vector(CCSDS_TX_CODER_CONV_DATA_BUS_SIZE*CCSDS_TX_CODER_CONV_RATE_OUTPUT-1 downto 0);
    dat_val_o: out std_logic
  );
end ccsds_tx_coder_convolutional;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture rtl of ccsds_tx_coder_convolutional is
-- internal constants
  type connexion_vectors_array is array(CCSDS_TX_CODER_CONV_RATE_OUTPUT-1 downto 0) of std_logic_vector(CCSDS_TX_CODER_CONV_CONSTRAINT_SIZE-1 downto 0);
  signal connexion_vectors: connexion_vectors_array;
  constant connexion_vectors_array_size: integer := CCSDS_TX_CODER_CONV_CONNEXION_VECTORS'length;
  constant output_inversion_array_size: integer := CCSDS_TX_CODER_CONV_OUTPUT_INVERSION'length;
-- internal variable signals
  signal coder_busy: std_logic := '0';
  signal coder_memory: std_logic_vector(CCSDS_TX_CODER_CONV_CONSTRAINT_SIZE-2 downto 0) := CCSDS_TX_CODER_CONV_SEED;
-- components instanciation and mapping
  begin
    bus_o <= coder_busy;
    CONNEXION_VECTORS_GENERATOR: for vector_counter in 0 to CCSDS_TX_CODER_CONV_RATE_OUTPUT-1 generate
      connexion_vectors(CCSDS_TX_CODER_CONV_RATE_OUTPUT-1-vector_counter) <= convert_std_logic_vector_array_to_std_logic_vector(CCSDS_TX_CODER_CONV_CONNEXION_VECTORS, vector_counter);
    end generate CONNEXION_VECTORS_GENERATOR;

-- presynthesis checks
     CHKCODERP0 : if (CCSDS_TX_CODER_CONV_SEED'length /= CCSDS_TX_CODER_CONV_CONSTRAINT_SIZE-1) generate
      process
      begin
        report "ERROR: SEED SIZE HAS TO BE EQUAL TO CONSTRAINT SIZE - 1" severity failure;
	      wait;
      end process;
    end generate CHKCODERP0;
     CHKCODERP1 : if (connexion_vectors_array_size /= CCSDS_TX_CODER_CONV_RATE_OUTPUT) generate
      process
      begin
        report "ERROR: CONNEXION VECTORS ARRAY SIZE HAS TO BE EQUAL TO OUTPUT RATE : " & integer'image(connexion_vectors_array_size) severity failure;
	      wait;
      end process;
    end generate CHKCODERP1;
     CHKCODERP2 : if (output_inversion_array_size /= CCSDS_TX_CODER_CONV_RATE_OUTPUT) generate
      process
      begin
        report "ERROR: OUTPUT INVERSION ARRAY HAS TO BE EQUAL TO OUTPUT RATE" severity failure;
	      wait;
      end process;
    end generate CHKCODERP2;

-- internal processing
    --=============================================================================
    -- Begin of coderp
    -- Convolutional encode bits based on connexion vectors
    --=============================================================================
    -- read: rst_i, dat_i, dat_val_i
    -- write: dat_o, dat_val_o, coder_busy
    -- r/w:
    CODERP: process (clk_i)
    variable coder_data_pointer: integer range -1 to (CCSDS_TX_CODER_CONV_DATA_BUS_SIZE-1) := -1;
    variable coder_data: std_logic_vector(CCSDS_TX_CODER_CONV_DATA_BUS_SIZE-1 downto 0) := (others => '0');
    variable coder_atomic_result: std_logic := '0';
    begin
      -- on each clock rising edge
      if rising_edge(clk_i) then
        -- reset signal received
        if (rst_i = '1') then
--          dat_o <= (others => '0');
          dat_val_o <= '0';
          coder_memory <= CCSDS_TX_CODER_CONV_SEED;
          coder_data_pointer := -1;
          coder_atomic_result := '0';
          coder_busy <= '0';
        else
          case coder_data_pointer is
            -- no current computation
            when -1 =>
              dat_val_o <= '0';
              -- reset on new frame behaviour
              if (CCSDS_TX_CODER_CONV_OPERATING_MODE = 1) then
                coder_memory <= CCSDS_TX_CODER_CONV_SEED;
              end if;
              -- store data
              if (dat_val_i = '1') then
                coder_data := dat_i;
                coder_busy <= '1';
                coder_data_pointer := CCSDS_TX_CODER_CONV_DATA_BUS_SIZE-1;
              else
                -- nothing to be done
                coder_busy <= '0';
              end if;
            -- processing
            when others =>
              coder_busy <= '1';
              dat_val_o <= '0';
              -- shift memory
              coder_memory <= coder_memory(CCSDS_TX_CODER_CONV_CONSTRAINT_SIZE-3 downto 0) & coder_data(coder_data_pointer);
              -- compute output
              for i in CCSDS_TX_CODER_CONV_RATE_OUTPUT-1 downto 0 loop
                if (connexion_vectors(i)(CCSDS_TX_CODER_CONV_CONSTRAINT_SIZE-1) = '1') then
                  coder_atomic_result := coder_data(coder_data_pointer);
                else
                  coder_atomic_result := '0';
                end if;
                for j in CCSDS_TX_CODER_CONV_CONSTRAINT_SIZE-2 downto 0 loop
                  if (connexion_vectors(i)(j) = '1') then
                    coder_atomic_result := coder_atomic_result xor coder_memory(CCSDS_TX_CODER_CONV_CONSTRAINT_SIZE-2-j);
                  end if;
                end loop;
                if (CCSDS_TX_CODER_CONV_OUTPUT_INVERSION(CCSDS_TX_CODER_CONV_RATE_OUTPUT-1-i) = true) then
                  dat_o(coder_data_pointer*CCSDS_TX_CODER_CONV_RATE_OUTPUT+i) <= not(coder_atomic_result);
                else
                  dat_o(coder_data_pointer*CCSDS_TX_CODER_CONV_RATE_OUTPUT+i) <= coder_atomic_result;
                end if;
              end loop;
              -- output is computed
              if (coder_data_pointer = 0) then
                coder_busy <= '0';
                dat_val_o <= '1';
              end if;
              coder_data_pointer := coder_data_pointer - 1;
          end case;
        end if;
      end if;
    end process;
end rtl;
