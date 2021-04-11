module decoder_5_32
(
	input 	[ 4:0] in,
	output	[31:0] out
);

genvar i;
generate
for(i=0;i<32;i=i+1)
begin
	assign out[i] = (in == i);
end

endgenerate


endmodule