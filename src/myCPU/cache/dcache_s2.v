`include "defines_cache.v"
module dcache_s2(
    input wire                  clk,
    input wire                  rst_n,
    
    //data from s1
    input wire [ 3: 0]         s2_bus_wen_i,
    input wire [`DataAddrBus]  s2_physical_addr_i,
    input wire                 s2_cache_rreq_i,
    input wire                 s2_cache_wreq_i,
    input wire                 s2_uc_rreq_i,
    input wire                 s2_uc_wreq_i,
    input wire [`DTagVBus]     s2_tagv_cache_w0_i,
    input wire [`DTagVBus]     s2_tagv_cache_w1_i,
    input wire                 s2_valid0_i,
    input wire                 s2_valid1_i,
    input wire                 s2_dirty0_i,
    input wire                 s2_dirty1_i,
    input wire [`DBlockNum-1:0] s2_colli0_i,
    input wire [`DBlockNum-1:0] s2_colli1_i,
    input wire                 s2_lru_i,

    input wire                 s2_cached_i,
    input wire                 s2_install_i,

    input wire [`DataBus]      s2_data_way0_i,
    input wire [`DataBus]      s2_data_way1_i, 
    input wire [`DataBus]      s2_colli_wdata_i,
    input wire [`DataBus]      s2_bus_wdata_i,//for hit write

    //from axi
    input wire                 s2_rend_i,
    input wire                 s2_wend_i,
    input wire                 s2_write_ok,
    input wire [`DWayBus]      s2_cacheline_rdata_i,

    //from cpu
    input wire                 s2_cpuvalid_i,

    //cache state
    output wire [`DCACHE_STATUS] s2_status_o,
    
    //to axi
    output wire                  s2_ca_rreq_o,
    output wire                  s2_ca_wreq_o,
    output wire                  s2_uc_rreq_o,
    output wire                  s2_uc_wreq_o,
    output wire [`DataAddrBus]   s2_addr_o,
    
    //to s1
    output wire                  dcache_stall_o,
    output wire                  s2_hit0_o,
    output wire                  s2_hit1_o,
    output wire                  s2_rreq_o,
    output wire                  s2_wreq_o,
    output wire [31: 0]          s2_hit_wdata_o,
    output wire                  s2_write_miss_o,

    //to cpu
    output wire [`DataAddrBus]   s2_cache_data_o,//cached data
    output wire                  dcache_data_valid,//data com from cached channel

    //to s2 next cycle
    input wire [`DCACHE_STATUS]  dcache_status_i,
    output wire [`DCACHE_STATUS] dcache_status_o

    );

//status
// `define DCACHE_IDLE     5'b00001
// `define DCACHE_CA_READ  5'b00010
// `define DCACHE_CA_WRITE 5'b00100
// `define DCACHE_UC_READ  5'b01000
// `define DCACHE_UC_WRITE 5'b10000

    wire [`DCACHE_STATUS] dcache_status_next;
    assign dcache_status_next = (dcache_status_i[0] | dcache_status_i == 0) && s2_uc_rreq_o ? `DCACHE_UC_READ :
                                (dcache_status_i[0] | dcache_status_i == 0) && s2_uc_wreq_o ? `DCACHE_UC_WRITE :
                                (dcache_status_i[0] | dcache_status_i == 0) && s2_ca_rreq_o ? `DCACHE_CA_READ :
                                (dcache_status_i[0] | dcache_status_i == 0) && s2_ca_wreq_o ? `DCACHE_CA_WRITE :
                                (dcache_status_i[1] &&  s2_rend_i) ? `DCACHE_IDLE :
                                (dcache_status_i[2] &&  s2_write_ok) ? `DCACHE_CA_READ :
                                (dcache_status_i[3] &&  s2_rend_i) ? `DCACHE_IDLE :
                                (dcache_status_i[4] &&  s2_wend_i) ? `DCACHE_IDLE :
                                dcache_status_i;
    assign s2_status_o =  dcache_status_i;

DFFRE #(.WIDTH(`DCACHE_STATUS_W))   stat_next   (.d(dcache_status_next), .q(dcache_status_o), .en(1), .clk(clk), .rst_n(rst_n));

    //data to s1 for write
    assign  s2_hit_wdata_o[31:24] = s2_bus_wen_i[3] ? s2_bus_wdata_i[31:24] : s2_cache_data_o[31:24] ;
    assign  s2_hit_wdata_o[23:16] = s2_bus_wen_i[2] ? s2_bus_wdata_i[23:16] : s2_cache_data_o[23:16] ;
    assign  s2_hit_wdata_o[15: 8] = s2_bus_wen_i[1] ? s2_bus_wdata_i[15: 8] : s2_cache_data_o[15: 8] ;
    assign  s2_hit_wdata_o[ 7: 0] = s2_bus_wen_i[0] ? s2_bus_wdata_i[ 7: 0] : s2_cache_data_o[ 7: 0] ;
   
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
        
    //Stall
    // assign dcache_stall_o = s2_ca_rreq_o | s2_ca_wreq_o | s2_uc_rreq_o | s2_uc_wreq_o 
    //                         | dcache_status_i[1] | dcache_status_i[2] | dcache_status_i[3] | dcache_status_i[4] ;
    assign dcache_stall_o = dcache_status_i[1] | dcache_status_i[2] | dcache_status_i[3] | dcache_status_i[4] | write_back_end
                            | s2_uc_rreq_o | s2_uc_wreq_o | ((s2_cache_rreq_i | s2_cache_wreq_i) & !(hit1 | hit2) & !s2_install_i)  ;

    //hit logic
    wire [`DTagVBus]  tag0;
    wire [`DTagVBus]  tag1;
    wire hit1      = (s2_tagv_cache_w0_i[`DTagVBus]==s2_physical_addr_i[`DTagBus] && s2_valid0_i==`Valid)? `HitSuccess : `HitFail;
    wire hit2      = (s2_tagv_cache_w1_i[`DTagVBus]==s2_physical_addr_i[`DTagBus] && s2_valid1_i==`Valid)? `HitSuccess : `HitFail;
    assign s2_hit0_o = hit1 && !s2_install_i;
    assign s2_hit1_o = hit2 && !s2_install_i;  
    //axi 

    wire [31: 0] write_addr;
    wire [31: 0] bank0_waddr;
    wire [31: 0] bank1_waddr;
    assign bank0_waddr  =  {{s2_tagv_cache_w0_i[`DTagVBus]} , {s2_physical_addr_i[`DIndexBus]} ,6'b0};
    assign bank1_waddr  =  {{s2_tagv_cache_w1_i[`DTagVBus]} , {s2_physical_addr_i[`DIndexBus]} ,6'b0};
    assign write_addr   =  s2_lru_i ? bank1_waddr : bank0_waddr;
    wire dirty_replace;//a dirty cacheline be replaced
    assign dirty_replace = s2_lru_i ? s2_dirty1_i : s2_dirty0_i;

    //send ca_rreq in next cycle of wend
    reg  write_back_end;
    always @(posedge clk) begin
        if((dcache_status_i[2] &&  s2_write_ok))
            begin
                write_back_end <= 1;
            end
        else 
            begin
                write_back_end <= 0;
            end
    end  

    //assign s2_ca_rreq_o = ((s2_cache_rreq_i | s2_cache_wreq_i) & !(hit1 | hit2) & !s2_install_i) | (dcache_status_i[2] &&  s2_wend_i); //only send request once
    assign s2_ca_rreq_o = (!dirty_replace & (s2_cache_rreq_i | s2_cache_wreq_i) & !(hit1 | hit2) & !s2_install_i) | write_back_end ; //only send request once
    //assign s2_ca_wreq_o = (s2_cache_wreq_i & !(hit1 | hit2) & !s2_install_i) | ((s2_cache_rreq_i & !(hit1 | hit2) & !s2_install_i) && ) ;
    assign s2_ca_wreq_o = (s2_cache_rreq_i | s2_cache_wreq_i) & !(hit1 | hit2) && !s2_install_i && dirty_replace ;
    
    assign s2_addr_o    =  s2_ca_rreq_o ? {s2_physical_addr_i[31 : 6], 6'b0} :
                           s2_ca_wreq_o ? write_addr : s2_physical_addr_i ;
    
    assign s2_uc_rreq_o  = s2_uc_rreq_i & !s2_install_i;
    assign s2_uc_wreq_o  = s2_uc_wreq_i & !s2_install_i;

    //to s1
    assign s2_rreq_o    = s2_cache_rreq_i;
    assign s2_wreq_o    = s2_cache_wreq_i;
    assign s2_write_miss_o = !(hit1 | hit2) && !s2_install_i && s2_cache_wreq_i;

    //get correct data
    wire[ 3: 0] bank;
    assign bank = s2_physical_addr_i[5:2];

    wire [31:0] data0;
    wire [31:0] data1;
    assign data0 = s2_colli0_i[bank] ? s2_colli_wdata_i : s2_data_way0_i;
    assign data1 = s2_colli1_i[bank] ? s2_colli_wdata_i : s2_data_way1_i;

    //to cpu
    reg [`DataBus] read_data;//data to be sent to cpu when read transfer ends
    assign dcache_data_valid = s2_cached_i;

    //data to cpu
    assign s2_cache_data_o = (use_readdata == 1 )? read_data: 
                          hit1 ? data0 :
                          hit2 ? data1 :
                          read_data;
 

    wire [ 3: 0] choose;
    assign choose = s2_physical_addr_i[5:2];

    wire [31: 0] data_in0;
    wire [31: 0] data_in1;
    wire [31: 0] data_in2;
    wire [31: 0] data_in3;
    wire [31: 0] data_in4;
    wire [31: 0] data_in5;
    wire [31: 0] data_in6;
    wire [31: 0] data_in7;
    wire [31: 0] data_in8;
    wire [31: 0] data_in9;
    wire [31: 0] data_ina;
    wire [31: 0] data_inb;
    wire [31: 0] data_inc;
    wire [31: 0] data_ind;
    wire [31: 0] data_ine;
    wire [31: 0] data_inf;

    wire [31: 0] data_in;

    assign  data_in0    = s2_cacheline_rdata_i[ 31:  0];
    assign  data_in1    = s2_cacheline_rdata_i[ 63: 32];
    assign  data_in2    = s2_cacheline_rdata_i[ 95: 64];
    assign  data_in3    = s2_cacheline_rdata_i[127: 96];
    assign  data_in4    = s2_cacheline_rdata_i[159:128];
    assign  data_in5    = s2_cacheline_rdata_i[191:160];
    assign  data_in6    = s2_cacheline_rdata_i[223:192];
    assign  data_in7    = s2_cacheline_rdata_i[255:224];
    assign  data_in8    = s2_cacheline_rdata_i[287:256];
    assign  data_in9    = s2_cacheline_rdata_i[319:288];
    assign  data_ina    = s2_cacheline_rdata_i[351:320];
    assign  data_inb    = s2_cacheline_rdata_i[383:352];
    assign  data_inc    = s2_cacheline_rdata_i[415:384];
    assign  data_ind    = s2_cacheline_rdata_i[447:416];
    assign  data_ine    = s2_cacheline_rdata_i[479:448];
    assign  data_inf    = s2_cacheline_rdata_i[511:480];

    assign data_in = (choose==4'b0000) ? data_in0 :
                     (choose==4'b0001) ? data_in1 :
                     (choose==4'b0010) ? data_in2 :
                     (choose==4'b0011) ? data_in3 :
                     (choose==4'b0100) ? data_in4 :
                     (choose==4'b0101) ? data_in5 :
                     (choose==4'b0110) ? data_in6 :
                     (choose==4'b0111) ? data_in7 :
                     (choose==4'b1000) ? data_in8 :
                     (choose==4'b1001) ? data_in9 :
                     (choose==4'b1010) ? data_ina :
                     (choose==4'b1011) ? data_inb :
                     (choose==4'b1100) ? data_inc :
                     (choose==4'b1101) ? data_ind :
                     (choose==4'b1110) ? data_ine :
                     data_inf;


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

