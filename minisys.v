`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module minisys ( 
    input			fpga_rst,	        // 板上的Reset信号，高电平复位
    input			fpga_clk,           // 板上的100MHz时钟信号
    //2个16位定时/计数器、4×4键盘控制器、8位7段数码管控制器
    //16位LED输出、16位拨码开关输入、PWM控制、看门狗控制器的设计
    input   [3:0]   button,             // 除S3外的四个按钮开关（S1-S5)
    input	[23:0]	switch2N4,	        // 拨码开关输入
    input   [3:0]   keyboardIn,         // 键盘输入线(列线)  
    output  [3:0]   keyboardOut,        // 键盘输出线(行线) 
    output	[23:0]	led2N4,             // LED结果输出到板上
    output  [7:0]   digitalTube,        // 8位7段数码管控制器
    output  [7:0]   digitalTubeEnable,  // 数码管使能信号A0-A7(低电平有效)
    output          buzzer,             // 蜂鸣管
	// UART Programmer Pinouts
	input           start_pg,           // 接板上的S3按键做下载启动键
	input           rx,                 // UART接收
	output          tx                  // UART发送
);
    
    wire cpu_clk;				        // cpu_clk: 分频后时钟供给系统
    wire rst;
    // UART Programmer Pinouts
    wire upg_clk, upg_clk_o, upg_wen_o, upg_done_o;
    wire [14:0] upg_adr_o;
    wire [31:0] upg_dat_o;  
      
    wire spg_bufg;
    BUFG U1(.I(start_pg), .O(spg_bufg));// S3按键去抖
    
    // Generate UART Programmer reset signal
    reg upg_rst;
    always @ (posedge fpga_clk) begin
        if (spg_bufg)    upg_rst = 0;
        if (fpga_rst)    upg_rst = 1;
    end
    
    assign rst = fpga_rst | !upg_rst;

    cpuclk cpuclk (
        .clk_in1        (fpga_clk),     // 100MHz, 板上时钟
        .clk_out1        (cpu_clk),     // CPU Clock (22MHz), 主时钟
        .clk_out2        (upg_clk)      // UPG Clock (10MHz), 用于串口下载
    );
        
    uart_bmpg_0 uartpg (                // 此模块已经接好，只作为串口下载的附件，可不去关注
        .upg_clk_i        (upg_clk),    // 10MHz   
        .upg_rst_i        (upg_rst),    // 高电平有效
         // blkram signals
         .upg_clk_o        (upg_clk_o),
         .upg_wen_o        (upg_wen_o),
         .upg_adr_o        (upg_adr_o),
         .upg_dat_o        (upg_dat_o),
         .upg_done_o       (upg_done_o),
         // uart signals
         .upg_rx_i        (rx),
         .upg_tx_o        (tx)
    );
    
    wire iowrite,ioread;	            // I/O读写信号
    wire [31:0] write_data;	            // 写RAM或IO的数据
    wire [31:0] rdata;		            // 读RAM或IO的数据
    wire [15:0] ioread_data;	        // 读IO的数据
    
    // 取值单元输出
    wire [31:0] instruction;
    wire [31:0] opcplus4;
    
    wire [31:0] read_data_1;	       // 从寄存器读出的(rs)
    wire [31:0] read_data_2;	       // 从寄存器读出的(rt)
    wire [31:0] sign_extend;	       // 立即数符号扩展
   
    wire [13:0] rom_adr;
    wire [31:0] rom_dat;
    
    // 执行单元相关
    wire alusrc;
    wire [1:0]  aluop;
    wire [31:0] add_result;	           // PC+4+offset<<2
    wire [31:0] alu_result;	           // ALU运算结果
    wire [31:0] read_data;	           // RAM中读取的数据
    wire zero,positive,negative,overflow,div_zero;
    
    // 控制单元
    wire i_format;
    wire beq,bne,bgez,bgtz,blez,bltz,bgezal,bltzal;
    wire jmp,jal,jr,jalr;
    wire mfhi,mflo,mfc0,mthi,mtlo,mtc0;
    wire divsel;
    wire break,syscall,eret;
    wire reserved_instruction;
    wire regdst;
    wire regwrite;
    wire memwrite;
    wire memread,memory_sign;
    wire [1:0]memory_data_width;
    wire memoriotoreg;
    wire memreg;
    wire sftmd;
    
	// ID
	wire [31:0] id_instruction;
	wire [31:0] id_opcplus4;
	
	// 接口相关
    wire ledctrl,switchctrl;
    wire tubectrl,keyboardctrl,buzzerctrl,pwmctrl;
    wire [15:0] ioread_data_keyboard;// 键盘
    wire [15:0] ioread_data_switch;  // 拨码开关

	// for multicycle
	wire [1:0] wpc;
	wire wir;
	wire waluresult;
	
	// 指令存储器IMEM:输入PC，读出指令
	programrom ROM (
		// Program ROM Pinouts
		.rom_clk_i		(cpu_clk),	    // 给CPU的22MHz的主时钟
		.rom_adr_i		(rom_adr),		// 取指单元给ROM的地址（PC/4）
		.Jpadr			(rom_dat),	    // ROM中读的数据（指令）output
		// UART Programmer Pinouts, 以下是串口下载所用，可不必关注
		.upg_rst_i		(upg_rst),		// UPG reset (高电平有效)
		.upg_clk_i		(upg_clk_o),	// UPG clock (10MHz)
		.upg_wen_i		(upg_wen_o & !upg_adr_o[14]),	// UPG write enable
		.upg_adr_i		(upg_adr_o[13:0]),	// UPG write address
		.upg_dat_i		(upg_dat_o),	    // UPG write data
		.upg_done_i		(upg_done_o)	    // 1 if programming is finished
	);
	
	wire [31:0]branch_PC;
	wire [25:0]jump_PC;
	wire if_zero,if_positive,if_negative;
	wire if_beq,if_bne,if_bgez,if_bgtz,if_blez,if_bltz,if_bgezal,if_bltzal;
	wire if_jmp,if_jal,if_jr,if_jalr;
	wire pcwrite;
    // 取指单元
    Ifetc32 ifetch(
        //.Wpc(wpc),
        //.Wir(wir),
        .reset          (rst),
        .clock          (cpu_clk),     
        .PCWrite        (pcwrite),
        .Jrn            (jr),           // (PC)←(rs),ID段传入
        .Jalr           (jalr),
        .Read_data_1    (read_data_1),  // (rs)
        
        .Jmp            (jmp),          // (PC)←((Zero-Extend) address<<2),ID段传入
        .Jal            (jal),  
        .Jump_PC        (jump_PC),      // ((Zero-Extend) address<<2)
        
        .Add_result     (branch_PC),    // (PC)+4+((Sign-Extend)offset<<2),EXE_MEM后传入
        .Beq            (if_beq),
        .Bne            (if_bne),
        .Bgez           (if_bgez),
        .Bgtz           (if_bgtz),
        .Blez           (if_blez),
        .Bltz           (if_bltz),
        .Bgezal         (if_bgezal),
        .Bltzal         (if_bltzal),
        .Zero           (if_zero),                                     
        .Positive       (if_positive),
        .Negative       (if_negative),  
        
        .opcplus4       (opcplus4),
        .Instruction    (instruction),
		// ROM Pinouts
		.rom_adr_o		(rom_adr),
		.Jpadr			(rom_dat),
		//
		.interrupt_PC   (),
        .flush          ()
    );
     
    // IR and NPC
    IF_ID IF_ID(
       .cpu_clk         (cpu_clk),
       .reset           (rst),  
       .PCWrite         (pcwrite),    
       .IF_opcplus4     (opcplus4),        
       .IF_instruction  (instruction),   
       .ID_opcplus4      (id_opcplus4),
       .ID_instruction  (id_instruction),
 
       .stall           (),              
       .clean           ()                    
    );
    
    //控制单元
    control32 control(
        // new
        //.clock           (cpu_clk),
        //.reset           (rst),
        ///.zero           (zero),
        ///.Wpc            (wpc),
        ///.Wir            (wir),
        ///.Waluresult     (waluresult),
 
        //
        .Instruction    (id_instruction),
        .Alu_resultHigh (alu_result[31:10]),
        .RegDST         (regdst),
        .ALUSrc         (alusrc),
        .MemIOtoReg     (memoriotoreg),
        .RegWrite       (regwrite),
        .MemRead        (memread),
        .MemWrite       (memwrite),
        .IORead         (ioread),
        .IOWrite        (iowrite),
        
        .Jmp            (jmp),
        .Jal            (jal),
        .Jrn            (jr),
        .Jalr           (jalr),
        
        .Beq            (beq),
        .Bne            (bne),
        .Bgez           (bgez),
        .Bgtz           (bgtz),
        .Blez           (blez),
        .Bltz           (bltz),
        .Bgezal         (bgezal),
        .Bltzal         (bltzal),
        
        .Mfhi           (mfhi),
        .Mflo           (mflo),
        .Mfc0           (mfc0),
        .Mthi           (mthi),
        .Mtlo           (mtlo),
        .Mtc0           (mtc0),
        
        .I_format       (i_format),
        .Sftmd          (sftmd),
        .DivSel         (divsel),
        .ALUOp          (aluop),
        .Memory_sign    (memory_sign),       
        .Memory_data_width(memory_data_width),
        
        .Break          (break),
        .Syscall        (syscall),
        .Eret           (eret),
        .Reserved_instruction(reserved_instruction)
    );
    
    wire [4:0] waddr;
    wire [4:0] id_waddr,addr0,addr1,rs;
    wire id_regwrite,wb_memoriotoreg;
    wire [31:0] wb_aluresult,wb_memdata,wb_data;
    Idecode32 idecode(
        .clock          (cpu_clk),
        .reset          (rst),
        .opcplus4       (id_opcplus4),
        .Instruction    (id_instruction),
        .waddr          (id_waddr),
        
        .read_data_1	(read_data_1),//
        .read_data_2	(read_data_2),//
        .wb_data        (wb_data),
        .write_address_0(addr0),
        .write_address_1(addr1),
        .rs             (rs),
        .Jump_PC        (jump_PC),
        .Jal            (jal),
        .Jalr           (jalr),
        .Bgezal         (bgezal),
        .Bltzal         (bltzal),
        .RegWrite       (id_regwrite),//
        .Sign_extend    (sign_extend),
            
        .Positive       (positive),
        .Negative       (negative),
        .Overflow       (overflow),
        .Divide_zero    (div_zero),
        .Reserved_instruction (reserved_instruction),
        .Mfc0           (mfc0),       
        .Mtc0           (mtc0),
        .Break          (break),
        .Syscall        (syscall),
        .Eret           (eret),
        .cp0_data_in    (),
        .cp0_wen        (),
        .cp0_data_out   (),
        .causeExcCode   ()
    );
    
    wire id_ex_stall,ex_memread;
    wire [4:0]  ex_address;
    hazard hazard(
        .ex_MemRead     (ex_memread),
        .id_rt          (addr0),
        .id_rs          (rs),
        .ex_rt          (ex_address),
        .PC_IFWrite     (pcwrite),
        .ID_EX_stall    (id_ex_stall)
    );
    
    wire [31:0] ex_opcplus4,ex_dataA,ex_dataB,ex_sign_extend;
    wire [1:0]  ex_aluop;
    wire        ex_alusrc;
    wire [4:0]  ex_address0,ex_address1,ex_rs;
    wire [5:0]  ex_func,ex_op;
    wire [4:0]  ex_shamt;
    wire ex_jr,ex_mem_jmp,ex_mem_jalr,ex_mem_jal;
    wire ex_regdst,ex_sftmd,ex_divsel,ex_i_format,ex_mem_regwrite,ex_mem_memoriotoreg,ex_mem_memwrite,ex_mem_memory_sign;
    wire [1:0] ex_mem_memory_data_width;
    wire ex_mem_beq,ex_mem_bne,ex_mem_bgez,ex_mem_bgtz,ex_mem_blez,ex_mem_bltz,ex_mem_bgezal,ex_mem_bltzal;
    wire ex_mem_mfhi,ex_mem_mflo,ex_mem_mtlo,ex_mem_mthi;
    
    // rtd,A,B,NPC,E,cmd 
    ID_EX ID_EX(
        .cpu_clk        (cpu_clk),
        .reset          (rst),
        .stall          (id_ex_stall),
        .ID_opcplus4    (id_opcplus4),
        .ID_dataA       (read_data_1),
        .ID_dataB       (read_data_2),
        .ID_ALUOp       (aluop),
        .ID_ALUSrc      (alusrc),
        .ID_func        (id_instruction[5:0]),
        .ID_op          (id_instruction[31:26]),
        .ID_shamt       (id_instruction[10:6]),
        .ID_Sign_extend (sign_extend),
        .ID_address0    (addr0),
        .ID_address1    (addr1),  
        .ID_rs          (rs),
        .ID_RegDst      (regdst),
        .ID_Sftmd       (sftmd),    
        .ID_DivSel      (divsel),
        .ID_I_format    (i_format),
        .ID_Jr          (jr),
        .ID_Jmp         (jmp),
        .ID_Jal         (jal),
        .ID_Jalr        (jalr),
    
        .ID_RegWrite    (regwrite),      
        .ID_MemIOtoReg  (memoriotoreg),
        .ID_MemWrite    (memwrite),
        .ID_MemRead     (memread),
        .ID_Memory_sign (memory_sign),
        .ID_Memory_data_width(memory_data_width),
        .ID_Beq         (beq),
        .ID_Bne         (bne),
        .ID_Bgez        (bgez),
        .ID_Bgtz        (bgtz),
        .ID_Blez        (blez),
        .ID_Bltz        (bltz),
        .ID_Bgezal      (bgezal),
        .ID_Bltzal      (bltzal),
        
        .ID_Mfhi        (mfhi),
        .ID_Mflo        (mflo),
        .ID_Mthi        (mthi),
        .ID_Mtlo        (mtlo),
        
        .EX_opcplus4    (ex_opcplus4),
        .EX_dataA       (ex_dataA),
        .EX_dataB       (ex_dataB),
        .EX_ALUOp       (ex_aluop),
        .EX_ALUSrc      (ex_alusrc),
        .EX_address0    (ex_address0),
        .EX_address1    (ex_address1), 
        .EX_rs          (ex_rs),
        .EX_func        (ex_func),
        .EX_op          (ex_op),
        .EX_shamt       (ex_shamt),
        .EX_Sign_extend (ex_sign_extend),
        .EX_RegDst      (ex_regdst),
        .EX_Sftmd       (ex_sftmd),    
        .EX_DivSel      (ex_divsel),
        .EX_I_format    (ex_i_format),
        .EX_Jr          (ex_jr),
        .EX_MEM_Jmp     (ex_mem_jmp),
        .EX_MEM_Jal     (ex_mem_jal),
        .EX_MEM_Jalr    (ex_mem_jalr),
    
        .EX_MEM_RegWrite(ex_mem_regwrite),      //传去EX_MEM
        .EX_MEM_MemIOtoReg(ex_mem_memoriotoreg),
        .EX_MEM_MemWrite(ex_mem_memwrite),
        .EX_MemRead     (ex_memread),
        .EX_MEM_Memory_sign (ex_mem_memory_sign),
        .EX_MEM_Memory_data_width(ex_mem_memory_data_width),
        
        .EX_MEM_Beq     (ex_mem_beq),
        .EX_MEM_Bne     (ex_mem_bne),
        .EX_MEM_Bgez    (ex_mem_bgez),
        .EX_MEM_Bgtz    (ex_mem_bgtz),
        .EX_MEM_Blez    (ex_mem_blez),
        .EX_MEM_Bltz    (ex_mem_bltz),
        .EX_MEM_Bgezal  (ex_mem_bgezal),
        .EX_MEM_Bltzal  (ex_mem_bltzal),
        
        .EX_MEM_Mfhi    (ex_mem_mfhi),
        .EX_MEM_Mflo    (ex_mem_mflo),
        .EX_MEM_Mthi    (ex_mem_mthi),
        .EX_MEM_Mtlo    (ex_mem_mtlo)
    );
    
    wire [1:0] ex_alusrcA,ex_alusrcB;
    wire mem_wb_mfhi,mem_wb_mflo,mem_wb_mtlo,mem_wb_mthi;
    wire wb_mfhi,wb_mflo,wb_mtlo,wb_mthi;
    wire [4:0] mem_wb_waddr;
    wire mem_wb_regwrite;
    forwarding forwarding(
        .rs             (ex_rs),		    // rs
        .rt             (ex_address0),      // rt
        .Mflo           (ex_mem_mflo),
        .Mfhi           (ex_mem_mfhi),
        .ALUSrc         (ex_alusrc),     // 是否选择扩展后的立即数
        //处理数据转发
        .EX_MEM_RegWrite(mem_wb_regwrite),
        .EX_MEM_waddr   (mem_wb_waddr),
        .EX_MEM_Mtlo    (mem_wb_mtlo),
        .EX_MEM_Mthi    (mem_wb_mthi),
         
        .MEM_WB_RegWrite(id_regwrite),
        .MEM_WB_waddr   (id_waddr),
        .MEM_WB_Mtlo    (wb_mtlo),
        .MEM_WB_Mthi    (wb_mthi),
    
        .ALUSrcA        (ex_alusrcA),       
        .ALUSrcB        (ex_alusrcB)
    );
    
	wire [31:0] mem_aluresult;
    Executs32 execute(
        // new
        .clock          (cpu_clk),
        .reset          (rst),
        //.Waluresult     (waluresult),
        
        .PC_plus_4      (ex_opcplus4),
        .Read_data_1	(ex_dataA),
        .Read_data_2	(ex_dataB),
        .address0       (ex_address0),
        .address1       (ex_address1),
        .RegDst         (ex_regdst),
        .ALUOp          (ex_aluop),
        .Sign_extend    (ex_sign_extend),
        .Func           (ex_func),// func
        .Op             (ex_op),//op code
        .Shamt          (ex_shamt),
        .ALUSrcA        (ex_alusrcA),
        .ALUSrcB        (ex_alusrcB),
        .EX_MEM_ALU_result(mem_aluresult),
        .WB_data        (wb_data), 
        .I_format       (ex_i_format),
        .Sftmd          (ex_sftmd),
        .DivSel         (ex_divsel),
        .Jrn            (ex_jr),
        
        .Zero           (zero),
        .Positive       (positive),
        .Negative       (negative),
        .Overflow       (overflow),     
        .Divide_zero    (div_zero),
        .address        (ex_address),
        .ALU_Result     (alu_result),
        .Add_Result     (add_result)
	);
	

	wire [31:0] mem_data_in;
	wire mem_memwrite,mem_memory_sign;
	wire [1:0] mem_memory_data_width;
	
	wire mem_wb_memoriotoreg;
    // rtd,T,B,C,cmd 
    EX_MEM EX_MEM(
        .reset          (rst),
        .clock          (cpu_clk),
        
        .EX_Zero        (zero),
        .EX_Positive    (positive),
        .EX_Negative    (negative),
        
        //.EX_Jr          (ex_jr),
        //.ID_EX_Jalr     (ex_mem_jalr),
        //.ID_EX_Jmp      (ex_mem_jmp),
        //.ID_EX_Jal      (ex_mem_jal),
        
        .ID_EX_Beq      (ex_mem_beq),
        .ID_EX_Bne      (ex_mem_bne),
        .ID_EX_Bgez     (ex_mem_bgez),
        .ID_EX_Bgtz     (ex_mem_bgtz),
        .ID_EX_Blez     (ex_mem_blez),
        .ID_EX_Bltz     (ex_mem_bltz),
        .ID_EX_Bgezal   (ex_mem_bgezal),
        .ID_EX_Bltzal   (ex_mem_bltzal),
        
        .ID_EX_Mfhi     (ex_mem_mfhi),
        .ID_EX_Mflo     (ex_mem_mflo),
        .ID_EX_Mthi     (ex_mem_mthi),
        .ID_EX_Mtlo     (ex_mem_mtlo),
        
        .ID_EX_RegWrite (ex_mem_regwrite),
        .ID_EX_MemIOtoReg(ex_mem_memoriotoreg),
        .ID_EX_MemWrite (ex_mem_memwrite),
        .ID_EX_Memory_sign(ex_mem_memory_sign),
        .ID_EX_Memory_data_width(ex_mem_memory_data_width),
        
        .EX_Add_Result  (add_result),    
        .EX_ALU_Result  (alu_result),   
        .EX_Read_data_2 (ex_dataB),   
        .EX_Wirte_Address(ex_address),

        .IF_Zero        (if_zero),
        .IF_Negative    (if_negative),
        .IF_Positive    (if_positive),
        //.IF_Jr          (if_jr),
        //.IF_Jalr        (if_jalr),
        //.IF_Jmp         (if_jmp),
        //.IF_Jal         (if_jal),
        
        .IF_Beq         (if_beq),
        .IF_Bne         (if_bne),
        .IF_Bgez        (if_bgez),
        .IF_Bgtz        (if_bgtz),
        .IF_Blez        (if_blez),
        .IF_Bltz        (if_bltz),
        .IF_Bgezal      (if_bgezal),
        .IF_Bltzal      (if_bltzal),
        
        .MEM_MemWrite   (mem_memwrite),
        .MEM_Memory_sign (mem_memory_sign),
        .MEM_Memory_data_width(mem_memory_data_width),
        
        .MEM_WB_Mfhi     (mem_wb_mfhi),
        .MEM_WB_Mflo     (mem_wb_mflo),
        .MEM_WB_Mthi     (mem_wb_mthi),
        .MEM_WB_Mtlo     (mem_wb_mtlo),
        
        .MEM_WB_RegWrite(mem_wb_regwrite),
        .MEM_WB_MemIOtoReg(mem_wb_memoriotoreg),
        .IF_Branch_PC     (branch_PC),
        .MEM_ALU_Result (mem_aluresult),
        .MEM_Data_In    (mem_data_in),
        .MEM_WB_Waddr   (mem_wb_waddr)
    );
    /*
    dmemory32 memory (
        .ram_clk_i		(cpu_clk),
        .ram_wen_i	    (mem_memwrite),			    // 来自控制单元
        .ram_adr_i		(mem_aluresult[15:2]),	    // 来自memorio模块，源头是来自执行单元算出的alu_result
        .ram_dat_i		(mem_data_in),		    // 来自译码单元的read_data2
        .ram_dat_o		(read_data),		    // 从存储器中获得的数据
		// UART Programmer Pinouts
		.upg_rst_i		(upg_rst),			// UPG reset (Active High)
		.upg_clk_i		(upg_clk_o),		// UPG clock (10MHz)
		.upg_wen_i		(upg_wen_o & upg_adr_o[14]),	// UPG write enable
		.upg_adr_i		(upg_adr_o[13:0]),	// UPG write address
		.upg_dat_i		(upg_dat_o),		// UPG write data
		.upg_done_i		(upg_done_o)		// 1 if programming is finished
    );*/

    dmemory4x8 memory (
        .ram_clk_i		(cpu_clk),
        .ram_wen_i	    (mem_memwrite),			    // 来自控制单元
        .ram_adr_i		(mem_aluresult[15:0]),	    // 来自memorio模块，源头是来自执行单元算出的alu_result
        .ram_dat_i		(mem_data_in),		    // 来自译码单元的read_data2
        .ram_dat_o		(read_data),		    // 从存储器中获得的数据
		.ram_dat_width  (mem_memory_data_width),
		.ram_sign       (mem_memory_sign),
		// UART Programmer Pinouts
		.upg_rst_i		(upg_rst),			// UPG reset (Active High)
		.upg_clk_i		(upg_clk_o),		// UPG clock (10MHz)
		.upg_wen_i		(upg_wen_o & upg_adr_o[14]),	// UPG write enable
		.upg_adr_i		(upg_adr_o[13:0]),	// UPG write address
		.upg_dat_i		(upg_dat_o),		// UPG write data
		.upg_done_i		(upg_done_o)		// 1 if programming is finished
    );    
    
	MEM_WB MEM_WB(
	   .reset           (rst),
       .clock           (cpu_clk),
       .EX_MEM_RegWrite (mem_wb_regwrite),
       .EX_MEM_MemIOtoReg(mem_wb_memoriotoreg),
       .MEM_ALU_Result  (mem_aluresult),  
       .MEM_MemData     (read_data),
       .EX_MEM_waddr    (mem_wb_waddr),
       
       .EX_MEM_Mfhi     (mem_wb_mfhi),
       .EX_MEM_Mflo     (mem_wb_mflo),
       .EX_MEM_Mthi     (mem_wb_mthi),
       .EX_MEM_Mtlo     (mem_wb_mtlo),
       
       .ID_RegWrite     (id_regwrite),
       .WB_MemIOtoReg   (wb_memoriotoreg),
       
       .WB_Mfhi         (wb_mfhi),
       .WB_Mflo         (wb_mflo),
       .WB_Mthi         (wb_mthi),
       .WB_Mtlo         (wb_mtlo),
       
       .WB_ALU_Result   (wb_aluresult),
       .WB_MemData      (wb_memdata),
       .WB_waddr        (id_waddr)
	);
	
	wb wb(
        .read_data      (wb_memdata),    //从DATA RAM or I/O port取出的数据
        .ALU_result     (wb_aluresult),
        .MemIOtoReg     (wb_memoriotoreg),
        .wb_data        (wb_data)
	);
	
	CP0 CP0(
       .reset           (rst),
       .clock           (cpu_clk),
       .wen             (),        
       .PC              (),
       .write_address   (),
       .ExcCode         (),
       .data_in         (),   
       .Mfc0            (),      
       .Mtc0            (),
       .Eret            (),
       .cause_IE        (),
       .status_KSU      (),
       .read_address    (),
       .data_out        ()
    );
    
    memorio memio(
        .caddress		(alu_result),
        .address		(mem_aluresult),
        .memread		(memread),
        .memwrite		(memwrite),
        .ioread			(ioread),
        .iowrite		(iowrite),
        .mread_data		(read_data),
        .ioread_data	(ioread_data),
        .wdata			(read_data_2),
        .rdata			(rdata),
        .write_data		(write_data),
        .LEDCtrl		(ledctrl),
        .SwitchCtrl		(switchctrl)
    );
    
    ioread multiioread(
        .reset				(rst),
        .ior				(ioread),
        .switchctrl			(switchctrl),
        .ioread_data		(ioread_data),
        .ioread_data_switch	(ioread_data_switch)
    );
		
    // interface
    leds led24(
        .ledrst             (rst),
        .led_clk            (cpu_clk),
        .ledwrite           (ledctrl),
        .ledcs              (ledctrl),
        .ledaddr            (mem_aluresult[1:0]),
        .ledwdata           (write_data[15:0]),
        .ledout             (led2N4)
    );
    
    switchs switch24(
        .switrst        (rst),
        .switclk        (cpu_clk),
        .switchread     (switchctrl),
        .switchaddr     (mem_aluresult[1:0]),
        .switchcs       (switchctrl),
        .switchrdata    (ioread_data_switch),//output
        .switch_i       (switch2N4)//input
    );
endmodule
