-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rx
---- Version: 1.0.0
---- Description:
---- TO BE DONE
-------------------------------
---- Author(s):
---- Guillaume REMBERT, guillaume.rembert@euryecetelecom.com
-------------------------------
---- Licence:
---- MIT
-------------------------------
---- Changes list:
---- 2015/11/17: initial release
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;

-- unitary rx external physical inputs and outputs
entity ccsds_rx is
  generic (
    CCSDS_RX_PHYS_SIG_QUANT_DEPTH : integer := 16;
    CCSDS_RX_DATA_OUTPUT_TYPE: integer := 0;
    CCSDS_RX_DATA_INPUT_TYPE: integer := 0;
    CCSDS_RX_DATA_BUS_SIZE: integer := 32
  );
  port(
    rst_i: in std_logic; -- system reset input
    ena_i: in std_logic; -- system enable input
    clk_i: in std_logic; -- input samples clock
    i_samples_par_i: in std_logic_vector(CCSDS_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- in-phased parallel complex samples
    q_samples_par_i: in std_logic_vector(CCSDS_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- quadrature-phased parallel complex samples
    if_samples_par_i: in std_logic_vector(CCSDS_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- intermediate frequency real parallel samples
    i_samples_ser_i: in std_logic; -- in-phased serial complex samples
    q_samples_ser_i: in std_logic; -- quadrature-phased serial complex samples
    if_samples_ser_i: in std_logic; -- intermediate-frequency serial real samples
    clk_o: out std_logic; -- received data clock
    data_par_o: out std_logic_vector(CCSDS_RX_DATA_BUS_SIZE-1 downto 0); -- received data parallel output
    data_ser_o: out std_logic -- received data serial output
  );
end ccsds_rx;

architecture structure of ccsds_rx is
  component ccsds_rx_datalink_layer is
    generic(
      CCSDS_RX_DATALINK_DATA_BUS_SIZE : integer
    );
    port(
      clk_i: in std_logic;
      clk_o: out std_logic;
      rst_i: in std_logic;
      data_par_i: in std_logic_vector(CCSDS_RX_DATA_BUS_SIZE-1 downto 0);
      data_ser_i: in std_logic;
      data_par_o: out std_logic_vector(CCSDS_RX_DATA_BUS_SIZE-1 downto 0);
      data_ser_o: out std_logic
    );
  end component;
  component ccsds_rx_physical_layer is
    generic(
      CCSDS_RX_PHYSICAL_SIG_QUANT_DEPTH : integer;
      CCSDS_RX_PHYSICAL_DATA_BUS_SIZE : integer
    );
    port(
      clk_i: in std_logic;
      clk_o: out std_logic;
      rst_i: in std_logic;
      i_samples_par_i: in std_logic_vector(CCSDS_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      q_samples_par_i: in std_logic_vector(CCSDS_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      if_samples_par_i: in std_logic_vector(CCSDS_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      i_samples_ser_i: in std_logic;
      q_samples_ser_i: in std_logic;
      if_samples_ser_i: in std_logic;
      data_par_o: out std_logic_vector(CCSDS_RX_DATA_BUS_SIZE-1 downto 0);
      data_ser_o: out std_logic
    );
  end component;
  
  signal wire_data_par: std_logic_vector(CCSDS_RX_DATA_BUS_SIZE-1 downto 0);
  signal wire_data_ser: std_logic;
  signal wire_clk_m: std_logic;
  signal wire_clk_i: std_logic;
	
begin
  rx_datalink_layer_1: ccsds_rx_datalink_layer
    generic map(
      CCSDS_RX_DATALINK_DATA_BUS_SIZE => CCSDS_RX_DATA_BUS_SIZE
    )
    port map(
      clk_i => wire_clk_m,
      clk_o => clk_o,
      rst_i => rst_i,
      data_par_i => wire_data_par,
      data_ser_i => wire_data_ser,
      data_par_o => data_par_o,
      data_ser_o => data_ser_o
    );
  rx_physical_layer_1: ccsds_rx_physical_layer
    generic map(
      CCSDS_RX_PHYSICAL_SIG_QUANT_DEPTH => CCSDS_RX_PHYS_SIG_QUANT_DEPTH,
      CCSDS_RX_PHYSICAL_DATA_BUS_SIZE => CCSDS_RX_DATA_BUS_SIZE
    )
    port map(
      clk_i => wire_clk_i,
      clk_o => wire_clk_m,
      rst_i => rst_i,
      i_samples_par_i => i_samples_par_i,
      q_samples_par_i => q_samples_par_i,
      if_samples_par_i => if_samples_par_i,
      i_samples_ser_i => i_samples_ser_i,
      q_samples_ser_i => q_samples_ser_i,
      if_samples_ser_i => if_samples_ser_i,
      data_par_o => wire_data_par,
      data_ser_o => wire_data_ser
    );
    --=============================================================================
    -- Begin of enablep
    -- Enable/disable clk forwarding
    --=============================================================================
    -- read: clk_i, ena_i
    -- write: wire_clk_i
    -- r/w: 
    ENABLEP : process (clk_i, ena_i)
      begin
        if (ena_i = '1') then
          wire_clk_i <= clk_i;
        else
          wire_clk_i <= '0';
        end if;
      end process;
end structure;
