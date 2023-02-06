// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
`default_nettype none
module mda_top(
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
    output bus_rdy,
    output bus_0ws_l,
    input bus_aen,
    input bus_ale,

    // RAM
    output ram_we_l,
    output[18:0] ram_a,
    inout[7:0] ram_d,

    // Video outputs
    output hsync,
    output vsync,
    output vid_en_l,
    output d_r,
    output d_g,
    output d_b,
    output d_r2,
    output d_g2,
    output d_b2,
    output vga_hsync,
    output vga_vsync,
    output[5:0] red,
    output[6:0] green,
    output[5:0] blue,

    // Config switches
    input switch2,
    input switch3
    );

    wire clk_main;
    wire pll_lock;

    wire[7:0] bus_out;

    wire video;
    wire intensity;

    // Unused pins on video connector
    assign bus_rdy = 1'b1;
    assign bus_0ws_l = 1'b1;
    assign vid_en_l = 1'b0;
    assign d_r = 1'b0;
    assign d_g = 1'b0;
    assign d_b = 1'b0;
    assign d_r2 = 1'b0;

    assign d_g2 = intensity;
    assign d_b2 = video;

    assign vga_hsync = hsync;
    assign vga_vsync = vsync;

    // Set up bus direction
    assign bus_d = (bus_dir) ? bus_out : 8'hzz;


    // Take our incoming 10MHz clock and generate the pixel clock
    // 33MHz: 0, 105, 5
        `ifdef SYNTHESIS
    SB_PLL40_PAD #(
        .FEEDBACK_PATH("SIMPLE"),
        .DIVR(0),
        .DIVF(105),
        .DIVQ(5),
        .FILTER_RANGE(1)
    ) mda_pll (
        .LOCK(pll_lock),
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .PACKAGEPIN(clk_10m),
        .PLLOUTGLOBAL(clk_main)
    );
    `else
    assign clk_main = clk_10m;
    `endif

    mda_vgaport vga (
        .clk(clk_main),
        .video(video),
        .intensity(intensity),
        .red(red),
        .green(green),
        .blue(blue)
    );

    mda mda1 (
        .clk(clk_main),
        .bus_a(bus_a),
        .bus_ior_l(bus_ior_l),
        .bus_iow_l(bus_iow_l),
        .bus_memr_l(bus_memr_l),
        .bus_memw_l(bus_memw_l),
        .bus_d(bus_d),
        .bus_out(bus_out),
        .bus_dir(bus_dir),
        .bus_aen(bus_aen),
        .ram_we_l(ram_we_l),
        .ram_a(ram_a),
        .ram_d(ram_d),
        .hsync(hsync),
        .vsync(vsync),
        .intensity(intensity),
        .video(video)
    );

    defparam mda1.MDA_70HZ = 0;
    defparam mda1.BLINK_MAX = 24'd5280000;

endmodule
