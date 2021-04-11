module DFFRE
#(parameter WIDTH=1)
(
	input wire[WIDTH-1:0]	d,
	input wire 				clk,
	input wire				rst_n,
	input wire 				en,
	output reg[WIDTH-1:0]	q
);

	always @(posedge clk or negedge rst_n)
	begin
		if(rst_n == 1'b0)		q <= 0;
		else if (en == 1'b1)	q[WIDTH-1:0] <= d[WIDTH-1:0];
		else;	
	end
endmodule