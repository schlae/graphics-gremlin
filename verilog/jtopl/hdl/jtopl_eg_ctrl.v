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

module jtopl_eg_ctrl(
    input               keyon_now,
    input               keyoff_now,
    input       [2:0]   state_in,
    input       [9:0]   eg,
    // envelope configuration   
    input               en_sus, // enable sustain
    input       [3:0]   arate,  // attack  rate
    input       [3:0]   drate,  // decay   rate
    input       [3:0]   rrate,
    input       [3:0]   sl,     // sustain level

    output reg  [4:0]   base_rate,
    output reg  [2:0]   state_next,
    output reg          pg_rst
);

localparam  ATTACK = 3'b001, 
            DECAY  = 3'b010, 
            HOLD   = 3'b100,
            RELEASE= 3'b000; // default state is release 

// wire is_decaying = state_in[1] | state_in[2];

wire [4:0] sustain = { &sl, sl}; //93dB if sl==4'hF

always @(*) begin
    pg_rst = keyon_now;
end

always @(*) 
    casez ( { keyoff_now, keyon_now, state_in} )
        5'b01_???: begin // key on
            base_rate   = {arate,1'b0};
            state_next  = ATTACK;
        end
        {2'b00, ATTACK}: 
            if( eg==10'd0 ) begin
                base_rate   = {drate,1'b0};
                state_next  = DECAY;
            end
            else begin
                base_rate   = {arate,1'b0};
                state_next  = ATTACK;
            end
        {2'b00, DECAY}: begin
            if( eg[9:5] >= sustain ) begin
                base_rate  = en_sus ? 5'd0 : {rrate,1'b0};
                state_next = en_sus ? HOLD : RELEASE;
            end else begin
                base_rate  = {drate,1'b0}; 
                state_next = DECAY;
            end
        end
        {2'b00, HOLD}: begin
            base_rate   = 5'd0;
            state_next  = HOLD;
        end
        default: begin // RELEASE, note that keyoff_now==1 will enter this state too
            base_rate   = {rrate,1'b1};
            state_next  = RELEASE;  // release
        end
    endcase


endmodule // jtopl_eg_ctrl