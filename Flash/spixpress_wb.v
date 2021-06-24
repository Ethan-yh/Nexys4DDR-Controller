`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/04 19:34:30
// Design Name: 
// Module Name: spixpress_wb
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


module spixpress_wb(
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

    // flash pins
    output wire  cs_n,
    input wire       sdi,
    output wire  sdo,
    output  wire    wp_n,
    output  wire  hld_n
    );


    assign wp_n = 1'b1;
    assign hld_n = 1'b1;

    

    reg wb_cyc;
    reg wb_stb;
    reg [21:0] wb_addr;
    reg [31:0] wb_data_i;
    wire wb_ack;
    wire [31:0] wb_data_o;
    wire flash_sck_en;
    reg flash_sck;

    reg clk_50M;
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if(wb_rst_i)begin
            clk_50M <= 1'b0;
        end
        else begin
            clk_50M <= ~clk_50M;
        end
    end

    reg [1:0] flash_sck_en_d;
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if(wb_rst_i)begin
            flash_sck_en_d <= 2'b0;
        end
        else begin
            flash_sck_en_d <= {flash_sck_en_d[0], flash_sck_en};
        end
    end

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if(wb_rst_i)begin
            flash_sck <= 1'b0;
        end
        else if (flash_sck_en_d[1]) begin
            flash_sck <= ~flash_sck;
        end
        else begin
            flash_sck <= 1'b0;
        end
    end

    

    spixpress spixpress0(

		.i_clk(clk_50M),
        .i_reset(wb_rst_i),

		.i_wb_cyc(wb_cyc),
        .i_wb_stb(wb_stb),
        .i_cfg_stb(1'b0),
        .i_wb_we(1'b0),
		.i_wb_addr(wb_addr[21:0]),
		.i_wb_data(wb_data_i),
		.o_wb_stall(),
        .o_wb_ack(wb_ack),
		.o_wb_data(wb_data_o),

		.o_spi_cs_n(cs_n),
        .o_spi_sck(flash_sck_en),
        .o_spi_mosi(sdo),
		.i_spi_miso(sdi)

	);

    STARTUPE2
    #(
    .PROG_USR("FALSE"),
    .SIM_CCLK_FREQ(10.0)
    )
    STARTUPE2_inst
    (
    .CFGCLK     (),
    .CFGMCLK    (),
    .EOS        (),
    .PREQ       (),
    .CLK        (1'b0),
    .GSR        (1'b0),
    .GTS        (1'b0),
    .KEYCLEARB  (1'b0),
    .PACK       (1'b0),
    .USRCCLKO   (flash_sck),      // First three cycles after config ignored, see AR# 52626
    .USRCCLKTS  (1'b0),     // 0 to enable CCLK output
    .USRDONEO   (1'b1),     // Shouldn't matter if tristate is high, but generates a warning if tied low.
    .USRDONETS  (1'b1)      // 1 to tristate DONE output
    );

    // Wishbone read/write accesses
    wire wb_acc = wb_cyc_i & wb_stb_i;    // WISHBONE access
    wire wb_wr  = wb_acc & wb_we_i;       // WISHBONE write access
    wire wb_rd  = wb_acc & !wb_we_i;      // WISHBONE read access

    reg [3:0] state;

    parameter IDLE = 4'b0000;
    parameter START = 4'b0001;
    parameter WAIT = 4'b0010;
    parameter END = 4'b0011;

    reg [7:0] wait_count;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if(wb_rst_i)begin
            wb_cyc <= 1'b0;
            wb_stb <= 1'b0;
            wb_addr <= 22'b0;
            wb_data_i <= 32'b0;

            wait_count <= 8'h0;

            wb_dat_o <= 32'b0;
            wb_ack_o <= 1'b0;

            state <= IDLE;
        end
        else begin
            case(state)
            IDLE:begin
                wait_count <= 8'h0;
                if(wb_acc)begin
                    wb_addr <= wb_adr_i[23:2];
                    state <= START;
                end
            end
            START: begin
                wb_cyc <= 1'b1;
                wb_stb <= 1'b1;
                state <= WAIT;
            end
            WAIT: begin
                if (wb_ack) begin
                    wb_cyc <= 1'b0;
                    wb_stb <= 1'b0;
                    wb_dat_o <= wb_data_o;
                    wb_ack_o <= 1'b1;
                    state <= END;
                end
            end
            END: begin
                wb_ack_o <= 1'b0;
                if(wait_count < 8'h8)begin
                    wait_count <= wait_count + 1;
                end
                else begin
                    wait_count <= 8'h0;
                    state <= IDLE;
                end
            end
            endcase
        end
    end
endmodule
