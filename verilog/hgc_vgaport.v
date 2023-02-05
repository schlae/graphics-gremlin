// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
module hgc_vgaport(
    input clk,

    input video,
    input intensity,

    // Analog outputs
    output[5:0] red,
    output[6:0] green,
    output[5:0] blue
    );

    reg[5:0] r;
    reg[5:0] g;

    assign red = r;
    assign green = {g, 1'b0};
    assign blue = 6'd0;

    always @(posedge clk)
    begin
        case({video, intensity})
            2'd0: begin
                r <= 6'd0;
                g <= 6'd0;
            end
            2'd1: begin
                r <= 6'd16;
                g <= 6'd12;
            end
            2'd2: begin
                r <= 6'd48;
                g <= 6'd21;
            end
            2'd3: begin
                r <= 6'd63;
                g <= 6'd27;
            end
            default: ;
        endcase
    end
endmodule
