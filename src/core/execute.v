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

 	//bypass 
 	output wire				ex_wdata_bp_o

);
	
	wire					en;
	assign  en 				= ~ ex_stall_i; ;
	
    wire					ex_wren_next;
    wire 		[ 4: 0] 	ex_waddr_next;
    wire		[31: 0]		ex_wdata_next;
    wire 		[31: 0]		ex_inst_next;
    wire					ex_inslot_next;
    wire		[`MMOP]		ex_memop_next;
    wire 					ex_nofwd_next;


//useful values
	wire 	s_opr1;			
	wire 	s_opr2;			
	wire 	s_res;			

	wire	opr_lt;		
	wire	opr_ltu; 		
	wire	opr_eq; 

	wire	ls_addr;

	assign 	s_opr1			= ex_opr1_i[31];
	assign 	s_opr2			= ex_opr2_i[31];
	assign 	s_res			= ex_alures_i[31];

	assign	opr_lt			= $signed(ex_opr1_i) < $signed(ex_opr2_i);
	assign	opr_ltu 		= ex_opr1_i < ex_opr2_i;
	assign	opr_eq  		= (ex_opr1_i ^ ex_opr2_i) == 0;

	assign	ls_addr			= ex_alures_i;

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

//to bypass
	assign ex_wdata_bp_o	= ex_wdata_next;



//DFFREs
DFFRE #(.WIDTH(1))		wren_next			(.d(ex_wren_next), .q(ex_wren_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(5))		waddr_next			(.d(ex_waddr_next), .q(ex_waddr_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))		wdata_next			(.d(ex_wdata_next), .q(ex_wdata_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))		inst_next			(.d(ex_inst_next), .q(ex_inst_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))		inslot_next			(.d(ex_inslot_next), .q(ex_inslot_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))		nofwd_next			(.d(ex_nofwd_next), .q(ex_nofwd_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(`MMOP_W))		memop_next			(.d(ex_memop_next), .q(ex_memop_o), .en(en), .clk(clk), .rst_n(rst_n));

//未完成
assign ex_stallreq_o = 0;

assign ex_menen_o = 0;	    //data_sram_en
assign ex_memwen_o = 0;	    //data_sram_wen	
assign ex_memaddr_o = 0;	//data_sram_addr
assign ex_memwdata_o = 0;   //data_sram_wdata


endmodule