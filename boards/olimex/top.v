//
// Example using the usb_hid_host core for Olimex GateMate
// based on the icesugar-pro example by nand2mario, 8/2023
//

module top (
    input clk_i,

    // UART
    //input ftdi_txd,
    //output ftdi_rxd,

    // BUTTONs
    input rstn_i,

    // LEDs
    output o_led_D1,
    output [7:0]o_led,

    // USB
    inout usb1_fpga_bd_dn,
    inout usb1_fpga_bd_dp,
    
    output usb1_fpga_pu_dn,
    output usb1_fpga_pu_dp
);

wire sys_resetn = ~rstn_i;
wire clk_usb, lock_usb;
wire [1:0] usb_type;
wire [7:0] key_modifiers, key1, key2, key3, key4;
wire [7:0] mouse_btn;
wire signed [7:0] mouse_dx, mouse_dy;
wire [63:0] hid_report;
wire usb_report, usb_conerr, game_l, game_r, game_u, game_d, game_a, game_b, game_x, game_y;
wire game_sel, game_sta;
wire usb_oe, usb_dm_i, usb_dp_i, usb_dm_o, usb_dp_o;

assign usb_fpga_pu_dn = 1'b0; // host pull down 10k
assign usb_fpga_pu_dp = 1'b0; // host pull down 10k

/* PLL for 12MHz USB */
pll12 pll_inst_usb (
    .clock_in(clk_i), // 10 MHz
    .rst_in(~rstn_i),
    .clock_out(clk_usb), // 12 MHz, 0 deg
    .locked(lock_usb)
);

usb_hid_host usb (
    .usbclk(clk_usb), .usbrst_n(sys_resetn),
    .usb_dm(usb_fpga_bd_dn),
    .usb_dp(usb_fpga_bd_dp),
    /*
    .usb_oe(usb_oe),
    .usb_dm_i(usb_dm_i), .usb_dp_i(usb_dp_i),
    .usb_dm_o(usb_dm_o), .usb_dp_o(usb_dp_o),
    .update_leds_stb(1'b1), .leds(btn[6:3]),
    */
    .typ(usb_type), .report(usb_report),
    .key_modifiers(key_modifiers), .key1(key1), .key2(key2), .key3(key3), .key4(key4),
    .mouse_btn(mouse_btn), .mouse_dx(mouse_dx), .mouse_dy(mouse_dy),
    .game_l(game_l), .game_r(game_r), .game_u(game_u), .game_d(game_d),
    .game_a(game_a), .game_b(game_b), .game_x(game_x), .game_y(game_y), 
    .game_sel(game_sel), .game_sta(game_sta),
    .conerr(usb_conerr), .dbg_hid_report(hid_report)
);
/*
assign usb_dm_i = usb_fpga_bd_dn;
assign usb_dp_i = usb_fpga_bd_dp;
assign usb_fpga_bd_dn = usb_oe ? usb_dm_o : 1'bZ;
assign usb_fpga_bd_dp = usb_oe ? usb_dp_o : 1'bZ;
*/

/*
hid_printer prt (
    .clk(clk_usb), .resetn(sys_resetn),
    .uart_tx(ftdi_rxd), .usb_type(usb_type), .usb_report(usb_report),
    .key_modifiers(key_modifiers), .key1(key1), .key2(key2), .key3(key3), .key4(key4),
    .mouse_btn(mouse_btn), .mouse_dx(mouse_dx), .mouse_dy(mouse_dy),
    .game_l(game_l), .game_r(game_r), .game_u(game_u), .game_d(game_d),
    .game_a(game_a), .game_b(game_b), .game_x(game_x), .game_y(game_y), 
    .game_sel(game_sel), .game_sta(game_sta)
);
*/

reg [6:0] report_counter;      // blinks whenever there's a report
always @(posedge clk_usb)
  if      (!sys_resetn) report_counter <= 0;
  else if (usb_report)  report_counter <= report_counter+1;

assign o_led[  7] = 0; // blue
assign o_led[  6] = report_counter[6]; // green every 128 report
assign o_led[5:4] = 0; // red orange
assign o_led[  3] = ~sys_resetn; // blue reset
assign o_led_D1 = report_counter[0]; // green every report
assign o_led[2] = report_counter[0]; // green every report
assign o_led[1:0] = usb_type; // orange, red

endmodule
