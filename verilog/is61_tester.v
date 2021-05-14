// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
`timescale 1ns / 1ps
module is61_tester;

    reg[18:0] address;
    wire[7:0] data;
    reg ce_l;
    reg oe_l;
    reg we_l;

    reg[7:0] data_out;
    reg data_dir;

    assign data = data_dir ? data_out : 8'hzz;

    is61c5128 dut(
        .address(address),
        .data(data),
        .ce_l(ce_l),
        .oe_l(oe_l),
        .we_l(we_l)
        );

    initial begin
        $dumpfile("is61_tester.vcd");
        $dumpvars(0,is61_tester);
        ce_l = 1;
        oe_l = 1;
        we_l = 1;
        address = 19'h00000;
        data_out = 8'h00;
        data_dir = 0;

        #500
        data_dir = 1;
        data_out = 8'hAA;
        ce_l = 0;
        oe_l = 0;
        we_l = 0;
        #10
        we_l = 1;
        data_dir = 0;
        #10
        address = 19'h1;
        data_dir = 1;
        data_out = 8'h55;
        we_l = 0;
        #10
        we_l = 1;
        data_dir = 0;
        #10
        address = 19'h0;


        #100 $finish;
    end
endmodule
