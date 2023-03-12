module test(
    input                 keyon_now,
    input                 keyoff_now,
    input       [ 2:0]    state_in,
    input       [ 9:0]    eg_in,
    // envelope configuration
    input                 en_sus, // enable sustain
    input       [ 3:0]    arate, // attack  rate
    input       [ 3:0]    drate, // decay   rate
    input       [ 3:0]    rrate,
    input       [ 3:0]    sl,    // sustain level

    output reg  [ 2:0]    state_next,
    output reg            pg_rst,
    ///////////////////////////////////
    // II
    input       [ 3:0]    keycode,
    input       [14:0]    eg_cnt,
    input                 cnt_in,
    input                 ksr,
    output                cnt_lsb,
    output                sum_up_out,
    ///////////////////////////////////
    // III
    input                 sum_up_in,
    output reg  [ 9:0]    pure_eg_out,
    ///////////////////////////////////
    // IV
    input       [ 3:0]    lfo_mod,
    input       [ 3:0]    fnum,
    input       [ 2:0]    block,
    input                 amsen,
    input                 ams,
    input       [ 5:0]    tl,
    input       [ 1:0]    ksl,
    input       [ 3:0]    final_keycode,
    output reg  [ 9:0]    eg_out
);

wire [4:0]  base_rate;
wire        attack = state_next[0];
wire        step;
wire [5:0]  step_rate_out;

jtopl_eg_comb uut(
    .keyon_now      ( keyon_now     ),
    .keyoff_now     ( keyoff_now    ),
    .state_in       ( state_in      ),
    .eg_in          ( eg_in         ),
    // envelope configuration
    .en_sus         ( en_sus        ),
    .arate          ( arate         ), // attack  rate
    .drate          ( drate         ), // decay   rate
    .rrate          ( rrate         ),
    .sl             ( sl            ),   // sustain level

    .base_rate      ( base_rate     ),
    .state_next     ( state_next    ),
    .pg_rst         ( pg_rst        ),

    // Frequency settings
    .fnum           ( fnum          ),
    .block          ( block         ),
    .ksl            ( ksl           ),
    .ksr            ( ksr           ),
    .final_keycode  ( final_keycode ),

    ///////////////////////////////////
    // II
    .step_attack    ( attack        ),
    .step_rate_in   ( base_rate     ),
    .keycode        ( keycode       ),
    .eg_cnt         ( eg_cnt        ),
    .cnt_in         ( cnt_in        ),
    .cnt_lsb        ( cnt_lsb       ),
    .step           ( step          ),
    .step_rate_out  ( step_rate_out ),
    .sum_up_out     ( sum_up_out    ),
    ///////////////////////////////////
    // III
    .pure_attack    ( attack        ),
    .pure_step      ( step          ) ,
    .pure_rate      (step_rate_out[5:1]),
    .pure_eg_in     ( eg_in         ),
    .pure_eg_out    ( pure_eg_out   ),
    .sum_up_in      ( sum_up_in     ),
    ///////////////////////////////////
    // IV
    .lfo_mod        ( lfo_mod       ),
    .amsen          ( amsen         ),
    .ams            ( ams           ),
    .tl             ( tl            ),
    .final_eg_in    ( pure_eg_out   ),
    .final_eg_out   ( eg_out        )
);

endmodule // test