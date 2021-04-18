`include "../defines.v"

module mycpu_top
(
  input wire                clk,
  input wire                resetn,
  input wire  [ 5: 0]       ext_int,

  //to/from instmem
  output wire                inst_sram_en,
  output wire [ 3: 0]        inst_sram_wen,
  output wire [31: 0]        inst_sram_addr,
  output wire [31: 0]        inst_sram_wdata,
  input  wire [31: 0]        inst_sram_rdata,

  //to/from datamem
  output wire                data_sram_en,
  output wire [ 3: 0]        data_sram_wen,
  output wire [31: 0]        data_sram_addr,
  output wire [31: 0]        data_sram_wdata,
  input  wire [31: 0]        data_sram_rdata,

  //debug
  output wire [31: 0]        debug_wb_pc,
  output wire [ 3: 0]        debug_wb_rf_wen, //write regfile enable
  output wire [ 4: 0]        debug_wb_rf_wnum,//dest reg id
  output wire [31: 0]        debug_wb_rf_wdata

);

//if stage signals
wire         if_branch_en;
wire [31: 0] branch_pc_i;
wire [31: 0] if_inst_i;
wire         if_in_delay_slot_i;


//id stage signals
wire [31: 0] id_pc_i;
wire [31: 0] id_inst_i;
wire         id_inslot_i;

wire [31: 0] id_reg1data_i;
wire [31: 0] id_reg2data_i;

//ex stage signals
wire [31: 0] ex_inst_i;
wire         ex_inslot_i;
wire [31: 0] ex_pc_i;
wire [31: 0] ex_opr1_i;
wire [31: 0] ex_opr2_i;
wire         ex_wren_i;
wire [ 4: 0] ex_waddr_i;
wire [31: 0] ex_rtvalue_i;
wire [31: 0] ex_offset_i;
wire         ex_nofwd_i;

wire [`AOP]  ex_aluop_i;
wire [`MDOP] ex_mduop_i;
wire [`MMOP] ex_memop_i;
wire [`TOP]  ex_tlbop_i;
wire [`COP]  ex_cacheop_i;

wire [31: 0] ex_alures_i;
wire         ex_c0wen_i;
wire         ex_c0ren_i;
wire [ 7: 0] ex_c0addr_i;

//to alu
wire [31: 0] opr1;
wire [31: 0] opr2;
wire [`AOP]  alu_op;

//mem stage signals
wire [ 1: 0] mem_memaddr_low_i;
wire         mem_nofwd_i;
wire         mem_inst_load_i;
wire [31: 0] mem_inst_i;
wire [31: 0] mem_pc_i;
wire         mem_inslot_i;
wire [`MMOP] mem_memop_i;

wire [ 4: 0] mem_waddr_i;
wire [31: 0] mem_wdata_i;
wire         mem_wren_i;

//writeback stage signals
wire [`MMOP] wb_memop_i;
wire         wb_wen_i;
wire [31: 0] wb_waddr_i;
wire [31: 0] wb_wdata_i;

wire [31: 0] wb_pc_i;
wire [31: 0] wb_mem_addr_i;
wire [31: 0] wb_mem_data_i;
wire [31: 0] wb_inst_i;

//to regfile
wire         rf_ren1_i;
wire         rf_ren2_i;
wire [ 4: 0] rf_raddr1_i;
wire [ 4: 0] rf_raddr2_i;

wire         rf_wren;
wire         rf_waddr;
wire         rf_wdata;

wire         rf_ex_nofwd;
wire         rf_mem_nofwd;

wire [31: 0] ex_wdata_bp;
wire [31: 0] mem_wdata_bp;

// module declaration
pc PC
(
  .clk                (clk                ),
  .rst_n              (resetn             ),
  .if_flush_i         (0                  ),     
  .if_stall_i         (0                  ),     
  .branch_en          (if_branch_en       ),

  .flush_pc_i         (0                  ),
  .branch_pc_i        (branch_pc_i        ),
  .inst_i             (inst_sram_rdata    ),     
  .if_inslot_i        (if_in_delay_slot_i ),

  .inst_sram_en       (inst_sram_en       ),  
  .if_pc_o            (id_pc_i            ),    
  .if_next_pc_o       (inst_sram_addr     ), 
  .if_inst_o          (id_inst_i          ),    
  .if_inslot_o        (id_inslot_i        ),

  .inst_sram_wen      (inst_sram_wen      ),
  .inst_sram_wdata    (inst_sram_wdata    )
);

decoder DECODER
(
  .clk                (clk                ),
  .rst_n              (resetn             ),
  .id_flush_i         (0                  ),
  .id_stall_i         (0                  ), 

  .id_pc_i            (id_pc_i            ),
  .id_inst_i          (id_inst_i          ),
  .id_inslot_i        (id_inslot_i        ),


  .id_reg1data_i      (id_reg1data_i      ),
  .id_reg2data_i      (id_reg2data_i      ),


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

  .id_wren_o          (ex_wren_i          ),
  .id_waddr_o         (ex_waddr_i         ),
  .id_rtvalue_o       (ex_rtvalue_i       ),

  .id_aluop_o         (ex_aluop_i         ),
  .id_mduop_o         (ex_mduop_i         ),
  .id_memop_o         (ex_memop_i         ),
  .id_tlbop_o         (ex_tlbop_i         ),
  .id_cacheop_o       (ex_cacheop_i       ),

  .id_c0wen_o         (ex_c0wen_i         ),
  .id_c0ren_o         (ex_c0ren_i         ),
  .id_c0addr_o        (ex_c0addr_i        ),

  .id_stallreq_o      (                   )
);

regfile REGFILE
(
  .clk                (clk                ),

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
  .stallreq           (                   )
);

execute EXECUTE
(
  .clk                (clk                ),
  .rst_n              (resetn             ),
  .ex_flush_i         (0                  ),    
  .ex_stall_i         (0                  ),

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

  .ex_aluop_i         (ex_aluop_i         ),
  .ex_mduop_i         (ex_mduop_i         ),
  .ex_memop_i         (ex_memop_i         ),
  .ex_tlbop_i         (ex_tlbop_i         ),
  .ex_cacheop_i       (ex_cacheop_i       ),

  .ex_alures_i        (ex_alures_i        ),

  .ex_c0wen_i         (ex_c0wen_i         ),
  .ex_c0ren_i         (ex_c0ren_i         ),
  .ex_c0addr_i        (ex_c0addr_i        ),

    
  .ex_wren_o          (mem_wren_i         ),
  .ex_waddr_o         (mem_waddr_i        ),
  .ex_wdata_o         (mem_wdata_i        ),
  .ex_nofwd_o         (mem_nofwd_i        ),
    
  .ex_aluop_o         (alu_op             ),
  .ex_memop_o         (mem_memop_i        ),
  .ex_opr1_o          (opr1               ),
  .ex_opr2_o          (opr2               ),

  .ex_menen_o         (data_sram_en       ),   
  .ex_memwen_o        (data_sram_wen      ),   
  .ex_memaddr_o       (data_sram_addr     ), 
  .ex_memwdata_o      (data_sram_wdata    ), 

  .ex_inst_o          (mem_inst_i         ),
  .ex_inslot_o        (mem_inslot_i       ),
  .ex_stallreq_o      (                   ),
  .ex_pc_o            (mem_pc_i           ),
  .ex_inst_load_o     (mem_inst_load_i    ),
  .ex_memaddr_low_o   (mem_memaddr_low_i  ),

  .ex_wdata_bp_o      (ex_wdata_bp        )
);

alu ALU
(
  .opr1               (opr1               ),
  .opr2               (opr2               ),
  .alu_op             (alu_op             ),
  .alu_res            (ex_alures_i        )
);

mem MEM
(
  .clk                (clk),
  .rst_n              (resetn),

  .mem_memdata_i      (data_sram_rdata),  

  .mem_inst_i         (mem_inst_i),
  .mem_pc_i           (mem_pc_i),
  .mem_inslot_i       (mem_inslot_i),
  .mem_memop_i        (mem_memop_i),
  .mem_memaddr_low_i  (mem_memaddr_low_i),

  .mem_waddr_i        (mem_waddr_i),
  .mem_wdata_i        (mem_wdata_i),
  .mem_wren_i         (mem_wren_i),
  .mem_nofwd_i        (mem_nofwd_i),
  .mem_inst_load_i    (mem_inst_load_i),

  .mem_stall_i        (0),
  .mem_flush_i        (0),  

  .mem_inst_o         (wb_inst_i),
  .mem_inslot_o       (),

  .mem_waddr_o        (wb_waddr_i),
  .mem_wdata_o        (wb_wdata_i),
  .mem_wren_o         (wb_wren_i),
  .mem_pc_o           (wb_pc_i),

  .mem_wdata_bp       (mem_wdata_bp),
  .mem_stall_o        ()

);


writeback WRITEBACK
(
  .clk                (clk),
  .rst_n              (resetn),
  .wb_stall_i         (0),
  .wb_flush_i         (0),

  .wb_memop_i         (wb_memop_i),
  .wb_wren_i          (wb_wren_i),
  .wb_waddr_i         (wb_waddr_i),
  .wb_wdata_i         (wb_wdata_i),
  .wb_inst_i          (wb_inst_i),

  .wb_pc_i            (wb_pc_i),

  .wb_mem_addr_i      (wb_mem_addr_i),
  .wb_mem_data_i      (wb_mem_data_i),

  .wb_wren_o          (rf_wren),
  .wb_waddr_o         (rf_waddr),
  .wb_wdata_o         (rf_wdata),


  .debug_wb_pc        (debug_wb_pc),
  .debug_wb_rf_wen    (debug_wb_rf_wen),
  .debug_wb_rf_wnum   (debug_wb_rf_wnum),
  .debug_wb_rf_wdata  (debug_wb_rf_wdata)
);
endmodule
