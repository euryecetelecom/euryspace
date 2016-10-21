-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_manager
---- Version: 1.0.0
---- Description:
---- TBD - in charge of clock enable/disable + input switch / ser to par conversion
-------------------------------
---- Author(s):
---- Guillaume REMBERT
-------------------------------
---- Licence:
---- MIT
-------------------------------
---- Changes list:
---- 2016/10/16: initial release
-------------------------------
--FIXME: use dedicated serdes component + merge ser2par code from here

-- libraries used
library ieee;
use ieee.std_logic_1164.all;

--=============================================================================
-- Entity declaration for ccsds_tx / unitary tx manager inputs and outputs
--=============================================================================
entity ccsds_tx_manager is
    generic(
      CCSDS_TX_MANAGER_DATA_BUS_SIZE : integer := 32
    );
    port(
      clk_i: in std_logic;
      clk_o: out std_logic;
      rst_i: in std_logic;
      ena_i: in std_logic;
      enabled_o: out std_logic;
      input_sel_i: in std_logic; -- 0 = parallel data / 1 = external serial data
      data_par_i: in std_logic_vector(CCSDS_TX_MANAGER_DATA_BUS_SIZE-1 downto 0);
      data_ser_i: in std_logic;
      data_valid_i: in std_logic;
      data_valid_o: out std_logic;
      data_o: out std_logic_vector(CCSDS_TX_MANAGER_DATA_BUS_SIZE-1 downto 0)
    );
end ccsds_tx_manager;

--=============================================================================
-- architecture declaration / internal connections
--=============================================================================
architecture structure of ccsds_tx_manager is

-- interconnection signals

-- components instanciation and mapping
  begin
    --=============================================================================
    -- Begin of enablep
    -- Enable/disable clk forwarding
    --=============================================================================
    -- read: ena_i
    -- write: clk_o, enabled_o
    -- r/w: 
    ENABLEP : process (clk_i)
    begin
      if (ena_i = '1') then
        clk_o <= clk_i;
        enabled_o <= '1';
      else
        clk_o <= '0';
        enabled_o <= '0';
      end if;
    end process;
    --=============================================================================
    -- Begin of serparp
    -- Serial to parallel data if input_sel_i = 1 / first input bit as MSB
    --=============================================================================
    -- read: clk_i, rst_i, ena_i, data_valid_i, input_sel_i
    -- write: data_o, data_valid_o
    -- r/w: 
    SERPARP : process (clk_i)
    -- variables instantiation
    variable circular_pointer: integer range 0 to CCSDS_TX_MANAGER_DATA_BUS_SIZE-1 := CCSDS_TX_MANAGER_DATA_BUS_SIZE-1;
    begin
      -- on each clock rising edge
      if rising_edge(clk_i) then
        if (rst_i = '1') then
          data_o <= (others => '0');
          data_valid_o <= '0';
        else
          if (ena_i = '1') then
            if (data_valid_i = '1') then
              if (input_sel_i = '1') then
                data_o(circular_pointer) <= data_ser_i;
                if (circular_pointer = 0) then
                  data_valid_o <= '1';
                  circular_pointer := CCSDS_TX_MANAGER_DATA_BUS_SIZE-1;
                else
                  data_valid_o <= '0';
                  circular_pointer := circular_pointer - 1;
                end if;
              else
                data_valid_o <= '1';
                data_o <= data_par_i;
              end if;
            else
              data_valid_o <= '0';
            end if;
          else
            data_valid_o <= '0';
          end if;
        end if;
      end if;
    end process;
end structure;
