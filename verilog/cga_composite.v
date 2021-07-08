// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
`default_nettype none
module cga_composite(
    // Clock
    input clk,

    input lclk,
    input hclk,

    input[3:0] video, // IRGB video in
    input hsync,
    input vsync_l,
    input bw_mode,

    output hsync_out,
    output vsync_out,
    output [6:0] comp_video
    );

    reg[3:0] vid_del;
    reg hsync_dly = 1'b0;
    reg vsync_dly_l = 1'b0;
    reg[3:0] hsync_counter = 4'd0;
    reg[3:0] vsync_counter = 4'd0;
    reg vsync_trig = 1'b0;

    reg[2:0] count_358 = 3'd0;
    wire clk_3m58;
    wire clk_14m3;
    reg clk_old = 1'b0;

    wire burst;
    wire csync;

    reg[6:0] grey_level;

    // Color shifter
    reg yellow_burst;
    reg red;
    reg magenta;
    wire blue;
    wire cyan;
    wire green;

    reg color_out;
    wire color_out2;

    reg hclk_old;

    always @ (posedge clk)
    begin
        hclk_old <= hclk;
    end

    // Resync the video to the falling edge of 14.318MHz
    always @ (posedge clk)
    begin
        if (clk_14m3 && !clk_old) begin
            vid_del <= video;
        end
    end

    // Delay the sync pulses
    always @ (posedge clk)
    begin
        if (hclk && !hclk_old) begin
            hsync_dly <= hsync;
            vsync_dly_l <= vsync_l;
        end
    end

    // hsync counter
    always @ (posedge clk)
    begin
        if (lclk) begin
            if (hsync_dly) begin
                if (hsync_counter == 4'd11) begin
                    hsync_counter <= 4'd0;
                end else begin
                    hsync_counter <= hsync_counter + 4'd1;
                    if ((hsync_counter + 4'd1) == 4'd2) begin
                        vsync_trig <= 1'b1;
                    end
                end
            end else begin
                hsync_counter <= 4'd0;
            end
        end else begin
            vsync_trig <= 1'b0;
        end
    end

    assign hsync_out = (hsync_counter > 4'd1) && (hsync_counter < 4'd6);
    assign burst = bw_mode ? 1'b0 : (~vsync_dly_l &
                                     ((hsync_counter == 4'd7) ||
                                      (hsync_counter == 4'd8)));

    // vsync counter
    always @ (posedge clk)
    begin
        if (vsync_trig) begin
            if (!vsync_dly_l) begin
                vsync_counter <= 4'd0;
            end else begin
                vsync_counter <= {vsync_counter[2:0], 1'b1};
            end
        end
    end

    // Positive going vsync pulse
    assign vsync_out = vsync_counter[0] & ~vsync_counter[3];

    assign csync = ~(vsync_out ^ hsync_out);

    // Generate 3.58MHz from the 28MHz clock coming in
    always @ (posedge clk)
    begin
        count_358 <= count_358 + 3'd1;
        clk_old <= clk_14m3;
    end
    assign clk_3m58 = count_358[2];
    wire clk_7m;
    assign clk_7m = count_358[1];
    assign clk_14m3 = count_358[0];

    // Create color phase clocks
    always @ (posedge clk)
    begin
        // Check for 14.318MHz rising edge
        if (!clk_14m3 && clk_old) begin
            yellow_burst <= clk_3m58;
            red <= yellow_burst;
        end
        // Check for 14.318MHz falling edge
        if (clk_14m3 && !clk_old) begin
            magenta <= red;
        end
    end
    assign blue = ~yellow_burst;
    assign cyan = ~red;
    assign green = ~magenta;

    // Color mux
    always @ (*)
    begin
        // R, G, B
        case ({vid_del[2] ^ burst, vid_del[1] ^ burst, vid_del[0]})
            3'd0: color_out <= 1'b0;
            3'd1: color_out <= blue;
            3'd2: color_out <= green;
            3'd3: color_out <= cyan;
            3'd4: color_out <= red;
            3'd5: color_out <= magenta;
            3'd6: color_out <= yellow_burst;
            3'd7: color_out <= 1'b1;
        endcase
    end

    // Black and white mode? Color is disabled.
    assign color_out2 = bw_mode ?
                        (vid_del[2:0] != 0) :
                        (color_out);

    always @ (*)
    begin
        case (vid_del[2:0])
            3'd0:  grey_level <= 7'd29;
            3'd1:  grey_level <= 7'd36;
            3'd2:  grey_level <= 7'd49;
            3'd3:  grey_level <= 7'd56;
            3'd4:  grey_level <= 7'd39;
            3'd5:  grey_level <= 7'd46;
            3'd6:  grey_level <= 7'd60;
            3'd7:  grey_level <= 7'd68;
        endcase
    end

    assign comp_video = ~csync ? 0 : (grey_level + (vid_del[3] ? 7'd31 : 7'd0) +
                        (color_out2 ? 7'd28 : 7'd0));

endmodule
