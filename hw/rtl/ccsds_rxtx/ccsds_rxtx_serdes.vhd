-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rxtx_serdes
---- Version: 1.0.0
---- Description:
---- Constant rate data serialiser/deserialiser
---- Input: 1 clk / [SER2PAR: dat_ser_val_i <= '1' / dat_ser_i <= 'NEXTSERIALDATA' ] / [PAR2SER: dat_par_val_i <= '1' / dat_par_i <= "PARALLELDATA"]
---- Timing requirements: SER2PAR: 1 clock cycle - PAR2SER: CCSDS_RXTX_SERDES_DEPTH clock cycles
---- Output: [SER2PAR: dat_par_val_o <= "1" / dat_par_o <= "PARALLELIZEDDATA"] / [PAR2SER: dat_ser_val_o <= "1" / dat_ser_o <= "SERIALIZEDDATA"]
---- Ressources requirements: CCSDS_RXTX_SERDES_DEPTH + 2*|log(CCSDS_RXTX_SERDES_DEPTH-1)/log(2)| + 2 registers
-------------------------------
---- Author(s):
---- Guillaume Rembert
-------------------------------
---- Licence:
---- MIT
-------------------------------
---- Changes list:
---- 2015/11/18: initial release
---- 2016/10/27: review + add ser2par
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;
library work;
use work.ccsds_rxtx_parameters.all;

--=============================================================================
-- Entity declaration for ccsds_rxtx_serdes / data serialiser/deserialiser
--=============================================================================
entity ccsds_rxtx_serdes is
  generic (
    constant CCSDS_RXTX_SERDES_DEPTH : integer
  );
  port(
    -- inputs
    clk_i: in std_logic; -- parallel input data clock
    dat_par_i: in std_logic_vector(CCSDS_RXTX_SERDES_DEPTH-1 downto 0); -- parallel input data
    dat_par_val_i: in std_logic; -- parallel data valid indicator
    dat_ser_i: in std_logic; -- serial input data
    dat_ser_val_i: in std_logic; -- serial data valid indicator
    rst_i: in std_logic; -- system reset input
    -- outputs
    bus_o: out std_logic; -- par2ser busy indicator
    dat_par_o: out std_logic_vector(CCSDS_RXTX_SERDES_DEPTH-1 downto 0); -- parallel output data
    dat_par_val_o: out std_logic; -- parallel output data valid indicator
    dat_ser_o: out std_logic; -- serial output data
    dat_ser_val_o: out std_logic -- serial output data valid indicator
  );
end ccsds_rxtx_serdes;

--=============================================================================
-- architecture declaration / internal processing
--=============================================================================
architecture rtl of ccsds_rxtx_serdes is

-- internal variable signals
  signal wire_busy: std_logic := '0';
  signal wire_data_par_valid: std_logic := '0';
  signal wire_data_ser_valid: std_logic := '0';
  signal serial_data_pointer: integer range 0 to CCSDS_RXTX_SERDES_DEPTH-1 := CCSDS_RXTX_SERDES_DEPTH-1;
  signal parallel_data_pointer: integer range 0 to CCSDS_RXTX_SERDES_DEPTH-1 := CCSDS_RXTX_SERDES_DEPTH-1;

  begin
-- components instanciation and mapping
  bus_o <= wire_busy;
  dat_par_val_o <= wire_data_par_valid;
  dat_ser_val_o <= wire_data_ser_valid;
-- presynthesis checks
-- internal processing

    --=============================================================================
    -- Begin of par2serp
    -- Serialization of parallel data received starting with MSB
    --=============================================================================
    -- read: clk_i, rst_i, dat_par_i, dat_par_val_i
    -- write: dat_ser_o, wire_data_ser_valid, wire_busy
    -- r/w: parallel_data_pointer
    PAR2SERP : process (clk_i)
      variable serdes_memory: std_logic_vector(CCSDS_RXTX_SERDES_DEPTH-1 downto 0) := (others => '0');
      begin
        -- on each clock rising edge
        if rising_edge(clk_i) then
          -- reset signal received
          if (rst_i = '1') then
            -- reset all
            wire_busy <= '0';
            dat_ser_o <= '0';
            wire_data_ser_valid <= '0';
            parallel_data_pointer <= CCSDS_RXTX_SERDES_DEPTH-1;
--            serdes_memory := (others => '0');
          else
            if (dat_par_val_i = '1') and (parallel_data_pointer = CCSDS_RXTX_SERDES_DEPTH-1) then
              wire_busy <= '1';
              serdes_memory := dat_par_i;
              -- serialise data on output_bus
              dat_ser_o <= dat_par_i(parallel_data_pointer);
              -- decrement position pointer
              parallel_data_pointer <= (parallel_data_pointer - 1) mod CCSDS_RXTX_SERDES_DEPTH;
              wire_data_ser_valid <= '1';
            else
              if (parallel_data_pointer /= CCSDS_RXTX_SERDES_DEPTH-1) then
                wire_busy <= '1';
                -- serialise data on output_bus
                dat_ser_o <= serdes_memory(parallel_data_pointer);
                -- decrement position pointer
                parallel_data_pointer <= (parallel_data_pointer - 1) mod CCSDS_RXTX_SERDES_DEPTH;
                wire_data_ser_valid <= '1';
              else
                -- nothing to do
                wire_busy <= '0';
                wire_data_ser_valid <= '0';
              end if;
            end if;
          end if;
        end if;
      end process;
    --=============================================================================
    -- Begin of ser2parp
    -- Parallelization of serial data received
    --=============================================================================
    -- read: clk_i, rst_i, dat_ser_i, dat_ser_val_i
    -- write: dat_par_o, wire_data_par_valid
    -- r/w: serial_data_pointer
    SER2PARP : process (clk_i)
      begin
        -- on each clock rising edge
        if rising_edge(clk_i) then
          -- reset signal received
          if (rst_i = '1') then
            -- reset all
            dat_par_o <= (others => '0');
            wire_data_par_valid <= '0';
            serial_data_pointer <= CCSDS_RXTX_SERDES_DEPTH-1;
          else
            if (dat_ser_val_i = '1') then
              -- serialise data on output_bus
              dat_par_o(serial_data_pointer) <= dat_ser_i;
              if (serial_data_pointer = 0) then
                wire_data_par_valid <= '1';
              else
                wire_data_par_valid <= '0';
              end if;
              -- decrement position pointer
              serial_data_pointer <= (serial_data_pointer - 1) mod CCSDS_RXTX_SERDES_DEPTH;
            else
              wire_data_par_valid <= '0';
            end if;
          end if;
        end if;
      end process;
end rtl;
--=============================================================================
-- architecture end
--=============================================================================
