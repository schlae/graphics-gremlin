/* This file is part of JTOPL

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
    Date: 13-6-2020 

*/

module jtopl_slot_cnt(
    input             rst,
    input             clk,
    input             cen,

    // Pipeline order
    output            zero,
    output reg [ 1:0] group,
    output reg        op,           // 0 for modulator operators    
    output reg [ 2:0] subslot,
    output reg [17:0] slot         // hot one encoding of active slot
);

// Each group contains three channels
// and each subslot contains six operators
wire [2:0] next_sub   = subslot==3'd5 ? 3'd0 : (subslot+3'd1);
wire [1:0] next_group = subslot==3'd5 ? (group==2'b10 ? 2'b00 : group+2'b1) : group;

`ifdef SIMULATION
// These signals need to operate during rst
// initial state is not relevant (or critical) in real life
// but we need a clear value during simulation
initial begin
    group   = 2'd0;
    subslot = 3'd0;
    slot    = 18'd1;
end
`endif

assign     zero = slot[0];

always @(posedge clk) begin : up_counter
    if( cen ) begin
        { group, subslot }  <= { next_group, next_sub };
        if( { next_group, next_sub }==5'd0 ) begin
            slot <= 18'd1;
        end else begin
            slot <= { slot[16:0], 1'b0 };
        end
        op <= next_sub >= 3'd3;
    end
end

endmodule