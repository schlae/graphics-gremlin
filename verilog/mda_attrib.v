// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
`default_nettype none
module mda_attrib(
    input clk,
    input[7:0] att_byte,
    input[4:0] row_addr,
    input display_enable,
    input blink_enabled,
    input blink,
    input cursor,
    input pix_in,
    output pix_out,
    output intensity_out
    );

    reg blinkdiv;
    reg[1:0] blink_old;
    wire att_inverse;
    wire att_underline;
    wire att_blink;
    wire att_nodisp;
    wire[2:0] att_fg;
    wire[2:0] att_bg;
    wire cursorblink;
    wire blink_area;
    wire vid_underline;
    wire intensity_bg;
    wire intensity_fg;
    wire alpha_dots;

    // Extract attributes from the attribute byte
    assign att_fg = att_byte[2:0];
    assign att_bg = att_byte[6:4];
    assign att_underline = (att_fg == 3'b001) & (row_addr==5'd12);
    assign intensity_bg = att_byte[7] & ~blink_enabled;
    assign intensity_fg = att_byte[3];
    assign att_inverse = (att_fg == 3'b000) & (att_bg == 3'b111);
    assign att_nodisp = (att_fg == 3'b000) & (att_bg == 3'b000);
    assign att_blink = att_byte[7];

    // Character blink is half the rate of the cursor blink
    always @ (posedge clk)
    begin
        blink_old <= {blink_old[0], blink};
        if (blink_old == 2'b01) begin
            blinkdiv <= ~blinkdiv;
        end
    end

    // Assemble all the signals to create the final video signal
    assign cursorblink = cursor & blink;
    assign blink_area = att_blink & blinkdiv & ~cursor & blink_enabled;
    assign vid_underline = (pix_in | att_underline);
    assign alpha_dots = (vid_underline & ~att_nodisp & ~blink_area) | cursorblink;
    assign pix_out = (alpha_dots ^ att_inverse) & display_enable;

    // Assign intensity signal
    assign intensity_out = (alpha_dots ? intensity_fg : intensity_bg) & display_enable;


endmodule

