`include "../defines.v"

module mem
(
	input wire			clk,
	input wire			rst,

	input wire [31: 0]	mem_memdata_i,	//data from data sram

	input wire [31: 0]	mem_inst_i,
	input wire 			mem_inslot_i,
	input wire [`MMOP]	mem_memop_i,

	input wire [ 4: 0]	mem_waddr_i,
	input wire [31: 0]	mem_wdata_i,
	input wire 			mem_wren_i,
	input wire			mem_nofwd_i,

	input wire 			mem_stall_i,
	input wire 			mem_flush_i,	

	output wire [31: 0]	mem_inst_o,
	output wire 		mem_inslot_o,

	output wire [ 4: 0]	mem_waddr_o,
	output wire [31: 0]	mem_wdata_o,
	output wire 		mem_wren_o,

	output wire			mem_stall_o



);
	
	wire			en;

	wire 			mem_inst_next;
	wire 			mem_inslot_next;
	wire [ 4: 0]	mem_waddr_next;
	wire [31: 0]	mem_wdata_next;
	wire 			mem_wren_next;
	wire 			mem_nofwd_next;

	assign  mem_inst_next  		= mem_inst_i;
	assign  mem_inslot_next		= mem_inslot_i;
	assign  mem_waddr_next 		= mem_waddr_i;
	assign  mem_wdata_next 		= mem_wdata_i;
	assign 	mem_wren_next		= mem_wren_i;


DFFRE #(.WIDTH(32))		inst_next				(.d(mem_inst_next), .q(mem_inst_o), .en(en), .clk(clk), .rst_n(1));
DFFRE #(.WIDTH(32))		inslot_next				(.d(mem_inslot_next), .q(mem_inslot_o), .en(en), .clk(clk), .rst_n(1));
DFFRE #(.WIDTH(32))		waddr_next				(.d(mem_waddr_next), .q(mem_waddr_o), .en(en), .clk(clk), .rst_n(1));
DFFRE #(.WIDTH(32))		wdata_next				(.d(mem_wdata_next), .q(mem_wdata_o), .en(en), .clk(clk), .rst_n(1));
DFFRE #(.WIDTH(32))		wren_next				(.d(mem_wren_next), .q(mem_wren_o), .en(en), .clk(clk), .rst_n(1));

//未完成
assign mem_stall_o = 0;

endmodule