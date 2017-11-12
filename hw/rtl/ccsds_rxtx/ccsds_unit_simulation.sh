#!/bin/bash

cd ./build/euryspace_0/src/ccsds_rxtx_0
HDLFILES="ccsds_rxtx_types.vhd ccsds_rxtx_functions.vhd ccsds_tx_coder_convolutional.vhd ccsds_rxtx_parameters.vhd ccsds_tx_coder_differential.vhd ccsds_rxtx_srrc.vhd ccsds_rxtx_oversampler.vhd ccsds_tx_filter.vhd ccsds_rxtx_clock_divider.vhd ccsds_tx_mapper_bits_symbols.vhd ccsds_tx_mapper_symbols_samples.vhd ccsds_tx_randomizer.vhd ccsds_rxtx_lfsr.vhd ccsds_tx_synchronizer.vhd ccsds_rxtx_constants.vhd ccsds_rxtx_serdes.vhd ccsds_rxtx_crc.vhd ccsds_tx_coder.vhd ccsds_tx_framer.vhd ccsds_tx_header.vhd ccsds_tx_footer.vhd ccsds_rxtx_buffer.vhd ccsds_rx_datalink_layer.vhd ccsds_rx_physical_layer.vhd ccsds_rx.vhd ccsds_tx_datalink_layer.vhd ccsds_tx_physical_layer.vhd ccsds_tx_manager.vhd ccsds_tx.vhd ccsds_rxtx_top.vhd ccsds_rxtx_bench.vhd"
echo "START: Importing HDL files"
ghdl -i -v $HDLFILES
echo "START: Analyzing HDL files"
ghdl -a -v $HDLFILES
echo "START: Elaborating testbench entity"
ghdl -e -v ccsds_rxtx_bench
echo "START: Running simulation with testbench entity"
ghdl -r -v ccsds_rxtx_bench --vcd=ccsds_rxtx_sim_results.vcd --stop-time=1000000ns --unbuffered 
#echo "START: Opening simulation results window"
#gtkwave /home/grembert/or1k/build_socs/build/euryspace/src/ccsds_rxtx/ccsds_rxtx_sim_results.vcd &
