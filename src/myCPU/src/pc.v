`include "../defines.v"

module pc
(
	input wire				clk,
	input wire				rst_n,
	input wire 				if_flush_i,			//from controller
	input wire 				pc_flush_i,
	input wire				if_stall_i,			//from controller
	input wire 				icache_axi_stall,//icache åœ¨ç­‰å¾…æ•°æ?
	input wire 				icache_stall,
	//input wire				usrmode,
	input wire				branch_en,
	input wire [31: 0]		if_pc_i,

	input wire [31: 0]		flush_pc_i,
	input wire [31: 0]		branch_pc_i,
	input wire [31: 0]		uc_inst_i,			//inst_sram_rdata    from icache_axi
	input wire				if_inslot_i,

	//from icache
	input  wire [31: 0] 	cache_inst_i,
	input  wire 			cache_valid_i,

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
	output wire [ 3: 0] 	inst_sram_wen,
    output wire [31: 0] 	inst_sram_wdata,
    output wire 			pc_pcvalid_o

    
	//output wire		if_inslot_o,
	//output wire		if_inst_null_o
);

wire [31:0] 	pc_next;
wire [31: 0]	if_inst_next;
wire 			if_has_exc_next;
wire 			en;
wire 			pre_in_en;
//wire[31:0] 	inst_next;
wire 			if_inslot_next;
wire [`ExcE] 	if_excs_next;
wire			pc_pcvalid_next;

reg [31: 0] branch_pc_reg;
reg 		use_branch_pc_reg;
reg [31: 0] exc_pc_reg;
reg 		use_exc_pc_reg;
reg 		in_delay_slot;

wire [31: 0]		inst_i;

wire icache_streq;
assign icache_streq = icache_axi_stall | icache_stall;

assign inst_i = cache_valid_i ? cache_inst_i : uc_inst_i ;

assign pre_in_en 		= (!rst_n) | branch_en | pc_flush_i	 ? 1 : 
					  icache_streq | if_stall_i  ? 0 :1;

assign inst_sram_wen   = 4'h0;
assign inst_sram_wdata = 32'b0;
//assign inst_sram_en   =!(if_stall_i||pc_flush_i) ;
//assign inst_sram_en   =!pc_flush_i;
assign inst_sram_en   = !if_stall_i;
assign pc_next 		=  !rst_n	? 32'hbfbffffc		:			   
				   		// stall	? pc_next 			:
				   		//pc_flush_i	? flush_pc_i	:
				   		if_pc_i;
				   		

assign if_next_pc_o =  	//!rst_n	? 32'hbfc00000:
						!rst_n	? 32'hbfbffffc		:
						icache_streq | if_stall_i ? if_pc_i		:
						(pc_flush_i & !(icache_streq | if_stall_i)) ? flush_pc_i		:
						(branch_en & !(icache_streq | if_stall_i) ) ? branch_pc_i		:
						use_exc_pc_reg ? exc_pc_reg :
						use_branch_pc_reg ? branch_pc_reg :
						//pre_in_en 	  ? if_pc_i + 4 :						
				   		pc_next + 4
				   		;

assign if_inst_next 	= !rst_n 	? 0					:
						// stall	? inst_next 		:
						( if_flush_i | use_exc_pc_reg )	? 0					:
						inst_i
						;

assign if_has_exc_next  = ( if_flush_i | use_exc_pc_reg ) ? 0 : ~(if_pc_i[1:0] == 2'b00);
assign if_excs_next[0]	= 0;
assign if_excs_next[1]	= ( if_flush_i | use_exc_pc_reg ) ? 0 : ~(if_pc_i[1:0] == 2'b00);
assign if_excs_next[`ExcE_W-1: 2]	= 0;
assign pc_pcvalid_next	= ( if_flush_i | use_exc_pc_reg ) ? 0 : 1;

assign en 			= 	~ if_stall_i;

assign if_inslot_next = ( if_flush_i | use_exc_pc_reg ) ? 0 : (if_inslot_i | in_delay_slot);


DFFRE #(.WIDTH(32))		pc_result_next			(.d(pc_next), .q(if_pc_o), .en(en), .clk(clk), .rst_n(1));
DFFRE #(.WIDTH(1))		delayslot_result_next	(.d(if_inslot_next), .q(if_inslot_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))		inst_result_next		(.d(if_inst_next), .q(if_inst_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))		pc_next_in				(.d(if_next_pc_o), .q(next_pc_o), .en(pre_in_en), .clk(clk), .rst_n(1));
DFFRE #(.WIDTH(`ExcE_W))excs_next				(.d(if_excs_next), .q(if_excs_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))		has_excs_next			(.d(if_has_exc_next), .q(if_has_exc_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))		pcvalid_next			(.d(pc_pcvalid_next), .q(pc_pcvalid_o), .en(en), .clk(clk), .rst_n(rst_n));



always @(posedge clk, negedge rst_n) begin
        if(!rst_n | !icache_streq) begin
            branch_pc_reg <= 0;
			use_branch_pc_reg <= 0;						
        end
        else begin
        	if((branch_en & icache_streq)&~if_stall_i)
        	begin
        		use_branch_pc_reg <= 1;
        		branch_pc_reg <= branch_pc_i;
        	end
        end
    end

always @(posedge clk, negedge rst_n) begin
        if(!rst_n | !icache_streq) begin
            exc_pc_reg <= 0;
			use_exc_pc_reg <= 0;					
        end
        else begin
        	if(pc_flush_i & ( icache_streq | if_stall_i ))
        	begin
        		exc_pc_reg <= flush_pc_i;
				use_exc_pc_reg <= 1;
        	end
        end
    end

always @(posedge clk, negedge rst_n) begin
        if(!rst_n | !icache_streq) begin
            in_delay_slot <= 0;					
        end
        else begin
        	if((if_inslot_i & icache_streq)&(~if_stall_i))
        	begin
				in_delay_slot <= 1;
        	end
        end
    end



endmodule