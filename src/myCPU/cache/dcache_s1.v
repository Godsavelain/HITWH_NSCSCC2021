`include "defines_cache.v"

module dcache_s1(

    input wire                  clk,
    input wire                  rst_n,

    //from dcache
    input wire                  s1_bus_en_i,
    input wire [ 3: 0]          s1_bus_wen_i,
    input wire [`DataAddrBus]   s1_virtual_addr_i,
    input wire [`DataAddrBus]   s1_physical_addr_i,
    input wire [31: 0]          s1_bus_wdata_i,
    input wire [ 1: 0]          s1_bus_store_size_i,
    input wire [ 1: 0]          s1_bus_load_size_i,
    input wire                  s1_cached_i,
    input wire                  s1_bus_stall_i,

    //from last cycle
    input wire [`DataAddrBus]   old_virtual_addr_i,
    input wire [`DataAddrBus]   old_physical_addr_i,
    input wire [ 3: 0]          old_wen_i,
    input wire [31: 0]          old_data_i,

    //from axi
    input  wire                 s1_rend_i,//give this signal and data at the same time
    input  wire                 s1_wend_i,
    input  wire [`WayBus]       s1_cacheline_rdata_i,

    //from S2   
    input  wire                 dcache_stall_i,
    input  wire                 s1_hit0_i,
    input  wire                 s1_hit1_i,
    input  wire                 s1_s2rreq_i,//s2 stage has req
    input  wire                 s1_s2wreq_i,
    input  wire [`DCACHE_STATUS] s1_s2_status_i,
    input  wire [31: 0]         s1_hit_wdata_i, //for hit write
    input  wire                 s1_write_miss_i,

    //to dcache
    output  wire                s1_cached_o,
    output  wire [ 3: 0]        s1_bus_wen_o,
    output  wire [31: 0]        s1_bus_wdata_o,//for uncache wdata
    output  wire [ 1: 0]        s1_bus_store_size_o,
    output  wire [ 1: 0]        s1_bus_load_size_o,
    output  wire [`WayBus]      s1_cacheline_wdata_o,
    
    //to S2
    output wire [`DataAddrBus]  s1_virtual_addr_o,
    output wire [`DataAddrBus]  s1_physical_addr_o,

    output wire [`TagVBus]      s1_tagv_cache_w0_o,
    output wire [`TagVBus]      s1_tagv_cache_w1_o,
    output wire                 s1_valid0_o,
    output wire                 s1_valid1_o,
    output wire                 s1_dirty0_o,
    output wire                 s1_dirty1_o,
    output wire [`BlockNum-1:0] s1_colli0_o,//read/write collision
    output wire [`BlockNum-1:0] s1_colli1_o,
    output wire                 s1_lru_o,
    output wire                 s1_install_o,

    output wire [`DataBus]      s1_colli_wdata_o,
    output wire [`DataBus]      s1_data_way0_o,
    output wire [`DataBus]      s1_data_way1_o,

    //these sigs won't be sent to axi directly
    //must go to s2, sw send all requests after pending
    output wire                 s1_cache_rreq_o,
    output wire                 s1_cache_wreq_o,
    output wire                 s1_uc_rreq_o,
    output wire                 s1_uc_wreq_o


    );
    
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////Initialization////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
    assign wen = |s1_bus_wen_i;  

    //updated cacheline data
    wire [`DataBus]new_rdata[`BlockNum-1:0];  
    for(genvar i =0 ;i<`BlockNum; i=i+1)begin
    //if there is a write miss, must update the cacheline data to be written when rend enters 
        assign new_rdata[i][31:24] = old_wen_i[3] ? old_data_i[31:24] : s1_cacheline_rdata_i[32*(i+1)- 1:(32*i+24)];
        assign new_rdata[i][23:16] = old_wen_i[2] ? old_data_i[23:16] : s1_cacheline_rdata_i[32*(i+1)- 9:(32*i+16)];
        assign new_rdata[i][15: 8] = old_wen_i[1] ? old_data_i[15: 8] : s1_cacheline_rdata_i[32*(i+1)-17:(32*i+ 8)];
        assign new_rdata[i][ 7: 0] = old_wen_i[0] ? old_data_i[ 7: 0] : s1_cacheline_rdata_i[32*(i+1)-25: 32*i    ];
    end

    //has write miss works to do
    reg write_miss;
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n ) begin
            write_miss <= 0;                 
        end
        else begin
            if(s1_write_miss_i)
            begin
                write_miss <= 1;
            end
            else if(s1_rend_i)
            begin
                write_miss <= 0;
            end
        end
    end  

    //mem_data_i in 2-dimen array
    wire [`DataBus]mem_rdata[`BlockNum-1:0];

    //if there is a write miss, must update the cacheline data to be written when rend enters 
        assign mem_rdata[0] = ((old_bank == 3'b000) && write_miss) ? new_rdata[0] : s1_cacheline_rdata_i[31: 0];
        assign mem_rdata[1] = ((old_bank == 3'b001) && write_miss) ? new_rdata[1] : s1_cacheline_rdata_i[63:32];
        assign mem_rdata[2] = ((old_bank == 3'b010) && write_miss) ? new_rdata[2] : s1_cacheline_rdata_i[95:64];
        assign mem_rdata[3] = ((old_bank == 3'b011) && write_miss) ? new_rdata[3] : s1_cacheline_rdata_i[127:96];
        assign mem_rdata[4] = ((old_bank == 3'b100) && write_miss) ? new_rdata[4] : s1_cacheline_rdata_i[159:128];
        assign mem_rdata[5] = ((old_bank == 3'b101) && write_miss) ? new_rdata[5] : s1_cacheline_rdata_i[191:160];
        assign mem_rdata[6] = ((old_bank == 3'b110) && write_miss) ? new_rdata[6] : s1_cacheline_rdata_i[223:192];
        assign mem_rdata[7] = ((old_bank == 3'b111) && write_miss) ? new_rdata[7] : s1_cacheline_rdata_i[255:224];

    //BANK 0~7 WAY 0~1

    reg [`DataBus]cache_wdata[`BlockNum-1:0];
    
    wire [3:0] wea_way0;
    wire [3:0] wea_way1;
 
    wire [ 5: 0] virtual_index;
    assign virtual_index = s1_virtual_addr_i[`IndexBus];
    //for hit write wen
    wire  way0_wen0;
    wire  way0_wen1;
    wire  way0_wen2;
    wire  way0_wen3;
    wire  way0_wen4;
    wire  way0_wen5;
    wire  way0_wen6;
    wire  way0_wen7;

    wire  way1_wen0;
    wire  way1_wen1;
    wire  way1_wen2;
    wire  way1_wen3;
    wire  way1_wen4;
    wire  way1_wen5;
    wire  way1_wen6;
    wire  way1_wen7;

    wire[ 2: 0] old_bank;
    assign old_bank  = old_virtual_addr_i[4:2];
    assign way0_wen0 = (s1_s2wreq_i & s1_hit0_i & ((old_bank ^ 3'b000)==0)) ? 1 : 0 ;
    assign way0_wen1 = (s1_s2wreq_i & s1_hit0_i & ((old_bank ^ 3'b001)==0)) ? 1 : 0 ;
    assign way0_wen2 = (s1_s2wreq_i & s1_hit0_i & ((old_bank ^ 3'b010)==0)) ? 1 : 0 ;
    assign way0_wen3 = (s1_s2wreq_i & s1_hit0_i & ((old_bank ^ 3'b011)==0)) ? 1 : 0 ;
    assign way0_wen4 = (s1_s2wreq_i & s1_hit0_i & ((old_bank ^ 3'b100)==0)) ? 1 : 0 ;
    assign way0_wen5 = (s1_s2wreq_i & s1_hit0_i & ((old_bank ^ 3'b101)==0)) ? 1 : 0 ;
    assign way0_wen6 = (s1_s2wreq_i & s1_hit0_i & ((old_bank ^ 3'b110)==0)) ? 1 : 0 ;
    assign way0_wen7 = (s1_s2wreq_i & s1_hit0_i & ((old_bank ^ 3'b111)==0)) ? 1 : 0 ;

    assign way1_wen0 = (s1_s2wreq_i & s1_hit1_i & ((old_bank ^ 3'b000)==0)) ? 1 : 0 ;
    assign way1_wen1 = (s1_s2wreq_i & s1_hit1_i & ((old_bank ^ 3'b001)==0)) ? 1 : 0 ;
    assign way1_wen2 = (s1_s2wreq_i & s1_hit1_i & ((old_bank ^ 3'b010)==0)) ? 1 : 0 ;
    assign way1_wen3 = (s1_s2wreq_i & s1_hit1_i & ((old_bank ^ 3'b011)==0)) ? 1 : 0 ;
    assign way1_wen4 = (s1_s2wreq_i & s1_hit1_i & ((old_bank ^ 3'b100)==0)) ? 1 : 0 ;
    assign way1_wen5 = (s1_s2wreq_i & s1_hit1_i & ((old_bank ^ 3'b101)==0)) ? 1 : 0 ;
    assign way1_wen6 = (s1_s2wreq_i & s1_hit1_i & ((old_bank ^ 3'b110)==0)) ? 1 : 0 ;
    assign way1_wen7 = (s1_s2wreq_i & s1_hit1_i & ((old_bank ^ 3'b111)==0)) ? 1 : 0 ;

    wire [`DataBus]way0_cache[`BlockNum-1:0];
    simple_dual_ram Bank0_way0 (.clka(clk),.ena( (|wea_way0) | way0_wen0),.wea( (wea_way0) | {4{way0_wen0}}),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[0]),.clkb(clk),.addrb(virtual_index),.doutb(way0_cache[0]));
    simple_dual_ram Bank1_way0 (.clka(clk),.ena( (|wea_way0) | way0_wen1),.wea( (wea_way0) | {4{way0_wen1}}),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[1]),.clkb(clk),.addrb(virtual_index),.doutb(way0_cache[1]));
    simple_dual_ram Bank2_way0 (.clka(clk),.ena( (|wea_way0) | way0_wen2),.wea( (wea_way0) | {4{way0_wen2}}),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[2]),.clkb(clk),.addrb(virtual_index),.doutb(way0_cache[2]));
    simple_dual_ram Bank3_way0 (.clka(clk),.ena( (|wea_way0) | way0_wen3),.wea( (wea_way0) | {4{way0_wen3}}),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[3]),.clkb(clk),.addrb(virtual_index),.doutb(way0_cache[3]));
    simple_dual_ram Bank4_way0 (.clka(clk),.ena( (|wea_way0) | way0_wen4),.wea( (wea_way0) | {4{way0_wen4}}),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[4]),.clkb(clk),.addrb(virtual_index),.doutb(way0_cache[4]));
    simple_dual_ram Bank5_way0 (.clka(clk),.ena( (|wea_way0) | way0_wen5),.wea( (wea_way0) | {4{way0_wen5}}),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[5]),.clkb(clk),.addrb(virtual_index),.doutb(way0_cache[5]));
    simple_dual_ram Bank6_way0 (.clka(clk),.ena( (|wea_way0) | way0_wen6),.wea( (wea_way0) | {4{way0_wen6}}),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[6]),.clkb(clk),.addrb(virtual_index),.doutb(way0_cache[6]));
    simple_dual_ram Bank7_way0 (.clka(clk),.ena( (|wea_way0) | way0_wen7),.wea( (wea_way0) | {4{way0_wen7}}),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[7]),.clkb(clk),.addrb(virtual_index),.doutb(way0_cache[7]));
   
    wire [`DataBus]way1_cache[`BlockNum-1:0]; 
    simple_dual_ram Bank0_way1 (.clka(clk),.ena((|wea_way1) | way1_wen0),.wea(wea_way1 | {4{way1_wen0}}),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[0]),.clkb(clk),.addrb(virtual_index),.doutb(way1_cache[0]));
    simple_dual_ram Bank1_way1 (.clka(clk),.ena((|wea_way1) | way1_wen1),.wea(wea_way1 | {4{way1_wen1}}),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[1]),.clkb(clk),.addrb(virtual_index),.doutb(way1_cache[1]));
    simple_dual_ram Bank2_way1 (.clka(clk),.ena((|wea_way1) | way1_wen2),.wea(wea_way1 | {4{way1_wen2}}),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[2]),.clkb(clk),.addrb(virtual_index),.doutb(way1_cache[2]));
    simple_dual_ram Bank3_way1 (.clka(clk),.ena((|wea_way1) | way1_wen3),.wea(wea_way1 | {4{way1_wen3}}),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[3]),.clkb(clk),.addrb(virtual_index),.doutb(way1_cache[3]));
    simple_dual_ram Bank4_way1 (.clka(clk),.ena((|wea_way1) | way1_wen4),.wea(wea_way1 | {4{way1_wen4}}),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[4]),.clkb(clk),.addrb(virtual_index),.doutb(way1_cache[4]));
    simple_dual_ram Bank5_way1 (.clka(clk),.ena((|wea_way1) | way1_wen5),.wea(wea_way1 | {4{way1_wen5}}),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[5]),.clkb(clk),.addrb(virtual_index),.doutb(way1_cache[5]));
    simple_dual_ram Bank6_way1 (.clka(clk),.ena((|wea_way1) | way1_wen6),.wea(wea_way1 | {4{way1_wen6}}),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[6]),.clkb(clk),.addrb(virtual_index),.doutb(way1_cache[6]));
    simple_dual_ram Bank7_way1 (.clka(clk),.ena((|wea_way1) | way1_wen7),.wea(wea_way1 | {4{way1_wen7}}),.addra(old_virtual_addr_i[`IndexBus]), 
        .dina(cache_wdata[7]),.clkb(clk),.addrb(virtual_index),.doutb(way1_cache[7])); 

    //for write cacheline
    for(genvar i =0 ;i<`BlockNum; i=i+1)begin
        assign s1_cacheline_wdata_o[32*(i+1)-1:32*i] = LRU_pick ? way1_cache[i] : way0_cache[i];
    end
    

    wire way0_colli_0;
    wire way0_colli_1;
    wire way0_colli_2;
    wire way0_colli_3;
    wire way0_colli_4;
    wire way0_colli_5;
    wire way0_colli_6;
    wire way0_colli_7;

    wire way1_colli_0;
    wire way1_colli_1;
    wire way1_colli_2;
    wire way1_colli_3;
    wire way1_colli_4;
    wire way1_colli_5;
    wire way1_colli_6;
    wire way1_colli_7;

    assign way0_colli_0 = way0_wen0 && ((bank ^ 3'b000)==0) && (virtual_index == old_virtual_addr_i[`IndexBus]);
    assign way0_colli_1 = way0_wen1 && ((bank ^ 3'b001)==0) && (virtual_index == old_virtual_addr_i[`IndexBus]);
    assign way0_colli_2 = way0_wen2 && ((bank ^ 3'b010)==0) && (virtual_index == old_virtual_addr_i[`IndexBus]);
    assign way0_colli_3 = way0_wen3 && ((bank ^ 3'b011)==0) && (virtual_index == old_virtual_addr_i[`IndexBus]);
    assign way0_colli_4 = way0_wen4 && ((bank ^ 3'b100)==0) && (virtual_index == old_virtual_addr_i[`IndexBus]);
    assign way0_colli_5 = way0_wen5 && ((bank ^ 3'b101)==0) && (virtual_index == old_virtual_addr_i[`IndexBus]);
    assign way0_colli_6 = way0_wen6 && ((bank ^ 3'b110)==0) && (virtual_index == old_virtual_addr_i[`IndexBus]);
    assign way0_colli_7 = way0_wen7 && ((bank ^ 3'b111)==0) && (virtual_index == old_virtual_addr_i[`IndexBus]);

    assign way1_colli_0 = way1_wen0 && ((bank ^ 3'b000)==0) && (virtual_index == old_virtual_addr_i[`IndexBus]);
    assign way1_colli_1 = way1_wen1 && ((bank ^ 3'b001)==0) && (virtual_index == old_virtual_addr_i[`IndexBus]);
    assign way1_colli_2 = way1_wen2 && ((bank ^ 3'b010)==0) && (virtual_index == old_virtual_addr_i[`IndexBus]);
    assign way1_colli_3 = way1_wen3 && ((bank ^ 3'b011)==0) && (virtual_index == old_virtual_addr_i[`IndexBus]);
    assign way1_colli_4 = way1_wen4 && ((bank ^ 3'b100)==0) && (virtual_index == old_virtual_addr_i[`IndexBus]);
    assign way1_colli_5 = way1_wen5 && ((bank ^ 3'b101)==0) && (virtual_index == old_virtual_addr_i[`IndexBus]);
    assign way1_colli_6 = way1_wen6 && ((bank ^ 3'b110)==0) && (virtual_index == old_virtual_addr_i[`IndexBus]);
    assign way1_colli_7 = way1_wen7 && ((bank ^ 3'b111)==0) && (virtual_index == old_virtual_addr_i[`IndexBus]);
    
    //Tag
    wire [31: 0] tag0;
    wire [31: 0] tag1;
    wire [31: 0] tag_in;

    assign s1_tagv_cache_w0_o = tag0[`TagBus];
    assign s1_tagv_cache_w1_o = tag1[`TagBus];
    assign tag_in            = {old_physical_addr_i[`TagBus], 11'b0};

    //for debug 
    wire [ 5: 0] old_index;
    assign old_index = old_virtual_addr_i[`IndexBus];

    simple_dual_dram TagV0 (.clka(clk),.rst_n(rst_n),.ena(|wea_way0),.wea(wea_way0),
        .addra(old_virtual_addr_i[`IndexBus]), .dina(tag_in),
        .clkb(clk),.addrb(virtual_index),.doutb(tag0));

    simple_dual_dram TagV1 (.clka(clk),.rst_n(rst_n),.ena(|wea_way1),.wea(wea_way1),
        .addra(old_virtual_addr_i[`IndexBus]), .dina(tag_in),
        .clkb(clk),.addrb(virtual_index),.doutb(tag1)); 

    //hit judgement
    wire hit_success = (s1_hit0_i | s1_hit1_i) & (s1_s2rreq_i | s1_s2wreq_i);//hit & req valid
    wire hit_fail = ~(hit_success) & (s1_s2rreq_i | s1_s2wreq_i);   

    //LRU
    reg [`SetBus]LRU;
    wire LRU_pick = LRU[old_virtual_addr_i[`IndexBus]];
    always@(posedge clk)begin
        if(!rst_n)
            LRU <= 0;
        else if(hit_success == `HitSuccess)//hit: set LRU to bit that is not hit
            LRU[old_virtual_addr_i[`IndexBus]] <= s1_hit0_i;
            //LRU_pick = 1, the way0 is used recently, the way0 is picked 
            //LRU_pick = 0, the way1 is used recently, the way1 is picked 
        else if(s1_rend_i == 1 && hit_fail == `Valid)//not hit: set opposite LRU
            LRU[old_virtual_addr_i[`IndexBus]] <= ~LRU_pick;
        else
            LRU <= LRU;
    end
    assign s1_lru_o = LRU_pick;

        //Valid
    reg  [63: 0] ca_valid0 ; 
    reg  [63: 0] ca_valid1 ;
    assign valid0 = ca_valid0[virtual_index];
    assign valid1 = ca_valid1[virtual_index];
        always@(posedge clk)begin
        if(!rst_n)
        begin
            ca_valid0 <= 0;
            ca_valid1 <= 0;
        end
        else if(s1_rend_i == 1)
        begin
            if(LRU_pick == 1)
                begin
                    ca_valid1[old_virtual_addr_i[`IndexBus]] <= 1;
                end
            else begin
                    ca_valid0[old_virtual_addr_i[`IndexBus]] <= 1;
            end
        end
            
    end 

    //dirty
    reg  [63: 0] ca_dirty0 ; 
    reg  [63: 0] ca_dirty1 ;
    assign dirty0 = ca_dirty0[virtual_index];
    assign dirty1 = ca_dirty1[virtual_index];
        always@(posedge clk)begin
        if(!rst_n)
        begin
            ca_dirty0 <= 0;
            ca_dirty1 <= 0;
        end
        else if(s1_rend_i == 1)
        begin
            if(LRU_pick == 1)
                begin
                if(write_miss)
                begin
                    ca_dirty1[old_virtual_addr_i[`IndexBus]] <= 1;
                end
                else begin
                    ca_dirty1[old_virtual_addr_i[`IndexBus]] <= 0;
                    end
                end
            else begin
                    if(write_miss)
                begin
                    ca_dirty0[old_virtual_addr_i[`IndexBus]] <= 1;
                end
                else begin
                    ca_dirty0[old_virtual_addr_i[`IndexBus]] <= 0;
                    end
            end
        end
        else if(s1_s2wreq_i)
        begin
            if(s1_hit0_i)
                begin
                    ca_dirty0[old_virtual_addr_i[`IndexBus]] <= 1;
                end
            else if(s1_hit1_i) begin
                    ca_dirty1[old_virtual_addr_i[`IndexBus]] <= 1;
            end
        end
            
    end 

    wire[ 2: 0] bank;
    assign bank  = old_virtual_addr_i[4:2];
    assign s1_data_way0_o = way0_cache[bank];
    assign s1_data_way1_o = way1_cache[bank];
                                
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////Main Operation////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

   //write to ram
    assign wea_way0 = ((s1_s2_status_i == `DCACHE_CA_READ) && s1_rend_i == 1 && LRU_pick == 1'b0)? 4'b1111 : 4'h0;   
    assign wea_way1 = ((s1_s2_status_i == `DCACHE_CA_READ) && s1_rend_i == 1 && LRU_pick == 1'b1)? 4'b1111 : 4'h0;
                     
                 
    //ram write data
    // always@(*) begin 
    //     cache_wdata[0] <= `ZeroWord;
    //     cache_wdata[1] <= `ZeroWord;
    //     cache_wdata[2] <= `ZeroWord;
    //     cache_wdata[3] <= `ZeroWord;
    //     cache_wdata[4] <= `ZeroWord;
    //     cache_wdata[5] <= `ZeroWord;
    //     cache_wdata[6] <= `ZeroWord;
    //     cache_wdata[7] <= `ZeroWord;

    //     if((s1_s2_status_i == `DCACHE_CA_READ))begin//hit fail
    //         cache_wdata[0] <= (way0_wen0 | way1_wen0) ? s1_hit_wdata_i : mem_rdata[0];
    //         cache_wdata[1] <= (way0_wen1 | way1_wen1) ? s1_hit_wdata_i : mem_rdata[1];
    //         cache_wdata[2] <= (way0_wen2 | way1_wen2) ? s1_hit_wdata_i : mem_rdata[2];
    //         cache_wdata[3] <= (way0_wen3 | way1_wen3) ? s1_hit_wdata_i : mem_rdata[3];
    //         cache_wdata[4] <= (way0_wen4 | way1_wen4) ? s1_hit_wdata_i : mem_rdata[4];
    //         cache_wdata[5] <= (way0_wen5 | way1_wen5) ? s1_hit_wdata_i : mem_rdata[5];
    //         cache_wdata[6] <= (way0_wen6 | way1_wen6) ? s1_hit_wdata_i : mem_rdata[6];
    //         cache_wdata[7] <= (way0_wen7 | way1_wen7) ? s1_hit_wdata_i : mem_rdata[7];
            
    //     end
    // end
        always@(*) begin 
            cache_wdata[0] <= (way0_wen0 | way1_wen0) ? s1_hit_wdata_i : mem_rdata[0];
            cache_wdata[1] <= (way0_wen1 | way1_wen1) ? s1_hit_wdata_i : mem_rdata[1];
            cache_wdata[2] <= (way0_wen2 | way1_wen2) ? s1_hit_wdata_i : mem_rdata[2];
            cache_wdata[3] <= (way0_wen3 | way1_wen3) ? s1_hit_wdata_i : mem_rdata[3];
            cache_wdata[4] <= (way0_wen4 | way1_wen4) ? s1_hit_wdata_i : mem_rdata[4];
            cache_wdata[5] <= (way0_wen5 | way1_wen5) ? s1_hit_wdata_i : mem_rdata[5];
            cache_wdata[6] <= (way0_wen6 | way1_wen6) ? s1_hit_wdata_i : mem_rdata[6];
            cache_wdata[7] <= (way0_wen7 | way1_wen7) ? s1_hit_wdata_i : mem_rdata[7];          
    end
  
    wire stall;
    assign stall = s1_bus_stall_i | dcache_stall_i;

    wire [`DataAddrBus]  s1_virtual_addr_next;
    wire [`DataAddrBus]  s1_physical_addr_next;
    wire                 s1_cache_rreq_next;   
    wire                 s1_valid0_next;
    wire                 s1_valid1_next;
    wire                 s1_dirty0_next;
    wire                 s1_dirty1_next;
    wire [`BlockNum-1:0] s1_colli0_next;
    wire [`BlockNum-1:0] s1_colli1_next;
    wire [ 5: 0]         s1_virtual_index_next;

    wire                 s1_install_next;
    wire                 s1_uncache_req_next;
    wire                 s1_cached_next;

    wire [ 3: 0]         s1_bus_wen_next;
    wire [31: 0]         s1_bus_wdata_next;
    wire [31: 0]         s1_colli_wdata_next;
    wire [ 1: 0]         s1_bus_store_size_next;
    wire [ 1: 0]         s1_bus_load_size_next;  

    assign  s1_virtual_addr_next   = s1_virtual_addr_i;
    assign  s1_physical_addr_next  = s1_physical_addr_i;

    assign  s1_valid0_next         = valid0;
    assign  s1_valid1_next         = valid1;
    assign  s1_dirty0_next         = dirty0;
    assign  s1_dirty1_next         = dirty1;
    assign  s1_colli0_next         = {way0_colli_7 , way0_colli_6 , way0_colli_5 , way0_colli_4 
                                    ,way0_colli_3 , way0_colli_2 , way0_colli_1 , way0_colli_0};
    assign  s1_colli1_next         = {way1_colli_7 , way1_colli_6 , way1_colli_5 , way1_colli_4 
                                    ,way1_colli_3 , way1_colli_2 , way1_colli_1 , way1_colli_0} ;

    assign  s1_install_next        = stall;

    assign  s1_bus_wen_next        = s1_bus_wen_i;
    assign  s1_bus_wdata_next      = s1_bus_wdata_i;
    assign  s1_colli_wdata_next    = s1_hit_wdata_i;

    assign  s1_bus_store_size_next = s1_bus_store_size_i;
    assign  s1_bus_load_size_next  = s1_bus_load_size_i; 

    assign  s1_cache_rreq_next     = s1_cached_i && !wen && s1_bus_en_i ;
    assign  s1_cache_wreq_next     = s1_cached_i && wen && s1_bus_en_i ;
    assign  s1_uc_rreq_next        = !s1_cached_i&& !wen && s1_bus_en_i ;
    assign  s1_uc_wreq_next        = !s1_cached_i&& wen && s1_bus_en_i ;
    assign  s1_cached_next         = s1_cached_i;

    wire en;
    assign en = !stall;


DFFRE #(.WIDTH(32))     virtual_addr_next    (.d(s1_virtual_addr_next), .q(s1_virtual_addr_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))     physical_addr_next   (.d(s1_physical_addr_next), .q(s1_physical_addr_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))      valid1_next          (.d(s1_valid0_next), .q(s1_valid0_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))      valid2_next          (.d(s1_valid1_next), .q(s1_valid1_o), .en(en), .clk(clk), .rst_n(rst_n));

DFFRE #(.WIDTH(1))      dirty0_next          (.d(s1_dirty0_next), .q(s1_dirty0_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))      dirty1_next          (.d(s1_dirty1_next), .q(s1_dirty1_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(`BlockNum))  colli0_next      (.d(s1_colli0_next), .q(s1_colli0_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(`BlockNum))  colli1_next      (.d(s1_colli1_next), .q(s1_colli1_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))      install_next         (.d(s1_install_next), .q(s1_install_o), .en(1'b1), .clk(clk), .rst_n(rst_n));

DFFRE #(.WIDTH(1))      cached_next          (.d(s1_cached_next), .q(s1_cached_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(4))      bus_wen_next         (.d(s1_bus_wen_next), .q(s1_bus_wen_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))     bus_wdata_next       (.d(s1_bus_wdata_next), .q(s1_bus_wdata_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(32))     colli_wdata_next     (.d(s1_colli_wdata_next), .q(s1_colli_wdata_o), .en(en), .clk(clk), .rst_n(rst_n));

DFFRE #(.WIDTH(2))      bus_store_size_next  (.d(s1_bus_store_size_next), .q(s1_bus_store_size_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(2))      bus_load_size_next   (.d(s1_bus_load_size_next), .q(s1_bus_load_size_o), .en(en), .clk(clk), .rst_n(rst_n));

DFFRE #(.WIDTH(1))      cache_rreq_next      (.d(s1_cache_rreq_next), .q(s1_cache_rreq_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))      cache_wreq_next      (.d(s1_cache_wreq_next), .q(s1_cache_wreq_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))      uc_rreq_next         (.d(s1_uc_rreq_next), .q(s1_uc_rreq_o), .en(en), .clk(clk), .rst_n(rst_n));
DFFRE #(.WIDTH(1))      uc_wreq_next         (.d(s1_uc_wreq_next), .q(s1_uc_wreq_o), .en(en), .clk(clk), .rst_n(rst_n));

endmodule
