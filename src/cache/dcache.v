`include "../defines.v"

module d_cache
(
    input  wire          aclk,
    input  wire          aresetn,
    output wire  [ 3: 0] arid,
    output wire  [31: 0] araddr,
    output wire  [ 3: 0] arlen,
    output wire  [ 2: 0] arsize,
    output wire  [ 1: 0] arburst,
    output wire  [ 1: 0] arlock,
    output wire  [ 3: 0] arcache,
    output wire  [ 2: 0] arprot,
    output wire          arvalid,
    input  wire          arready,
    input  wire  [ 3: 0] rid,
    input  wire  [31: 0] rdata,
    input  wire  [ 1: 0] rresp,
    input  wire          rlast,
    input  wire          rvalid,
    output wire          rready,
    output wire  [ 3: 0] awid,
    output wire  [31: 0] awaddr,
    output wire  [ 3: 0] awlen,
    output wire  [ 2: 0] awsize,
    output wire  [ 1: 0] awburst,
    output wire  [ 1: 0] awlock,
    output wire  [ 3: 0] awcache,
    output wire  [ 2: 0] awprot,
    output wire          awvalid,
    input  wire          awready,
    output wire  [ 3: 0] wid,
    output wire  [31: 0] wdata,
    output wire  [ 3: 0] wstrb,
    output wire          wlast,
    output wire          wvalid,
    input  wire          wready,
    input  wire [ 3: 0]  bid,
    input  wire [ 1: 0]  bresp,
    input  wire          bvalid,
    output wire          bready,

    input  wire          bus_en,
    input  wire [ 3: 0]  bus_wen,
    input  wire [31: 0]  bus_addr,
    output wire [31: 0]  bus_rdata,
    input  wire [31: 0]  bus_wdata,
    input  wire [ 1: 0]  bus_size,
    //input  wire          bus_stall,
    //input  wire          bus_stall,
    //input  wire          bus_cached,

    input  wire [`DCACHE_STATS]  status_in, 
    output wire [`DCACHE_STATS]  status_out, 
    output wire                  dcache_stall

);
    reg [31: 0]        read_data;
    assign bus_rdata = read_data;

    assign arid     = 4'b0;
    assign arlen    = 4'h0;
    assign arsize   = 3'b010;
    assign arburst  = 2'b01;
    assign arlock   = 2'b0;
    assign arcache  = 4'b0;
    assign arprot   = 3'b0;

    assign rready   = 1'b1;

    assign awid     = 4'b0;
    assign awlen    = 4'b0;
    assign awburst  = 2'b01;
    assign awlock   = 2'b0;
    assign awcache  = 4'b0;
    assign awprot   = 3'b0;

    assign wid      = 4'b0;

    assign wlast    = 1;


    assign bready   = 1'b1;


//axi logic
    parameter IDLE           = 8'b00000001;
    parameter READ_REQUEST   = 8'b00000010;
    parameter READ_TRANSFER  = 8'b00000100;
    parameter READ_END       = 8'b00001000;
    parameter WRITE_REQUEST  = 8'b00010000;
    parameter WRITE_TRANSFER = 8'b00100000;
    parameter WRITE_RESPONSE = 8'b01000000;
    parameter WRITE_END      = 8'b10000000;


    wire [`DCACHE_STATS] status;
    wire [`DCACHE_STATS] status_next;
    wire         read_req;
    wire         read_addr_handshake;

    wire         write_req;
    wire         write_addr_handshake;

    wire         write_handshake;
    wire         read_handshake;

    assign read_req =  ((status_in[0] | status_in[3] | status_in[7] |status_in == 0) & bus_en & !(| bus_wen));
    //assign read_req = (status_in[0] | status_in == 0) & bus_en & (| bus_wen);
    assign araddr   = bus_addr;
    assign arvalid  = read_req | status_in[1];
    assign read_addr_handshake = arvalid & arready;

    assign write_req = (status_in[0] | status_in[3] | status_in[7] | status_in == 0) & bus_en & (| bus_wen);
    //assign read_req = (status_in[0] | status_in == 0) & bus_en & (| bus_wen);
    assign awaddr   = bus_addr;
    assign awvalid  = write_req | status_in[4];
    assign write_addr_handshake = awvalid & awready;

    assign read_handshake = rvalid & rready;
    assign write_handshake = wvalid & wready;

    assign awsize   = { 1'b0, bus_size};
    assign wstrb    = bus_wen;
    assign wvalid   = status_in[4] | status_in[5];
    assign wdata    = bus_wdata;

    assign dcache_stall = status_in[1] | (status_in[2] & !(rlast & read_handshake)) | read_req | write_req | 
                          status_in[4] | status_in[5]                               | (status_in[6] & !bvalid) 
                          ;

    assign status_next = (status_in[0] | status_in == 0) && read_req    ? READ_REQUEST  :
                         status_in[1] && read_addr_handshake            ? READ_TRANSFER :
                         status_in[2] && !(rlast & read_handshake)      ? READ_TRANSFER :
                         status_in[2] && (rlast & read_handshake)       ? READ_END      :
                         (status_in[3] | status_in[7]) && !read_req && !write_req       ? IDLE :
                         (status_in[3] | status_in[7]) && read_req      ? READ_REQUEST  :
                         status_in[0] && write_req                      ? WRITE_REQUEST :
                         status_in[4] && write_addr_handshake           ? WRITE_TRANSFER :
                         status_in[5] && !(wlast & write_handshake)     ? WRITE_TRANSFER :
                         status_in[5] && (wlast & write_handshake)      ? WRITE_RESPONSE :
                         status_in[6] && !bvalid                        ? WRITE_RESPONSE :
                         status_in[6] && bvalid                         ? WRITE_END     :
                         (status_in[3] | status_in[7]) && write_req     ? WRITE_REQUEST  :
                         8'b0000001;


    DFFRE #(.WIDTH(`DCACHE_STATS_W))      stat_next           (.d(status_next), .q(status_out), .en(1), .clk(aclk), .rst_n(aresetn));

   always @(posedge aclk, negedge aresetn) begin
        if (!aresetn) begin
            read_data <= 0;
        end
        else if (read_handshake) begin
            read_data <= rdata;
        end

    end
    
    endmodule