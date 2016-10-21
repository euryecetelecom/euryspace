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
    CCSDS_RX_DATA_BUS_SIZE: integer := 32
  );
  port(
    rst_i: in std_logic; -- system reset input
    ena_i: in std_logic; -- system enable input
    clk_i: in std_logic; -- input samples clock
    i_samples_i: in std_logic_vector(CCSDS_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- in-phased parallel complex samples
    q_samples_i: in std_logic_vector(CCSDS_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- quadrature-phased parallel complex samples
    data_next_i: in std_logic; -- next data
    data_o: out std_logic_vector(CCSDS_RX_DATA_BUS_SIZE-1 downto 0); -- received data parallel output
    irq_o: out std_logic; -- data ready to be read / IRQ signal
    data_valid_o: out std_logic; -- data valid
    -- Monitoring outputs
    data_buffer_full_o: out std_logic; -- data buffer status indicator
    frames_buffer_full_o: out std_logic; -- frames buffer status indicator
    bits_buffer_full_o: out std_logic; -- bits buffer status indicator
    enabled_o: out std_logic -- enabled status indicator
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
      data_i: in std_logic_vector(CCSDS_RX_DATA_BUS_SIZE-1 downto 0);
      data_o: out std_logic_vector(CCSDS_RX_DATA_BUS_SIZE-1 downto 0);
      data_buffer_full_o: out std_logic;
      frames_buffer_full_o: out std_logic;
      bits_buffer_full_o: out std_logic
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
      i_samples_i: in std_logic_vector(CCSDS_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      q_samples_i: in std_logic_vector(CCSDS_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
      data_o: out std_logic_vector(CCSDS_RX_DATA_BUS_SIZE-1 downto 0)
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
      data_i => wire_data_m,
      data_o => data_o,
      data_buffer_full_o => data_buffer_full_o,
      frames_buffer_full_o => frames_buffer_full_o,
      bits_buffer_full_o => bits_buffer_full_o
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
      i_samples_i => i_samples_i,
      q_samples_i => q_samples_i,
      data_o => wire_data_m
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
          enabled_o <= '1';
        else
          wire_clk_i <= '0';
          enabled_o <= '0';
        end if;
      end process;
end structure;
