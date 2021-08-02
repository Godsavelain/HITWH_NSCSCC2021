`include "defines_cache.v"
module icache_s2(
    input wire                  clk,
    input wire                  rst_n,
    
    //data from s1
    input wire [`DataAddrBus]  s2_virtual_addr_i,
    input wire [`DataAddrBus]  s2_physical_addr_i,
    input wire                 s2_cache_rreq_i,
    input wire [`TagVBus]      s2_tagv_cache_w0_i,
    input wire [`TagVBus]      s2_tagv_cache_w1_i,
    input wire                 s2_valid0_i,
    input wire                 s2_valid1_i,
    input wire                 s2_cached_i,
    input wire                 s2_en_i,
    input wire                 s2_install_i,


    input wire [`DataBus]      s2_data_way0_i,
    input wire [`DataBus]      s2_data_way1_i, 

    //from axi
    input wire                 s2_rend_i,
    input wire [`WayBus]       s2_cacheline_rdata_i,

    //from cpu
    input wire                 s2_cpuvalid_i,//cpu get data in this cycle

    //cache state
    output wire [`ICACHE_STATUS] s2_status_o,
    
    //to axi
    output wire                  s2_axi_req_o,
    output wire [`DataAddrBus]   s2_addr_o,
    output wire                  s2_uc_req_o,
    output wire [`DataBus]       s2_uc_addr_o,
    
    //to s1
    output wire                  icache_stall_o,
    output wire                  s2_hit1_o,
    output wire                  s2_hit2_o,
    output wire                  s2_rreq_o,

    //to cpu
    output wire [`DataAddrBus]   s2_rdata_o,
    output wire                  icache_data_valid//data com from cached channel


    );
    
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////Initialization////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
    
    
    //keep input data
    reg use_readdata;
        always@(posedge clk)begin
        if(!rst_n)begin
            use_readdata    <= 0;
        end
        else if(s2_rend_i)begin
            use_readdata    <= 1;
        end
        else if(s2_cpuvalid_i)begin
            use_readdata    <= 0;
        end
        
    end


    reg [`TagVBus]      tagv_cache_w0;
    reg [`TagVBus]      tagv_cache_w1;

    always@(posedge clk)begin
        if(!rst_n)begin
            tagv_cache_w0    <= 0;
            tagv_cache_w1    <= 0;
        end
        else if(icache_stall_o)begin
            tagv_cache_w0    <= s2_tagv_cache_w0_i;
            tagv_cache_w1    <= s2_tagv_cache_w1_i;
        end
        else begin
            tagv_cache_w0    <= tagv_cache_w0;
            tagv_cache_w1    <= tagv_cache_w1;
        end
    end
    
    //status
    reg [`ICACHE_STATUS] icache_status;
    assign s2_status_o = icache_status;
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            icache_status <= `ICACHE_IDLE;                 
        end
        else begin
            if((icache_status==`ICACHE_IDLE) && (s2_axi_req_o | s2_uc_req_o)  )
            begin
                icache_status <= `ICACHE_READ;
            end
            else if((icache_status==`ICACHE_READ) && s2_rend_i )
            begin
                icache_status <= `ICACHE_IDLE;
            end
        end
    end
    
    //Stall
    assign icache_stall_o = (icache_status == `ICACHE_READ) | (s2_axi_req_o) | s2_uc_req_o;

    //hit logic
    wire [20: 0] tag1;
    wire [20: 0] tag2;
    wire hit1      = (s2_tagv_cache_w0_i[20:0]==s2_physical_addr_i[`TagBus] && s2_valid0_i==`Valid)? `HitSuccess : `HitFail;
    wire hit2      = (s2_tagv_cache_w1_i[20:0]==s2_physical_addr_i[`TagBus] && s2_valid1_i==`Valid)? `HitSuccess : `HitFail;
    assign s2_hit1_o = hit1;
    assign s2_hit2_o = hit2;
    
    //axi 
    assign s2_axi_req_o = s2_cache_rreq_i & !(hit1 | hit2) & !s2_install_i; //only send request once
    assign s2_addr_o    = {s2_physical_addr_i[31 : 5], 5'b0};

    assign s2_uc_req_o  = (!s2_cached_i) && s2_en_i && !s2_install_i;
    assign s2_uc_addr_o = s2_physical_addr_i;
    //to s1
    assign s2_rreq_o    = s2_cache_rreq_i;

    //to cpu
    reg [`DataBus] read_data;//data to be sent to cpu when read transfer ends
    assign icache_data_valid = s2_cached_i;
    assign s2_rdata_o   = (use_readdata == 1 )? read_data: 
                          hit1 ? s2_data_way0_i :
                          hit2 ? s2_data_way1_i :
                          read_data;
 

    wire [ 2: 0] choose;
    assign choose = s2_physical_addr_i[4:2];

    wire [31: 0] data_in0;
    wire [31: 0] data_in1;
    wire [31: 0] data_in2;
    wire [31: 0] data_in3;
    wire [31: 0] data_in4;
    wire [31: 0] data_in5;
    wire [31: 0] data_in6;
    wire [31: 0] data_in7;

    wire [31: 0] data_in;

    assign  data_in0    = s2_cacheline_rdata_i[31 : 0];
    assign  data_in1    = s2_cacheline_rdata_i[63 :32];
    assign  data_in2    = s2_cacheline_rdata_i[95 :64];
    assign  data_in3    = s2_cacheline_rdata_i[127:96];
    assign  data_in4    = s2_cacheline_rdata_i[159:128];
    assign  data_in5    = s2_cacheline_rdata_i[191:160];
    assign  data_in6    = s2_cacheline_rdata_i[223:192];
    assign  data_in7    = s2_cacheline_rdata_i[255:224];

    assign data_in = (choose==3'b000) ? data_in0 :
                     (choose==3'b001) ? data_in1 :
                     (choose==3'b010) ? data_in2 :
                     (choose==3'b011) ? data_in3 :
                     (choose==3'b100) ? data_in4 :
                     (choose==3'b101) ? data_in5 :
                     (choose==3'b110) ? data_in6 :
                     data_in7;


    always @(posedge clk, negedge rst_n) begin
        if(!rst_n ) begin
            read_data <= 0;                 
        end
        else begin
            if(s2_rend_i)
            begin
                read_data <= data_in;
            end
        end
    end   

endmodule
