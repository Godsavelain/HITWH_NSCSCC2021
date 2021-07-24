`include "defines_cache.v"

module dcache(

    input  wire                 clk,
    input  wire                 rst_n,
    
    //from cpu 
    input  wire                 dc_bus_en_i,
    input  wire [ 3: 0]         dc_bus_wen_i,
    input  wire [31: 0]         dc_bus_viraddr_i,
    input  wire [31: 0]         dc_bus_phyaddr_i,
    input  wire [31: 0]         dc_bus_wdata_i,
    input  wire [ 1: 0]         dc_bus_store_size_i,
    input  wire [ 1: 0]         dc_bus_load_size_i,

    input wire                  cpu_cached_i,
    input wire                  cpu_bus_stall_i,//bus stall sent to cache

    input wire                  cpu_mem_valid_i,

    //from cache_axi
    input  wire                 rend,//give this signal and data at the same time
    input  wire                 wend,
    input  wire [`WayBus]       cacheline_rdata_i,
    input  wire [31: 0]         dc_uc_data_i,

    //to axi
    output  wire [ 3: 0]        dc_bus_wen_o,
    output  wire [31: 0]        dc_bus_addr_o,
    output  wire [31: 0]        dc_bus_wdata_o,
    output  wire [ 1: 0]        dc_bus_store_size_o,
    output  wire [ 1: 0]        dc_bus_load_size_o,

    output  wire                uncache_wreq,
    output  wire                uncache_rreq,
    output  wire                cache_rreq,
    output  wire                cache_wreq,

    output  wire [`WayBus]      cacheline_wdata_o,

    //to cpu
    output wire                 dcache_stall_o,
    output wire [`DataAddrBus]  dcache_rdata_o,
    output wire                 dcache_data_valid
    );
//s1 wires
    wire [`DataAddrBus]  s1_virtual_addr_o;
    wire [`DataAddrBus]  s1_physical_addr_o;
    wire                 s1_cache_rreq_o;
    wire                 s1_cache_wreq_o;
    wire                 s1_uc_rreq_o;
    wire                 s1_uc_wreq_o;
    wire [`TagVBus]      s1_tagv_cache_w0_o;
    wire [`TagVBus]      s1_tagv_cache_w1_o;
    wire                 s1_valid0_o;
    wire                 s1_valid1_o;
    wire                 s1_dirty0_o;
    wire                 s1_dirty1_o;
    wire                 s1_colli0_o;
    wire                 s1_colli1_o;
    wire                 s1_lru_o;
    wire                 s1_cached_o;
    wire                 s1_install_o;
    wire [`DataBus]      s1_data_way0_o;
    wire [`DataBus]      s1_data_way1_o;
    wire [`DataBus]      s1_colli_wdata_o;
    wire [`DCACHE_STATUS]    s1_s2_status_i;
    wire                 s1_s2wreq_i;
    wire                 s1_s2rreq_i;
    wire                 s1_write_miss_i;
    wire [ 3: 0]         s1_bus_wen_o;
    wire [`WayBus]       s1_data_o;
    wire [ 5: 0]         s1_virtual_index_o;

    wire [31: 0]        cache_data;
    wire [31: 0]        s1_hit_wdata_i;


dcache_s1 DCACHE_S1
(
    .clk                    (clk),
    .rst_n                  (rst_n),

    .s1_bus_en_i            (dc_bus_en_i),
    .s1_bus_wen_i           (dc_bus_wen_i),
    .s1_virtual_addr_i      (dc_bus_viraddr_i),
    .s1_physical_addr_i     (dc_bus_phyaddr_i),
    .s1_bus_wdata_i         (dc_bus_wdata_i),
    .s1_bus_store_size_i    (dc_bus_store_size_i),
    .s1_bus_load_size_i     (dc_bus_load_size_i),
    .s1_cached_i            (cpu_cached_i),
    .s1_bus_stall_i         (cpu_bus_stall_i),
                 
    .old_virtual_addr_i     (s1_virtual_addr_o),
    .old_physical_addr_i    (s1_physical_addr_o),
    .old_wen_i              (s1_bus_wen_o),
    .old_data_i             (dc_bus_wdata_o),
 
    .s1_rend_i              (rend),
    .s1_wend_i              (wend),
    .s1_cacheline_rdata_i   (cacheline_rdata_i),
    
    .dcache_stall_i         (dcache_stall_o),
    .s1_hit0_i              (s1_hit0_i),
    .s1_hit1_i              (s1_hit1_i),
    .s1_s2rreq_i            (s1_s2rreq_i),
    .s1_s2wreq_i            (s1_s2wreq_i),
    .s1_s2_status_i         (s1_s2_status_i),
    .s1_hit_wdata_i         (s1_hit_wdata_i), 
    .s1_write_miss_i        (s1_write_miss_i),
 
    .s1_cached_o            (s1_cached_o),
    .s1_bus_wen_o           (s1_bus_wen_o),
    .s1_bus_wdata_o         (dc_bus_wdata_o),
    .s1_bus_store_size_o    (dc_bus_store_size_o),
    .s1_bus_load_size_o     (dc_bus_load_size_o),
    .s1_cacheline_wdata_o   (cacheline_wdata_o),
    
    .s1_virtual_addr_o      (s1_virtual_addr_o),
    .s1_physical_addr_o     (s1_physical_addr_o),

    .s1_tagv_cache_w0_o     (s1_tagv_cache_w0_o),
    .s1_tagv_cache_w1_o     (s1_tagv_cache_w1_o),
    .s1_valid0_o            (s1_valid0_o),
    .s1_valid1_o            (s1_valid1_o),
    .s1_dirty0_o            (s1_dirty0_o),
    .s1_dirty1_o            (s1_dirty1_o),
    .s1_colli0_o            (s1_colli0_o),
    .s1_colli1_o            (s1_colli1_o),
    .s1_lru_o               (s1_lru_o),
    .s1_install_o           (s1_install_o),

    .s1_cache_rreq_o        (s1_cache_rreq_o),
    .s1_cache_wreq_o        (s1_cache_wreq_o),
    .s1_uc_rreq_o           (s1_uc_rreq_o),
    .s1_uc_wreq_o           (s1_uc_wreq_o),

    .s1_colli_wdata_o       (s1_colli_wdata_o),
    .s1_data_way0_o         (s1_data_way0_o),
    .s1_data_way1_o         (s1_data_way1_o)

);
wire [`DCACHE_STATUS]  dcache_status_o;
assign dc_bus_wen_o = s1_bus_wen_o;

dcache_s2 DCACHE_S2
(
    .clk                    (clk),
    .rst_n                  (rst_n),
    
    .s2_bus_wen_i           (s1_bus_wen_o),
    .s2_physical_addr_i     (s1_physical_addr_o),
    .s2_cache_rreq_i        (s1_cache_rreq_o),
    .s2_cache_wreq_i        (s1_cache_wreq_o),
    .s2_uc_rreq_i           (s1_uc_rreq_o),
    .s2_uc_wreq_i           (s1_uc_wreq_o),
    .s2_tagv_cache_w0_i     (s1_tagv_cache_w0_o),
    .s2_tagv_cache_w1_i     (s1_tagv_cache_w1_o),
    .s2_valid0_i            (s1_valid0_o),
    .s2_valid1_i            (s1_valid1_o),
    .s2_dirty0_i            (s1_dirty0_o),
    .s2_dirty1_i            (s1_dirty1_o),
    .s2_colli0_i            (s1_colli0_o),
    .s2_colli1_i            (s1_colli1_o),
    .s2_lru_i               (s1_lru_o),
    .s2_cached_i            (s1_cached_o),
    .s2_install_i           (s1_install_o),

    .s2_data_way0_i         (s1_data_way0_o),
    .s2_data_way1_i         (s1_data_way1_o), 
    .s2_colli_wdata_i       (s1_colli_wdata_o),
    .s2_bus_wdata_i         (dc_bus_wdata_o),

    .s2_rend_i              (rend),
    .s2_wend_i              (wend),
    .s2_cacheline_rdata_i   (cacheline_rdata_i),
    
    .s2_status_o            (s1_s2_status_i),
    
    .s2_ca_rreq_o           (cache_rreq),
    .s2_ca_wreq_o           (cache_wreq),
    .s2_uc_rreq_o           (uncache_rreq),
    .s2_uc_wreq_o           (uncache_wreq),
    .s2_addr_o              (dc_bus_addr_o),
    
    .dcache_stall_o         (dcache_stall_o),
    .s2_hit0_o              (s1_hit0_i),
    .s2_hit1_o              (s1_hit1_i),
    .s2_rreq_o              (s1_s2rreq_i),
    .s2_wreq_o              (s1_s2wreq_i),
    .s2_hit_wdata_o         (s1_hit_wdata_i),
    .s2_write_miss_o        (s1_write_miss_i),

    .s2_cache_data_o        (cache_data),
    .dcache_data_valid      (dcache_data_valid),
    .s2_cpuvalid_i          (cpu_mem_valid_i),

    .dcache_status_i        (dcache_status_o),
    .dcache_status_o        (dcache_status_o)
);
    
assign dcache_rdata_o = dcache_data_valid ? cache_data : dc_uc_data_i;

endmodule