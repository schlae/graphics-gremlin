// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
module cga_vram(
    // Clock
    input clk,

    // Lines from other logic
    // Port 0 is read/write
    input[18:0] isa_addr,
    input[7:0] isa_din,
    output[7:0] isa_dout,
    input isa_read,
    input isa_write,
    input isa_op_enable,

    // Port 1 is read only
    input[18:0] pixel_addr,
    output reg[7:0] pixel_data,
    input pixel_read,

    // Lines to RAM pins
    output reg[18:0] ram_a,
    inout[7:0] ram_d,
    output ram_ce_l,
    output ram_oe_l,
    output ram_we_l
    );

    parameter MDA_70HZ = 0;

    reg[19:0] op_addr = 20'd0;
    reg[7:0] ram_write_data = 8'd0;
    reg isa_write_old = 1'b0;
    reg[2:0] write_del = 0;

    assign ram_ce_l = 0;
    assign ram_oe_l = 0;

    assign ram_we_l = ~(write_del == 3'd4);
    assign isa_dout = ram_d;

    // Gated by clock so that we give the SRAM chip
    // some time to tristate its data output after
    // we begin the write operation. (tHZWE)
    assign ram_d = (~ram_we_l & ~clk) ? ram_write_data : 8'hZZ;

    // RAM address pin mux
    always @ (*)
    begin
        if (isa_read) begin
            ram_a <= isa_addr;
        end else if ((write_del == 3'd3) || (write_del == 3'd4)) begin
            ram_a <= op_addr;
        end else begin
            ram_a <= pixel_addr;
        end
    end

    // For edge detection of ISA writes
    always @ (posedge clk)
    begin
        isa_write_old <= isa_write;
    end

    // Address is latched on initial edge of write
    always @ (posedge clk)
    begin
        if (isa_write && !isa_write_old) begin
            op_addr <= isa_addr;
        end
    end

    // Wait a few cycles before latching data from ISA
    // bus, since the data isn't valid right away.
    always @ (posedge clk)
    begin
        if (isa_write && !isa_write_old) begin
            write_del <= 3'd1;
        end else if (write_del != 3'd0) begin
            if (write_del == 3'd7) begin
                write_del <= 3'd0;
            end else begin
                write_del <= write_del + 1;
            end
        end
    end

    always @ (posedge clk)
    begin
        if (write_del == 3'd2) begin
            ram_write_data <= isa_din;
        end
    end

    // Pixel data output mux
    always @ (posedge clk)
    begin
        if (isa_read || (write_del == 3'd3) || (write_del == 3'd4)) begin
            // The cause of CGA snow!
            pixel_data <= 8'hff;
        end else begin
            pixel_data <= ram_d;
        end
    end

endmodule
