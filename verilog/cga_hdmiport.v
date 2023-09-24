module cga_hdmiport(
    input clk,
    input[3:0] video,
    input display_enable,

    input hsync,
    input vsync,

    output hdmi_red,
    output hdmi_grn,
    output hdmi_blu,
    output hdmi_int,
    output hdmi_grn_int,

    output hdmi_vs,
    output hdmi_hs,

    output hdmi_clk,

    output hdmi_de,

    );

    assign hdmi_clk = clk;

    assign hdmi_de = display_enable;

    assign hdmi_vs = vsync;
    assign hdmi_hs = hsync;

    assign hdmi_red = video[2];
    assign hdmi_blu = video[0];
    assign hdmi_int = video[3];

    assign hdmi_grn = video[1] ^ (hdmi_red & video[1] & (hdmi_blu ^ 1) & (hdmi_int ^ 1));
    assign hdmi_grn_int = hdmi_int ^ (hdmi_red & video[1] & (hdmi_blu ^ 1) & (hdmi_int ^ 1));
    
endmodule