// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//

// behavioral model of IS61C5128AL SRAM
module is61c5128(
    input[18:0] address,
    inout[7:0] data,
    input ce_l,
    input oe_l,
    input we_l
    );

    wire array_out;
    wire[7:0] data_out;
    wire[7:0] data_in_delay;
    wire[7:0] debug_data0;
    wire data_dir;

    wire ce_delay;
    wire oe_delay;
    wire we_delay;
    wire[18:0] addr_delay;
    integer i;
    // Truncated data array for simulation speed
    reg [7:0] data_array[0:1024];

    initial begin
        for (i = 0; i < 1024; i++) begin
            data_array[i] = i & 8'hFF;
        end
    end

    assign debug_data0 = data_array[10'h00];

    assign #10 addr_delay = address;
    assign #2 ce_delay = ~ce_l; // 2ns tLZCS
    assign oe_delay = ~oe_l; // 0ns min tLZOE
    assign #3 we_delay = ~we_l; // 3ns tLZWE
    assign #1 data_in_delay = data; // This makes the 0ns hold time work

    // Tristate buffer
    assign data_dir = ce_delay & oe_delay & ~we_delay;
    assign data = data_dir ? data_out : 8'hzz;

    assign data_out = data_array[addr_delay[10:0]];

    always @ (posedge we_l) begin
        data_array[addr_delay[10:0]] <= data_in_delay;
    end

endmodule

