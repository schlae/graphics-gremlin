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
    input tandy_16_mode,
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
    reg[1:0] pix_bits;
    reg[1:0] pix_bits_old;
    reg[3:0] tandy_bits;
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

    // Fetch pixel data for graphics modes
    wire [2:0]muxin;
    assign muxin = hres_mode ? (clk_seq[3:1] + 3'd6) : (clk_seq[4:2] + 3'd7);
    always @ (*)
    begin
        if (video_enabled) begin
            // Hi-res vs low-res needs different adjustments
            // Normal CGA is low res only in graphics mode
            // Tandy uses "high res" mode for both 320x200x16
            // and 640x200x4 color modes
            case (muxin)
                3'd0: pix_bits <= char_byte[7:6];
                3'd1: pix_bits <= char_byte[5:4];
                3'd2: pix_bits <= char_byte[3:2];
                3'd3: pix_bits <= char_byte[1:0];
                3'd4: pix_bits <= attr_byte[7:6];
                3'd5: pix_bits <= attr_byte[5:4];
                3'd6: pix_bits <= attr_byte[3:2];
                3'd7: pix_bits <= attr_byte[1:0];
                default: pix_bits <= 2'b0;
            endcase
        end else begin
            pix_bits <= 2'b0;
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

    // In 640x200 mode, alternate between the two bits from
    // the shift register outputs at specific times in the sequence
    wire[2:0] tmp_clk_seq;
    assign tmp_clk_seq = clk_seq + 3'd7;
    assign pix_640 = tmp_clk_seq[1] ? pix_bits[0] : pix_bits[1];

    // In Tandy 320x200x16 mode, concatenate two adjacent pixels
    wire temp;
    assign temp = clk_seq[1:0] == 2'b00;
    always @ (posedge clk)
    begin
        if (clk_seq[0]) begin
            if (clk_seq[1]) begin
                tandy_bits <= {pix_bits_old, pix_bits};
            end else begin
                pix_bits_old <= pix_bits;
            end
        end
    end

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
        .tandy_16_mode(tandy_16_mode),
        .display_enable(display_enable_del[0]),
        .blink_enabled(blink_enabled),
        .blink(blink),
        .cursor(cursor_del[0]),
        .hsync(hsync),
        .vsync(vsync),
        .pix_in(pix_delay),
        .c0(pix_bits[0]),
        .c1(pix_bits[1]),
        .pix_640(pix_640),
        .pix_tandy(tandy_bits),
        .pix_out(video)
    );

endmodule
