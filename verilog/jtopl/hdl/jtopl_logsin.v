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
    Date: 13-6-2020

*/

//altera message_off 10030

module jtopl_logsin(
    input             clk,
    input             cen,
    input      [ 7:0] addr,
    output reg [11:0] logsin
);  

reg [11:0] sinelut[255:0];
initial begin
    sinelut[8'd000] = 12'h000;
    sinelut[8'd001] = 12'h000;
    sinelut[8'd002] = 12'h000;
    sinelut[8'd003] = 12'h000;
    sinelut[8'd004] = 12'h000;
    sinelut[8'd005] = 12'h000;
    sinelut[8'd006] = 12'h000;
    sinelut[8'd007] = 12'h000;
    sinelut[8'd008] = 12'h001;
    sinelut[8'd009] = 12'h001;
    sinelut[8'd010] = 12'h001;
    sinelut[8'd011] = 12'h001;
    sinelut[8'd012] = 12'h001;
    sinelut[8'd013] = 12'h001;
    sinelut[8'd014] = 12'h001;
    sinelut[8'd015] = 12'h002;
    sinelut[8'd016] = 12'h002;
    sinelut[8'd017] = 12'h002;
    sinelut[8'd018] = 12'h002;
    sinelut[8'd019] = 12'h003;
    sinelut[8'd020] = 12'h003;
    sinelut[8'd021] = 12'h003;
    sinelut[8'd022] = 12'h004;
    sinelut[8'd023] = 12'h004;
    sinelut[8'd024] = 12'h004;
    sinelut[8'd025] = 12'h005;
    sinelut[8'd026] = 12'h005;
    sinelut[8'd027] = 12'h005;
    sinelut[8'd028] = 12'h006;
    sinelut[8'd029] = 12'h006;
    sinelut[8'd030] = 12'h007;
    sinelut[8'd031] = 12'h007;
    sinelut[8'd032] = 12'h007;
    sinelut[8'd033] = 12'h008;
    sinelut[8'd034] = 12'h008;
    sinelut[8'd035] = 12'h009;
    sinelut[8'd036] = 12'h009;
    sinelut[8'd037] = 12'h00a;
    sinelut[8'd038] = 12'h00a;
    sinelut[8'd039] = 12'h00b;
    sinelut[8'd040] = 12'h00c;
    sinelut[8'd041] = 12'h00c;
    sinelut[8'd042] = 12'h00d;
    sinelut[8'd043] = 12'h00d;
    sinelut[8'd044] = 12'h00e;
    sinelut[8'd045] = 12'h00f;
    sinelut[8'd046] = 12'h00f;
    sinelut[8'd047] = 12'h010;
    sinelut[8'd048] = 12'h011;
    sinelut[8'd049] = 12'h011;
    sinelut[8'd050] = 12'h012;
    sinelut[8'd051] = 12'h013;
    sinelut[8'd052] = 12'h014;
    sinelut[8'd053] = 12'h014;
    sinelut[8'd054] = 12'h015;
    sinelut[8'd055] = 12'h016;
    sinelut[8'd056] = 12'h017;
    sinelut[8'd057] = 12'h017;
    sinelut[8'd058] = 12'h018;
    sinelut[8'd059] = 12'h019;
    sinelut[8'd060] = 12'h01a;
    sinelut[8'd061] = 12'h01b;
    sinelut[8'd062] = 12'h01c;
    sinelut[8'd063] = 12'h01d;
    sinelut[8'd064] = 12'h01e;
    sinelut[8'd065] = 12'h01f;
    sinelut[8'd066] = 12'h020;
    sinelut[8'd067] = 12'h021;
    sinelut[8'd068] = 12'h022;
    sinelut[8'd069] = 12'h023;
    sinelut[8'd070] = 12'h024;
    sinelut[8'd071] = 12'h025;
    sinelut[8'd072] = 12'h026;
    sinelut[8'd073] = 12'h027;
    sinelut[8'd074] = 12'h028;
    sinelut[8'd075] = 12'h029;
    sinelut[8'd076] = 12'h02a;
    sinelut[8'd077] = 12'h02b;
    sinelut[8'd078] = 12'h02d;
    sinelut[8'd079] = 12'h02e;
    sinelut[8'd080] = 12'h02f;
    sinelut[8'd081] = 12'h030;
    sinelut[8'd082] = 12'h031;
    sinelut[8'd083] = 12'h033;
    sinelut[8'd084] = 12'h034;
    sinelut[8'd085] = 12'h035;
    sinelut[8'd086] = 12'h037;
    sinelut[8'd087] = 12'h038;
    sinelut[8'd088] = 12'h039;
    sinelut[8'd089] = 12'h03b;
    sinelut[8'd090] = 12'h03c;
    sinelut[8'd091] = 12'h03e;
    sinelut[8'd092] = 12'h03f;
    sinelut[8'd093] = 12'h040;
    sinelut[8'd094] = 12'h042;
    sinelut[8'd095] = 12'h043;
    sinelut[8'd096] = 12'h045;
    sinelut[8'd097] = 12'h046;
    sinelut[8'd098] = 12'h048;
    sinelut[8'd099] = 12'h04a;
    sinelut[8'd100] = 12'h04b;
    sinelut[8'd101] = 12'h04d;
    sinelut[8'd102] = 12'h04e;
    sinelut[8'd103] = 12'h050;
    sinelut[8'd104] = 12'h052;
    sinelut[8'd105] = 12'h053;
    sinelut[8'd106] = 12'h055;
    sinelut[8'd107] = 12'h057;
    sinelut[8'd108] = 12'h059;
    sinelut[8'd109] = 12'h05b;
    sinelut[8'd110] = 12'h05c;
    sinelut[8'd111] = 12'h05e;
    sinelut[8'd112] = 12'h060;
    sinelut[8'd113] = 12'h062;
    sinelut[8'd114] = 12'h064;
    sinelut[8'd115] = 12'h066;
    sinelut[8'd116] = 12'h068;
    sinelut[8'd117] = 12'h06a;
    sinelut[8'd118] = 12'h06c;
    sinelut[8'd119] = 12'h06e;
    sinelut[8'd120] = 12'h070;
    sinelut[8'd121] = 12'h072;
    sinelut[8'd122] = 12'h074;
    sinelut[8'd123] = 12'h076;
    sinelut[8'd124] = 12'h078;
    sinelut[8'd125] = 12'h07a;
    sinelut[8'd126] = 12'h07d;
    sinelut[8'd127] = 12'h07f;
    sinelut[8'd128] = 12'h081;
    sinelut[8'd129] = 12'h083;
    sinelut[8'd130] = 12'h086;
    sinelut[8'd131] = 12'h088;
    sinelut[8'd132] = 12'h08a;
    sinelut[8'd133] = 12'h08d;
    sinelut[8'd134] = 12'h08f;
    sinelut[8'd135] = 12'h092;
    sinelut[8'd136] = 12'h094;
    sinelut[8'd137] = 12'h097;
    sinelut[8'd138] = 12'h099;
    sinelut[8'd139] = 12'h09c;
    sinelut[8'd140] = 12'h09f;
    sinelut[8'd141] = 12'h0a1;
    sinelut[8'd142] = 12'h0a4;
    sinelut[8'd143] = 12'h0a7;
    sinelut[8'd144] = 12'h0a9;
    sinelut[8'd145] = 12'h0ac;
    sinelut[8'd146] = 12'h0af;
    sinelut[8'd147] = 12'h0b2;
    sinelut[8'd148] = 12'h0b5;
    sinelut[8'd149] = 12'h0b8;
    sinelut[8'd150] = 12'h0bb;
    sinelut[8'd151] = 12'h0be;
    sinelut[8'd152] = 12'h0c1;
    sinelut[8'd153] = 12'h0c4;
    sinelut[8'd154] = 12'h0c7;
    sinelut[8'd155] = 12'h0ca;
    sinelut[8'd156] = 12'h0cd;
    sinelut[8'd157] = 12'h0d1;
    sinelut[8'd158] = 12'h0d4;
    sinelut[8'd159] = 12'h0d7;
    sinelut[8'd160] = 12'h0db;
    sinelut[8'd161] = 12'h0de;
    sinelut[8'd162] = 12'h0e2;
    sinelut[8'd163] = 12'h0e5;
    sinelut[8'd164] = 12'h0e9;
    sinelut[8'd165] = 12'h0ec;
    sinelut[8'd166] = 12'h0f0;
    sinelut[8'd167] = 12'h0f4;
    sinelut[8'd168] = 12'h0f8;
    sinelut[8'd169] = 12'h0fb;
    sinelut[8'd170] = 12'h0ff;
    sinelut[8'd171] = 12'h103;
    sinelut[8'd172] = 12'h107;
    sinelut[8'd173] = 12'h10b;
    sinelut[8'd174] = 12'h10f;
    sinelut[8'd175] = 12'h114;
    sinelut[8'd176] = 12'h118;
    sinelut[8'd177] = 12'h11c;
    sinelut[8'd178] = 12'h121;
    sinelut[8'd179] = 12'h125;
    sinelut[8'd180] = 12'h129;
    sinelut[8'd181] = 12'h12e;
    sinelut[8'd182] = 12'h133;
    sinelut[8'd183] = 12'h137;
    sinelut[8'd184] = 12'h13c;
    sinelut[8'd185] = 12'h141;
    sinelut[8'd186] = 12'h146;
    sinelut[8'd187] = 12'h14b;
    sinelut[8'd188] = 12'h150;
    sinelut[8'd189] = 12'h155;
    sinelut[8'd190] = 12'h15b;
    sinelut[8'd191] = 12'h160;
    sinelut[8'd192] = 12'h166;
    sinelut[8'd193] = 12'h16b;
    sinelut[8'd194] = 12'h171;
    sinelut[8'd195] = 12'h177;
    sinelut[8'd196] = 12'h17c;
    sinelut[8'd197] = 12'h182;
    sinelut[8'd198] = 12'h188;
    sinelut[8'd199] = 12'h18f;
    sinelut[8'd200] = 12'h195;
    sinelut[8'd201] = 12'h19b;
    sinelut[8'd202] = 12'h1a2;
    sinelut[8'd203] = 12'h1a9;
    sinelut[8'd204] = 12'h1b0;
    sinelut[8'd205] = 12'h1b7;
    sinelut[8'd206] = 12'h1be;
    sinelut[8'd207] = 12'h1c5;
    sinelut[8'd208] = 12'h1cd;
    sinelut[8'd209] = 12'h1d4;
    sinelut[8'd210] = 12'h1dc;
    sinelut[8'd211] = 12'h1e4;
    sinelut[8'd212] = 12'h1ec;
    sinelut[8'd213] = 12'h1f5;
    sinelut[8'd214] = 12'h1fd;
    sinelut[8'd215] = 12'h206;
    sinelut[8'd216] = 12'h20f;
    sinelut[8'd217] = 12'h218;
    sinelut[8'd218] = 12'h222;
    sinelut[8'd219] = 12'h22c;
    sinelut[8'd220] = 12'h236;
    sinelut[8'd221] = 12'h240;
    sinelut[8'd222] = 12'h24b;
    sinelut[8'd223] = 12'h256;
    sinelut[8'd224] = 12'h261;
    sinelut[8'd225] = 12'h26d;
    sinelut[8'd226] = 12'h279;
    sinelut[8'd227] = 12'h286;
    sinelut[8'd228] = 12'h293;
    sinelut[8'd229] = 12'h2a0;
    sinelut[8'd230] = 12'h2af;
    sinelut[8'd231] = 12'h2bd;
    sinelut[8'd232] = 12'h2cd;
    sinelut[8'd233] = 12'h2dc;
    sinelut[8'd234] = 12'h2ed;
    sinelut[8'd235] = 12'h2ff;
    sinelut[8'd236] = 12'h311;
    sinelut[8'd237] = 12'h324;
    sinelut[8'd238] = 12'h339;
    sinelut[8'd239] = 12'h34e;
    sinelut[8'd240] = 12'h365;
    sinelut[8'd241] = 12'h37e;
    sinelut[8'd242] = 12'h398;
    sinelut[8'd243] = 12'h3b5;
    sinelut[8'd244] = 12'h3d3;
    sinelut[8'd245] = 12'h3f5;
    sinelut[8'd246] = 12'h41a;
    sinelut[8'd247] = 12'h443;
    sinelut[8'd248] = 12'h471;
    sinelut[8'd249] = 12'h4a6;
    sinelut[8'd250] = 12'h4e4;
    sinelut[8'd251] = 12'h52e;
    sinelut[8'd252] = 12'h58b;
    sinelut[8'd253] = 12'h607;
    sinelut[8'd254] = 12'h6c3;
    sinelut[8'd255] = 12'h859;
end

always @ (posedge clk) if(cen) begin
    logsin <= sinelut[addr];
end

endmodule
