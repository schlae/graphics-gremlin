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
    Date: 25-6-2020
    
    */

module jtopl_pg_rhy (
    input       [ 9:0]  phase_pre,
    // Rhythm
    input               noise,
    input       [ 9:0]  hh,
    input               hh_en,
    input               tc_en,
    input               sd_en,
    input               rm_xor,
    output reg  [ 9:0]  phase_op
);

always @(*) begin
    if( hh_en ) begin
        phase_op = {rm_xor, 9'd0 };
        if( rm_xor ^ noise )
            phase_op = phase_op | 10'hd0;
        else
            phase_op = phase_op | 10'h34;
    end else if( sd_en ) begin
        phase_op = { hh[8], hh[8]^noise, 8'd0 };
    end else if( tc_en ) begin
        phase_op = { rm_xor, 9'h80 };
    end else
        phase_op = phase_pre;
end

endmodule // jtopl_pg_sum