`include "../defines.v"

module execute
(
	input wire				clk,
	input wire				rst,
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

    //output wire [ 1: 0]		ex_memsize_o,
    

    //to alu
    output wire [`AOP] 		ex_aluop_o,
    output wire [31: 0]		ex_opr1_o,
 	output wire [31: 0]		ex_opr2_o,

 	//to mmu
 	output wire				ex_menen_o,		//data_sram_en
	output wire [ 3: 0]		ex_memwen_o,	//data_sram_wen	
	output wire [31: 0] 	ex_memaddr_o,	//data_sram_addr
    output wire [31: 0] 	ex_memwdata_o,	//data_sram_wdata


 	output wire 			ex_stallreq_o

);

	
    wire					ex_wren_next;
    wire 		[ 4: 0] 	ex_waddr_next;
    wire		[31: 0]		ex_wdata_next;


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





endmodule