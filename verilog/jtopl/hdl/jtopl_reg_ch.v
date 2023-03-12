/* This file is part of JTOPL

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

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 28-5-2022

*/

module jtopl_reg_ch#( parameter
    CHCSRW = 10
) (
    input                   rst,
    input                   clk,
    input                   cen,
    input                   zero,
    input                   rhy_en,
    input             [4:0] rhy_kon,
    input            [17:0] slot,

    input             [1:0] group,
    input      [CHCSRW-1:0] chcfg_inmux,

    output reg [CHCSRW-1:0] chcfg,
    output reg              rhy_oen,    // high for rhythm operators if rhy_en is set
    output                  rhyon_csr
);

// Rhythm key-on CSR
localparam BD=4, SD=3, TOM=2, TC=1, HH=0;

reg  [CHCSRW-1:0] chcfg0_in, chcfg1_in, chcfg2_in;
wire [CHCSRW-1:0] chcfg0_out, chcfg1_out, chcfg2_out;

reg  [5:0] rhy_csr;

assign rhyon_csr = rhy_csr[5];

always @(*) begin
    case( group )
        default: chcfg = chcfg0_out;
        2'd1: chcfg = chcfg1_out;
        2'd2: chcfg = chcfg2_out;
    endcase
    chcfg0_in = group==2'b00 ? chcfg_inmux : chcfg0_out;
    chcfg1_in = group==2'b01 ? chcfg_inmux : chcfg1_out;
    chcfg2_in = group==2'b10 ? chcfg_inmux : chcfg2_out;
end

`ifdef SIMULATION
reg  [CHCSRW-1:0] chsnap0, chsnap1,chsnap2;

always @(posedge clk) if(zero) begin
    chsnap0 <= chcfg0_out;
    chsnap1 <= chcfg1_out;
    chsnap2 <= chcfg2_out;
end
`endif

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        rhy_csr <= 6'd0;
        rhy_oen <= 0;
    end else if(cen) begin
        if(slot[11]) rhy_oen <= rhy_en;
        if(slot[17]) begin
            rhy_csr <= { rhy_kon[BD], rhy_kon[HH], rhy_kon[TOM],
                         rhy_kon[BD], rhy_kon[SD], rhy_kon[TC] };
            rhy_oen <= 0;
        end else
            rhy_csr <= { rhy_csr[4:0], rhy_csr[5] };
    end
end

jtopl_sh_rst #(.width(CHCSRW),.stages(3)) u_group0(
    .clk    ( clk        ),
    .cen    ( cen        ),
    .rst    ( rst        ),
    .din    ( chcfg0_in  ),
    .drop   ( chcfg0_out )
);

jtopl_sh_rst #(.width(CHCSRW),.stages(3)) u_group1(
    .clk    ( clk        ),
    .cen    ( cen        ),
    .rst    ( rst        ),
    .din    ( chcfg1_in  ),
    .drop   ( chcfg1_out )
);

jtopl_sh_rst #(.width(CHCSRW),.stages(3)) u_group2(
    .clk    ( clk        ),
    .cen    ( cen        ),
    .rst    ( rst        ),
    .din    ( chcfg2_in  ),
    .drop   ( chcfg2_out )
);

endmodule