`include "../defines.v"

module control 
(
	input wire streq_pc_i,
	input wire streq_id_i,
	input wire streq_ex_i,
	input wire streq_mem_i,
	input wire streq_wb_i,
	input wire exc_flag,

	input wire icache_stall_i,
	input wire dcache_stall_i,

	//output wire stall_pre_pc_o,
	output wire stall_pc_o,
	output wire stall_id_o,
	output wire stall_ex_o,
	output wire stall_mem_o,
	output wire stall_wb_o,

	output wire  flush_id_o,
	output wire  flush_ex_o,
	output wire  flush_mem_o,
	output wire  flush_wb_o

);

	wire [4:0 ] stall;
	//assign stall_pre_pc_o = streq_pc_i;
	assign stall_pc_o  = exc_flag ? 1'b0 : stall[1];
	assign stall_id_o  = exc_flag ? 1'b0 : stall[2];
	assign stall_ex_o  = exc_flag ? 1'b0 : stall[3];
	assign stall_mem_o = exc_flag ? 1'b0 : stall[4];
	assign stall_wb_o  = 1'b0;

assign stall = streq_wb_i  					? 5'b11111 :
			   (streq_mem_i | dcache_stall_i) ? 5'b01111 :
			   streq_ex_i 					? 5'b00111 :
			   streq_id_i  			    	? 5'b00011 :
			   icache_stall_i				? 5'b00001 :
			   //streq_pc_i  					? 5'b00011 :			   
			   5'b00000;
assign flush_wb_o  = exc_flag ? 1'b1 : stall[3] & ~stall[4];
assign flush_mem_o = exc_flag ? 1'b1 : stall[2] & ~stall[3];
assign flush_ex_o  = exc_flag ? 1'b1 : stall[1] & ~stall[2];
assign flush_id_o  = (exc_flag | streq_pc_i) ? 1'b1 : stall[0] & ~stall[1];
//assign flush_pc_o  = exc_flag ? 1'b1 : stall[0];


endmodule