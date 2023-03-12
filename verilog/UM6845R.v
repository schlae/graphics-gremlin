//============================================================================
//  UM6845R for Amstrad CPC
//  Copyright (C) 2018 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

`default_nettype wire
module UM6845R
(
	input            CLOCK,
	input            CLKEN,
	input            nCLKEN,
	input            nRESET,
	input            CRTC_TYPE,

	input            ENABLE,
	input            nCS,
	input            R_nW,
	input            RS,
	input      [7:0] DI,
	output reg [7:0] DO,
	
    input            lock,
	output           line_reset,	
	
	output reg       VSYNC,
	output reg       HSYNC,
	output           DE,
	output           FIELD,
	output           CURSOR,

	output    [13:0] MA,
	output     [4:0] RA
);

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

/* verilator lint_off WIDTH */

assign FIELD = ~field & interlace[0];

assign MA = row_addr_r;
assign RA = line | (field & interlace[0]);

assign DE = de[R8_skew & ~{2{CRTC_TYPE}}];

assign line_reset = hcc_last;

reg [7:0] R0_h_total = H_TOTAL;
reg [7:0] R1_h_displayed = H_DISP;
reg [7:0] R2_h_sync_pos = H_SYNCPOS;
reg [3:0] R3_v_sync_width;
reg [3:0] R3_h_sync_width = H_SYNCWIDTH;
reg [6:0] R4_v_total = V_TOTAL;
reg [4:0] R5_v_total_adj = V_TOTALADJ;
reg [6:0] R6_v_displayed = V_DISP;
reg [6:0] R7_v_sync_pos = V_SYNCPOS;
reg [1:0] R8_skew;
reg [1:0] R8_interlace = 2'd2;
reg [4:0] R9_v_max_line = V_MAXSCAN;
reg [1:0] R10_cursor_mode = 2'd0;
reg [4:0] R10_cursor_start = C_START;
reg [4:0] R11_cursor_end = C_END;
reg [5:0] R12_start_addr_h = 6'd0;
reg [7:0] R13_start_addr_l = 8'd0;
reg [5:0] R14_cursor_h = 6'd0;
reg [7:0] R15_cursor_l = 8'd0;

reg [4:0] addr;
always @(*) begin
	DO = 8'hFF;
	if (ENABLE & ~nCS) begin
		if (RS) begin
			case (addr)
				10: DO = {R10_cursor_mode, R10_cursor_start};
				11: DO = R11_cursor_end;
				12: DO = CRTC_TYPE ? 8'h00 : R12_start_addr_h;
				13: DO = CRTC_TYPE ? 8'h00 : R13_start_addr_l;
				14: DO = R14_cursor_h;
				15: DO = R15_cursor_l;
				31: DO = CRTC_TYPE ? 8'hFF : 8'h00;
			 default: DO = 0;
			endcase
		end
		else if(CRTC_TYPE) begin
			DO = vde ? 8'h00 : 8'h20; // status for CRTC1
		end
	end
end

always @(posedge CLOCK) begin
	if (ENABLE & ~nCS & ~R_nW & ~lock) begin
		if (~RS) addr <= DI[4:0];
		else begin
			case (addr)
				00: R0_h_total <= DI;
				01: R1_h_displayed <= DI;
				02: R2_h_sync_pos <= DI;
				03: {R3_v_sync_width,R3_h_sync_width} <= DI;
				04: R4_v_total <= DI[6:0];
				05: R5_v_total_adj <= DI[4:0];
				06: R6_v_displayed <= DI[6:0];
				07: R7_v_sync_pos <= DI[6:0];
				08: {R8_skew, R8_interlace} <= {DI[5:4],DI[1:0]};
				09: R9_v_max_line <= DI[4:0];
				10: {R10_cursor_mode,R10_cursor_start} <= DI[6:0];
				11: R11_cursor_end <= DI[4:0];
				12: R12_start_addr_h <= DI[5:0];
				13: R13_start_addr_l <= DI[7:0];
				14: R14_cursor_h <= DI[5:0];
				15: R15_cursor_l <= DI[7:0];
			endcase
		end
	end
end

wire [4:0] interlace = &R8_interlace[1:0];

reg        in_adj;

reg  [7:0] hcc;
wire       hcc_last  = (hcc == R0_h_total) && (CRTC_TYPE || R0_h_total); // always false if !R0_h_total on CRTC0
wire [7:0] hcc_next  = hcc_last ? 8'h00 : hcc + 1'd1;

reg  [4:0] line;
wire [4:0] line_max  = (in_adj ? (|R5_v_total_adj ? R5_v_total_adj-1'd1 : 5'd0) : R9_v_max_line) & ~interlace;
reg        line_last_r;
wire       line_last = (line == line_max) || !line_max;
wire [4:0] line_next = ((CRTC_TYPE ? line_last : line_last_r) ? 5'd0 : line + 1'd1 + interlace) & ~interlace;
wire       line_new  = hcc_last;

reg  [6:0] row;
reg        row_last_r;
wire       row_last  = (row == R4_v_total) || (!CRTC_TYPE && !R4_v_total);
wire       row_frame_last = ((CRTC_TYPE ? row_last : row_last_r) | in_adj) & ~frame_adj;
wire [6:0] row_next  = row_frame_last ? 7'd0 : row + 1'd1;
wire       row_new   = line_new & (CRTC_TYPE ? line_last : line_last_r);

reg        frame_adj_r;
wire       frame_adj_CRTC0 = (hcc == 2) ? frame_adj_r & |R5_v_total_adj : frame_adj_r;
wire       frame_adj_CRTC1 = row_last && ~in_adj && R5_v_total_adj;
wire       frame_adj = CRTC_TYPE ? frame_adj_CRTC1 : frame_adj_CRTC0;
wire       frame_new = row_new & row_frame_last;

// counters
reg  field;
always @(posedge CLOCK) begin
	if(~nRESET) begin
		hcc    <= 0;
		line   <= 0;
		row    <= 0;
		in_adj <= 0;
		field  <= 0;
	end
	else if(CLKEN) begin
		hcc <= hcc_next;
		if(line_new) line <= line_next;
		if(hcc == 0) begin
			line_last_r <= line_last;
			row_last_r <= row_last;
			frame_adj_r <= line_last & row_last & ~in_adj;
		end
		// CRTC0 always schedule the adjustment run at HCC=0,
		// then at HCC=2 it decides that it really has to run
		if(hcc == 2) frame_adj_r <= frame_adj_r & |R5_v_total_adj;

		if(row_new) begin
			row <= row_next;
			if(frame_adj) in_adj <= 1;
			else if(frame_new) begin
				in_adj <= 0;
				row <= 0;
				field <= ~field & R8_interlace[0];
			end
		end
	end
end

wire CRTC1_reload =  CRTC_TYPE & (frame_new | (~line_last & !row & !hcc_next)); //CRTC1 reloads addr on every line of 1st row
wire CRTC0_reload = ~CRTC_TYPE & frame_new;
wire row_addr_save = hcc == R1_h_displayed && (CRTC_TYPE ? line_last : line_last_r);

// address
reg  [13:0] row_addr;   // saved pointer
reg  [13:0] row_addr_r; // current pointer
always @(posedge CLOCK) begin
	if(CLKEN) begin
		if(row_addr_save) row_addr <= row_addr_r; // save current pointer

		if(hcc_last & !row_addr_save) row_addr_r <= row_addr; // restore the pointer, take care of simultaneous saving and restoring
		if(!hcc_last)                 row_addr_r <= row_addr_r + 1'd1;

		if(CRTC0_reload) begin
			row_addr <= {R12_start_addr_h, R13_start_addr_l};
			row_addr_r <= {R12_start_addr_h, R13_start_addr_l};
		end
		if(CRTC1_reload) begin
			row_addr_r <= {R12_start_addr_h, R13_start_addr_l};
		end
	end
end

// horizontal output
reg        hde;
reg  [3:0] hsc;

wire hsync_on = hcc == R2_h_sync_pos && R3_h_sync_width != 0;
wire hsync_off = (hsc == R3_h_sync_width) || (CRTC_TYPE && R3_h_sync_width == 0);

always @(posedge CLOCK) begin

	if(~nRESET) begin
		hsc    <= 0;
		hde    <= 0;
		HSYNC  <= 0;
	end
	else begin
		// should be a half char delay (other edge of the clock?)
		if (hsync_off)     HSYNC <= 0;
		else if (hsync_on) HSYNC <= 1;

		if (ENABLE & RS & ~nCS & ~R_nW & addr == 5'd01 & hcc == DI) hde <= 0;

		if (CLKEN) begin
			if(line_new)                   hde <= 1;
			if(hcc_next == R1_h_displayed) hde <= 0;

			if(HSYNC) hsc <= hsc + 1'd1;
			else hsc <= 0;
		end
	end
end

// vertical output
reg vde, vde_r;
reg VSYNC_r;
reg  [3:0] vsc;
reg        vsync_allow;
always @(posedge CLOCK) VSYNC <= VSYNC_r; // delay the same as HSYNC to not confuse the GA
always @(posedge CLOCK) begin

	if(~nRESET) begin
		vsc    <= 0;
		vde    <= 0;
		vde_r  <= 0;
		VSYNC_r<= 0;
		vsync_allow <= 1;
	end
	else if (CLKEN) begin
		if (!CRTC_TYPE && row == 0 && line == 0 && R6_v_displayed == 0) begin
			vde <= ~vde;
			vde_r <= ~vde_r;
		end

		if(row_new) begin
			if((frame_new & row !=0) | row_next != row) vsync_allow <= 1;
			if(frame_new)                  begin vde <= 1; vde_r <= 1; end
			if(row_next == R6_v_displayed) begin vde <= 0; vde_r <= 0; end
		end
		if(field ? (hcc_next == {1'b0, R0_h_total[7:1]}) : line_new) begin
			if(vsc) vsc <= vsc - 1'd1;
			else if (vsync_allow & (field ? (row == R7_v_sync_pos && !line) : (row_next == R7_v_sync_pos && line_last))) begin
				VSYNC_r <= 1;
				// Don't allow a new vsync until a new row (Onescreen Colonies) or the R7 is written (PHX)
				vsync_allow <= 0;
				vsc <= (CRTC_TYPE ? 4'd0 : R3_v_sync_width) - 1'd1;
			end
			else VSYNC_r <= 0;
		end
	end
	else if (nCLKEN) begin
		if (!CRTC_TYPE && row == 0 && line == 0 && R6_v_displayed == 0) begin
			vde <= ~vde;
			vde_r <= ~vde_r;
		end
	end

	if (ENABLE & RS & ~nCS & ~R_nW & addr == 5'd07) begin
		vsync_allow <= 1;
		if (row == DI[6:0] && !VSYNC_r) begin
			// TODO: extra conditions for CRTC0
			VSYNC_r <= 1;
			vsc <= (CRTC_TYPE ? 4'd0 : R3_v_sync_width) - 1'd1;
		end
	end
	if (nCLKEN & ENABLE & RS & ~nCS & ~R_nW & addr == 5'd06) begin
		if (CRTC_TYPE) begin
			if (row == DI[6:0]) vde_r <= 0;
			if (row != DI[6:0] && DI[6:0] != 0) vde <= vde_r;
			if (row == R6_v_displayed && DI[6:0] != row) vde <= 1;
			if (row == DI[6:0] || DI[6:0] == 0) vde <= 0;
		end else begin
			if (row == DI[6:0] && !(row == 0 && line == 0)) vde_r <= 0;
		end
	end
end

wire [3:0] de = {1'b0, dde[1:0], hde & vde & vde_r};
reg  [1:0] dde;
always @(posedge CLOCK) if (CLKEN) dde <= {dde[0],de[0]};

// Cursor control
reg cursor_line;
assign CURSOR = hde & vde & MA == {R14_cursor_h, R15_cursor_l} & cursor_line;

always @(posedge CLOCK) begin

	if(~nRESET) begin
		cursor_line <= 0;
	end
	else if (CLKEN) begin
		if (line == R10_cursor_start)
			cursor_line <= 1;
		else if (line == R11_cursor_end)
			cursor_line <= 0;
		end
	end

endmodule
