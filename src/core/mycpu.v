module mycpu
(
  input wire                clk,
  input wire                resetn,

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


endmodule