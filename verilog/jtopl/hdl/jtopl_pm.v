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
    Date: 21-6-2020
    */

// Based on Nuked's work on OPLL and OPL3

module jtopl_pm (
    input       [ 2:0] vib_cnt,
    input       [ 9:0] fnum,
    input              vib_dep,
    input              viben,
    output reg  [ 3:0] pm_offset
);

reg [2:0] range;

always @(*) begin
    if( vib_cnt[1:0]==2'b00 )
        range = 3'd0;
    else begin
        range = fnum[9:7]>>vib_cnt[0];
        if(!vib_dep) range = range>>1;
    end
    if( vib_cnt[2] )
        pm_offset = ~{1'b0, range } + 4'd1;
    else
        pm_offset = {1'b0, range };
    if(!viben) pm_offset = 4'd0;
end

endmodule
