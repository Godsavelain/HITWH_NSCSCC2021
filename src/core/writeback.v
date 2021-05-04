`include "../defines.v"

module writeback
(
	input wire 				clk,
	input wire 				rst_n,
	input wire				wb_stall_i,
	input wire 				wb_flush_i,

	input wire [`MMOP]		wb_memop_i,
	input wire 				wb_wren_i,
	input wire [4: 0]		wb_waddr_i,
	input wire [31: 0]		wb_wdata_i,
	input wire [31: 0]		wb_inst_i,
	input wire 				wb_mduinst_i,

	input wire [31: 0]		wb_pc_i,

	input wire [31: 0]		wb_mem_addr_i,
	//from mem
	input wire [31: 0]		wb_mem_data_i,

	//from mdu
	input wire [31: 0] 		wb_hi_i,
	input wire [31: 0] 		wb_lo_i,
	input wire 				wb_whien_i,
	input wire 				wb_wloen_i,
	input wire 				wb_inst_mfhi_i,
	input wire 				wb_inst_mflo_i,

	//to regfile
	output wire 			wb_wren_o,
	output wire [ 4: 0]		wb_waddr_o,
	output wire [31: 0]		wb_wdata_o,

	//to hilo
	output wire 			wb_whien_o,
	output wire 			wb_wloen_o,
	output wire [31: 0]		wb_hi_o,
	output wire [31: 0]		wb_lo_o,

	//to control
	output wire 			wb_stallreq,

	output [31: 0] 			debug_wb_pc,
    output [ 3: 0] 			debug_wb_rf_wen ,
    output [ 4: 0] 			debug_wb_rf_wnum,
    output [31: 0] 			debug_wb_rf_wdata
);


	wire   [31: 0]			wb_wdata_final;

	assign wb_wdata_final		= wb_inst_mfhi_i ? wb_hi_i :
								  wb_inst_mflo_i ? wb_lo_i :
								  wb_wdata_i;
//to regfile
	assign wb_wren_o			= wb_stallreq ? 0 : wb_wren_i;
	assign wb_waddr_o			= wb_waddr_i;
	assign wb_wdata_o  			= wb_wdata_final;

	assign debug_wb_rf_wen 		= wb_stallreq ? 0 : {4{wb_wren_i}};
	assign debug_wb_rf_wnum		= wb_stallreq ? 0 : wb_waddr_i;
	assign debug_wb_rf_wdata	= wb_stallreq ? 0 : wb_wdata_final;

	assign debug_wb_pc			= wb_stallreq ? 0 : wb_pc_i;

//to controller
	assign wb_stallreq  		= 0;

//to hilo
	assign 			wb_whien_o =  wb_whien_i;
	assign 			wb_wloen_o =  wb_wloen_i;
	assign			wb_hi_o    =  wb_hi_i;
	assign			wb_lo_o    =  wb_lo_i;


endmodule