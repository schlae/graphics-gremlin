// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// Copyright (c) 2023 Aitor Gomez Garcia (spark2k06)
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
`default_nettype none
module sound_top(
    // Clocks
    input clk_10m,
    input clk_14m318,
    input clk_bus,

    // Bus reset
    input busreset,

    // ISA bus
    input[19:0] bus_a,
    input bus_ior_l,
    input bus_iow_l,
    input bus_memr_l,
    input bus_memw_l,
    inout[7:0] bus_d,
    output bus_dir,
    output reg bus_rdy = 1'b1,
    output bus_0ws_l,
    input bus_aen,
    input bus_ale,

    // RAM
    output reg ram_we_l = 1'b0,
    output reg [18:0] ram_a = 19'd0,
    inout [7:0] ram_d = 8'hzz,

    // Video outputs
    output reg hsync = 1'b0,
    output reg vsync = 1'b0,
    output reg vid_en_l = 1'b0,
    output reg d_r = 1'b0,
    output reg d_g = 1'b0,
    output reg d_b = 1'b0,
    output reg d_r2 = 1'b0,
    output reg d_g2 = 1'b0,
    output reg d_b2 = 1'b0,
    output reg vga_hsync = 1'b0,
    output reg vga_vsync = 1'b0,
    output reg [5:0] red = 6'd0,
    output     [6:0] green,
    output reg [5:0] blue = 6'd0,

    // Config switches
    input switch2,
    input switch3
    );

    wire pll_lock;

    wire[7:0] bus_out;

    // Set up bus direction
    assign bus_d = (bus_dir) ? bus_out : 8'hzz;
    
    wire [6:0]snd;
    assign green = snd;
    
    sound sound1 (
        .reset(busreset),
        .clk(clk_14m318),
        .bus_a(bus_a),
        .bus_ior_l(bus_ior_l),
        .bus_iow_l(bus_iow_l),
        .bus_d(bus_d),
        .bus_out(bus_out),
        .bus_dir(bus_dir),
        .bus_aen(bus_aen),
        .opl2_snd_e(snd)
    );

endmodule
