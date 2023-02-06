// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
`default_nettype wire
module cga(
    // Clocks
    input clk,

    // ISA bus
    input[19:0] bus_a,
    input bus_ior_l,
    input bus_iow_l,
    input bus_memr_l,
    input bus_memw_l,
    input[7:0] bus_d,
    output[7:0] bus_out,
    output bus_dir,
    input bus_aen,
    output bus_rdy,

    // RAM
    output ram_we_l,
    output[18:0] ram_a,
    inout[7:0] ram_d,

    // Video outputs
    output hsync,
    output dbl_hsync,
    output vsync,
    output[3:0] video,
    output[3:0] dbl_video,
    output[6:0] comp_video,

    input thin_font
    );

    parameter MDA_70HZ = 0;
    parameter BLINK_MAX = 0;
    // `define CGA_SNOW = 1; No snow

    parameter USE_BUS_WAIT = 0; // Should we add wait states on the ISA bus?
    parameter NO_DISPLAY_DISABLE = 1; // If 1, prevents flicker artifacts in DOS

    parameter IO_BASE_ADDR = 20'h3d0; // MDA is 3B0, CGA is 3D0
    parameter FRAMEBUFFER_ADDR = 20'hB8000; // MDA is B0000, CGA is B8000

    wire crtc_cs;
    wire status_cs;
    wire tandy_newcolorsel_cs;
    wire colorsel_cs;
    wire control_cs;
    wire bus_mem_cs;
    wire video_mem_cs;
    wire tandy_page_cs;
    wire nmi_mask_register_cs;
    wire tandy_mode_cs;

    reg[7:0] bus_int_out;
    wire[7:0] bus_out_crtc;
    wire[7:0] bus_out_mem;
    wire[7:0] cga_status_reg;
    reg[7:0] cga_control_reg = 8'b0010_1000; // 0010_1001
    reg[7:0] cga_color_reg = 8'b0000_0000;
    reg[7:0] tandy_color_reg = 8'b0000_0000;
    reg[3:0] tandy_newcolor = 4'b0000;
    reg[3:0] tandy_bordercol = 4'b0000;
    reg[4:0] tandy_modesel = 5'b00000;
    reg tandy_palette_set;
    wire hres_mode;
    wire grph_mode;
    wire bw_mode;
    wire mode_640;
    wire video_enabled;
    wire blink_enabled;

    wire hsync_int;
    wire vsync_l;
    wire cursor;
    wire[3:0] video;
    wire display_enable;

    // Two different clocks from the sequencer
    wire hclk;
    wire lclk;

    wire[13:0] crtc_addr;
    wire[4:0] row_addr;
    wire line_reset;
    wire pixel_addr13;
    wire pixel_addr14;

    wire charrom_read;
    wire disp_pipeline;
    wire isa_op_enable;
    wire vram_read_char;
    wire vram_read_att;
    wire vram_read;
    wire vram_read_a0;
    wire[4:0] clkdiv;
    wire crtc_clk;
    wire[7:0] ram_1_d;

    reg[23:0] blink_counter = 24'd0;
    reg blink = 0;

    reg bus_memw_synced_l;
    reg bus_memr_synced_l;
    reg bus_ior_synced_l;
    reg bus_iow_synced_l;

    wire cpu_memsel;
    reg[1:0] wait_state = 2'd0;
    reg bus_rdy_latch;
    reg [7:0] tandy_page_data = 8'h00;
    reg [7:0] nmi_mask_register_data = 8'hFF;
    reg tandy_mode = 1'b0;

    // Synchronize ISA bus control lines to our clock
    always @ (posedge clk)
    begin
        bus_memw_synced_l <= bus_memw_l;
        bus_memr_synced_l <= bus_memr_l;
        bus_ior_synced_l <= bus_ior_l;
        bus_iow_synced_l <= bus_iow_l;
    end

    // Some modules need a non-inverted vsync trigger
    assign vsync = ~vsync_l;

    // Mapped IO
    assign crtc_cs = (bus_a[19:3] == IO_BASE_ADDR[19:3]) & ~bus_aen; // 3B4/3B5
    assign status_cs = (bus_a == IO_BASE_ADDR + 20'hA) & ~bus_aen;
    assign tandy_newcolorsel_cs = (bus_a == IO_BASE_ADDR + 20'hE) & ~bus_aen;
    assign control_cs = (bus_a == IO_BASE_ADDR + 20'h8) & ~bus_aen;
    assign colorsel_cs = (bus_a == IO_BASE_ADDR + 20'h9) & ~bus_aen;
    assign tandy_mode_cs = (bus_a[15:0] == 16'h0370) & ~bus_aen;
    assign tandy_page_cs = (bus_a[15:0] == 16'h03DF) & ~bus_aen & tandy_mode;
    assign nmi_mask_register_cs = (bus_a[15:3] == (16'h00a0 >> 3)) & ~bus_aen & tandy_mode; // 0xa0 .. 0xa7
   
    assign bus_mem_cs = (bus_a[19:15] == FRAMEBUFFER_ADDR[19:15]); // B8000 - BFFFF (16 KB / 32 KB)
    assign video_mem_cs = (bus_a[19:17] == nmi_mask_register_data[3:1]) & tandy_mode; // 128KB
    
    /*    
    // Tandy base memory shared, not implementable with Graphics Gremlin, address is only input by design
    // As a result, some games or programs designed for Tandy will not be able to run or be played
    always @ (*)
    begin
        if (bus_mem_cs && ~bus_iow_l && tandy_mode)
            latch_bus_a   = {nmi_mask_register_data[3:1], tandy_page_data[3] ? {1'b0, tandy_page_data[5:3], bus_a[14:0]} : {2'b00, tandy_page_data[5:4], bus_a[14:0]}};
        else
            latch_bus_a   = bus_a;
    end
    */

    // Mux ISA bus data from every possible internal source.
    always @ (*)
    begin
        if (bus_mem_cs & ~bus_memr_l) begin
            bus_int_out <= bus_out_mem;
        end else if (status_cs & ~bus_ior_l) begin
            bus_int_out <= cga_status_reg;            
        end else if (tandy_mode_cs & ~bus_ior_l) begin
            bus_int_out <= {7'b0, tandy_mode};
        end else if (nmi_mask_register_cs & ~bus_ior_l) begin
            bus_int_out <= nmi_mask_register_data;
        end else if (crtc_cs & ~bus_ior_l & (bus_a[0] == 1)) begin
            bus_int_out <= bus_out_crtc;
        end else begin
            bus_int_out <= 8'h00;
        end
    end

    // Only for read operations does bus_dir go high.
    assign bus_dir = ((crtc_cs | status_cs | tandy_mode_cs | nmi_mask_register_cs) & ~bus_ior_l) |
                    (bus_mem_cs & ~bus_memr_l);
    assign bus_out = bus_int_out;

    // Wait state generator
    // Optional for operation but required to run timing-sensitive demos
    // e.g. 8088MPH.
    if (USE_BUS_WAIT == 0) begin
        assign bus_rdy = 1;
    end else begin
        assign bus_rdy = bus_rdy_latch;
    end

    assign cpu_memsel = bus_mem_cs & (~bus_memr_l | ~bus_memw_l);

    always @ (posedge clk)
    begin
        if (cpu_memsel) begin
            case (wait_state)
                2'b00: begin
                    if (clkdiv == 5'd17) wait_state <= 2'b01;
                    bus_rdy_latch <= 0;
                end
                2'b01: begin
                    if (clkdiv == 5'd20) wait_state <= 2'b10;
                    bus_rdy_latch <= 0;
                end
                2'b10: begin
                    wait_state <= 2'b10;
                    bus_rdy_latch <= 1;
                end
                default: begin
                    wait_state <= 2'b00;
                    bus_rdy_latch <= 0;
                end
            endcase
        end else begin
            wait_state <= 2'b00;
            bus_rdy_latch <= 1;
        end
    end


    // status register (read only at 3BA)
    // FIXME: vsync_l should be delayed/synced to HCLK.
    assign cga_status_reg = {4'b1111, vsync_l, 2'b10, ~display_enable};

    // mode control register (write only)
    //
    assign hres_mode = cga_control_reg[0]; // 1=80x25,0=40x25
    assign grph_mode = cga_control_reg[1]; // 1=graphics, 0=text
    assign bw_mode = cga_control_reg[2]; // 1=b&w, 0=color
    if (NO_DISPLAY_DISABLE == 1) begin
        assign video_enabled = 1;
    end else begin
        assign video_enabled = cga_control_reg[3];
    end
    assign mode_640 = cga_control_reg[4]; // 1=640x200 mode, 0=others
    assign blink_enabled = cga_control_reg[5];

	assign tandy_border_en = tandy_modesel[2];
	assign tandy_color_4 = tandy_modesel[3];
	assign tandy_color_16 = tandy_modesel[4];

    assign hsync = hsync_int;
    
    // Update control or color register
    always @ (posedge clk)
    begin
        tandy_palette_set <= 1'b0;
        if (~bus_iow_synced_l) begin
            if (control_cs) begin
                cga_control_reg <= bus_d;
            end else if (colorsel_cs) begin
                cga_color_reg <= bus_d;
            end else if (status_cs) begin
                tandy_color_reg <= bus_d;
            end else if (tandy_mode_cs) begin
                tandy_mode <= bus_d[0];
            end else if (tandy_page_cs) begin // Tandy Page Data
                tandy_page_data <= bus_d;
            end else if (nmi_mask_register_cs) begin // Mask Register
                nmi_mask_register_data <= bus_d;
            end else if (tandy_newcolorsel_cs && tandy_color_reg[7:4] == 4'b0001) begin // Palette Mask Register
                tandy_newcolor <= bus_d[3:0];
                tandy_palette_set <= 1'b1;
            end else if (tandy_newcolorsel_cs && tandy_color_reg[3:0] == 4'b0010) begin // Border Color
                tandy_bordercol <= bus_d[3:0];
            end else if (tandy_newcolorsel_cs && tandy_color_reg[3:0] == 4'b0011) begin // Mode Select
                tandy_modesel <= bus_d[4:0];
            end

        end
    end

    // CRT controller (MC6845 compatible)
    crtc6845 crtc (
        .clk(clk),
        .divclk(crtc_clk),
        .cs(crtc_cs),
        .a0(bus_a[0]),
        .write(~bus_iow_synced_l),
        .read(~bus_ior_synced_l),
        .bus(bus_d),
        .bus_out(bus_out_crtc),
        .lock(1'b0),
        .hsync(hsync_int),
        .vsync(vsync_l),
        .display_enable(display_enable),
        .cursor(cursor),
        .mem_addr(crtc_addr),
        .row_addr(row_addr),
        .line_reset(line_reset)
    );

    // CGA 40 column timings
    defparam crtc.H_TOTAL = 8'd56; // 113
    defparam crtc.H_DISP = 8'd40;   // 80
    defparam crtc.H_SYNCPOS = 8'd45;    // 90
    defparam crtc.H_SYNCWIDTH = 4'd10;
    defparam crtc.V_TOTAL = 7'd31;
    defparam crtc.V_TOTALADJ = 5'd6;
    defparam crtc.V_DISP = 7'd25;
    defparam crtc.V_SYNCPOS = 7'd28;
    defparam crtc.V_MAXSCAN = 5'd7;
    defparam crtc.C_START = 7'd6;
    defparam crtc.C_END = 5'd7;

    // Interface to video SRAM chip
    
    wire [18:0] CGA_VRAM_ADDR;
    assign CGA_VRAM_ADDR = {4'h0, pixel_addr14, pixel_addr13, crtc_addr[11:0],
                    vram_read_a0};
    
`ifdef CGA_SNOW
    cga_vram video_buffer (
        .clk(clk),
        .isa_addr(video_mem_cs ? {4'b0000, bus_a[14:0]} : tandy_page_data[3] ? {3'b000, tandy_page_data[5:3], bus_a[13:0]} : {2'b00, tandy_page_data[5:4], bus_a[14:0]}),
        .isa_din(bus_d),
        .isa_dout(bus_out_mem),
        .isa_read((bus_mem_cs | video_mem_cs) & ~bus_memr_synced_l),
        .isa_write((bus_mem_cs | video_mem_cs) & ~bus_memw_synced_l),        
        .pixel_addr((grph_mode & hres_mode) ? {tandy_page_data[2:1], CGA_VRAM_ADDR[14:0]} : {tandy_page_data[2:0], CGA_VRAM_ADDR[13:0]}),
        .pixel_data(ram_1_d),
        .pixel_read(vram_read),
        .ram_a(ram_a),
        .ram_d(ram_d),
        .ram_we_l(ram_we_l),
        .isa_op_enable(isa_op_enable)
    );
`else
    // Just use the MDA VRAM interface (no snow)
    mda_vram video_buffer (
        .clk(clk),
        .isa_addr(tandy_mode ? video_mem_cs ? {4'b0000, bus_a[14:0]} : tandy_page_data[3] ? {3'b000, tandy_page_data[5:3], bus_a[13:0]} : {2'b00, tandy_page_data[5:4], bus_a[14:0]} : {4'b0000, bus_a[14:0]}),
        .isa_din(bus_d),
        .isa_dout(bus_out_mem),
        .isa_read((bus_mem_cs | video_mem_cs) & ~bus_memr_synced_l),
        .isa_write((bus_mem_cs | video_mem_cs) & ~bus_memw_synced_l),
        .pixel_addr(tandy_mode ? (grph_mode & hres_mode) ? {tandy_page_data[2:1], CGA_VRAM_ADDR[14:0]} : {tandy_page_data[2:0], CGA_VRAM_ADDR[13:0]} : CGA_VRAM_ADDR[13:0]),
        .pixel_data(ram_1_d),
        .pixel_read(vram_read),
        .ram_a(ram_a),
        .ram_d(ram_d),
        .ram_we_l(ram_we_l),
        .isa_op_enable(isa_op_enable)
    );
    defparam video_buffer.MDA_70HZ = 0; // 70Hz VRAM timing no good for CGA.
`endif

    // In graphics mode, memory address MSB comes from CRTC row
    // which produces the weird CGA "interlaced" memory map
    assign pixel_addr13 = grph_mode ? row_addr[0] : crtc_addr[12];

    // Address bit 14 is only used for Tandy modes (32K RAM)
    assign pixel_addr14 = grph_mode ? row_addr[1] : 1'b0;


    // Sequencer state machine
    cga_sequencer sequencer (
        .clk(clk),
        .clk_seq(clkdiv),
        .vram_read(vram_read),
        .vram_read_a0(vram_read_a0),
        .vram_read_char(vram_read_char),
        .vram_read_att(vram_read_att),
        .hres_mode(hres_mode),
        .crtc_clk(crtc_clk),
        .charrom_read(charrom_read),
        .disp_pipeline(disp_pipeline),
        .isa_op_enable(isa_op_enable),
        .hclk(hclk),
        .lclk(lclk),
        .tandy_16_gfx(grph_mode & hres_mode),
        .tandy_color_16(tandy_color_16)
    );

    // Pixel pusher
    cga_pixel pixel (
        .clk(clk),
        .clk_seq(clkdiv),
        .hres_mode(hres_mode),
        .grph_mode(grph_mode),
        .bw_mode(bw_mode),
        .mode_640(mode_640),
        .thin_font(thin_font),
        .vram_data(ram_1_d),
        .vram_read_char(vram_read_char),
        .vram_read_att(vram_read_att),
        .disp_pipeline(disp_pipeline),
        .charrom_read(charrom_read),
        .display_enable(display_enable),
        .cursor(cursor),
        .row_addr(row_addr),
        .blink_enabled(blink_enabled),
        .blink(blink),
        .hsync(hsync_int),
        .vsync(vsync_l),
        .video_enabled(video_enabled),
        .cga_color_reg(cga_color_reg),
        .tandy_palette_color(tandy_color_reg[3:0]),
        .tandy_newcolor(tandy_newcolor),
        .tandy_palette_set(tandy_palette_set),
        .tandy_bordercol(tandy_bordercol),
        .tandy_color_4(tandy_color_4),
        .tandy_color_16(tandy_color_16),
        .video(video)
    );

    // Generate blink signal for cursor and character
    always @ (posedge clk)
    begin
        if (blink_counter == BLINK_MAX) begin
            blink_counter <= 0;
            blink <= ~blink;
        end else begin
            blink_counter <= blink_counter + 1;
        end
    end

    // Composite video generation
    cga_composite comp (
        .clk(clk),
        .lclk(lclk),
        .hclk(hclk),
        .video(video),
        .hsync(hsync_int),
        .vsync_l(vsync_l),
        .bw_mode(bw_mode),
        .comp_video(comp_video)
    );

    cga_scandoubler scandoubler (
        .clk(clk),
        .line_reset(line_reset),
        .video(video),
        .dbl_hsync(dbl_hsync),
        .dbl_video(dbl_video)
    );

endmodule
