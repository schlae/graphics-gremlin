// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
`default_nettype none
module hgc_pixel(
    input clk,
    input[4:0] clk_seq,
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
    input video_enabled,
    output video,
    output intensity,
    input grph_mode
    );

    reg[7:0] attr_byte;
    reg[7:0] char_byte;
    reg[7:0] char_byte_del;
    reg[7:0] char_byte_old;
    reg[7:0] attr_byte_del;
    reg[7:0] charbits;
    reg[1:0] cursor_del;
    reg[1:0] display_enable_del;
    reg pix;
    reg pix_delay;
    reg ninth_column;
    wire[11:0] rom_addr;
    reg[1:0] pix_bits;
    wire pix_750;

    // Character ROM
    reg[7:0] char_rom[0:4095];
    initial $readmemh("hgc.hex", char_rom, 0, 4095);


    // Latch character and attribute data from VRAM
    // at appropriate times
    always @ (posedge clk)
    begin
        if (vram_read_char) begin
            char_byte <= vram_data; //ES testing
            char_byte_old <= char_byte;
        end
        if (vram_read_att) begin
            attr_byte <= vram_data; //ES testing				
        end
    end
	 
    always @ (posedge clk)
        char_byte_del <= char_byte;
		  
    always @ (*)
    begin
        if (video_enabled) begin
            case ((clk_seq[4:2] + 3'd7))
                3'd0: pix_bits <= char_byte_del[7:6];
                3'd1: pix_bits <= char_byte_del[5:4];
                3'd2: pix_bits <= char_byte_del[3:2];
                3'd3: pix_bits <= char_byte_del[1:0];
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
    assign rom_addr = {row_addr[3], char_byte, row_addr[2:0]};
    always @ (posedge clk)
    begin
        // Only load character bits at this point
        if (charrom_read) begin
            charbits <= char_rom[rom_addr];
        end
    end

    // Pixel shifter
    always @ (*)
    begin
        case (clk_seq[4:1])
            5'd0: pix <= charbits[0];
            5'd1: pix <= ninth_column;
            5'd2: pix <= charbits[7];
            5'd3: pix <= charbits[6];
            5'd4: pix <= charbits[5];
            5'd5: pix <= charbits[4];
            5'd6: pix <= charbits[3];
            5'd7: pix <= charbits[2];
            5'd8: pix <= charbits[1];
            default: pix <= 0;
        endcase
    end

    // In graphics mode, alternate between the two bits from
    // the shift register outputs at specific times in the sequence
    wire[2:0] tmp_clk_seq;
    assign tmp_clk_seq = clk_seq + 3'd7;
    assign pix_750 = tmp_clk_seq[1] ? pix_bits[0] : pix_bits[1];

    // For some characters, duplicate the 8th column as the 9th column
    // (Mainly line drawing characters so they span the whole cell)
    always @ (posedge clk)
    begin
        if (charrom_read) begin
            ninth_column <= (char_byte_old[7:5] == 3'b110) ? charbits[0] : 0;
        end
    end

    // Add one clk cycle delay to match up pixel data with attribute byte
    // data.
    always @ (posedge clk)
    begin
        pix_delay <= pix;
    end

    // Applies video attributes, generates final video
    hgc_attrib attrib (
        .clk(clk),
        .att_byte(attr_byte_del),
        .row_addr(row_addr),
        .display_enable(display_enable_del[1]),
        .blink_enabled(blink_enabled),
        .blink(blink),
        .cursor(cursor_del[1]),
        .pix_in(pix_delay),
        .pix_out(video),
        .intensity_out(intensity),
        .grph_mode(grph_mode),
        .pix_750(pix_750)
		  
    );

endmodule
