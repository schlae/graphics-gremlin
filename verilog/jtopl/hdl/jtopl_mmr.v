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

module jtopl_mmr(
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
    // Timers
    output  reg [ 7:0]  value_A,
    output  reg [ 7:0]  value_B,
    output  reg         load_A,
    output  reg         load_B,
    output  reg         flagen_A,
    output  reg         flagen_B,
    output  reg         clr_flag_A,
    output  reg         clr_flag_B,
    input               flag_A,
    input               overflow_A,
    // Phase Generator
    output      [ 9:0]  fnum_I,
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

localparam [7:0] REG_TESTYM  = 8'h01,
                 REG_CLKA    = 8'h02,
                 REG_CLKB    = 8'h03,
                 REG_TIMER   = 8'h04,
                 REG_CSM     = 8'h08,
                 REG_RYTHM   = 8'hBD;

reg  [ 7:0] selreg;       // selected register
reg  [ 7:0] din_copy;
reg         csm, effect;
reg  [ 1:0] sel_group;     // group to update
reg  [ 2:0] sel_sub;       // subslot to update
reg         up_fnumlo, up_fnumhi, up_fbcon, 
            up_mult, up_ksl_tl, up_ar_dr, up_sl_rr,
            up_wav;
reg         wave_mode,     // 1 if waveform selection is enabled (OPL2)
            csm_en,
            note_sel;      // keyboard split, not implemented
reg  [ 4:0] rhy_kon;

// this runs at clk speed, no clock gating here
// if I try to make this an async rst it fails to map it
// as flip flops but uses latches instead. So I keep it as sync. reset
always @(posedge clk) begin
    if( rst ) begin
        selreg    <= 8'h0;
        sel_group <= 2'd0;
        sel_sub   <= 3'd0;
        // Updaters
        up_fbcon  <= 0;
        up_fnumlo <= 0;
        up_fnumhi <= 0;
        up_mult   <= 0;
        up_ksl_tl <= 0;
        up_ar_dr  <= 0;
        up_sl_rr  <= 0;
        up_wav    <= 0;
        // Rhythms
        rhy_en    <= 0;
        rhy_kon   <= 5'd0;
        // sensitivity to LFO
        am_dep    <= 0;
        vib_dep   <= 0;
        csm_en    <= 0;
        note_sel  <= 0;
        // OPL2 waveforms
        wave_mode <= 0;
        // timers
        { value_A, value_B } <= 16'd0;
        { clr_flag_B, clr_flag_A, load_B, load_A } <= 4'd0;
        flagen_A   <= 1;
        flagen_B   <= 1;
        din_copy   <= 8'd0;
    end else begin
        // WRITE IN REGISTERS
        if( write ) begin
            if( !addr ) begin
                selreg <= din;  
            end else begin
                // Global registers
                din_copy  <= din;
                up_fnumhi <= 0;
                up_fnumlo <= 0;
                up_fbcon  <= 0;
                up_mult   <= 0;
                up_ksl_tl <= 0;
                up_ar_dr  <= 0;
                up_sl_rr  <= 0;
                up_wav    <= 0;
                // General control (<0x20 registers)
                casez( selreg )
                    REG_TESTYM: if(OPL_TYPE>1) wave_mode <= din[5];
                    REG_CLKA: value_A <= din;
                    REG_CLKB: value_B <= din;
                    REG_TIMER: begin
                        clr_flag_A <= din[7];
                        clr_flag_B <= din[7];
                        if (~din[7]) begin
                            flagen_A   <= ~din[6];
                            flagen_B   <= ~din[5];
                            { load_B, load_A   } <= din[1:0];
                        end
                    end
                    REG_CSM: {csm_en, note_sel} <= din[7:6];
                    default:;
                endcase
                // Operator registers
                // Mapping done according to Table 2-3, page 7 of YM3812 App. Manual
                if( selreg >= 8'h20 &&
                    (selreg < 8'hA0 || (selreg>=8'hE0 && OPL_TYPE>1) ) &&
                    selreg[2:0]<=3'd5 && selreg[4:3]!=2'b11) begin
                    sel_group <= selreg[4:3];
                    sel_sub   <= selreg[2:0];
                    case( selreg[7:5] )
                        3'b001: up_mult   <= 1;
                        3'b010: up_ksl_tl <= 1;
                        3'b011: up_ar_dr  <= 1;
                        3'b100: up_sl_rr  <= 1;
                        3'b111: up_wav    <= OPL_TYPE!=1;
                        default:;
                    endcase
                end                
                // Channel registers
                if( selreg[3:0]<=4'd8) begin
                    case( selreg[7:4] )
                        4'hA: up_fnumlo <= 1;
                        4'hB: up_fnumhi <= 1;
                        4'hC: up_fbcon  <= 1;
                        default:;
                    endcase
                end
                if( selreg[7:4]>=4'hA && selreg[7:4]<4'hd
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
        else if(cenop) begin /* clear once-only bits */
            { clr_flag_B, clr_flag_A } <= 2'd0;
        end
    end
end

jtopl_reg #(.OPL_TYPE(OPL_TYPE)) u_reg(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cen        ( cenop         ),
    .din        ( din_copy      ),
    .write      ( write         ),
    // Pipeline order
    .zero       ( zero          ),
    .group      ( group         ),
    .op         ( op            ),
    .slot       ( slot          ),
    
    .sel_group  ( sel_group     ),     // group to update
    .sel_sub    ( sel_sub       ),     // subslot to update

    .rhy_en     ( rhy_en        ),
    .rhy_kon    ( rhy_kon       ),
    
    //input           csm,
    //input           flag_A,
    //input           overflow_A,

    .up_fbcon   ( up_fbcon      ),
    .up_fnumlo  ( up_fnumlo     ),
    .up_fnumhi  ( up_fnumhi     ),

    .up_mult    ( up_mult       ),
    .up_ksl_tl  ( up_ksl_tl     ),
    .up_ar_dr   ( up_ar_dr      ),
    .up_sl_rr   ( up_sl_rr      ),
    .up_wav     ( up_wav        ),

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
