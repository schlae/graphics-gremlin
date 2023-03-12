/*  This file is part of JTOPL.

    JTOPL is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTOPL is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTOPL.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 10-6-2020

    */

module jtopl_timers(
  input         clk,
  input         rst,
  input         cenop,
  input         zero,
  input [7:0]   value_A,
  input [7:0]   value_B,
  input         load_A,
  input         load_B,
  input         clr_flag_A,
  input         clr_flag_B,
  output        flag_A,
  output        flag_B,
  input         flagen_A,
  input         flagen_B,
  output        overflow_A,
  output        irq_n
);

wire   pre_A, pre_B;

assign flag_A = pre_A & flagen_A;
assign flag_B = pre_B & flagen_B;

assign irq_n = ~( flag_A | flag_B );

// 1 count per 288 master clock ticks
jtopl_timer #(.MW(2)) timer_A (
    .clk        ( clk       ), 
    .rst        ( rst       ),
    .cenop      ( cenop     ),
    .zero       ( zero      ),
    .start_value( value_A   ),
    .load       ( load_A    ),
    .clr_flag   ( clr_flag_A),
    .flag       ( pre_A     ),
    .overflow   ( overflow_A)
);

// 1 count per 288*4 master clock ticks
jtopl_timer #(.MW(4)) timer_B(
    .clk        ( clk       ), 
    .rst        ( rst       ),
    .cenop      ( cenop     ),
    .zero       ( zero      ),
    .start_value( value_B   ),
    .load       ( load_B    ),
    .clr_flag   ( clr_flag_B),
    .flag       ( pre_B     ),
    .overflow   (           )
);

endmodule

module jtopl_timer #(parameter MW=2) (
    input      clk, 
    input      rst,
    input      cenop,
    input      zero,
    input      [7:0] start_value,
    input      load,
    input      clr_flag,
    output reg flag,
    output reg overflow
);

reg    [7:0] cnt, next, init;
reg [MW-1:0] free_cnt, free_next;
reg          load_l, free_ov;

always@(posedge clk)
    if( clr_flag || rst)
        flag <= 1'b0;
    else if(cenop && zero && load && overflow) flag<=1'b1;

always @(*) begin
    {free_ov, free_next} = { 1'b0, free_cnt} + 1'b1;
/* verilator lint_off WIDTH */
    {overflow, next } = {1'b0, cnt}+free_ov;
/* verilator lint_on WIDTH */
    init = start_value;
end

always @(posedge clk) begin
    load_l <= load;
    if( (!load_l && load) || rst) begin
        cnt <= start_value;
    end else if( cenop && zero && load ) begin
        cnt <= overflow ? init : next;
    end
end

// Free running counter, resetting
// the value of this part with the load
// event can slow down music, vg Bad Dudes
always @(posedge clk) begin
    if( rst ) begin
        free_cnt <= 0;
    end else if( cenop && zero ) begin
        free_cnt <= free_next;
    end
end

endmodule
