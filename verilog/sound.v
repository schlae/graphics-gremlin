// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// Copyright (c) 2023 Aitor Gomez Garcia (spark2k06)
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
`default_nettype wire
module sound(
    input reset,
    // Clocks
    input clk,

    // ISA bus
    input[19:0] bus_a,
    input bus_ior_l,
    input bus_iow_l,
    input[7:0] bus_d,
    output[7:0] bus_out,
    output bus_dir,
    input bus_aen,
    output bus_rdy = 1,
    output [6:0] opl2_snd_e
    );

    wire opl_388_cs;
    reg[7:0] bus_int_out;

    // Mapped IO
    assign opl_388_cs = (bus_a[15:1] == (16'h0388 >> 1)) & ~bus_aen; // 0x388 .. 0x389 (Adlib)

    always @ (*)
    begin
        
        if (opl_388_cs & ~bus_ior_l)
            bus_int_out <= jtopl2_dout;
        else
            bus_int_out <= 8'h00;
        
    end

    // Only for read operations does bus_dir go high.
    assign bus_dir = (opl_388_cs & ~bus_ior_l);
    assign bus_out = bus_int_out;

    // OPL2 sound   
    wire clk_en_opl2;    
    reg [1:0] counter;

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    assign clk_en_opl2 = (counter == 2'b10);
  
    wire [15:0]jtopl2_snd_e;
    reg [31:0]sndval;
    
    wire [16:0]sndmix = (({jtopl2_snd_e[15], jtopl2_snd_e}) << 1); // signed mixer    
    wire [15:0]sndamp = (~|sndmix[16:15] | &sndmix[16:15]) ? {!sndmix[15], sndmix[14:0]} : {16{!sndmix[16]}}; // clamp to [-32768..32767] and add 32878
    wire sndsign = sndval[31:16] < sndamp;
    
    always @(posedge clk) begin	
        sndval <= sndval - sndval[31:7] + (sndsign << 25);
    end
            
    assign opl2_snd_e = {sndsign, sndsign, sndsign, sndsign, sndsign, sndsign, sndsign};
    
    wire [7:0] jtopl2_dout;
    
    jtopl2 jtopl2_inst
    (
        .rst(reset),
        .clk(clk),
        .cen(clk_en_opl2),
        .din(bus_d),
        .dout(jtopl2_dout),
        .addr(bus_a[0]),
        .cs_n(~opl_388_cs),
        .wr_n(bus_iow_l),
        .irq_n(),
        .snd(jtopl2_snd_e),
        .sample()
    );

endmodule
