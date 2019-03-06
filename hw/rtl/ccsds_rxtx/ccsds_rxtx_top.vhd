-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rxtx_top
---- Version: 1.0.0
---- Description: CCSDS compliant RX/TX for space communications
---- TX Modulations: BPSK, QPSK, Offset-QPSK, QAM, Offset-QAM
---- RX Performances: QAM: min Eb/N0 = XdB, max frequency shift = X Hz (Doppler + speed), max frequency shift rate = X Hz / secs (Doppler + acceleration), synchronisation, agc / dynamic range, filters capabilities, multipaths, ...
---- This is the entry point / top level entity
---- WB slave interface, RX/TX external inputs/outputs
---- Synchronized with rising edge of clocks
-------------------------------
---- Author(s):
---- Guillaume REMBERT
-------------------------------
---- Licence:
---- MIT
-------------------------------
-- TODO: additionnal modulations: ASK, FSK, GMSK, OFDM, CDMA
-- TODO: dynamic modulation and coding

-- libraries used
library ieee;
use ieee.std_logic_1164.all;
library work;
use work.ccsds_rxtx_parameters.all;
use work.ccsds_rxtx_functions.all;
--use work.ccsds_rxtx_constants.all;

--=============================================================================
-- Entity declaration for ccsds_rxtx_top / overall rx-tx external physical inputs and outputs
--=============================================================================
entity ccsds_rxtx_top is
  generic (
    CCSDS_RXTX_RX_AUTO_ENABLED: boolean := RX_SYSTEM_AUTO_ENABLED;
    CCSDS_RXTX_RX_PHYS_SIG_QUANT_DEPTH: integer := RX_PHYS_SIG_QUANT_DEPTH;
    CCSDS_RXTX_TX_AUTO_ENABLED: boolean := TX_SYSTEM_AUTO_ENABLED;
    CCSDS_RXTX_TX_AUTO_EXTERNAL: boolean := TX_SYSTEM_AUTO_EXTERNAL;
    CCSDS_RXTX_TX_PHYS_SIG_QUANT_DEPTH: integer := TX_PHYS_SIG_QUANT_DEPTH;
    CCSDS_RXTX_WB_ADDR_BUS_SIZE: integer := RXTX_SYSTEM_WB_ADDR_BUS_SIZE;
    CCSDS_RXTX_WB_DATA_BUS_SIZE: integer := RXTX_SYSTEM_WB_DATA_BUS_SIZE
  );
  port(
-- system wide inputs
    --rst_i: in std_logic; -- implement external system reset port?
-- system wide outputs
-- wishbone slave bus connections / to the master CPU
  -- wb inputs
    wb_adr_i: in std_logic_vector(CCSDS_RXTX_WB_ADDR_BUS_SIZE-1 downto 0); -- address input array
    wb_clk_i: in std_logic; -- clock input / wb operations are always on rising edge of clk
    wb_cyc_i: in std_logic; -- cycle input / valid bus cycle in progress
    wb_dat_i: in std_logic_vector(CCSDS_RXTX_WB_DATA_BUS_SIZE-1 downto 0); -- data input array
    --wb_lock_i: out std_logic; -- lock input / current bus cycle is uninterruptible
    wb_rst_i: in std_logic; -- reset input
    --wb_sel_i: in std_logic_vector(3 downto 0); -- select input array / related to wb_dat_i + wb_dat_o / indicates where valid data is placed on the array  / provide data granularity
    wb_stb_i: in std_logic; -- strobe input / slave is selected
    --wb_tga_i: in std_logic; -- address tag type / related to wb_adr_i / qualified by wb_stb_i / TBD
    --wb_tgc_i: in std_logic; -- cycle tag type / qualified by wb_cyc_i / TBD
    --wb_tgd_i: in std_logic; -- data tag type / related to wb_dat_i / ex: parity protection, ecc, timestamps
    wb_we_i: in std_logic; -- write enable input / indicates if cycle is of write or read type
  -- wb outputs
    wb_ack_o: out std_logic; -- acknowledge output / normal bus cycle termination
    wb_dat_o: out std_logic_vector(CCSDS_RXTX_WB_DATA_BUS_SIZE-1 downto 0); -- data output array
    wb_err_o: out std_logic; -- error output / abnormal bus cycle termination
    wb_rty_o: out std_logic; -- retry output / not ready - retry bus cycle
    --wb_tgd_o: out std_logic; -- data tag type / related to wb_dat_o / ex: parity protection, ecc, timestamps
-- RX connections
  -- rx inputs
    rx_clk_i: in std_logic; -- received samples clock
    rx_sam_i_i: in std_logic_vector(CCSDS_RXTX_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- i samples
    rx_sam_q_i: in std_logic_vector(CCSDS_RXTX_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- q samples
  -- rx outputs
    rx_ena_o: out std_logic; -- rx enabled status indicator
    rx_irq_o: out std_logic; -- interrupt request output / data received indicator
-- TX connections
  -- tx inputs
    tx_clk_i: in std_logic; -- output samples clock
    tx_dat_ser_i: in std_logic; -- direct data serial input
  -- tx outputs
    tx_buf_ful_o: out std_logic; -- buffer full / data overflow indicator
    tx_clk_o: out std_logic; -- emitted samples clock
    tx_ena_o: out std_logic; -- tx enabled status indicator
    tx_idl_o: out std_logic; -- idle status / data-padding indicator
    tx_sam_i_o: out std_logic_vector(CCSDS_RXTX_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- i samples
    tx_sam_q_o: out std_logic_vector(CCSDS_RXTX_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0) -- q samples
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
        CCSDS_RX_DATA_BUS_SIZE: integer
      );
      port(
        rst_i: in std_logic; -- system reset
        ena_i: in std_logic; -- system enable
        clk_i: in std_logic; -- input samples clock
        sam_i_i: in std_logic_vector(CCSDS_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- in-phased parallel complex samples
        sam_q_i: in std_logic_vector(CCSDS_RX_PHYS_SIG_QUANT_DEPTH-1 downto 0); -- quadrature-phased parallel complex samples
        dat_nxt_i: in std_logic; -- next data
        irq_o: out std_logic; -- data ready to be read / IRQ signal
        dat_o: out std_logic_vector(CCSDS_RX_DATA_BUS_SIZE-1 downto 0); -- received data parallel output
        dat_val_o: out std_logic; -- data valid
        buf_dat_ful_o: out std_logic; -- data buffer status indicator
        buf_fra_ful_o: out std_logic; -- frames buffer status indicator
        buf_bit_ful_o: out std_logic; -- bits buffer status indicator
        ena_o: out std_logic -- enabled status indicator
      );
    end component;
    component ccsds_tx is
      generic (
        CCSDS_TX_PHYS_SIG_QUANT_DEPTH : integer;
        CCSDS_TX_DATA_BUS_SIZE: integer
      );
      port(
        rst_i: in std_logic;
        ena_i: in std_logic;
        clk_i: in std_logic;
        in_sel_i: in std_logic;
        dat_val_i: in std_logic;
        dat_par_i: in std_logic_vector(CCSDS_TX_DATA_BUS_SIZE-1 downto 0);
        dat_ser_i: in std_logic;
        buf_ful_o: out std_logic;
        clk_o: out std_logic;
        idl_o: out std_logic;
        sam_i_o: out std_logic_vector(CCSDS_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
        sam_q_o: out std_logic_vector(CCSDS_TX_PHYS_SIG_QUANT_DEPTH-1 downto 0);
        ena_o: out std_logic
      );
    end component;
    signal wire_rst: std_logic;
    signal wire_rx_ena: std_logic := convert_boolean_to_std_logic(CCSDS_RXTX_RX_AUTO_ENABLED);
    signal wire_rx_data_valid: std_logic;
    signal wire_rx_data_next: std_logic := '0';
    signal wire_rx_buffer_data_full: std_logic;
    signal wire_rx_buffer_frames_full: std_logic;
    signal wire_rx_buffer_bits_full: std_logic;
    signal wire_tx_clk: std_logic;
    signal wire_tx_ena: std_logic := convert_boolean_to_std_logic(CCSDS_RXTX_TX_AUTO_ENABLED);
    signal wire_tx_ext: std_logic := convert_boolean_to_std_logic(CCSDS_RXTX_TX_AUTO_EXTERNAL);
    signal wire_tx_data_valid: std_logic := '0';
    signal wire_tx_buf_ful: std_logic;
    signal wire_rx_data: std_logic_vector(CCSDS_RXTX_WB_DATA_BUS_SIZE-1 downto 0);
    signal wire_tx_data: std_logic_vector(CCSDS_RXTX_WB_DATA_BUS_SIZE-1 downto 0) := (others => '0');

--=============================================================================
-- architecture begin
--=============================================================================
begin
  -- components entities instantiation
    rx_001: ccsds_rx
      generic map(
        CCSDS_RX_PHYS_SIG_QUANT_DEPTH => CCSDS_RXTX_RX_PHYS_SIG_QUANT_DEPTH,
        CCSDS_RX_DATA_BUS_SIZE => CCSDS_RXTX_WB_DATA_BUS_SIZE
      )
      port map(
        rst_i => wb_rst_i,
        ena_i => wire_rx_ena,
        clk_i => rx_clk_i,
        sam_i_i => rx_sam_i_i,
        sam_q_i => rx_sam_q_i,
        dat_nxt_i => wire_rx_data_next,
        irq_o => rx_irq_o,
        dat_o => wire_rx_data,
        dat_val_o => wire_rx_data_valid,
        buf_dat_ful_o => wire_rx_buffer_data_full,
        buf_fra_ful_o => wire_rx_buffer_frames_full,
        buf_bit_ful_o => wire_rx_buffer_bits_full,
        ena_o => rx_ena_o
      );
    tx_001: ccsds_tx
      generic map(
        CCSDS_TX_PHYS_SIG_QUANT_DEPTH => CCSDS_RXTX_TX_PHYS_SIG_QUANT_DEPTH,
        CCSDS_TX_DATA_BUS_SIZE => CCSDS_RXTX_WB_DATA_BUS_SIZE
      )
      port map(
        clk_i => tx_clk_i,
        rst_i => wb_rst_i,
        ena_i => wire_tx_ena,
        in_sel_i => wire_tx_ext,
        dat_val_i => wire_tx_data_valid,
        dat_par_i => wire_tx_data,
        dat_ser_i => tx_dat_ser_i,
        buf_ful_o => wire_tx_buf_ful,
        clk_o => tx_clk_o,
        idl_o => tx_idl_o,
        sam_i_o => tx_sam_i_o,
        sam_q_o => tx_sam_q_o,
        ena_o => tx_ena_o
      );
    tx_buf_ful_o <= wire_tx_buf_ful;
    --=============================================================================
    -- Begin of wbstartp
    -- In charge of wishbone bus interactions + rx/tx management through it
    --=============================================================================
    -- read: wb_clk_i, wb_rst_i, wb_cyc_i, wb_stb_i, wb_dat_i
    -- write: wb_ack_o, wb_err_o, wb_rty_o, (rx_/tx_XXX:rst_i), wb_dat_o, wire_rst, wire_irq, wire_rx_ena, wire_tx_ena
    -- r/w: wire_tx_ext
    WBSTARTP : process (wb_clk_i)
    variable ack_state: std_logic := '0';
    -- variables instantiation
    begin
      -- on each wb clock rising edge
      if rising_edge(wb_clk_i) then
        -- wb reset signal received
        if (wb_rst_i = '1') then
          -- reinitialize all dyn elements to default value
          ack_state := '0';
          wire_rx_ena <= convert_boolean_to_std_logic(CCSDS_RXTX_RX_AUTO_ENABLED);
          wire_tx_ena <= convert_boolean_to_std_logic(CCSDS_RXTX_TX_AUTO_ENABLED);
          -- reinitialize all outputs
          wire_tx_ext <= convert_boolean_to_std_logic(CCSDS_RXTX_TX_AUTO_EXTERNAL);
 	        if (CCSDS_RXTX_TX_AUTO_EXTERNAL = false) then
       	    wire_tx_data_valid <= '0';
       	  else
       	    wire_tx_data_valid <= '1';
      	  end if;
      	  wb_dat_o <= (others => '0');
          wb_ack_o <= '0';
          wb_err_o <= '0';
          wb_rty_o <= '0';
        else
          if (wb_cyc_i = '1') and (wb_stb_i = '1') then
            -- single classic standard read cycle
            if (wb_we_i = '0') then
              if (wb_adr_i = "0000") then
                -- classic rx cycle - forward data from rx to master
                if (ack_state = '0') then
                  wb_dat_o <= wire_rx_data;
                  wb_ack_o <= '0';
                  ack_state := '1';
                else
                  wb_dat_o <= (others => '0');
                  wb_ack_o <= '1';
                  ack_state := '0';
                end if;
   	          else
                wb_err_o <= '1';
                wb_rty_o <= '1';
       	      end if;
            -- single write cycle
            else
              wb_dat_o <= (others => '0');
              -- classic tx cycle - store and forward data from master to tx
              if (wb_adr_i = "0000") then
                -- check internal configuration
                if (wire_tx_ext = '0') then
                  if (wire_tx_buf_ful = '0') and (ack_state = '0') then
                    wb_ack_o <= '1';
                    ack_state := '1';
                    wire_tx_data <= wb_dat_i;
                    wire_tx_data_valid <= '1';
                  else
                    if (ack_state = '1') then
                      wire_tx_data_valid <= '0';
                      wb_ack_o <= '0';
                      ack_state := '0';
                    else
                      wb_ack_o <= '0';
                      wb_err_o <= '1';
                      wb_rty_o <= '1';
                    end if;
                  end if;
                else
                  wb_ack_o <= '0';
                  wb_err_o <= '1';
                  wb_rty_o <= '1';
                end if;
              -- RX configuration cycle - set general rx parameters
              elsif (wb_adr_i = "0001") then
                if (ack_state = '0') then
                  wire_rx_ena <= wb_dat_i(0);
                  wb_ack_o <= '1';
                  ack_state := '1';
                else
                  wb_ack_o <= '0';
                  ack_state := '0';
                end if;
                -- TX configuration cycle - set general tx parameters
              elsif (wb_adr_i = "0010") then
                if (ack_state = '0') then
                  wire_tx_ena <= wb_dat_i(0);
                  wire_tx_ext <= wb_dat_i(1);
                  wb_ack_o <= '1';
                  ack_state := '1';
                else
                  wb_ack_o <= '0';
                  ack_state := '0';
                end if;
              else
                wb_ack_o <= '0';
                wb_err_o <= '1';
                wb_rty_o <= '1';
       	      end if;
       	    end if;
       	  else
            wb_dat_o <= (others => '0');
            wb_ack_o <= '0';
            wb_err_o <= '0';
            wb_rty_o <= '0';
            ack_state := '0';
            if (wire_tx_ext = '0') then
              wire_tx_data_valid <= '0';
            else
              wire_tx_data_valid <= '1';
            end if;
          end if;
     	  end if;
      end if;
    end process;
end structure;
--=============================================================================
-- architecture end
--=============================================================================
