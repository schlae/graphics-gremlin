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
    Date: 17-6-2020 

*/

module jtopl_csr #(
    parameter LEN=18, W=34
) ( // Circular Shift Register + input mux
    input           rst,
    input           clk,
    input           cen,
    input   [ 7:0]  din,
    output [W-1:0]  shift_out,

    input           up_mult,
    input           up_ksl_tl,
    input           up_ar_dr,
    input           up_sl_rr,
    input           up_wav,
    input           update_op_I,
    input           update_op_II,
    input           update_op_IV
);


wire [W-1:0] regop_in;

jtopl_sh_rst #(.width(W),.stages(LEN)) u_regch(
    .clk    ( clk          ),
    .cen    ( cen          ),
    .rst    ( rst          ),
    .din    ( regop_in     ),
    .drop   ( shift_out    )
);

wire up_mult_I    = up_mult   & update_op_I;
wire up_mult_II   = up_mult   & update_op_II;
wire up_mult_IV   = up_mult   & update_op_IV;
wire up_ksl_tl_IV = up_ksl_tl & update_op_IV;
wire up_ar_dr_op  = up_ar_dr  & update_op_I;
wire up_sl_rr_op  = up_sl_rr  & update_op_I;
wire up_wav_I     = up_wav    & update_op_I;

assign regop_in[31:0] = { // 4 bytes:
        up_mult_IV  ? din[7]      : shift_out[31], // AM enable
        up_mult_I   ? din[6:5]    : shift_out[30:29], // Vib enable, EG type, KSR
        up_mult_II  ? din[4:0]    : shift_out[28:24], // KSR + Mult

        up_ksl_tl_IV? din         : shift_out[23:16], // KSL + TL

        up_ar_dr_op ? din         : shift_out[15: 8],

        up_sl_rr_op ? din         : shift_out[ 7: 0]
    };

`ifdef JTOPL2
    assign regop_in[33:32] = up_wav_I ? din[1:0] : shift_out[33:32];
`endif

endmodule // jtopl_reg