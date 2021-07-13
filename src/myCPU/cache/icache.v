`include "defines_cache.v"

module icache(

    input wire                  clk,
    input wire                  rst_n,
    
    //from cpu 
    input wire                  cpu_rreq_i,
    //input wire [3:0]            cpu_wsel_i,
    //input wire [`DataAddrBus]   cpu_wdata_i,
    input wire                  cpu_cached_i,
    input wire [`DataAddrBus]   cpu_virtual_addr_i,
    input wire [`DataAddrBus]   cpu_physical_addr_i,
    input wire                  cpu_bus_stall_i,

    //from cache_axi
    input  wire                 rend,//give this signal and data at the same time
    input  wire [`WayBus]       cacheline_rdata_i,
    //input  wire                 write_end,

    //to cache_axi
    output wire                 icache_rreq_o,
    output wire [`DataAddrBus]  icache_raddr_o,
    
    //to cpu
    output wire                 cpu_stall_o,
    output wire [`DataAddrBus]  icache_rdata_o,
    output wire                 icache_data_valid
    );
//s1 wires
    wire [`DataAddrBus]  s1_virtual_addr_o;
    wire [`DataAddrBus]  s1_physical_addr_o;
    wire                 s1_cache_rreq_o;
    wire [`TagVBus]      s1_tagv_cache_w0_o;
    wire [`TagVBus]      s1_tagv_cache_w1_o;
    wire                 s1_valid0_o;
    wire                 s1_valid1_o;
    wire                 s1_cached_o;
    wire                 s1_install_o;
    wire [`DataBus]      s1_data_way0_o;
    wire [`DataBus]      s1_data_way1_o;
    wire [`ICACHE_STATUS]    s1_s2_status_i;

icache_s1 ICACHE_S1
(
    .clk(clk),
    .rst_n(rst_n),

    
    .s1_rreq_i(cpu_rreq_i),
    .s1_cached_i(cpu_cached_i),
    .s1_virtual_addr_i(cpu_virtual_addr_i),
    .s1_physical_addr_i(cpu_physical_addr_i),
    .s1_bus_stall_i(cpu_bus_stall_i),

    .old_virtual_addr_i(s1_virtual_addr_o),
    .old_physical_addr_i(s1_physical_addr_o),

    
    .s1_rend_i(rend),
    .s1_cacheline_rdata_i(cacheline_rdata_i),
    
    
    .icache_stall_i(cpu_stall_o),
    .s1_hit1_i(s1_hit1_i),
    .s1_hit2_i(s1_hit2_i),
    .s1_s2rreq_i(s1_s2rreq_i),
    .s1_s2_status_i(s1_s2_status_i),

    
    .s1_virtual_addr_o(s1_virtual_addr_o),
    .s1_physical_addr_o(s1_physical_addr_o),
    .s1_cache_rreq_o(s1_cache_rreq_o),
    .s1_tagv_cache_w0_o(s1_tagv_cache_w0_o),
    .s1_tagv_cache_w1_o(s1_tagv_cache_w1_o),
    .s1_valid0_o(s1_valid0_o),
    .s1_valid1_o(s1_valid1_o),
    .s1_cached_o(s1_cached_o),
    .s1_install_o(s1_install_o),

    .s1_data_way0_o(s1_data_way0_o),
    .s1_data_way1_o(s1_data_way1_o)     
);

icache_s2 ICACHE_S2
(
    .clk(clk),
    .rst_n(rst_n),
    
    .s2_virtual_addr_i(s1_virtual_addr_o),
    .s2_physical_addr_i(s1_physical_addr_o),
    .s2_cache_rreq_i(s1_cache_rreq_o),
    .s2_tagv_cache_w0_i(s1_tagv_cache_w0_o),
    .s2_tagv_cache_w1_i(s1_tagv_cache_w1_o),
    .s2_valid0_i(s1_valid0_o),
    .s2_valid1_i(s1_valid1_o),
    .s2_cached_i(s1_cached_o),
    .s2_install_i(s1_install_o),

    .s2_data_way0_i(s1_data_way0_o),
    .s2_data_way1_i(s1_data_way1_o), 

    .s2_rend_i(rend),
    .s2_cacheline_rdata_i(cacheline_rdata_i),
    
    .s2_status_o(s1_s2_status_i),
    
    .s2_axi_req_o(icache_rreq_o),
    .s2_addr_o(icache_raddr_o),
    
    .icache_stall_o(cpu_stall_o),
    .s2_hit1_o(s1_hit1_i),
    .s2_hit2_o(s1_hit2_i),
    .s2_rreq_o(s1_s2rreq_i),

    .s2_rdata_o(icache_rdata_o),
    .icache_data_valid(icache_data_valid)
);
    

endmodule