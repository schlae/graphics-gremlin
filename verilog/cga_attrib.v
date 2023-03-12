// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
`default_nettype none
module cga_attrib(
    input clk,
    input[7:0] att_byte,
    input[4:0] row_addr,
    input[7:0] cga_color_reg,
    input grph_mode,
    input bw_mode,
    input mode_640,
    input tandy_16_mode,
    input display_enable,
    input blink_enabled,
    input blink,
    input cursor,
    input hsync,
    input vsync,
    input pix_in,
    input c0,
    input c1,
    input pix_640,
    input [3:0] pix_tandy,
    input [3:0] tandy_bordercol,
    input tandy_color_4,
    input tandy_color_16,
    output reg[3:0] pix_out,
    output wire overscan
    );

    reg blinkdiv;
    reg[1:0] blink_old;
    wire att_blink;
    wire[3:0] att_fg;
    wire[3:0] att_bg;
    wire cursorblink;
    wire blink_area;
    wire alpha_dots;
    wire mux_a;
    wire mux_b;
    wire shutter;
    wire selblue;
    wire[3:0] rgbi;
    wire[3:0] active_area;

    // Extract attributes from the attribute byte
    assign att_fg = att_byte[3:0];
    assign att_bg = blink_enabled ? {1'b0, att_byte[6:4]} : att_byte[7:4];
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
    assign blink_area = ~(blink_enabled & att_blink & ~cursor) | ~blinkdiv;
    assign alpha_dots = (pix_in & blink_area) | cursorblink;

    // Determine mux A and mux B inputs for selecting output colors.
    assign mux_a = ~display_enable |
                   (grph_mode ?
                   ((tandy_16_mode | tandy_color_16) ? 0 : (~(~mode_640 & (c0 | c1)))) :
                    ~alpha_dots);
    assign mux_b = grph_mode | ~display_enable;

    // Shutter closes when video is blanked during sync
    assign shutter = (hsync | vsync) | ((mode_640 & ~tandy_color_4) ? ~(display_enable & pix_640) : 1'b0);

    // Blue palette selection bit
    assign selblue = bw_mode ? c0 : cga_color_reg[5];

	 assign active_area = tandy_color_4 ? {1'b0, c1, c0, 1'b0} :
	 (tandy_16_mode | tandy_color_16) ? pix_tandy : {cga_color_reg[4], c1, c0, selblue};
	 
	 assign overscan = (mux_b & mux_a);
    	 
    always @ (*)
    begin
        if (shutter) begin
            pix_out <= 4'b0;
        end else begin
            case ({mux_b, mux_a})
                2'b00: pix_out <= att_fg; // Text foreground
                2'b01: pix_out <= att_bg; // Text background
                2'b10: pix_out <= active_area; // Graphics
                2'b11: pix_out <= (tandy_16_mode | tandy_color_16) ? tandy_bordercol : cga_color_reg[3:0]; // Overscan color
            endcase
        end
    end

endmodule

