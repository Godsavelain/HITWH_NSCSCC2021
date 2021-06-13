`include "../defines.v"

module pc
(
	input wire				clk,
	input wire				rst_n,
	input wire 				if_flush_i,			//from controller
	input wire 				pc_flush_i,
	input wire				if_stall_i,			//from controller
	//input wire				usrmode,
	input wire				branch_en,
	input wire [31: 0]		if_pc_i,

	input wire [31: 0]		flush_pc_i,
	input wire [31: 0]		branch_pc_i,
	input wire [31: 0]		inst_i,			//inst_sram_rdata
	input wire				if_inslot_i,

	output wire [31: 0]		next_pc_o,
	output wire				inst_sram_en,  
	output wire [31: 0] 	if_pc_o,		//current pc
	output wire [31: 0] 	if_next_pc_o,	//inst_sram_addr
	output wire [31: 0]		if_inst_o,		//current inst
	//output wire			if_stallreq_o,	//to controller
	output wire				if_inslot_o,
	output wire [`ExcE] 	if_excs_o,		//exceptions
	output wire 			if_has_exc_o,

	//constants     can't write instram
	output wire [ 3: 0] 	inst_sram_wen  ,
    output wire [31: 0] 	inst_sram_wdata

    
	//output wire		if_inslot_o,
	//output wire		if_inst_null_o
);

wire [31:0] 	pc_next;
wire [31: 0]	if_inst_next;
wire 			if_has_exc_next;
wire 			en;
//wire[31:0] 	inst_next;
wire 			if_inslot_next;
wire [`ExcE] 	if_excs_next;



assign inst_sram_wen   = 4'h0;
assign inst_sram_wdata = 32'b0;
// assign inst_sram_en   =!(if_stall_i||pc_flush_i) ;
//assign inst_sram_en   =!pc_flush_i;
assign inst_sram_en   = 1;
assign pc_next 		=  !rst_n	? 32'hbfbffffc		:			   
				   		// stall	? pc_next 			:
				   		pc_flush_i	? flush_pc_i	:
				   		if_pc_i;
				   		;

assign if_next_pc_o =  	if_stall_i? pc_next		:
						branch_en? branch_pc_i		:						
				   		pc_next + 4
				   		;

assign if_inst_next 	= 	!rst_n 	? 0					:
						// stall	? inst_next 		:
						if_flush_i 	? 0					:
						inst_i
						;

assign if_has_exc_next  = if_flush_i ? 0 : ~(if_pc_i[1:0] == 2'b00);
assign if_excs_next[0]	= 0;
assign if_excs_next[1]	= if_flush_i ? 0 : ~(if_pc_i[1:0] == 2'b00);
assign if_excs_next[`ExcE_W-1: 2]	= 0;

assign en 			= 	~ if_stall_i;

assign if_inslot_next = if_flush_i ? 0 :if_inslot_i;

DFFRE #(.WIDTH(32))		pc_result_next			(.d(pc_next), .q(if_pc_o), .en(en), .clk(clk), .rst_n(1));
DFFRE #(.WIDTH(1))		delayslot_result_next	(.d(if_inslot_next), .q(if_inslot_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))		inst_result_next		(.d(if_inst_next), .q(if_inst_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))		pc_next_in				(.d(if_next_pc_o), .q(next_pc_o), .en(en), .clk(clk), .rst_n(1));
DFFRE #(.WIDTH(`ExcE_W))excs_next				(.d(if_excs_next), .q(if_excs_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))		has_excs_next			(.d(if_has_exc_next), .q(if_has_exc_o), .en(en), .clk(clk), .rst_n(rst_n));

endmodule