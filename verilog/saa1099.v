//============================================================================
// 
//  SAA1099 sound generator
//  Copyright (C) 2016 Sorgelig
//
//  Based on SAA1099.v code from Miguel Angel Rodriguez Jodar
//  Based on SAASound code  from Dave Hooper
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module saa1099
(
   input wire   clk_sys,
   input wire   ce,      // 8 MHz
   input wire   rst_n,
   input wire   cs_n,
   input wire   a0,      // 0=data, 1=address
   input wire   wr_n,
   input wire   [7:0] din,
   output wire  [7:0] out_l,
   output wire  [7:0] out_r
);

reg [7:0] amplit0, amplit1, amplit2, amplit3, amplit4, amplit5;
reg [7:0] freq0, freq1, freq2, freq3, freq4, freq5;
reg [7:0] oct10, oct32, oct54;
reg [7:0] freqenable;
reg [7:0] noiseenable;
reg [7:0] noisegen;
reg [7:0] envelope0, envelope1;
reg [7:0] ctrl;

reg [4:0] addr;
wire      rst = ~rst_n | ctrl[1];
reg       wr;

reg       old_wr;
always @(posedge clk_sys) begin

	old_wr <= wr_n;
	wr <= 0;
	if(~rst_n) begin
		addr <= 0;
		{amplit0, amplit1, amplit2, amplit3, amplit4, amplit5} <= 0;
		{freq0, freq1, freq2, freq3, freq4, freq5} <= 0;
		{oct10, oct32, oct54} <= 0;
		{freqenable, noiseenable, noisegen} <= 0;
		{envelope0, envelope1} <= 0;
		ctrl <= 0;
	end
	else begin
		if(!cs_n & old_wr & !wr_n) begin
			wr <= 1;
			if(a0) addr <= din[4:0];
			else begin
				case (addr)
                    5'h00: amplit0    <= din;
                    5'h01: amplit1    <= din;
                    5'h02: amplit2    <= din;
                    5'h03: amplit3    <= din;
                    5'h04: amplit4    <= din;
                    5'h05: amplit5    <= din;

                    5'h08: freq0      <= din;
                    5'h09: freq1      <= din;
                    5'h0A: freq2      <= din;
                    5'h0B: freq3      <= din;
                    5'h0C: freq4      <= din;
                    5'h0D: freq5      <= din;

                    5'h10: oct10      <= din;
                    5'h11: oct32      <= din;
                    5'h12: oct54      <= din;

                    5'h14: freqenable <= din;
                    5'h15: noiseenable<= din;
                    5'h16: noisegen   <= din;

                    5'h18: envelope0  <= din;
                    5'h19: envelope1  <= din;

                    5'h1C: ctrl       <= din;
				endcase
			end
		end
	end
end

wire [21:0] out0;
saa1099_triplet top
(
    .rst        (rst        				),
    .clk_sys    (clk_sys    				),
    .ce         (ce         				),

	.vol		   ({amplit0, amplit1, amplit2}),
	.env			(envelope0					),

	.freq			({freq0, freq1, freq2}	),
	.octave		({oct10[2:0], oct10[6:4], oct32[2:0]}),
	.freq_en		(freqenable [2:0]			),

	.noise_en	(noiseenable[2:0]			),
	.noise_freq	(noisegen   [1:0]			),

	.wr_addr		(wr &  a0 & (din[4:0] == 'h18)),
	.wr_data		(wr & !a0 & (addr == 'h18)),

	.out			(out0							)

);

wire [21:0] out1;
saa1099_triplet bottom
(
    .rst        (rst        				),
    .clk_sys    (clk_sys    				),
    .ce         (ce         				),
	 
	.vol		({amplit3, amplit4, amplit5}),
	.env			(envelope1					),

	.freq			({freq3, freq4, freq5}	),
	.octave		({oct32[6:4], oct54[2:0], oct54[6:4]}),
	.freq_en		(freqenable [5:3]			),

	.noise_en	(noiseenable[5:3]			),
	.noise_freq	(noisegen   [5:4]			),

	.wr_addr		(wr &  a0 & (din[4:0] == 'h19)),
	.wr_data		(wr & !a0 & (addr == 'h19)),

	.out			(out1							)
);

saa1099_output_mixer outmix_l(.ce(ce), .clk_sys(clk_sys), .en(ctrl[0]), .in0(out0[10:0]),  .in1(out1[10:0]),  .out(out_l));
saa1099_output_mixer outmix_r(.ce(ce), .clk_sys(clk_sys), .en(ctrl[0]), .in0(out0[21:11]), .in1(out1[21:11]), .out(out_r));

endmodule

/////////////////////////////////////////////////////////////////////////////////
module saa1099_triplet
(
    input wire   rst,
    input wire   clk_sys,
    input wire   ce,

    input wire [23:0] vol,
    input wire [7:0] env,

    input wire [23:0] freq,
    input wire [8:0] octave,
    input wire [2:0] freq_en,

    input wire [2:0] noise_en,
    input wire [1:0] noise_freq,

    input wire  wr_addr,
    input wire  wr_data,

    output wire [21:0] out
);

wire       tone0, tone1, tone2, noise;
wire       pulse_noise, pulse_envelope;
wire[21:0] out0, out1, out2;

saa1099_tone  freq_gen0(.rst(rst), .clk_sys(clk_sys), .ce(ce), .out(tone0), .octave(octave[8:6]), .freq(freq[23:16]), .pulse(pulse_noise));
saa1099_tone  freq_gen1(.rst(rst), .clk_sys(clk_sys), .ce(ce), .out(tone1), .octave(octave[5:3]), .freq(freq[15: 8]), .pulse(pulse_envelope));
saa1099_tone  freq_gen2(.rst(rst), .clk_sys(clk_sys), .ce(ce), .out(tone2), .octave(octave[2:0]), .freq(freq[ 7: 0]), .pulse());
saa1099_noise noise_gen(.rst(rst), .clk_sys(clk_sys), .ce(ce), .pulse_noise(pulse_noise), .noise_freq(noise_freq), .out(noise));

saa1099_amp amp0(.rst(rst), .clk_sys(clk_sys), .noise(noise), .wr_addr(wr_addr), .wr_data(wr_data), .pulse_envelope(pulse_envelope), .mixmode({noise_en[0], freq_en[0]}), .tone(tone0), .envreg(0),   .vol(vol[23:16]), .out(out0));
saa1099_amp amp1(.rst(rst), .clk_sys(clk_sys), .noise(noise), .wr_addr(wr_addr), .wr_data(wr_data), .pulse_envelope(pulse_envelope), .mixmode({noise_en[1], freq_en[1]}), .tone(tone1), .envreg(0),   .vol(vol[15: 8]), .out(out1));
saa1099_amp amp2(.rst(rst), .clk_sys(clk_sys), .noise(noise), .wr_addr(wr_addr), .wr_data(wr_data), .pulse_envelope(pulse_envelope), .mixmode({noise_en[2], freq_en[2]}), .tone(tone2), .envreg(env), .vol(vol[ 7: 0]), .out(out2));

assign out[10: 0] = out0[ 8:0] + out1[ 8:0] + out2[ 8:0];
assign out[21:11] = out0[17:9] + out1[17:9] + out2[17:9];

endmodule

/////////////////////////////////////////////////////////////////////////////////

module saa1099_tone
(
    input wire  rst,
    input wire  clk_sys,
    input wire  ce,

    input wire  [ 8:0] octave,
    input wire  [23:0] freq,
    output reg  out,
    output reg  pulse
);

wire [16:0] fcount = ((17'd511 - freq) << (4'd8 - octave)) - 1'd1;

    reg [16:0] count;

always @(posedge clk_sys) begin

    pulse <= 0;
	if(rst) begin
		count <= fcount;
		out   <= 0;
	end else if(ce) begin
		if(!count) begin
			count <= fcount;
			pulse <= 1;
			out <= ~out;
		end else begin
			count <= count - 1'd1;
		end
	end
end

endmodule

/////////////////////////////////////////////////////////////////////////////////

module saa1099_noise
(
    input wire       rst,
    input wire       clk_sys,
    input wire       ce,
    input wire       pulse_noise,
    input wire [1:0] noise_freq,
    output wire      out
);

reg  [16:0] lfsr = 0;
wire [16:0] new_lfsr = {(lfsr[0] ^ lfsr[2] ^ !lfsr), lfsr[16:1]};
wire [10:0] fcount = (11'd256 << noise_freq) - 1'b1;


reg [10:0] count;
always @(posedge clk_sys) begin

	if(rst) begin
		count <= fcount;
	end else
	if(noise_freq != 3) begin
		if(ce) begin
			if(!count) begin
				count <= fcount;
				lfsr <= new_lfsr;
			end else begin
				count <= count - 1'd1;
			end
		end
	end else if(pulse_noise) begin
		lfsr <= new_lfsr;
	end
end

assign out = lfsr[0];

endmodule

/////////////////////////////////////////////////////////////////////////////////

module saa1099_amp
(
    input wire        rst,
    input wire        clk_sys,
    
    input wire  [7:0] envreg,
    input wire  [1:0] mixmode,
    input wire        tone,
    
    input wire        noise,
    input wire        wr_addr,
    input wire        wr_data,
    input wire        pulse_envelope,

    input wire [23:0] vol,
    output reg [17:0] out
);

//wire  phases[8] = '{0,0,0,0,1,1,0,0};
wire    phases[0:7];
assign  phases[0] = 0;
assign  phases[1] = 0;
assign  phases[2] = 0;
assign  phases[3] = 0;
assign  phases[4] = 1;
assign  phases[5] = 1;
assign  phases[6] = 0;
assign  phases[7] = 0;

//wire [1:0] env[8][2] = '{'{0,0}, '{1,1}, '{2,0}, '{2,0}, '{3,2}, '{3,2}, '{3,0}, '{3,0}};
wire [1:0] env[0:7][0:1];
assign  env[0][0] = 0;
assign  env[0][1] = 0;
assign  env[1][0] = 1;
assign  env[1][1] = 1;
assign  env[2][0] = 2;
assign  env[2][1] = 0;
assign  env[3][0] = 2;
assign  env[3][1] = 0;
assign  env[4][0] = 3;
assign  env[4][1] = 2;
assign  env[5][0] = 3;
assign  env[5][1] = 2;
assign  env[6][0] = 3;
assign  env[6][1] = 0;
assign  env[7][0] = 3;
assign  env[7][1] = 0;

//wire [3:0] levels[4][16] =
wire [3:0] levels[0:3][0:15];
assign  levels[0][0]  =  0;
assign  levels[0][1]  =  0;
assign  levels[0][2]  =  0;
assign  levels[0][3]  =  0;
assign  levels[0][4]  =  0;
assign  levels[0][5]  =  0;
assign  levels[0][6]  =  0;
assign  levels[0][7]  =  0;
assign  levels[0][8]  =  0;
assign  levels[0][9]  =  0;
assign  levels[0][10] =  0;
assign  levels[0][11] =  0;
assign  levels[0][12] =  0;
assign  levels[0][13] =  0;
assign  levels[0][14] =  0;
assign  levels[0][15] =  0;

assign  levels[1][0]  =  15;
assign  levels[1][1]  =  15;
assign  levels[1][2]  =  15;
assign  levels[1][3]  =  15;
assign  levels[1][4]  =  15;
assign  levels[1][5]  =  15;
assign  levels[1][6]  =  15;
assign  levels[1][7]  =  15;
assign  levels[1][8]  =  15;
assign  levels[1][9]  =  15;
assign  levels[1][10] =  15;
assign  levels[1][11] =  15;
assign  levels[1][12] =  15;
assign  levels[1][13] =  15;
assign  levels[1][14] =  15;
assign  levels[1][15] =  15;

assign  levels[2][0]  =  15;
assign  levels[2][1]  =  14;
assign  levels[2][2]  =  13;
assign  levels[2][3]  =  12;
assign  levels[2][4]  =  11;
assign  levels[2][5]  =  10;
assign  levels[2][6]  =  9;
assign  levels[2][7]  =  8;
assign  levels[2][8]  =  7;
assign  levels[2][9]  =  6;
assign  levels[2][10] =  5;
assign  levels[2][11] =  4;
assign  levels[2][12] =  3;
assign  levels[2][13] =  2;
assign  levels[2][14] =  1;
assign  levels[2][15] =  0;

assign  levels[3][0]  =  0;
assign  levels[3][1]  =  1;
assign  levels[3][2]  =  2;
assign  levels[3][3]  =  3;
assign  levels[3][4]  =  4;
assign  levels[3][5]  =  5;
assign  levels[3][6]  =  6;
assign  levels[3][7]  =  7;
assign  levels[3][8]  =  8;
assign  levels[3][9]  =  9;
assign  levels[3][10] =  10;
assign  levels[3][11] =  11;
assign  levels[3][12] =  12;
assign  levels[3][13] =  13;
assign  levels[3][14] =  14;
assign  levels[3][15] =  15;

reg [2:0] shape;
reg       stereo;
wire      resolution = envreg[4];
wire      enable     = envreg[7];
reg [3:0] counter;
reg       phase;
wire[3:0] mask = {3'b000, resolution};

    reg clock;
    reg new_data;
always @(posedge clk_sys) begin


	if(rst | ~enable) begin
		new_data <= 0;
		stereo   <= envreg[0];
		shape    <= envreg[3:1];
		clock    <= envreg[5];
		phase    <= 0;
		counter  <= 0;
	end
	else begin
		if(wr_data) new_data <= 1;
		if(clock ? wr_addr : pulse_envelope) begin  // pulse from internal or external clock?
			counter <= counter + resolution + 1'd1;
			if((counter | mask) == 15) begin
				if(phase >= phases[shape]) begin
					if(~shape[0]) counter <= 15;
					if(new_data | shape[0]) begin // if we reached one of the designated points (3) or (4) and there is pending data, load it
						new_data <= 0;
						stereo   <= envreg[0];
						shape    <= envreg[3:1];
						clock    <= envreg[5];
						phase    <= 0;
						if(new_data) counter <= 0;
					end
				end else begin
					phase <= 1;
				end
			end
		end
	end
end

wire [3:0] env_l = levels[env[shape][phase]][counter] & ~mask;
wire [3:0] env_r = stereo ? (4'd15 & ~mask) - env_l : env_l; // bit 0 of envreg inverts envelope shape

reg  [1:0] outmix;
    always @* begin
	case(mixmode)
		0: outmix <= 0;
		1: outmix <= {tone,  1'b0};
		2: outmix <= {noise, 1'b0};
		3: outmix <= {tone & ~noise, tone & noise};
	endcase
end

//wire [8:0] vol_mix_l = {vol[3:1], vol[0] & ~enable, 5'b00000} >> outmix[0];
//wire [8:0] vol_mix_r = {vol[7:5], vol[4] & ~enable, 5'b00000} >> outmix[0];

wire [8:0] vol_mix_l = {vol[3:1], vol[0] & ~enable, 5'b00000} >> outmix[0];
wire [8:0] vol_mix_r = {vol[7:5], vol[4] & ~enable, 5'b00000} >> outmix[0];

wire [8:0] env_out_l;
wire [8:0] env_out_r;
saa1099_mul_env mod_l(.vol(vol_mix_l[8:4]), .env(env_l), .out(env_out_l));
saa1099_mul_env mod_r(.vol(vol_mix_r[8:4]), .env(env_r), .out(env_out_r));

    always @* begin
	case({enable, outmix})
//      'b100, 'b101: out = {env_out_r, env_out_l};
        3'b100:       out = {env_out_r, env_out_l};
        3'b101:       out = {env_out_r, env_out_l};
//      'b001, 'b010: out = {vol_mix_r, vol_mix_l};
        3'b001:       out = {vol_mix_r, vol_mix_l};
        3'b010:       out = {vol_mix_r, vol_mix_l};
		     default: out = 0;
	endcase
end

endmodule

/////////////////////////////////////////////////////////////////////////////////

module saa1099_mul_env
(
    input wire  [4:0] vol,
    input wire  [3:0] env,
    output wire [8:0] out
);

//assign out = (env[0] ?  vol          : 9'd0)+
//             (env[1] ? {vol, 1'b0  } : 9'd0)+
//             (env[2] ? {vol, 2'b00 } : 9'd0)+
//             (env[3] ? {vol, 3'b000} : 9'd0);
				 
assign out = (env[0] ? {4'b0000, vol        } : 9'd0)+
             (env[1] ? {3'b000 , vol, 1'b0  } : 9'd0)+
             (env[2] ? {2'b00  , vol, 2'b00 } : 9'd0)+
             (env[3] ? {1'b0   , vol, 3'b000} : 9'd0);
				 
//assign out = (env[0] ? {3'b000, vol, 1'b0   } : 9'd0)+
//             (env[1] ? {2'b00 , vol, 2'b00  } : 9'd0)+
//             (env[2] ? {1'b0  , vol, 3'b000 } : 9'd0)+
//             (env[3] ? {        vol, 4'b0000} : 9'd0);

endmodule

/////////////////////////////////////////////////////////////////////////////////

module saa1099_output_mixer
(
    input wire        clk_sys,
    input wire        ce,
    input wire        en,
    input wire [10:0] in0,
    input wire [10:0] in1,
    output reg [ 7:0] out
);

wire [17:0] o = 18'd91 * ({1'b0,in0} + {1'b0,in1});
//wire [17:0] o = 18'd91 * ({in0,1'b0} + {in1,1'b0});

// Clean the audio.
    reg ced;
always @(posedge clk_sys) begin

	ced <= ce;
	if(ced) out <= ~en ? 8'h00 : o[17:10];
end

endmodule
