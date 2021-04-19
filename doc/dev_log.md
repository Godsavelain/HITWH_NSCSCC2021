### TO DO LIST:添加指令完成sram功能测试

###### 2021.4.19

* 添加了beq bne bgez bgtz blez bltz bgezal bltzal j jal jr jalr指令内容。未测试。
* 根据自己动手写CPU的测试用例，利用ori指令测试了数据旁路，可以工作

###### 2021.4.18

* 添加了访存指令lw lh lhu lb lbu sw sh sb，未测试
* 修改了mem至decoder的旁路逻辑bug，现在mem送入的数据会考虑是否是访存信号
* 为execute至mem段新增了inst_load信号，表明当前指令为load指令

###### 2021.4.17

* 修复bug，完成了ori指令并测试通过。

###### 2021.4.16

* 完成顶层文件的连接，修复了约20个bug，绝大部分是typo+位宽缺失+连线遗失
* 完成ori指令的测试，ori指令存在bug，送入的立即数操作数为符号扩展（应为0扩展），尚未修复。

###### 2021.4.15

* 在顶层文件进行了一些部件连接工作，尚未完成
* 确定了regfile中使用en信号，用于阻塞逻辑判定，并在译码阶段添加其译码
* 在EX段与MEM段添加了旁路信号
* 更正了一些typo 如触发器宽度错误、ret_n误作rst
* 尚未测试

###### 2021.4.14

* 继续完善内容，搭建了流水线从取指到写回的基本框架，应该可以处理普通的算数逻辑运算
* 尚未测试



###### 2021.4.11

* 依照《CPU设计实战》的内容以及胡森给出的代码规范重构了架构。取消了显式的流水段间寄存器，将其隐藏在流水段内。
* 代码按照使用Block Ram的时序编写
* 完成了PC的框架并完成了ID段中一部分译码逻辑



###### 2021.3.25 

* 创建了log日志
* 创建了cpu核内的基本组件的空文件（不包括TLB相关与cache相关），包括
  * pc  取指单元
  * reg_if_id 取指译码中间寄存器
  * decoder 译码单元
  * reg_id_ex 译码执行中间寄存器
  * alu 执行单元算逻运算单元
  * mdu 执行单元乘除运算单元
  * reg_ex_mem 执行访存中间寄存器
  * mem 访存单元
  * reg_mem_wb 访存写回中间寄存器
  * writeback 写回单元
  * regfile 寄存器文件
  * hilo hilo寄存器
  * control 控制器（处理stall flush等）
  * cp0 cp0寄存器
  * cpu_core_top cpu核顶层文件
  * exception 异常处理单元
* 将以上内容上传至HITWH_NSCSCC2021仓库