// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
module cga_vgaport(
    input clk,

    input[3:0] video,

    // Analog outputs
    output[5:0] red,
    output[6:0] green,
    output[5:0] blue
    );

    reg[17:0] c;

    assign blue = c[5:0];
    assign green = {c[11:6], 1'b1}; // FIXME: 1?
    assign red = c[17:12];

    always @(posedge clk)
    begin
        case(video)
            4'h0: c <= 18'b000000_000000_000000;
            4'h1: c <= 18'b000000_000000_101010;
            4'h2: c <= 18'b000000_101010_000000;
            4'h3: c <= 18'b000000_101010_101010;
            4'h4: c <= 18'b101010_000000_000000;
            4'h5: c <= 18'b101010_000000_101010;
            4'h6: c <= 18'b101010_010101_000000; // Brown!
            4'h7: c <= 18'b101010_101010_101010;
            4'h8: c <= 18'b010101_010101_010101;
            4'h9: c <= 18'b010101_010101_111111;
            4'hA: c <= 18'b010101_111111_010101;
            4'hB: c <= 18'b010101_111111_111111;
            4'hC: c <= 18'b111111_010101_010101;
            4'hD: c <= 18'b111111_010101_111111;
            4'hE: c <= 18'b111111_111111_010101;
            4'hF: c <= 18'b111111_111111_111111;
            default: ;
        endcase
    end
endmodule
