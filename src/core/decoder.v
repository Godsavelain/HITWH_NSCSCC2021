`include "../defines.v"

module decoder
(
	input wire				clk,
	input wire				rst_n,
	input wire 				id_flush_i,			//from controller
	input wire				id_stall_i,	

	//from if
	input wire [31: 0] 		id_pc_i,
	input wire [31: 0] 		id_inst_i,
	input wire 				id_in_delay_slot_i,

	//from regfile
	input wire [31: 0]		id_reg1data_i,
	input wire [31: 0]		id_reg2data_i,

	//exceptions
	// input  wire [`Excs] excs_i,
 	// output reg  [`Excs] excs_o

 	//for branch
 	output wire 			id_branch_en_o,
 	output wire [31: 0]		id_branch_pc_o,
 	output wire				id_next_inslot_o,

 	//to regfile
 	output wire [ 4: 0]		id_reg1addr_o,
 	output wire [ 4: 0]		id_reg2addr_o,	

 	output wire [31: 0]		id_opr1_o,
 	output wire [31: 0]		id_opr2_o,	
 	output wire [ 4: 0]		id_wren_o,
 	output wire [31: 0]		id_wdata_o,
 	output wire [`AOP] 		id_aluop_o,
 	output wire [`MDOP] 	id_mduop_o,
 	output wire [`MMOP] 	id_memop_o,
 	output wire  [`TOP ] 	id_tlbop_o,
    output wire  [`COP ] 	id_cacheop_o,

    //about C0
    output wire          	id_c0wen_o,
    output wire          	id_c0ren_o,
    output wire [ 7: 0]  	id_c0addr_o,

 	output wire 			id_stallreq_o
);

//output signals
	wire 		en;
	wire [ 4: 0]		id_reg1addr_next;
 	wire [ 4: 0]		id_reg2addr_next;	

 	wire [31: 0]		id_opr1_next;
 	wire [31: 0]		id_opr2_next;	
 	wire [ 4: 0]		id_wren_next;
 	wire [31: 0]		id_wdata_next;
 	wire [`AOP] 		id_aluop_next;
 	wire [`MDOP] 		id_mduop_next;
 	wire [`MMOP] 		id_memop_next;
 	wire [`TOP ] 		id_tlbop_next;
    wire [`COP ] 		id_cacheop_next;

    wire          		id_c0wen_next;
    wire          		id_c0ren_next;
    wire [ 7: 0] 		id_c0addr_next;




    wire [ 5: 0] opcode    = id_inst_i[31:26];
    wire [ 4: 0] rs        = id_inst_i[25:21];
    wire [ 4: 0] rt        = id_inst_i[20:16];
    wire [ 4: 0] rd        = id_inst_i[15:11];
    wire [ 4: 0] sa        = id_inst_i[10: 6];
    wire [ 5: 0] funct     = id_inst_i[ 5: 0];
    wire [15: 0] imme      = id_inst_i[15: 0];
    wire [25: 0] j_offset  = id_inst_i[25: 0];
    wire [ 2: 0] sel       = id_inst_i[ 2: 0];

    wire [63: 0] op_d;
    wire [63: 0] func_d;
    wire [31: 0] sa_d;
	wire [31:0] rs_d;
	wire [31:0] rt_d;
	wire [31:0] rd_d;

	wire [11:0] alu_op;

	wire        src1_is_sa;
	wire        src1_is_pc;
	wire        src2_is_imm;
	wire        src2_is_8;


    decoder_6_64 u_dec0(.in(opcode), .out(op_d	 ));
    decoder_6_64 u_dec1(.in(funct) , .out(func_d));
    decoder_5_32 u_dec5(.in(sa)	   , .out(sa_d	 ));

	decoder_5_32 u_dec2(.in(rs  ), .out(rs_d  ));
	decoder_5_32 u_dec3(.in(rt  ), .out(rt_d  ));
	decoder_5_32 u_dec4(.in(rd  ), .out(rd_d  ));


	wire        inst_addu;
	wire        inst_subu;
	wire        inst_addiu;

	wire        inst_slt;
	wire        inst_sltu;

	wire        inst_and;
	wire        inst_or;
	wire        inst_xor;
	wire        inst_nor;

	wire        inst_sll;
	wire        inst_srl;
	wire        inst_sra;

	wire        inst_lui;
	wire        inst_lw;
	wire        inst_sw;

	wire        inst_beq;
	wire        inst_bne;
	wire        inst_jal;
	wire        inst_jr;


    assign inst_addu   = op_d[6'h00] & func_d[6'h21] & sa_d[5'h00];
	assign inst_subu   = op_d[6'h00] & func_d[6'h23] & sa_d[5'h00];
	assign inst_slt    = op_d[6'h00] & func_d[6'h2a] & sa_d[5'h00];
	assign inst_sltu   = op_d[6'h00] & func_d[6'h2b] & sa_d[5'h00];
	assign inst_and    = op_d[6'h00] & func_d[6'h24] & sa_d[5'h00];
	assign inst_or     = op_d[6'h00] & func_d[6'h25] & sa_d[5'h00];
	assign inst_xor    = op_d[6'h00] & func_d[6'h26] & sa_d[5'h00];
	assign inst_nor    = op_d[6'h00] & func_d[6'h27] & sa_d[5'h00];
	assign inst_sll    = op_d[6'h00] & func_d[6'h00] & rs_d[5'h00];
	assign inst_srl    = op_d[6'h00] & func_d[6'h02] & rs_d[5'h00];
	assign inst_sra    = op_d[6'h00] & func_d[6'h03] & rs_d[5'h00];
	assign inst_addiu  = op_d[6'h09];
	assign inst_lui    = op_d[6'h0f] & rs_d[5'h00];
	assign inst_lw     = op_d[6'h23];
	assign inst_sw     = op_d[6'h2b];
	assign inst_beq    = op_d[6'h04];
	assign inst_bne    = op_d[6'h05];
	assign inst_jal    = op_d[6'h03];
	assign inst_jr     = op_d[6'h00] & func_d[6'h08] & rt_d[5'h00] & rd_d[5'h00] & sa_d[5'h00];

	assign alu_op[ 0] = inst_addu | inst_addiu | inst_lw | inst_sw | inst_jal;
	assign alu_op[ 1] = inst_subu;
	assign alu_op[ 2] = inst_slt;
	assign alu_op[ 3] = inst_sltu;
	assign alu_op[ 4] = inst_and;
	assign alu_op[ 5] = inst_nor;
	assign alu_op[ 6] = inst_or;
	assign alu_op[ 7] = inst_xor;
	assign alu_op[ 8] = inst_sll;
	assign alu_op[ 9] = inst_srl;
	assign alu_op[10] = inst_sra;
	assign alu_op[11] = inst_lui;

	assign src1_is_sa   = inst_sll   | inst_srl | inst_sra;
	assign src1_is_pc   = inst_jal;
	assign src2_is_imm  = inst_addiu | inst_lui | inst_lw | inst_sw;
	assign src2_is_8    = inst_jal;


endmodule