// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
`timescale 1ns / 1ps

// Test bench for ISA Video

module isavideo_t;
    reg clk;
    wire hsync;
    wire vsync;
    wire video;

    reg[19:0] bus_a;
    wire[7:0] bus_d;
    reg[7:0] bus_d_out;
    reg bus_d_write = 0;
    wire bus_rdy;

    assign bus_d = (bus_d_write) ? bus_d_out : 8'hZZ;

    reg bus_ior_l = 1;
    reg bus_iow_l = 1;
    reg bus_memr_l = 1;
    reg bus_memw_l = 1;
    reg bus_aen = 1;

    wire ram_we_l;
    wire[18:0] ram_a;
    wire[7:0] ram_d;
    // Use isavideo here for HGC, cga_top for CGA.
    cga_top dut (
//        .clk_10m(clk), // for HGC
        .clk_14m318(clk), // for CGA

        .bus_a(bus_a),
        .bus_ior_l(bus_ior_l),
        .bus_iow_l(bus_iow_l),
        .bus_memr_l(bus_memr_l),
        .bus_memw_l(bus_memw_l),
        .bus_aen(bus_aen),
        .bus_d(bus_d),
        .bus_rdy(bus_rdy),

        .ram_we_l(ram_we_l),
        .ram_d(ram_d),
        .ram_a(ram_a),

        .hsync(hsync),
        .vsync(vsync),
        .d_b2(video),
        .switch3(1'b0),
        .switch2(1'b0)
    );

    is61c5128 vram(
        .address(ram_a),
        .data(ram_d),
        .ce_l(0),
        .oe_l(0),
        .we_l(ram_we_l)
    );

    // 15=33.3MHz
    // 8=62.5MHz
    // 17=29.4MHz
    always #17 clk = ~clk;

    task isa_op;
        input state;
        input read;
        input io;
        begin
            if (read) begin
                if (io) begin
                    bus_ior_l = state;
                end else begin
                    bus_memr_l = state;
                end
            end else begin
                if (io) begin
                    bus_iow_l = state;
                end else begin
                    bus_memw_l = state;
                end
            end
        end
    endtask

    task isa_cycle;
        input[19:0] addr;
        input[7:0] data;
        input read;
        input io;
        begin
            bus_a = addr;
            bus_d_write = !read;
            bus_d_out = data;
            #176
            isa_op(0, read, io);
            #420
            wait(bus_rdy);
            isa_op(1, read, io);
            #236
            bus_d_write = 0;
        end
    endtask

    task crtc_write;
        input[7:0] addr;
        input[7:0] data;
        begin
           isa_cycle(20'h3D4, addr, 0, 1);
           isa_cycle(20'h3D5, data, 0, 1);
        end
    endtask

    integer i;

    initial begin
        clk = 0;
        $dumpfile("isavideo_t.vcd");
        $dumpvars(0,isavideo_t);

        bus_aen = 0;

        // Set up graphics mode for this test.
        isa_cycle(20'h3D8, 8'b0000_1011, 0, 1); // 0000_1010
        isa_cycle(20'h3D9, 8'b0000_0000, 0, 1);
        crtc_write(8'd0, 8'd56);
        crtc_write(8'd1, 8'd40);
        crtc_write(8'd2, 8'd45);
        crtc_write(8'd4, 8'd127);
        crtc_write(8'd6, 8'd100);
        crtc_write(8'd7, 8'd112);
        crtc_write(8'd9, 8'd1);




        bus_a = 20'hB8055;
        bus_d_out = 8'hAA;
        bus_d_write = 1;
        #430
        #120 bus_memw_l = 0;
        #200 bus_memw_l = 1;
        #10 bus_d_write = 0;
        #100 bus_memr_l = 0;
        #200 bus_memr_l = 1;

        for (i = 0; i < 20; i++) begin
        #12
            #400
            bus_a = 20'hB8000 | i;
            bus_d_out = 8'h11; //8'hA0 + i;
            bus_memw_l = 0;
            bus_d_write = 1;
            #600
            wait(bus_rdy);
            bus_memw_l = 1; // was 200
            #50 bus_d_write = 0;
        end
        #400
        for (i = 0; i < 20; i++) begin
        #12
            #400
            bus_a = 20'hB8000 | i;
            bus_memr_l = 0;
            bus_d_write = 0;
            #600
            wait(bus_rdy);
            bus_memr_l = 1;
        end
        #400
        for (i = 0; i < 20; i+=2) begin
        bus_a = 20'hB8000 | i;
        bus_d_write = 0;
        #176
        bus_memr_l = 0;
        #420
        wait(bus_rdy);
        bus_memr_l = 1;
        #236
        bus_a = 20'hB8000 | (i + 1);
        #174
        bus_memr_l = 0;
        #420
        wait(bus_rdy);
        bus_memr_l = 1;
        #886
        bus_a = 20'hB8000 | i;
        bus_d_out = 8'h00 + (2<<(i&7));
        bus_d_write = 1;
        #164
        bus_memw_l = 0;
        #420
        wait(bus_rdy);
        bus_memw_l = 1;
        #224
        bus_a = 20'hB8000 | (i + 1);
        bus_d_out = 8'h00 + (2<<((i + 1)&7));
        #196
        bus_memw_l = 0;
        #420
        wait(bus_rdy);
        bus_memw_l = 1;
        #1494
        bus_d_write = 0;
        end

        // Try to write to CRTC
        bus_a = 20'h3D4;
        bus_aen = 0;
        bus_iow_l = 0;
        bus_d_write = 1;
        bus_d_out = 8'd1;
        #600 bus_iow_l = 1;
        bus_aen = 1;
        #400
        bus_a = 20'h3D5;
        bus_aen = 0;
        bus_iow_l = 0;
        bus_d_write = 1;
        bus_d_out = 8'd5;
        #600 bus_iow_l = 1;
        bus_aen = 1;
        bus_d_write = 0;
        #400
        bus_aen = 0;
        bus_ior_l = 0;
        bus_d_write = 0;
        #600 bus_ior_l = 1;
        bus_aen = 0;
        #350000 $finish;
          #10000 $finish;
    end
endmodule

