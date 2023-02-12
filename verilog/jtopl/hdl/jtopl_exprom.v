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
    Date: 20-6-2020

*/

// Yamaha used the same table for OPN, OPM and OPL
// Originally written in more compact way that required some logic to decompress
// Not really worth compressing when the target is an FPGA as one BRAM will be
// used in either case. So it's better to leave it uncompress and save the 
// decoding logic

// altera message_off 10030

module jtopl_exprom
(
    input [7:0] addr,
    input clk, 
    input cen,
    output reg [9:0] exp
);

    reg [9:0] explut_jt51[255:0];
    initial
    begin
        explut_jt51[8'd000] = 10'd1018;
        explut_jt51[8'd001] = 10'd1013;
        explut_jt51[8'd002] = 10'd1007;
        explut_jt51[8'd003] = 10'd1002;
        explut_jt51[8'd004] = 10'd0996;
        explut_jt51[8'd005] = 10'd0991;
        explut_jt51[8'd006] = 10'd0986;
        explut_jt51[8'd007] = 10'd0980;
        explut_jt51[8'd008] = 10'd0975;
        explut_jt51[8'd009] = 10'd0969;
        explut_jt51[8'd010] = 10'd0964;
        explut_jt51[8'd011] = 10'd0959;
        explut_jt51[8'd012] = 10'd0953;
        explut_jt51[8'd013] = 10'd0948;
        explut_jt51[8'd014] = 10'd0942;
        explut_jt51[8'd015] = 10'd0937;
        explut_jt51[8'd016] = 10'd0932;
        explut_jt51[8'd017] = 10'd0927;
        explut_jt51[8'd018] = 10'd0921;
        explut_jt51[8'd019] = 10'd0916;
        explut_jt51[8'd020] = 10'd0911;
        explut_jt51[8'd021] = 10'd0906;
        explut_jt51[8'd022] = 10'd0900;
        explut_jt51[8'd023] = 10'd0895;
        explut_jt51[8'd024] = 10'd0890;
        explut_jt51[8'd025] = 10'd0885;
        explut_jt51[8'd026] = 10'd0880;
        explut_jt51[8'd027] = 10'd0874;
        explut_jt51[8'd028] = 10'd0869;
        explut_jt51[8'd029] = 10'd0864;
        explut_jt51[8'd030] = 10'd0859;
        explut_jt51[8'd031] = 10'd0854;
        explut_jt51[8'd032] = 10'd0849;
        explut_jt51[8'd033] = 10'd0844;
        explut_jt51[8'd034] = 10'd0839;
        explut_jt51[8'd035] = 10'd0834;
        explut_jt51[8'd036] = 10'd0829;
        explut_jt51[8'd037] = 10'd0824;
        explut_jt51[8'd038] = 10'd0819;
        explut_jt51[8'd039] = 10'd0814;
        explut_jt51[8'd040] = 10'd0809;
        explut_jt51[8'd041] = 10'd0804;
        explut_jt51[8'd042] = 10'd0799;
        explut_jt51[8'd043] = 10'd0794;
        explut_jt51[8'd044] = 10'd0789;
        explut_jt51[8'd045] = 10'd0784;
        explut_jt51[8'd046] = 10'd0779;
        explut_jt51[8'd047] = 10'd0774;
        explut_jt51[8'd048] = 10'd0770;
        explut_jt51[8'd049] = 10'd0765;
        explut_jt51[8'd050] = 10'd0760;
        explut_jt51[8'd051] = 10'd0755;
        explut_jt51[8'd052] = 10'd0750;
        explut_jt51[8'd053] = 10'd0745;
        explut_jt51[8'd054] = 10'd0741;
        explut_jt51[8'd055] = 10'd0736;
        explut_jt51[8'd056] = 10'd0731;
        explut_jt51[8'd057] = 10'd0726;
        explut_jt51[8'd058] = 10'd0722;
        explut_jt51[8'd059] = 10'd0717;
        explut_jt51[8'd060] = 10'd0712;
        explut_jt51[8'd061] = 10'd0708;
        explut_jt51[8'd062] = 10'd0703;
        explut_jt51[8'd063] = 10'd0698;
        explut_jt51[8'd064] = 10'd0693;
        explut_jt51[8'd065] = 10'd0689;
        explut_jt51[8'd066] = 10'd0684;
        explut_jt51[8'd067] = 10'd0680;
        explut_jt51[8'd068] = 10'd0675;
        explut_jt51[8'd069] = 10'd0670;
        explut_jt51[8'd070] = 10'd0666;
        explut_jt51[8'd071] = 10'd0661;
        explut_jt51[8'd072] = 10'd0657;
        explut_jt51[8'd073] = 10'd0652;
        explut_jt51[8'd074] = 10'd0648;
        explut_jt51[8'd075] = 10'd0643;
        explut_jt51[8'd076] = 10'd0639;
        explut_jt51[8'd077] = 10'd0634;
        explut_jt51[8'd078] = 10'd0630;
        explut_jt51[8'd079] = 10'd0625;
        explut_jt51[8'd080] = 10'd0621;
        explut_jt51[8'd081] = 10'd0616;
        explut_jt51[8'd082] = 10'd0612;
        explut_jt51[8'd083] = 10'd0607;
        explut_jt51[8'd084] = 10'd0603;
        explut_jt51[8'd085] = 10'd0599;
        explut_jt51[8'd086] = 10'd0594;
        explut_jt51[8'd087] = 10'd0590;
        explut_jt51[8'd088] = 10'd0585;
        explut_jt51[8'd089] = 10'd0581;
        explut_jt51[8'd090] = 10'd0577;
        explut_jt51[8'd091] = 10'd0572;
        explut_jt51[8'd092] = 10'd0568;
        explut_jt51[8'd093] = 10'd0564;
        explut_jt51[8'd094] = 10'd0560;
        explut_jt51[8'd095] = 10'd0555;
        explut_jt51[8'd096] = 10'd0551;
        explut_jt51[8'd097] = 10'd0547;
        explut_jt51[8'd098] = 10'd0542;
        explut_jt51[8'd099] = 10'd0538;
        explut_jt51[8'd100] = 10'd0534;
        explut_jt51[8'd101] = 10'd0530;
        explut_jt51[8'd102] = 10'd0526;
        explut_jt51[8'd103] = 10'd0521;
        explut_jt51[8'd104] = 10'd0517;
        explut_jt51[8'd105] = 10'd0513;
        explut_jt51[8'd106] = 10'd0509;
        explut_jt51[8'd107] = 10'd0505;
        explut_jt51[8'd108] = 10'd0501;
        explut_jt51[8'd109] = 10'd0496;
        explut_jt51[8'd110] = 10'd0492;
        explut_jt51[8'd111] = 10'd0488;
        explut_jt51[8'd112] = 10'd0484;
        explut_jt51[8'd113] = 10'd0480;
        explut_jt51[8'd114] = 10'd0476;
        explut_jt51[8'd115] = 10'd0472;
        explut_jt51[8'd116] = 10'd0468;
        explut_jt51[8'd117] = 10'd0464;
        explut_jt51[8'd118] = 10'd0460;
        explut_jt51[8'd119] = 10'd0456;
        explut_jt51[8'd120] = 10'd0452;
        explut_jt51[8'd121] = 10'd0448;
        explut_jt51[8'd122] = 10'd0444;
        explut_jt51[8'd123] = 10'd0440;
        explut_jt51[8'd124] = 10'd0436;
        explut_jt51[8'd125] = 10'd0432;
        explut_jt51[8'd126] = 10'd0428;
        explut_jt51[8'd127] = 10'd0424;
        explut_jt51[8'd128] = 10'd0420;
        explut_jt51[8'd129] = 10'd0416;
        explut_jt51[8'd130] = 10'd0412;
        explut_jt51[8'd131] = 10'd0409;
        explut_jt51[8'd132] = 10'd0405;
        explut_jt51[8'd133] = 10'd0401;
        explut_jt51[8'd134] = 10'd0397;
        explut_jt51[8'd135] = 10'd0393;
        explut_jt51[8'd136] = 10'd0389;
        explut_jt51[8'd137] = 10'd0385;
        explut_jt51[8'd138] = 10'd0382;
        explut_jt51[8'd139] = 10'd0378;
        explut_jt51[8'd140] = 10'd0374;
        explut_jt51[8'd141] = 10'd0370;
        explut_jt51[8'd142] = 10'd0367;
        explut_jt51[8'd143] = 10'd0363;
        explut_jt51[8'd144] = 10'd0359;
        explut_jt51[8'd145] = 10'd0355;
        explut_jt51[8'd146] = 10'd0352;
        explut_jt51[8'd147] = 10'd0348;
        explut_jt51[8'd148] = 10'd0344;
        explut_jt51[8'd149] = 10'd0340;
        explut_jt51[8'd150] = 10'd0337;
        explut_jt51[8'd151] = 10'd0333;
        explut_jt51[8'd152] = 10'd0329;
        explut_jt51[8'd153] = 10'd0326;
        explut_jt51[8'd154] = 10'd0322;
        explut_jt51[8'd155] = 10'd0318;
        explut_jt51[8'd156] = 10'd0315;
        explut_jt51[8'd157] = 10'd0311;
        explut_jt51[8'd158] = 10'd0308;
        explut_jt51[8'd159] = 10'd0304;
        explut_jt51[8'd160] = 10'd0300;
        explut_jt51[8'd161] = 10'd0297;
        explut_jt51[8'd162] = 10'd0293;
        explut_jt51[8'd163] = 10'd0290;
        explut_jt51[8'd164] = 10'd0286;
        explut_jt51[8'd165] = 10'd0283;
        explut_jt51[8'd166] = 10'd0279;
        explut_jt51[8'd167] = 10'd0276;
        explut_jt51[8'd168] = 10'd0272;
        explut_jt51[8'd169] = 10'd0268;
        explut_jt51[8'd170] = 10'd0265;
        explut_jt51[8'd171] = 10'd0262;
        explut_jt51[8'd172] = 10'd0258;
        explut_jt51[8'd173] = 10'd0255;
        explut_jt51[8'd174] = 10'd0251;
        explut_jt51[8'd175] = 10'd0248;
        explut_jt51[8'd176] = 10'd0244;
        explut_jt51[8'd177] = 10'd0241;
        explut_jt51[8'd178] = 10'd0237;
        explut_jt51[8'd179] = 10'd0234;
        explut_jt51[8'd180] = 10'd0231;
        explut_jt51[8'd181] = 10'd0227;
        explut_jt51[8'd182] = 10'd0224;
        explut_jt51[8'd183] = 10'd0220;
        explut_jt51[8'd184] = 10'd0217;
        explut_jt51[8'd185] = 10'd0214;
        explut_jt51[8'd186] = 10'd0210;
        explut_jt51[8'd187] = 10'd0207;
        explut_jt51[8'd188] = 10'd0204;
        explut_jt51[8'd189] = 10'd0200;
        explut_jt51[8'd190] = 10'd0197;
        explut_jt51[8'd191] = 10'd0194;
        explut_jt51[8'd192] = 10'd0190;
        explut_jt51[8'd193] = 10'd0187;
        explut_jt51[8'd194] = 10'd0184;
        explut_jt51[8'd195] = 10'd0181;
        explut_jt51[8'd196] = 10'd0177;
        explut_jt51[8'd197] = 10'd0174;
        explut_jt51[8'd198] = 10'd0171;
        explut_jt51[8'd199] = 10'd0168;
        explut_jt51[8'd200] = 10'd0164;
        explut_jt51[8'd201] = 10'd0161;
        explut_jt51[8'd202] = 10'd0158;
        explut_jt51[8'd203] = 10'd0155;
        explut_jt51[8'd204] = 10'd0152;
        explut_jt51[8'd205] = 10'd0148;
        explut_jt51[8'd206] = 10'd0145;
        explut_jt51[8'd207] = 10'd0142;
        explut_jt51[8'd208] = 10'd0139;
        explut_jt51[8'd209] = 10'd0136;
        explut_jt51[8'd210] = 10'd0133;
        explut_jt51[8'd211] = 10'd0130;
        explut_jt51[8'd212] = 10'd0126;
        explut_jt51[8'd213] = 10'd0123;
        explut_jt51[8'd214] = 10'd0120;
        explut_jt51[8'd215] = 10'd0117;
        explut_jt51[8'd216] = 10'd0114;
        explut_jt51[8'd217] = 10'd0111;
        explut_jt51[8'd218] = 10'd0108;
        explut_jt51[8'd219] = 10'd0105;
        explut_jt51[8'd220] = 10'd0102;
        explut_jt51[8'd221] = 10'd0099;
        explut_jt51[8'd222] = 10'd0096;
        explut_jt51[8'd223] = 10'd0093;
        explut_jt51[8'd224] = 10'd0090;
        explut_jt51[8'd225] = 10'd0087;
        explut_jt51[8'd226] = 10'd0084;
        explut_jt51[8'd227] = 10'd0081;
        explut_jt51[8'd228] = 10'd0078;
        explut_jt51[8'd229] = 10'd0075;
        explut_jt51[8'd230] = 10'd0072;
        explut_jt51[8'd231] = 10'd0069;
        explut_jt51[8'd232] = 10'd0066;
        explut_jt51[8'd233] = 10'd0063;
        explut_jt51[8'd234] = 10'd0060;
        explut_jt51[8'd235] = 10'd0057;
        explut_jt51[8'd236] = 10'd0054;
        explut_jt51[8'd237] = 10'd0051;
        explut_jt51[8'd238] = 10'd0048;
        explut_jt51[8'd239] = 10'd0045;
        explut_jt51[8'd240] = 10'd0042;
        explut_jt51[8'd241] = 10'd0040;
        explut_jt51[8'd242] = 10'd0037;
        explut_jt51[8'd243] = 10'd0034;
        explut_jt51[8'd244] = 10'd0031;
        explut_jt51[8'd245] = 10'd0028;
        explut_jt51[8'd246] = 10'd0025;
        explut_jt51[8'd247] = 10'd0022;
        explut_jt51[8'd248] = 10'd0020;
        explut_jt51[8'd249] = 10'd0017;
        explut_jt51[8'd250] = 10'd0014;
        explut_jt51[8'd251] = 10'd0011;
        explut_jt51[8'd252] = 10'd0008;
        explut_jt51[8'd253] = 10'd0006;
        explut_jt51[8'd254] = 10'd0003;
        explut_jt51[8'd255] = 10'd0000;
    end

    always @ (posedge clk) if(cen)
        exp <= explut_jt51[addr];

endmodule
