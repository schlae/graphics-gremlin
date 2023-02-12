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

    Based on Sauraen VHDL version of OPN/OPN2, which is based on die shots.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 19-6-2020

*/


module jtopl_op(
    input           rst,
    input           clk,
    input           cenop,

    // these signals need be delayed
    input   [1:0]   group,
    input           op, // 0 for modulator operators
    input           con_I,
    input   [2:0]   fb_I,       // voice feedback

    input           zero,

    input   [9:0]   pg_phase_I,
    input   [1:0]   wavsel_I,
    input   [9:0]   eg_atten_II, // output from envelope generator
    
    
    output reg signed [12:0] op_result,
    output                   op_out,
    output                   con_out
);

parameter OPL_TYPE=1;

localparam  OPW=13,     // Operator Width
            PW=OPW*2;   // Previous data Width

reg  [11:0] level_II;
reg         signbit_II, signbit_III;
reg         nullify_II;

wire [ 8:0] ctrl_in, ctrl_dly;
wire [ 1:0] group_d;
wire        op_d, con_I_d;
wire [ 1:0] wavsel_d;
wire [ 2:0] fb_I_d;

reg  [PW-1:0] prev,  prev0_din, prev1_din, prev2_din;
wire [PW-1:0] prev0, prev1,     prev2;

assign      ctrl_in = { wavsel_I, group, op, con_I, fb_I };
assign      { wavsel_d, group_d, op_d, con_I_d, fb_I_d } = ctrl_dly;

jtopl_sh #( .width(9), .stages(3)) u_delay(
    .clk    ( clk       ),
    .cen    ( cenop     ),
    .din    ( ctrl_in   ),
    .drop   ( ctrl_dly  )
);

jtopl_sh #( .width(2), .stages(3)) u_condly(
    .clk    ( clk                ),
    .cen    ( cenop              ),
    .din    ( {op_d, con_I_d}    ),
    .drop   ( {op_out, con_out}  )
);

always @(*) begin
    prev0_din     = op_d && group_d==2'd0 ? { prev0[OPW-1:0], op_result } : prev0;
    prev1_din     = op_d && group_d==2'd1 ? { prev1[OPW-1:0], op_result } : prev1;
    prev2_din     = op_d && group_d==2'd2 ? { prev2[OPW-1:0], op_result } : prev2;
    case( group_d )
        default: prev = prev0;
        2'd1:    prev = prev1;
        2'd2:    prev = prev2;
    endcase
end

jtopl_sh #( .width(PW), .stages(3)) u_csr0(
    .clk    ( clk       ),
    .cen    ( cenop     ),
    .din    ( prev0_din ),
    .drop   ( prev0     )
);

jtopl_sh #( .width(PW), .stages(3)) u_csr1(
    .clk    ( clk       ),
    .cen    ( cenop     ),
    .din    ( prev1_din ),
    .drop   ( prev1     )
);

jtopl_sh #( .width(PW), .stages(3)) u_csr2(
    .clk    ( clk       ),
    .cen    ( cenop     ),
    .din    ( prev2_din ),
    .drop   ( prev2     )
);


reg [   10:0]  subtresult;
reg [OPW-1:0]  shifter;
wire signed [OPW-1:0] fb1 = prev[PW-1:OPW];
wire signed [OPW-1:0] fb0 = prev[OPW-1:0];

// REGISTER/CYCLE 1
// Creation of phase modulation (FM) feedback signal, before shifting
reg signed [OPW-1:0] modmux_I;
reg signed [OPW-1:0] fbmod_I;

always @(*) begin
    modmux_I = op_d ? op_result : fb1+fb0;
    // OPL-L shifts by 8-FB
    // OPL3  shifts by 9-FB
    // OPLL seems to use lower resolution for OPW so it makes
    // sense that it shifts by one fewer
    fbmod_I  = modmux_I>>>(4'd9-{1'b0,fb_I_d});
end

reg signed [9:0] phasemod_I;

always @(*) begin
    // Shift FM feedback signal
    if (op_d)
        phasemod_I = con_I_d ? 10'd0 : modmux_I[9:0];
    else
        phasemod_I = fb_I_d==3'd0 ? 10'd0 : fbmod_I[9:0];
end

reg [ 9:0]  phase;
reg [ 7:0]  aux_I;

always @(*) begin
    phase   = phasemod_I + pg_phase_I;
    aux_I   = phase[7:0] ^ {8{~phase[8]}};
end

// REGISTER/CYCLE 1

always @(posedge clk) if( cenop ) begin    
    if( OPL_TYPE==1 ) begin
        signbit_II <= phase[9];
        nullify_II <= 0;
    end else begin
        signbit_II <= wavsel_d==0 && phase[9];
        nullify_II <= (wavsel_d==2'b01 && phase[9]) || (wavsel_d==2'b11 && phase[8]);
    end
end

wire [11:0]  logsin_II;

jtopl_logsin u_logsin (
    .clk    ( clk           ),
    .cen    ( cenop         ),
    .addr   ( aux_I[7:0]    ),
    .logsin ( logsin_II     )
);

// REGISTER/CYCLE 2
// Sine table    
// Main sine table body

always @(*) begin
    subtresult = eg_atten_II + logsin_II[11:2];
    level_II   = { subtresult[9:0], logsin_II[1:0] } | {12{subtresult[10]}};
    if( nullify_II ) begin
        level_II = ~12'h0;
    end
end

wire [9:0] mantissa_III;
reg  [3:0] exponent_III;

jtopl_exprom u_exprom(
    .clk    ( clk           ),
    .cen    ( cenop         ),
    .addr   ( level_II[7:0] ),
    .exp    ( mantissa_III  )
);

always @(posedge clk) if( cenop ) begin
    exponent_III <= level_II[11:8];    
    signbit_III  <= signbit_II;    
end

// REGISTER/CYCLE 3
// 2's complement & Carry-out discarded

always @(*) begin    
    // Floating-point to integer, and incorporating sign bit
    shifter = { 2'b01, mantissa_III,1'b0 } >> exponent_III;
end

// It looks like OPLL and OPL3 don't do full 2's complement but just bit inversion
always @(posedge clk) if( cenop ) begin
    op_result <= ( shifter ^ {OPW{signbit_III}});// + {13'd0,signbit_III};
end

`ifdef SIMULATION
reg signed [OPW-1:0] op_sep0_0;
reg signed [OPW-1:0] op_sep1_0;
reg signed [OPW-1:0] op_sep2_0;
reg signed [OPW-1:0] op_sep0_1;
reg signed [OPW-1:0] op_sep1_1;
reg signed [OPW-1:0] op_sep2_1;
reg signed [OPW-1:0] op_sep4_0;
reg signed [OPW-1:0] op_sep5_0;
reg signed [OPW-1:0] op_sep6_0;
reg signed [OPW-1:0] op_sep4_1;
reg signed [OPW-1:0] op_sep5_1;
reg signed [OPW-1:0] op_sep6_1;
reg signed [OPW-1:0] op_sep7_0;
reg signed [OPW-1:0] op_sep8_0;
reg signed [OPW-1:0] op_sep9_0;
reg signed [OPW-1:0] op_sep7_1;
reg signed [OPW-1:0] op_sep8_1;
reg signed [OPW-1:0] op_sep9_1;
reg        [ 4:0] sepcnt;

always @(posedge clk) if(cenop) begin
    sepcnt <= zero ? 5'd0 : sepcnt+5'd1;
    case( (sepcnt+3)%18  )
        0: op_sep0_0 <= op_result;
        1: op_sep1_0 <= op_result;
        2: op_sep2_0 <= op_result;
        3: op_sep0_1 <= op_result;
        4: op_sep1_1 <= op_result;
        5: op_sep2_1 <= op_result;
        6: op_sep4_0 <= op_result;
        7: op_sep5_0 <= op_result;
        8: op_sep6_0 <= op_result;
        9: op_sep4_1 <= op_result;
       10: op_sep5_1 <= op_result;
       11: op_sep6_1 <= op_result;
       12: op_sep7_0 <= op_result;
       13: op_sep8_0 <= op_result;
       14: op_sep9_0 <= op_result;
       15: op_sep7_1 <= op_result;
       16: op_sep8_1 <= op_result;
       17: op_sep9_1 <= op_result;
    endcase
end

`endif

endmodule
