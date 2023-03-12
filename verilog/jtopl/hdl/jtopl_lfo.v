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

// Follows OPLL Reverse Engineering from Nuked
// https://github.com/nukeykt/Nuked-OPLL

// The AM logic renders a triangular waveform. The logic for it is rather
// obscure, but apparently that's how the original was done

module jtopl_lfo(
    input             rst,
    input             clk,
    input             cenop,
    input      [17:0] slot,
    output     [ 2:0] vib_cnt,
    output reg [ 3:0] trem
);

parameter [6:0] LIM=7'd60;

reg  [12:0] cnt;
reg         am_inc, am_incen, am_dir, am_step;
reg  [ 1:0] am_bit;
reg         am_carry;
reg  [ 8:0] am_cnt;

wire [12:0] next    = cnt+1'b1;

assign vib_cnt = cnt[12:10];

always @(*) begin
    am_inc = (slot[0] | am_dir ) & am_step & am_incen;
    am_bit = {1'b0, am_cnt[0]} + {1'b0, am_inc} + {1'b0, am_carry & am_incen};
end

always @(posedge clk) begin
    if( rst ) begin
        cnt      <= 13'd0;
        am_incen <= 1;
        am_dir   <= 0;
        am_carry <= 0;
        am_cnt   <= 9'd0;
        am_step  <= 0;
    end else if( cenop ) begin
        if( slot[17] ) begin
            cnt      <= next;
            am_step  <= &next[5:0];
            am_incen <= 1;
        end
        else if(slot[8]) am_incen <= 0;        
        am_cnt   <= { am_bit[0], am_cnt[8:1] };
        am_carry <= am_bit[1];
        if( slot[0] ) begin
            if( am_dir && am_cnt[6:0]==7'd0 ) am_dir <= 0;
        else
            if( !am_dir && ( (am_cnt[6:0]&7'h69) == 7'h69) ) am_dir <= 1;
        end
        // output
        if( slot[0] ) trem <= am_cnt[6:3];
    end
end

endmodule
