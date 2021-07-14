`include "../defines.v"

module mem
(
	input wire			clk,
	input wire			rst_n,

	input wire [31: 0]	mem_memdata_i,	//data from data sram

	input wire [31: 0]	mem_inst_i,
	input wire 			mem_inslot_i,
	input wire [`MMOP]	mem_memop_i,
	input wire [31: 0]	mem_pc_i,
	input wire [ 1: 0]  mem_memaddr_low_i,

	input wire [ 4: 0]	mem_waddr_i,
    input wire [31: 0]	mem_wdata_i,
	input wire 			mem_c0_ren_i,
	input wire [31: 0]	mem_c0data_i,
	input wire [ 3: 0]	mem_wren_i,
	input wire			mem_nofwd_i,
	input wire 			mem_inst_load_i,

	input wire 			mem_stall_i,
    input wire 			mem_flush_i,

	//from mdu
	input wire 			mem_s2_stallreq_i,

	//from dcache
	input wire			dcache_axi_stall_i,	

	output wire [31: 0]	mem_inst_o,
	//output wire 		mem_inslot_o,
	//output wire 		mem_memop_o,

	output wire [ 4: 0]	mem_waddr_o,
    output wire [31: 0]	mem_wdata_o,
	output wire [ 3: 0]	mem_wren_o,
	output wire [31: 0] mem_pc_o,
	//for bypass
	output wire [31: 0] mem_wdata_bp,
	output wire 		mem_nofwd_bp,

	output wire			mem_stall_o

);
	
	wire			en;
	assign  		en 	= ~ mem_stall_i;
	
	wire [31: 0]	lb_res;
	wire [31: 0]	lbu_res;
	wire [31: 0]	lh_res;
	wire [31: 0]	lhu_res;
	wire [31: 0]	lw_res;
	wire [31: 0]	load_res;
	wire [31: 0]	lwl_res;
	wire [31: 0]	lwr_res;
	
	assign 			lb_res 		=  mem_memaddr_low_i == 2'b00 ? {{24{mem_memdata_i[ 7]}} , mem_memdata_i[7 : 0]} :
								   mem_memaddr_low_i == 2'b01 ? {{24{mem_memdata_i[15]}} , mem_memdata_i[15: 8]} :
								   mem_memaddr_low_i == 2'b10 ? {{24{mem_memdata_i[23]}} , mem_memdata_i[23:16]} :
								   {{24{mem_memdata_i[31]}} , mem_memdata_i[31:24]};

	assign 			lbu_res 	=  mem_memaddr_low_i == 2'b00 ? {24'b0 , mem_memdata_i[7 : 0]} :
								   mem_memaddr_low_i == 2'b01 ? {24'b0 , mem_memdata_i[15: 8]} :
								   mem_memaddr_low_i == 2'b10 ? {24'b0 , mem_memdata_i[23:16]} :
								   {24'b0 , mem_memdata_i[31:24]};

	assign 			lh_res 		=  mem_memaddr_low_i == 2'b00 ? {{16{mem_memdata_i[15]}} , mem_memdata_i[15: 0]} :
								   {{16{mem_memdata_i[31]}} , mem_memdata_i[31:16]};

	assign 			lhu_res 	=  mem_memaddr_low_i == 2'b00 ? {16'b0 , mem_memdata_i[15: 0]} :
								   {16'b0 , mem_memdata_i[31:16]};

	assign 			lw_res		=  mem_memdata_i;


	assign 			load_res 	= ({32{mem_memop_i[0]}} & lb_res ) 
								| ({32{mem_memop_i[1]}} & lbu_res)
								| ({32{mem_memop_i[2]}} & lh_res )
								| ({32{mem_memop_i[3]}} & lhu_res)
								| ({32{mem_memop_i[4]}} & lw_res )
								| ({32{mem_memop_i[8]}} & lwl_res)
								| ({32{mem_memop_i[9]}} & lwr_res);

	assign 			lwl_res  	= ({32{!(mem_memaddr_low_i[0] |  mem_memaddr_low_i[1])}} &{mem_memdata_i[ 7: 0] , 24'b0} )
								| ({32{ (mem_memaddr_low_i[0] & !mem_memaddr_low_i[1])}} &{mem_memdata_i[15: 0] , 16'b0} )
								| ({32{(!mem_memaddr_low_i[0] &  mem_memaddr_low_i[1])}} &{mem_memdata_i[23: 0] ,  8'b0} )
								| ({32{ (mem_memaddr_low_i[0] &  mem_memaddr_low_i[1])}} & mem_memdata_i[31: 0] 		 );


	assign 			lwr_res  	= ({32{!(mem_memaddr_low_i[0] |  mem_memaddr_low_i[1])}} & 		  mem_memdata_i[31: 0]	 )
								| ({32{ (mem_memaddr_low_i[0] & !mem_memaddr_low_i[1])}} &{8'b0 , mem_memdata_i[31: 8] } )
								| ({32{(!mem_memaddr_low_i[0] &  mem_memaddr_low_i[1])}} &{16'b0, mem_memdata_i[31:16] } )
								| ({32{ (mem_memaddr_low_i[0] &  mem_memaddr_low_i[1])}} &{24'b0, mem_memdata_i[31:24] } );

	// assign 			lwl_res  	= mem_memaddr_low_i == 2'b00 ? {mem_memdata_i[ 7: 0] , 24'b0} :
	// 							  mem_memaddr_low_i == 2'b01 ? {mem_memdata_i[15: 0] , 16'b0} :
	// 							  mem_memaddr_low_i == 2'b10 ? {mem_memdata_i[23: 0] ,  8'b0} :
	// 							  mem_memdata_i;

	// assign 			lwr_res  	= mem_memaddr_low_i == 2'b00 ?  mem_memdata_i:
	// 							  mem_memaddr_low_i == 2'b01 ? {mem_memdata_i[23: 0] ,  8'b0} :
	// 							  mem_memaddr_low_i == 2'b10 ? {mem_memdata_i[15: 0] , 16'b0} :
	// 							  {mem_memdata_i[ 7: 0] , 24'b0} ;

	assign 			mem_wdata_bp= mem_wdata_i;
	assign 			mem_nofwd_bp= mem_nofwd_i;


	wire [31: 0] 	mem_inst_next;
	//wire 			mem_inslot_next;
	wire [ 4: 0]	mem_waddr_next;
	wire [31: 0]	mem_wdata_next;
	wire [ 3: 0]	mem_wren_next;
	wire 			mem_nofwd_next;
	wire 			mem_memop_next;
	wire [31: 0]	mem_pc_next;
	wire 			mem_mduinst_next;

	wire [ 3: 0]	lwl_wren;
	wire [ 3: 0]	lwr_wren;

	assign lwl_wren	 =  ({4{!(mem_memaddr_low_i[0] |  mem_memaddr_low_i[1])}} & 4'b1000 )
					   |({4{ (mem_memaddr_low_i[0] & !mem_memaddr_low_i[1])}} & 4'b1100 )
					   |({4{(!mem_memaddr_low_i[0] &  mem_memaddr_low_i[1])}} & 4'b1110 )
					   |({4{ (mem_memaddr_low_i[0] &  mem_memaddr_low_i[1])}} & 4'b1111 );

	assign lwr_wren	 =  ({4{!(mem_memaddr_low_i[0] |  mem_memaddr_low_i[1])}} & 4'b1111 )
					   |({4{ (mem_memaddr_low_i[0] & !mem_memaddr_low_i[1])}} & 4'b0111 )
					   |({4{(!mem_memaddr_low_i[0] &  mem_memaddr_low_i[1])}} & 4'b0011 )
					   |({4{ (mem_memaddr_low_i[0] &  mem_memaddr_low_i[1])}} & 4'b0001 );

	// assign lwl_wren	 = mem_memaddr_low_i == 2'b00 ? 1000 :
	// 				   mem_memaddr_low_i == 2'b01 ? 1100 :
	// 				   mem_memaddr_low_i == 2'b10 ? 1110 :
	// 				   1111 ;
	// assign lwr_wren	 = mem_memaddr_low_i == 2'b00 ? 1111 :
	// 				   mem_memaddr_low_i == 2'b01 ? 0111 :
	// 				   mem_memaddr_low_i == 2'b10 ? 0011 :
	// 				   0001 ;

	assign  mem_inst_next  		= mem_flush_i ? 0 :mem_inst_i;
	//assign  mem_inslot_next		= mem_flush_i ? 0 :mem_inslot_i;
	assign  mem_waddr_next 		= mem_flush_i ? 0 :mem_waddr_i;
	assign  mem_wdata_next 		= mem_flush_i ? 0 :mem_c0_ren_i ? mem_c0data_i :mem_inst_load_i ? load_res :
								  mem_wdata_i;
	assign 	mem_wren_next		= mem_flush_i ? 0 : mem_memop_i[8] ? lwl_wren :
								  					mem_memop_i[9] ? lwr_wren :
								  					mem_wren_i;
	assign  mem_memop_next		= mem_flush_i ? 0 :mem_memop_i;
	assign  mem_pc_next			= mem_pc_i;


//for bypass


DFFRE #(.WIDTH(32))		inst_next				(.d(mem_inst_next), .q(mem_inst_o), .en(en), .clk(clk), .rst_n(rst_n));
//DFFRE #(.WIDTH(1))		inslot_next				(.d(mem_inslot_next), .q(mem_inslot_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(5))		waddr_next				(.d(mem_waddr_next), .q(mem_waddr_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))		wdata_next				(.d(mem_wdata_next), .q(mem_wdata_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(4))		wren_next				(.d(mem_wren_next), .q(mem_wren_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))		pc_next					(.d(mem_pc_next), .q(mem_pc_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))		mduinst_next			(.d(mem_mduinst_next), .q(mem_mduinst_o), .en(en), .clk(clk), .rst_n(rst_n));


assign mem_stall_o = mem_s2_stallreq_i;

endmodule