`include "../defines.v"

module regfile
(
	input 	wire		 	clk,
	//for read
	input	wire 			ren1,
	input	wire 			ren2,
	input 	wire [ 4: 0]	raddr1,
	input 	wire [ 4: 0]	raddr2,
	output 	wire [31: 0]	rdata1,
	output 	wire [31: 0]	rdata2,
	//for write
	input 	wire			we,
	input 	wire			waddr,
	input	wire [31: 0]	wdata,
	//for bypass
	input 	wire 			ex_wen,
	input	wire [31: 0]	ex_waddr,
	input 	wire [31: 0]	ex_wdata,
	input 	wire 			mem_wen,
	input	wire [31: 0]	mem_waddr,
	input 	wire [31: 0]	mem_wdata,

	//指令相关等需要暂停两周期
	input	wire 			ex_nofwd,
	input	wire 			mem_nofwd,
	output  wire 			stallreq
);

	reg [31: 0] GPR [31: 0];

	integer i;
    initial for (i = 0; i < 32; i = i + 1) GPR[i] = 0;

    wire   r1_ex_haz;
    wire   r1_mem_haz;
    wire   r1_wb_haz;

    wire   r2_ex_haz;
    wire   r2_mem_haz;
    wire   r2_wb_haz; 

    always @(posedge clk) begin
        if(we)  GPR[waddr] <= wdata;
    end

    assign   r1_ex_haz  = (raddr1 ^ ex_waddr ) == 0 && ex_wen ;
    assign   r1_mem_haz = (raddr1 ^ mem_waddr) == 0 && mem_wen;
    assign   r1_wb_haz  = (raddr1 ^ waddr     ) == 0 && we;

    assign   r2_ex_haz  = (raddr2 ^ ex_waddr ) == 0 && ex_wen ;
    assign   r2_mem_haz = (raddr2 ^ mem_waddr) == 0 && mem_wen;
    assign   r2_wb_haz  = (raddr2 ^ waddr     ) == 0 && we;

//bypass
    assign rdata1 = raddr1 == 0 ? 0          :
                    r1_ex_haz   ? ex_wdata  :
                    r1_mem_haz  ? mem_wdata : 
                    r1_wb_haz   ? wdata      :
                    GPR[raddr1];

    assign rdata2 = raddr2 == 0 ? 0          :
                    r2_ex_haz   ? ex_wdata  :
                    r2_mem_haz  ? mem_wdata : 
                    r2_wb_haz   ? wdata      :
                    GPR[raddr2];

//沿用CK的设计，当EX段不能产生结果时暂停两周期
    wire   r1_rvalid = ren1 && (raddr1 != 0);
    wire   r2_rvalid = ren2 && (raddr2 != 0);
    wire   ex_haz    = (r1_ex_haz  && r1_rvalid) || (r2_ex_haz  && r2_rvalid);
    wire   mem_haz   = (r1_mem_haz && r1_rvalid) || (r2_mem_haz && r2_rvalid);
    assign stallreq  = (ex_haz     && ex_nofwd ) || (mem_haz    && mem_nofwd);

endmodule