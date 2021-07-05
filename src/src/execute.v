`include "../defines.v"

module execute
(
	input wire				clk,
	input wire				rst_n,
	input wire 				ex_flush_i,			//from controller
	input wire				ex_stall_i,

	input wire [31: 0] 		ex_inst_i,
 	input wire 		 		ex_inslot_i,
 	input wire [31: 0]		ex_pc_i,
 	input wire [31: 0]		ex_opr1_i,
 	input wire [31: 0]		ex_opr2_i,
 	input wire [ 3: 0]		ex_wren_i,
 	input wire [ 4: 0]		ex_waddr_i,
 	input wire [31: 0]		ex_offset_i,
 	input wire 				ex_nofwd_i,
 	input wire [31: 0]		ex_rtvalue_i,
 	input wire 				ex_divinst_i,
 	input wire 				ex_mduinst_i,

 	input wire [`ExcE] 		ex_excs_i,
 	input wire 				ex_has_exc_i,
 	input wire 				ex_ov_inst_i,

 	input wire [`AOP] 		ex_aluop_i,
 	input wire [`MDOP] 		ex_mduop_i,
 	input wire [`MMOP] 		ex_memop_i,
 	input wire [`TOP ] 		ex_tlbop_i,
    input wire [`COP ] 		ex_cacheop_i,

    input wire	[31: 0]		ex_alures_i,
    input wire 				ex_aluov_i,

    input wire          	ex_c0wen_i,
    input wire          	ex_c0ren_i,
    input wire [ 7: 0]  	ex_c0addr_i,
   
   //from mdu 
    input wire 				mdu_is_active,//mdu单元正在工作
    input wire 				mdu_div_active,//mdu单元正在执行除法

    output wire	[ 3: 0]	    ex_wren_o,
    output wire [ 4: 0] 	ex_waddr_o,
    output wire [31: 0] 	ex_wdata_o,
    output wire 			ex_nofwd_o,
    

    //to alu
    output wire [`AOP] 		ex_aluop_o,
    output wire [31: 0]		ex_opr1_o,
 	output wire [31: 0]		ex_opr2_o,

 	//to mdu
 	output wire [31: 0]		ex_mdu_opr1_o,
 	output wire [31: 0]		ex_mdu_opr2_o,
 	output wire [`MDOP] 	ex_mduop_o,
 	output wire [31: 0]		ex_mdu_whi_o,
 	output wire [31: 0]		ex_mdu_wlo_o,

 	//to mem
 	output wire				ex_memen_o,		//data_sram_en
	output wire [ 3: 0]		ex_memwen_o,	//data_sram_wen	
	output wire [31: 0] 	ex_memaddr_o,	//data_sram_addr
    output wire [31: 0] 	ex_memwdata_o,	//data_sram_wdata
    output wire [ 1: 0]		ex_bus_store_size,
    output wire [ 1: 0]		ex_bus_load_size,
    output wire 			ex_storeinst_o, //could cause store

    output wire [`MMOP] 	ex_memop_o,
    output wire [31: 0] 	ex_bad_memaddr_o,	//for adress exception

    output wire [31: 0]		ex_inst_o,
    output wire 			ex_inslot_o,
 	output wire 			ex_stallreq_o,
 	output wire [31: 0]		ex_pc_o,
 	output wire 			ex_inst_load_o,
 	output wire [ 1: 0]		ex_memaddr_low_o,
 	output wire [`ExcE] 	ex_excs_o,
 	output wire          	ex_c0wen_o,
    output wire          	ex_c0ren_o,
    output wire [ 7: 0]  	ex_c0addr_o,
    output wire [31: 0]		ex_c0_wdata_o,


 	//bypass 
 	output wire	[31: 0]		ex_wdata_bp_o,
 	output wire 			ex_nofwd_bp_o


);
	
	wire					en;
	assign  en 				= ~ ex_stall_i; 
	
    wire		[ 3: 0]		ex_wren_next;
    wire 		[ 4: 0] 	ex_waddr_next;
    wire		[31: 0]		ex_wdata_next;
    wire 		[31: 0]		ex_inst_next;
    wire					ex_inslot_next;
    wire		[`MMOP]		ex_memop_next;
    wire 		[31: 0]		ex_pc_next;
    wire					ex_inst_load_next;
    wire		[ 1: 0]		ex_memaddr_low_next;
    wire 					ex_nofwd_next;
    wire 					ex_mdu_inst_next;
 	wire 		[`ExcE] 	ex_excs_next;
 	wire 					ex_has_exc_next;
  	wire          			ex_c0wen_next;
    wire          			ex_c0ren_next;
    wire 		[ 7: 0]  	ex_c0addr_next;  
    wire 		[31: 0]  	ex_c0_wdata_next;
    wire 		[31: 0]		ex_bad_memaddr_next;  

//useful values
		
	wire 	ov;

	wire	opr_lt;		
	wire	opr_ltu; 		
	wire	opr_eq; 

	wire	ls_addr;

	wire	op_lb;
	wire	op_lbu;
	wire	op_lh;
	wire	op_lhu;
	wire	op_lw;
	wire	op_sb;
	wire	op_sh;
	wire	op_sw;
	wire 	op_lwl;
	wire 	op_lwr;
	wire 	op_swl;
	wire 	op_swr;

	assign  ov				= ex_aluov_i & ex_ov_inst_i;

	assign	opr_lt			= $signed(ex_opr1_i) < $signed(ex_opr2_i);
	assign	opr_ltu 		= ex_opr1_i < ex_opr2_i;
	assign	opr_eq  		= (ex_opr1_i ^ ex_opr2_i) == 0;

	assign	ls_addr			= ex_alures_i;

	assign  op_lb 			= ex_memop_i[0];
	assign  op_lbu 			= ex_memop_i[1];
	assign  op_lh 			= ex_memop_i[2];
	assign  op_lhu 			= ex_memop_i[3];
	assign  op_lw 			= ex_memop_i[4];
	assign  op_sb 			= ex_memop_i[5];
	assign  op_sh 			= ex_memop_i[6];
	assign  op_sw 			= ex_memop_i[7];
	assign  op_lwl 			= ex_memop_i[8];
	assign  op_lwr 			= ex_memop_i[9];
	assign  op_swl 			= ex_memop_i[10];
	assign  op_swr 			= ex_memop_i[11];

//to alu
	assign	ex_aluop_o		= ex_aluop_i;
	assign	ex_opr1_o		= ex_opr1_i;
	assign	ex_opr2_o		= ex_opr2_i;

//to next stage
	assign ex_wren_next		= ex_flush_i ? 0 : ex_wren_i;
	assign ex_waddr_next	= ex_flush_i ? 0 : ex_waddr_i;
	assign ex_wdata_next	= ex_flush_i ? 0 : ex_alures_i;
	assign ex_inst_next		= ex_flush_i ? 0 : ex_inst_i;
	assign ex_inslot_next   = ex_flush_i ? 0 : ex_inslot_i;
	assign ex_memop_next	= ex_flush_i ? 0 : ex_memop_i;
	assign ex_nofwd_next	= ex_flush_i ? 0 : ex_nofwd_i;
	assign ex_pc_next		= ex_flush_i ? 0 : ex_pc_i;
	assign ex_inst_load_next= ex_flush_i ? 0 : op_lb | op_lbu | op_lh | op_lhu | op_lw | op_lwl | op_lwr;
	assign ex_memaddr_low_next = ex_flush_i ? 0 : ex_memaddr_low;
	assign ex_mdu_inst_next = ex_flush_i ? 0 : ex_mduinst_i;
	assign ex_excs_next[`ExcE_W-1: 5]	= ex_flush_i ? 0 : ex_excs_i[`ExcE_W-1: 5];
	assign ex_excs_next[4] 	= ex_flush_i ? 0 : ov;
	assign ex_excs_next[3] 	= ex_flush_i ? 0 : (ex_memaddr_low[0] & op_sh) | ((ex_memaddr_low[1:0] != 00) & op_sw);
	assign ex_excs_next[2] 	= ex_flush_i ? 0 : (ex_memaddr_low[0] &(op_lh | op_lhu)) | ((ex_memaddr_low[1:0] != 00) & op_lw);
	assign ex_excs_next[ 1: 0] 	= ex_flush_i ? 0 : ex_excs_i[ 1: 0]; 
   	assign ex_c0wen_next	= ex_flush_i ? 0 : ex_c0wen_i;
    assign ex_c0ren_next	= ex_flush_i ? 0 : ex_c0ren_i;
    assign ex_c0addr_next	= ex_flush_i ? 0 : ex_c0addr_i;
    assign ex_c0_wdata_next = ex_flush_i ? 0 : ex_rtvalue_i;

    //assign ex_has_exc_next	= ex_flush_i ? 0 :ex_has_exc_i | ov | ex_excs_next[3] | ex_excs_next[2];
    assign ex_has_exc		= ex_has_exc_i | ov | (ex_memaddr_low[0] & op_sh) | ((ex_memaddr_low[1:0] != 00) & op_sw)
    						 | (ex_memaddr_low[0] &(op_lh | op_lhu)) | ((ex_memaddr_low[1:0] != 00) & op_lw);
//to bypass
	//assign ex_wdata_bp_o	= ex_wdata_next;
	assign ex_wdata_bp_o	= ex_alures_i;
	assign ex_nofwd_bp_o	= ex_nofwd_i;

//for mem
	wire [ 1: 0]  ex_memaddr_low; 						//地址最末两位
	wire [ 3: 0]  ex_memwen_sb;
	wire [ 3: 0]  ex_memwen_sh;
	wire [ 3: 0]  ex_memwen_swl;
	wire [ 3: 0]  ex_memwen_swr;

	wire [31: 0]  swl_data; 
	wire [31: 0]  swr_data; 

	wire [ 1: 0]  swl_bus; 
	wire [ 1: 0]  swr_bus; 
	wire [ 1: 0]  lwl_bus;
	wire [ 1: 0]  lwr_bus;

	assign ex_memaddr_low	= ex_alures_i[1:0];
	assign ex_memwen_sb		= ex_memaddr_low == 2'b00 ? 4'b0001:
							  ex_memaddr_low == 2'b01 ? 4'b0010:
							  ex_memaddr_low == 2'b10 ? 4'b0100:
							  4'b1000;
	assign ex_memwen_sh		= ex_memaddr_low == 2'b00 ? 4'b0011:
							  4'b1100;

	assign ex_memwen_swl	= ex_memaddr_low == 2'b00 ? 4'b0001:
							  ex_memaddr_low == 2'b01 ? 4'b0011:
							  ex_memaddr_low == 2'b10 ? 4'b0111:
							  4'b1111;

	assign ex_memwen_swr	= ex_memaddr_low == 2'b00 ? 4'b1111:
							  ex_memaddr_low == 2'b01 ? 4'b1110:
							  ex_memaddr_low == 2'b10 ? 4'b1100:
							  4'b1000;

	assign swl_data			= ex_memaddr_low == 2'b00 ? {4{ex_rtvalue_i[31:24]}} :
							  ex_memaddr_low == 2'b01 ? {2{ex_rtvalue_i[31:16]}} :
							  ex_memaddr_low == 2'b10 ? {8'b0 , {ex_rtvalue_i[31:8]}} :
							  ex_rtvalue_i;
	assign swr_data			= ex_memaddr_low == 2'b00 ? ex_rtvalue_i:
							  ex_memaddr_low == 2'b01 ? {{ex_rtvalue_i[23: 0]} , 8'b0}:
							  ex_memaddr_low == 2'b10 ? {2{ex_rtvalue_i[15: 0]}} 	 :
							  {4{ex_rtvalue_i[ 7: 0]}};
	//assign ex_memen_o 		= ex_flush_i ? 0 : (|ex_memop_i) & (~ex_has_exc_next);	    //使能
	assign ex_memen_o 		=  (|ex_memop_i) & (~ex_has_exc);	    //使能
	assign ex_memwen_o 		= op_sb ? ex_memwen_sb :
							  op_sh ? ex_memwen_sh :
							  op_sw ? 4'b1111	   :
							  op_swl? ex_memwen_swl:
							  op_swr? ex_memwen_swr:
							  4'b0000; 	    			//写使能	
	assign ex_storeinst_o   = op_sb | op_sh | op_sw | op_swl | op_swr ;

	//assign ex_memaddr_o 	= {ex_alures_i[31:2],2'b00};		//data_sram_addr  访存地址通过alu计算
	assign ex_memaddr_o 	= ex_alures_i;		//data_sram_addr  访存地址通过alu计算
	assign ex_bad_memaddr_next = ex_alures_i;
	assign ex_memwdata_o 	= op_sb ? {4{ex_rtvalue_i[7:0]}} :
							  op_sh ? {2{ex_rtvalue_i[15:0]}}:
							  op_swl? swl_data				 :
							  op_swr? swr_data				 :
							  ex_rtvalue_i;   	//data_sram_wdata

	assign swl_bus 			= ex_memaddr_low == 2'b00 ? 2'b00 :
							  ex_memaddr_low == 2'b01 ? 2'b01 :
							  ex_memaddr_low == 2'b10 ? 2'b10 :
							  2'b10;

	assign swr_bus			= ex_memaddr_low == 2'b00 ? 2'b10 :
							  ex_memaddr_low == 2'b01 ? 2'b10 :
							  ex_memaddr_low == 2'b10 ? 2'b01 :
							  2'b00;

	assign lwl_bus 			= ex_memaddr_low == 2'b00 ? 2'b00 :
							  ex_memaddr_low == 2'b01 ? 2'b01 :
							  ex_memaddr_low == 2'b10 ? 2'b10 :
							  2'b10;

	assign lwr_bus			= ex_memaddr_low == 2'b00 ? 2'b10 :
							  ex_memaddr_low == 2'b01 ? 2'b10 :
							  ex_memaddr_low == 2'b10 ? 2'b01 :
							  2'b00;

	assign ex_bus_store_size		= op_sb 	? 2'b00:
							  		op_sh 	? 2'b01:
							  		op_swl	? swl_bus :
							  		op_swr	? swr_bus :
							  		2'b10;

	assign ex_bus_load_size			= op_lb | op_lbu 	? 2'b00:
							  		op_lh   | op_lhu 	? 2'b01:
							  		op_lwl	? lwl_bus :
							  		op_lwr	? lwr_bus :
							  		2'b10;


//to mdu
	assign ex_mdu_opr1_o	= ex_opr1_i;
	assign ex_mdu_opr2_o	= ex_opr2_i;
	assign ex_mduop_o 		= ex_mduop_i;
	assign ex_mdu_whi_o  	= ex_opr1_i;
	assign ex_mdu_wlo_o  	= ex_opr1_i;
//DFFREs
DFFRE #(.WIDTH(4))		wren_next			(.d(ex_wren_next), .q(ex_wren_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(5))		waddr_next			(.d(ex_waddr_next), .q(ex_waddr_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))		wdata_next			(.d(ex_wdata_next), .q(ex_wdata_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))		inst_next			(.d(ex_inst_next), .q(ex_inst_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))		inslot_next			(.d(ex_inslot_next), .q(ex_inslot_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))		nofwd_next			(.d(ex_nofwd_next), .q(ex_nofwd_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(`MMOP_W))memop_next			(.d(ex_memop_next), .q(ex_memop_o),  .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))		pc_next				(.d(ex_pc_next), .q(ex_pc_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))		inst_load_next		(.d(ex_inst_load_next), .q(ex_inst_load_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(2))		memaddr_low_next	(.d(ex_memaddr_low_next), .q(ex_memaddr_low_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(`ExcE_W))excs_next			(.d(ex_excs_next), .q(ex_excs_o), .en(en), .clk(clk), .rst_n(rst_n));
//DFFRE #(.WIDTH(1))		has_exc_next		(.d(ex_has_exc_next), .q(ex_has_exc_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))		c0wen_next			(.d(ex_c0wen_next), .q(ex_c0wen_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))		c0ren_next			(.d(ex_c0ren_next), .q(ex_c0ren_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))		c0data_next			(.d(ex_c0_wdata_next), .q(ex_c0_wdata_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(8))		c0addr_next			(.d(ex_c0addr_next), .q(ex_c0addr_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))		badvaddr_next		(.d(ex_bad_memaddr_next), .q(ex_bad_memaddr_o), .en(en), .clk(clk), .rst_n(rst_n));


//除法指令必须等mdu为空时进行，进行除法运算时不能移入新的乘法指令
assign ex_stallreq_o = (ex_divinst_i & mdu_is_active) | (ex_mduinst_i & mdu_div_active);




endmodule