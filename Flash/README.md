# Flash

## 简介
本文件夹内为SPI Flash驱动。
基于开源项目[qspiflash](https://github.com/ZipCPU/qspiflash)。

原项目中提供了如何构建一个spi flash驱动的[文档](http://zipcpu.com/blog/2018/08/16/spiflash.html)。

[spixpress.v](./spixpress.v)来自原项目，是SPI Flash的驱动。

[spixpress_wb.v](./spixpress_wb.v)为顶层文件，是本人在原驱动基础上再封装了一层，将`flash_sck`的产生和原语的使用进行了封装，使用更加方便。

## 封装说明
如果不打算使用[spixpress_wb.v](./spixpress_wb.v)，自己封装的话，需要注意时钟。[spixpress.v](./spixpress.v)中的`o_spi_sck`这个信号，它并非真的是一个时钟信号，而是一个时钟有效信号(`flash_sck_en`)。

```verilog
input	wire		i_clk, i_reset,
//
input	wire		i_wb_cyc, i_wb_stb, i_cfg_stb, i_wb_we,
input	wire	[21:0]	i_wb_addr,
input	wire	[31:0]	i_wb_data,
output	reg		o_wb_stall, o_wb_ack,
output	reg	[31:0]	o_wb_data,

//就是下面这个o_spi_sck
output	reg		o_spi_cs_n, o_spi_sck, o_spi_mosi,
input	wire		i_spi_miso
```

因此需要根据这个时钟有效信号，去产生一个时钟信号(`flash_sck`)，该时钟(`flash_sck`)仅在时钟有效信号有效时(高电平)，才以50M工作，其余时候保持为0。原仓库中用`ODDR原语`得到`flash_sck`，因为对`ODDR原语`不熟悉，这里本人直接通过`always语句`得到。另外，时钟有效信号(`flash_sck_en`)可能需要延迟两周期，具体可以观察波形图。

以下是本人在[spixpress_wb.v](./spixpress_wb.v)中的处理方式：
```verilog
//延迟处理
reg [1:0] flash_sck_en_d;
always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if(wb_rst_i)begin
        flash_sck_en_d <= 2'b0;
    end
    else begin
        flash_sck_en_d <= {flash_sck_en_d[0], flash_sck_en};
    end
end

//得到真正的flash_sck
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

//原语传入flash_sck
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
```
总之就是要保证在一次读操作的波形中，串行数据的各bit位与时钟(`flash_sck`)的上升沿对应关系是满足spi flash协议的。
