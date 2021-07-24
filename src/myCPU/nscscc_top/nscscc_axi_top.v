//`include "defines_cache.v"

module mycpu_top
(
    input  wire [ 5: 0] ext_int,
    input  wire         aclk,
    input  wire         aresetn,
    output wire [ 3: 0] arid,
    output wire [31: 0] araddr,
    output wire [ 3: 0] arlen,
    output wire [ 2: 0] arsize,
    output wire [ 1: 0] arburst,
    output wire [ 1: 0] arlock,
    output wire [ 3: 0] arcache,
    output wire [ 2: 0] arprot,
    output wire         arvalid,
    input  wire         arready,
    input  wire [ 3: 0] rid,
    input  wire [31: 0] rdata,
    input  wire [ 1: 0] rresp,
    input  wire         rlast,
    input  wire         rvalid,
    output wire         rready,
    output wire [ 3: 0] awid,
    output wire [31: 0] awaddr,
    output wire [ 3: 0] awlen,
    output wire [ 2: 0] awsize,
    output wire [ 1: 0] awburst,
    output wire [ 1: 0] awlock,
    output wire [ 3: 0] awcache,
    output wire [ 2: 0] awprot,
    output wire         awvalid,
    input  wire         awready,
    output wire [ 3: 0] wid,
    output wire [31: 0] wdata,
    output wire [ 3: 0] wstrb,
    output wire         wlast,
    output wire         wvalid,
    input  wire         wready,
    input  wire [ 3: 0] bid,
    input  wire [ 1: 0] bresp,
    input  wire         bvalid,
    output wire         bready,
    
    output wire [31: 0] debug_wb_pc,
    output wire [ 3: 0] debug_wb_rf_wen,
    output wire [ 4: 0] debug_wb_rf_wnum,
    output wire [31: 0] debug_wb_rf_wdata
);

    wire  [ 3: 0] icache_arid;
    wire  [31: 0] icache_araddr;
    wire  [ 3: 0] icache_arlen;
    wire  [ 2: 0] icache_arsize;
    wire  [ 1: 0] icache_arburst;
    wire  [ 1: 0] icache_arlock;
    wire  [ 3: 0] icache_arcache;
    wire  [ 2: 0] icache_arprot;                
    wire          icache_arvalid;
    wire          icache_arready;
    wire  [ 3: 0] icache_rid;
    wire  [31: 0] icache_rdata;
    wire  [ 1: 0] icache_rresp;
    wire          icache_rlast;
    wire          icache_rvalid;
    wire          icache_rready;
    wire  [ 3: 0] icache_awid;
    wire  [31: 0] icache_awaddr;
    wire  [ 3: 0] icache_awlen;
    wire  [ 2: 0] icache_awsize;
    wire  [ 1: 0] icache_awburst;
    wire  [ 1: 0] icache_awlock;
    wire  [ 3: 0] icache_awcache;
    wire  [ 2: 0] icache_awprot;
    wire          icache_awvalid;
    wire          icache_awready;
    wire  [ 3: 0] icache_wid;
    wire  [31: 0] icache_wdata;
    wire  [ 3: 0] icache_wstrb;
    wire          icache_wlast;
    wire          icache_wvalid;
    wire          icache_wready;
    wire [ 3: 0]  icache_bid;
    wire [ 1: 0]  icache_bresp;
    wire          icache_bvalid;
    wire          icache_bready;

    wire          icache_bus_en;
    wire [ 3: 0]  icache_bus_wen;
    wire [31: 0]  icache_bus_addr;
    wire [31: 0]  icache_bus_rdata;
    wire [31: 0]  icache_bus_wdata;
    wire          icache_bus_streq;
    wire          icache_bus_stall;
    wire          icache_bus_cached;
 
    wire [ 3: 0]  icache_status_out;
    wire          icache_axi_stall;
    wire          icache_stall;
    

    wire  [ 3: 0] dcache_arid;
    wire  [31: 0] dcache_araddr;
    wire  [ 3: 0] dcache_arlen;
    wire  [ 2: 0] dcache_arsize;
    wire  [ 1: 0] dcache_arburst;
    wire  [ 1: 0] dcache_arlock;
    wire  [ 3: 0] dcache_arcache;
    wire  [ 2: 0] dcache_arprot;                
    wire          dcache_arvalid;
    wire          dcache_arready;
    wire  [ 3: 0] dcache_rid;
    wire  [31: 0] dcache_rdata;
    wire  [ 1: 0] dcache_rresp;
    wire          dcache_rlast;
    wire          dcache_rvalid;
    wire          dcache_rready;
    wire  [ 3: 0] dcache_awid;
    wire  [31: 0] dcache_awaddr;
    wire  [ 3: 0] dcache_awlen;
    wire  [ 2: 0] dcache_awsize;
    wire  [ 1: 0] dcache_awburst;
    wire  [ 1: 0] dcache_awlock;
    wire  [ 3: 0] dcache_awcache;
    wire  [ 2: 0] dcache_awprot;
    wire          dcache_awvalid;
    wire          dcache_awready;
    wire  [ 3: 0] dcache_wid;
    wire  [31: 0] dcache_wdata;
    wire  [ 3: 0] dcache_wstrb;
    wire          dcache_wlast;
    wire          dcache_wvalid;
    wire          dcache_wready;
    wire [ 3: 0]  dcache_bid;
    wire [ 1: 0]  dcache_bresp;
    wire          dcache_bvalid;
    wire          dcache_bready;

    wire          dcache_bus_en;
    wire [ 3: 0]  dcache_bus_wen;
    wire [31: 0]  dcache_bus_addr;
    wire [31: 0]  dcache_bus_rdata;
    wire [ 1: 0]  dcache_bus_store_size;
    wire [ 1: 0]  dcache_bus_load_size;
    wire [31: 0]  dcache_bus_wdata;
    wire          dcache_bus_streq;
    wire          dcache_bus_stall;
    wire          dcache_bus_cached;

    wire [`DCACHE_STATS]  dcache_status_out; 
    wire                  dcache_axi_stall;
    wire                  dcache_cache_stall;
    wire                  ibus_stall;
    //wire                  dbus_stall;

    wire                  ibus_cached;
    wire [31: 0]          icache_virtual_addr_i;
    wire                  icache_axi_req_i;
    wire [31: 0]          icache_axi_addr_i;
    wire                  icache_axi_rend;
    wire [`WayBus]        icache_axi_data_o;
    wire [31: 0]          icache_rdata_o;
    wire                  icache_data_valid;
    wire [31: 0]          ic_req_addr_in;

    wire                  dcache_active;//dcache is working
    wire                  cpu_if_valid_o;


//dcache axi
    wire                  dbus_cached;
    wire                  uncache_req;
    wire [31: 0]          dcache_phy_addr_i;
    wire [31: 0]          dcache_vir_addr_i;
    wire                  dcache_axi_rend;
    wire [`WayBus]        dcache_axi_data_o;
    wire [31: 0]          dcache_rdata_o;
    wire                  dcache_data_valid;
    wire                  cpu_mem_valid_o;
    wire [31: 0]          dc_req_addr_in;
    wire [31: 0]          dc_bus_addr_o;
    wire [31: 0]          dc_uc_data_i;
    wire [31: 0]          dc_bus_wdata_o;
    wire [ 3: 0]          dc_bus_wen_o;
    wire [ 1: 0]          dc_bus_store_size_o;
    wire [ 1: 0]          dc_bus_load_size_o;
//dcache
    wire                  uncache_wreq;
    wire                  uncache_rreq;
    wire                  cache_rreq;
    wire                  cache_wreq;
    wire                  dcache_stall;
    wire [`WayBus]        cacheline_wdata_o;

mycpu_core_top MY_TOP
(
  .clk              (aclk),
  .resetn           (aresetn),
  .ext_int          (ext_int),

  .icache_axi_stall     (icache_axi_stall),
  .icache_stall         (icache_stall),
  .dcache_stall         (dcache_stall),
  .ibus_stall       (ibus_stall),
  //.dbus_stall       (dbus_stall),

  //to/from icache
  .icache_bus_en    (icache_bus_en),
  .icache_bus_wen   (icache_bus_wen),
  .icache_bus_addr  (icache_bus_addr),
  .icache_bus_wdata (icache_bus_wdata),
  .icache_bus_rdata (icache_bus_rdata), //data from icache_axi

  .icache_inst      (icache_rdata_o),
  .icache_data_valid(icache_data_valid),
  .ibus_cached      (ibus_cached),
  .if_virtual_addr_o(icache_virtual_addr_i),
  .cpu_if_valid_o   (cpu_if_valid_o),

  .dcache_bus_en    (dcache_bus_en),
  .dcache_bus_wen   (dcache_bus_wen),
  .dcache_phy_addr  (dcache_phy_addr_i),
  .dcache_vir_addr  (dcache_vir_addr_i),
  .dcache_bus_wdata (dcache_bus_wdata),
  .dcache_bus_rdata (dcache_bus_rdata),
  .dcache_bus_store_size  (dcache_bus_store_size),
  .dcache_bus_load_size   (dcache_bus_load_size),

  .dbus_cached      (dbus_cached),
  .dbus_stall       (dbus_stall),
  .cpu_mem_valid_o  (cpu_mem_valid_o),

  .debug_wb_pc      (debug_wb_pc),
  .debug_wb_rf_wen  (debug_wb_rf_wen), 
  .debug_wb_rf_wnum (debug_wb_rf_wnum),
  .debug_wb_rf_wdata(debug_wb_rf_wdata)

);



icache_axi ICACHE_AXI
(
    .aclk                   (aclk),
    .aresetn                (aresetn),
    .arid                   (icache_arid),
    .araddr                 (icache_araddr),
    .arlen                  (icache_arlen),
    .arsize                 (icache_arsize),
    .arburst                (icache_arburst),
    .arlock                 (icache_arlock),
    .arcache                (icache_arcache),
    .arprot                 (icache_arprot),                
    .arvalid                (icache_arvalid),
    .arready                (icache_arready),
    .rid                    (icache_rid),
    .rdata                  (icache_rdata),
    .rresp                  (icache_rresp),
    .rlast                  (icache_rlast),
    .rvalid                 (icache_rvalid),
    .rready                 (icache_rready),
    .awid                   (icache_awid),
    .awaddr                 (icache_awaddr),
    .awlen                  (icache_awlen),
    .awsize                 (icache_awsize),
    .awburst                (icache_awburst),
    .awlock                 (icache_awlock),
    .awcache                (icache_awcache),
    .awprot                 (icache_awprot),
    .awvalid                (icache_awvalid),
    .awready                (icache_awready),
    .wid                    (icache_wid),
    .wdata                  (icache_wdata),
    .wstrb                  (icache_wstrb),
    .wlast                  (icache_wlast),
    .wvalid                 (icache_wvalid),
    .wready                 (icache_wready),
    .bid                    (icache_bid),
    .bresp                  (icache_bresp),
    .bvalid                 (icache_bvalid),
    .bready                 (icache_bready),
    
    .bus_en                 (icache_bus_en),
    .bus_wen                (icache_bus_wen),
    .bus_addr               (icache_bus_addr),
    .bus_rdata              (icache_bus_rdata),
    .bus_wdata              (icache_bus_wdata),
    .bus_stall              (ibus_stall),

    .status_in              (icache_status_out), 
    .req_addr_in            (ic_req_addr_in),
    .status_out             (icache_status_out), 
    .req_addr_out           (ic_req_addr_in),
    .icache_axi_stall       (icache_axi_stall),

    .bus_cached             (ibus_cached),
    .icache_axi_req_i       (icache_axi_req_i),
    .icache_axi_addr_i      (icache_axi_addr_i),   
    .dcache_active          (dcache_stall),
    .icache_axi_rend        (icache_axi_rend),
    .icache_axi_data_o      (icache_axi_data_o)
);


icache ICACHE
(
    .clk                    (aclk),
    .rst_n                  (aresetn),
     
    .cpu_rreq_i             (icache_bus_en),
    .cpu_cached_i           (ibus_cached),
    .cpu_virtual_addr_i     (icache_virtual_addr_i),
    .cpu_physical_addr_i    (icache_bus_addr),
    .cpu_bus_stall_i        (ibus_stall),
    .cpu_if_valid_i         (cpu_if_valid_o),
    
    .rend                   (icache_axi_rend),
    .cacheline_rdata_i      (icache_axi_data_o),
    
    .icache_rreq_o          (icache_axi_req_i),
    .icache_raddr_o         (icache_axi_addr_i),
    
    .cpu_stall_o            (icache_stall),
    .icache_rdata_o         (icache_rdata_o),
    .icache_data_valid      (icache_data_valid)                          
);

dcache_axi DCACHE_AXI
(
    .aclk                    (aclk),
    .aresetn                 (aresetn),
    .arid                    (dcache_arid),
    .araddr                  (dcache_araddr),
    .arlen                   (dcache_arlen),
    .arsize                  (dcache_arsize),
    .arburst                 (dcache_arburst),
    .arlock                  (dcache_arlock),
    .arcache                 (dcache_arcache),
    .arprot                  (dcache_arprot),
    .arvalid                 (dcache_arvalid),
    .arready                 (dcache_arready),
    .rid                     (dcache_rid),
    .rdata                   (dcache_rdata),
    .rresp                   (dcache_rresp),
    .rlast                   (dcache_rlast),
    .rvalid                  (dcache_rvalid),
    .rready                  (dcache_rready),
    .awid                    (dcache_awid),
    .awaddr                  (dcache_awaddr),
    .awlen                   (dcache_awlen),
    .awsize                  (dcache_awsize),
    .awburst                 (dcache_awburst),
    .awlock                  (dcache_awlock),
    .awcache                 (dcache_awcache),
    .awprot                  (dcache_awprot),
    .awvalid                 (dcache_awvalid),
    .awready                 (dcache_awready),
    .wid                     (dcache_wid),
    .wdata                   (dcache_wdata),
    .wstrb                   (dcache_wstrb),
    .wlast                   (dcache_wlast),
    .wvalid                  (dcache_wvalid),
    .wready                  (dcache_wready),
    .bid                     (dcache_bid),
    .bresp                   (dcache_bresp),
    .bvalid                  (dcache_bvalid),
    .bready                  (dcache_bready),

    .uc_wen                  (dc_bus_wen_o),
    .cache_addr              (dc_bus_addr_o),
    .bus_rdata               (dc_uc_data_i),
    .bus_wdata               (dc_bus_wdata_o),
    .bus_store_size          (dc_bus_store_size_o),
    .bus_load_size           (dc_bus_load_size_o),

    .ca_rreq_i               (cache_rreq),
    .ca_wreq_i               (cache_wreq),
    .uc_rreq_i               (uncache_rreq),
    .uc_wreq_i               (uncache_wreq),
    .cacheline_wdata_i       (cacheline_wdata_o),

    .dcache_axi_rend         (dcache_axi_rend),
    .dcache_axi_wend         (dcache_axi_wend),
    .dcache_axi_data_o       (dcache_axi_data_o),

    .status_in               (dcache_status_out), 
    .status_out              (dcache_status_out),
    .req_addr_in             (dc_req_addr_in),
    .req_addr_out            (dc_req_addr_in), 
    .dcache_axi_stall        (dcache_axi_stall)

);

dcache DCACHE
(
     .clk                       (aclk),
     .rst_n                     (aresetn),
    
     .dc_bus_en_i               (dcache_bus_en),
     .dc_bus_wen_i              (dcache_bus_wen),
     .dc_bus_viraddr_i          (dcache_vir_addr_i),
     .dc_bus_phyaddr_i          (dcache_phy_addr_i),
     .dc_bus_wdata_i            (dcache_bus_wdata),
     .dc_bus_store_size_i       (dcache_bus_store_size),
     .dc_bus_load_size_i        (dcache_bus_load_size),
            
     .cpu_cached_i              (dbus_cached),
     .cpu_bus_stall_i           (dbus_stall),
     .cpu_mem_valid_i           (cpu_mem_valid_o),
    
     .rend                      (dcache_axi_rend),
     .wend                      (dcache_axi_wend),
     .cacheline_rdata_i         (dcache_axi_data_o),
     .dc_uc_data_i              (dc_uc_data_i),
    
     .dc_bus_wen_o              (dc_bus_wen_o),
     .dc_bus_addr_o             (dc_bus_addr_o),
     .dc_bus_wdata_o            (dc_bus_wdata_o),
     .dc_bus_store_size_o       (dc_bus_store_size_o),
     .dc_bus_load_size_o        (dc_bus_load_size_o),

     .uncache_wreq              (uncache_wreq),
     .uncache_rreq              (uncache_rreq),
     .cache_rreq                (cache_rreq),
     .cache_wreq                (cache_wreq),

     .cacheline_wdata_o         (cacheline_wdata_o),

     .dcache_stall_o            (dcache_cache_stall),
     .dcache_rdata_o            (dcache_bus_rdata),
     .dcache_data_valid         (dcache_data_valid)
    );

    assign dcache_stall = dcache_axi_stall | dcache_cache_stall;

AXI_2x1 Bus_Interface (
        .aclk             ( aclk        ),                 
        .aresetn          ( aresetn       ),
        
        .s_axi_arid       ( {icache_arid   ,dcache_arid   } ),
        .s_axi_araddr     ( {icache_araddr ,dcache_araddr } ),
        .s_axi_arlen      ( {icache_arlen  ,dcache_arlen  } ),
        .s_axi_arsize     ( {icache_arsize ,dcache_arsize } ),
        .s_axi_arburst    ( {icache_arburst,dcache_arburst} ),
        .s_axi_arlock     ( {icache_arlock ,dcache_arlock } ),
        .s_axi_arcache    ( {icache_arcache,dcache_arcache} ),
        .s_axi_arprot     ( {icache_arprot ,dcache_arprot } ),
        .s_axi_arqos      ( 0                               ),
        .s_axi_arvalid    ( {icache_arvalid,dcache_arvalid} ),
        .s_axi_arready    ( {icache_arready,dcache_arready} ),
        .s_axi_rid        ( {icache_rid    ,dcache_rid    } ),
        .s_axi_rdata      ( {icache_rdata  ,dcache_rdata  } ),
        .s_axi_rresp      ( {icache_rresp  ,dcache_rresp  } ),
        .s_axi_rlast      ( {icache_rlast  ,dcache_rlast  } ),
        .s_axi_rvalid     ( {icache_rvalid ,dcache_rvalid } ),
        .s_axi_rready     ( {icache_rready ,dcache_rready } ),
        .s_axi_awid       ( {icache_awid   ,dcache_awid   } ),
        .s_axi_awaddr     ( {icache_awaddr ,dcache_awaddr } ),
        .s_axi_awlen      ( {icache_awlen  ,dcache_awlen  } ),
        .s_axi_awsize     ( {icache_awsize ,dcache_awsize } ),
        .s_axi_awburst    ( {icache_awburst,dcache_awburst} ),
        .s_axi_awlock     ( {icache_awlock ,dcache_awlock } ),
        .s_axi_awcache    ( {icache_awcache,dcache_awcache} ),
        .s_axi_awprot     ( {icache_awprot ,dcache_awprot } ),
        .s_axi_awqos      ( 0                               ),
        .s_axi_awvalid    ( {icache_awvalid,dcache_awvalid} ),
        .s_axi_awready    ( {icache_awready,dcache_awready} ),
        .s_axi_wid        ( {icache_wid    ,dcache_wid    } ),
        .s_axi_wdata      ( {icache_wdata  ,dcache_wdata  } ),
        .s_axi_wstrb      ( {icache_wstrb  ,dcache_wstrb  } ),
        .s_axi_wlast      ( {icache_wlast  ,dcache_wlast  } ),
        .s_axi_wvalid     ( {icache_wvalid ,dcache_wvalid } ),
        .s_axi_wready     ( {icache_wready ,dcache_wready } ),
        .s_axi_bid        ( {icache_bid    ,dcache_bid    } ),
        .s_axi_bresp      ( {icache_bresp  ,dcache_bresp  } ),
        .s_axi_bvalid     ( {icache_bvalid ,dcache_bvalid } ),
        .s_axi_bready     ( {icache_bready ,dcache_bready } ),
        
        .m_axi_arid       ( arid        ),
        .m_axi_araddr     ( araddr      ),
        .m_axi_arlen      ( arlen       ),
        .m_axi_arsize     ( arsize      ),
        .m_axi_arburst    ( arburst     ),
        .m_axi_arlock     ( arlock      ),
        .m_axi_arcache    ( arcache     ),
        .m_axi_arprot     ( arprot      ),
        .m_axi_arqos      (             ),
        .m_axi_arvalid    ( arvalid     ),
        .m_axi_arready    ( arready     ),
        .m_axi_rid        ( rid         ),
        .m_axi_rdata      ( rdata       ),
        .m_axi_rresp      ( rresp       ),
        .m_axi_rlast      ( rlast       ),
        .m_axi_rvalid     ( rvalid      ),
        .m_axi_rready     ( rready      ),
        .m_axi_awid       ( awid        ),
        .m_axi_awaddr     ( awaddr      ),
        .m_axi_awlen      ( awlen       ),
        .m_axi_awsize     ( awsize      ),
        .m_axi_awburst    ( awburst     ),
        .m_axi_awlock     ( awlock      ),
        .m_axi_awcache    ( awcache     ),
        .m_axi_awprot     ( awprot      ),
        .m_axi_awqos      (             ),
        .m_axi_awvalid    ( awvalid     ),
        .m_axi_awready    ( awready     ),
        .m_axi_wid        ( wid         ),
        .m_axi_wdata      ( wdata       ),
        .m_axi_wstrb      ( wstrb       ),
        .m_axi_wlast      ( wlast       ),
        .m_axi_wvalid     ( wvalid      ),
        .m_axi_wready     ( wready      ),
        .m_axi_bid        ( bid         ),
        .m_axi_bresp      ( bresp       ),
        .m_axi_bvalid     ( bvalid      ),
        .m_axi_bready     ( bready      )
    );

endmodule