`include "../defines.v"

module mycpu_core_top
(
  input wire                clk,
  input wire                resetn,
  input wire  [ 5: 0]       ext_int,

  input wire                 icache_stall,
  input wire                 dcache_stall,
  input wire                 icache_ask,
  output wire                ibus_stall,
  //output wire                dbus_stall,

  //to/from icache
  output wire                icache_bus_en,
  output wire [ 3: 0]        icache_bus_wen,
  output wire [31: 0]        icache_bus_addr,
  output wire [31: 0]        icache_bus_wdata,
  input  wire [31: 0]        icache_bus_rdata, 

  //to/from dcache
  output wire                dcache_bus_en,
  output wire [ 3: 0]        dcache_bus_wen,
  output wire [31: 0]        dcache_bus_addr,
  output wire [31: 0]        dcache_bus_wdata,
  input  wire [31: 0]        dcache_bus_rdata,
  output wire [ 1: 0]        dcache_bus_store_size,
  output wire [ 1: 0]        dcache_bus_load_size,

  //debug
  output wire [31: 0]        debug_wb_pc,
  output wire [ 3: 0]        debug_wb_rf_wen, //write regfile enable
  output wire [ 4: 0]        debug_wb_rf_wnum,//dest reg id
  output wire [31: 0]        debug_wb_rf_wdata

);

//if stage signals
wire         if_branch_en;
wire [31: 0] branch_pc_i;
wire [31: 0] flush_pc_i;
wire [31: 0] if_inst_i;
wire         if_in_delay_slot_i;
wire [31: 0] if_pc_i;
wire [`ExcE] if_excs_o;
wire         if_has_exc_o;
wire [31: 0] if_bus_vaddr;
wire         if_pcvalid_o;


//id stage signals
wire [31: 0] id_pc_i;
wire [31: 0] id_inst_i;
wire         id_inslot_i;
wire         id_ex_res_as1_i;
wire         id_ex_res_as2_i;
wire [31: 0] id_res_from_ex_i;
wire [31: 0] raw_data1_i;
wire [31: 0] raw_data2_i;

wire [31: 0] id_reg1data_i;
wire [31: 0] id_reg2data_i;
wire [`ExcE] id_excs_o;
wire         id_has_exc_o;
wire         id_ov_inst_o;
wire [ 5: 0] id_intr_o;
wire         id_c0wen_o;
wire         id_c0ren_o;
wire [ 7: 0] id_c0addr_o;
wire         id_is_branch_o;
wire         id_pcvalid_o;

//ex stage signals
wire [31: 0] ex_inst_i;
wire         ex_inslot_i;
wire [31: 0] ex_pc_i;
wire [31: 0] ex_opr1_i;
wire [31: 0] ex_opr2_i;
wire [ 3: 0] ex_wren_i;
wire [ 4: 0] ex_waddr_i;
wire [31: 0] ex_rtvalue_i;
wire         ex_divinst_i;
wire         ex_mduinst_i;
wire [31: 0] ex_offset_i;
wire         ex_nofwd_i;
wire         ex_storeinst_o;

wire [`AOP]  ex_aluop_i;
wire [`MDOP] ex_mduop_i;
wire [`MMOP] ex_memop_i;
wire [`TOP]  ex_tlbop_i;
wire [`COP]  ex_cacheop_i;

wire [31: 0] ex_alures_i;
wire         ex_aluov_i;
wire         ex_c0wen_o;
wire         ex_c0ren_o;
wire [ 7: 0] ex_c0addr_o;
wire [31: 0] ex_c0_wdata_o;
wire         ex_ov_inst_i;
wire [`ExcE] ex_excs_o;
wire [ 5: 0] ex_intr_o;
wire [31: 0] ex_bus_vaddr;
wire         ex_pcvalid_o;

//to alu
wire [31: 0] opr1;
wire [31: 0] opr2;
wire [`AOP]  alu_op;

//to mdu
wire [`MDOP]  mduop_i;
wire [31: 0]  mdu_whi_in;
wire [31: 0]  mdu_wlo_in;
wire [31: 0]  mdu_opr1_i;
wire [31: 0]  mdu_opr2_i;

wire [31: 0]  ex_bad_memaddr_o;
wire          hi_wen;
wire [31: 0]  hi_o;
wire          lo_wen;
wire [31: 0]  lo_o;
wire          is_active;
wire          mdu_div_active;

//mem stage signals
wire [ 1: 0] mem_memaddr_low_i;
wire         mem_nofwd_i;
wire         mem_inst_load_i;
wire [31: 0] mem_inst_i;
wire [31: 0] mem_pc_i;
wire         mem_inslot_i;
wire [`MMOP] mem_memop_i;
wire [31: 0] mem_c0data_i;

wire [ 4: 0] mem_waddr_i;
wire [31: 0] mem_wdata_i;
wire [ 3: 0] mem_wren_i;

//writeback stage signals
wire [`MMOP] wb_memop_i;
wire [ 3: 0] wb_wren_i;
wire [ 4: 0] wb_waddr_i;
wire [31: 0] wb_wdata_i;
wire         wb_mduinst_i;

wire [31: 0] wb_pc_i;
wire [31: 0] wb_mem_addr_i;
wire [31: 0] wb_mem_data_i;
wire [31: 0] wb_inst_i;

wire [31: 0] wb_hi_i;
wire [31: 0] wb_lo_i;
wire         wb_whien_i;
wire         wb_wloen_i;
wire         wb_inst_mfhi_i;
wire         wb_inst_mflo_i;
wire         mdu_s2_stallreq_o;

//to regfile
wire         rf_ren1_i;
wire         rf_ren2_i;
wire [ 4: 0] rf_raddr1_i;
wire [ 4: 0] rf_raddr2_i;

wire [ 3: 0] rf_wren;
wire [ 4: 0] rf_waddr;
wire [31: 0] rf_wdata;

wire         rf_ex_nofwd;
wire         rf_mem_nofwd;

wire [31: 0] ex_wdata_bp;
wire [31: 0] mem_wdata_bp;

//to control
wire        streq_pc_i; 
wire        streq_id_i;
wire        streq_ex_i;
wire        streq_mem_i;
wire        streq_wb_i;
wire        exc_flag;

wire        stall_pc_o;
//wire        stall_pre_pc_o;
wire        stall_id_o;
wire        stall_ex_o;
wire        stall_mem_o;
wire        stall_wb_o;

wire        flush_pc_o;
wire        flush_id_o;
wire        flush_ex_o;
wire        flush_mem_o;
wire        flush_wb_o;

//to hilo
wire [31: 0] whidata;
wire [31: 0] wlodata;
wire         whien;
wire         wloen;

wire [31: 0] hilo_hi_o;
wire [31: 0] hilo_lo_o;

//exceptions
 wire  [31: 0]  exc_EPC_i;
 wire  [31: 0]  exc_ErrorEPC_i;//from cp0

 wire           exc_intr_i;//中断信号，来自cp0

 wire          exc_flag_o;//确认发生异常/中断
 wire [`ExcT]  exc_type_o;//异常类型
 wire [31: 0]  exc_baddr_o;
 wire [ 1: 0]  exc_cpun_o;


// module declaration
pc PC
(
  .clk                (clk                ),
  .rst_n              (resetn             ),
  .pc_flush_i         (exc_flag           ),
  .if_flush_i         (flush_id_o         ),     
  .if_stall_i         (stall_pc_o         ), 
  .icache_ask         (icache_ask         ), 
  .icache_stall       (icache_stall       ),   
  .branch_en          (if_branch_en       ),

  .flush_pc_i         (flush_pc_i         ),
  .branch_pc_i        (branch_pc_i        ),
  .inst_i             (icache_bus_rdata    ),     
  .if_inslot_i        (if_in_delay_slot_i ),
  .if_pc_i            (if_pc_i            ),

  .inst_sram_en       (icache_bus_en       ),  
  .if_pc_o            (id_pc_i            ),    
  .if_next_pc_o       (if_bus_vaddr        ), 
  .if_inst_o          (id_inst_i          ),    
  .if_inslot_o        (id_inslot_i        ),
  .if_excs_o          (if_excs_o          ),
  .if_has_exc_o       (if_has_exc_o       ),
  .next_pc_o          (if_pc_i            ),

  .inst_sram_wen      (icache_bus_wen      ),
  .inst_sram_wdata    (icache_bus_wdata    ),
  .pc_pcvalid_o       (if_pcvalid_o)
);

mmu IMMU
(
  .en       (icache_bus_en),
  .vaddr    (if_bus_vaddr),
  .paddr    (icache_bus_addr)
);

decoder DECODER
(
  .clk                (clk                ),
  .rst_n              (resetn             ),
  .if_flush_i         (flush_id_o         ),
  .id_flush_i         (flush_ex_o         ),
  .id_stall_i         (stall_id_o         ), 

  .id_pc_i            (id_pc_i            ),
  .id_inst_i          (id_inst_i          ),
  .id_inslot_i        (id_inslot_i        ),


  .id_reg1data_i      (id_reg1data_i      ),
  .id_reg2data_i      (id_reg2data_i      ),

  .id_excs_i          (if_excs_o          ),
  .id_has_exc_i       (if_has_exc_o       ),

  .id_branch_en_o     (if_branch_en       ),
  .id_branch_pc_o     (branch_pc_i        ),
  .id_next_inslot_o   (if_in_delay_slot_i ),

  .id_inst_o          (ex_inst_i          ),
  .id_inslot_o        (ex_inslot_i        ),
  .id_nofwd_o         (ex_nofwd_i         ),

  .id_reg1addr_o      (rf_raddr1_i        ),
  .id_reg2addr_o      (rf_raddr2_i        ), 
  .id_ren1_o          (rf_ren1_i          ),
  .id_ren2_o          (rf_ren2_i          ), 
  

  .id_pc_o            (ex_pc_i            ),
  .id_opr1_o          (ex_opr1_i          ),
  .id_opr2_o          (ex_opr2_i          ),
  .id_offset_o        (ex_offset_i        ),
  .id_divinst_o       (ex_divinst_i       ),
  .id_mduinst_o       (ex_mduinst_i       ),

  .id_wren_o          (ex_wren_i          ),
  .id_waddr_o         (ex_waddr_i         ),
  .id_rtvalue_o       (ex_rtvalue_i       ),
  .id_excs_o          (id_excs_o          ),
  .id_has_exc_o       (id_has_exc_o       ),
  .id_ov_inst_o       (ex_ov_inst_i       ),

  .id_aluop_o         (ex_aluop_i         ),
  .id_mduop_o         (ex_mduop_i         ),
  .id_memop_o         (ex_memop_i         ),
  .id_tlbop_o         (ex_tlbop_i         ),
  .id_cacheop_o       (ex_cacheop_i       ),

  .id_c0wen_o         (id_c0wen_o         ),
  .id_c0ren_o         (id_c0ren_o         ),
  .id_c0addr_o        (id_c0addr_o        ),

  .id_stallreq_o      (                   ),

  .id_is_branch_o     (id_is_branch_o     ),
  .id_res_from_ex_i   (id_res_from_ex_i   ),
  .id_ex_res_as1_i    (id_ex_res_as1_i    ),
  .id_ex_res_as2_i    (id_ex_res_as2_i    ),

  .raw_data1_i        (raw_data1_i),
  .raw_data2_i        (raw_data2_i),
  .id_pcvalid_i       (if_pcvalid_o),
  .id_pcvalid_o       (id_pcvalid_o)
);

regfile REGFILE
(
  .clk                (clk                ),
  .rst_n              (resetn             ),

  .ren1               (rf_ren1_i          ),
  .ren2               (rf_ren2_i          ),
  .raddr1             (rf_raddr1_i        ),
  .raddr2             (rf_raddr2_i        ),
  .rdata1             (id_reg1data_i      ),
  .rdata2             (id_reg2data_i      ),
 
  .we                 (rf_wren            ),
  .waddr              (rf_waddr           ),
  .wdata              (rf_wdata           ),

  .ex_wen             (ex_wren_i          ),
  .ex_waddr           (ex_waddr_i         ),
  .ex_wdata           (ex_wdata_bp        ),
  .mem_wen            (mem_wren_i         ),
  .mem_waddr          (mem_waddr_i        ),
  .mem_wdata          (mem_wdata_bp       ),


  .ex_nofwd           (rf_ex_nofwd        ),
  .mem_nofwd          (rf_mem_nofwd       ),
  .stallreq           (streq_id_i         ),

  .id_is_branch       (id_is_branch_o     ),
  .ex_data_to_id_o    (id_res_from_ex_i),
  .id_ex_res_as1_o    (id_ex_res_as1_i),
  .id_ex_res_as2_o    (id_ex_res_as2_i),
  .raw_data1_o        (raw_data1_i),
  .raw_data2_o        (raw_data2_i)
);

execute EXECUTE
(
  .clk                (clk                ),
  .rst_n              (resetn             ),
  .ex_flush_i         (flush_mem_o        ),    
  .ex_stall_i         (stall_ex_o         ),

  .ex_inst_i          (ex_inst_i          ),
  .ex_inslot_i        (ex_inslot_i        ),
  .ex_pc_i            (ex_pc_i            ),
  .ex_opr1_i          (ex_opr1_i          ),
  .ex_opr2_i          (ex_opr2_i          ),
  .ex_wren_i          (ex_wren_i          ),
  .ex_waddr_i         (ex_waddr_i         ),
  .ex_offset_i        (ex_offset_i        ),
  .ex_nofwd_i         (ex_nofwd_i         ),
  .ex_rtvalue_i       (ex_rtvalue_i       ),
  .ex_divinst_i       (ex_divinst_i       ),
  .ex_mduinst_i       (ex_mduinst_i       ),
  .ex_excs_i          (id_excs_o          ),
  .ex_has_exc_i       (id_has_exc_o       ),
  .ex_ov_inst_i       (ex_ov_inst_i       ),

  .ex_aluop_i         (ex_aluop_i         ),
  .ex_mduop_i         (ex_mduop_i         ),
  .ex_memop_i         (ex_memop_i         ),
  .ex_tlbop_i         (ex_tlbop_i         ),
  .ex_cacheop_i       (ex_cacheop_i       ),

  .ex_alures_i        (ex_alures_i        ),
  .ex_aluov_i         (ex_aluov_i         ),

  .ex_c0wen_i         (id_c0wen_o         ),
  .ex_c0ren_i         (id_c0ren_o         ),
  .ex_c0addr_i        (id_c0addr_o        ),          

  .mdu_is_active      (is_active          ),
  .mdu_div_active     (mdu_div_active     ),

  .ex_wren_o          (mem_wren_i         ),
  .ex_waddr_o         (mem_waddr_i        ),
  .ex_wdata_o         (mem_wdata_i        ),
  .ex_nofwd_o         (mem_nofwd_i        ),
    
  .ex_aluop_o         (alu_op             ),
  .ex_memop_o         (mem_memop_i        ),
  .ex_opr1_o          (opr1               ),
  .ex_opr2_o          (opr2               ),

  .ex_mdu_opr1_o      (mdu_opr1_i),
  .ex_mdu_opr2_o      (mdu_opr2_i),
  .ex_mduop_o         (mduop_i),
  .ex_mdu_whi_o       (mdu_whi_in),
  .ex_mdu_wlo_o       (mdu_wlo_in),

  .ex_memen_o         (dcache_bus_en       ),   
  .ex_memwen_o        (dcache_bus_wen      ),   
  .ex_memaddr_o       (ex_bus_vaddr        ), 
  .ex_memwdata_o      (dcache_bus_wdata    ),
  .ex_bus_store_size  (dcache_bus_store_size     ),
  .ex_bus_load_size  (dcache_bus_load_size),
  .ex_storeinst_o     (ex_storeinst_o     ), 
  .ex_bad_memaddr_o   (ex_bad_memaddr_o   ), 

  .ex_inst_o          (mem_inst_i         ),
  .ex_inslot_o        (mem_inslot_i       ),
  .ex_stallreq_o      (streq_ex_i         ),
  .ex_pc_o            (mem_pc_i           ),
  .ex_inst_load_o     (mem_inst_load_i    ),
  .ex_memaddr_low_o   (mem_memaddr_low_i  ),
  .ex_excs_o          (ex_excs_o          ),
  .ex_c0wen_o         (ex_c0wen_o         ),
  .ex_c0ren_o         (ex_c0ren_o         ),
  .ex_c0addr_o        (ex_c0addr_o        ),
  .ex_c0_wdata_o      (ex_c0_wdata_o      ),

  .ex_wdata_bp_o      (ex_wdata_bp        ),
  .ex_nofwd_bp_o      (rf_ex_nofwd        ),
  .ex_pcvalid_i       (id_pcvalid_o),
  .ex_pcvalid_o       (ex_pcvalid_o)
);

mmu DMMU
(
  .en       (dcache_bus_en),
  .vaddr    (ex_bus_vaddr),
  .paddr    (dcache_bus_addr)
);

alu ALU
(
  .opr1               (opr1               ),
  .opr2               (opr2               ),
  .alu_op             (alu_op             ),
  .alu_res            (ex_alures_i        ),
  .ov                 (ex_aluov_i         )
);

mdu MDU
(
  .clk                (clk),
  .rst_n              (resetn),
  .mduop_i            (mduop_i),
  .mdu_s1_stall_i     (stall_ex_o),
  .mdu_s1_flush_i     (flush_mem_o),
  .mdu_s2_stall_i     (stall_mem_o),
  .mdu_s2_flush_i     (flush_wb_o),
  .mdu_opr1_in        (mdu_opr1_i),
  .mdu_opr2_in        (mdu_opr2_i),
  .mdu_whi_in         (mdu_whi_in),
  .mdu_wlo_in         (mdu_wlo_in),

  .mdu_hi_i           (hilo_hi_o),
  .mdu_lo_i           (hilo_lo_o),

  
  .hi_wen             (wb_whien_i),
  .hi_o               (wb_hi_i),
  .lo_wen             (wb_wloen_i),
  .lo_o               (wb_lo_i),
  .is_active          (is_active),
  .mdu_div_active     (mdu_div_active),
  .inst_mfhi_o        (wb_inst_mfhi_i),
  .inst_mflo_o        (wb_inst_mflo_i),

  .mdu_s2_stallreq_o  (mdu_s2_stallreq_o)
);

exception EXC
(
  .exc_pc_i           (mem_pc_i),//进入PC
  .exc_mem_en_i       (ex_storeinst_o),//当前有写请求
  .exc_m_addr_i       (ex_bad_memaddr_o),
  .exc_EPC_i          (exc_EPC_i),
  .exc_ErrorEPC_i     (exc_ErrorEPC_i),//from cp0
  .exc_excs_i         (ex_excs_o),//异常向量
  .exc_pcvalid_i      (ex_pcvalid_o),

  .exc_intr_i         (exc_intr_i),//中断信号，来自cp0

  .exc_flag_o         (exc_flag),//确认发生异常/中断
  .exc_type_o         (exc_type_o),//异常类型
  .exc_baddr_o        (exc_baddr_o),
  .exc_cpun_o         (exc_cpun_o),
  .flush_pc_o         (flush_pc_i)
);

cp0 CP0
(
  .clk                (clk),
  .rst_n              (resetn),
  .cp0_intr_i         (ext_int),//外部中断
  .cp0_addr_i         (ex_c0addr_o),//地址
  .cp0_ren_i          (ex_c0ren_o),//读使�?
  .cp0_wdata_i        (ex_c0_wdata_o),//写数�?
  .cp0_wen_i          (ex_c0wen_o),//写使�?

  .cp0_pc_i           (mem_pc_i),//异常指令对应的pc
  .cp0_exc_flag_i     (exc_flag),//标记发生异常
  .cp0_exc_type_i     (exc_type_o),//标记异常类型
  .cp0_baddr_i        (exc_baddr_o),//来自Exceptions，地�?异常的地�?
  .cp0_cpun_i         (), //来自Exceptions，协处理器缺失异�?
  .cp0_inslot_i       (mem_inslot_i),
  //.cp0_issave_i       (),//当前指令写内存，来自MEM

  .cp0_rdata_o        (mem_c0data_i),//读出数据
  .Status_o           (),
  .Cause_o            (),
  .EPC_o              (exc_EPC_i),
  .Config_o           (),
  .ErrorEPC_o         (),
  .exc_intr           (exc_intr_i)//标记产生中断
);

mem MEM
(
  .clk                (clk),
  .rst_n              (resetn),

  .mem_memdata_i      (dcache_bus_rdata),  

  .mem_inst_i         (mem_inst_i),
  .mem_pc_i           (mem_pc_i),
  .mem_inslot_i       (mem_inslot_i),
  .mem_memop_i        (mem_memop_i),
  .mem_memaddr_low_i  (mem_memaddr_low_i),

  .mem_waddr_i        (mem_waddr_i),
  .mem_wdata_i        (mem_wdata_i),
  .mem_c0_ren_i       (ex_c0ren_o),
  .mem_c0data_i       (mem_c0data_i),
  .mem_wren_i         (mem_wren_i),
  .mem_nofwd_i        (mem_nofwd_i),
  .mem_inst_load_i    (mem_inst_load_i),

  .mem_stall_i        (stall_mem_o),
  .mem_flush_i        (flush_wb_o ),  

  .mem_s2_stallreq_i  (mdu_s2_stallreq_o),
  .mem_inst_o         (wb_inst_i),
  .mem_inslot_o       (),

  .mem_waddr_o        (wb_waddr_i),
  .mem_wdata_o        (wb_wdata_i),
  .mem_wren_o         (wb_wren_i),
  .mem_pc_o           (wb_pc_i),

  .mem_wdata_bp       (mem_wdata_bp),
  .mem_nofwd_bp       (rf_mem_nofwd),
  .mem_stall_o        (streq_mem_i)

);


writeback WRITEBACK
(
  .clk                (clk),
  .rst_n              (resetn),
  .wb_stall_i         (stall_wb_o),
  .wb_flush_i         (flush_wb_o),

  .wb_memop_i         (wb_memop_i),
  .wb_wren_i          (wb_wren_i),
  .wb_waddr_i         (wb_waddr_i),
  .wb_wdata_i         (wb_wdata_i),
  .wb_inst_i          (wb_inst_i),

  .wb_pc_i            (wb_pc_i),

  .wb_mem_addr_i      (wb_mem_addr_i),
  .wb_mem_data_i      (wb_mem_data_i),

  .wb_hi_i            (wb_hi_i),
  .wb_lo_i            (wb_lo_i),
  .wb_whien_i         (wb_whien_i),
  .wb_wloen_i         (wb_wloen_i),
  .wb_inst_mfhi_i     (wb_inst_mfhi_i),
  .wb_inst_mflo_i     (wb_inst_mflo_i),

  .wb_wren_o          (rf_wren),
  .wb_waddr_o         (rf_waddr),
  .wb_wdata_o         (rf_wdata),
  .wb_stallreq        (streq_wb_i),

  .wb_whien_o         (whien),
  .wb_wloen_o         (wloen),
  .wb_hi_o            (whidata),
  .wb_lo_o            (wlodata),

  .debug_wb_pc        (debug_wb_pc),
  .debug_wb_rf_wen    (debug_wb_rf_wen),
  .debug_wb_rf_wnum   (debug_wb_rf_wnum),
  .debug_wb_rf_wdata  (debug_wb_rf_wdata)
);

control control
(
  .streq_pc_i         (icache_stall),
  .streq_id_i         (streq_id_i),
  .streq_ex_i         (streq_ex_i),
  .streq_mem_i        (streq_mem_i),
  .streq_wb_i         (streq_wb_i),
  .exc_flag           (exc_flag),
  .dcache_stall       (dcache_stall),

  .stall_pc_o         (stall_pc_o),
  .stall_id_o         (stall_id_o),
  .stall_ex_o         (stall_ex_o),
  .stall_mem_o        (stall_mem_o),
  .stall_wb_o         (stall_wb_o),

  .flush_pc_o         (flush_pc_o),
  .flush_id_o         (flush_id_o),
  .flush_ex_o         (flush_ex_o),
  .flush_mem_o        (flush_mem_o),
  .flush_wb_o         (flush_wb_o)

);

assign  ibus_stall = stall_pc_o;
// assign  ibus_stall = dcache_stall;
//assign  dbus_stall = stall_ex_o;

hilo HILO
(
  .clk                (clk),
  .rst_n              (resetn),
  .whidata            (whidata),
  .wlodata            (wlodata),
  .whien              (whien),
  .wloen              (wloen),

  .rhidata            (hilo_hi_o),
  .rlodata            (hilo_lo_o)
);

endmodule
