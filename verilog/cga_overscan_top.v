// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
`default_nettype none
module cga_overscan_top(
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

    output hdmi_red,
    output hdmi_grn,
    output hdmi_blu,
    output hdmi_int,
    output hdmi_grn_int,

    output hdmi_vs,
    output hdmi_hs,

    output hdmi_clk,

    output hdmi_de,


    // Video outputs
    // output hsync,
    // output vsync,
    // output vid_en_l,
    // output d_r,
    // output d_g,
    // output d_b,
    // output d_r2,
    // output d_g2,
    // output d_b2,
    output vga_hsync,
    output vga_vsync,
    output[5:0] red,
    output[6:0] green,
    output[5:0] blue,

    // Config switches
    input switch2,
    input switch3
    );

    wire hsync;
    wire vsync;
    wire d_r;
    wire d_g;
    wire d_b;
    wire d_r2;
    wire d_g2;
    wire d_b2;

    // Sets up the card to generate a video signal
    // that will work with a standard VGA monitor
    // connected to the VGA port.
    parameter MDA_70HZ = 0;

    wire clk_main;
    wire pll_lock;

    wire[7:0] bus_out;

    wire[3:0] video;
    wire[3:0] vga_video;

    wire composite_on;
    wire thin_font;
    wire display_enable;
    wire dbl_display_enable;

    wire[5:0] vga_red;
    wire[6:0] vga_green;
    wire[5:0] vga_blue;
    wire[6:0] comp_video;

    // Unused pins on video connector
    assign bus_0ws_l = 1'b1;
    //assign vid_en_l = 1'b0;

    // Composite mode switch
    assign composite_on = switch3;

    // Thin font switch
    assign thin_font = switch2;

    // Set up bus direction
    assign bus_d = (bus_dir) ? bus_out : 8'hzz;

    // CGA mode
    // Take our incoming 14.318MHz clock and generate the pixel clock
    // 28.636MHz: 0, 63, 5
    // Could also use an SB_PLL40_2_PAD to generate an additional
    // 14.318MHz clock without having to use a separate divider.
    wire int_clk;
    `ifdef SYNTHESIS
    SB_PLL40_PAD #(
            .FEEDBACK_PATH("SIMPLE"),
            .DIVR(0),
            .DIVF(63),
            .DIVQ(5),
            .FILTER_RANGE(1)
        ) cga_pll (
            .LOCK(pll_lock),
            .RESETB(1'b1),
            .BYPASS(1'b0),
            .PACKAGEPIN(clk_14m318),
            .PLLOUTGLOBAL(clk_main)
        );
    `else
    assign clk_main = clk_14m318;
    `endif

    // CGA digital to analog converter
    cga_vgaport vga (
        .clk(clk_main),
        .video(vga_video),
        .red(vga_red),
        .green(vga_green),
        .blue(vga_blue)
    );

    cga_hdmiport hdmi(
        .clk(clk_main),
        .video(vga_video),
        .display_enable(dbl_display_enable),
        .hsync(vga_hsync),
        .vsync(vsync),
        .hdmi_red(hdmi_red),
        .hdmi_grn(hdmi_grn),
        .hdmi_blu(hdmi_blu),
        .hdmi_grn_int(hdmi_grn_int),
        .hdmi_int(hdmi_int),
        .hdmi_hs(hdmi_hs),
        .hdmi_vs(hdmi_vs),
        .hdmi_clk(hdmi_clk),
        .hdmi_de(hdmi_de),
    );

    // Analog output mux: Either RGB or composite
    assign red = composite_on ? 6'd0 : vga_red;
    assign green = composite_on ? comp_video : vga_green;
    assign blue = composite_on ? 6'd0 : vga_blue;

    assign vga_vsync = vsync;

    cga cga1 (
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
        .bus_rdy(bus_rdy),
        .ram_we_l(ram_we_l),
        .ram_a(ram_a),
        .ram_d(ram_d),
        .hsync(hsync),
        .dbl_hsync(vga_hsync),
        .vsync(vsync),
        .video(video),
        .dbl_video(vga_video),
        .comp_video(comp_video),
        .thin_font(thin_font),
        .display_enable(display_enable),
        .dbl_display_enable(dbl_display_enable)
    );

    defparam cga1.OVERSCAN = 1;

`ifdef SYNTHESIS
    defparam cga1.BLINK_MAX = 24'd4772727;
`else
    defparam cga1.BLINK_MAX = 24'd10;
`endif

endmodule
