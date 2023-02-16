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
    
    reg bus_ior_synced_l;
    reg bus_iow_synced_l;
    wire opl_388_cs;
    wire cms_220_cs;
    reg[7:0] bus_int_out;

    // Mapped IO
    assign opl_388_cs = (bus_a[15:1] == (16'h0388 >> 1)) & ~bus_aen; // 0x388 .. 0x389 (Adlib)
    assign cms_220_cs = (bus_a[15:4] == (16'h0220 >> 4)) & ~bus_aen; // 0x220 .. 0x22F (CMS Audio)

    always @ (*)
    begin
        
        if (opl_388_cs & ~bus_ior_synced_l)
            bus_int_out <= jtopl2_dout;
        else if (cms_rd && ~bus_ior_synced_l)
            bus_int_out <= data_from_cms;
        else
            bus_int_out <= 8'h00;
        
    end
    
    // Synchronize ISA bus control lines to our clock
    always @ (posedge clk)
    begin
        bus_ior_synced_l <= bus_ior_l;
        bus_iow_synced_l <= bus_iow_l;
    end
    
    // Only for read operations does bus_dir go high.
    assign bus_dir = ((opl_388_cs | cms_rd) & ~bus_ior_synced_l);
    assign bus_out = bus_int_out;
    
    wire clk_en_opl2;
    wire ce_saa;
    reg [1:0] counter;

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    assign clk_en_opl2 = (counter == 2'b10);
    assign ce_saa = (counter == 2'b01) || (counter == 2'b11);
    
    
    // Game Blaster (CMS)
    wire cms_rd = (bus_a[3:0] == 4'h4 || bus_a[3:0] == 4'hB) && cms_220_cs;
    wire [7:0] data_from_cms = bus_a[3] ? cms_det : 8'h7F;

    wire cms_wr = ~bus_a[3] & cms_220_cs;

    reg [7:0] cms_det;
    always @(posedge clk) if(~bus_iow_synced_l && cms_wr && &bus_a[2:1]) cms_det <= bus_d;

    reg [15:0] o_cms;
    wire [7:0] saa1_l,saa1_r;
    saa1099 ssa1
    (
	    .clk_sys(clk),
	    .ce(ce_saa),
	    .rst_n(~reset),
	    .cs_n(~(cms_wr && (bus_a[2:1] == 0))),
	    .a0(bus_a[0]),
	    .wr_n(bus_iow_synced_l),
	    .din(bus_d),
	    .out_l(saa1_l),
	    .out_r(saa1_r)
    );

    wire [7:0] saa2_l,saa2_r;
    saa1099 ssa2
    (
	    .clk_sys(clk),
	    .ce(ce_saa),
	    .rst_n(~reset),
	    .cs_n(~(cms_wr && (bus_a[2:1] == 1))),
	    .a0(bus_a[0]),
	    .wr_n(bus_iow_synced_l),
	    .din(bus_d),
	    .out_l(saa2_l),
	    .out_r(saa2_r)
    );

    wire [8:0] cms_l = {1'b0, saa1_l} + {1'b0, saa2_l};
    wire [8:0] cms_r = {1'b0, saa1_r} + {1'b0, saa2_r};
	 
    reg [15:0] sample_pre;
    always @(posedge clk) begin
	    sample_pre <= {1'b0, cms_l, cms_l[8:4], 1'b0} + {1'b0, cms_r, cms_r[8:4], 1'b0};
    end

    always @(posedge clk) begin
	    o_cms <= $signed(sample_pre) >>> ~{3'd7};
    end

    // OPL2 sound  
    wire [15:0]jtopl2_snd_e;
    reg [31:0]sndval;
    
    wire [16:0]sndmix = (({jtopl2_snd_e[15], jtopl2_snd_e}) << 1) + (({o_cms[15], o_cms}) << 1) ; // signed mixer
    wire [15:0]sndamp = (~|sndmix[16:15] | &sndmix[16:15]) ? {!sndmix[15], sndmix[14:0]} : {16{!sndmix[16]}}; // clamp to [-32768..32767] and add 32878
    wire sndsign = sndval[31:16] < sndamp;
    
    always @(posedge clk) begin	
        sndval <= sndval - sndval[31:7] + (sndsign << 25);
    end

    assign opl2_snd_e = {7{sndsign}};
    
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
        .wr_n(bus_iow_synced_l),
        .irq_n(),
        .snd(jtopl2_snd_e),
        .sample()
    );

endmodule
