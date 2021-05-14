// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
`default_nettype none
module cga_pixel(
    input clk,
    input[4:0] clk_seq,
    input hres_mode,
    input grph_mode,
    input bw_mode,
    input mode_640,
    input thin_font,
    input[7:0] vram_data,
    input vram_read_char,
    input vram_read_att,
    input disp_pipeline,
    input charrom_read,
    input display_enable,
    input cursor,
    input[4:0] row_addr,
    input blink_enabled,
    input blink,
    input hsync,
    input vsync,
    input video_enabled,
    input[7:0] cga_color_reg,
    output[3:0] video
    );

    reg[7:0] attr_byte;
    reg[7:0] char_byte;
    reg[7:0] char_byte_old;
    reg[7:0] attr_byte_del;
    reg[7:0] charbits;
    reg[1:0] cursor_del;
    reg[1:0] display_enable_del;
    reg pix;
    reg pix_delay;
    reg[7:0] c0;
    reg[7:0] c1;
    wire pix_640;
    wire[10:0] rom_addr;
    wire load_shifter;

    // Character ROM
    reg[7:0] char_rom[0:4095];
    initial $readmemh("cga.hex", char_rom, 0, 4095);


    // Latch character and attribute data from VRAM
    // at appropriate times
    always @ (posedge clk)
    begin
        if (vram_read_char) begin
            char_byte <= vram_data;
            char_byte_old <= char_byte;
        end
        if (vram_read_att) begin
            attr_byte <= vram_data;
        end
    end

    // Load or shift
    assign load_shifter = (clk_seq == 5'd4);
    always @ (posedge clk)
    begin
        if (!video_enabled) begin
            c0 <= 7'd0;
            c1 <= 7'd0;
        end else if (load_shifter) begin
            c1[7] <= char_byte[7];
            c0[7] <= char_byte[6];
            c1[6] <= char_byte[5];
            c0[6] <= char_byte[4];
            c1[5] <= char_byte[3];
            c0[5] <= char_byte[2];
            c1[4] <= char_byte[1];
            c0[4] <= char_byte[0];
            c1[3] <= attr_byte[7];
            c0[3] <= attr_byte[6];
            c1[2] <= attr_byte[5];
            c0[2] <= attr_byte[4];
            c1[1] <= attr_byte[3];
            c0[1] <= attr_byte[2];
            c1[0] <= attr_byte[1];
            c0[0] <= attr_byte[0];
        end else if (clk_seq[1:0] == 2'b00) begin
            c1 <= {c1[6:0], 1'b0};
            c0 <= {c0[6:0], 1'b0};
        end
    end

    // Add a pipeline delay to the attribute byte data, cursor, and display
    // enable so they line up with the displayed character
    always @ (posedge clk)
    begin
        if (disp_pipeline) begin
            attr_byte_del <= video_enabled ? attr_byte : 8'd0;
            display_enable_del <= {display_enable_del[0], display_enable};
            cursor_del <= {cursor_del[0], cursor};
        end
    end

    // Look up character byte in our character ROM table
    assign rom_addr = {char_byte, row_addr[2:0]};
    always @ (posedge clk)
    begin
        // Only load character bits at this point
        if (charrom_read) begin
            charbits <= char_rom[{~thin_font, rom_addr}];
        end
    end

    // This must be a mux. Using a shift register causes very weird
    // issues with the character ROM and Yosys turns it into a bunch
    // of flip-flops instead of a ROM.
    always @ (*)
    begin
        if (video_enabled) begin
            // Hi-res vs low-res needs different adjustments
            case (hres_mode ? (clk_seq[3:1] + 3'd6) : (clk_seq[4:2] + 3'd7))
                5'd0: pix <= charbits[7];
                5'd1: pix <= charbits[6];
                5'd2: pix <= charbits[5];
                5'd3: pix <= charbits[4];
                5'd4: pix <= charbits[3];
                5'd5: pix <= charbits[2];
                5'd6: pix <= charbits[1];
                5'd7: pix <= charbits[0];
                default: pix <= 0;
            endcase
        end else begin
            pix <= 0;
        end
    end

    // In 640x200 mode, alternate between c0 and c1 shift register
    // outputs at specific times in the sequence
    wire[2:0] tmp_clk_seq;
    assign tmp_clk_seq = clk_seq + 3'd7;
    assign pix_640 = tmp_clk_seq[1] ? c0[7] : c1[7];

    // Add one clk cycle delay to match up pixel data with attribute byte
    // data.
    always @ (posedge clk)
    begin
        pix_delay <= pix;
    end

    // Applies video attributes, generates final video
    cga_attrib attrib (
        .clk(clk),
        .att_byte(attr_byte_del),
        .row_addr(row_addr),
        .cga_color_reg(cga_color_reg),
        .grph_mode(grph_mode),
        .bw_mode(bw_mode),
        .mode_640(mode_640),
        .display_enable(display_enable_del[0]),
        .blink_enabled(blink_enabled),
        .blink(blink),
        .cursor(cursor_del[0]),
        .hsync(hsync),
        .vsync(vsync),
        .pix_in(pix_delay),
        .c0(c0[7]),
        .c1(c1[7]),
        .pix_640(pix_640),
        .pix_out(video)
    );

endmodule
