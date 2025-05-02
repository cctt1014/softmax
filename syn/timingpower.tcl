log_begin ./syn/timingpower.log
read_liberty ./lib/sky130_fd_sc_hvl__tt_100C_3v30.lib
read_verilog ./syn/synth_softmax.yv
link_design softmax
create_clock -name Clock -period 400 {Clock}
elapsed_run_time
report_checks
report_power
report_area
log_end
exit
