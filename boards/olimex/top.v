//
// Example using the usb_hid_host core for Olimex GateMate
// based on the icesugar-pro example by nand2mario, 8/2023
//

module top 
#(
    parameter C_report_bytes = 64, // 8:usual gamepad, 20:xbox360
    parameter C_disp_bits=128,
)
(
    input clk_i,

    // UART
    //input ftdi_txd,
    //output ftdi_rxd,

    // BUTTONs
    input rstn_i,

    output [3:0] o_r,
    output [3:0] o_g,
    output [3:0] o_b,
    output o_vsync,
    output o_hsync,
    output [7:0] o_led,

    // LEDs
    output o_led_D1,
    output [7:0]o_led,

    // USB
    inout usb1_fpga_bd_dn,
    inout usb1_fpga_bd_dp,
    
    output usb1_fpga_pu_dn,
    output usb1_fpga_pu_dp
);

wire sys_resetn = rstn_i;
wire clk_usb, clk_pix, lock_usb, lock_pix;
wire [1:0] usb_type;
wire [7:0] key_modifiers, key1, key2, key3, key4;
wire [7:0] mouse_btn;
wire signed [7:0] mouse_dx, mouse_dy;
wire [63:0] hid_report;
wire usb_report, usb_conerr, game_l, game_r, game_u, game_d, game_a, game_b, game_x, game_y;
wire game_sel, game_sta;
wire usb_oe, usb_dm_i, usb_dp_i, usb_dm_o, usb_dp_o;

wire [2:0] S_valid;
wire [C_report_bytes*8-1:0] S_report[0:2];
reg  [C_disp_bits-1:0] R_display;

assign usb1_fpga_pu_dn = 1'b0; // host pull down 10k
assign usb1_fpga_pu_dp = 1'b0; // host pull down 10k

/* PLL for 12MHz USB */
pll12 pll_inst_usb (
    .clock_in(clk_i), // 10 MHz
    .rst_in(rstn_i),
    .clock_out(clk_usb), // 12 MHz, 0 deg
    .locked(lock_usb)
);

pll25 pll_inst_pix (
    .clock_in(clk_i),       //  10 MHz reference
    .clock_out(clk_pix),    //  25 MHz, 0 deg
    .locked(lock_pix)
);

usb_hid_host usb (
    .usbclk(clk_usb), .usbrst_n(sys_resetn),
    .usb_dm(usb1_fpga_bd_dn),
    .usb_dp(usb1_fpga_bd_dp),
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
assign usb_dm_i = usb1_fpga_bd_dn;
assign usb_dp_i = usb1_fpga_bd_dp;
assign usb1_fpga_bd_dn = usb_oe ? usb_dm_o : 1'bZ;
assign usb1_fpga_bd_dp = usb_oe ? usb_dp_o : 1'bZ;
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

parameter C_color_bits = 16; 

wire [9:0] x;
wire [9:0] y;
// for reverse screen:
wire [9:0] rx = 636-x;
wire [C_color_bits-1:0] color;
hex_decoder_v
#(
    .c_data_len(C_disp_bits),
    .c_row_bits(4), // 2**n digits per row (4*2**n bits/row) 3->32, 4->64, 5->128, 6->256 
    .c_grid_6x8(0), // NOTE: TRELLIS needs -abc9 option to compile
    .c_font_file("hex_font.mem"),
    //.c_x_bits(8),
    //.c_y_bits(4),
    .c_color_bits(C_color_bits)
)
hex_decoder_v_inst
(
    .clk(clk_pix),
    .data(hid_report),
    .x(rx[9:2]),
    .y(y[5:2]),
    .color(color)
);

assign o_r = color[15:12];
assign o_g = color[10:7];
assign o_b = color[4:1];

// VGA signal generator
wire [7:0] vga_r, vga_g, vga_b;
assign vga_r = {color[15:11],color[11],color[11],color[11]};
assign vga_g = {color[10:5],color[5],color[5]};
assign vga_b = {color[4:0],color[0],color[0],color[0]};

wire vga_hsync, vga_vsync, vga_blank;

vga
vga_instance
(
.clk_pixel(clk_pix),
.clk_pixel_ena(1'b1),
.test_picture(1'b0), // enable test picture generation
.beam_x(x),
.beam_y(y),
.vga_hsync(o_hsync),
.vga_vsync(o_vsync),
.vga_blank(vga_blank)
);

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
