// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
module hgc_vram(
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
    output[7:0] pixel_data,
    input pixel_read,

    // Lines to RAM pins
    output reg[18:0] ram_a,
    inout[7:0] ram_d,
    output ram_ce_l,
    output ram_oe_l,
    output ram_we_l
    );

    parameter HGC_70HZ = 1;

    wire ram_write;
    reg[2:0] isa_phase = 3'd0;
    reg isa_write_old = 0;
    reg isa_read_old = 0;
    reg[19:0] op_addr = 20'd0;
    reg[7:0] op_data = 8'd0;
    reg op_write_queued = 0;
    reg op_read_queued = 0;
    reg[7:0] read_data_isa = 8'h0;
    reg[7:0] read_data_pixel = 8'h0;
    reg[7:0] ram_data_out = 8'h00;
    reg[2:0] write_del = 0;

    assign ram_ce_l = 0;
    assign ram_oe_l = 0;

    assign ram_write = (isa_phase == 3'd2) || (isa_phase == 3'd4);
    assign ram_we_l = ~(ram_write & ~pixel_read);
    assign isa_dout = read_data_isa;
    assign pixel_data = read_data_pixel;

    // Gated by clock so that we give the SRAM chip
    // some time to tristate its data output after
    // we begin the write operation. (tHZWE)
    assign ram_d = (~ram_we_l & (~clk | (isa_phase == 3'd4))) ? ram_data_out : 8'hZZ;

    // RAM address pin mux
    always @ (*)
    begin
        if (pixel_read) begin
            ram_a <= pixel_addr;
        end else if ((isa_phase == 3'd2) || (isa_phase == 3'd4)) begin
            ram_a <= op_addr;
        end else if (isa_read && isa_op_enable) begin
            ram_a <= isa_addr;
        end else begin
            ram_a <= 19'h0;
        end
    end

    // For edge detector
    always @ (posedge clk)
    begin
        isa_write_old <= isa_write;
        isa_read_old <= isa_read;
    end

    // Address is latched on initial edge of read or write signal
    always @ (posedge clk)
    begin
        if ((isa_write && ~isa_write_old) || (isa_read && ~isa_read_old)) begin
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

    // Write data (from host PC) is latched on final edge of write signal
    // We cheat and latch it after the initial edge plus a delay
    always @ (posedge clk)
    begin
        if (write_del == 3'd2) begin
            op_data <= isa_din;
            op_write_queued <= 1;
        end else if ((isa_phase == 3'd4)) begin
            op_write_queued <= 0;
        end
    end

    // Read operation triggered on initial edge of read signal
    always @ (posedge clk)
    begin
        if (isa_read && !isa_read_old) begin
            op_read_queued <= 1;
        end else if ((isa_phase == 3'd5)) begin
            op_read_queued <= 0;
        end
    end

    // ISA bus access state machine
    // State 0: idle, waiting for read or write to trip.
    //          reads data for slower clocks
    // State 1: read addr phase (only for faster clocks)
    // State 2: write addr phase
    // State 4: write completion phase
    // State 5: read completion phase

    always @ (posedge clk)
    begin
        if (!isa_op_enable) begin
            isa_phase <= 3'd0;
        end else begin
            case (isa_phase)
                3'd0: begin
                        // Read signal is active, so start read phase
                        if (op_read_queued) begin
                            if (HGC_70HZ == 1) begin
                                // At faster PLL clock, delay SRAM
                                // read by 1 cycle to allow for more
                                // address setup time.
                                isa_phase <= 3'd1;
                            end else begin
                                // At slower PLL clock, shorten SRAM
                                // read cycle so we don't run out
                                // of ISA bus cycle time.
                                read_data_isa <= ram_d;
                                isa_phase <= 3'd5; // was 1
                            end
                        // A write is queued, so start write phase
                        end else if (op_write_queued) begin
                            isa_phase <= 3'd2;
                            ram_data_out <= op_data;
                        end
                    end
                3'd1: begin // Extra read cycle for fast PLL clocks
                        read_data_isa <= ram_d;
                        isa_phase <= 3'd5;
                end
                3'd2: begin // Write phase
                        isa_phase <= 3'd4;
                    end
                3'd4: isa_phase <= 3'd0;
                3'd5: isa_phase <= 3'd0;
                default: isa_phase <= 3'd0;
            endcase
        end
    end

    // Pixel read port is much simpler.
    always @ (posedge clk)
    begin
        if (pixel_read) begin
            read_data_pixel <= ram_d;
        end
    end

endmodule
