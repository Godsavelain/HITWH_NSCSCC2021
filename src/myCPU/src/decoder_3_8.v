module decoder_3_8
(
	input 	[ 2:0] in,
	output	[ 7:0] out
);

genvar i;
generate
for(i=0;i<8;i=i+1)
begin
	assign out[i] = (in == i);
end

endgenerate


endmodule