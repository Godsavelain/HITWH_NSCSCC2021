`include "../defines.v"

module mdu_s1
(
	input wire 			clk,
	input wire 			rst_n,
	input wire 			mdus1_en,
	input wire [31: 0] 	mdu_opr1,
	input wire [31: 0] 	mdu_opr2,
	input wire [`MDOP] 	s1_mduop_i,
	input wire 			is_signed,

	input wire [31: 0] 	s1_whi_i,
	input wire [31: 0] 	s1_wlo_i,

	//from control
	input wire			s1_stall_i,
	input wire			s1_flush_i,

	output wire [31: 0] s1_AC_o,
	output wire [31: 0] s1_AD_o,
	output wire [31: 0] s1_CB_o,
	output wire [31: 0] s1_BD_o,
	output wire [`MDOP] s1_mduop_o,
	output wire			s1_res_sign_o,
	output wire 		s1_valid_o,
	output wire [31: 0]	s1_opr1_o,
	output wire [31: 0]	s1_opr2_o,

	output wire [31: 0] s1_whi_o,
	output wire [31: 0] s1_wlo_o,

	output wire 		s1_is_active,
	output wire 		s1_is_div
//	output wire 		s1_allow_in//to EX
);

 wire en;
 //assign en = mdus1_en && (!s1_stall_i);
assign en = ~s1_stall_i;
 wire [31: 0] opr1;
 wire [31: 0] opr2;

 wire opr1_sign;
 wire opr2_sign;
 wire result_sign;

 assign opr1_sign = mdu_opr1[31];
 assign opr2_sign = mdu_opr2[31];

 assign opr1  = (is_signed & opr1_sign)? ~mdu_opr1 + 1: mdu_opr1;
 assign opr2  = (is_signed & opr2_sign)? ~mdu_opr2 + 1: mdu_opr2;

 wire [15: 0] A;
 wire [15: 0] B;
 wire [15: 0] C;
 wire [15: 0] D;

 wire  [31: 0] BD;
 wire  [31: 0] AC;
 wire  [31: 0] AD;
 wire  [31: 0] CB;

 assign A  = opr1[31:16];
 assign B  = opr1[15: 0];
 assign C  = opr2[31:16];
 assign D  = opr2[15: 0];

 assign BD = B * D;
 assign AC = A * C;
 assign AD = A * D;
 assign CB = C * B;
 assign result_sign = is_signed & (opr1_sign ^ opr2_sign);

 assign s1_is_active = mdus1_en;
 assign s1_is_div	 = s1_mduop_i[2] | s1_mduop_i[3];

 wire [31: 0] s1_AC_next;
 wire [31: 0] s1_AD_next;
 wire [31: 0] s1_CB_next;
 wire [31: 0] s1_BD_next;

 wire		  s1_res_sign_next;
 wire 		  s1_valid_next;

 wire [31: 0] s1_whi_next;
 wire [31: 0] s1_wlo_next;
 wire [31: 0] s1_opr1_next;
 wire [31: 0] s1_opr2_next;
 wire  		  s1_whien_next;
 wire  		  s1_wloen_next;
 wire [`MDOP] s1_mduop_next;


 assign	s1_AC_next 	  = s1_flush_i ? 0 : AC;
 assign	s1_AD_next    = s1_flush_i ? 0 : AD;
 assign	s1_CB_next    = s1_flush_i ? 0 : CB;
 assign	s1_BD_next    = s1_flush_i ? 0 : BD;

 assign	s1_res_sign_next  = s1_flush_i ? 0 : result_sign;
 assign	s1_valid_next 	  = s1_flush_i ? 0 : mdus1_en;
 assign	s1_whi_next   	  = s1_flush_i ? 0 : s1_whi_i;
 assign	s1_wlo_next 	  = s1_flush_i ? 0 : s1_wlo_i;
 assign s1_mduop_next	  = s1_flush_i ? 0 : s1_mduop_i;
 assign s1_opr1_next	  = s1_flush_i ? 0 : mdu_opr1;
 assign s1_opr2_next	  = s1_flush_i ? 0 : mdu_opr2;

 DFFRE #(.WIDTH(32))		AC_next		(.d(s1_AC_next), .q(s1_AC_o), .en(en), .clk(clk), .rst_n(rst_n));
 DFFRE #(.WIDTH(32))		AD_next		(.d(s1_AD_next), .q(s1_AD_o), .en(en), .clk(clk), .rst_n(rst_n));    
 DFFRE #(.WIDTH(32))		CB_next		(.d(s1_CB_next), .q(s1_CB_o), .en(en), .clk(clk), .rst_n(rst_n));  
 DFFRE #(.WIDTH(32))		BD_next		(.d(s1_BD_next), .q(s1_BD_o), .en(en), .clk(clk), .rst_n(rst_n));  
 DFFRE #(.WIDTH(32))		opr1_next	(.d(s1_opr1_next), .q(s1_opr1_o), .en(en), .clk(clk), .rst_n(rst_n)); 
 DFFRE #(.WIDTH(32))		opr2_next	(.d(s1_opr2_next), .q(s1_opr2_o), .en(en), .clk(clk), .rst_n(rst_n)); 

 DFFRE #(.WIDTH(1))		    res_sign_next		(.d(s1_res_sign_next), .q(s1_res_sign_o), .en(en), .clk(clk), .rst_n(rst_n));  
 DFFRE #(.WIDTH(1))		    valid_next			(.d(s1_valid_next), .q(s1_valid_o), .en(en), .clk(clk), .rst_n(rst_n));  
 DFFRE #(.WIDTH(32))		whi_next			(.d(s1_whi_next), .q(s1_whi_o), .en(en), .clk(clk), .rst_n(rst_n));  
 DFFRE #(.WIDTH(32))		wlo_next			(.d(s1_wlo_next), .q(s1_wlo_o), .en(en), .clk(clk), .rst_n(rst_n));     
 DFFRE #(.WIDTH(`MDOP_W))	mduop_next			(.d(s1_mduop_next), .q(s1_mduop_o), .en(en), .clk(clk), .rst_n(rst_n));  
endmodule