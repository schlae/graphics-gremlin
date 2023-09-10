`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.09.2023 10:54:51
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
	input clk,
	
	input hdmi_red,
    input hdmi_grn,
    input hdmi_blu,
    input hdmi_int,
    input hdmi_vs,
    input hdmi_hs,
    input hdmi_clk,
    input hdmi_de,
    
	output [2:0] TMDSp, TMDSn,
	output TMDSp_clock, TMDSn_clock
    );
    

    
    HDMI_test(clk, hdmi_red, hdmi_grn, hdmi_blu, hdmi_int, hdmi_vs, hdmi_hs, hdmi_clk, hdmi_de, TMDSp, TMDSn, TMDSp_clock, TMDSn_clock);
    
endmodule
