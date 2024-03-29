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
	input wire 				id_inslot_i,
	input wire [`ExcE] 		id_excs_i,
	input wire 				id_has_exc_i,

	//from regfile
	input wire [31: 0]		id_reg1data_i,
	input wire [31: 0]		id_reg2data_i,

 	//for branch	
 	output wire 			id_branch_en_o,
 	output wire [31: 0]		id_branch_pc_o,
 	output wire				id_next_inslot_o,

 	output wire [31: 0] 	id_inst_o,
 	output wire 		 	id_inslot_o,
 	output wire 			id_valid_o,
 	//to regfile
 	output wire 			id_ren1_o,
 	output wire 			id_ren2_o,
 	output wire [ 4: 0]		id_reg1addr_o,
 	output wire [ 4: 0]		id_reg2addr_o,

 	output wire				id_nofwd_o,// for load stall
 	output wire [31: 0]		id_pc_o,
 	output wire [31: 0]		id_opr1_o,
 	output wire [31: 0]		id_opr2_o,
 	output wire [31: 0]		id_offset_o,
 	output wire 			id_divinst_o,
 	output wire 			id_mduinst_o,

 	output wire [ 3: 0]	    id_wren_o,
 	output wire [ 4: 0]		id_waddr_o,
 	output wire [31: 0]		id_rtvalue_o,
 	output wire [`ExcE] 	id_excs_o,
	output wire 			id_has_exc_o,
	output wire 			id_ov_inst_o,//current inst could cause an ov exception

 	output wire [`AOP] 		id_aluop_o,
 	output wire [`MDOP] 	id_mduop_o,
 	output wire [`MMOP] 	id_memop_o,
 	output wire [`TOP ] 	id_tlbop_o,
    output wire [`COP ] 	id_cacheop_o,

    output wire 			id_intr_dis_o,

    //about C0
    output wire          	id_c0wen_o,
    output wire          	id_c0ren_o,
    output wire [ 7: 0]  	id_c0addr_o,

 	output wire 			id_stallreq_o,

 	//for optimization
 	output wire 			id_is_branch_o,

 	input  wire [31: 0]     raw_data1_i,  
    input  wire [31: 0]     raw_data2_i,
    input  wire 			id_pcvalid_i,
    output wire 			id_pcvalid_o,

    output wire 			id_inst_wb_nofwd_o
);

//output signals
	wire 				en;
	wire [31: 0]		id_inst;

	wire [31: 0] 		id_inst_next;
 	wire 		 		id_inslot_next;

 	wire [31: 0]		id_opr1_next;
 	wire [31: 0]		id_opr2_next;
 	wire [31: 0]		id_offset_next;
 	wire [31: 0]		id_pc_next;	
 	wire [ 3: 0]		id_wren_next;
 	wire [ 4: 0]		id_waddr_next;
 	wire [31: 0]  		id_rtvalue_next;
 	wire [`ExcE] 		id_excs_next;
	wire 				id_has_exc_next;
	wire 				id_ov_inst_next;
 	wire [`AOP] 		id_aluop_next;
 	wire [`MDOP] 		id_mduop_next;
 	wire 				id_mduinst_next;
 	wire [`MMOP] 		id_memop_next;
 	wire [`TOP ] 		id_tlbop_next;
    wire [`COP ] 		id_cacheop_next;
    wire 				id_nofwd_next;

    wire 				id_intr_dis_next;

    wire          		id_c0wen_next;
    wire          		id_c0ren_next;
    wire [ 7: 0] 		id_c0addr_next;
    wire				id_pcvalid_next;

    wire 				id_inst_wb_nofwd_next;


    wire [63: 0] op_d;
    wire [63: 0] func_d;
    wire [31: 0] sa_d;
	wire [31: 0] rs_d;
	wire [31: 0] rt_d;
	wire [31: 0] rd_d;

	wire [`AOP]  alu_op;
	wire [`MMOP] mem_op;

	wire        src1_is_sa;
	wire        src1_is_pc;
	wire        src2_is_8;
	wire 		src2_is_imm_s;//æœ‰ç¬¦å·æ‰©å±?
	wire 		src2_is_imm_u;//æ— ç¬¦å·æ‰©å±?
	wire		src2_is_joffset;

	wire [ 5: 0] opcode;
    wire [ 4: 0] rs;
    wire [ 4: 0] rt;
    wire [ 4: 0] rd;
    wire [ 4: 0] sa;
    wire [ 5: 0] funct;
    wire [15: 0] imme;
    wire [25: 0] j_offset;
    wire [ 2: 0] sel;

    //useful values
    wire [31: 0] pcp4;
    wire [31: 0] zero_ext;
    wire [31: 0] sign_ext;
    wire [31: 0] lui_ext;	//load upper imm
    wire [31: 0] sa_ext;	//used for shift
    wire		 waddr_is_31;// write GPR addr is 31
    wire		 waddr_is_rt;// write GPR addr is rt
    wire 		 mul_div;

    //arithmetic
	wire 		inst_add;
	wire 		inst_addi;
	wire        inst_addu;
	wire        inst_addiu;
	wire        inst_sub;
	wire        inst_subu;

	wire        inst_slt;
	wire        inst_slti;
	wire        inst_sltu;
	wire        inst_sltiu;

	wire        inst_div;
	wire        inst_divu;
	wire        inst_mult;
	wire        inst_multu;
	wire 		inst_mul;

//logic
	wire        inst_and;
	wire        inst_andi;
	wire        inst_lui;
	wire        inst_or;
	wire        inst_ori;
	wire        inst_xor;
	wire        inst_xori;
	wire        inst_nor;

//shift
	wire        inst_sll;
	wire        inst_sllv;
	wire        inst_srl;
	wire        inst_srlv;
	wire        inst_sra;
	wire        inst_srav;

//data transfer
	wire        inst_mfhi;
	wire        inst_mflo;
	wire        inst_mthi;
	wire        inst_mtlo;

//load/store
	wire        inst_lb;
	wire        inst_lbu;
	wire        inst_lh;
	wire        inst_lhu;
	wire        inst_lw;
	wire        inst_sb;
	wire        inst_sh;
	wire        inst_sw;
	wire 		inst_lwl;
	wire 		inst_lwr;
	wire 		inst_swl;
	wire 		inst_swr;

//branch
	wire        inst_beq;
	wire        inst_bne;
	wire        inst_bgez;
	wire        inst_bgtz;
	wire        inst_blez;
	wire        inst_bltz;
	wire        inst_bgezal;
	wire        inst_bltzal;
	wire        inst_j;
	wire        inst_jal;
	wire        inst_jr;
	wire        inst_jalr;

//privilege
	wire        inst_eret;
	wire 		inst_eret_0;//use it to judge inst_eret
	wire        inst_mfc0;
	wire        inst_mfc0_0;//use it to judge inst_mfc0
	wire        inst_mtc0;
	wire        inst_mtc0_0;//use it to judge inst_mtc0

	wire        inst_break;
	wire        inst_break_0;
    wire        inst_syscall;
	wire        inst_syscall_0;

    assign id_inst 		= id_inst_i;

    assign opcode    	= id_inst[31:26];
    assign rs        	= id_inst[25:21];
    assign rt        	= id_inst[20:16];
    assign rd        	= id_inst[15:11];
    assign sa        	= id_inst[10: 6];
    assign funct     	= id_inst[ 5: 0];
    assign imme      	= id_inst[15: 0];
    assign j_offset  	= id_inst[25: 0];
    assign sel       	= id_inst[ 2: 0];

    assign pcp4 	 	= id_pc_i + 4;
    assign zero_ext  	= {16'h0, imme};
    assign sign_ext  	= {{16{imme[15]}}, imme};
    assign lui_ext	 	= {imme, 16'h0};
    assign sa_ext	 	= {27'h0, sa};

    assign waddr_is_31	= inst_bgezal | inst_bltzal | inst_jal  | inst_jalr;
    assign waddr_is_rt	= inst_addi   | inst_addiu  | inst_slti | inst_sltiu 
    					| inst_andi   | inst_lui    | inst_ori  | inst_xori 
    					| inst_lb 	  | inst_lbu 	| inst_lh 	| inst_lhu
    					| inst_lw 	  | inst_mfc0	| inst_lwl  | inst_lwr
    					| inst_mfc0;
    assign mul_div 		= inst_div 	  | inst_divu 	|inst_mult 	| inst_multu;
    					//do not include mul because mul needs to write GPR

    //to regfile
	assign id_reg1addr_o	=	rs;
	assign id_reg2addr_o	=	rt;

	wire   inst_valid;
	assign inst_valid   = inst_add 	  | inst_addi    | inst_addu  | inst_addiu
						| inst_sub    | inst_subu    | inst_slt   | inst_slti
						| inst_sltu   | inst_sltiu	 | inst_div
						| inst_divu   | inst_mult    | inst_multu | inst_and
						| inst_andi   | inst_lui     | inst_or 	  | inst_ori
						| inst_xor    | inst_xori    | inst_nor   | inst_sll
						| inst_sllv   | inst_srl     | inst_srlv  | inst_sra
						| inst_srav   | inst_mfhi    | inst_mflo  | inst_mthi
						| inst_mtlo   | inst_lb      | inst_lbu   | inst_lh
						| inst_lhu    | inst_lw      | inst_sb    | inst_sh
						| inst_sw     | inst_lwl     | inst_lwr   | inst_swl
						| inst_swr    | inst_beq     | inst_bne   | inst_bgez
						| inst_bgtz   | inst_blez    | inst_bltz  | inst_bgezal
						| inst_bltzal | inst_j       | inst_jal   | inst_jr
						| inst_jalr   | inst_eret    | inst_mfc0  | inst_mtc0
						| inst_break  | inst_syscall | inst_mul;


	assign id_excs_next[0] = 0;
	assign id_excs_next[1] =  id_flush_i ? 0 : id_excs_i[1];
	assign id_excs_next[2] =  id_flush_i ? 0 : id_excs_i[2];
	assign id_excs_next[3] =  id_flush_i ? 0 : id_excs_i[3];
	assign id_excs_next[4] =  id_flush_i ? 0 : id_excs_i[4];
	assign id_excs_next[5] =  id_flush_i ? 0 : inst_syscall;
	assign id_excs_next[6] =  id_flush_i ? 0 : inst_break;
	assign id_excs_next[7] =  id_flush_i ? 0 : ~inst_valid;
	assign id_excs_next[8] =  id_flush_i ? 0 : inst_eret;
	assign id_has_exc_next =  id_flush_i ? 0 : id_has_exc_i | id_excs_next[8] | id_excs_next[5] | id_excs_next[6] | id_excs_next[7];
	assign id_ov_inst_next =  id_flush_i ? 0 : inst_add | inst_addi | inst_sub;

    decoder_6_64 u_dec0(.in(opcode), .out(op_d	 ));
    decoder_6_64 u_dec1(.in(funct) , .out(func_d ));
    decoder_5_32 u_dec5(.in(sa)	   , .out(sa_d	 ));

	decoder_5_32 u_dec2(.in(rs  ), .out(rs_d  ));
	decoder_5_32 u_dec3(.in(rt  ), .out(rt_d  ));
	decoder_5_32 u_dec4(.in(rd  ), .out(rd_d  ));



//decode
	assign inst_add    = op_d[`OP_SPECIAL] & func_d[6'h20] & sa_d[5'h00];
	assign inst_addi   = op_d[`OP_ADDI];
	assign inst_addiu  = op_d[`OP_ADDIU]; 
    assign inst_addu   = op_d[`OP_SPECIAL] & func_d[6'h21] & sa_d[5'h00];
    assign inst_sub    = op_d[`OP_SPECIAL] & func_d[6'h22] & sa_d[5'h00];
	assign inst_subu   = op_d[`OP_SPECIAL] & func_d[6'h23] & sa_d[5'h00];
	assign inst_slt    = op_d[`OP_SPECIAL] & func_d[6'h2a] & sa_d[5'h00];
	assign inst_slti   = op_d[`OP_SLTI];
	assign inst_sltu   = op_d[`OP_SPECIAL] & func_d[6'h2b] & sa_d[5'h00];
	assign inst_sltiu  = op_d[`OP_SLTIU];
	assign inst_div    = op_d[`OP_SPECIAL] & func_d[6'h1a] & sa_d[5'h00] & rd_d[5'h00];
	assign inst_divu   = op_d[`OP_SPECIAL] & func_d[6'h1b] & sa_d[5'h00] & rd_d[5'h00];
	assign inst_mul    = op_d[`OP_SPECIAL2] & func_d[6'h02] & sa_d[5'h00];
	assign inst_mult   = op_d[`OP_SPECIAL] & func_d[6'h18] & sa_d[5'h00] & rd_d[5'h00];
	assign inst_multu  = op_d[`OP_SPECIAL] & func_d[6'h19] & sa_d[5'h00] & rd_d[5'h00];
	assign inst_and    = op_d[`OP_SPECIAL] & func_d[6'h24] & sa_d[5'h00];
	assign inst_andi   = op_d[`OP_ANDI];
	assign inst_lui    = op_d[`OP_LUI] & rs_d[5'h00];
	assign inst_or     = op_d[`OP_SPECIAL] & func_d[6'h25] & sa_d[5'h00];
	assign inst_ori    = op_d[`OP_ORI];
	assign inst_xor    = op_d[`OP_SPECIAL] & func_d[6'h26] & sa_d[5'h00];
	assign inst_xori   = op_d[`OP_XORI];
	assign inst_nor    = op_d[`OP_SPECIAL] & func_d[6'h27] & sa_d[5'h00];
	assign inst_sll    = op_d[`OP_SPECIAL] & func_d[6'h00] & rs_d[5'h00];
	assign inst_sllv   = op_d[`OP_SPECIAL] & func_d[6'h04] & sa_d[5'h00];
	assign inst_srl    = op_d[`OP_SPECIAL] & func_d[6'h02] & rs_d[5'h00];
	assign inst_srlv   = op_d[`OP_SPECIAL] & func_d[6'h06] & sa_d[5'h00];
	assign inst_sra    = op_d[`OP_SPECIAL] & func_d[6'h03] & rs_d[5'h00];
	assign inst_srav   = op_d[`OP_SPECIAL] & func_d[6'h07] & sa_d[5'h00];


	assign inst_mfhi   = op_d[`OP_SPECIAL] & func_d[6'h10] & sa_d[5'h00];
	assign inst_mflo   = op_d[`OP_SPECIAL] & func_d[6'h12] & sa_d[5'h00];
	assign inst_mthi   = op_d[`OP_SPECIAL] & func_d[6'h11];
	assign inst_mtlo   = op_d[`OP_SPECIAL] & func_d[6'h13];
	
	
	assign inst_lb     = op_d[`OP_LB];
	assign inst_lbu    = op_d[`OP_LBU];
	assign inst_lh     = op_d[`OP_LH];
	assign inst_lhu    = op_d[`OP_LHU];
	assign inst_lw     = op_d[`OP_LW];
	assign inst_sb     = op_d[`OP_SB];
	assign inst_sh     = op_d[`OP_SH];
	assign inst_sw     = op_d[`OP_SW];
	assign inst_lwl    = op_d[`OP_LWL];
	assign inst_lwr    = op_d[`OP_LWR];
	assign inst_swl    = op_d[`OP_SWL];
	assign inst_swr    = op_d[`OP_SWR];

	//branch
	assign inst_beq    = op_d[`OP_BEQ];
	assign inst_bne    = op_d[`OP_BNE];
	assign inst_bgez   = op_d[`OP_REGIMM] & rt_d[5'h01];
	assign inst_bgtz   = op_d[`OP_BGTZ]   & rt_d[5'h00];
	assign inst_blez   = op_d[`OP_BLEZ]   & rt_d[5'h00];
	assign inst_bltz   = op_d[`OP_REGIMM] & rt_d[5'h00];
	assign inst_bgezal = op_d[`OP_REGIMM] & rt_d[5'h11];
	assign inst_bltzal = op_d[`OP_REGIMM] & rt_d[5'h10];
	assign inst_j 	   = op_d[`OP_J];
	assign inst_jal    = op_d[`OP_JAL];
	assign inst_jr     = op_d[`OP_SPECIAL] & func_d[6'h08] & rt_d[5'h00] & rd_d[5'h00] & sa_d[5'h00];
	assign inst_jalr   = op_d[`OP_SPECIAL] & func_d[6'h09] & rt_d[5'h00] & sa_d[5'h00];

	assign inst_eret_0 = op_d[`OP_COP0] & func_d[6'h18];
	assign inst_eret   = inst_eret_0 & id_inst_i[25] & ((id_inst_i[24: 6] ^ 0)==0);
	assign inst_mfc0_0 = op_d[`OP_COP0] & rs_d[5'h00];
	assign inst_mfc0   = inst_mfc0_0 & ((id_inst_i[10: 3] ^ 0)==0);
	assign inst_mtc0_0 = op_d[`OP_COP0] & rs_d[5'h04];
	assign inst_mtc0   = inst_mtc0_0 & ((id_inst_i[10: 3] ^ 0)==0);

	// assign inst_break_0= op_d[`OP_SPECIAL] & func_d[6'h0d];
	// assign inst_break  = inst_break_0 & ((id_inst_i[25: 6] ^ 0)==0);
	// assign inst_syscall_0= op_d[`OP_SPECIAL] & func_d[6'h0c];
	// assign inst_syscall= inst_syscall_0 & ((id_inst_i[25: 6] ^ 0)==0);

	assign inst_break_0= op_d[`OP_SPECIAL] & func_d[6'h0d];
	assign inst_break  = inst_break_0 ;
	assign inst_syscall_0= op_d[`OP_SPECIAL] & func_d[6'h0c];
	assign inst_syscall= inst_syscall_0 ;

	assign alu_op[ 0] = inst_addu | inst_addiu | inst_lw | inst_lhu | inst_lh 
					  | inst_add  | inst_lbu   | inst_lb | inst_sw  | inst_sh
					  | inst_addi | inst_sb    | inst_jal| inst_jalr| inst_bgezal
					  |	inst_lwl  | inst_lwr   | inst_swl| inst_swr	| inst_bltzal;
	assign alu_op[ 1] = inst_subu | inst_sub;
	assign alu_op[ 2] = inst_slt  | inst_slti;
	assign alu_op[ 3] = inst_sltu | inst_sltiu;
	assign alu_op[ 4] = inst_and  | inst_andi;
	assign alu_op[ 5] = inst_nor;
	assign alu_op[ 6] = inst_or   | inst_ori;
	assign alu_op[ 7] = inst_xor  | inst_xori;
	assign alu_op[ 8] = inst_sll  | inst_sllv;
	assign alu_op[ 9] = inst_srl  | inst_srlv;
	assign alu_op[10] = inst_sra  | inst_srav;
	assign alu_op[11] = inst_lui;

	assign mem_op[0]  = inst_lb;
	assign mem_op[1]  = inst_lbu;
	assign mem_op[2]  = inst_lh;
	assign mem_op[3]  = inst_lhu;
	assign mem_op[4]  = inst_lw;
	assign mem_op[5]  = inst_sb;
	assign mem_op[6]  = inst_sh;
	assign mem_op[7]  = inst_sw;
	assign mem_op[8]  = inst_lwl;
	assign mem_op[9]  = inst_lwr;
	assign mem_op[10] = inst_swl;
	assign mem_op[11] = inst_swr;

//transfer info to EX stage
	assign id_pc_next 		= id_pc_i;
	assign id_ren1_o		= inst_add | inst_addi | inst_addu | inst_addiu | inst_sub | inst_subu
							| inst_slt | inst_slti | inst_sltu | inst_sltiu | inst_div | inst_divu
							| inst_mult| inst_multu| inst_and  | inst_andi  | inst_nor | inst_or
							| inst_ori | inst_xor  | inst_xori | inst_sllv  | inst_srav| inst_srlv| inst_beq
							| inst_bne | inst_bgez | inst_bgtz | inst_blez  | inst_bltz| inst_bgezal
							| inst_bltzal|inst_jr  | inst_jalr | inst_mthi  | inst_mtlo
							| inst_lw  | inst_lh   | inst_lhu  | inst_lb 	| inst_lbu 
							| inst_sw  | inst_sh   | inst_sb   | inst_swl   | inst_swr | inst_mul  ;

	assign id_ren2_o		= inst_add | inst_addu | inst_sub  | inst_subu  | inst_sra  | inst_sll
							| inst_slt | inst_sltu | inst_div  | inst_divu  | inst_srl
							| inst_mult| inst_multu| inst_and  | inst_nor   | inst_or
							| inst_sllv| inst_srav | inst_srlv | inst_beq	| inst_xor   |
							| inst_bne | inst_sb   | inst_sh   | inst_sw    | inst_swl   | inst_swr
							| inst_mtc0| inst_mul ;

 	assign id_wren_next 	= id_flush_i ? 0 : {4{~mul_div & ~inst_beq & ~inst_bne & ~inst_bgez & 
 							  ~inst_bgtz & ~inst_blez & ~inst_bltz & ~inst_j &
 							  ~inst_mthi & ~inst_mtlo & ~inst_break & ~inst_syscall &
 							  ~inst_sw   & ~inst_sh   & ~inst_sb & ~inst_eret & ~inst_mtc0 & ~inst_swl & ~inst_swr}};
 	assign id_rtvalue_next  = id_flush_i ? 0 : id_reg2data_i;						  

 	assign id_aluop_next	= id_flush_i ? 0 : alu_op;
 	assign id_memop_next	= id_flush_i ? 0 : mem_op;

	assign src1_is_sa   	= inst_sll   | inst_srl   | inst_sra;
	assign src1_is_pc   	= inst_jal 	 | inst_jalr  | inst_bgezal| inst_bltzal;
	assign src2_is_imm_s  	= inst_addi  | inst_addiu | inst_slti  | inst_sltiu | inst_lb  | inst_lbu  
							| inst_lh    | inst_lhu   | inst_lw    | inst_sw    | inst_sh  | inst_sb | inst_lwl | inst_lwr | inst_swl | inst_swr; 
	assign src2_is_imm_u	= inst_andi  | inst_lui   | inst_ori   | inst_xori  ;
	assign src2_is_8    	= inst_jal 	 | inst_jalr  | inst_bgezal| inst_bltzal;


	//to next stage
	assign id_opr1_next 	= id_flush_i 	  ? 0 : 
							  src1_is_sa 	  ? sa_ext 	   :
						  	  src1_is_pc 	  ? id_pc_next  :
						  	  id_reg1data_i;

	assign id_opr2_next 	= id_flush_i 	  ? 0 : 
							  src2_is_imm_s	  ? sign_ext   :
							  src2_is_imm_u	  ? zero_ext   :
						      src2_is_8   	  ? 32'd8  	   :
						      id_reg2data_i;

	assign id_waddr_next 	= id_flush_i 	  	  ? 0 		   : 
							  waddr_is_31 	  	  ? 5'd31 	   :
						      waddr_is_rt	  	  ? rt 		   :
						      rd;

	assign id_offset_next	= id_flush_i ? 0 : sign_ext;

	assign id_inslot_next   = id_flush_i ? 0 : id_inslot_i;
	assign id_inst_next 	= id_flush_i ? 0 : id_inst;

	assign id_mduinst_next  = inst_mult | inst_multu | inst_div | inst_divu | inst_mthi | inst_mtlo | inst_mul;
	assign id_divinst_next  = inst_div  | inst_divu;
	assign id_mduop_next    = {inst_mul,inst_mtlo,inst_mthi ,inst_mflo,inst_mfhi,inst_divu,inst_div,inst_multu,inst_mult};
	assign id_c0wen_next 	= inst_mtc0;
	assign id_c0ren_next 	= inst_mfc0;
	assign id_c0addr_next 	= {id_inst_i[15:11],id_inst_i[2:0]};
	assign id_pcvalid_next  = id_flush_i ? 0 : id_pcvalid_i;
	assign id_inst_wb_nofwd_next = id_flush_i ? 0 : inst_mfhi | inst_mflo | inst_mul;
	assign id_intr_dis_next = inst_div | inst_divu | (|mem_op);

	//for branch outputs
	wire [31: 0] j_target;	//j and jal
    wire [31: 0] b_target;	//branch target

    wire LZ;     // Less Than Zero
    wire GEZ;    // Greater Than or Equal to Zero
    wire LEZ;    // Less Than or Equal to Zero
    wire GZ;     // Greater Than Zero
    wire EQ;     // Equal
    wire NEQ;    // Not Equal

    wire [31: 0] 	branch_opr1;
	wire [31: 0] 	branch_opr2;
	
    assign j_target  		= {pcp4[31:28], j_offset, 2'b00};
    assign b_target  		= pcp4 + {sign_ext[29: 0], 2'b00};

    wire inst_branch_b;		//è½¬ç§»åœ°å€ä¸ºb_target
    wire inst_branch_j;		//è½¬ç§»åœ°å€ä¸ºj_target
    wire inst_branch_rs;	//è½¬ç§»åœ°å€ä¸ºrs
    assign inst_branch_b	= inst_beq | inst_bne | inst_bgez | inst_bgtz | inst_blez | inst_bltz 
    						| inst_bgezal | inst_bltzal ;
    assign inst_branch_j	= inst_j   | inst_jal;
    assign inst_branch_rs	= inst_jr  | inst_jalr;

    assign id_branch_pc_o   = inst_branch_b ? b_target :
    						  inst_branch_j ? j_target :
    						  branch_opr1;
    assign id_nofwd_next 	= id_flush_i ? 0 : (| mem_op) | inst_mfhi | inst_mflo | inst_mfc0 |inst_mul;


	assign branch_opr1 = raw_data1_i;
	assign branch_opr2 = raw_data2_i;
    assign LZ     = branch_opr1[31];               
    assign GEZ    = ~LZ;                      
    assign LEZ    = (LZ || (branch_opr1 == 0));    
    assign GZ     = ~LEZ;                    
    assign EQ     = (branch_opr1 ^ branch_opr2) == 0;   
    assign NEQ    = ~EQ;                     

    assign id_branch_en_o	= ((inst_beq & EQ) | (inst_bne & NEQ) | (inst_bgez & GEZ) | (inst_bgtz & GZ) 
    						| (inst_blez & LEZ) | (inst_bltz & LZ) | (inst_bgezal & GEZ) | (inst_bltzal & LZ)
    						| inst_j | inst_jal | inst_jr | inst_jalr);
    assign id_next_inslot_o = (inst_beq | inst_bne | inst_bgez | inst_bgtz | inst_blez | inst_bltz 
    						| inst_bgezal | inst_bltzal | inst_j   | inst_jal | inst_jr  | inst_jalr);

	assign en 				= ~ id_stall_i;

//to avoid the critical path of ex bypass to id branch to pc
assign id_is_branch_o = inst_beq | inst_bne | inst_bgez | inst_bgtz | inst_blez | inst_bltz 
								 | inst_bgezal | inst_bltzal | inst_jr | inst_jalr;
assign id_valid_o = en & ~id_flush_i;

//DFFREs
DFFRE #(.WIDTH(32))			opr1_next			(.d(id_opr1_next), .q(id_opr1_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))			opr2_next			(.d(id_opr2_next), .q(id_opr2_o), .en(en), .clk(clk), .rst_n(rst_n));


DFFRE #(.WIDTH(32))			offset_next			(.d(id_offset_next), .q(id_offset_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))			pc_next				(.d(id_pc_next), .q(id_pc_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(4))			wren_next			(.d(id_wren_next), .q(id_wren_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(5))			waddr_next			(.d(id_waddr_next), .q(id_waddr_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))			inslot_next			(.d(id_inslot_next), .q(id_inslot_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))			rtvalue_next		(.d(id_rtvalue_next), .q(id_rtvalue_o), .en(en), .clk(clk), .rst_n(rst_n));


DFFRE #(.WIDTH(32))			inst_next			(.d(id_inst_next), .q(id_inst_o), .en(en), .clk(clk), .rst_n(rst_n));

DFFRE #(.WIDTH(`AOP_W))		aluop_next			(.d(id_aluop_next), .q(id_aluop_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(`MDOP_W))	mduop_next			(.d(id_mduop_next), .q(id_mduop_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))			mduinst_next		(.d(id_mduinst_next), .q(id_mduinst_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))			divinst_next		(.d(id_divinst_next), .q(id_divinst_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(`MMOP_W))	memop_next			(.d(id_memop_next), .q(id_memop_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(`TOP_W))		tlbop_next			(.d(id_tlbop_next), .q(id_tlbop_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(`COP_W))		cacheop_next		(.d(id_cacheop_next), .q(id_cacheop_o), .en(en), .clk(clk), .rst_n(rst_n));

DFFRE #(.WIDTH(1))			c0wen_next			(.d(id_c0wen_next), .q(id_c0wen_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))			c0ren_next			(.d(id_c0ren_next), .q(id_c0ren_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(8))			c0addr_next			(.d(id_c0addr_next), .q(id_c0addr_o), .en(en), .clk(clk), .rst_n(rst_n));

DFFRE #(.WIDTH(1))			nofwd_next			(.d(id_nofwd_next), .q(id_nofwd_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(`ExcE_W))	excs_next			(.d(id_excs_next), .q(id_excs_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))			has_exc_next		(.d(id_has_exc_next), .q(id_has_exc_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))			ov_inst_next		(.d(id_ov_inst_next), .q(id_ov_inst_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))			pcvalid_next		(.d(id_pcvalid_next), .q(id_pcvalid_o), .en(en), .clk(clk), .rst_n(rst_n));

DFFRE #(.WIDTH(1))			inst_wb_nofwd_next	(.d(id_inst_wb_nofwd_next), .q(id_inst_wb_nofwd_o), .en(en), .clk(clk), .rst_n(rst_n));

DFFRE #(.WIDTH(1))			intr_dis_next		(.d(id_intr_dis_next), .q(id_intr_dis_o), .en(en), .clk(clk), .rst_n(rst_n));

//å°šæœªå®žçŽ°

assign 				id_tlbop_next = 0;
assign 				id_cacheop_next = 0;
assign   			id_stallreq_o = 0;

endmodule