`include "../defines.v"

module dcache_axi
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

    input  wire [ 3: 0]  uc_wen,
    input  wire [31: 0]  cache_addr,
    output wire [31: 0]  bus_rdata,//uncache read data,to cpu via dcache
    input  wire [31: 0]  bus_wdata,
    input  wire [ 1: 0]  bus_store_size,
    input  wire [ 1: 0]  bus_load_size,

    //from dcache
    input wire                   ca_rreq_i,
    input wire                   ca_wreq_i,
    input wire                   uc_rreq_i,
    input wire                   uc_wreq_i,
    input wire [`DWayBus]        cacheline_wdata_i,

    //to dcache
    output wire                  dcache_axi_rend,
    output wire                  dcache_axi_wend,
    output wire                  dcache_axi_write_ok,
    output wire [`DWayBus]       dcache_axi_data_o,//give a cacheline at once

    input  wire [`DCACHE_STATS]  status_in, 
    input  wire [31: 0]          req_addr_in, //to hold the uncache req addr 
    output wire [31: 0]          req_addr_out, 
    output wire [`DCACHE_STATS]  status_out, 
    output wire                  dcache_axi_stall

);
    reg [31: 0]        read_data;
    assign bus_rdata = read_data;

    assign arid     = 4'b0;
    assign arburst  = 2'b01;
    assign arlock   = 2'b0;
    assign arcache  = 4'b0;
    assign arprot   = 3'b0;

    assign rready   = 1'b1;

    assign awid     = 4'b0;

    assign awburst  = 2'b01;
    assign awlock   = 2'b0;
    assign awcache  = 4'b0;
    assign awprot   = 3'b0;

    assign wid      = 4'b0;

    assign bready   = 1'b1;

//to hold req
    wire burst_write;
    reg burst_write_reg;
    always @(posedge aclk, negedge aresetn) begin
        if(!aresetn ) begin
            burst_write_reg <= 0;                 
        end
        else begin
            if(bvalid)
            begin
                burst_write_reg <= 0;
            end
            else if(write_addr_handshake)
            begin
                burst_write_reg <= 1;
            end
        end
    end
    assign burst_write = bvalid ? 0 : burst_write_reg;

    wire burst_read;
    reg burst_read_reg;
    always @(posedge aclk, negedge aresetn) begin
        if(!aresetn ) begin
            burst_read_reg <= 0;                 
        end
        else begin
            if(rlast && read_handshake)
            begin
                burst_read_reg <= 0;
            end
            else if(read_addr_handshake)
            begin
                burst_read_reg <= 1;
            end
        end
    end
    assign burst_read = (rlast && read_handshake) ? 0 : burst_read_reg;

    reg  ca_rreq_reg;
    always @(posedge aclk, negedge aresetn) begin
        if(!aresetn ) begin
            ca_rreq_reg <= 0;                 
        end
        else begin
            if(dcache_axi_rend)
            begin
                ca_rreq_reg <= 0;
            end
            else if(ca_rreq_i)
            begin
                ca_rreq_reg <= 1;
            end
        end
    end

    wire   ca_rreq;
    assign ca_rreq   = ca_rreq_i ? 1 : ca_rreq_reg;
    assign arlen     = ca_rreq ? 4'hF : 4'h0;

    reg  ca_wreq_reg;
    always @(posedge aclk, negedge aresetn) begin
        if(!aresetn ) begin
            ca_wreq_reg <= 0;                 
        end
        else begin
            if(dcache_axi_wend)
            begin
                ca_wreq_reg <= 0;
            end
            else if(ca_wreq_i)
            begin
                ca_wreq_reg <= 1;
            end
        end
    end

    wire   ca_wreq;
    assign ca_wreq   = ca_wreq_i ? 1 : ca_wreq_reg;
    assign awlen     = ca_wreq ? 4'hF : 4'b0;

    reg  uc_wreq_reg;
    always @(posedge aclk, negedge aresetn) begin
        if(!aresetn ) begin
            uc_wreq_reg <= 0;                 
        end
        else begin
            if(dcache_axi_wend)
            begin
                uc_wreq_reg <= 0;
            end
            else if(uc_wreq_i)
            begin
                uc_wreq_reg <= 1;
            end
        end
    end

    wire   uc_wreq;
    assign uc_wreq   = uc_wreq_i ? 1 : uc_wreq_reg;

    reg  uc_rreq_reg;
    always @(posedge aclk, negedge aresetn) begin
        if(!aresetn ) begin
            uc_rreq_reg <= 0;                 
        end
        else begin
            if(dcache_axi_rend)
            begin
                uc_rreq_reg <= 0;
            end
            else if(uc_rreq_i)
            begin
                uc_rreq_reg <= 1;
            end
        end
    end

    wire   uc_rreq;
    assign uc_rreq   = uc_rreq_i ? 1 : uc_rreq_reg;

    reg [ 3: 0] bus_wen_reg;
    always @(posedge aclk, negedge aresetn) begin
        if(!aresetn ) begin
            bus_wen_reg <= 0;                 
        end
        else begin
            if(dcache_axi_wend)
            begin
                bus_wen_reg <= 0;
            end
            else if(uc_wreq_i)
            begin
                bus_wen_reg <= uc_wen;
            end
        end
    end

    wire [ 3: 0] bus_wen;
    assign bus_wen = uc_wreq ? bus_wen_reg : 4'b1111;

//axi logic
    parameter IDLE           = 8'b00000001;
    parameter READ_REQUEST   = 8'b00000010;
    parameter READ_TRANSFER  = 8'b00000100;
    parameter READ_END       = 8'b00001000;
    parameter WRITE_REQUEST  = 8'b00010000;
    parameter WRITE_TRANSFER = 8'b00100000;
    parameter WRITE_RESPONSE = 8'b01000000;
    parameter WRITE_END      = 8'b10000000;

    wire [`DCACHE_STATS] status_next;
    wire         read_req;
    wire         read_addr_handshake;

    wire         write_req;
    wire         write_addr_handshake;

    wire         write_handshake;
    wire         read_handshake;

    wire [31: 0] req_addr_next;
    assign req_addr_next = (ca_rreq_i | ca_wreq_i | uc_rreq_i | uc_wreq_i ) ? cache_addr : req_addr_in;  

    assign read_req =  ((status_in[0] | status_in[3] | status_in[7] |status_in == 0) & (ca_rreq_i | uc_rreq_i));

    assign araddr   = req_addr_next;
    assign arvalid  = read_req | status_in[1];
    assign read_addr_handshake = arvalid & arready;

    assign write_req = (status_in[0] | status_in[3] | status_in[7] | status_in == 0) & (uc_wreq_i | ca_wreq_i);

    assign awaddr   = req_addr_next;
    assign awvalid  = write_req | status_in[4];
    assign write_addr_handshake = awvalid & awready;

    assign read_handshake = rvalid & rready;
    assign write_handshake = wvalid & wready;

    //end of read,give data in same cycle
    assign dcache_axi_rend = (rlast & read_handshake);
    //end of write
    assign dcache_axi_wend = bvalid ;
    assign dcache_axi_write_ok = write_addr_handshake;

    assign awsize   = ca_wreq ? 3'b010 : { 1'b0, bus_store_size};
    assign arsize   = ca_rreq ? 3'b010 : { 1'b0, bus_load_size};
    assign wstrb    = bus_wen;
    assign wvalid   = status_in[4] | status_in[5] | burst_write;

    // assign dcache_axi_stall = status_in[1] | (status_in[2] & !(rlast & read_handshake)) | read_req | write_req | 
    //                       status_in[4] | status_in[5] | (status_in[6] & !bvalid) 
    //                       ;
    assign dcache_axi_stall = status_in[1] | (status_in[2] & !(rlast & read_handshake)) | 
                          status_in[4] | status_in[5] | (status_in[6] & !bvalid);

    assign status_next = (status_in[0] | status_in == 0) && read_req    ? READ_REQUEST  :
                         status_in[1] && read_addr_handshake            ? READ_TRANSFER :
                         status_in[1] && !read_addr_handshake           ? READ_REQUEST :
                         status_in[2] && (burst_read | burst_write)     ? READ_TRANSFER :
                         status_in[2] && !(burst_read | burst_write)    ? READ_END      :
                         (status_in[3] | status_in[7]) && !read_req && !write_req   ? IDLE :
                         (status_in[3] | status_in[7]) && read_req      ? READ_REQUEST  :
                         status_in[0] && write_req                      ? WRITE_REQUEST :
                         status_in[4] && (write_addr_handshake && !ca_wreq) ? WRITE_TRANSFER :
                         status_in[4] && (write_addr_handshake && ca_wreq) ? WRITE_END :
                         status_in[4] && !write_addr_handshake          ? WRITE_REQUEST :
                         status_in[5] && !(wlast & write_handshake)     ? WRITE_TRANSFER :
                         status_in[5] && (wlast & write_handshake)      ? WRITE_RESPONSE :
                         status_in[6] && !bvalid                        ? WRITE_RESPONSE :
                         status_in[6] && bvalid                         ? WRITE_END     :
                         (status_in[3] | status_in[7]) && write_req     ? WRITE_REQUEST  :
                         8'b0000001;

    DFFRE #(.WIDTH(32))  addr_next  (.d(req_addr_next), .q(req_addr_out), .en(1), .clk(aclk), .rst_n(aresetn));
    DFFRE #(.WIDTH(`DCACHE_STATS_W))  stat_next  (.d(status_next), .q(status_out), .en(1), .clk(aclk), .rst_n(aresetn));

   always @(posedge aclk, negedge aresetn) begin
        if (!aresetn) begin
            read_data <= 0;
        end
        else if (read_handshake) begin
            read_data <= rdata;
        end

    end
    
    //write burst count
   reg [3:0] write_counter;
   always @(posedge aclk, negedge aresetn) begin
        if(!aresetn ) begin
            write_counter <= 0;                 
        end
        else if(bvalid)
        begin
            write_counter <= 0;
        end
        else begin
            if(write_handshake)
            begin
                write_counter <= write_counter+1;
            end
        end
    end

    //burst write
    reg [`DataBus]burst_wdata[`DBlockNum-1:0];
    always @(posedge aclk) begin
    if(ca_wreq_i)
        begin
        burst_wdata[ 0] <= cacheline_wdata_i[ 31:  0];
        burst_wdata[ 1] <= cacheline_wdata_i[ 63: 32];
        burst_wdata[ 2] <= cacheline_wdata_i[ 95: 64];
        burst_wdata[ 3] <= cacheline_wdata_i[127: 96];
        burst_wdata[ 4] <= cacheline_wdata_i[159:128];
        burst_wdata[ 5] <= cacheline_wdata_i[191:160];
        burst_wdata[ 6] <= cacheline_wdata_i[223:192];
        burst_wdata[ 7] <= cacheline_wdata_i[255:224];
        burst_wdata[ 8] <= cacheline_wdata_i[287:256];
        burst_wdata[ 9] <= cacheline_wdata_i[319:288];
        burst_wdata[10] <= cacheline_wdata_i[351:320];
        burst_wdata[11] <= cacheline_wdata_i[383:352];
        burst_wdata[12] <= cacheline_wdata_i[415:384];
        burst_wdata[13] <= cacheline_wdata_i[447:416];
        burst_wdata[14] <= cacheline_wdata_i[479:448];
        burst_wdata[15] <= cacheline_wdata_i[511:480];
        end
    end
    assign wdata = ca_wreq_reg ? burst_wdata[write_counter] : bus_wdata;
    assign wlast = uc_wreq ? 1 : (write_counter==4'b1111);

    //read burst count
    reg [3:0] read_counter;
    always @(posedge aclk, negedge aresetn) begin
        if(!aresetn ) begin
            read_counter <= 0;                 
        end
        else if(rlast && read_handshake)
        begin
            read_counter <= 0;
        end
        else begin
            if(read_handshake)
            begin
                read_counter <= read_counter+1;
            end
        end
    end
    //burst read data
    reg [`DataBus]burst_rdata[`DBlockNum-1:0];
    always @(posedge aclk, negedge aresetn) begin
        if(!aresetn ) begin
            burst_rdata[0 ] <= 0;
            burst_rdata[1 ] <= 0; 
            burst_rdata[2 ] <= 0; 
            burst_rdata[3 ] <= 0; 
            burst_rdata[4 ] <= 0;            
            burst_rdata[5 ] <= 0; 
            burst_rdata[6 ] <= 0; 
            burst_rdata[7 ] <= 0;
            burst_rdata[8 ] <= 0; 
            burst_rdata[9 ] <= 0; 
            burst_rdata[10] <= 0; 
            burst_rdata[11] <= 0; 
            burst_rdata[12] <= 0; 
            burst_rdata[13] <= 0; 
            burst_rdata[14] <= 0; 
            burst_rdata[15] <= 0;  
        end
        else begin
        burst_rdata[read_counter] <= rdata;
        end
    end
 
    assign dcache_axi_data_o[31 :  0] = burst_rdata[0 ];
    assign dcache_axi_data_o[63 : 32] = burst_rdata[1 ];
    assign dcache_axi_data_o[95 : 64] = burst_rdata[2 ];
    assign dcache_axi_data_o[127: 96] = burst_rdata[3 ];
    assign dcache_axi_data_o[159:128] = burst_rdata[4 ];
    assign dcache_axi_data_o[191:160] = burst_rdata[5 ];
    assign dcache_axi_data_o[223:192] = burst_rdata[6 ];
    assign dcache_axi_data_o[255:224] = burst_rdata[7 ];
    assign dcache_axi_data_o[287:256] = burst_rdata[8 ];
    assign dcache_axi_data_o[319:288] = burst_rdata[9 ];
    assign dcache_axi_data_o[351:320] = burst_rdata[10];
    assign dcache_axi_data_o[383:352] = burst_rdata[11];
    assign dcache_axi_data_o[415:384] = burst_rdata[12];
    assign dcache_axi_data_o[447:416] = burst_rdata[13];
    assign dcache_axi_data_o[479:448] = burst_rdata[14];
    assign dcache_axi_data_o[511:480] = (rlast && read_handshake) ? rdata : burst_rdata[15] ;

    endmodule