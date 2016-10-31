-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_manager
---- Version: 1.0.0
---- Description:
---- In charge of clock forwarding to reduce power draw + select TX input data
-------------------------------
---- Author(s):
---- Guillaume REMBERT
-------------------------------
---- Licence:
---- MIT
-------------------------------
---- Changes list:
---- 2016/10/16: initial release
---- 2016/10/31: add serdes sub-component
-------------------------------

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
  component ccsds_rxtx_serdes is
    generic (
      constant CCSDS_RXTX_SERDES_DEPTH : integer
    );
    port(
      clk_i: in std_logic;
      dat_par_i: in std_logic_vector(CCSDS_RXTX_SERDES_DEPTH-1 downto 0);
      dat_par_val_i: in std_logic;
      dat_ser_i: in std_logic;
      dat_ser_val_i: in std_logic;
      rst_i: in std_logic;
      bus_o: out std_logic;
      dat_par_o: out std_logic_vector(CCSDS_RXTX_SERDES_DEPTH-1 downto 0);
      dat_par_val_o: out std_logic;
      dat_ser_o: out std_logic;
      dat_ser_val_o: out std_logic
    );
  end component;

-- interconnection signals
  signal gated_clock: std_logic;
  signal wire_serdes_dat_par_o: std_logic_vector(CCSDS_TX_MANAGER_DATA_BUS_SIZE-1 downto 0);
  signal wire_serdes_dat_par_val_o: std_logic;
  signal wire_serdes_dat_ser_val_i: std_logic;

  begin
-- components instanciation and mapping
    serdes_001: ccsds_rxtx_serdes
      generic map(
        CCSDS_RXTX_SERDES_DEPTH => CCSDS_TX_MANAGER_DATA_BUS_SIZE
      )
      port map(
        clk_i => gated_clock,
        dat_par_i => (others => '0'),
        dat_par_val_i => '0',
        dat_ser_i => dat_ser_i,
        dat_ser_val_i => wire_serdes_dat_ser_val_i,
        rst_i => rst_i,
        dat_par_o => wire_serdes_dat_par_o,
        dat_par_val_o => wire_serdes_dat_par_val_o
      );

    ena_o <= ena_i;
    clk_o <= clk_i and ena_i;
    gated_clock <= clk_i and ena_i;
    
    --=============================================================================
    -- Begin of selectp
    -- Input selection
    --=============================================================================
    -- read: rst_i, ena_i, in_sel_i, dat_val_i
    -- write: dat_o, dat_val_o, wire_serdes_dat_ser_val_i
    -- r/w: 
    SELECTP : process (gated_clock)
    -- variables instantiation
    begin
      -- on each clock rising edge
      if rising_edge(gated_clock) then
        if (rst_i = '1') then
          dat_o <= (others => '0');
          dat_val_o <= '0';
          wire_serdes_dat_ser_val_i <= '0';
        else
          if (in_sel_i = '1') then
            wire_serdes_dat_ser_val_i <= '1';
            dat_o <= wire_serdes_dat_par_o;
            dat_val_o <= wire_serdes_dat_par_val_o;
          else
            wire_serdes_dat_ser_val_i <= '0';
            dat_val_o <= dat_val_i;
            dat_o <= dat_par_i;
          end if;
        end if;
      end if;
    end process;
end structure;
