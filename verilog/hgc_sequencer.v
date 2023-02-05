// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
`default_nettype none
module hgc_sequencer(
    input clk,
    output[4:0] clk_seq,
    output vram_read,
    output vram_read_a0,
    output vram_read_char,
    output vram_read_att,
    output crtc_clk,
    output charrom_read,
    output disp_pipeline,
    output isa_op_enable,
    input grph_mode
    );

    parameter HGC_70HZ = 0;

    reg crtc_clk_int = 1'b0;
    reg[4:0] clkdiv = 5'b0;

    // Sequencer: times internal operations
    always @ (posedge clk)
    begin
        if (grph_mode)
            if (clkdiv == 5'd31) begin
                clkdiv <= 5'd0;
                crtc_clk_int <= 1'b1;
            end else begin
                clkdiv <= clkdiv + 1;
                crtc_clk_int <= 1'b0;
            end
        else
            if (clkdiv == 5'd17) begin
                clkdiv <= 5'd0;
                crtc_clk_int <= 1'b1;
            end else begin
                clkdiv <= clkdiv + 1;
                crtc_clk_int <= 1'b0;
            end
    end

    // Control signals based on the sequencer state
    assign vram_read = grph_mode ? (clkdiv == 5'd1) || (clkdiv == 5'd2) || (clkdiv == 5'd3) ||
                       (clkdiv == 5'd17) || (clkdiv == 5'd18) || (clkdiv == 5'd19) :
                       ((clkdiv == 5'd1) || (clkdiv == 5'd2) || (clkdiv == 5'd3)
                        || (clkdiv == 5'd4));

    assign vram_read_a0 = grph_mode ? (clkdiv == 5'd2) || (clkdiv == 5'd18) :
                          (clkdiv == 5'd3);

    assign vram_read_char = grph_mode ? (clkdiv == 5'd2) || (clkdiv == 5'd18) :
                            (clkdiv == 5'd3);

    assign vram_read_att = grph_mode ? (clkdiv == 5'd3) || (clkdiv == 5'd19) :
                           (clkdiv == 5'd4);

    assign charrom_read = (clkdiv == 5'd1); // Only for text
    assign disp_pipeline = (clkdiv == 5'd4); // Only for text
    assign crtc_clk = crtc_clk_int;
    assign clk_seq = clkdiv;
    // Leave a gap of at least 2 cycles between the end of ISA operation and
    // vram_read. This is because an ISA operation takes 3 cycles.
    // Stupid hack: 70Hz needs an extra cycle. 50Hz can't tolerate
    // an extra cycle.
    if (HGC_70HZ) begin
        assign isa_op_enable = (clkdiv > 5'd6) && (clkdiv < 5'd16);
    end else begin
        assign isa_op_enable = (clkdiv > 5'd5) && (clkdiv < 5'd16);
    end


endmodule

