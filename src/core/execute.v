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
 	input wire 				ex_wren_i,
 	input wire [ 4: 0]		ex_waddr_i,
 	input wire [31: 0]		ex_offset_i,
 	input wire 				ex_nofwd_i,
 	input wire [31: 0]		ex_rtvalue_i,

 	input wire [`AOP] 		ex_aluop_i,
 	input wire [`MDOP] 		ex_mduop_i,
 	input wire [`MMOP] 		ex_memop_i,
 	input wire [`TOP ] 		ex_tlbop_i,
    input wire [`COP ] 		ex_cacheop_i,

    input wire	[31: 0]		ex_alures_i,

    input wire          	ex_c0wen_i,
    input wire          	ex_c0ren_i,
    input wire [ 7: 0]  	ex_c0addr_i,

    
    output wire				ex_wren_o,
    output wire [ 4: 0] 	ex_waddr_o,
    output wire [31: 0] 	ex_wdata_o,
    output wire 			ex_nofwd_o,
    

    //to alu
    output wire [`AOP] 		ex_aluop_o,
    output wire [`MMOP] 	ex_memop_o,
    output wire [31: 0]		ex_opr1_o,
 	output wire [31: 0]		ex_opr2_o,

 	//to mem
 	output wire				ex_menen_o,		//data_sram_en
	output wire [ 3: 0]		ex_memwen_o,	//data_sram_wen	
	output wire [31: 0] 	ex_memaddr_o,	//data_sram_addr
    output wire [31: 0] 	ex_memwdata_o,	//data_sram_wdata

    output wire [31: 0]		ex_inst_o,
    output wire 			ex_inslot_o,
 	output wire 			ex_stallreq_o,
 	output wire [31: 0]		ex_pc_o,
 	output wire 			ex_inst_load_o,
 	output wire [ 1: 0]		ex_memaddr_low_o,

 	//bypass 
 	output wire	[31: 0]		ex_wdata_bp_o

);
	
	wire					en;
	assign  en 				= ~ ex_stall_i; 
	
    wire					ex_wren_next;
    wire 		[ 4: 0] 	ex_waddr_next;
    wire		[31: 0]		ex_wdata_next;
    wire 		[31: 0]		ex_inst_next;
    wire					ex_inslot_next;
    wire		[`MMOP]		ex_memop_next;
    wire 					ex_nofwd_next;
    wire 		[31: 0]		ex_pc_next;
    wire					ex_inst_load_next;
    wire		[ 1: 0]		ex_memaddr_low_next;


//useful values
	wire 	s_opr1;			
	wire 	s_opr2;			
	wire 	s_res;			

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

	assign 	s_opr1			= ex_opr1_i[31];
	assign 	s_opr2			= ex_opr2_i[31];
	assign 	s_res			= ex_alures_i[31];

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

//to alu
	assign	ex_aluop_o		= ex_aluop_i;
	assign	ex_opr1_o		= ex_opr1_i;
	assign	ex_opr2_o		= ex_opr2_i;

//to next stage
	assign ex_wren_next		= ex_wren_i;
	assign ex_waddr_next	= ex_waddr_i;
	assign ex_wdata_next	= ex_alures_i;
	assign ex_inst_next		= ex_inst_i;
	assign ex_inslot_next   = ex_inslot_i;
	assign ex_memop_next	= ex_memop_i;
	assign ex_nofwd_next	= ex_nofwd_i;
	assign ex_pc_next		= ex_pc_i;
	assign ex_inst_load_next= op_lb | op_lbu | op_lh | op_lhu;
	assign ex_memaddr_low_next = ex_memaddr_low;

//to bypass
	assign ex_wdata_bp_o	= ex_wdata_next;

//for mem
	wire [1:0]  ex_memaddr_low; 						//地址最末两位
	wire   ex_memwen_sb;
	wire   ex_memwen_sh;
	assign ex_memaddr_low	= ex_alures_i[1:0];
	assign ex_memwen_sb		= ex_memaddr_low == 2'b00 ? 4'b0001:
							  ex_memaddr_low == 2'b01 ? 4'b0010:
							  ex_memaddr_low == 2'b10 ? 4'b0100:
							  4'b1000;
	assign ex_memwen_sh		= ex_memaddr_low == 2'b00 ? 4'b0011:
							  4'b1100;

	assign ex_menen_o 		= |ex_memop_i;	    //使能
	assign ex_memwen_o 		= op_sb ? ex_memwen_sb :
							  op_sh ? ex_memwen_sh :
							  op_sw ? 4'b1111	   :
							  4'b0000; 	    			//写使能	
	assign ex_memaddr_o 	= {ex_alures_i[31:2],2'b00};		//data_sram_addr  访存地址通过alu计算
	assign ex_memwdata_o 	= op_sb ? {4{ex_rtvalue_i[7:0]}} :
							  op_sh ? {2{ex_rtvalue_i[15:0]}}:
							  ex_rtvalue_i;   	//data_sram_wdata


//DFFREs
DFFRE #(.WIDTH(1))		wren_next			(.d(ex_wren_next), .q(ex_wren_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(5))		waddr_next			(.d(ex_waddr_next), .q(ex_waddr_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))		wdata_next			(.d(ex_wdata_next), .q(ex_wdata_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))		inst_next			(.d(ex_inst_next), .q(ex_inst_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))		inslot_next			(.d(ex_inslot_next), .q(ex_inslot_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))		nofwd_next			(.d(ex_nofwd_next), .q(ex_nofwd_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(`MMOP_W))		memop_next			(.d(ex_memop_next), .q(ex_memop_o),  .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))		pc_next				(.d(ex_pc_next), .q(ex_pc_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))		inst_load_next		(.d(ex_inst_load_next), .q(ex_inst_load_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(2))		memaddr_low_next	(.d(ex_memaddr_low_next), .q(ex_memaddr_low_o), .en(en), .clk(clk), .rst_n(rst_n));



//未完成
assign ex_stallreq_o = 0;




endmodule