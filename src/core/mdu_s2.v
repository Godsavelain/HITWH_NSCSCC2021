`include "../defines.v"

module mdu_s2
(
	input wire 			clk,
	input wire 			rst_n,
	input wire [31: 0]  s2_AC_i,
 	input wire [31: 0]  s2_AD_i,
 	input wire [31: 0]  s2_CB_i,
 	input wire [31: 0]  s2_BD_i,
	input wire [`MDOP] 	s2_mduop_i,
	input wire			s2_res_sign_i,
	input wire 			s2_valid_i,
	input wire			s2_stall_i,
	input wire			s2_flush_i,
//for mthi/mtlo

    input wire [31: 0]  s2_whi_i,//data for mthi
    input wire [31: 0]  s2_wlo_i,//data for mtlo

    input wire [31: 0]  s2_opr1_i,
    input wire [31: 0]  s2_opr2_i,
//from div
    input wire          s2_div_rdy_i,
    input wire [63: 0]  s2_div_data_i,
    input wire          s2_div_ansok_i,
//from divu
    input wire          s2_divu_rdy_i,
    input wire [63: 0]  s2_divu_data_i,
    input wire          s2_divu_ansok_i,
//from s2 last stage
    input wire          s2_div_active,
//to mdu
	output wire [`MDOP]	s2_mduop_o,
	output wire [31: 0]	s2_hi_o,
	output wire [31: 0]	s2_lo_o,
    output wire         s2_is_active,
    output wire         s2_is_div,
    output wire         s2_stall_req,//to mem
    output wire [31: 0] s2_whidata_o,//data for mthi
    output wire [31: 0] s2_wlodata_o,//data for mtlo
    output wire [63: 0] s2_divans_o,
    output wire [63: 0] s2_divuans_o,
//to div
    output wire [31:0]  s2_div_opr1_o,
    output wire [31:0]  s2_div_opr2_o,
    output wire         s2_div_valid_o,

//to divu
    output wire [31:0]  s2_divu_opr1_o,
    output wire [31:0]  s2_divu_opr2_o,
    output wire         s2_divu_valid_o,

//to s2 next stage
    output wire         s2_next_div_active_o
);

    wire [15: 0] tmp_tail;
    wire [33: 0] tmp_middle;
    wire [15: 0] tmp_top;
    wire [ 1: 0] middle_carry = tmp_middle[33:32];

    wire					en;
	assign  en 				= ~ s2_stall_i; 

    assign tmp_tail           = s2_BD_i[15: 0];
    assign tmp_middle    	  = s2_AD_i + s2_CB_i + {s2_AC_i[15: 0], s2_BD_i[31:16]};
    assign tmp_top       	  = s2_AC_i[31:16] + middle_carry;

    wire [63: 0] tmp_result_abs;
    wire [63: 0] tmp_result;

    assign tmp_result_abs     = {tmp_top,tmp_middle[31: 0],tmp_tail};
    assign tmp_result         = s2_res_sign_i? (~tmp_result_abs + 1): tmp_result_abs;

    assign s2_is_active       = s2_valid_i;
    assign s2_is_div          = s2_mduop_i[2] | s2_mduop_i[3];

    wire [31: 0] s2_hi_next;
    wire [31: 0] s2_lo_next;
    wire [`MDOP] s2_mduop_next;
    wire         s2_next_div_active_next;
    wire [31: 0] s2_whidata_next;
    wire [31: 0] s2_wlodata_next;
    wire [63: 0] s2_divans_next;
    wire [63: 0] s2_divuans_next;
    assign  s2_whidata_next         = s2_flush_i ? 0 : s2_whi_i;
    assign  s2_wlodata_next         = s2_flush_i ? 0 : s2_wlo_i;
    assign  s2_mduop_next           = s2_flush_i ? 0 : s2_mduop_i;
    assign  s2_next_div_active_next = s2_div_active ? (!s2_div_ansok_i & !s2_divu_ansok_i) :
                                     (s2_mduop_i[2] & s2_div_rdy_i )|( s2_mduop_i[3] & s2_divu_rdy_i );

    assign  s2_hi_next 		      = s2_flush_i ? 0 : tmp_result[63:32];
    assign  s2_lo_next 		      = s2_flush_i ? 0 : tmp_result[31: 0];
    //from div and divu
    assign  s2_divans_next        = s2_flush_i ? 0 : s2_div_data_i;
    assign  s2_divuans_next       = s2_flush_i ? 0 : s2_divu_data_i;
    //to div and divu
    assign  s2_div_opr1_o         = s2_opr1_i;
    assign  s2_div_opr2_o         = s2_opr2_i;
    assign  s2_div_valid_o        = s2_mduop_i[2] & !s2_div_active ;

    assign  s2_divu_opr1_o        = s2_opr1_i;
    assign  s2_divu_opr2_o        = s2_opr2_i;
    assign  s2_divu_valid_o       = s2_mduop_i[3] & !s2_div_active ;


    assign  s2_stall_req          = (s2_mduop_i[2] & !s2_div_ansok_i) | (s2_mduop_i[3] & !s2_divu_ansok_i);
    //当前设计应该不需要考虑开始计算时ready为0的情况，因为严格确保一条除法指令执行完毕后才载入下一条

    DFFRE #(.WIDTH(32))		hi_next			(.d(s2_hi_next), .q(s2_hi_o), .en(en), .clk(clk), .rst_n(rst_n));
    DFFRE #(.WIDTH(32))		lo_next			(.d(s2_lo_next), .q(s2_lo_o), .en(en), .clk(clk), .rst_n(rst_n));
    DFFRE #(.WIDTH(`MDOP_W))mduop_next      (.d(s2_mduop_next), .q(s2_mduop_o), .en(en), .clk(clk), .rst_n(rst_n));
    DFFRE #(.WIDTH(1))      div_active_next (.d(s2_next_div_active_next), .q(s2_next_div_active_o), .en(en), .clk(clk), .rst_n(rst_n));
    DFFRE #(.WIDTH(32))     whidata_next    (.d(s2_whidata_next), .q(s2_whidata_o), .en(en), .clk(clk), .rst_n(rst_n));
    DFFRE #(.WIDTH(32))     wlodata_next    (.d(s2_wlodata_next), .q(s2_wlodata_o), .en(en), .clk(clk), .rst_n(rst_n));
    DFFRE #(.WIDTH(64))     divans_next     (.d(s2_divans_next), .q(s2_divans_o), .en(en), .clk(clk), .rst_n(rst_n));
    DFFRE #(.WIDTH(64))     divuans_next    (.d(s2_divuans_next), .q(s2_divuans_o), .en(en), .clk(clk), .rst_n(rst_n));
endmodule