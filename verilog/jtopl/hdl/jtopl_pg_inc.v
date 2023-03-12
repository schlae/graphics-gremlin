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

module jtopl_pg_inc (
    input        [ 2:0] block,
    input        [ 9:0] fnum,
    input signed [ 3:0] pm_offset,
    output reg   [16:0] phinc_pure
);

reg [16:0] freq;

always @(*) begin 
    freq       = { 7'd0, fnum } + { {13{pm_offset[3]}}, pm_offset };
    // Add PM here
    freq       = freq << block;
    phinc_pure = freq >> 1;
end

endmodule // jtopl_pg_inc