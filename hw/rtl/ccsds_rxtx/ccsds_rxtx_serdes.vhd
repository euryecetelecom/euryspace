-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rxtx_serdes
---- Version: 1.0.0
---- Description:
---- This is the data serialiser/deserialiser
---- requires CCSDS_RXTX_SERDES_DEPTH clk cycles to finish
-------------------------------
---- Author(s):
---- Guillaume Rembert
-------------------------------
---- Licence:
---- MIT
-------------------------------
---- Changes list:
---- 2015/11/18: initial release
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
    CCSDS_RXTX_SERDES_DEPTH : integer := RXTX_SYSTEM_WB_DATA_BUS_SIZE
  );
  port(
    rst_i: in std_logic; -- system reset input
    clk_par_i: in std_logic; -- parallel input data clock
    clk_ser_i: in std_logic; -- serial input data clock
    clk_par_o: out std_logic; -- parallel output data clock
    clk_ser_o: out std_logic; -- serial output data clock
    data_par_i: in std_logic_vector(CCSDS_RXTX_SERDES_DEPTH-1 downto 0); -- parallel input data
    data_ser_i: in std_logic; -- serial input data
    data_par_o: out std_logic_vector(CCSDS_RXTX_SERDES_DEPTH-1 downto 0); -- parallel output data
    data_ser_o: out std_logic -- serial output data
  );
end ccsds_rxtx_serdes;

--=============================================================================
-- architecture declaration / internal processing
--=============================================================================
architecture rtl of ccsds_rxtx_serdes is
--=============================================================================
-- architecture begin
--=============================================================================
  begin
    --=============================================================================
    -- Begin of par2serp
    -- Serialization of parrallel data received starting with MSB
    --=============================================================================
    -- read: clk_par_i, rst_i, data_par_i
    -- write: data_ser_o
    -- r/w: 
    PAR2SERP : process (clk_par_i)
      variable serdes_pnt: integer range 0 to CCSDS_RXTX_SERDES_DEPTH-1 := CCSDS_RXTX_SERDES_DEPTH-1;
      begin
        -- on each clock rising edge
        if rising_edge(clk_par_i) then
          -- reset signal received
          if (rst_i = '1') then
            -- reset all
            serdes_pnt := CCSDS_RXTX_SERDES_DEPTH-1;
            clk_ser_o <= '0';
            data_ser_o <= '0';
          else
            -- generate a dynamic bus position pointer
            if (serdes_pnt = 0) then
              serdes_pnt := CCSDS_RXTX_SERDES_DEPTH-1;
            else
              serdes_pnt := serdes_pnt - 1;
            end if;
            -- serialise data on output_bus
            data_ser_o <= data_par_i(serdes_pnt);
          end if;
        end if;
      end process;
    --=============================================================================
    -- Begin of ser2parp
    -- Serialization of parrallel data received
    --=============================================================================
    -- read: clk_par_i, rst_i
    -- write: 
    -- r/w: 
--    SER2PARP : process (clk_ser_i)
--      begin
--        data_o <= i_samples_i(0);
--        clk_o <= clk_i;
--      end process;
end rtl;
--=============================================================================
-- architecture end
--=============================================================================
