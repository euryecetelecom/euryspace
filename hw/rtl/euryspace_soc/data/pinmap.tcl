#
# Clock (internal) / Reset (push button 0)
#
set_location_assignment PIN_J15 -to rst_n_pad_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to rst_n_pad_i
set_location_assignment PIN_R8 -to sys_clk_pad_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sys_clk_pad_i

#
# UART0: PINS RX <-> GPIO_124 (n°27) / TX <-> GPIO_126 (n°29)
#
set_location_assignment PIN_N15 -to uart0_srx_pad_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to uart0_srx_pad_i
set_location_assignment PIN_L14 -to uart0_stx_pad_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to uart0_stx_pad_o

#
# CCSDS_RXTX0: PINS
#
#RX EXTERNAL IN/OUT
#FIXME: CHANGE ASSIGNATION / TBD as clk (yet push button 1)
#set_location_assignment PIN_E1 -to ccsds_rxtx0_rx_clk_i
#set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ccsds_rxtx0_rx_clk_i
#Switch 0 as i serial samples
#set_location_assignment PIN_M1 -to ccsds_rxtx0_rx_sam_i_i
#set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ccsds_rxtx0_rx_sam_i_i
#Switch 1 as q serial samples
#set_location_assignment PIN_T8 -to ccsds_rxtx0_rx_sam_q_i
#set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ccsds_rxtx0_rx_sam_q_i
#LED 0 as RX enabled
set_location_assignment PIN_A15 -to ccsds_rxtx0_rx_ena_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ccsds_rxtx0_rx_ena_o
#LED 1 as demodulated data clk
#set_location_assignment PIN_A13 -to ccsds_rxtx0_rx_clk_o
#set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ccsds_rxtx0_rx_clk_o
#LED 2 as serial demodulated data
#set_location_assignment PIN_B13 -to ccsds_rxtx0_rx_data_ser_o
#set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ccsds_rxtx0_rx_data_ser_o
#TX EXTERNAL IN/OUT
#GPIO_00 as external clk input
set_location_assignment PIN_D3 -to ccsds_rxtx0_tx_clk_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ccsds_rxtx0_tx_clk_i
#GPIO_01 as external serial data input
set_location_assignment PIN_C3 -to ccsds_rxtx0_tx_dat_ser_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ccsds_rxtx0_tx_dat_ser_i
#GPIO_O27 as ??
#set_location_assignment PIN_E10 -to ccsds_rxtx0_tx_sam_val_o
#set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ccsds_rxtx0_tx_samples_valid_o
#GPIO_O29 as LSB i samples output
set_location_assignment PIN_B11 -to ccsds_rxtx0_tx_sam_i_o[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ccsds_rxtx0_tx_sam_i_o[0]
#GPIO_O31 as LSB q samples output
set_location_assignment PIN_D11 -to ccsds_rxtx0_tx_sam_q_o[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ccsds_rxtx0_tx_sam_q_o[0]
#GPIO_O33 as samples clk output
set_location_assignment PIN_B12 -to ccsds_rxtx0_tx_clk_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ccsds_rxtx0_tx_clk_o
#LED 7 as TX enabled
set_location_assignment PIN_L3 -to ccsds_rxtx0_tx_ena_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ccsds_rxtx0_tx_ena_o

#
# GPIO0 => LEDS
#
#set_location_assignment PIN_A15 -to gpio0_io[0]
set_location_assignment PIN_A13 -to gpio0_io[1]
set_location_assignment PIN_B13 -to gpio0_io[2]
set_location_assignment PIN_A11 -to gpio0_io[3]
set_location_assignment PIN_D1 -to gpio0_io[4]
set_location_assignment PIN_F3 -to gpio0_io[5]
set_location_assignment PIN_B1 -to gpio0_io[6]
#set_location_assignment PIN_L3 -to gpio0_io[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to gpio0_io[*]

#
# GPIO1: Switches + Push buttons
#
# Switches
#set_location_assignment PIN_M1  -to gpio1_i[0]
#set_location_assignment PIN_T8  -to gpio1_i[1]
#set_location_assignment PIN_B9  -to gpio1_i[2]
#set_location_assignment PIN_M15 -to gpio1_i[3]
# Push buttons
#set_location_assignment PIN_J15 -to gpio1_i[4]
#set_location_assignment PIN_E1 -to gpio1_i[5]
#set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to gpio1_i[*]

#
# I2C0: Connected to the EEPROM
#
set_location_assignment PIN_F2 -to i2c0_scl_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to i2c0_scl_io
set_location_assignment PIN_F1 -to i2c0_sda_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to i2c0_sda_io

#
# SPI0: Connected to the EPCS
#
set_global_assignment -name RESERVE_FLASH_NCE_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name RESERVE_DATA0_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name RESERVE_DATA1_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name RESERVE_DCLK_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_location_assignment PIN_C1 -to spi0_mosi_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to spi0_mosi_o
set_location_assignment PIN_H2 -to spi0_miso_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to spi0_miso_i
set_location_assignment PIN_H1 -to spi0_sck_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to spi0_sck_o
set_location_assignment PIN_D2 -to spi0_ss_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to spi0_ss_o

#
# SDRAM
#
set_location_assignment PIN_P2 -to sdram_a_pad_o[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_a_pad_o[0]
set_location_assignment PIN_N5 -to sdram_a_pad_o[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_a_pad_o[1]
set_location_assignment PIN_N6 -to sdram_a_pad_o[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_a_pad_o[2]
set_location_assignment PIN_M8 -to sdram_a_pad_o[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_a_pad_o[3]
set_location_assignment PIN_P8 -to sdram_a_pad_o[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_a_pad_o[4]
set_location_assignment PIN_T7 -to sdram_a_pad_o[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_a_pad_o[5]
set_location_assignment PIN_N8 -to sdram_a_pad_o[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_a_pad_o[6]
set_location_assignment PIN_T6 -to sdram_a_pad_o[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_a_pad_o[7]
set_location_assignment PIN_R1 -to sdram_a_pad_o[8]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_a_pad_o[8]
set_location_assignment PIN_P1 -to sdram_a_pad_o[9]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_a_pad_o[9]
set_location_assignment PIN_N2 -to sdram_a_pad_o[10]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_a_pad_o[10]
set_location_assignment PIN_N1 -to sdram_a_pad_o[11]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_a_pad_o[11]
set_location_assignment PIN_L4 -to sdram_a_pad_o[12]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_a_pad_o[12]

set_location_assignment PIN_G2 -to sdram_dq_pad_io[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_dq_pad_io[0]
set_location_assignment PIN_G1 -to sdram_dq_pad_io[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_dq_pad_io[1]
set_location_assignment PIN_L8 -to sdram_dq_pad_io[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_dq_pad_io[2]
set_location_assignment PIN_K5 -to sdram_dq_pad_io[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_dq_pad_io[3]
set_location_assignment PIN_K2 -to sdram_dq_pad_io[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_dq_pad_io[4]
set_location_assignment PIN_J2 -to sdram_dq_pad_io[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_dq_pad_io[5]
set_location_assignment PIN_J1 -to sdram_dq_pad_io[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_dq_pad_io[6]
set_location_assignment PIN_R7 -to sdram_dq_pad_io[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_dq_pad_io[7]
set_location_assignment PIN_T4 -to sdram_dq_pad_io[8]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_dq_pad_io[8]
set_location_assignment PIN_T2 -to sdram_dq_pad_io[9]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_dq_pad_io[9]
set_location_assignment PIN_T3 -to sdram_dq_pad_io[10]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_dq_pad_io[10]
set_location_assignment PIN_R3 -to sdram_dq_pad_io[11]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_dq_pad_io[11]
set_location_assignment PIN_R5 -to sdram_dq_pad_io[12]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_dq_pad_io[12]
set_location_assignment PIN_P3 -to sdram_dq_pad_io[13]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_dq_pad_io[13]
set_location_assignment PIN_N3 -to sdram_dq_pad_io[14]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_dq_pad_io[14]
set_location_assignment PIN_K1 -to sdram_dq_pad_io[15]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_dq_pad_io[15]

set_location_assignment PIN_R6 -to sdram_dqm_pad_o[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_dqm_pad_o[0]
set_location_assignment PIN_T5 -to sdram_dqm_pad_o[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_dqm_pad_o[1]

set_location_assignment PIN_M7 -to sdram_ba_pad_o[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_ba_pad_o[0]
set_location_assignment PIN_M6 -to sdram_ba_pad_o[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_ba_pad_o[1]

set_location_assignment PIN_L1 -to sdram_cas_pad_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_cas_pad_o

set_location_assignment PIN_L7 -to sdram_cke_pad_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_cke_pad_o

set_location_assignment PIN_P6 -to sdram_cs_n_pad_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_cs_n_pad_o

set_location_assignment PIN_L2 -to sdram_ras_pad_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_ras_pad_o

set_location_assignment PIN_C2 -to sdram_we_pad_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_we_pad_o

set_location_assignment PIN_R4 -to sdram_clk_pad_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sdram_clk_pad_o

#ADC
#set_location_assignment PIN_B10 -to spi1_mosi_o
#set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to spi1_mosi_o
#set_location_assignment PIN_A9 -to spi1_miso_i
#set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to spi1_miso_i
#set_location_assignment PIN_B14 -to spi1_sck_o
#set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to spi1_sck_o
#set_location_assignment PIN_A10 -to spi1_ss_o
#set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to spi1_ss_o
#GPIO_2[0] PIN_A14
#GPIO_2[1] PIN_B16
#GPIO_2[2] PIN_C14
#GPIO_2[3] PIN_C16
#GPIO_2[4] PIN_C15
#GPIO_2[5] PIN_D16
#GPIO_2[6] PIN_D15
#GPIO_2[7] PIN_D14
#GPIO_2[8] PIN_F15
#GPIO_2[9] PIN_F16
#GPIO_2[10] PIN_F14
#GPIO_2[11] PIN_G16
#GPIO_2[12] PIN_G15
#GPIO_2_IN[0] PIN_E15
#GPIO_2_IN[1] PIN_E16
#GPIO_2_IN[2] PIN_M16
