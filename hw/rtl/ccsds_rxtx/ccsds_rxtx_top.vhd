-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rxtx_top
---- Version: 1.0.0
---- Description: CCSDS compliant RX/TX for space communications
---- TX Modulations: QAM, nPSK, OQPSK, ASK, GMSK, FSK
---- RX Performances: QAM: min Eb/N0 = XdB, max frequency shift = X Hz (Doppler + speed), max frequency shift rate = X Hz / secs (Doppler + acceleration), synchronisation, agc / dynamic range, filters capabilities, multipaths, ...
---- This is the entry point / top level entity
---- WB slave interface, RX/TX external inputs/outputs
---- Synchronized with rising edge of external clocks
-------------------------------
---- Author(s):
---- Guillaume REMBERT
-------------------------------
---- Licence:
---- MIT
-------------------------------
---- Changes list:
---- 2016/02/26: initial release - only basic RX-TX capabilities through direct R/W on WB Bus / no dynamic configuration capabilities
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;
library work;
use work.ccsds_rxtx_parameters.all;
--use work.ccsds_rxtx_constants.all;

--=============================================================================
-- Entity declaration for ccsds_rxtx_top / overall rx-tx external physical inputs and outputs
--=============================================================================
entity ccsds_rxtx_top is
  generic (
    CCSDS_RXTX_CST_RX_AUTO_ENABLED: std_logic := RX_SYSTEM_AUTO_ENABLED;
    CCSDS_RXTX_CST_RX_AUTO_EXTERNAL: std_logic := RX_SYSTEM_AUTO_EXTERNAL;
    CCSDS_RXTX_CST_RX_PHYS_SIG_QUANT_DEPTH: integer := RX_PHYS_SIG_QUANT_DEPTH;
    CCSDS_RXTX_CST_RX_DATA_BUS_SIZE: integer := RX_SYSTEM_DATA_BUS_SIZE;
    CCSDS_RXTX_CST_RX_DATA_INPUT_TYPE: integer := RX_SYSTEM_DATA_INPUT_TYPE;
    CCSDS_RXTX_CST_RX_DATA_OUTPUT_TYPE: integer := RX_SYSTEM_DATA_OUTPUT_TYPE;
    CCSDS_RXTX_CST_TX_AUTO_ENABLED: std_logic := TX_SYSTEM_AUTO_ENABLED;
    CCSDS_RXTX_CST_TX_AUTO_EXTERNAL: std_logic := TX_SYSTEM_AUTO_EXTERNAL;
    CCSDS_RXTX_CST_TX_PHYS_SIG_QUANT_DEPTH: integer := TX_PHYS_SIG_QUANT_DEPTH;
    CCSDS_RXTX_CST_TX_DATA_BUS_SIZE: integer := TX_SYSTEM_DATA_BUS_SIZE;
    CCSDS_RXTX_CST_TX_DATA_BUFFER_SIZE: integer := TX_SYSTEM_DATA_BUFFER_SIZE;
    CCSDS_RXTX_CST_TX_DATA_OUTPUT_TYPE: integer := TX_SYSTEM_DATA_OUTPUT_TYPE;
    CCSDS_RXTX_CST_TX_DATA_INPUT_TYPE: integer := TX_SYSTEM_DATA_INPUT_TYPE;
    CCSDS_RXTX_CST_WB_ADDR_BUS_SIZE: integer := RXTX_SYSTEM_WB_ADDR_BUS_SIZE;
    CCSDS_RXTX_CST_WB_DATA_BUS_SIZE: integer := RXTX_SYSTEM_WB_DATA_BUS_SIZE
  );
  port(
  -- system wide inputs
    --rst_i: in std_logic; -- implement external system reset port?
  -- system wide outputs
    irq_o: out std_logic; -- interrupt request output
  -- wishbone slave bus connections / to the master CPU
    wb_ack_o: out std_logic; -- acknowledge output / normal bus cycle termination
    wb_adr_i: in std_logic_vector(CCSDS_RXTX_CST_WB_ADDR_BUS_SIZE-1 downto 0); -- address input array
    wb_clk_i: in std_logic; -- clock input / wb operations are always on rising edge of clk
    wb_cyc_i: in std_logic; -- cycle input / valid bus cycle in progress
    wb_dat_i: in std_logic_vector(CCSDS_RXTX_CST_WB_DATA_BUS_SIZE-1 downto 0); -- data input array
    wb_dat_o: out std_logic_vector(CCSDS_RXTX_CST_WB_DATA_BUS_SIZE-1 downto 0); -- data output array
    wb_err_o: out std_logic; -- error output / abnormal bus cycle termination
    --wb_lock_i: out std_logic; -- lock input / current bus cycle is uninterruptible
    wb_rst_i: in std_logic; -- reset input
    wb_rty_o: out std_logic; -- retry output / not ready - retry bus cycle
    --wb_sel_i: in std_logic_vector(3 downto 0); -- select input array / related to wb_dat_i + wb_dat_o / indicates where valid data is placed on the array  / provide data granularity
    wb_stb_i: in std_logic; -- strobe input / slave is selected
    --wb_tga_i: in std_logic; -- address tag type / related to wb_adr_i / qualified by wb_stb_i / TBD
    --wb_tgc_i: in std_logic; -- cycle tag type / qualified by wb_cyc_i / TBD
    --wb_tgd_i: in std_logic; -- data tag type / related to wb_dat_i / ex: parity protection, ecc, timestamps
    --wb_tgd_o: out std_logic; -- data tag type / related to wb_dat_o / ex: parity protection, ecc, timestamps
    wb_we_i: in std_logic; -- write enable input / indicates if cycle is of write or read type
  -- rx inputs
    rx_clk_i: in std_logic; -- received serial or parallel samples clock
    -- for parallel samples input / I&Q sampling
    rx_i_samples_par_i: in std_logic_vector(CCSDS_RXTX_CST_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- i samples
    rx_q_samples_par_i: in std_logic_vector(CCSDS_RXTX_CST_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- q samples
    -- for parallel samples input / IF sampling
    rx_if_samples_par_i: in std_logic_vector(CCSDS_RXTX_CST_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- if samples
    -- for serial samples input / I&Q sampling
    rx_i_samples_ser_i: in std_logic; -- i samples
    rx_q_samples_ser_i: in std_logic; -- q samples
    -- for serial samples input / IF sampling
    rx_if_samples_ser_i: in std_logic; -- if samples
  -- rx outputs
    rx_clk_o: out std_logic; -- received data clock
    rx_data_par_o: out std_logic_vector(CCSDS_RXTX_CST_RX_DATA_BUS_SIZE-1 downto 0); -- received data parallel output
    rx_data_ser_o: out std_logic; -- received data serial output
    rx_ok_o: out std_logic; -- rx status indicator
  -- tx inputs
    tx_clk_i: in std_logic; -- direct data clock
    tx_data_valid_i: in std_logic; -- input data valid indicator
    tx_data_par_i: in std_logic_vector(CCSDS_RXTX_CST_TX_DATA_BUS_SIZE-1 downto 0); -- direct data parallel input
    tx_data_ser_i: in std_logic; -- direct data serial input
  -- tx outputs
    -- for parallel samples output / I&Q sampling
    tx_i_samples_par_o: out std_logic_vector(CCSDS_RXTX_CST_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- i samples
    tx_q_samples_par_o: out std_logic_vector(CCSDS_RXTX_CST_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- q samples
    -- for parallel samples output / IF sampling
    tx_if_samples_par_o: out std_logic_vector(CCSDS_RXTX_CST_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- if samples
    -- for serial samples output / I&Q sampling
    tx_i_samples_ser_o: out std_logic; -- i samples
    tx_q_samples_ser_o: out std_logic; -- q samples
    -- for serial samples output / IF sampling
    tx_if_samples_ser_o: out std_logic; -- if samples
    tx_samples_valid_o: out std_logic; -- output samples valid indicator
    tx_clk_o: out std_logic; -- emitted samples clock
    tx_ok_o: out std_logic -- tx status indicator
  );
end ccsds_rxtx_top;

--=============================================================================
-- architecture declaration / internal connections
--=============================================================================
architecture structure of ccsds_rxtx_top is
  -- components declaration
    component ccsds_rx is
      generic (
        CCSDS_RX_PHYS_SIG_QUANT_DEPTH : integer;
        CCSDS_RX_DATA_OUTPUT_TYPE: integer;
        CCSDS_RX_DATA_INPUT_TYPE: integer
      );
      port(
        rst_i: in std_logic; -- system reset
        ena_i: in std_logic; -- system enable
        clk_i: in std_logic; -- input samples clock
        i_samples_par_i: in std_logic_vector(CCSDS_RXTX_CST_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- in-phased parallel complex samples
        q_samples_par_i: in std_logic_vector(CCSDS_RXTX_CST_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- quadrature-phased parallel complex samples
        if_samples_par_i: in std_logic_vector(CCSDS_RXTX_CST_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- intermediate frequency real parallel samples
        i_samples_ser_i: in std_logic; -- in-phased serial complex samples
        q_samples_ser_i: in std_logic; -- quadrature-phased serial complex samples
        if_samples_ser_i: in std_logic; -- intermediate-frequency serial real samples
        clk_o: out std_logic; -- received data clock
        data_ser_o: out std_logic; -- received data serial output
        data_par_o: out std_logic_vector(CCSDS_RXTX_CST_RX_DATA_BUS_SIZE-1 downto 0) -- received data parallel output
      );
    end component;
    component ccsds_tx is
      generic (
        CCSDS_TX_PHYS_SIG_QUANT_DEPTH : integer;
        CCSDS_TX_DATA_OUTPUT_TYPE: integer;
        CCSDS_TX_DATA_INPUT_TYPE: integer;
        CCSDS_TX_DATA_BUFFER_SIZE: integer;
        CCSDS_TX_DATA_BUS_SIZE: integer
      );
      port(
        rst_i: in std_logic; -- system reset
        ena_i: in std_logic; -- system enable
        clk_i: in std_logic; -- transmitted data clock
        data_valid_i: in std_logic; -- transmitted data valid signal
        data_par_i: in std_logic_vector(CCSDS_RXTX_CST_TX_DATA_BUS_SIZE-1 downto 0); -- transmitted data parallel input
        data_ser_i: in std_logic; -- transmitted data serial input
        clk_o: out std_logic; -- output samples clock
        samples_valid_o: out std_logic; -- samples valid signal
        i_samples_par_o: out std_logic_vector(CCSDS_RXTX_CST_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- in-phased parallel complex samples
        q_samples_par_o: out std_logic_vector(CCSDS_RXTX_CST_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- quadrature-phased parallel complex samples
        if_samples_par_o: out std_logic_vector(CCSDS_RXTX_CST_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- intermediate frequency real parallel samples
        i_samples_ser_o: out std_logic; -- in-phased serial complex samples
        q_samples_ser_o: out std_logic; -- quadrature-phased serial complex samples
        if_samples_ser_o: out std_logic; -- -- intermediate-frequency serial real samples
        buf_full_o: out std_logic -- buffer full indicator / data received will be lost when indicating 1
      );
    end component;
    signal wire_rst: std_logic;
    signal wire_irq: std_logic;
    signal wire_rx_ok: std_logic;
    signal wire_rx_clk: std_logic;
    signal wire_rx_ena: std_logic;
    signal wire_tx_ok: std_logic;
    signal wire_tx_data_par: std_logic_vector(CCSDS_RXTX_CST_TX_DATA_BUS_SIZE-1 downto 0);
    signal wire_tx_data_ser: std_logic;
    signal wire_tx_data_valid: std_logic;
    signal wire_tx_clk: std_logic;
    signal wire_tx_ena: std_logic;
    signal wire_tx_buffer_full: std_logic;
--=============================================================================
-- architecture begin
--=============================================================================
begin
  -- components entities instantiation
    rx_001: ccsds_rx
      generic map(
        CCSDS_RX_PHYS_SIG_QUANT_DEPTH => CCSDS_RXTX_CST_RX_PHYS_SIG_QUANT_DEPTH,
        CCSDS_RX_DATA_OUTPUT_TYPE => CCSDS_RXTX_CST_RX_DATA_INPUT_TYPE,
        CCSDS_RX_DATA_INPUT_TYPE => CCSDS_RXTX_CST_RX_DATA_OUTPUT_TYPE
      )
      port map(
        rst_i => wire_rst,
        ena_i => wire_rx_ena,
        clk_i => wire_rx_clk,
        i_samples_par_i => rx_i_samples_par_i,
        q_samples_par_i => rx_q_samples_par_i,
        if_samples_par_i => rx_if_samples_par_i,
        i_samples_ser_i => rx_i_samples_ser_i,
        q_samples_ser_i => rx_q_samples_ser_i,
        if_samples_ser_i => rx_if_samples_ser_i,
        clk_o => rx_clk_o,
        data_par_o => rx_data_par_o,
        data_ser_o => rx_data_ser_o
      );
    tx_001: ccsds_tx
      generic map(
        CCSDS_TX_PHYS_SIG_QUANT_DEPTH => CCSDS_RXTX_CST_TX_PHYS_SIG_QUANT_DEPTH,
        CCSDS_TX_DATA_OUTPUT_TYPE => CCSDS_RXTX_CST_TX_DATA_INPUT_TYPE,
        CCSDS_TX_DATA_INPUT_TYPE => CCSDS_RXTX_CST_TX_DATA_OUTPUT_TYPE,
        CCSDS_TX_DATA_BUFFER_SIZE => CCSDS_RXTX_CST_TX_DATA_BUFFER_SIZE,
        CCSDS_TX_DATA_BUS_SIZE => CCSDS_RXTX_CST_TX_DATA_BUS_SIZE
      )
      port map(
        rst_i => wire_rst,
        ena_i => wire_tx_ena,
        clk_i => wire_tx_clk,
        data_valid_i => wire_tx_data_valid,
        data_par_i => wire_tx_data_par,
        data_ser_i => wire_tx_data_ser,
        clk_o => tx_clk_o,
        samples_valid_o => tx_samples_valid_o,
        i_samples_par_o => tx_i_samples_par_o,
        q_samples_par_o => tx_q_samples_par_o,
        if_samples_par_o => tx_if_samples_par_o,
        i_samples_ser_o => tx_i_samples_ser_o,
        q_samples_ser_o => tx_q_samples_ser_o,
        if_samples_ser_o => tx_if_samples_ser_o,
        buf_full_o => wire_tx_buffer_full
      );
    --=============================================================================
    -- Begin of wbstartp
    -- In charge of wishbone bus interactions + rx/tx management through it
    --=============================================================================
    -- read: wb_clk_i, wb_rst_i, wb_cyc_i, wb_stb_i, wb_dat_i, rx_clk_i, tx_clk_i
    -- write: wb_ack_o, wb_err_o, wb_rty_o, (rx_/tx_XXX:rst_i), wb_dat_o, rx_ok_o, tx_ok_o, irq_o
    -- r/w: 
    WBSTARTP : process (wb_clk_i, tx_clk_i, rx_clk_i, wire_rx_ok, wire_tx_ok)
    -- variables instantiation
    variable ccsds_rxtx_dyn_wb_state: integer range -1 to 2 := 0;
    variable ccsds_rxtx_dyn_rx_ena: std_logic := CCSDS_RXTX_CST_RX_AUTO_ENABLED;
    variable ccsds_rxtx_dyn_rx_ext: std_logic := CCSDS_RXTX_CST_RX_AUTO_EXTERNAL;
    --variable ccsds_rxtx_dyn_rx_data_input_type: integer := CCSDS_RXTX_CST_RX_DATA_INPUT_TYPE range -1 to 2;
    --variable ccsds_rxtx_dyn_rx_data_output_type: integer := CCSDS_RXTX_CST_RX_DATA_OUTPUT_TYPE range -1 to 2;
    variable ccsds_rxtx_dyn_rx_data: std_logic_vector(CCSDS_RXTX_CST_WB_DATA_BUS_SIZE-1 downto 0) := RX_SYSTEM_DATA_DEFAULT_DATA;
    variable ccsds_rxtx_dyn_tx_ena: std_logic := CCSDS_RXTX_CST_TX_AUTO_ENABLED;
    variable ccsds_rxtx_dyn_tx_ext: std_logic := CCSDS_RXTX_CST_TX_AUTO_EXTERNAL;
    variable ccsds_rxtx_dyn_tx_data: std_logic_vector(CCSDS_RXTX_CST_WB_DATA_BUS_SIZE-1 downto 0) := TX_SYSTEM_DATA_DEFAULT_DATA;
    --variable ccsds_rxtx_dyn_tx_data_input_type: integer := CCSDS_RXTX_CST_TX_DATA_INPUT_TYPE;
    --variable ccsds_rxtx_dyn_tx_data_output_type: integer := CCSDS_RXTX_CST_TX_DATA_OUTPUT_TYPE;(others => '1')
    begin
      -- on each wb clock rising edge
      if rising_edge(wb_clk_i) then
        -- wb reset signal received
        if (wb_rst_i = '1') then
          -- send reset signal to all devices
          wire_rst <= '1';
          -- reinitialize all dyn elements to default value
          ccsds_rxtx_dyn_rx_ena := CCSDS_RXTX_CST_RX_AUTO_ENABLED;
          ccsds_rxtx_dyn_tx_ena := CCSDS_RXTX_CST_TX_AUTO_ENABLED;
          ccsds_rxtx_dyn_rx_ext := CCSDS_RXTX_CST_RX_AUTO_EXTERNAL;
          ccsds_rxtx_dyn_tx_ext := CCSDS_RXTX_CST_TX_AUTO_EXTERNAL;
          ccsds_rxtx_dyn_rx_data := RX_SYSTEM_DATA_DEFAULT_DATA;
          ccsds_rxtx_dyn_tx_data := TX_SYSTEM_DATA_DEFAULT_DATA;
          ccsds_rxtx_dyn_wb_state := 0;
          -- reinitialize all outputs
          wb_ack_o <= '0';
          wb_err_o <= '0';
          wb_rty_o <= '0';
          wire_rx_ok <= '1';
          wire_rx_clk <= '0';
          wire_tx_ok <= '1';
          wire_tx_clk <= '0';
          wire_irq <= '0';
          wire_tx_data_valid <= '0';
        else
          case ccsds_rxtx_dyn_wb_state is
            -- termination of normal bus cycle
            when 1 =>
              wb_ack_o <= '1';
       	      ccsds_rxtx_dyn_wb_state := 0;
              if (ccsds_rxtx_dyn_tx_ext = '0') then
                wire_tx_data_valid <= '0';
              end if;
       	    -- error in bus cycle signaled
            when -1 =>
              wire_rx_ok <= '0';
              wire_tx_ok <= '0';
              wb_err_o <= '1';
              if (ccsds_rxtx_dyn_tx_ext = '0') then
                wire_tx_data_valid <= '0';
              end if;
      	      ccsds_rxtx_dyn_wb_state := 0;
            -- nothing to do / end of cycle / reinit all output signals to 0
            when 0 => 
              if (ccsds_rxtx_dyn_rx_ena = '0') then
                wire_rx_ok <= '0';
              else
                wire_rx_ok <= '1';
              end if;
              if (ccsds_rxtx_dyn_tx_ena = '0') then
                wire_tx_ok <= '0';
              else
                wire_tx_ok <= '1';
              end if;
              wb_ack_o <= '0';
              wb_err_o <= '0';
              wb_rty_o <= '0';
              wb_dat_o <= (others => '0');
      	      ccsds_rxtx_dyn_wb_state := 2;
       	    when 2 =>
              -- single classic standard read cycle
              if ((wb_cyc_i = '1') and (wb_stb_i = '1') and (wb_we_i = '0')) then
                if (wb_adr_i = "0000") then
                  -- classic rx cycle - forward data from rx to master
     	          ccsds_rxtx_dyn_wb_state := 1;
  	          wb_dat_o <= ccsds_rxtx_dyn_rx_data;
       	        else
        	  ccsds_rxtx_dyn_wb_state := -1;
         	end if;
              -- single write cycle
              elsif ((wb_cyc_i = '1') and (wb_stb_i = '1') and (wb_we_i = '1')) then
                -- classic tx cycle - store and forward data from master to tx
                if (wb_adr_i = "0000") then
                  -- check internal configuration
                  if (ccsds_rxtx_dyn_tx_ext = '0') then
                    if (wire_tx_buffer_full = '0') then
                      ccsds_rxtx_dyn_wb_state := 1;
                      ccsds_rxtx_dyn_tx_data := wb_dat_i;
                      wire_tx_data_valid <= '1';
                    else
                      ccsds_rxtx_dyn_wb_state := -1;
                    end if;
                  else
                    ccsds_rxtx_dyn_wb_state := -1;
                  end if;
                -- RX configuration cycle - set general rx parameters
                elsif (wb_adr_i = "0001") then
                  ccsds_rxtx_dyn_wb_state := 1;
                  ccsds_rxtx_dyn_rx_ena := wb_dat_i(0);
                  ccsds_rxtx_dyn_rx_ext := wb_dat_i(1);
                -- TX configuration cycle - set general tx parameters
                elsif (wb_adr_i = "0010") then
                  ccsds_rxtx_dyn_wb_state := 1;
                  ccsds_rxtx_dyn_tx_ena := wb_dat_i(0);
                  ccsds_rxtx_dyn_tx_ext := wb_dat_i(1);
                else
                  ccsds_rxtx_dyn_wb_state := -1;
                end if;
       	      end if;
       	    when others =>
       	      ccsds_rxtx_dyn_wb_state := -1;
          end case;
        end if;
      end if;
      --enable or disable rx/tx
      wire_rx_ena <= ccsds_rxtx_dyn_rx_ena;
      wire_tx_ena <= ccsds_rxtx_dyn_tx_ena;
      --update rx/tx status
      rx_ok_o <= wire_rx_ok;
      tx_ok_o <= wire_tx_ok;
      -- generate IRQ
      irq_o <= wire_irq;
      --RX: use external clock and data
--      if (ccsds_rxtx_dyn_rx_ext = '1') then
        --external clock
--        wire_rx_clk <= rx_clk_i;
--      else
        wire_rx_clk <= wb_clk_i;
     	  --TBD: implement internal samples forwarding from WB bus?
--      end if;
      --TX: use external clock and data
--      if (ccsds_rxtx_dyn_tx_ext = '1') then
--        wire_tx_clk <= tx_clk_i;
--        wire_tx_data_par <= tx_data_par_i;
--        wire_tx_data_ser <= tx_data_ser_i;
--      else
        -- switch to parallel input mode from WB for TX
        -- FIXME: WARNING - WISHBONE BUS HAS TO BE THE SAME SIZE FOR THE TIME BEING
        wire_tx_clk <= wb_clk_i;
        wire_tx_data_par <= ccsds_rxtx_dyn_tx_data;
--      end if;
    end process;
end structure;
--=============================================================================
-- architecture end
--=============================================================================
