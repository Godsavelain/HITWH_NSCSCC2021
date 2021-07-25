
`include "../defines.v"

module mmu
(
    input  wire         en,
    input  wire [31: 0] vaddr,
    output wire [31: 0] paddr,
    output wire         cached,
    input  wire [ 2: 0] ConfigK0
);

wire [ 7: 0] mode;
decoder_3_8 u_dec0(.in(vaddr[31:29]), .out(mode));

wire kuseg  =  mode[0] | mode[1] | mode[2] | mode[3] ;
wire kseg0  =  mode[4];
wire kseg1  =  mode[5];
wire kseg2  =  mode[6];
wire kseg3  =  mode[7];

assign paddr = (kseg0 | kseg1) ? {3'b000, vaddr[28:0]} :
                vaddr;

 assign cached = kseg0 & ((ConfigK0 ^ 3'b011) == 0) | kseg2 | kseg3 | kuseg;
//assign cached = kseg2 | kseg3 | kuseg;
endmodule