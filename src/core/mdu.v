`include "../defines.v"

module mdu
(
	input wire 			clk,
	input wire 			rst_n,
	input wire [`MDOP] 	mduop_i,
	input wire 			mdu_s1_stall_i,
	input wire 			mdu_s1_flush_i,
	input wire 			mdu_s2_stall_i,
	input wire 			mdu_s2_flush_i,
	input wire [31: 0]	mdu_opr1_in,
	input wire [31: 0]	mdu_opr2_in,
	input wire [31: 0]	mdu_whi_in,
	input wire [31: 0]	mdu_wlo_in,

	//from ex DFF Q
	

	//from hilo
	input wire [31: 0]  mdu_hi_i,
	input wire [31: 0]  mdu_lo_i,

	//to ex
	output wire 			is_active,
	output wire 			mdu_div_active,
	//to wb
	output wire 			hi_wen,
	output wire [31: 0]		hi_o,
	output wire 			lo_wen,
	output wire [31: 0]		lo_o,
	output wire 			inst_mfhi_o,
	output wire 			inst_mflo_o,
	//to mem
	output wire 			mdu_s2_stallreq_o
);

//to s1
	wire 			mdus1_en;
	wire [31: 0] 	mdu_opr1;
	wire [31: 0] 	mdu_opr2;
	wire 			is_signed;
	wire			s1_stall_i;
	wire			s1_flush_i;

//from s1
	wire 			s1_is_div;
	wire 			s1_active;

//to s2
    wire [31: 0] 	s1_AC;
    wire [31: 0] 	s1_AD;
    wire [31: 0] 	s1_CB;
    wire [31: 0] 	s1_BD;
    wire [`MDOP]	s2_mduop_i;
    wire [31: 0]	s2_opr1_i;
    wire [31: 0]	s2_opr2_i;
	wire			s2_res_sign_i;
	wire 			s2_valid_i;
	wire			s2_stall_i;
	wire			s2_flush_i;

	wire [31: 0]	s2_whi_i;
	wire [31: 0]	s2_wlo_i;

//from s2
	wire 			s2_active;
	wire [`MDOP]	s2_mduop_o;
	wire [31: 0]	s2_hi_o;
	wire [31: 0]	s2_lo_o;
	wire 			s2_is_div;
	wire 		 	div_active;
	wire [31: 0] 	s2_whidata_o;
	wire [31: 0] 	s2_wlodata_o;
	wire [63: 0]	s2_divans;
	wire [63: 0]	s2_divuans;

	wire 		 	s2_div_active;


//to div and divu 
	wire [31: 0] 	div_opr1;//除数
	wire [31: 0] 	div_opr2;
	wire 		 	div_ready;
	wire 		 	div_ready1;
	wire 		 	div_ready2;
	wire 		 	div_valid;

	wire [63: 0] 	div_ans;
	wire 		 	div_ok;

	wire [31: 0] 	divu_opr1;//除数
	wire [31: 0] 	divu_opr2;
	wire 		 	divu_ready;
	wire 		 	divu_ready1;
	wire 		 	divu_ready2;
	wire 		 	divu_valid;

	wire [63: 0] 	divu_ans;
	wire 		 	divu_ok;


	wire 			inst_mult;	
	wire 			inst_multu;
	wire 			inst_div;
	wire 			inst_divu;
	wire 			inst_mfhi;
	wire 			inst_mflo;
	wire 			inst_mthi;
	wire 			inst_mtlo;

assign inst_mult  = s2_mduop_o[0];
assign inst_multu = s2_mduop_o[1];
assign inst_div   = s2_mduop_o[2];
assign inst_divu  = s2_mduop_o[3];
assign inst_mfhi  = s2_mduop_o[4];
assign inst_mflo  = s2_mduop_o[5];
assign inst_mthi  = s2_mduop_o[6];
assign inst_mtlo  = s2_mduop_o[7];

//assign div_active = s2_is_div | s1_is_div;
//assign is_active = s1_active | s2_active | div_active ;
assign div_active = s2_is_div;
assign is_active = s2_active | div_active ;
assign mdu_div_active =  div_active;

//0:MULT 1:MULTU 2:DIV 3:DIVU 4:MFHI 5:MFLO 6:MTHI 7:MTLO


assign mdus1_en  = |mduop_i;
assign is_signed = mduop_i[0] | mduop_i[2] ;

assign hi_wen 	 = inst_mult | inst_multu | inst_div | inst_divu | inst_mthi | inst_mtlo;

assign inst_mfhi_o = inst_mfhi;
assign inst_mflo_o = inst_mflo;

assign hi_wen 	 = inst_mult | inst_multu | inst_div | inst_divu | inst_mthi ;
assign lo_wen 	 = inst_mult | inst_multu | inst_div | inst_divu | inst_mtlo;;
assign hi_o 	 = ({32{inst_mult | inst_multu}} 		& s2_hi_o 	)
				  |({32{inst_div}} 						& s2_divans [31: 0]	)
				  |({32{inst_divu}} 					& s2_divuans[31: 0]	)
				  |({32{inst_mthi}} 					& s2_whidata_o		)
				  |({32{inst_mfhi}}						& mdu_hi_i 			);
assign lo_o 	 = ({32{inst_mult | inst_multu}} 		& s2_lo_o 			)
				  |({32{inst_div}} 						& s2_divans [63:32]	)
				  |({32{inst_divu}} 					& s2_divuans[63:32]	)
				  |({32{inst_mtlo}} 					& s2_wlodata_o		)
				  |({32{inst_mflo}}						& mdu_lo_i 			);
assign div_ready = div_ready1 & div_ready2;
assign divu_ready = divu_ready1 & divu_ready2;
mdu_s1 S1
(
	.clk			(clk),
	.rst_n			(rst_n),
	.mdus1_en		(mdus1_en),
	.mdu_opr1		(mdu_opr1_in),
	.mdu_opr2		(mdu_opr2_in),
	.s1_mduop_i 	(mduop_i),
	.is_signed		(is_signed),

	.s1_stall_i 	(mdu_s1_stall_i),
	.s1_flush_i 	(mdu_s1_flush_i),

	.s1_whi_i 		(mdu_whi_in),
	.s1_wlo_i 		(mdu_wlo_in),

 	.s1_AC_o 		(s1_AC),
 	.s1_AD_o 		(s1_AD),
 	.s1_CB_o		(s1_CB),
 	.s1_BD_o		(s1_BD),
 	.s1_mduop_o 	(s2_mduop_i),
	.s1_res_sign_o 	(s2_res_sign_i),
	.s1_valid_o 	(s2_valid_i),
	.s1_opr1_o 		(s2_opr1_i),
	.s1_opr2_o 		(s2_opr2_i),
	.s1_is_active	(s1_active),
	.s1_is_div 		(s1_is_div),

	.s1_whi_o 		(s2_whi_i),
	.s1_wlo_o 		(s2_wlo_i)


);


mdu_s2 S2
(
	.clk 			(clk),
	.rst_n			(rst_n),
	.s2_AC_i		(s1_AC),
 	.s2_AD_i 		(s1_AD),
 	.s2_CB_i		(s1_CB),
 	.s2_BD_i		(s1_BD),
 	.s2_mduop_i		(s2_mduop_i),

	.s2_res_sign_i 	(s2_res_sign_i),
	.s2_valid_i 	(s2_valid_i),
	.s2_stall_i 	(mdu_s2_stall_i),
	.s2_flush_i 	(mdu_s2_flush_i),

    .s2_whi_i   	(s2_whi_i),
    .s2_wlo_i 		(s2_wlo_i),
    .s2_opr1_i 		(s2_opr1_i),
    .s2_opr2_i 		(s2_opr2_i),

	.s2_div_rdy_i 	(div_ready),
	.s2_div_data_i  (div_ans),
	.s2_div_ansok_i (div_ok),

	.s2_divu_rdy_i 	(divu_ready),
	.s2_divu_data_i (divu_ans),
	.s2_divu_ansok_i(divu_ok),

	.s2_div_active  (s2_div_active),

	.s2_div_opr1_o	(div_opr1),
	.s2_div_opr2_o	(div_opr2),
	.s2_div_valid_o (div_valid),

	.s2_divu_opr1_o	(divu_opr1),
	.s2_divu_opr2_o	(divu_opr2),
	.s2_divu_valid_o(divu_valid),

	.s2_mduop_o 	(s2_mduop_o),
	.s2_hi_o 		(s2_hi_o),
	.s2_lo_o 		(s2_lo_o),
	.s2_is_active	(s2_active),
	.s2_is_div 		(s2_is_div),
	.s2_stall_req 	(mdu_s2_stallreq_o),
	.s2_whidata_o	(s2_whidata_o),
	.s2_wlodata_o	(s2_wlodata_o),
	.s2_divans_o 	(s2_divans),
	.s2_divuans_o 	(s2_divuans),

	.s2_next_div_active_o (s2_div_active)
);

mydiv DIV
(
	.aclk 					(clk),
	.s_axis_divisor_tdata  	(div_opr2),
	.s_axis_divisor_tready 	(div_ready2),
	.s_axis_divisor_tvalid  (div_valid),

	.s_axis_dividend_tdata  (div_opr1),
	.s_axis_dividend_tready (div_ready1),
	.s_axis_dividend_tvalid (div_valid),

	.m_axis_dout_tdata 		(div_ans),
	.m_axis_dout_tvalid 	(div_ok)
);

mydivu DIVU
(
	.aclk 					(clk),
	.s_axis_divisor_tdata  	(divu_opr2),
	.s_axis_divisor_tready 	(divu_ready2),
	.s_axis_divisor_tvalid  (divu_valid),

	.s_axis_dividend_tdata  (divu_opr1),
	.s_axis_dividend_tready (divu_ready1),
	.s_axis_dividend_tvalid (divu_valid),

	.m_axis_dout_tdata 		(divu_ans),
	.m_axis_dout_tvalid 	(divu_ok)
);

endmodule