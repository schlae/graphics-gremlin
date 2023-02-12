/* This file is part of JTOPL.

 
    JTOPL program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTOPL program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTOPL.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 20-6-2020 
    
*/

// Accumulates an arbitrary number of inputs with saturation
// restart the sum when input "zero" is high

module jtopl_single_acc #(parameter 
        INW=13, // input data width 
        OUTW=16 // output data width
)(
    input                 clk,
    input                 cenop,
    input [INW-1:0]       op_result,
    input                 sum_en,
    input                 zero,
    output reg [OUTW-1:0] snd
);

// for full resolution use INW=14, OUTW=16
// for cut down resolution use INW=9, OUTW=12
// OUTW-INW should be > 0

reg signed [OUTW-1:0] next, acc, current;
reg overflow;

wire [OUTW-1:0] plus_inf  = { 1'b0, {(OUTW-1){1'b1}} }; // maximum positive value
wire [OUTW-1:0] minus_inf = { 1'b1, {(OUTW-1){1'b0}} }; // minimum negative value

always @(*) begin
    current = sum_en ? { {(OUTW-INW){op_result[INW-1]}}, op_result } : {OUTW{1'b0}};
    next = zero ? current : current + acc;
    overflow = !zero && 
        (current[OUTW-1] == acc[OUTW-1]) && 
        (acc[OUTW-1]!=next[OUTW-1]);
end

always @(posedge clk) if( cenop ) begin
    acc <= overflow ? (acc[OUTW-1] ? minus_inf : plus_inf) : next;
    if(zero) snd <= acc;
end

endmodule