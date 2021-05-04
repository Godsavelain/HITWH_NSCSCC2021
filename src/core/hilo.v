module hilo
(
    input  wire         clk,
    input  wire         rst_n,
    input  wire [31: 0] whidata,
    input  wire [31: 0] wlodata,
    input  wire         whien,
    input  wire         wloen,

    output wire [31: 0] rhidata,
    output wire [31: 0] rlodata
);

    reg [31: 0] hi;
    reg [31: 0] lo;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            hi <= 32'b0;
        end
        else begin
            if(whien) hi <= whidata;
        end

        if(!rst_n) begin
            lo <= 32'b0;
        end
        else begin
            if(wloen) lo <= wlodata;
        end
    end

    assign rhidata = hi;
    assign rlodata = lo;

endmodule