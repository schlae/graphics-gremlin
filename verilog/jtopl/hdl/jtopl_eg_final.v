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
    Date: 17-6-2020

    */

module jtopl_eg_final(
    input      [3:0] lfo_mod,
    input      [3:0] fnum,
    input      [2:0] block,
    input            amsen,
    input            ams,
    input      [5:0] tl,
    input      [1:0] ksl,   // level damped by pitch
    input      [9:0] eg_pure_in,
    output reg [9:0] eg_limited
);

reg [ 5:0] am_final;
reg [11:0] sum_eg_tl;
reg [11:0] sum_eg_tl_am;
reg [ 8:0] ksl_dB;
reg [ 6:0] ksl_lut[0:15];
reg [ 7:0] ksl_base;

always @(*) begin
    ksl_base = {1'b0, ksl_lut[fnum]}- { 1'b0, 4'd8-{1'b0,block}, 3'b0 };
    if( ksl_base[7] || ksl==2'b0 ) begin
        ksl_dB = 9'd0;
    end else begin
        ksl_dB = {ksl_base[6:0],2'b0} >> ~ksl;
    end
end

always @(*) begin
    am_final = amsen ? ( ams ? {lfo_mod, 2'b0} : {2'b0, lfo_mod} ) : 6'd0;
    sum_eg_tl = {  2'b0, tl,     3'd0 } + 
                {  1'b0, ksl_dB, 1'd0 } +
                {  1'b0, eg_pure_in}; // leading zeros needed to compute correctly
    sum_eg_tl_am = sum_eg_tl + { 5'd0, am_final };
end

always @(*) begin
    eg_limited = sum_eg_tl_am[11:10]==2'd0 ? sum_eg_tl_am[9:0] : 10'h3ff;
end

initial begin
    ksl_lut[ 0] = 7'd00; ksl_lut[ 1] = 7'd32; ksl_lut[ 2] = 7'd40; ksl_lut[ 3] = 7'd45;
    ksl_lut[ 4] = 7'd48; ksl_lut[ 5] = 7'd51; ksl_lut[ 6] = 7'd53; ksl_lut[ 7] = 7'd55;
    ksl_lut[ 8] = 7'd56; ksl_lut[ 9] = 7'd58; ksl_lut[10] = 7'd59; ksl_lut[11] = 7'd60;
    ksl_lut[12] = 7'd61; ksl_lut[13] = 7'd62; ksl_lut[14] = 7'd63; ksl_lut[15] = 7'd64;
end

endmodule