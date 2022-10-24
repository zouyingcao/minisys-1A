`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module minisys ( 
    input			fpga_rst,	        // ���ϵ�Reset�źţ��ߵ�ƽ��λ
    input			fpga_clk,           // ���ϵ�100MHzʱ���ź�
    //2��16λ��ʱ/��������4��4���̿�������8λ7������ܿ�����
    //16λLED�����16λ���뿪�����롢PWM���ơ����Ź������������
    input   [3:0]   button,             // ��S3����ĸ���ť���أ�S1-S5)
    input	[23:0]	switch2N4,	        // ���뿪������
    input   [3:0]   keyboardIn,         // ����������(����)  
    output  [3:0]   keyboardOut,        // ���������(����) 
    output	[23:0]	led2N4,             // LED������������
    output  [7:0]   digitalTube,        // 8λ7������ܿ�����
    output  [7:0]   digitalTubeEnable,  // �����ʹ���ź�A0-A7(�͵�ƽ��Ч)
    output          buzzer,             // ������
	// UART Programmer Pinouts
	input           start_pg,           // �Ӱ��ϵ�S3����������������
	input           rx,                 // UART����
	output          tx                  // UART����
);
    // cpuclk��Ƶ�����
    wire cpu_clk;                       // cpu_clk: ��Ƶ��ʱ�ӹ���ϵͳ
    wire upg_clk;                       // ����Uart��clock

    // UART Programmer���
    wire upg_clk_o, upg_wen_o, upg_done_o;
    wire [14:0] upg_adr_o;
    wire [31:0] upg_dat_o;  
      
    wire spg_bufg;
    BUFG U1(.I(start_pg), .O(spg_bufg));// S3����ȥ��
    
    // Generate UART Programmer reset signal
    reg upg_rst;
    always @ (posedge fpga_clk) begin
        if (spg_bufg)    upg_rst = 0;
        if (fpga_rst)    upg_rst = 1;
    end
    
    wire rst;
    assign rst = fpga_rst | !upg_rst;

    cpuclk cpuclk (
        .clk_in1         (fpga_clk),    // 100MHz, ����ʱ��
        .clk_out1        (cpu_clk),     // CPU Clock (22MHz), ��ʱ��
        .clk_out2        (upg_clk)      // UPG Clock (10MHz), ���ڴ�������
    );
        
    uart_bmpg_0 uartpg (                // ��ģ���Ѿ��Ӻã�ֻ��Ϊ�������صĸ������ɲ�ȥ��ע
        .upg_clk_i        (upg_clk),    // 10MHz   
        .upg_rst_i        (upg_rst),    // �ߵ�ƽ��Ч
         // blkram signals
         .upg_clk_o       (upg_clk_o),
         .upg_wen_o       (upg_wen_o),
         .upg_adr_o       (upg_adr_o),
         .upg_dat_o       (upg_dat_o),
         .upg_done_o      (upg_done_o),
         // uart signals
         .upg_rx_i        (rx),
         .upg_tx_o        (tx)
    );
    
    // ����ROM��Ԫ���
    wire [31:0] rom_dat;                // ��ȡָ��Ԫ��ָ��
    
    // IF�����
    wire [13:0] rom_adr;                // ������ROM��Ԫ��ȡָ��ַ
    wire [31:0] instruction;            // ȡ����ָ��
    wire [31:0] opcplus4;               // PC+4
    
    // IF_ID���
    wire [31:0] id_instruction;         
    wire [31:0] id_opcplus4;
    
    // BranchTest���
    wire nBranch,ifBranch;              // Ԥ���֧����⵽����֧
    wire [31:0] if_rs;                  // ������תָ�(PC)<-(rs)
    wire JR,J,if_flush;
    
    // Control���
    wire regdst;
    wire regwrite;
    wire iowrite,ioread;	             // I/O��д�ź�
    wire memwrite,memread,memory_sign;
    wire [1:0]memory_data_width;
    wire memoriotoreg;
    wire sftmd;
    wire i_format;
    wire beq,bne,bgez,bgtz,blez,bltz,bgezal,bltzal;
    wire jmp,jal,jr,jalr;
    wire mfhi,mflo,mfc0,mthi,mtlo,mtc0;
    wire alusrc;
    wire [1:0] aluop;
    wire divsel;
    wire break,syscall,eret;
    wire reserved_instruction;
    
    // idecode���
    wire [25:0] jump_PC;                // J��ָ���е�address�ֶ�
    wire [31:0] read_data_1;            // �ӼĴ���������(rs)
    wire [31:0] read_data_2;            // �ӼĴ���������(rt)
    wire [31:0] write_register_data;    // Ҫд��Ĵ���������
    wire [4:0] addr0,addr1,rs;          // rt,rd,rs
    wire [31:0] sign_extend;            // ������������չ
    
    // hazard���
    wire pcwrite;                       // ���load-useð��
    wire id_ex_stall;             
          
    // ID_EX���
    wire [31:0] ex_mem_opcplus4,ex_dataA,ex_dataB,ex_sign_extend;
    wire [1:0] ex_aluop;
    wire ex_alusrc;
    wire [4:0] ex_address0,ex_address1,ex_rs,ex_shamt;
    wire [5:0] ex_func,ex_op;
    wire ex_regdst,ex_sftmd,ex_divsel,ex_i_format;
    wire ex_jr,ex_mem_jmp,ex_mem_jalr,ex_mem_jal;
    wire ex_memread,ex_mem_regwrite,ex_mem_memoriotoreg,ex_mem_memwrite,ex_mem_ioread,ex_mem_iowrite,ex_mem_memory_sign;
    wire [1:0] ex_mem_memory_data_width;
    wire ex_mem_beq,ex_mem_bne,ex_mem_bgez,ex_mem_bgtz,ex_mem_blez,ex_mem_bltz,ex_mem_bgezal,ex_mem_bltzal;
    wire ex_mem_mfhi,ex_mem_mflo,ex_mem_mtlo,ex_mem_mthi;
    
    // forwarding���
    wire [1:0] ex_alusrcA,ex_alusrcB,alusrcC,alusrcD;
    
    // EX�����
    wire [4:0] ex_address;
    wire [31:0] add_result;	             // PC+4+offset<<2
    wire [31:0] alu_result;	             // ALU������
    wire zero,positive,negative,overflow,div_zero;
	
	// EX_MEM���
    wire mem_wb_zero,mem_wb_positive,mem_wb_negative;
    wire mem_wb_jmp,mem_wb_jal,mem_wb_jr,mem_wb_jalr;
    wire mem_wb_beq,mem_wb_bne,mem_wb_bgez,mem_wb_bgtz,mem_wb_blez,mem_wb_bltz,mem_wb_bgezal,mem_wb_bltzal;
    wire mem_wb_regwrite,mem_wb_memoriotoreg,mem_memwrite,mem_memread,mem_ioread,mem_iowrite,mem_memory_sign;
    wire [1:0] mem_memory_data_width;
    wire mem_wb_mfhi,mem_wb_mflo,mem_wb_mtlo,mem_wb_mthi;
	wire [31:0] mem_wb_opcplus4,mem_aluresult,mem_dataB;
	wire [4:0] mem_wb_waddr;
	
	// memorio���
	wire [31:0] address;               // address to DMEM
	
	// DataMemory���
    wire [31:0] mem_data_out;	        // RAM�ж�ȡ������
	
	// MEM_WB���
    wire [4:0] wb_waddr;
    wire wb_regwrite,wb_memoriotoreg;
    wire wb_mfhi,wb_mflo,wb_mtlo,wb_mthi;
    wire wb_jal,wb_jalr,wb_bgezal,wb_bltzal,wb_negative;
    wire [31:0] wb_opcplus4,wb_aluresult,wb_memdata;
    
    // WB�����
    wire [31:0] wb_data;
	
	// �ӿ����
    wire ledctrl,switchctrl;
    wire tubectrl,keyboardctrl,buzzerctrl,pwmctrl;
    wire [15:0] ioread_data_keyboard; // ����
    wire [15:0] ioread_data_switch;   // ���뿪��
   

    wire [31:0] write_data;	           // дRAM��IO������
    wire [31:0] rdata;                // ��RAM��IO������
    wire [15:0] ioread_data;          // ��IO������
	
	// for multicycle
	wire [1:0] wpc;
	wire wir;
	wire waluresult;
	
	// ָ��洢��IMEM:����PC������ָ��
	programrom ROM (
		// Program ROM Pinouts
		.rom_clk_i		(cpu_clk),	    // ��CPU��22MHz����ʱ��
		.rom_adr_i		(rom_adr),		// ȡָ��Ԫ��ROM�ĵ�ַ��PC/4��
		.Jpadr			(rom_dat),	    // ROM�ж������ݣ�ָ�output
		// UART Programmer Pinouts, �����Ǵ����������ã��ɲ��ع�ע
		.upg_rst_i		(upg_rst),		// UPG reset (�ߵ�ƽ��Ч)
		.upg_clk_i		(upg_clk_o),	// UPG clock (10MHz)
		.upg_wen_i		(upg_wen_o & !upg_adr_o[14]),	// UPG write enable
		.upg_adr_i		(upg_adr_o[13:0]),	// UPG write address
		.upg_dat_i		(upg_dat_o),	    // UPG write data
		.upg_done_i		(upg_done_o)	    // 1 if programming is finished
	);

    // ȡָ��Ԫ
    Ifetc32 ifetch(
        //.Wpc(wpc),
        //.Wir(wir),
        .reset          (rst),
        .clock          (cpu_clk),     
        .PCWrite        (pcwrite),
        
        .Read_data_1    (if_rs),        // (rs)ע�⣡����
        .Jump_PC        (jump_PC),      // ((Zero-Extend) address<<2)
        .J              (J),
        .JR             (JR),
        .IFBranch       (ifBranch),
        .nBranch        (nBranch),
        .ID_opcpuls4    (id_opcplus4),
        
        .opcplus4       (opcplus4),
        .Instruction    (instruction),
		// ROM Pinouts
		.rom_adr_o		(rom_adr),
		.Jpadr			(rom_dat),   // ����ROM�����ָ��
		//
		.interrupt_PC   (),
        .flush          ()
    );
    
    branchTest branchTest(
        .IF_op          (rom_dat[31:26]), // �Ӷ���ifetchͬ��
        //��������ת ID��
        .Beq            (beq),
        .Bne            (bne),
        .Bgez           (bgez),
        .Bgtz           (bgtz),
        .Blez           (blez),
        .Bltz           (bltz),
        .Bgezal         (bgezal),
        .Bltzal         (bltzal),
        
        .Jrn            (jr),        
        .Jalr           (jalr),
        .Jmp            (jmp),       
        .Jal            (jal),  
        
        .ALUSrc         (alusrc),
        .ALUSrcC        (alusrcC),
        .ALUSrcD        (alusrcD),
        .read_data_1    (read_data_1),//register[rs]
        .read_data_2    (read_data_2),//register[rt]
        .Sign_extend    (sign_extend),
        .EX_ALU_result  (alu_result),
        .MEM_ALU_result (mem_aluresult),  
        .WB_data        (write_register_data),
        
        .nBranch        (nBranch),
        .IFBranch       (ifBranch),
        .J              (J),
        .JR             (JR),
        .IF_Flush       (if_flush),
        .rs             (if_rs)
    );
    
    // IR and NPC
    IF_ID IF_ID(
       .cpu_clk         (cpu_clk),
       .reset           (rst),  
       .PCWrite         (pcwrite),
       .flush           (if_flush),
       .IF_opcplus4     (opcplus4),        
       .IF_instruction  (instruction),   
       .ID_opcplus4     (id_opcplus4),
       .ID_instruction  (id_instruction)        
    );
    
    //���Ƶ�Ԫ
    control32 control(
        // new
        //.clock           (cpu_clk),
        //.reset           (rst),
        ///.zero           (zero),
        ///.Wpc            (wpc),
        ///.Wir            (wir),
        ///.Waluresult     (waluresult),
 
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

    Idecode32 idecode(
        .clock          (cpu_clk),
        .reset          (rst),
        .opcplus4       (wb_opcplus4),
        .Instruction    (id_instruction),
        .wb_data        (wb_data),
        .waddr          (wb_waddr),
        
        .read_data_1	(read_data_1),     // rs
        .read_data_2	(read_data_2),     // rt
        .write_address_0(addr0),           // rt
        .write_address_1(addr1),           // rd
        .write_data     (write_register_data),
        .rs             (rs),
        .Jump_PC        (jump_PC),
        .Jal            (wb_jal),
        .Jalr           (wb_jalr),
        .Bgezal         (wb_bgezal),
        .Bltzal         (wb_bltzal),
        .RegWrite       (wb_regwrite),
        .Sign_extend    (sign_extend),
            
        .Negative       (wb_negative),
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
    
    hazard hazard(
        .ex_MemRead     (ex_memread),
        .id_rt          (addr0),
        .id_rs          (rs),
        .ex_rt          (ex_address),
        .PC_IFWrite     (pcwrite),
        .ID_EX_stall    (id_ex_stall)
    );
   
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
        .ID_IORead      (ioread),
        .ID_IOWrite     (iowrite),
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
        
        .EX_MEM_opcplus4(ex_mem_opcplus4),
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
    
        .EX_MEM_RegWrite(ex_mem_regwrite),      //��ȥEX_MEM
        .EX_MEM_MemIOtoReg(ex_mem_memoriotoreg),
        .EX_MEM_MemWrite(ex_mem_memwrite),
        .EX_MemRead     (ex_memread),
        .EX_MEM_IORead  (ex_mem_ioread),
        .EX_MEM_IOWrite (ex_mem_iowrite),
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

    forwarding forwarding(
        .EX_rs          (ex_rs),		    // rs
        .EX_rt          (ex_address0),      // rt
        .EX_Mflo        (ex_mem_mflo),
        .EX_Mfhi        (ex_mem_mfhi),
        .EX_ALUSrc      (ex_alusrc),        // �Ƿ�ѡ����չ���������
        
        .ID_rs          (rs),		        // ID��
        .ID_rt          (addr0),            
        .ID_Mflo        (mflo),
        .ID_Mfhi        (mfhi),
        .ID_ALUSrc      (alusrc),      
        
        .ID_EX_RegWrite (ex_mem_regwrite),
        .ID_EX_waddr    (ex_address),
        .ID_EX_Mtlo     (ex_mem_mtlo),
        .ID_EX_Mthi     (ex_mem_mthi),  
        
        //��������ת��
        .EX_MEM_RegWrite(mem_wb_regwrite),
        .EX_MEM_waddr   (mem_wb_waddr),
        .EX_MEM_Mtlo    (mem_wb_mtlo),
        .EX_MEM_Mthi    (mem_wb_mthi),
         
        .MEM_WB_RegWrite(wb_regwrite),
        .MEM_WB_waddr   (wb_waddr),
        .MEM_WB_Mtlo    (wb_mtlo),
        .MEM_WB_Mthi    (wb_mthi),
    
        .ALUSrcA        (ex_alusrcA),       
        .ALUSrcB        (ex_alusrcB),
        .ALUSrcC        (alusrcC),
        .ALUSrcD        (alusrcD)
    );

    Executs32 execute(
        // new
        .clock          (cpu_clk),
        .reset          (rst),
        //.Waluresult     (waluresult),
        
        .PC_plus_4      (wb_opcplus4),
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
        .WB_data        (write_register_data), 
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
	
    // rtd,T,B,C,cmd 
    EX_MEM EX_MEM(
        .reset          (rst),
        .clock          (cpu_clk),
        
        .EX_Zero        (zero),
        .EX_Positive    (positive),
        .EX_Negative    (negative),
        
        .EX_Jr          (ex_jr),
        .ID_EX_Jalr     (ex_mem_jalr),
        .ID_EX_Jmp      (ex_mem_jmp),
        .ID_EX_Jal      (ex_mem_jal),
        
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
        .ID_EX_MemRead  (ex_memread),
        .ID_EX_IORead   (ex_mem_ioread),
        .ID_EX_IOWrite  (ex_mem_iowrite),
        .ID_EX_Memory_sign(ex_mem_memory_sign),
        .ID_EX_Memory_data_width(ex_mem_memory_data_width),
        .ID_EX_opcplus4 (ex_mem_opcplus4),
        
        .EX_Add_Result  (add_result),    
        .EX_ALU_Result  (alu_result),   
        .EX_Read_data_2 (ex_dataB),   
        .EX_Wirte_Address(ex_address),

        .MEM_WB_Zero    (mem_wb_zero),
        .MEM_WB_Negative(mem_wb_negative),
        .MEM_WB_Positive(mem_wb_positive),
        .MEM_WB_Jr      (mem_wb_jr),
        .MEM_WB_Jalr    (mem_wb_jalr),
        .MEM_WB_Jmp     (mem_wb_jmp),
        .MEM_WB_Jal     (mem_wb_jal),
        
        .MEM_WB_Beq     (mem_wb_beq),
        .MEM_WB_Bne     (mem_wb_bne),
        .MEM_WB_Bgez    (mem_wb_bgez),
        .MEM_WB_Bgtz    (mem_wb_bgtz),
        .MEM_WB_Blez    (mem_wb_blez),
        .MEM_WB_Bltz    (mem_wb_bltz),
        .MEM_WB_Bgezal  (mem_wb_bgezal),
        .MEM_WB_Bltzal  (mem_wb_bltzal),
        
        .MEM_MemWrite   (mem_memwrite),
        .MEM_MemRead    (mem_memread),
        .MEM_IORead     (mem_ioread),
        .MEM_IOWrite    (mem_iowrite),
        .MEM_Memory_sign(mem_memory_sign),
        .MEM_Memory_data_width(mem_memory_data_width),
        .MEM_WB_opcplus4(mem_wb_opcplus4),
        
        .MEM_WB_Mfhi    (mem_wb_mfhi),
        .MEM_WB_Mflo    (mem_wb_mflo),
        .MEM_WB_Mthi    (mem_wb_mthi),
        .MEM_WB_Mtlo    (mem_wb_mtlo),
        
        .MEM_WB_RegWrite(mem_wb_regwrite),
        .MEM_WB_MemIOtoReg(mem_wb_memoriotoreg),
        //.IF_Branch_PC   (branch_PC),
        .MEM_ALU_Result (mem_aluresult),
        .MEM_Data_In    (mem_dataB),
        .MEM_WB_Waddr   (mem_wb_waddr)
    );
    
    memorio memio(
        .caddress       (mem_aluresult),
        .address        (address),///////////
        .memread        (mem_memread),
        .memwrite       (mem_memwrite),
        .ioread         (mem_ioread),
        .iowrite        (mem_iowrite),
        .mread_data     (mem_data_out),
        .ioread_data    (ioread_data),
        .wdata          (mem_dataB),
        .rdata          (rdata),                // ouput,mread_data��ioread_dataѡ��һ
        .write_data     (write_data),
        .LEDCtrl        (ledctrl),
        .SwitchCtrl     (switchctrl)
    );

    dmemory4x8 memory (
        .ram_clk_i		(cpu_clk),
        .ram_wen_i	    (mem_memwrite),			// ���Կ��Ƶ�Ԫ
        .ram_adr_i		(address[15:0]),	    // ����memorioģ�飬Դͷ������ִ�е�Ԫ�����alu_result
        .ram_dat_i		(write_data),		    // �������뵥Ԫ��read_data2
        .ram_dat_o		(mem_data_out),		    // �Ӵ洢���л�õ�����
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
       .EX_MEM_opcplus4 (mem_wb_opcplus4),
       .MEM_ALU_Result  (mem_aluresult),  
       .MEM_MemData     (mem_data_out),
       .EX_MEM_waddr    (mem_wb_waddr),
       
       .EX_MEM_Mfhi     (mem_wb_mfhi),
       .EX_MEM_Mflo     (mem_wb_mflo),
       .EX_MEM_Mthi     (mem_wb_mthi),
       .EX_MEM_Mtlo     (mem_wb_mtlo),
       
       .EX_MEM_Jal      (mem_wb_jal),
       .EX_MEM_Jalr     (mem_wb_jalr),
       .EX_MEM_Bgezal   (mem_wb_bgezal),
       .EX_MEM_Bltzal   (mem_wb_bltzal),
       .EX_MEM_pnegative(mem_wb_negative),
       
       .WB_RegWrite     (wb_regwrite),
       .WB_MemIOtoReg   (wb_memoriotoreg),
       
       .WB_Mfhi         (wb_mfhi),
       .WB_Mflo         (wb_mflo),
       .WB_Mthi         (wb_mthi),
       .WB_Mtlo         (wb_mtlo),
       
       .WB_Jal          (wb_jal),
       .WB_Jalr         (wb_jalr),
       .WB_Bgezal       (wb_bgezal),
       .WB_Bltzal       (wb_bltzal),
       .WB_negative     (wb_negative),
       
       .WB_opcplus4     (wb_opcplus4),
       .WB_ALU_Result   (wb_aluresult),
       .WB_MemData      (wb_memdata),
       .WB_waddr        (wb_waddr)
	);
	
	wb wb(
        .read_data      (wb_memdata),    //��DATA RAM or I/O portȡ��������
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
