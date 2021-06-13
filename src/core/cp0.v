`include "../defines.v"

module cp0
(
	input wire 			clk,
	input wire 			rst_n,
	input wire 	[ 5: 0] cp0_intr_i,//外部中断
	input wire 	[ 7: 0]	cp0_addr_i,//读地址
	input wire 			cp0_ren_i,//读使能
	input wire 	[31: 0]	cp0_wdata_i,//写数据
	input wire 			cp0_wen_i,//写使能

	input wire 	[31: 0]	cp0_pc_i,//异常指令对应的pc
	input wire 			cp0_exc_flag_i,//标记发生异常
	input wire 	[`ExcT]	cp0_exc_type_i,//标记异常类型
	input wire 	[31: 0]	cp0_baddr_i,//来自Exceptions，地址异常的地址
	input wire 	[ 1: 0]	cp0_cpun_i, //来自Exceptions，协处理器缺失异常
	input wire 			cp0_inslot_i,
	//input wire 	[31: 0]	cp0_issave_i,//当前指令写内存，来自MEM

	output reg  [31: 0] cp0_rdata_o,//读出数据
	//output reg  [31: 0] Index_o,
	//output reg  [31: 0] Random_o,
	output wire  [31: 0] Status_o,
	output wire  [31: 0] Cause_o,
	output wire  [31: 0] EPC_o,
	output wire  [31: 0] Config_o,
	output wire  [31: 0] ErrorEPC_o,
	output wire 		 exc_intr//标记产生中断
);

    // Count & Compare
    reg  [32: 0] Count2;//每两个时钟周期加一
    reg  [31: 0] Compare;
    wire [31: 0] Count = Count2[32:1];

    reg  timer_intr;
    wire timer_eq = (Count ^ Compare) == 0;//compare == count
    wire timer_on = Compare != 0 && timer_eq;//定时器异常

    // Status
    reg          Status_BEV;
    reg  [ 7: 0] Status_IM;
    //reg          Status_UM;
    //reg          Status_ERL;
    reg          Status_EXL;
    reg          Status_IE;

    wire [31: 0] Status = {
        9'b0,
        Status_BEV, // 22
        6'b0,
        Status_IM,  // 15:8
        6'b0,
        Status_EXL, // 1
        Status_IE   // 0
    };

    // Cause
    reg          Cause_BD;
    reg  		 Cause_TI;
    reg  [ 7: 0] Cause_IP;
    reg  [ 4: 0] Cause_ExcCode;

    wire [31: 0] Cause = {
        Cause_BD,       // 31 R
        Cause_TI,       // 30 TI
        14'b0,
        Cause_IP,       // 15:8 R[15:10] RW[9:8]
        1'b0,
        Cause_ExcCode,  // 6:2 R
        2'b0
    };

    // PrId
    wire [31: 0] PrId = 
    {
        8'h00,          // Company Options
        8'h01,          // Company ID
        8'h80,          // Processor ID
        8'h21           // Revision
    };


    // Config
    reg  [ 2: 0] Config_K0;

    wire [31: 0] Config = {
        1'b1,       // 31    Config1
        23'b0,      
        1'b1,     
        3'b0,
        1'b0,       //  3    VI:0
        Config_K0   //  2: 0
    };

    // Config1
    wire [31: 0] Config1 = {
        1'b0,       // 31    Config2
        6'd31,      // 30:25 MMU Size-1
        3'd0,       // 24:22 IS
        3'd5,       // 21:19 IL = 5 64B
        3'd3,       // 18:16 IA
        3'd0,       // 15:13 DS
        3'd5,       // 12:10 DL = 5 64B
        3'd3,       //  9: 7 DA
        1'b0,       //  6    C2
        1'b0,       //  5    MD
        1'b0,       //  4    PC
        1'b0,       //  3    WR
        1'b0,       //  2    CA
        1'b0,       //  1    EP
        1'b0        //  0    FP
    };

    // // Index
    // reg          Index_P;
    // reg  [ 4: 0] Index_I;

    // wire [31: 0] Index = {
    //     Index_P,
    //     26'b0,
    //     Index_I
    // };

    // // Random
    // reg  [ 4: 0] Random_I;
    // wire [31: 0] Random = {
    //     27'b0,
    //     Random_I
    // };
    
    // // EntryLo
    // reg  [19: 0] EntryLo0_PFN,  EntryLo1_PFN;
    // reg  [ 2: 0] EntryLo0_C,    EntryLo1_C;
    // reg          EntryLo0_D,    EntryLo1_D;
    // reg          EntryLo0_V,    EntryLo1_V;
    // reg          EntryLo0_G,    EntryLo1_G;

    // wire [31: 0] EntryLo0 = {
    //     6'b0,
    //     EntryLo0_PFN,   // 25: 6
    //     EntryLo0_C,     //  5: 3
    //     EntryLo0_D,     //  2
    //     EntryLo0_V,     //  1
    //     EntryLo0_G      //  0
    // };

    // wire [31: 0] EntryLo1 = {
    //     6'b0,
    //     EntryLo1_PFN,
    //     EntryLo1_C,
    //     EntryLo1_D,
    //     EntryLo1_V,
    //     EntryLo1_G
    // };

    // // EntryHi
    // reg  [18: 0] EntryHi_VPN2;
    // reg  [ 7: 0] EntryHi_ASID;

    // wire [31: 0] EntryHi = {
    //     EntryHi_VPN2,
    //     5'b0,
    //     EntryHi_ASID
    // };

    // Context
    // reg  [ 8: 0] Context_PTEBase;
    // reg  [18: 0] Context_BadVPN2;

    // wire [31: 0] Context = {
    //     Context_PTEBase,
    //     Context_BadVPN2,
    //     4'b0
    // };

    // // Wired
    // reg  [ 4: 0] Wired_I;
    // wire [31: 0] Wired;

    // assign Wired = {
    //     27'b0,
    //     Wired_I
    // };

	reg  [31: 0] BadVAddr;
    reg  [31: 0] EPC;
    //reg  [31: 0] TagLo;
    //reg  [31: 0] TagHi;
    reg  [31: 0] ErrorEPC;


// CP0 Operations
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            BadVAddr        <= 0;
            Count2          <= 0;
            timer_intr      <= 0;
            Compare         <= 0;
            Status_BEV      <= 1;
            Status_IM       <= 0;
            Status_EXL      <= 0;
            Status_IE       <= 0;
            Cause_BD        <= 0;
            Cause_TI        <= 0;
            Cause_IP        <= 0;
            Cause_ExcCode   <= 0;
            EPC             <= 0;
            Config_K0       <= 3;
            ErrorEPC        <= 32'hBFC00000;
        end
        else begin
            // Count & Compare
            Count2 <= Count2 + 1;
            if(timer_on) timer_intr <= 1;

            // Interrupts
            Cause_IP[7:2] <= {cp0_intr_i[5] | timer_intr, cp0_intr_i[4:0]};

            // Exceptions
            if(cp0_exc_flag_i) begin
                case (cp0_exc_type_i)//普通异常
                    `ExcT_Intr,
                    `ExcT_AdEL1,
                    `ExcT_AdEL2,
                    `ExcT_AdES,
                    `ExcT_Ov,
                    `ExcT_SysC, 
                    `ExcT_Bp,                 
                    `ExcT_RI: begin
                        if(!Status_EXL) begin
                            EPC       <= cp0_inslot_i ? cp0_pc_i - 4 : cp0_pc_i;
                            Cause_BD  <= cp0_inslot_i;
                        end
                        Status_EXL <= 1;
                    end
                    
                    `ExcT_ERET: begin
                        Status_EXL <= 0;
                    end
                endcase

                 case (cp0_exc_type_i)
                     `ExcT_AdEL1,
                     `ExcT_AdEL2,
                     `ExcT_AdES: BadVAddr <= cp0_baddr_i;

                //     `ExcT_TLBR,
                //     `ExcT_TLBI,
                //     `ExcT_TLBM: begin
                //         BadVAddr        <= exc_baddr;
                //         Context_BadVPN2 <= exc_baddr[`VPN2];
                //         EntryHi_VPN2    <= exc_baddr[`VPN2];
                //     end

                //     `ExcT_CpU: Cause_CE <= exc_cpun;
              endcase

                // ExcCode
                case (cp0_exc_type_i)//异常码
                    `ExcT_Intr: Cause_ExcCode <= `ExcC_Intr;
                    `ExcT_RI:   Cause_ExcCode <= `ExcC_RI;
                    `ExcT_Ov:   Cause_ExcCode <= `ExcC_Ov;
                    `ExcT_SysC: Cause_ExcCode <= `ExcC_SysC;
                    `ExcT_Bp:   Cause_ExcCode <= `ExcC_Bp;
                    `ExcT_AdEL1,
                    `ExcT_AdEL2:Cause_ExcCode <= `ExcC_AdEL ;
                    `ExcT_AdES:Cause_ExcCode  <= `ExcC_AdES ;
                    // `ExcT_IBE:  Cause_ExcCode <= `ExcC_IBE
                    // `ExcT_DBE:  Cause_ExcCode <= `ExcC_DBE
                endcase

                // Displaying
                case (cp0_exc_type_i)
                    `ExcT_Intr: $display("Interrupt Exception");
                    `ExcT_RI:   $display("Reserved Instruction Exception");
                    `ExcT_Ov:   $display("Integer Overflow Exception");
                    `ExcT_SysC: $display("System Call Exception");
                    `ExcT_Bp:   $display("Breakpoint Exception");
                    `ExcT_AdEL1,
                    `ExcT_AdEL2,
                    `ExcT_AdES:  $display("Address Error Exception");
                    // `ExcT_IBE: $display("Bus Error Exception - Inst");
                    // `ExcT_DBE: $display("Bus Error Exception - Data");
                endcase
            end
            // else if(index_wen) begin
            //     Index_P <= index_wd[31];
            //     Index_I <= index_wd[ 4: 0];
            // end
            // else if(tlb_wen) begin
            //     EntryHi_VPN2 <= tlb_wd[`TLB_VPN2];
            //     EntryHi_ASID <= tlb_wd[`TLB_ASID];
            //     EntryLo0_G   <= tlb_wd[`TLB_G];
            //     EntryLo0_PFN <= tlb_wd[`TLB_PFN0];
            //     EntryLo0_V   <= tlb_wd[`TLB_V0];
            //     EntryLo0_D   <= tlb_wd[`TLB_D0];
            //     EntryLo0_C   <= tlb_wd[`TLB_C0];
            //     EntryLo1_G   <= tlb_wd[`TLB_G];
            //     EntryLo1_PFN <= tlb_wd[`TLB_PFN1];
            //     EntryLo1_V   <= tlb_wd[`TLB_V1];
            //     EntryLo1_D   <= tlb_wd[`TLB_D1];
            //     EntryLo1_C   <= tlb_wd[`TLB_C1];
            // end
            else if(cp0_wen_i) begin
                case (cp0_addr_i)
                    // `CP0_Index: begin
                    //     Index_I  <= wdata[ 4: 0];
                    // end

                    // `CP0_EntryLo0: begin
                    //     EntryLo0_PFN <= wdata[`PFN];
                    //     EntryLo0_C   <= wdata[`CCA];
                    //     EntryLo0_D   <= wdata[`Drt];
                    //     EntryLo0_V   <= wdata[`Vld];
                    //     EntryLo0_G   <= wdata[`Glb];
                    // end

                    // `CP0_EntryLo1: begin
                    //     EntryLo1_PFN <= wdata[`PFN];
                    //     EntryLo1_C   <= wdata[`CCA];
                    //     EntryLo1_D   <= wdata[`Drt];
                    //     EntryLo1_V   <= wdata[`Vld];
                    //     EntryLo1_G   <= wdata[`Glb];
                    // end

                    // `CP0_Context: begin
                    //     Context_PTEBase <= wdata[`PTEBase];
                    // end

                    // `CP0_Wired: begin
                    //     Wired_I  <= wdata[ 4: 0];
                    //     Random_I <= 31;
                    // end

                    `CP0_BadVAddr: begin
                        BadVAddr <= cp0_wdata_i;
                    end

                    `CP0_Count: begin
                        Count2 <= {cp0_wdata_i, 1'b0};
                    end

                    // `CP0_EntryHi: begin
                    //     EntryHi_VPN2 <= wdata[`VPN2];
                    //     EntryHi_ASID <= wdata[`ASID];
                    // end

                    `CP0_Compare: begin
                        Compare    <= cp0_wdata_i;
                        timer_intr <= 0;
                    end

                    `CP0_Status: begin
                        //Status_CU0 <= wdata[`CU0];
                        Status_BEV <= cp0_wdata_i[`BEV];
                        Status_IM  <= cp0_wdata_i[`IM ];
                        //Status_UM  <= wdata[`UM ];
                        //Status_ERL <= cp0_wdata_i[`ERL];
                        Status_EXL <= cp0_wdata_i[`EXL];
                        Status_IE  <= cp0_wdata_i[`IE ];
                    end

                    `CP0_Cause: begin
                        //Cause_IV      <= wdata[`IV ];
                        Cause_IP[1:0] <= cp0_wdata_i[`IPS];
                    end

                    `CP0_EPC: begin
                        EPC <= cp0_wdata_i;
                    end

                    `CP0_Config: begin
                        Config_K0  <= cp0_wdata_i[`K0 ];
                    end

                    // `CP0_TagLo: begin
                    //     TagLo <= cp0_wdata_i;
                    // end

                    // `CP0_TagHi: begin
                    //     TagHi <= cp0_wdata_i;
                    // end

                    `CP0_ErrorEPC: begin
                        ErrorEPC <= cp0_wdata_i;
                    end
                endcase
            end
        end
    end

    always @(*) begin
        if(cp0_ren_i) begin
            case (cp0_addr_i) 
               // `CP0_Index:    cp0_rdata_o <= Index;
               // `CP0_Random:   cp0_rdata_o <= Random;
               // `CP0_EntryLo0: cp0_rdata_o <= EntryLo0;
               // `CP0_EntryLo1: cp0_rdata_o <= EntryLo1;
               // `CP0_Context:  cp0_rdata_o <= Context;
               // `CP0_Wired:    cp0_rdata_o <= Wired;
                `CP0_BadVAddr: cp0_rdata_o <= BadVAddr;
                `CP0_Count:    cp0_rdata_o <= Count;
               // `CP0_EntryHi:  cp0_rdata_o <= EntryHi;
                `CP0_Compare:  cp0_rdata_o <= Compare;
                `CP0_Status:   cp0_rdata_o <= Status;
                `CP0_Cause:    cp0_rdata_o <= Cause;
                `CP0_EPC:      cp0_rdata_o <= EPC;
                `CP0_PrId:     cp0_rdata_o <= PrId;
                `CP0_Config:   cp0_rdata_o <= Config;
                `CP0_Config1:  cp0_rdata_o <= Config1;
               // `CP0_TagLo:    cp0_rdata_o <= TagLo;
               // `CP0_TagHi:    cp0_rdata_o <= TagHi;
                `CP0_ErrorEPC: cp0_rdata_o <= ErrorEPC;
                default:       cp0_rdata_o <= 0;
            endcase
        end
        else cp0_rdata_o <= cp0_wdata_i;
    end

    wire   no_ex_er = ~Status[`ERL] & ~Status[`EXL];
    assign exc_intr = (Cause[`IP] & Status[`IM]) != 0 && Status[`IE] && no_ex_er;

    // Output

    assign Status_o   = Status;
    assign Cause_o    = Cause;
    assign EPC_o      = EPC;
    assign Config_o   = Config;
    assign ErrorEPC_o = ErrorEPC;

endmodule