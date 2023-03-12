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
    Date: 24-6-2020

    */

// Following research by Andete in
// https://github.com/andete/ym2413
// This has been research for the YM2413 (OPLL)
// I assume other OPL chips use the same one

module jtopl_noise(
    input  rst,        // rst should be at least 6 clk&cen cycles long
    input  clk,        // CPU clock
    input  cen,        // optional clock enable, it not needed leave as 1'b1
    output noise
);

reg [22:0] poly;
reg        nbit;

assign     noise = poly[22] ^ poly[9] ^ poly[8] ^ poly[0];

always @(posedge clk, posedge rst) begin
    if( rst )
        poly <= 1;
    else if(cen) begin
        poly <= poly==0 ? 23'd1 : { poly[21:0], noise };
    end
end

endmodule