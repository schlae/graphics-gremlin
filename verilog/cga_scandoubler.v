// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
`default_nettype none
module cga_scandoubler(
    input clk,
    input line_reset,
    input[3:0] video,
    output reg dbl_hsync,
    output[3:0] dbl_video
    );

    reg sclk = 1'b0;
    reg[9:0] hcount_slow;
    reg[9:0] hcount_fast;
    reg line_reset_old = 1'b0;

    wire[9:0] addr_a;
    wire[9:0] addr_b;

    reg[3:0] data_a;
    reg[3:0] data_b;

    reg[3:0] scan_ram_a [1023:0];
    reg[3:0] scan_ram_b [1023:0];

    reg select = 1'b0;

    // VGA 640x480@60Hz has pix clk of 25.175MHz. Ours is 28.6364MHz,
    // so it is not quite an exact match. 896 clocks per line gives us
    // an horizontal rate of 31.96KHz which is close to 31.78KHz (spec).

    // Vertical lines are doubled, so 262 * 2 = 524 which matches exactly.

    always @ (posedge clk)
    begin
        line_reset_old <= line_reset;
    end

    // Double scanned horizontal counter
    always @ (posedge clk)
    begin
        if (line_reset & ~line_reset_old) begin
            hcount_fast <= 11'd0;
        end else begin
            if (hcount_fast == 10'd911) begin
                hcount_fast <= 10'd0;
            end else begin
                hcount_fast <= hcount_fast + 11'd1;
            end

            // Fixed doubled hsync
            if (hcount_fast == 10'd720) begin
                dbl_hsync <= 1;
            end
            if (hcount_fast == (10'd720 + 10'd160)) begin
                dbl_hsync <= 0;
            end
        end
    end

    // Standard scan horizontal counter
    always @ (posedge clk)
    begin
        sclk <= ~sclk;
        if (line_reset & ~line_reset_old) begin
            hcount_slow <= 10'd0;
        end else if (sclk) begin
            hcount_slow <= hcount_slow + 10'd1;
        end
    end

    // Select latch lets us swap between line store RAMs A and B
    always @ (posedge clk)
    begin
        if (line_reset & ~line_reset_old) begin
            select = ~select;
        end
    end

    assign addr_a = select ? hcount_slow : hcount_fast;
    assign addr_b = select ? hcount_fast : hcount_slow;

    // RAM A
    always @ (posedge clk)
    begin
        if (select) begin
            scan_ram_a[(addr_a)] <= video;
        end
        data_a <= scan_ram_a[addr_a];
    end

    // RAM B
    always @ (posedge clk)
    begin
        if (!select) begin
            scan_ram_b[(addr_b)] <= video;
        end
        data_b <= scan_ram_b[addr_b];
    end

    assign dbl_video = select ? data_b : data_a;

endmodule
