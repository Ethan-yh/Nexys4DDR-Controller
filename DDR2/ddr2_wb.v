`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/03 00:43:10
// Design Name: 
// Module Name: ddr2_wb
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


module ddr2_wb(
    input    wire                wb_clk_i,
    input    wire                wb_rst_i,
    input    wire                wb_cyc_i,
    input    wire                wb_stb_i,
    input    wire                wb_we_i,
    input    wire    [3:0]        wb_sel_i,
    input   wire    [31:0]        wb_adr_i,
    input    wire    [31:0]        wb_dat_i,
    output    reg        [31:0]      wb_dat_o,
    output    reg                 wb_ack_o,

    //ddr Interface
    inout[15:0] ddr2_dq,
    inout[1:0] ddr2_dqs_n,
    inout[1:0] ddr2_dqs_p,
    output[12:0] ddr2_addr,
    output[2:0] ddr2_ba,
    output ddr2_ras_n,
    output ddr2_cas_n,
    output ddr2_we_n,
    output ddr2_ck_p,
    output ddr2_ck_n,
    output ddr2_cke,
    output ddr2_cs_n,
    output[1:0] ddr2_dm,
    output ddr2_odt
    );
    wire clk_mem;
    wire rst_n = ~wb_rst_i;

    // Wishbone read/write accesses
    wire wb_acc = wb_cyc_i & wb_stb_i;    // WISHBONE access
    wire wb_wr  = wb_acc & wb_we_i;       // WISHBONE write access
    wire wb_rd  = wb_acc & !wb_we_i;      // WISHBONE read access

    mem_clk mem_clk0
   (
    // Clock out ports
    .clk_out1(clk_mem),     // output clk_out1
   // Clock in ports
    .clk_in1(wb_clk_i));

    wire[31:0] mem_d_from_ram;
    wire mem_transaction_complete;
    wire mem_ready;
    
    reg[27:0] mem_addr;
    reg[31:0] mem_d_to_ram;
    reg [3:0] mem_mask;
    reg mem_wstrobe, mem_rstrobe;

    ddr2_ctrl ddr2_ctrl0(
        .clk_mem(clk_mem),
        .rst_n(rst_n),

        .ddr2_addr(ddr2_addr),
        .ddr2_ba(ddr2_ba),
        .ddr2_cas_n(ddr2_cas_n),
        .ddr2_ck_n(ddr2_ck_n),
        .ddr2_ck_p(ddr2_ck_p),
        .ddr2_cke(ddr2_cke),
        .ddr2_ras_n(ddr2_ras_n),
        .ddr2_we_n(ddr2_we_n),
        .ddr2_dq(ddr2_dq),
        .ddr2_dqs_n(ddr2_dqs_n),
        .ddr2_dqs_p(ddr2_dqs_p),
        .ddr2_cs_n(ddr2_cs_n),
        .ddr2_dm(ddr2_dm),
        .ddr2_odt(ddr2_odt),

        .cpu_clk(wb_clk_i),
        .addr(mem_addr),
        .mask(mem_mask),
        .data_in(mem_d_to_ram),
        .data_out(mem_d_from_ram),
        .rstrobe(mem_rstrobe),
        .wstrobe(mem_wstrobe),
        .transaction_complete(mem_transaction_complete),
        .ready(mem_ready)
    );

    reg  [3:0]  state;
    parameter IDLE       = 4'b0000;
    parameter WRITE      = 4'b0001;
    parameter WWAIT      = 4'b0010;
    parameter READ       = 4'b0011;
    parameter RWAIT      = 4'b0100;
    parameter ENDING     = 4'b0101;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if(wb_rst_i) begin
            mem_addr <= 28'b0;
            mem_d_to_ram <= 32'b0;
            mem_wstrobe <= 1'b0;
            mem_rstrobe <= 1'b0;
            mem_mask <= 4'b0;

            wb_ack_o <= 1'b0;
            wb_dat_o <= 32'b0;

            state <= IDLE;
        end
        else begin
            case(state)
            IDLE: begin
                if(wb_wr)begin
                    mem_addr <= wb_adr_i[27:0];
                    mem_d_to_ram <= wb_dat_i;
                    mem_mask <= ~wb_sel_i;
                    state <= WRITE;
                end
                if(wb_rd)begin
                    mem_addr <= wb_adr_i[27:0];
                    state <= READ;
                end
            end
            WRITE: begin
                if(mem_ready) begin
                    mem_wstrobe <= 1;
                    state <= WWAIT;
                end
            end
            WWAIT:  begin
                mem_wstrobe <= 0;
                if(mem_transaction_complete) begin
                    wb_ack_o <= 1'b1;
                    state <= ENDING;
                end
            end
            READ: begin
                if(mem_ready) begin
                    mem_rstrobe <= 1;
                    state <= RWAIT;
                end
            end
            RWAIT:  begin
                mem_rstrobe <= 0;
                if(mem_transaction_complete) begin
                    wb_dat_o <= mem_d_from_ram;
                    wb_ack_o <= 1'b1;
                    state <= ENDING;
                end
            end
            ENDING: begin
                wb_ack_o <= 1'b0;
                state <= IDLE;
            end
            endcase
        end

    end
endmodule
