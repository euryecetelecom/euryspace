-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rx
---- Version: 1.0.0
---- Description:
---- TO BE DONE
-------------------------------
---- Author(s):
---- Guillaume REMBERT
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
    CCSDS_RX_DATA_BUS_SIZE: integer := 32
  );
  port(
    -- inputs
    clk_i: in std_logic; -- input samples clock
    dat_nxt_i: in std_logic; -- next data
    ena_i: in std_logic; -- system enable input
    rst_i: in std_logic; -- system reset input
    sam_i_i: in std_logic_vector(CCSDS_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- in-phased parallel complex samples
    sam_q_i: in std_logic_vector(CCSDS_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- quadrature-phased parallel complex samples
    -- outputs
    buf_bit_ful_o: out std_logic; -- bits buffer status indicator
    buf_dat_ful_o: out std_logic; -- data buffer status indicator
    buf_fra_ful_o: out std_logic; -- frames buffer status indicator
    dat_o: out std_logic_vector(CCSDS_RX_DATA_BUS_SIZE-1 downto 0); -- received data parallel output
    dat_val_o: out std_logic; -- data valid
    ena_o: out std_logic; -- enabled status indicator
    irq_o: out std_logic -- data ready to be read / IRQ signal
  );
end ccsds_rx;

architecture structure of ccsds_rx is
  component ccsds_rx_datalink_layer is
    generic(
      CCSDS_RX_DATALINK_DATA_BUS_SIZE : integer
    );
    port(
      clk_i: in std_logic;
      rst_i: in std_logic;
      dat_i: in std_logic_vector(CCSDS_RX_DATA_BUS_SIZE-1 downto 0);
      dat_o: out std_logic_vector(CCSDS_RX_DATA_BUS_SIZE-1 downto 0);
      buf_dat_ful_o: out std_logic;
      buf_fra_ful_o: out std_logic;
      buf_bit_ful_o: out std_logic
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
      sam_i_i: in std_logic_vector(CCSDS_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      sam_q_i: in std_logic_vector(CCSDS_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      dat_o: out std_logic_vector(CCSDS_RX_DATA_BUS_SIZE-1 downto 0)
    );
  end component;
  
  signal wire_data_m: std_logic_vector(CCSDS_RX_DATA_BUS_SIZE-1 downto 0);
  signal wire_clk_m: std_logic;
  signal wire_clk_i: std_logic;
	
begin
  rx_datalink_layer_1: ccsds_rx_datalink_layer
    generic map(
      CCSDS_RX_DATALINK_DATA_BUS_SIZE => CCSDS_RX_DATA_BUS_SIZE
    )
    port map(
      clk_i => wire_clk_m,
      rst_i => rst_i,
      dat_i => wire_data_m,
      dat_o => dat_o,
      buf_dat_ful_o => buf_dat_ful_o,
      buf_fra_ful_o => buf_fra_ful_o,
      buf_bit_ful_o => buf_bit_ful_o
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
      sam_i_i => sam_i_i,
      sam_q_i => sam_q_i,
      dat_o => wire_data_m
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
          ena_o <= '1';
        else
          wire_clk_i <= '0';
          ena_o <= '0';
        end if;
      end process;
end structure;
