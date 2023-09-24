module mda_hdmiport(
    input clk,
    input video,
    input intensity,

    input hsync,
    input vsync,
    input display_enable,
    
    input switch2,
    input switch3,

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

    assign hdmi_de = display_enable;
    assign hdmi_int = intensity;
    assign hdmi_grn_int = intensity;

    assign hdmi_vs = vsync;
    assign hdmi_hs = hsync;

    //Cut clock in half to display as 720x350 instead of 1440x350
    always @ ( posedge clk ) begin
        hdmi_clk <= ~hdmi_clk;
    end

    // Use external switch 1 and 2 (internally mapped as switch 2 and 3) to select display colour
    /*
        switch2	switch3	colour	r	g	b
        0	    0	    green	0	1	0
        0	    1	    yellow	1	1	0
        1	    0	    white	1	1	1
        1	    1	    red	    1	0	0
    */

    assign hdmi_red = video && (switch2 || switch3);
    assign hdmi_grn = video && ~(switch2 && switch3);
    assign hdmi_blu = video && (switch2 && ~(switch2 && switch3));

endmodule