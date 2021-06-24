# Flash

本文件夹内为SPI Flash驱动。
基于开源项目[qspiflash](https://github.com/ZipCPU/qspiflash)。

原项目中提供了如何构建一个spi flash驱动的[文档](http://zipcpu.com/blog/2018/08/16/spiflash.html)。

[spixpress.v](./spixpress.v)来自原项目，是SPI Flash的驱动。

[spixpress_wb.v](./spixpress_wb.v)为顶层文件，在原驱动基础上再封装了一层，使用更加方面。
