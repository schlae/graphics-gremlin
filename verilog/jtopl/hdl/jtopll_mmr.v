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
    Date: 10-6-2020
    */

module jtopll_mmr(
    input               rst,
    input               clk,
    input               cen,
    output              cenop,
    input       [ 7:0]  din,
    input               write,
    input               addr,
    // location
    output              zero,
    output      [ 1:0]  group,
    output              op,
    output      [17:0]  slot,
    output  reg         rhy_en,
    // Phase Generator
    output      [ 8:0]  fnum_I,
    output      [ 2:0]  block_I,
    output      [ 3:0]  mul_II,
    output              viben_I,
    // Operator
    output      [ 1:0]  wavsel_I,
    // Envelope Generator
    output              keyon_I,
    output              en_sus_I, // enable sustain
    output      [ 3:0]  arate_I,  // attack  rate
    output      [ 3:0]  drate_I,  // decay   rate
    output      [ 3:0]  rrate_I,  // release rate
    output      [ 3:0]  sl_I,     // sustain level
    output              ks_II,    // key scale
    output      [ 5:0]  tl_IV,
    output              amen_IV,
    // global values
    output reg          am_dep,
    output reg          vib_dep,
    output      [ 1:0]  ksl_IV,
    // Operator configuration
    output      [ 2:0]  fb_I,
    output              con_I
);

parameter OPL_TYPE=1;

jtopl_div #(OPL_TYPE) u_div  (
    .rst            ( rst             ),
    .clk            ( clk             ),
    .cen            ( cen             ),
    .cenop          ( cenop           )
);

localparam [7:0] REG_TESTYM  = 8'h0F,
                 REG_RYTHM   = 8'h0E;

reg  [ 7:0] selreg;       // selected register
reg  [ 7:0] din_copy;
reg         csm, effect;
reg  [ 1:0] sel_group;     // group to update
reg  [ 2:0] sel_sub;       // subslot to update
reg         up_fnumlo, up_fnumhi, up_inst,
            up_original;
reg         wave_mode,     // 1 if waveform selection is enabled (OPL2)
            csm_en,
            note_sel;      // keyboard split, not implemented
reg  [ 4:0] rhy_kon;

// this runs at clk speed, no clock gating here
// if I try to make this an async rst it fails to map it
// as flip flops but uses latches instead. So I keep it as sync. reset
always @(posedge clk) begin
    if( rst ) begin
        selreg      <= 0;
        sel_group   <= 0;
        sel_sub     <= 0;
        // Updaters
        up_inst     <= 0;
        up_fnumlo   <= 0;
        up_fnumhi   <= 0;
        up_original <= 0;
        // Rhythms
        rhy_en      <= 0;
        rhy_kon     <= 0;
        // sensitivity to LFO
        am_dep      <= 0;
        vib_dep     <= 0;
        csm_en      <= 0;
        note_sel    <= 0;
        // OPL2 waveforms
        wave_mode   <= 0;
        din_copy    <= 0;
    end else begin
        // WRITE IN REGISTERS
        if( write ) begin
            if( !addr ) begin
                selreg <= din;  
            end else begin
                // Global registers
                din_copy    <= din;
                up_fnumhi   <= 0;
                up_fnumlo   <= 0;
                up_inst     <= 0;
                up_original <= 0;
                // Operator registers
                // Mapping done according to Table 2-3, page 7 of YM3812 App. Manual
                if( selreg < 8 ) begin
                    up_original <= 1;
                    sel_sub     <= selreg[2:0];
                end                
                // Channel registers
                if( selreg[3:0]<=4'd8) begin
                    case( selreg[7:4] )
                        4'h1: up_fnumlo <= 1;
                        4'h2: up_fnumhi <= 1;
                        4'h3: up_inst   <= 1;
                        default:;
                    endcase
                end
                if( selreg[7:4]>=4'h1 && selreg[7:4]<4'h4
                    && selreg[3:0]<=8 ) begin
                    // Each group has three channels
                    // Channels 0-2 -> group 0
                    // Channels 3-5 -> group 1
                    // Channels 6-8 -> group 2
                    // other        -> group 3 - ignored
                    sel_group <= selreg[3:0] < 4'd3 ? 2'd0 :
                                 selreg[3:0] < 4'd6 ? 2'd1 :
                                 selreg[3:0] < 4'd9 ? 2'd2 : 2'd3;
                    sel_sub <= selreg[3:0] < 4'd6 ? selreg[2:0] :
                        { 1'b0, ~&selreg[2:1], selreg[0] };
                end
                // Global register
                if( selreg==REG_RYTHM ) begin
                    am_dep  <= din[7];
                    vib_dep <= din[6];
                    rhy_en  <= din[5];
                    rhy_kon <= din[4:0];
                end
            end
        end
    end
end

jtopll_reg u_reg(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cen        ( cenop         ),
    .din        ( din_copy      ),
    // Pipeline order
    .zero       ( zero          ),
    .group      ( group         ),
    .op         ( op            ),
    .slot       ( slot          ),
    
    .sel_group  ( sel_group     ),     // group to update
    .sel_sub    ( sel_sub       ),     // subslot to update

    .rhy_en     ( rhy_en        ),
    .rhy_kon    ( rhy_kon       ),

    .up_original( up_original   ),
    .up_inst    ( up_inst       ),
    .up_fnumlo  ( up_fnumlo     ),
    .up_fnumhi  ( up_fnumhi     ),

    // PG
    .fnum_I     ( fnum_I        ),
    .block_I    ( block_I       ),
    .mul_II     ( mul_II        ),
    .viben_I    ( viben_I       ),
    // OP
    .wavsel_I   ( wavsel_I      ),
    .wave_mode  ( wave_mode     ),
    // EG
    .keyon_I    ( keyon_I       ),
    .en_sus_I   ( en_sus_I      ),
    .arate_I    ( arate_I       ),
    .drate_I    ( drate_I       ),
    .rrate_I    ( rrate_I       ),
    .sl_I       ( sl_I          ),
    .ks_II      ( ks_II         ),
    .ksl_IV     ( ksl_IV        ),
    .amen_IV    ( amen_IV       ),
    .tl_IV      ( tl_IV         ),
    // Timbre - Neiro
    .fb_I       ( fb_I          ),
    .con_I      ( con_I         )
);

endmodule
