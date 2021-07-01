`include "../defines.v"

module i_cache
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
    //output wire          bus_streq,
    input  wire          bus_stall,
    //input  wire          bus_cached,

    input  wire [ 3: 0]  status_in, 
    input  wire [31: 0]  req_addr_in, 
    output wire [ 3: 0]  status_out, 
    output wire [31: 0]  req_addr_out, 
    output wire          icache_stall,
    output wire          icache_ask//申请事务

    //input  wire [`COP ]  cacheop,
    //input  wire [31: 0]  cop_dtag
);
    reg [31: 0]        read_data;
    assign bus_rdata = read_data;

    assign arid     = 4'b0;
    assign arlen    = 4'b0;
    assign arsize   = 3'b010;
    assign arburst  = 2'b01;
    assign arlock   = 2'b0;
    assign arcache  = 4'b0;
    assign arprot   = 3'b0;

    assign awid     = 4'b0;
    assign awlen    = 4'b0;
    assign awsize   = 3'b010;
    assign awburst  = 2'b01;
    assign awlock   = 2'b0;
    assign awcache  = 4'b0;
    assign awprot   = 3'b0;
    assign awvalid  = 1'b0;

    assign wid      = 4'b0;
    assign wvalid   = 0;
    assign wlast    = 1'b1;
    assign wstrb    = 4'b0;
    assign wdata    = 0;

    assign bready   = 1'b1;

    assign rready   = 1'b1;


//axi logic
    parameter IDLE          = 4'b0001;
    parameter READ_REQUEST  = 4'b0010;
    parameter READ_TRANSFER = 4'b0100;
    parameter READ_END      = 4'b1000;


    wire [ 3: 0] status;
    wire [ 3: 0] status_next;
    wire [31: 0] req_addr_next;
    wire [31: 0] req_addr;
    wire         read_req;
    wire         read_addr_handshake;
    wire         read_handshake;

    assign read_req =  !bus_stall & ((status_in[0] | status_in[3] | status_in == 0) & bus_en);
    //assign read_req = (status_in[0] | status_in == 0) & bus_en & (| bus_wen);
    assign araddr   = read_req ? bus_addr : req_addr_in;
    assign arvalid  = read_req | status_in[1];
    assign read_addr_handshake = arvalid & arready;
    assign read_handshake      = rvalid & rready;

    assign awaddr = bus_addr;

    assign status_next = (status_in[0] | status_in == 0) && read_req  ? READ_REQUEST  :
                         status_in[1] && !read_addr_handshake         ? READ_REQUEST  :
                         status_in[1] && read_addr_handshake          ? READ_TRANSFER :
                         status_in[2] && !(rlast & read_handshake)    ? READ_TRANSFER :
                         status_in[2] && (rlast & read_handshake)     ? READ_END      :
                         status_in[3] && read_req                     ? READ_REQUEST  :
                         status_in[3] && !read_req                    ? IDLE          :
                         4'b0001;
    assign req_addr_next = read_req ? bus_addr : req_addr_in;

    DFFRE #(.WIDTH(4))      stat_next           (.d(status_next), .q(status_out), .en(1), .clk(aclk), .rst_n(aresetn));
    DFFRE #(.WIDTH(32))     req_next            (.d(req_addr_next), .q(req_addr_out), .en(1), .clk(aclk), .rst_n(aresetn));
   

   //assign icache_stall = read_req | status_in[1] | (status_in[2] && !(rlast & read_handshake));
   //assign icache_stall = (read_req & !status_in[3]) | status_in[1] | status_in[2] ;
   assign icache_stall = status_in[1] | status_in[2] ;
   assign icache_ask   = read_req;
   

   always @(posedge aclk, negedge aresetn) begin
        if (!aresetn) begin
            read_data <= 0;
        end
        else if (read_handshake) begin
            read_data <= rdata;
        end

    end
    
    endmodule