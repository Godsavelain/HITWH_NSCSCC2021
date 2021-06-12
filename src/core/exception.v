`include "../defines.v"

module exception
(
	  input wire  [31: 0]  exc_pc_i,//进入PC
	  input wire 			     exc_mem_en_i,//当前有写请求
    input  wire [31: 0]  exc_m_addr_i,
    input wire  [31: 0]  exc_EPC_i,
    input wire  [31: 0]  exc_ErrorEPC_i,//from cp0
    input wire  [`ExcE]  exc_excs_i,//异常向量

    input wire           exc_intr_i,//中断信号，来自cp0

    output wire          exc_flag_o,//确认发生异常/中断
    output wire [`ExcT]  exc_type_o,//异常类型
    output wire [31: 0]  exc_baddr_o,
    output wire [ 1: 0]  exc_cpun_o,
    output wire [31: 0]  flush_pc_o
);

    wire [`ExcE] excs;

    assign  excs [`ExcE_W-1: 1]  = exc_excs_i[`ExcE_W-1: 1];
    assign  excs [`Exc_Intr   ]  = exc_intr_i & ~exc_mem_en_i;
    assign  exc_flag_o 			     = exc_type_o != 0;

    assign  exc_type_o  			 = excs[`Exc_Intr  ] ? `ExcT_Intr :
            					           excs[`Exc_AdEL1 ] ? `ExcT_AdEL1:
                                 excs[`Exc_AdEL2 ] ? `ExcT_AdEL2:
                                 excs[`Exc_AdES  ] ? `ExcT_AdES :
            					           excs[`Exc_Ov    ] ? `ExcT_Ov   :
            					           excs[`Exc_SysC  ] ? `ExcT_SysC :
            					           excs[`Exc_Bp    ] ? `ExcT_Bp   :
            					           excs[`Exc_RI    ] ? `ExcT_RI   :            					   
            					           excs[`Exc_ERET  ] ? `ExcT_ERET : `ExcT_NoExc;

    assign  exc_baddr_o = excs[`Exc_AdEL1] ? exc_pc_i :
                          excs[`Exc_AdEL2] | excs[`Exc_AdES] ? exc_m_addr_i : 0;

    assign  flush_pc_o  = excs[`Exc_ERET  ] ? exc_EPC_i-4 :32'hBFC0_037c;



endmodule