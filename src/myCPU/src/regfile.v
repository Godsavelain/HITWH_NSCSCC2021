`include "../defines.v"

module regfile
(
	input 	wire		 	clk,
    input   wire            rst_n,
	//for read
	input	wire 			ren1,
	input	wire 			ren2,
	input 	wire [ 4: 0]	raddr1,
	input 	wire [ 4: 0]	raddr2,
	output 	wire [31: 0]	rdata1,
	output 	wire [31: 0]	rdata2,
	//for write
	input 	wire [ 3: 0]	we,
	input 	wire [ 4: 0]	waddr,
	input	wire [31: 0]	wdata,
	//for bypass
	input 	wire [ 3: 0]	ex_wen,
	input	wire [ 4: 0]	ex_waddr,
	input 	wire [31: 0]	ex_wdata,
	input 	wire [ 3: 0]	mem_wen,
	input	wire [ 4: 0]	mem_waddr,
	input 	wire [31: 0]	mem_wdata,

	//指令相关等需要暂停两周期
	input	wire 			ex_nofwd,
	input	wire 			mem_nofwd,
	output  wire 			stallreq,

    //当ID为branch指令且存在数据冲突时暂停一拍
    input   wire            id_is_branch,
    output  wire [31: 0]    ex_data_to_id_o,
    output  wire            id_ex_res_as1_o,
    output  wire            id_ex_res_as2_o,

    //分割信号
    output  wire [31: 0]    raw_data1_o,  
    output  wire [31: 0]    raw_data2_o
);

	reg [31: 0] GPR [31: 0];

	integer i;
    initial for (i = 0; i < 32; i = i + 1) GPR[i] = 0;

    wire   r1_ex_haz;
    wire   r1_mem_haz;
    wire   r1_wb_haz1;
    wire   r1_wb_haz2;
    wire   r1_wb_haz3;
    wire   r1_wb_haz4;
    wire   r1_wb_haz;

    wire   r2_ex_haz;
    wire   r2_mem_haz;
    wire   r2_wb_haz1; 
    wire   r2_wb_haz2;
    wire   r2_wb_haz3;
    wire   r2_wb_haz4;
    wire   r2_wb_haz;

    wire   branch_stall;
    wire   id_ex_res_as1_next;
    wire   id_ex_res_as2_next;
    wire [31: 0] ex_data_to_id_next;

    always @(posedge clk) begin
        if(we[0])  GPR[waddr][ 7: 0] <= wdata[ 7: 0];
        if(we[1])  GPR[waddr][15: 8] <= wdata[15: 8];
        if(we[2])  GPR[waddr][23:16] <= wdata[23:16];
        if(we[3])  GPR[waddr][31:24] <= wdata[31:24];
    end

    assign   r1_ex_haz  = (raddr1 ^ ex_waddr ) == 0 && ex_wen[0] ;
    assign   r1_mem_haz = (raddr1 ^ mem_waddr) == 0 && mem_wen[0];
    assign   r1_wb_haz1 = (raddr1 ^ waddr    ) == 0 && we[0] ;
    assign   r1_wb_haz2 = (raddr1 ^ waddr    ) == 0 && we[1] ;
    assign   r1_wb_haz3 = (raddr1 ^ waddr    ) == 0 && we[2] ;
    assign   r1_wb_haz4 = (raddr1 ^ waddr    ) == 0 && we[3] ;

    assign   r2_ex_haz  = (raddr2 ^ ex_waddr ) == 0 && ex_wen[0] ;
    assign   r2_mem_haz = (raddr2 ^ mem_waddr) == 0 && mem_wen[0];
    assign   r2_wb_haz1 = (raddr2 ^ waddr    ) == 0 && we[0];
    assign   r2_wb_haz2 = (raddr2 ^ waddr    ) == 0 && we[1];
    assign   r2_wb_haz3 = (raddr2 ^ waddr    ) == 0 && we[2];
    assign   r2_wb_haz4 = (raddr2 ^ waddr    ) == 0 && we[3];

    assign   r1_wb_haz  = r1_wb_haz1 | r1_wb_haz2 | r1_wb_haz3 | r1_wb_haz4;
    assign   r2_wb_haz  = r2_wb_haz1 | r2_wb_haz2 | r2_wb_haz3 | r2_wb_haz4;

    wire [31: 0] lrdata1;
    wire [31: 0] lrdata2;
    assign lrdata1[ 7: 0] = r1_wb_haz1 ? wdata[ 7: 0] : GPR[raddr1][ 7: 0];
    assign lrdata1[15: 8] = r1_wb_haz2 ? wdata[15: 8] : GPR[raddr1][15: 8];
    assign lrdata1[23:16] = r1_wb_haz3 ? wdata[23:16] : GPR[raddr1][23:16];
    assign lrdata1[31:24] = r1_wb_haz4 ? wdata[31:24] : GPR[raddr1][31:24];

    assign lrdata2[ 7: 0] = r2_wb_haz1 ? wdata[ 7: 0] : GPR[raddr2][ 7: 0];
    assign lrdata2[15: 8] = r2_wb_haz2 ? wdata[15: 8] : GPR[raddr2][15: 8];
    assign lrdata2[23:16] = r2_wb_haz3 ? wdata[23:16] : GPR[raddr2][23:16];
    assign lrdata2[31:24] = r2_wb_haz4 ? wdata[31:24] : GPR[raddr2][31:24];


//bypass
    assign rdata1 = raddr1 == 0 ? 0         :
                    r1_ex_haz   ? ex_wdata  :
                    r1_mem_haz  ? mem_wdata : 
                    r1_wb_haz   ? lrdata1   :
                    GPR[raddr1];

    assign rdata2 = raddr2 == 0 ? 0         :
                    r2_ex_haz   ? ex_wdata  :
                    r2_mem_haz  ? mem_wdata : 
                    r2_wb_haz   ? lrdata2   :
                    GPR[raddr2];

//沿用CK的设计，当EX段不能产生结果时暂停两周期
    wire   r1_rvalid = ren1 && (raddr1 != 0);
    wire   r2_rvalid = ren2 && (raddr2 != 0);
    wire   ex_haz    = (r1_ex_haz  && r1_rvalid) || (r2_ex_haz  && r2_rvalid);
    wire   mem_haz   = (r1_mem_haz && r1_rvalid) || (r2_mem_haz && r2_rvalid);
    assign stallreq  = (ex_haz     && ex_nofwd ) || (mem_haz    && mem_nofwd) || branch_stall;

    assign branch_stall   = id_is_branch && ex_haz ;


//当ID段为branch且与EX段存在相关时暂停一拍，将旁路数据与控制信号送往ID段，下一周期ID段再根据送入数据进行分支地址计算
    assign ex_data_to_id_next   =   ex_wdata;
    assign id_ex_res_as1_next   =   r1_ex_haz && id_is_branch;
    assign id_ex_res_as2_next   =   r2_ex_haz && id_is_branch;

    assign raw_data1_o          =   r1_mem_haz  ? mem_wdata : 
                                    r1_wb_haz   ? lrdata1   :
                                    GPR[raddr1];
    assign raw_data2_o          =   r2_mem_haz  ? mem_wdata : 
                                    r2_wb_haz   ? lrdata2   :
                                    GPR[raddr2];

    DFFRE #(.WIDTH(1))   ex_bp1_next   (.d(id_ex_res_as1_next), .q(id_ex_res_as1_o), .en(1), .clk(clk), .rst_n(rst_n));
    DFFRE #(.WIDTH(1))   ex_bp2_next   (.d(id_ex_res_as2_next), .q(id_ex_res_as2_o), .en(1), .clk(clk), .rst_n(rst_n));
    DFFRE #(.WIDTH(32))  ex_bpdata_next   (.d(ex_data_to_id_next), .q(ex_data_to_id_o), .en(1), .clk(clk), .rst_n(rst_n)); 
endmodule