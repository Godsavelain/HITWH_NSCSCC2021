`include "defines_cache.v"

module icache_s1(

    input wire                  clk,
    input wire                  rst_n,

    //from icache
    input wire                  s1_rreq_i,
    input wire                  s1_cached_i,
    input wire [`DataAddrBus]   s1_virtual_addr_i,
    input wire [`DataAddrBus]   s1_physical_addr_i,
    input wire                  s1_bus_stall_i,

    //from last cycle
    input wire [`DataAddrBus]   old_virtual_addr_i,
    input wire [`DataAddrBus]   old_physical_addr_i,

    //from axi
    input  wire                 s1_rend_i,//give this signal and data at the same time
    input  wire [`WayBus]       s1_cacheline_rdata_i,
    
    //from S2
    input  wire                 icache_stall_i,
    input  wire                 s1_hit1_i,
    input  wire                 s1_hit2_i,
    input  wire                 s1_s2rreq_i,//s2 stage has req
    input  wire [`ICACHE_STATUS] s1_s2_status_i,

    //to S2
    output wire [`DataAddrBus]  s1_virtual_addr_o,
    output wire [`DataAddrBus]  s1_physical_addr_o,
    output wire                 s1_cache_rreq_o,
    output wire [`TagVBus]      s1_tagv_cache_w0_o,
    output wire [`TagVBus]      s1_tagv_cache_w1_o,
    output wire                 s1_valid0_o,
    output wire                 s1_valid1_o,
    output wire                 s1_cached_o,
    output wire                 s1_en_o,
    output wire                 s1_install_o,

    output wire [`DataBus]      s1_data_way0_o,
    output wire [`DataBus]      s1_data_way1_o

    );
    
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////Initialization////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
    
    
    //mem_data_i in 2-dimen array
    wire [`DataBus]mem_rdata[`BlockNum-1:0];
    for(genvar i =0 ;i<`BlockNum; i=i+1)begin
        assign mem_rdata[i] = s1_cacheline_rdata_i[32*(i+1)-1:32*i];
    end

    wire  cache_rreq = s1_cached_i & s1_rreq_i;

    //BANK 0~7 WAY 0~1

    reg [`DataBus]cache_wdata[`BlockNum-1:0];
    
    wire [3:0] wea_way0;
    wire [3:0] wea_way1;
 
    wire[ 5: 0] virtual_index;
    assign virtual_index = s1_virtual_addr_i[`IndexBus];

    wire [`DataBus]way0_cache[`BlockNum-1:0];
    simple_dual_ram Bank0_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[0]),.clkb(clk),.addrb(virtual_index),.doutb(way0_cache[0]));
    simple_dual_ram Bank1_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[1]),.clkb(clk),.addrb(virtual_index),.doutb(way0_cache[1]));
    simple_dual_ram Bank2_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[2]),.clkb(clk),.addrb(virtual_index),.doutb(way0_cache[2]));
    simple_dual_ram Bank3_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[3]),.clkb(clk),.addrb(virtual_index),.doutb(way0_cache[3]));
    simple_dual_ram Bank4_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[4]),.clkb(clk),.addrb(virtual_index),.doutb(way0_cache[4]));
    simple_dual_ram Bank5_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[5]),.clkb(clk),.addrb(virtual_index),.doutb(way0_cache[5]));
    simple_dual_ram Bank6_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[6]),.clkb(clk),.addrb(virtual_index),.doutb(way0_cache[6]));
    simple_dual_ram Bank7_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[7]),.clkb(clk),.addrb(virtual_index),.doutb(way0_cache[7]));
   
    wire [`DataBus]way1_cache[`BlockNum-1:0]; 
    simple_dual_ram Bank0_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[0]),.clkb(clk),.addrb(virtual_index),.doutb(way1_cache[0]));
    simple_dual_ram Bank1_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[1]),.clkb(clk),.addrb(virtual_index),.doutb(way1_cache[1]));
    simple_dual_ram Bank2_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[2]),.clkb(clk),.addrb(virtual_index),.doutb(way1_cache[2]));
    simple_dual_ram Bank3_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[3]),.clkb(clk),.addrb(virtual_index),.doutb(way1_cache[3]));
    simple_dual_ram Bank4_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[4]),.clkb(clk),.addrb(virtual_index),.doutb(way1_cache[4]));
    simple_dual_ram Bank5_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[5]),.clkb(clk),.addrb(virtual_index),.doutb(way1_cache[5]));
    simple_dual_ram Bank6_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[6]),.clkb(clk),.addrb(virtual_index),.doutb(way1_cache[6]));
    simple_dual_ram Bank7_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[7]),.clkb(clk),.addrb(virtual_index),.doutb(way1_cache[7]));                        

    //Tag
    wire [31: 0] tag0;
    wire [31: 0] tag1;
    wire [31: 0] tag_in;

    assign s1_tagv_cache_w0_o = tag0[`TagBus];
    assign s1_tagv_cache_w1_o = tag1[`TagBus];
    assign tag_in            = {old_physical_addr_i[`TagBus], 11'b0};

    simple_dual_ram TagV0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),
        .addra(old_virtual_addr_i[`IndexBus]), .dina(tag_in),
        .clkb(clk),.addrb(virtual_index),.doutb(tag0));

    simple_dual_ram TagV1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),
        .addra(old_virtual_addr_i[`IndexBus]), .dina(tag_in),
        .clkb(clk),.addrb(virtual_index),.doutb(tag1)); 

    //hit judgement
    wire hit_success = (s1_hit1_i | s1_hit2_i) & s1_s2rreq_i;//hit & req valid
    wire hit_fail = ~(hit_success) & (s1_s2rreq_i);   

    //LRU
    reg [`SetBus]LRU;
    wire LRU_pick = LRU[old_virtual_addr_i[`IndexBus]];
    always@(posedge clk)begin
        if(!rst_n)
            LRU <= 0;
        else if(hit_success == `HitSuccess)//hit: set LRU to bit that is not hit
            LRU[old_virtual_addr_i[`IndexBus]] <= s1_hit1_i;
            //LRU_pick = 1, the way0 is used recently, the way0 is picked 
            //LRU_pick = 0, the way1 is used recently, the way1 is picked 
        else if(s1_rend_i == 1 && hit_fail == `Valid)//not hit: set opposite LRU
            LRU[old_virtual_addr_i[`IndexBus]] <= ~LRU_pick;
        else
            LRU <= LRU;
    end


        //Valid
    wire wea_val0;
    wire wea_val1;
    wire wdata_val0;
    wire wdata_val1;
    assign wea_val0 = !rst_n ? 1 : (s1_rend_i && !LRU_pick);
    assign wea_val1 = !rst_n ? 1 : (s1_rend_i &&  LRU_pick);
    assign wdata_val0 = !rst_n ? 0 : 1;
    assign wdata_val1 = !rst_n ? 0 : 1;

    valid_ram ca_valid0 (.clka(clk),.ena(wea_val0),.wea(wea_val0),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(wdata_val0),.clkb(clk),.addrb(virtual_index),.doutb(s1_valid0_o));    
    valid_ram ca_valid1 (.clka(clk),.ena(wea_val1),.wea(wea_val1),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(wdata_val1),.clkb(clk),.addrb(virtual_index),.doutb(s1_valid1_o)); 

    wire[ 2: 0] bank;
    assign bank  = old_virtual_addr_i[4:2];
    assign s1_data_way0_o = way0_cache[bank];
    assign s1_data_way1_o = way1_cache[bank];
                                
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////Main Operation////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
   

   //write to ram
    assign wea_way0 = ((s1_s2_status_i == `ICACHE_READ) && s1_rend_i == 1 && LRU_pick == 1'b0)? 4'b1111 : 4'h0;   
    assign wea_way1 = ((s1_s2_status_i == `ICACHE_READ) && s1_rend_i == 1 && LRU_pick == 1'b1)? 4'b1111 : 4'h0;
                     
                 
    //ram write data
    always@(*) begin 
        cache_wdata[0] <= `ZeroWord;
        cache_wdata[1] <= `ZeroWord;
        cache_wdata[2] <= `ZeroWord;
        cache_wdata[3] <= `ZeroWord;
        cache_wdata[4] <= `ZeroWord;
        cache_wdata[5] <= `ZeroWord;
        cache_wdata[6] <= `ZeroWord;
        cache_wdata[7] <= `ZeroWord;

        if((s1_s2_status_i == `ICACHE_READ))begin//hit fail
            cache_wdata[0] <= mem_rdata[0];
            cache_wdata[1] <= mem_rdata[1];
            cache_wdata[2] <= mem_rdata[2];
            cache_wdata[3] <= mem_rdata[3];
            cache_wdata[4] <= mem_rdata[4];
            cache_wdata[5] <= mem_rdata[5];
            cache_wdata[6] <= mem_rdata[6];
            cache_wdata[7] <= mem_rdata[7];
           
        end
    end
  
    wire stall;
    assign stall = s1_bus_stall_i | icache_stall_i;

    wire [`DataAddrBus]  s1_virtual_addr_next;
    wire [`DataAddrBus]  s1_physical_addr_next;
    wire                 s1_cache_rreq_next;   
    wire                 s1_cached_next;
    wire                 s1_en_next;
    wire                 s1_install_next;
     

    assign  s1_virtual_addr_next   = s1_virtual_addr_i;
    assign  s1_physical_addr_next  = s1_physical_addr_i;
    assign  s1_cache_rreq_next     = cache_rreq;
    assign  s1_cached_next         = s1_cached_i;
    assign  s1_install_next        = stall;
    assign  s1_en_next             = s1_rreq_i;



    wire en;
    assign en = !stall;


DFFRE #(.WIDTH(32))     virtual_addr_next    (.d(s1_virtual_addr_next), .q(s1_virtual_addr_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))     physical_addr_next   (.d(s1_physical_addr_next), .q(s1_physical_addr_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))      cache_rreq_next      (.d(s1_cache_rreq_next), .q(s1_cache_rreq_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))      cache_next           (.d(s1_cached_next), .q(s1_cached_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))      install_next         (.d(s1_install_next), .q(s1_install_o), .en(1), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))      en_next              (.d(s1_en_next), .q(s1_en_o), .en(en), .clk(clk), .rst_n(rst_n));



endmodule
