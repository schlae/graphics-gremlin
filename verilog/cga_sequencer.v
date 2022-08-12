// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
`default_nettype none
module cga_sequencer(
    input clk,
    output[4:0] clk_seq,
    output vram_read,
    output vram_read_a0,
    output vram_read_char,
    output vram_read_att,
    input hres_mode,
    output crtc_clk,
    output charrom_read,
    output disp_pipeline,
    output isa_op_enable,
    output hclk,
    output lclk,
    input tandy_16_gfx
    );

    wire crtc_clk_int;
    reg[4:0] clkdiv = 5'b0;

    // Sequencer: times internal operations
    always @ (posedge clk)
    begin
        if (clkdiv == 5'd31) begin
            clkdiv <= 5'd0;
        end else begin
            clkdiv <= clkdiv + 1;
        end
    end

    // For 80 column text, we do everything twice for a complete clkdiv cycle.
    // For 40 column text, we do everything once for a complete clkdiv cycle.
    assign lclk = (clkdiv == 5'd0);
    assign hclk = (clkdiv == 5'd0) || (clkdiv == 5'd16);

    assign crtc_clk_int = (clkdiv == 5'd0) || (hres_mode ? (clkdiv == 5'd16) : 0);

    // Control signals based on the sequencer state
    assign vram_read = (clkdiv == 5'd1) || (clkdiv == 5'd2) || (clkdiv == 5'd3) ||
                       (clkdiv == 5'd17) || (clkdiv == 5'd18) || (clkdiv == 5'd19);
    assign vram_read_a0 = (clkdiv == 5'd2) || (clkdiv == 5'd18);
    assign vram_read_char = (clkdiv == 5'd2) || (hres_mode ? (clkdiv == 5'd18) : 0);
    assign vram_read_att = (clkdiv == 5'd3) || (hres_mode ? (clkdiv == 5'd19) : 0);
    assign charrom_read = (clkdiv == 5'd3) || (hres_mode ? (clkdiv == 5'd19) : 0);// 3 and 19?
    assign disp_pipeline = (clkdiv == (tandy_16_gfx ? 5'd7 : 5'd4)) || (hres_mode ? (clkdiv == (tandy_16_gfx ? 5'd23 : 5'd20)) : 0);
    assign crtc_clk = crtc_clk_int;
    assign clk_seq = clkdiv;
    // Leave a gap of at least 2 cycles between the end of ISA operation and
    // vram_read. This is because an ISA operation takes 3 cycles.
    assign isa_op_enable = ((clkdiv > 5'd4) && (clkdiv < 5'd15)) ||
                           ((clkdiv > 5'd20) && (clkdiv < 5'd31));

endmodule

