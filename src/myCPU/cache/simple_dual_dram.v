`include "defines_cache.v"

module simple_dual_dram
(
	input 			 clka,
	input 			 rst_n,
	input   		 ena,
	input   [ 3: 0]	 wea,
	input   [ 5: 0]	 addra,
	input   [31: 0]	 dina,
	input 			 clkb,
	input   [ 5: 0]	 addrb,
	output  [31: 0]	 doutb
);

reg [31: 0] TAG[`SetNum-1:0];
reg[`SetNum-1:0] valid;

wire [31: 0] data_out;
wire val;
assign val 		= valid[addrb];
assign data_out = !val ? 0 :TAG[addrb];


//write
    always @(posedge clka) begin
    if(!rst_n)  
        begin
        valid <= 0;
        end
        else if (|wea) begin 
        valid[addra] <= 1;
        end
    end

        always @(posedge clka) begin 
        if(|wea)  
        begin 
        TAG[addra][31: 0] <= dina[31: 0];
        end
    end

DFFRE #(.WIDTH(32))     data_o    (.d(data_out), .q(doutb), .en(1), .clk(clka), .rst_n(1));


endmodule