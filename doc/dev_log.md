TO DO LIST：

###### 2021.8.3

* 将icache_axi_stall于dcache_axi_stall去除，现在所有的暂停信号统一由cache发出
* 合并icache中cache_req与uncache_req的状态机（由于忘记修改icache_s1中wea的条件导致uncache访问也会更新cache的内容，此bug已经修复）
* 主频提升至115M，性能分56.7分
* 此版本作为最终初赛提交版本

###### 2021.7.31

* 将uncache的inst取指放到第二个周期。现在所有的取指申请都由icache发出了。将valid信息用bram保存。主频优化至111M，性能分54.784，通过系统测试，计划作为最终初赛提交版本。
* 实现了将icache翻倍的版本，主频降低至106M，性能分下降，因此不采用。

###### 2021.7.30

* dcache容量翻倍，cacheline8字改16字，通过性能测试、系统测试，性能分数52，主频降低至105M。

###### 2021.7.29

* 实现cache写回与请求新数据合并，并拆分if段的取指，现在所有的取指请求均由icache发起了。
* 使用了21年的新版性能测试，跑分48。

###### 2021.7.28

* 优化时序到112M，跑分51.17

###### 2021.7.27

* 优化时序到108M

###### 2021.7.26

* 修复dcache中的bug，通过全部性能测试
  * 修复Bug如下：	
* * 向AXI写回数据的时机不对，应将输入AXI的要写的数据寄存起来
  * 更新dirty的时机有问题，当读入新的cacheline且包含对此cacheline的写时（对应上一次的write miss），应更新dirty为1。

目前性能测试跑分43.68，频率95M

###### 2021.7.25

* 修复dcache中的bug如下：
* * burst读时未指定size
  * 对于collid发生的判断不充分，不能对s1无效时送入的数据进行hit判定。通过在Hit逻辑中引入！s1_install解决。
  * 进行冲突判定时未比对bank
* 可以正确通过10个功能测试中的5个，2个跑错3个跑飞，待debug。

###### 2021.7.24

* 添加dcache，通过功能测试仿真。
* bug1:读bfc00380时发现取出的指令有问题，排查发现是更新dirty位的逻辑有问题。应该判定s1_hit1_i为1时更新dirty1，而不是在s1_dirty0为0时就更新dirty1
* 最大频率约95M，待优化

###### 2021.7.21

* 将dcache的uncache取指请求移动到MEM段，由dcache发出请求而非流水线直接请求dcache_axi。现在一切访存请求都由dcache向dcache_axi发出，CPU只从dcache中取数。通过功能测试与性能测试。memory game存在问题，有时候按键2,3,4号键会亮1号键的灯，检查中。

###### 2021.7.18

* 实现mul指令，看起来可以跑通系统测试的全部test了

###### 2021.7.17

* 改进关键路径，提升频率至108M，性能分6.8，通过功能测试性能测试记忆游戏，系统测试有问题

###### 2021.7.16

* icache通过性能测试。
* 之前的Bug是由于xor指令未设置ren2为true，导致无法正确判定关于xor的旁路阻塞情况，取出错误的数据
* 尚未进行系统测试

###### 2021.7.15

* 通过添加use_readdata寄存器，解决了icache在AXI总线burst传输完成后，若下一个申请的数据正好hit时，会发送命中的数据而非read_data的问题

* icache通过功能测试9个测试点，8号测试不过，但有读数

  

###### 2021.7.14

* icache成功通过改进版本的功能测试（即将全部地址段设为cached）
* 功能测试可以通过6个测试点，有4个不过，待debug

###### 2021.7.13

* 添加icache并通过正常版本的功能测试成功

###### 2021.7.8

* 通过系统测试
* 系统测试错误原因：flush时将送入下一级的pc清零导致中断的EPC计算有误

###### 2021.7.6

* 更正了syscall和break的译码错误，可以启动监控系统，但r指令存在问题，待修复

###### 2021.7.5

* 更正了AXI总线重复发读写请求的问题
* 带中断的系统测试不过，需要debug
* 性能测试频率升高性能降低是因为测试时没有把最左侧按键拨上

###### 2021.7.4

* 优化时序到120M，通过功能测试、性能测试和记忆游戏
* 发现性能测试中存在频率升高性能降低的诡异问题，排查中

###### 2021.7.2

* 添加了无cache的AXI总线，功能测试仿真通过
* AXI功能测试上板测试通过
* 性能测试得分2.733

###### 2021.6.22

* 解决了hilo寄存器的问题，SRAM上板功能测试通过

###### 2021.6.20

* 优化了时序，将送入EXC模块的当前需要写信号替换为延迟更少的另一条信号

###### 2021.6.13

* 通过了lab9的测试。

###### 2021.6.12

* 通过了lab8的测试。

###### 2021.6.6

* 在流水段中添加了ExcE与intr的传递并实现了ExcE向量的生成

###### 2021.5.8

* 添加了lwl lwr swl swr指令并仿真通过了第七章的功能测试
* 为实现lwl lwr为寄存器堆写添加了四位使能信号

###### 2021.5.4

* 添加了乘除法单元mdu
* 为工程添加了mul , mult , div , divu , mfhi , mflo , mthi , mtlo指令
* 通过了书第六章的功能测试
* 其实是过去十几天才搞完的，只是平时懒得写开发日记了。以后要加强记录。

###### 2021.4.22

* 消灭了所有的多驱动问题，才发现由于多驱动，之前的布线只布局了很少的逻辑单元
* 修改pc逻辑，现在可以正常取指，消灭了bram - bram的路径
* 修改pc逻辑，解决了第一条指令重复取与转移指令暂停会跳过延迟槽的问题
* 使用openmips中的测试代码测试load相关，通过

###### 2021.4.20

* 添加了控制单元，实现阻塞与清空。测试未通过，debug中
* 我真是个废物

###### 2021.4.19

* 添加了add addi and or nor xor xori andi ori sub slt slti sltu 等指令，测试了一部分
* 添加了beq bne bgez bgtz blez bltz bgezal bltzal j jal jr jalr指令内容。未测试。
* 根据自己动手写CPU的测试用例，利用ori指令测试了数据旁路，可以工作。

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