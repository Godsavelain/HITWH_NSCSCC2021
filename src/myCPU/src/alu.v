`include "../defines.v"

module alu
(
    input wire  [31: 0]			opr1,
    input wire  [31: 0]			opr2,
	input wire  [`AOP]			alu_op,

    output wire [31: 0]			alu_res,
	output wire 				ov
);

//operations
    wire 	op_add;		
	wire 	op_sub;
	wire 	op_slt;// signed set less than
	wire 	op_sltu;
	wire 	op_and;
	wire 	op_nor;
	wire 	op_or;
	wire 	op_xor;
	wire 	op_sll;// logic shift left
	wire 	op_srl;// logic shift right
	wire 	op_sra;// arithmatic shift right
	wire 	op_lui;// load imm to high bits

	assign   		op_add  = alu_op[ 0];
	assign   		op_sub  = alu_op[ 1];
	assign   		op_slt  = alu_op[ 2];
	assign   		op_sltu = alu_op[ 3];
	assign   		op_and  = alu_op[ 4];
	assign   		op_nor  = alu_op[ 5];
	assign   		op_or   = alu_op[ 6];
	assign   		op_xor  = alu_op[ 7];
	assign   		op_sll  = alu_op[ 8];
	assign   		op_srl  = alu_op[ 9];
	assign   		op_sra  = alu_op[10];
	assign   		op_lui  = alu_op[11];

    wire [31: 0]	add_sub_result;
	wire [31: 0]	slt_result;
	wire [31: 0]	sltu_result;
	wire [31: 0]	and_result;
	wire [31: 0]	nor_result;
	wire [31: 0]	or_result;
	wire [31: 0]	xor_result;
	wire [31: 0]	sll_result;
	wire [31: 0]	srl_result;
	wire [31: 0]	sra_result;
	wire [31: 0]	lui_result;

	//logic
	assign 			and_result = opr1 & opr2;
	assign 			or_result  = opr1 | opr2;
	assign 			nor_result = ~or_result;
	assign 			xor_result = opr1 ^ opr2;

	assign 			lui_result = {opr2[15: 0] , 16'b0};

	//add or sub
	wire [31: 0]	adder_a;
	wire [31: 0]	adder_b;
	wire 			cin;
	wire 			cout;
	wire [31: 0]	add_res;

	assign cin 		= (op_sub | op_slt | op_sltu) ?		1'b1  	:	1'b0;
	assign adder_b  = (op_sub | op_slt | op_sltu) ?		~opr2 	:	opr2;
	assign adder_a	= opr1;
	assign {cout , add_res}	= adder_a + adder_b + cin;

    assign add_sub_result		=	add_res;

	assign slt_result [31: 1] 	= 	31'b0;
	assign slt_result [0]		=	(opr1[31] & ~opr2[31])
								|	((opr1[31] ~^ opr2[31]) & add_res[31]);

	assign sltu_result [31: 1] 	= 	31'b0;
	assign sltu_result [0]		=   ~cout;

	//shift
	assign sll_result			=	opr2 << opr1 [ 4: 0];
	assign srl_result			=	opr2 >> opr1 [ 4: 0];
	assign sra_result			=	($signed(opr2)) >>> opr1 [ 4: 0];

//choose the output
    assign alu_res 				= 	({32{op_add | op_sub}} & add_sub_result)
								|	({32{op_slt}}		   & slt_result)
								|	({32{op_sltu}}		   & sltu_result)
								|	({32{op_and}}		   & and_result)
								|	({32{op_nor}}		   & nor_result)
								|	({32{op_or}}		   & or_result)
								|	({32{op_xor}}		   & xor_result)
								|	({32{op_sll}}		   & sll_result)
								|	({32{op_srl}}		   & srl_result)
								|	({32{op_sra}}		   & sra_result)
								|	({32{op_lui}}		   & lui_result);

//overflow
	assign 	s_opr1			= adder_a[31];
	assign 	s_opr2			= adder_b[31];
	assign 	s_res			= add_res[31];
	assign  ov				= (~(s_opr1^s_opr2)) & (s_opr2 ^ s_res);


endmodule