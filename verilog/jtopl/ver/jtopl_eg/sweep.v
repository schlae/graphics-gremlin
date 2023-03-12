module test(
    input               rst,
    input               clk,
    input               eg_stop,
    // envelope configuration
    input               en_sus_I, // enable sustain
    input       [3:0]   arate_I, // attack  rate
    input       [3:0]   drate_I, // decay   rate
    input       [3:0]   rrate_I, // release rate
    input       [3:0]   sl_I,   // sustain level
    input               ksr_II,     // key scale
    // envelope operation
    input               keyon_I,
    // envelope number
    input       [9:0]   fnum_I,
    input       [2:0]   block_I,
    input       [3:0]   lfo_mod,
    input               amsen_IV,
    input               ams_IV,
    input       [5:0]   tl_IV,
    input       [1:0]   ksl_IV,

    output  reg [9:0]   eg_V,
    output  reg         pg_rst_II
);

wire        cenop, zero, op;
wire        kon = keyon_I;// & zero;
wire [17:0] slot;
wire [ 3:0] keycode_II = { block_I, fnum_I[9] };

reg cen=0;

always @(posedge clk) cen <= ~cen;

jtopl_div u_div(
    .rst    ( rst   ),
    .clk    ( clk   ),
    .cen    ( cen   ),
    .cenop  ( cenop )   // clock enable at operator rate
);

jtopl_slot_cnt u_slot_cnt(
    .rst    ( rst   ),
    .clk    ( clk   ),
    .cen    ( cenop ),

    // Pipeline order
    .zero   ( zero  ),
    .group  (       ),
    .op     ( op    ),   // 0 for modulator operators
    .subslot(       ),
    .slot   ( slot  )    // hot one encoding of active slot
);

jtopl_eg uut(
    .rst        ( rst           ),
    .clk        ( clk           ),
    // .cen        ( cen           ),Mas
    .cenop      ( cenop         ),
    .zero       ( zero          ),
    .eg_stop    ( eg_stop       ),
    // envelope configuration
    .en_sus_I   ( en_sus_I      ), // enable sustain
    .keycode_II ( keycode_II    ),
    .arate_I    ( arate_I       ), // attack  rate
    .drate_I    ( drate_I       ), // decay   rate
    .rrate_I    ( rrate_I       ), // release rate
    .sl_I       ( sl_I          ),   // sustain level
    .ksr_II     ( ksr_II        ),     // key scale
    // envelope operation
    .keyon_I    ( kon           ),
    // envelope number
    .fnum_I     ( fnum_I        ),
    .block_I    ( block_I       ),
    .lfo_mod    ( lfo_mod       ),
    .amsen_IV   ( amsen_IV      ),
    .ams_IV     ( ams_IV        ),
    .tl_IV      ( tl_IV         ),
    .ksl_IV     ( ksl_IV        ),

    .eg_V       ( eg_V          ),
    .pg_rst_II  ( pg_rst_II     )
);

endmodule