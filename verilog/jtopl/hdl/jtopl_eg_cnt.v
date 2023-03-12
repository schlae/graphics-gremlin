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

module jtopl_eg_cnt(
	input             rst,
	input             clk,
	input             cen,
	input             zero,
	output reg [14:0] eg_cnt
);

always @(posedge clk, posedge rst) begin : envelope_counter
	if( rst ) begin
		eg_cnt		<=15'd0;
	end
	else begin
		if( zero && cen ) begin
			// envelope counter increases at each zero input
			// This is different from OPN/M where it increased
			// once every three zero inputs
			eg_cnt <= eg_cnt + 1'b1;
		end
	end
end

endmodule