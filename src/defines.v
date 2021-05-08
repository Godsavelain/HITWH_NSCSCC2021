// Bus Width
`define         AOP_W                   12
`define         MDOP_W                  8
`define         MMOP_W                  12
`define         AOP                     `AOP_W-1: 0
`define         MDOP                    `MDOP_W-1: 0
`define         MMOP                    `MMOP_W-1: 0

/*--------------------Encoding--------------------*/
// Opcode
`define         OP_SPECIAL          6'b000000
`define         OP_REGIMM           6'b000001
`define         OP_J                6'b000010
`define         OP_JAL              6'b000011
`define         OP_BEQ              6'b000100
`define         OP_BNE              6'b000101
`define         OP_BLEZ             6'b000110
`define         OP_BGTZ             6'b000111
`define         OP_ADDI             6'b001000
`define         OP_ADDIU            6'b001001
`define         OP_SLTI             6'b001010
`define         OP_SLTIU            6'b001011
`define         OP_ANDI             6'b001100
`define         OP_ORI              6'b001101
`define         OP_XORI             6'b001110
`define         OP_LUI              6'b001111
`define         OP_COP0             6'b010000
`define         OP_COP1             6'b010001
`define         OP_COP2             6'b010010
`define         OP_COP3             6'b010011
`define         OP_BEQL             6'b010100
`define         OP_BNEL             6'b010101
`define         OP_BLEZL            6'b010110
`define         OP_BGTZL            6'b010111
`define         OP_SPECIAL2         6'b011100
`define         OP_LB               6'b100000
`define         OP_LH               6'b100001
`define         OP_LWL              6'b100010
`define         OP_LW               6'b100011
`define         OP_LBU              6'b100100
`define         OP_LHU              6'b100101
`define         OP_LWR              6'b100110
`define         OP_SB               6'b101000
`define         OP_SH               6'b101001
`define         OP_SWL              6'b101010
`define         OP_SW               6'b101011
`define         OP_SWR              6'b101110
`define         OP_CACHE            6'b101111
`define         OP_LL               6'b110000
`define         OP_LWC1             6'b110001
`define         OP_LWC2             6'b110010
`define         OP_PREF             6'b110011
`define         OP_LDC1             6'b110101
`define         OP_LDC2             6'b110110
`define         OP_SC               6'b111000
`define         OP_SWC1             6'b111001
`define         OP_SWC2             6'b111010
`define         OP_SDC1             6'b111101
`define         OP_SDC2             6'b111110

// Function : Opcode = Special
`define         SP_SLL              6'b000000
`define         SP_MOVCI            6'b000001
`define         SP_SRL              6'b000010
`define         SP_SRA              6'b000011
`define         SP_SLLV             6'b000100
`define         SP_SRLV             6'b000110
`define         SP_SRAV             6'b000111
`define         SP_JR               6'b001000
`define         SP_JALR             6'b001001
`define         SP_MOVZ             6'b001010
`define         SP_MOVN             6'b001011
`define         SP_SYSCALL          6'b001100
`define         SP_BREAK            6'b001101
`define         SP_SYNC             6'b001111
`define         SP_MFHI             6'b010000
`define         SP_MTHI             6'b010001
`define         SP_MFLO             6'b010010
`define         SP_MTLO             6'b010011
`define         SP_MULT             6'b011000
`define         SP_MULTU            6'b011001
`define         SP_DIV              6'b011010
`define         SP_DIVU             6'b011011
`define         SP_ADD              6'b100000
`define         SP_ADDU             6'b100001
`define         SP_SUB              6'b100010
`define         SP_SUBU             6'b100011
`define         SP_AND              6'b100100
`define         SP_OR               6'b100101
`define         SP_XOR              6'b100110
`define         SP_NOR              6'b100111
`define         SP_SLT              6'b101010
`define         SP_SLTU             6'b101011
`define         SP_TGE              6'b110000
`define         SP_TGEU             6'b110001
`define         SP_TLT              6'b110010
`define         SP_TLTU             6'b110011
`define         SP_TEQ              6'b110100
`define         SP_TNE              6'b110110

// Rt : Opcode = RegImm
`define         RI_BLTZ             5'b00000
`define         RI_BGEZ             5'b00001
`define         RI_BLTZL            5'b00010
`define         RI_BGEZL            5'b00011
`define         RI_TGEI             5'b01000
`define         RI_TGEIU            5'b01001
`define         RI_TLTI             5'b01010
`define         RI_TLTIU            5'b01011
`define         RI_TEQI             5'b01100
`define         RI_TNEI             5'b01110
`define         RI_BLTZAL           5'b10000
`define         RI_BGEZAL           5'b10001
`define         RI_BLTZALL          5'b10010
`define         RI_BGEZALL          5'b10011

// Function : Opcode = Special2
`define         SP2_MADD            6'b000000
`define         SP2_MADDU           6'b000001
`define         SP2_MUL             6'b000010
`define         SP2_MSUB            6'b000100
`define         SP2_MSUBU           6'b000101
`define         SP2_CLZ             6'b100000
`define         SP2_CLO             6'b100001

// Rs : Opcode = COP0
`define         C0_MFC0             5'b00000
`define         C0_MTC0             5'b00100
`define         C0_CO               5'b10000

// Function : Opcode = COP0 and Rs = CO
`define         C0F_TLBR            6'b000001
`define         C0F_TLBWI           6'b000010
`define         C0F_TLBWR           6'b000110
`define         C0F_TLBP            6'b001000
`define         C0F_ERET            6'b011000
`define         C0F_WAIT            6'b100000

// Rt: Opcode = CACHE
`define         CA_III              5'b00000
`define         CA_DIWI             5'b00001
`define         CA_IIST             5'b01000
`define         CA_DIST             5'b01001
`define         CA_IHI              5'b10000
`define         CA_DHI              5'b10001
`define         CA_DHWI             5'b10101

/*--------------------Decoded Opcode--------------------*/
// ALU Op

// MDU Op
`define         MDU_MTHI            `MDOP_W'h0
`define         MDU_MTLO            `MDOP_W'h1
`define         MDU_MULT            `MDOP_W'h2
`define         MDU_MUL             `MDOP_W'h3
`define         MDU_MADD            `MDOP_W'h4
`define         MDU_MSUB            `MDOP_W'h5
`define         MDU_DIV             `MDOP_W'h6

// Memory Access Op
`define         MEM_NOP             `MMOP_W'h0
`define         MEM_LB              `MMOP_W'h1
`define         MEM_LBU             `MMOP_W'h2
`define         MEM_LH              `MMOP_W'h3
`define         MEM_LHU             `MMOP_W'h4
`define         MEM_LW              `MMOP_W'h5
`define         MEM_LWL             `MMOP_W'h6
`define         MEM_LWR             `MMOP_W'h7
`define         MEM_SB              `MMOP_W'h8
`define         MEM_SH              `MMOP_W'h9
`define         MEM_SW              `MMOP_W'hA
`define         MEM_SWL             `MMOP_W'hB
`define         MEM_SWR             `MMOP_W'hC
`define         MEM_LL              `MMOP_W'hD
`define         MEM_SC              `MMOP_W'hE
`define         MEM_CACHE           `MMOP_W'hF

/*--------------------Coprocessor 0--------------------*/
// CP0 Registers
`define         CP0_ZeroReg          8'd00
`define         CP0_Index           {5'd00, 3'd0}
`define         CP0_Random          {5'd01, 3'd0}
`define         CP0_EntryLo0        {5'd02, 3'd0}
`define         CP0_EntryLo1        {5'd03, 3'd0}
`define         CP0_Context         {5'd04, 3'd0}
`define         CP0_PageMask        {5'd05, 3'd0}
`define         CP0_Wired           {5'd06, 3'd0}
`define         CP0_BadVAddr        {5'd08, 3'd0}
`define         CP0_Count           {5'd09, 3'd0}
`define         CP0_EntryHi         {5'd10, 3'd0}
`define         CP0_Compare         {5'd11, 3'd0}
`define         CP0_Status          {5'd12, 3'd0}
`define         CP0_Cause           {5'd13, 3'd0}
`define         CP0_EPC             {5'd14, 3'd0}
`define         CP0_PrId            {5'd15, 3'd0}
`define         CP0_EBase           {5'd15, 3'd1}
`define         CP0_Config          {5'd16, 3'd0}
`define         CP0_Config1         {5'd16, 3'd1}
`define         CP0_TagLo           {5'd28, 3'd0}
`define         CP0_TagHi           {5'd29, 3'd0}
`define         CP0_ErrorEPC        {5'd30, 3'd0}

// Fields of Status Register
`define         CU3                 31
`define         CU2                 30
`define         CU1                 29
`define         CU0                 28
`define         BEV                 22
`define         IM                  15: 8
`define         UM                   4
`define         ERL                  2
`define         EXL                  1
`define         IE                   0

// Fields of Cause Register
`define         BD                  31
`define         CE                  29:28
`define         IV                  23
`define         IPH                 15:10
`define         IPS                  9: 8
`define         IP                  15: 8
`define         ExcCode              6: 2

// Fields of Config Registers
`define         K23                 30:28
`define         KU                  27:25
`define         K0                   2: 0

// Fields of CP0 TLB Registers
// EntryLo
`define         PFN                 25: 6
`define         CCA                  5: 3
`define         Drt                  2
`define         Vld                  1
`define         Glb                  0

// EntryHi
`define         VPN2                31:13
`define         ASID                 7: 0

// Context
`define         PTEBase             31:23
`define         BadVPN2             22: 4

/*--------------------MMU--------------------*/
// Virtual Address Segments
`define         kuseg               3'b0??
`define         kseg0               3'b100
`define         kseg1               3'b101
`define         kseg2               3'b110
`define         kseg3               3'b111

// TLB Item
`define         TLBI_W             78
`define         TLBI               `TLBI_W-1: 0

`define         TLB_VPN2           18: 0
`define         TLB_ASID           26:19
`define         TLB_G              27
`define         TLB_PFN0           47:28
`define         TLB_V0             48
`define         TLB_D0             49
`define         TLB_C0             52:50
`define         TLB_PFN1           72:53
`define         TLB_V1             73
`define         TLB_D1             74
`define         TLB_C1             77:75

// TLB Operation
`define         TOP_W                3
`define         TOP                  `TOP_W-1: 0

`define         TOP_NOP              `TOP_W'd0
`define         TOP_TLBR             `TOP_W'd1
`define         TOP_TLBWI            `TOP_W'd2
`define         TOP_TLBWR            `TOP_W'd3
`define         TOP_TLBP             `TOP_W'd4

/*--------------------Cache--------------------*/
`define         COP_W                   3
`define         COP                     `COP_W-1: 0
// Cache Operation
`define         COP_NOP                 `COP_W'b000

//CacheOp[0] = 1 : ICache
`define         COP_I_Index_Invl        `COP_W'b010
`define         COP_I_Index_St_Tag      `COP_W'b100
`define         COP_I_Hit_Invl          `COP_W'b110

//CacheOp[0] = 0 : DCache
`define         COP_D_Index_Wb_Invl     `COP_W'b001
`define         COP_D_Index_St_Tag      `COP_W'b011
`define         COP_D_Hit_Invl          `COP_W'b101
`define         COP_D_Hit_Wb_Invl       `COP_W'b111

/*--------------------Exceptions--------------------*/
`define         Excs_W              21
`define         ExcT_W              4
`define         Excs                `Excs_W-1: 0
`define         ExcT                `ExcT_W-1: 0

// Index of exception vector
`define         Exc_NMI             0
`define         Exc_Intr            1
`define         Exc_I_AdE           2
`define         Exc_I_TLBR          3
`define         Exc_I_TLBI          4
`define         Exc_I_BusE          5
`define         Exc_CpU             6
`define         Exc_CpUN            8: 7
`define         Exc_RI              9
`define         Exc_Ov              10
`define         Exc_Trap            11
`define         Exc_SysC            12
`define         Exc_Bp              13
`define         Exc_D_AdE           14
`define         Exc_D_TLBR          15
`define         Exc_D_TLBI          16
`define         Exc_D_TLBM          17
`define         Exc_D_BusE          18
`define         Exc_ERET            19
`define         Exc_Wait            20  //Not really an exception

// Exception Types
`define         ExcT_NoExc          `ExcT_W'h00
`define         ExcT_Intr           `ExcT_W'h01
`define         ExcT_CpU            `ExcT_W'h02
`define         ExcT_RI             `ExcT_W'h03
`define         ExcT_Ov             `ExcT_W'h04
`define         ExcT_Trap           `ExcT_W'h05
`define         ExcT_SysC           `ExcT_W'h06
`define         ExcT_Bp             `ExcT_W'h07
`define         ExcT_AdE            `ExcT_W'h08
`define         ExcT_TLBR           `ExcT_W'h09
`define         ExcT_TLBI           `ExcT_W'h0A
`define         ExcT_TLBM           `ExcT_W'h0B
`define         ExcT_IBE            `ExcT_W'h0C
`define         ExcT_DBE            `ExcT_W'h0D
`define         ExcT_ERET           `ExcT_W'h0E

// Cause.ExcCode
`define         ExcC_Intr           5'h00
`define         ExcC_Mod            5'h01
`define         ExcC_TLBL           5'h02
`define         ExcC_TLBS           5'h03
`define         ExcC_AdEL           5'h04
`define         ExcC_AdES           5'h05
`define         ExcC_IBE            5'h06
`define         ExcC_DBE            5'h07
`define         ExcC_SysC           5'h08
`define         ExcC_Bp             5'h09
`define         ExcC_RI             5'h0A
`define         ExcC_CpU            5'h0B
`define         ExcC_Ov             5'h0C
`define         ExcC_Tr             5'h0D