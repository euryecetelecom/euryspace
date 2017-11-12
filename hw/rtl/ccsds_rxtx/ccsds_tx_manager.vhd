-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_manager
---- Version: 1.0.0
---- Description:
---- In charge of internal clocks generation + forwarding to reduce power draw + select TX input data
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
---- 2016/11/05: add clock generator sub-component
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;

--=============================================================================
-- Entity declaration for ccsds_tx / unitary tx manager inputs and outputs
--=============================================================================
entity ccsds_tx_manager is
    generic(
      constant CCSDS_TX_MANAGER_BITS_PER_SYMBOL: integer;
      constant CCSDS_TX_MANAGER_MODULATION_TYPE: integer;
      constant CCSDS_TX_MANAGER_DATALINK_OVERHEAD_RATIO: integer := 4;
      constant CCSDS_TX_MANAGER_PARALLELISM_MAX_RATIO: integer := 16;
      constant CCSDS_TX_MANAGER_OVERSAMPLING_RATIO: integer;
      constant CCSDS_TX_MANAGER_DATA_BUS_SIZE : integer
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
      clk_bit_o: out std_logic;
      clk_dat_o: out std_logic;
      clk_sam_o: out std_logic;
      clk_sym_o: out std_logic;
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
  component ccsds_rxtx_clock_divider is
    generic(
      CCSDS_RXTX_CLOCK_DIVIDER: integer
    );
    port(
      clk_i: in std_logic;
      rst_i: in std_logic;
      clk_o: out std_logic
    );
  end component;

-- internal constants
  -- for simulation only / cannot be used when synthesizing
  constant CCSDS_TX_MANAGER_DEBUG: std_logic := '0';
--------------------------------
-- Clocks ratios computations --
--------------------------------
-- clk_dat
---- clk_bit = clk_dat / parallelism * data_link_overhead_ratio
------ clk_sym = clk_bit * data_bus_size / (2 * bits_per_symbol)
-------- clk_sam = clk_sym * oversampling_ratio
  constant CCSDS_TX_MANAGER_SAMPLES_TO_SYMBOLS_RATIO: integer := CCSDS_TX_MANAGER_OVERSAMPLING_RATIO;
  constant CCSDS_TX_MANAGER_SAMPLES_TO_BITS_RATIO: integer := CCSDS_TX_MANAGER_MODULATION_TYPE*CCSDS_TX_MANAGER_SAMPLES_TO_SYMBOLS_RATIO*CCSDS_TX_MANAGER_DATA_BUS_SIZE/(CCSDS_TX_MANAGER_BITS_PER_SYMBOL*2);
  constant CCSDS_TX_MANAGER_SAMPLES_TO_DATA_RATIO: integer := CCSDS_TX_MANAGER_SAMPLES_TO_BITS_RATIO*CCSDS_TX_MANAGER_DATALINK_OVERHEAD_RATIO/CCSDS_TX_MANAGER_PARALLELISM_MAX_RATIO;

-- interconnection signals
  signal wire_serdes_dat_par_o: std_logic_vector(CCSDS_TX_MANAGER_DATA_BUS_SIZE-1 downto 0);
  signal wire_serdes_dat_par_val_o: std_logic;
  signal wire_serdes_dat_ser_val_i: std_logic;
  signal wire_clk_dat: std_logic;
  signal wire_rst_clk: std_logic;

  begin
-- presynthesis checks
	  CHKMANAGERP0: if (CCSDS_TX_MANAGER_DEBUG = '1') generate
		  process
		  begin
			  report "INFO: TX CLOCK FREQUENCY HAS TO BE " & integer'image(CCSDS_TX_MANAGER_SAMPLES_TO_DATA_RATIO) & " x WB DATA CLOCK" severity note;
			  wait;
		  end process;
	  end generate CHKMANAGERP0;
-- components instanciation and mapping
    clock_divider_bits_001: ccsds_rxtx_clock_divider
      generic map(
        CCSDS_RXTX_CLOCK_DIVIDER => CCSDS_TX_MANAGER_SAMPLES_TO_BITS_RATIO
      )
      port map(
        clk_i => clk_i,
        rst_i => wire_rst_clk,
        clk_o => clk_bit_o
      );
    clock_divider_dat_001: ccsds_rxtx_clock_divider
      generic map(
        CCSDS_RXTX_CLOCK_DIVIDER => CCSDS_TX_MANAGER_SAMPLES_TO_DATA_RATIO
      )
      port map(
        clk_i => clk_i,
        rst_i => wire_rst_clk,
        clk_o => wire_clk_dat
      );
    clock_divider_sam_001: ccsds_rxtx_clock_divider
      generic map(
        CCSDS_RXTX_CLOCK_DIVIDER => 1
      )
      port map(
        clk_i => clk_i,
        rst_i => wire_rst_clk,
        clk_o => clk_sam_o
      );
    clock_divider_sym_001: ccsds_rxtx_clock_divider
      generic map(
        CCSDS_RXTX_CLOCK_DIVIDER => CCSDS_TX_MANAGER_SAMPLES_TO_SYMBOLS_RATIO
      )
      port map(
        clk_i => clk_i,
        rst_i => wire_rst_clk,
        clk_o => clk_sym_o
      );
    serdes_001: ccsds_rxtx_serdes
      generic map(
        CCSDS_RXTX_SERDES_DEPTH => CCSDS_TX_MANAGER_DATA_BUS_SIZE
      )
      port map(
        clk_i => wire_clk_dat,
        dat_par_i => (others => '0'),
        dat_par_val_i => '0',
        dat_ser_i => dat_ser_i,
        dat_ser_val_i => wire_serdes_dat_ser_val_i,
        rst_i => rst_i,
        dat_par_o => wire_serdes_dat_par_o,
        dat_par_val_o => wire_serdes_dat_par_val_o
      );

    ena_o <= ena_i;
    wire_rst_clk <= not(ena_i);
    clk_dat_o <= wire_clk_dat;
    --=============================================================================
    -- Begin of selectp
    -- Input selection
    --=============================================================================
    -- read: rst_i, ena_i, in_sel_i, dat_val_i
    -- write: dat_o, dat_val_o, wire_serdes_dat_ser_val_i
    -- r/w: 
    SELECTP : process (wire_clk_dat, ena_i)
    -- variables instantiation
    begin
      -- on each clock rising edge
      if rising_edge(wire_clk_dat) and (ena_i = '1') then
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
