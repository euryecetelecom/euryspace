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
--TODO: use dedicated serdes component

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
      -- inputs
      clk_i: in std_logic;
      dat_par_i: in std_logic_vector(CCSDS_TX_MANAGER_DATA_BUS_SIZE-1 downto 0);
      dat_ser_i: in std_logic;
      dat_val_i: in std_logic;
      ena_i: in std_logic;
      in_sel_i: in std_logic; -- 0 = parallel data / 1 = external serial data
      rst_i: in std_logic;
      -- outputs
      clk_o: out std_logic;
      dat_o: out std_logic_vector(CCSDS_TX_MANAGER_DATA_BUS_SIZE-1 downto 0);
      dat_val_o: out std_logic;
      ena_o: out std_logic
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
    ENABLEP : process (ena_i, clk_i)
    begin
      if (ena_i = '1') then
        clk_o <= clk_i;
        ena_o <= '1';
      else
        clk_o <= '0';
        ena_o <= '0';
      end if;
    end process;
    --=============================================================================
    -- Begin of serparp
    -- Serial to parallel data if in_sel_i = 1 / first input bit as MSB
    --=============================================================================
    -- read: clk_i, rst_i, ena_i, dat_val_i, in_sel_i
    -- write: dat_o, dat_val_o
    -- r/w: 
    SERPARP : process (clk_i)
    -- variables instantiation
    variable circular_pointer: integer range 0 to CCSDS_TX_MANAGER_DATA_BUS_SIZE-1 := CCSDS_TX_MANAGER_DATA_BUS_SIZE-1;
    begin
      -- on each clock rising edge
      if rising_edge(clk_i) then
        if (rst_i = '1') then
          dat_o <= (others => '0');
          dat_val_o <= '0';
        else
          if (ena_i = '1') then
            if (dat_val_i = '1') then
              if (in_sel_i = '1') then
                dat_o(circular_pointer) <= dat_ser_i;
                if (circular_pointer = 0) then
                  dat_val_o <= '1';
                  circular_pointer := CCSDS_TX_MANAGER_DATA_BUS_SIZE-1;
                else
                  dat_val_o <= '0';
                  circular_pointer := circular_pointer - 1;
                end if;
              else
                dat_val_o <= '1';
                dat_o <= dat_par_i;
              end if;
            else
              dat_val_o <= '0';
            end if;
          else
            dat_val_o <= '0';
          end if;
        end if;
      end if;
    end process;
end structure;
