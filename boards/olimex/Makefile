TEST_CASE := usb-hid-host
TOP := top
YOSYS_PARAM := -nomult -nomx8
VERILOG_FILES := \
	top.v \
	clk_in_10MHz_out_12MHz.v \
	clk_in_10MHz_out_25MHz.v \
	../../src/usb_hid_host.v \
	../../src/usb_hid_host_rom.v \
	../../src/vga.v \
	../../src/hex_decoder_v.v
include makefile.inc
