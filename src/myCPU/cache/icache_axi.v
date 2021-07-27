`include "../defines.v"

module icache_axi
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
    input  wire          bus_stall,//if stage is stalled
    //input  wire          bus_cached,

    input  wire [ 3: 0]  status_in, 
    input  wire [31: 0]  req_addr_in, //to hold the uncache req addr 
    output wire [ 3: 0]  status_out, 
    output wire [31: 0]  req_addr_out, 
    output wire          icache_axi_stall,

    //for uncache
    input  wire                 bus_cached, 
    //from cache
    input wire                  icache_axi_req_i,
    input wire [`DataAddrBus]   icache_axi_addr_i,
    //from dcache_axi
    input wire                  dcache_active,//dcache is working

    //to icache
    output wire           icache_axi_rend,
    output wire [`WayBus] icache_axi_data_o        

    //input  wire [`COP ]  cacheop,
    //input  wire [31: 0]  cop_dtag
);
    reg [31: 0]        read_data;
    assign bus_rdata = read_data;

    assign arid     = 4'b0;
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

//to hold values
    reg [31: 0] ca_req_addr_reg;
    always @(posedge aclk, negedge aresetn) begin
        if(!aresetn ) begin
            ca_req_addr_reg <= 0;                 
        end
        else begin
            if(icache_axi_req_i)
            begin
                ca_req_addr_reg <= icache_axi_addr_i;
            end
        end
    end

    reg  ca_req_reg;
    always @(posedge aclk, negedge aresetn) begin
        if(!aresetn ) begin
            ca_req_reg <= 0;                 
        end
        else begin
            if(icache_axi_rend)
            begin
                ca_req_reg <= 0;
            end
            else if(icache_axi_req_i)
            begin
                ca_req_reg <= 1;
            end
        end
    end

    wire ca_req;
    assign ca_req = icache_axi_req_i ? 1 : ca_req_reg;

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
    wire         cache_fill_req;
    wire         uncache_req;
    wire [31: 0] ca_req_addr;

    assign ca_req_addr    = icache_axi_req_i ? icache_axi_addr_i : ca_req_addr_reg;

    assign cache_fill_req = ca_req & (status_in[0] | status_in[3] | status_in == 0)  ;
    assign uncache_req    = (((status_in[0] | status_in[3] | status_in == 0) & bus_en) & !bus_cached);

    wire stall;
    assign stall = bus_stall | dcache_active ;
    assign read_req =  (uncache_req | cache_fill_req) & !stall ;
    //assign read_req = (status_in[0] | status_in == 0) & bus_en & (| bus_wen);
    assign araddr   = cache_fill_req ?  ca_req_addr :
                      (uncache_req & (!stall)) ? bus_addr : req_addr_in;
    assign arlen    = ca_req ? 4'h7 : 4'b0;
    assign arvalid  = read_req  | status_in[1];
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
    assign req_addr_next = cache_fill_req & !bus_stall ?  ca_req_addr :
                           (uncache_req & (!stall)) & !bus_stall ? bus_addr : req_addr_in;

    DFFRE #(.WIDTH(4))      stat_next           (.d(status_next), .q(status_out), .en(1), .clk(aclk), .rst_n(aresetn));
    DFFRE #(.WIDTH(32))     req_next            (.d(req_addr_next), .q(req_addr_out), .en(1), .clk(aclk), .rst_n(aresetn));
   

   //assign icache_axi_stall = read_req | status_in[1] | (status_in[2] && !(rlast & read_handshake));
   //assign icache_axi_stall = (read_req & !status_in[3]) | status_in[1] | status_in[2] ;
   assign icache_axi_stall = status_in[1] | status_in[2] ;
   
   //burst count
   reg [2:0] counter;
   always @(posedge aclk, negedge aresetn) begin
        if(!aresetn ) begin
            counter <= 0;                 
        end
        else if(rlast & read_handshake)
        begin
            counter <= 0;
        end
        else begin
            if(read_handshake)
            begin
                counter <= counter+1;
            end
        end
    end

    reg [`DataBus]burst_rdata[`BlockNum-1:0];
    always @(posedge aclk, negedge aresetn) begin
        if(!aresetn ) begin
                burst_rdata[0] <= 0;
                burst_rdata[1] <= 0; 
                burst_rdata[2] <= 0; 
                burst_rdata[3] <= 0; 
                burst_rdata[4] <= 0; 
                burst_rdata[5] <= 0; 
                burst_rdata[6] <= 0;
                burst_rdata[7] <= 0;                  
        end
        else begin
            if(read_handshake)
            begin
                burst_rdata[counter] <= rdata;
            end
        end
    end

    for(genvar i =0 ;i<`BlockNum-1; i=i+1)begin
         assign icache_axi_data_o[32*(i+1)-1:32*i] = burst_rdata[i] ;
        end 
        assign  icache_axi_data_o[255:224] = rdata ;


    assign icache_axi_rend = ca_req & rlast & read_handshake;

//transfer data to cpu
   always @(posedge aclk, negedge aresetn) begin
        if (!aresetn) begin
            read_data <= 0;
        end
        else if (read_handshake) begin
            read_data <= rdata;
        end

    end
    
    endmodule