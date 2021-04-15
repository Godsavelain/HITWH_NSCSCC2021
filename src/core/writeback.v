`include "../defines.v"

module writeback
(
	input wire 				clk,
	input wire 				rst,
	input wire				wb_stall_i,
	input wire 				wb_flush_i,

	input wire [`MMOP]		wb_memop_i,
	input wire 				wb_wen_i,
	input wire [31: 0]		wb_waddr_i,
	input wire [31: 0]		wb_wdata_i,

	input wire [31: 0]		wb_pc_i,

	input wire [31: 0]		wb_mem_addr_i,
	//from mem
	input wire [31: 0]		wb_mem_data_i,


	//to regfile
	output wire 			wb_wen_o,
	output wire [31: 0]		wb_waddr_o,
	output wire [31: 0]		wb_wdata_o,

	output [31: 0] 			debug_wb_pc,
    output [ 3: 0] 			debug_wb_rf_wen ,
    output [ 4: 0] 			debug_wb_rf_wnum,
    output [31: 0] 			debug_wb_rf_wdata
);


	wire   [31: 0]			wb_wdata_final;

	assign wb_wdata_final		= wb_wdata_i;

	assign debug_wb_rf_wen 		= {4{wb_wen_i}};
	assign debug_wb_rf_wnum		= wb_waddr_i;
	assign debug_wb_rf_wdata	= wb_wdata_final;

	assign debug_wb_pc			= wb_pc_i;


endmodule