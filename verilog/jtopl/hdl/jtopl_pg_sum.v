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
    Date: 13-6-2020
    
    */

// Original hardware uses an adder to do the multiplication
// but I think it will take less resources of the FPGA to
// use a real multiplier instead

module jtopl_pg_sum (
    input       [ 3:0] mul,        
    input       [18:0] phase_in,
    input              pg_rst,
    input       [16:0] phinc_pure,

    output reg  [18:0] phase_out,
    output reg  [ 9:0] phase_op
);

reg [21:0] phinc_mul;
reg [ 4:0] factor[0:15];

always @(*) begin
    phinc_mul = { 5'b0, phinc_pure} * factor[mul];
    phase_out = pg_rst ? 'd0 : (phase_in + phinc_mul[19:1]);
    phase_op  = phase_out[18:9];
end

initial begin
    factor[ 0] = 5'd01; factor[ 1] = 5'd02; factor[ 2] = 5'd04; factor[ 3] = 5'd06;
    factor[ 4] = 5'd08; factor[ 5] = 5'd10; factor[ 6] = 5'd12; factor[ 7] = 5'd14;
    factor[ 8] = 5'd16; factor[ 9] = 5'd18; factor[10] = 5'd20; factor[11] = 5'd20;
    factor[12] = 5'd24; factor[13] = 5'd24; factor[14] = 5'd30; factor[15] = 5'd30;
end

endmodule // jtopl_pg_sum