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
    Date: 27-5-2022

*/

module jtopll_reg(
    input            rst,
    input            clk,
    input            cen,
    input      [7:0] din,

    input            rhy_en,      // rhythm enable
    input      [4:0] rhy_kon,     // key-on for each rhythm instrument

    // Pipeline order
    output           zero,
    output     [1:0] group,
    output           op,           // 0 for modulator operators
    output    [17:0] slot,        // hot one encoding of active slot

    // Register update
    input      [1:0] sel_group,   // group to update
    input      [2:0] sel_sub,     // subslot to update

    input            up_fnumlo,
    input            up_fnumhi,
    input            up_inst,
    input            up_original,

    // PG
    output     [8:0] fnum_I,
    output     [2:0] block_I,
    // channel configuration
    output     [2:0] fb_I,


    output reg [3:0] mul_II,  // frequency multiplier
    output     [1:0] ksl_IV,  // key shift level
    output           amen_IV,
    output           viben_I,
    // OP
    output     [1:0] wavsel_I,
    input            wave_mode,
    // EG
    output           keyon_I,
    output     [5:0] tl_IV,
    output           en_sus_I, // enable sustain
    output     [3:0] arate_I,  // attack  rate
    output     [3:0] drate_I,  // decay   rate
    output     [3:0] rrate_I,  // release rate
    output     [3:0] sl_I,     // sustain level
    output reg       ks_II,    // key scale
    output           con_I     // 1 for adding the modulator operator at the accumulator
                               // carrier op. are always added

);

localparam CH=9;


reg  [ 5:0] rhy_csr;
wire        rhy_oen, rhyon_csr;
wire [ 2:0] subslot;
wire        match;
wire [ 3:0] vol_I;     // channel volume

wire [ 5:0] tl_I;
wire [ 1:0] ksl_I;
wire [ 3:0] mul_I;
wire        amen_I, ks_I;

// The original instrument (programmable patch) is at location 0
reg  [63:0] patch[0:(16+6-1)]; // instrument memory, 15 instruments + original + 6 drums
wire [ 3:0] inst_I;
wire [ 4:0] inst_sel;

assign wavsel_I[1] = 0;
assign match = { group, subslot } == { sel_group, sel_sub};

jtopl_slot_cnt u_slot_cnt(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .cen    ( cen       ),
    // Pipeline order
    .zero   ( zero      ),
    .group  ( group     ),
    .op     ( op        ),   // 0 for modulator operators
    .subslot(subslot    ),
    .slot   ( slot      )    // hot one encoding of active slot
);

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        patch[00]<=64'h0000000000000000;
        patch[01]<=64'h170078D0171E6171;
        patch[02]<=64'h1323F7D80D1A4113;
        patch[03]<=64'h2311C4F200990113;
        patch[04]<=64'h277064A8070E6131;
        patch[05]<=64'h280076E0061E2132;
        patch[06]<=64'h180071E005162231;
        patch[07]<=64'h07108182071D6121;
        patch[08]<=64'h070072A2142D2123;
        patch[09]<=64'h17106564061B6161;
        patch[10]<=64'h0771F785180B6141;
        patch[11]<=64'h0410E4FA11830113;
        patch[12]<=64'h1222F8F80724C117;
        patch[13]<=64'h4220F5C2050C5061;
        patch[14]<=64'h020395C903550101;
        patch[15]<=64'h1340E4F103894161;
        patch[16]<=64'h006A00DF0F180001;
        patch[17]<=64'h00A700C800000001;
        patch[18]<=64'h005900F800000005;
        patch[19]<=64'h6D00F80000000100;
        patch[20]<=64'h4800D80000000100;
        patch[21]<=64'h5500AA0000000100;
    end else begin
        if( up_original ) begin
            patch[0][ {sel_sub,3'd0} +: 8 ] <= din;
        end
    end
end

// Selects the current patch
assign inst_sel             = rhy_oen ? { 2'b10, subslot } : { 1'b0, inst_I };
assign { amen_I, viben_I, en_sus_I, ks_I, mul_I } = patch[ inst_sel ][ (op ? 8:0) +: 8 ];
assign ksl_I                = patch[ inst_sel ][ (op ? 31:23) -: 2 ];
assign tl_I                 =
    rhy_oen & (slot[13] | slot[14]) ? { inst_I, 2'd0 } : // HH and TT have the volume set this way
    op ? { vol_I, 2'd0 } : patch[ inst_sel ][ 16 +: 6 ];
assign wavsel_I[0]          = patch[ inst_sel ][ op ? 28 : 27];
assign fb_I                 = op ? 3'd0 : patch[ inst_sel ][ 24 +: 3 ];
assign { arate_I, drate_I } = patch[ inst_sel ][ (op ? 40 : 32) +: 8 ];
assign { sl_I, rrate_I    } = patch[ inst_sel ][ op ? 56 : 48 +: 8 ];

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        { ks_II, mul_II } <= 0;
    end else if(cen) begin
        { ks_II, mul_II } <= { ks_I, mul_I };
    end
end

jtopl_sh_rst #(.width(2+1+6),.stages(3)) u_iv(
    .clk    ( clk        ),
    .cen    ( cen        ),
    .rst    ( rst        ),
    .din    ( { ksl_I, amen_I, tl_I    } ),
    .drop   ( { ksl_IV, amen_IV, tl_IV } )
);

// Memory for CH registers
localparam KONW   = 1,
           SUSENW = 1,
           FNUMW  = 9,
           BLOCKW = 3,
           INSTW  = 4,
           VOLW   = 4;
localparam CHCSRW = SUSENW+KONW+FNUMW+BLOCKW+INSTW+VOLW;

wire [CHCSRW-1:0] chcfg, chcfg_inmux;
wire              sus_en, keyon_csr, con_csr;
wire       up_fnumlo_ch = up_fnumlo & match,
           up_fnumhi_ch = up_fnumhi & match,
           up_inst_ch   = up_inst   & match;

assign chcfg_inmux = {
    up_fnumhi_ch ? din[5:0] : { sus_en, keyon_csr, block_I, fnum_I[8] },
    up_fnumlo_ch ? din      : fnum_I[7:0],
    up_inst_ch   ? din      : { inst_I, vol_I }
};

assign con_I   = rhy_oen && !slot[12]; // slot 12 = BD, which uses modulation
                // slots 13/14 as rhythm, need to be added in the accumulator, so con_I is set to 1
assign { sus_en, keyon_csr, block_I, fnum_I[8:0], inst_I, vol_I } = chcfg;
assign keyon_I = rhy_oen ? rhyon_csr : keyon_csr;

jtopl_reg_ch#(CHCSRW) u_reg_ch(
    .rst         ( rst          ),
    .clk         ( clk          ),
    .cen         ( cen          ),
    .zero        ( zero         ),
    .rhy_en      ( rhy_en       ),
    .rhy_kon     ( rhy_kon      ),
    .slot        ( slot         ),
    .group       ( group        ),
    .chcfg_inmux ( chcfg_inmux  ),
    .chcfg       ( chcfg        ),
    .rhy_oen     ( rhy_oen      ),
    .rhyon_csr   ( rhyon_csr    )
);

endmodule
