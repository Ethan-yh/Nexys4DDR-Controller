# DDR2

本文件夹内为DDR2驱动。
基于开源项目[mig_example](https://github.com/ChrisPVille/mig_example)。


[ddr2_ctrl.v](./ddr2_ctrl.v)是仿照[mem_example.v](./mem_example.v)写的驱动，在位数的处理上做了修改。里面的mig ip核请参照[原文档](https://github.com/ChrisPVille/mig_example/blob/master/Nexys%204%20Onboard%20DDR2%20MIG%20Configuration.pdf)进行配置。

[ddr2_wb.v](./ddr2_wb.v)对[ddr2_ctrl.v](./ddr2_ctrl.v)进行了封装，符合wishbone总线。`mem_clk`是200M时钟，通过时钟ip核得到。


