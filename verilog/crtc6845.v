// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
`default_nettype none
module crtc6845(
    input clk,
    input divclk,

    // ISA bus
    input cs,
    input a0,
    input write,
    input read,
    input[7:0] bus,
    output[7:0] bus_out,

    input lock,

    // Video control signals
    output hsync,
    output vsync,
    output display_enable,
    output display_enable_mda,
    output cursor,
    output [13:0] mem_addr,
    output [4:0] row_addr,
    output line_reset);

    parameter H_TOTAL = 0;
    parameter H_DISP = 0;
    parameter H_SYNCPOS = 0;
    parameter H_SYNCWIDTH = 0;
    parameter V_TOTAL = 0;
    parameter V_TOTALADJ = 0;
    parameter V_DISP = 0;
    parameter V_SYNCPOS = 0;
    parameter V_MAXSCAN = 0;
    parameter C_START = 0;
    parameter C_END = 0;

    reg[4:0] cur_addr;
    reg[7:0] bus_out;

    // Address register
    always @ (posedge clk) begin
        if (~a0 & write & cs) begin
            cur_addr <= bus[4:0];
        end
    end

    // Register file
    always @ (posedge clk) begin
        if (a0 & write & cs & (~lock | (cur_addr > 5'd9))) begin
            case (cur_addr)
                5'd0: h_total <= bus;
                5'd1: h_disp <= bus;
                5'd2: h_syncpos <= bus;
                5'd3: h_syncwidth <= bus[3:0];
                5'd4: v_total <= bus[6:0];
                5'd5: v_totaladj <= bus[4:0];
                5'd6: v_disp <= bus[6:0];
                5'd7: v_syncpos <= bus[6:0];
                // Register 8 not implemented
                5'd9: v_maxscan <= bus[4:0];
                5'd10: c_start <= bus[6:0];
                5'd11: c_end <= bus[4:0];
                5'd12: start_a[13:8] <= bus[5:0];
                5'd13: start_a[7:0] <= bus;
                5'd14: cursor_a[13:8] <= bus[5:0];
                5'd15: cursor_a[7:0] <= bus;
                default: ;
            endcase
        end
    end
    // TODO: Add light pen register (optional)
    always @ (*)
    begin
        case (cur_addr)
            5'd0: bus_out <= h_total;
            5'd1: bus_out <= h_disp;
            5'd2: bus_out <= h_syncpos;
            5'd3: bus_out <= h_syncwidth;
            5'd4: bus_out <= v_total;
            5'd5: bus_out <= v_totaladj;
            5'd6: bus_out <= v_disp;
            5'd7: bus_out <= v_syncpos;
            5'd8: bus_out <= 8'h00;
            5'd9: bus_out <= v_maxscan;
            5'd10: bus_out <= c_start;
            5'd11: bus_out <= c_end;
            5'd12: bus_out <= {2'b00, start_a[13:8]};
            5'd13: bus_out <= start_a[7:0];
            5'd14: bus_out <= {2'b00, cursor_a[13:8]};
            5'd15: bus_out <= cursor_a[7:0];
            5'd16: bus_out <= 8'h00; // Light pen regs
            5'd17: bus_out <= 8'h00;
            default: bus_out <= 8'h00;
        endcase;
    end

// TODO: parameterize these defaults
    reg [7:0] h_total = H_TOTAL;         //R0 97
    reg [7:0] h_disp = H_DISP;           //R1 80
    reg [7:0] h_syncpos = H_SYNCPOS;     //R2 82
    reg [3:0] h_syncwidth = H_SYNCWIDTH; //R3 15

    reg [6:0] v_total = V_TOTAL;       //R4 25
    reg [4:0] v_totaladj = V_TOTALADJ; //R5 6
    reg [6:0] v_disp = V_DISP;         //R6 25
    reg [6:0] v_syncpos = V_SYNCPOS;   //R7 25
    reg [4:0] v_maxscan = V_MAXSCAN;       //R9 13

    reg [6:0] c_start = C_START;     //R10 11
    reg [4:0] c_end = C_END;       //R11 12

    reg [13:0] start_a = 14'd0;    //R13/R14

    reg [13:0] cursor_a = 14'd92;  //R14/R15

    // Counters
    reg [7:0] h_count = 8'd0;
    reg [3:0] h_synccount = 4'd1; // Must start at 1
    reg [4:0] v_scancount = 5'd0;
    reg [6:0] v_rowcount = 7'd0;
    reg [3:0] v_synccount = 4'd0;
    reg [4:0] cursor_counter = 5'd0; // Cursor blink


    wire [4:0] next_v_scancount;
    wire [13:0] ma = 14'd0;
    reg [13:0] ma_rst = 14'd0; // Column reset of memory address

    reg vs = 1'b0;
    reg hs = 1'b0;
    reg hdisp = 1'b1;
    reg hdisp_hdmi = 1'b1;
    reg vdisp = 1'b1;

    wire cur_on;
    wire blink;

    wire h_end;
    wire v_end;

    assign vsync = vs;
    assign hsync = hs;
    assign display_enable = hdisp & vdisp;
    assign display_enable_mda = hdisp_hdmi & vdisp;

    assign row_addr = v_scancount;

    assign h_end = (h_count == h_total);

    assign line_reset = h_end;

    // Horizontal counter
    always @ (posedge clk)
    begin
        if (divclk) begin

            if (h_count == h_total) begin
                h_count <= 8'd0;
                hdisp <= 1'b1;
            end else begin
                h_count <= h_count + 1;

                //hdisp_hdmi is used to generate another display_enable_hdmi as the existing display_enable has an issue of the screen being shifted to the right by one character
                if (h_count == 0) begin
                    hdisp_hdmi <= 1'b1;
                end

                // Blanking
                if (h_count + 1 == h_disp) begin
                    hdisp <= 1'b0;
                end

                if (h_count == h_disp) begin
                    hdisp_hdmi <= 1'b0;
                end

                // Sync output
                if (h_count + 1 == h_syncpos) begin
                    hs <= 1'b1;
                end
            end
        end

        // Horizontal sync timer
        if (divclk & hs) begin
            if (h_synccount == h_syncwidth) begin
                h_synccount <= 4'b1;
                hs <= 1'b0;
            end else begin
                h_synccount <= h_synccount + 4'b1;
            end
        end
    end


    assign v_end = (v_rowcount == v_total) &
                   (v_scancount == v_maxscan + v_totaladj);
    // Vertical counter
    always @ (posedge clk)
    begin
        if (divclk & (h_count == h_total)) begin // was h_syncpos

            if (v_rowcount != v_total) begin
                // Vertical count event
                if (v_scancount != v_maxscan) begin
                    v_scancount <= v_scancount + 1;
                end else begin
                    v_scancount <= 0;
                    v_rowcount <= v_rowcount + 1;

                    // Handle vertical pulse
                    if (v_rowcount + 1 == v_syncpos) begin
                        vs <= 1'b1;
                    end

                    // Handle blanking
                    if (v_rowcount + 1 == v_disp) begin
                        vdisp <= 1'b0;
                    end
                end
            end else begin
                // Pad with vertical adjust
                if (v_scancount != v_maxscan + v_totaladj) begin
                    v_scancount <= v_scancount + 1;
                end else begin
                    v_scancount <= 0;
                    v_rowcount <= 0;
                    vdisp <= 1'b1;
                    cursor_counter <= cursor_counter + 1;
                end
            end

            // Vertical sync pulse is fixed at 16 scan line times
            // Vsync pulse turns off after 16 lines
            if (vs) begin
                if (v_synccount == 4'd15) begin
                    v_synccount <= 4'd0;
                    vs <= 0;
                end else begin
                    v_synccount <= v_synccount + 1;
                end
            end
        end
    end

    // Cursor
    assign cur_on = (v_scancount >= c_start[4:0]) &
                    (v_scancount <= c_end[4:0]);
    assign blink = (c_start[6:5] == 2'b00) |
                   (c_start[5] ? cursor_counter[4] : cursor_counter[3]);
    assign cursor = (cursor_a == mem_addr) & cur_on &
                    blink & (c_start[6:5] != 2'b01) & display_enable;

    // Memory address generator
    assign mem_addr = start_a + ma_rst + {6'b000000, h_count};
    always @ (posedge clk)
    begin
        if (divclk & (v_end | h_end)) begin
            if (v_end) begin
                ma_rst <= 14'd0;
            end else begin
                if (v_scancount == v_maxscan) begin
                    ma_rst <= ma_rst + {6'b000000, h_disp};
                end
            end
        end
    end
endmodule
