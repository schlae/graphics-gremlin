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

module jt2413(
    input                rst,        // rst should be at least 6 clk&cen cycles long
    input                clk,        // CPU clock
    input                cen,        // optional clock enable, it not needed leave as 1'b1
    input         [ 7:0] din,
    input                addr,
    input                cs_n,
    input                wr_n,
    // combined output
    output signed [15:0] snd,
    output               sample
);

parameter OPL_TYPE=11;

wire          cenop, write, zero;
wire  [ 1:0]  group;
wire  [17:0]  slot;
wire  [ 3:0]  trem;

// Phase
wire  [ 8:0]  fnum_I;
wire  [ 2:0]  block_I;
wire  [ 3:0]  mul_II;
wire  [ 9:0]  phase_IV;
wire          pg_rst_II;
wire          viben_I;
wire  [ 2:0]  vib_cnt;
// envelope configuration
wire          en_sus_I; // enable sustain
wire  [ 3:0]  keycode_II;
wire  [ 3:0]  arate_I; // attack  rate
wire  [ 3:0]  drate_I; // decay   rate
wire  [ 3:0]  rrate_I; // release rate
wire  [ 3:0]  sl_I;   // sustain level
wire          ksr_II;    // key scale rate - affects rates
wire  [ 1:0]  ksl_IV;   // key scale level - affects amplitude
// envelope operation
wire          keyon_I;
wire          eg_stop;
// envelope number
wire          amen_IV;
wire  [ 5:0]  tl_IV;
wire  [ 9:0]  eg_V;
// Global values
wire          am_dep, vib_dep, rhy_en;
// Operator
wire  [ 2:0]  fb_I;
wire  [ 1:0]  wavsel_I;
wire          op, con_I, op_out, con_out;

wire signed [12:0] op_result;

assign        write   = !cs_n && !wr_n;
assign        eg_stop = 0;
assign        sample  = zero;

jtopll_mmr #(.OPL_TYPE(OPL_TYPE)) u_mmr(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cen        ( cen           ),  // external clock enable
    .cenop      ( cenop         ),  // internal clock enable
    .din        ( din           ),
    .write      ( write         ),
    .addr       ( addr          ),
    // location
    .zero       ( zero          ),
    .group      ( group         ),
    .op         ( op            ),
    .slot       ( slot          ),
    .rhy_en     ( rhy_en        ),
    // Phase Generator
    .fnum_I     ( fnum_I        ),
    .block_I    ( block_I       ),
    .mul_II     ( mul_II        ),
    // Operator
    .wavsel_I   ( wavsel_I      ),
    // Envelope Generator
    .keyon_I    ( keyon_I       ),
    .en_sus_I   ( en_sus_I      ),
    .arate_I    ( arate_I       ),
    .drate_I    ( drate_I       ),
    .rrate_I    ( rrate_I       ),
    .sl_I       ( sl_I          ),
    .ks_II      ( ksr_II        ),
    .tl_IV      ( tl_IV         ),
    .ksl_IV     ( ksl_IV        ),
    .amen_IV    ( amen_IV       ),
    .viben_I    ( viben_I       ),
    // Global Values
    .am_dep     ( am_dep        ),
    .vib_dep    ( vib_dep       ),
    // Timbre
    .fb_I       ( fb_I          ),
    .con_I      ( con_I         )
);

jtopl_lfo u_lfo(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cenop      ( cenop         ),
    .slot       ( slot          ),
    .vib_cnt    ( vib_cnt       ),
    .trem       ( trem          )
);

jtopl_pg u_pg(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cenop      ( cenop         ),
    .slot       ( slot          ),
    .rhy_en     ( rhy_en        ),
    // Channel frequency
    .fnum_I     ( { fnum_I, 1'b0 } ),
    .block_I    ( block_I       ),
    // Operator multiplying
    .mul_II     ( mul_II        ),
    // phase modulation from LFO (vibrato at 6.4Hz)
    .vib_cnt    ( vib_cnt       ),
    .vib_dep    ( vib_dep       ),
    .viben_I    ( viben_I       ),
    // phase operation
    .pg_rst_II  ( pg_rst_II     ),

    .keycode_II ( keycode_II    ),
    .phase_IV   ( phase_IV      )
);

jtopl_eg u_eg(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cenop      ( cenop         ),
    .zero       ( zero          ),
    .eg_stop    ( eg_stop       ),
    // envelope configuration
    .en_sus_I   ( en_sus_I      ), // enable sustain
    .keycode_II ( keycode_II    ),
    .arate_I    ( arate_I       ), // attack  rate
    .drate_I    ( drate_I       ), // decay   rate
    .rrate_I    ( rrate_I       ), // release rate
    .sl_I       ( sl_I          ), // sustain level
    .ksr_II     ( ksr_II        ), // key scale
    // envelope operation
    .keyon_I    ( keyon_I       ),
    // envelope number
    .fnum_I     ( { fnum_I, 1'b0 } ),
    .block_I    ( block_I       ),
    .lfo_mod    ( trem          ),
    .amsen_IV   ( amen_IV       ),
    .ams_IV     ( am_dep        ),
    .tl_IV      ( tl_IV         ),
    .ksl_IV     ( ksl_IV        ),
    .eg_V       ( eg_V          ),
    .pg_rst_II  ( pg_rst_II     )
);

jtopl_op #(.OPL_TYPE(OPL_TYPE)) u_op(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cenop      ( cenop         ),

    // location of current operator
    .group      ( group         ),
    .op         ( op            ),
    .zero       ( zero          ),

    .pg_phase_I ( phase_IV      ),
    .eg_atten_II( eg_V          ), // output from envelope generator
    .fb_I       ( fb_I          ), // voice feedback
    .wavsel_I   ( wavsel_I      ), // sine mask (OPL2)

    .con_I      ( con_I         ),
    .op_result  ( op_result     ),
    .op_out     ( op_out        ),
    .con_out    ( con_out       )
);

jtopl_acc u_acc(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cenop      ( cenop         ),
    .zero       ( zero          ),
    .op_result  ( op_result     ),
    .op         ( op_out        ),
    .con        ( con_out       ),
    .snd        ( snd           )
);


endmodule
    