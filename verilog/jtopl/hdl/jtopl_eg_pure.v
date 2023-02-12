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

module jtopl_eg_pure(
    input           attack,
    input           step,
    input [ 5:1]    rate,
    input [ 9:0]    eg_in,
    input           sum_up,
    output reg  [9:0] eg_pure
);

reg [ 3:0]  dr_sum;
reg [ 9:0]  dr_adj;
reg [10:0]  dr_result;

always @(*) begin : dr_calculation
    case( rate[5:2] )
        4'b1100: dr_sum = 4'h2; // 12
        4'b1101: dr_sum = 4'h4; // 13
        4'b1110: dr_sum = 4'h8; // 14
        4'b1111: dr_sum = 4'hf;// 15
        default: dr_sum = { 2'b0, step, 1'b0 };
    endcase
    // Decay rate attenuation is multiplied by 4 for SSG operation
    dr_adj    = {6'd0, dr_sum};
    dr_result = dr_adj + eg_in;
end

reg [ 7:0] ar_sum0;
reg [ 8:0] ar_sum1;
reg [10:0] ar_result;
reg [ 9:0] ar_sum;

always @(*) begin : ar_calculation
    casez( rate[5:2] )
        default: ar_sum0 = {2'd0, eg_in[9:4]};
        4'b1011, 4'b1100: ar_sum0 = {1'd0, eg_in[9:3]}; // 'hb
        // 4'b1101: ar_sum0 = {1'd0, eg_in[9:3]}; // 'hd
        // 4'b111?: ar_sum0 = eg_in[9:2];         // 'he/f
        4'b1101, 4'b111?: ar_sum0 = eg_in[9:2];         // 'he/f
    endcase
    ar_sum1 = ar_sum0+9'd1;
    if( rate[5:2] == 4'he )
        ar_sum = { ar_sum1, 1'b0 };
    else if( rate[5:2] > 4'hb )
        ar_sum = step ? { ar_sum1, 1'b0 } : { 1'b0, ar_sum1 }; // adds ar_sum1*3/2 max
    // else if( rate[5:2] == 4'hb )
    //     ar_sum = step ? { ar_sum1, 1'b0 } : 10'd0; // adds ar_sum1 max
    else
        ar_sum = step ? { 1'b0, ar_sum1 } : 10'd0; // adds ar_sum1/2 max
    ar_result = eg_in-ar_sum;
end

///////////////////////////////////////////////////////////
// rate not used below this point
reg [9:0] eg_pre_fastar; // pre fast attack rate
always @(*) begin
    if(sum_up) begin
        if( attack  )
            eg_pre_fastar = ar_result[10] ? 10'd0: ar_result[9:0];
        else 
            eg_pre_fastar = dr_result[10] ? 10'h3FF : dr_result[9:0];
    end
    else eg_pre_fastar = eg_in;
    eg_pure = (attack&rate[5:1]==5'h1F) ? 10'd0 : eg_pre_fastar;
end

endmodule