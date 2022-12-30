`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/12/09 17:37:30
// Design Name: 
// Module Name: cpu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cpu(
    input reset,
    input clock,
    
    input [31:0] rom_instruction,   // ָ��Ĵ���������ָ��
    output [13:0] iaddr,            // ��ָ��Ĵ����ĵ�ַ
    
    input [31:0] mread_data,         // ��DRAM/IO���������
    input [15:0] ioread_data,         // ��DRAM/IO���������
    output [31:0] write_data,       // 
    output [31:0] address,
    output wire mem_memwrite,
    output wire mem_memory_sign,
    output wire[1:0] mem_memory_data_width,
    
    output wire mem_iowrite,
    output wire mem_ioread,
    output wire ledctrl,
    output wire switchctrl,
    output wire timerctrl,           // 2��16λ��ʱ/������
    output wire keyboardctrl,        // 4��4���̿�����
    output wire digitaltubectrl,     // 8λ7�������
    output wire buzzerctrl,          // ������
    output wire wdtctrl,             // ���Ź�
    output wire pwmctrl,             // PWM�����ȵ���
    
    input [5:0] interrupt,       // �ⲿ�ж��ź� ������
    input mem_error
    );
     // IF�����
     wire [31:0] instruction;            // ȡ����ָ��
     wire [31:0] opcplus4;               // PC+4
     wire [31:0] pc;                     // PC
     wire if_backFromEret;
       
     // IF_ID���
     wire [31:0] id_instruction;         
     wire [31:0] id_opcplus4,id_ex_pc;
     wire id_backFromEret;
       
     // BranchTest���
     wire nBranch,ifBranch;              // Ԥ���֧����⵽����֧
     wire [31:0] if_rs;                  // ������תָ�(PC)<-(rs)
     wire JR,J,if_flush;
       
     // Control���
     wire regdst;
     wire regwrite;
     wire iowrite,ioread;                 // I/O��д�ź�
     wire memwrite,memread,memory_sign;
     wire [1:0]memory_data_width;
     wire memoriotoreg;
     wire sftmd;
     wire i_format,s_format,l_format;
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
     wire [31:0] rd_value;               // (rd)
     wire [4:0] write_address;           // д��ļĴ�����
     wire [4:0] addr0,addr1,rs;          // rt,rd,rs
     wire [31:0] sign_extend;            // ������������չ
       
     // hazard���
     wire pcwrite;                       // ���load-useð��
     wire id_ex_stall;             
             
     // ID_EX���
     wire ex_backFromEret;
     wire [31:0] ex_mem_opcplus4,ex_mem_pc,ex_dataA,ex_dataB,ex_sign_extend,ex_rd_value;
     wire [1:0] ex_aluop;
     wire ex_alusrc;
     wire [4:0] ex_address0,ex_address1,ex_rs,ex_shamt;
     wire [5:0] ex_func,ex_op;
     wire ex_regdst,ex_sftmd,ex_divsel,ex_i_format,ex_s_format,ex_l_format;
     wire ex_jr,ex_mem_jmp,ex_mem_jalr,ex_mem_jal;
     wire ex_memread,ex_mem_regwrite,ex_mem_memoriotoreg,ex_mem_memwrite,ex_mem_ioread,ex_mem_iowrite,ex_mem_memory_sign;
     wire [1:0] ex_mem_memory_data_width;
     wire ex_mem_beq,ex_mem_bne,ex_mem_bgez,ex_mem_bgtz,ex_mem_blez,ex_mem_bltz,ex_mem_bgezal,ex_mem_bltzal;
     wire ex_mem_mfhi,ex_mem_mflo,ex_mem_mtlo,ex_mem_mthi;
     wire ex_mem_mfc0,ex_mem_mtc0,ex_mem_syscall,ex_mem_break,ex_mem_eret,ex_mem_reserved_instruction;
       
     // forwarding���
     wire [1:0] ex_alusrcA,ex_alusrcB,ex_alusrcF,alusrcC,alusrcD;
       
     // EX�����
     wire [4:0] ex_address;
     wire [31:0] rt_value;
     wire [31:0] add_result;                 // PC+4+offset<<2
     wire [31:0] ex_mem_rd_value;         // (rd)
     wire [31:0] alu_result;                 // ALU������
     wire zero,positive,negative,overflow,div_zero,ex_stall;
       
     // EX_MEM���
     wire mem_backFromEret;
     wire mem_wb_zero,mem_wb_positive,mem_wb_negative;
     wire mem_wb_jmp,mem_wb_jal,mem_wb_jr,mem_wb_jalr;
     wire mem_wb_beq,mem_wb_bne,mem_wb_bgez,mem_wb_bgtz,mem_wb_blez,mem_wb_bltz,mem_wb_bgezal,mem_wb_bltzal;
     wire mem_wb_regwrite,mem_wb_memoriotoreg,mem_memread;
     wire mem_wb_mfhi,mem_wb_mflo,mem_wb_mtlo,mem_wb_mthi;
     wire mem_wb_mfc0,mem_wb_mtc0,mem_wb_overflow,mem_wb_divide_zero,mem_wb_syscall,mem_wb_break,mem_wb_eret,mem_wb_reserved_instruction;
     wire [31:0] mem_wb_opcplus4,mem_wb_pc,mem_aluresult,mem_dataB;
     wire [4:0] mem_wb_waddr;
     wire [31:0] mem_wb_rd_value;
           
     // memorio���
     wire [31:0] memoriodata;            // ��RAM��IO������
       
     // MEM_WB���
     wire wb_backFromEret;
     wire [4:0] wb_waddr;
     wire [31:0] cp0_rd_value;
     wire wb_regwrite,wb_memoriotoreg;
     wire wb_mfhi,wb_mflo,wb_mtlo,wb_mthi;
     wire wb_jal,wb_jalr,wb_bgezal,wb_bltzal,wb_negative;
     wire [31:0] wb_opcplus4,wb_pc,wb_aluresult,wb_memoriodata,cp0_rt_value;
     wire wb_mfc0,wb_mtc0,wb_overflow,wb_divide_zero,wb_syscall,wb_break,wb_eret,wb_reserved_instruction,wb_keyInterrupt,wb_tubeInterrupt;
           
     // WB�����
     wire cp0_wen,cp0_mfc0;
     wire [31:0] wb_data;
     wire [31:0] cp0_data;
     wire [31:0] cp0_pc_data;
     
     // ȡָ��Ԫ
     Ifetc32 ifetch(
              .reset          (reset),
              .ex_stall       (ex_stall),
              .clock          (clock),     
              .PCWrite        (pcwrite),
              
              .Read_data_1    (if_rs),        // (rs)ע�⣡����
              .Jump_PC        (jump_PC),      // ((Zero-Extend) ac'poddress<<2)
              .J              (J),
              .JR             (JR),
              .IFBranch       (ifBranch),
              .nBranch        (nBranch),
              .ID_opcplus4    (id_opcplus4),
              
              .opcplus4       (opcplus4),
              .PC             (pc),
              .Instruction    (instruction),
              // ROM Pinouts
              .rom_adr_o      (iaddr),
              .Jpadr          (rom_instruction),   // ����ROM�����ָ��
              // interrupt
              .interrupt_PC   (cp0_pc_data),
              .cp0_wen        (cp0_wen),
              
              .backFromEret   (wb_eret),
              .IF_backFromEret(if_backFromEret)
          );
          
          branchTest branchTest(
              .IF_op          (rom_instruction[31:26]), // �Ӷ���ifetchͬ��
              .PCWrite        (pcwrite),////////////new add
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
              .MEM_iomemRead  (mem_memread||mem_ioread),
              .memIOData      (memoriodata),
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
             .cpu_clk         (clock),
             .reset           (reset),  
             .ex_stall        (ex_stall),
             .PCWrite         (pcwrite),
             .flush           (if_flush||cp0_wen),
             .backFromEret    (if_backFromEret),
             .IF_opcplus4     (opcplus4),        
             .IF_PC           (pc),        
             .ID_backFromEret (id_backFromEret),
             .IF_instruction  (instruction),   
             .ID_opcplus4     (id_opcplus4),
             .ID_EX_PC        (id_ex_pc),
             .ID_instruction  (id_instruction)        
          );
          
          //���Ƶ�Ԫ
          control32 control(
              .Instruction    (id_instruction),
              .s_format       (ex_s_format),
              .l_format       (ex_l_format),
              .Alu_resultHigh (alu_result[31:10]),
              
              .RegDST         (regdst),
              .ALUSrc         (alusrc),
              .MemIOtoReg     (ex_mem_memoriotoreg),///
              .RegWrite       (regwrite),
              .MemRead        (ex_memread),///
              .MemWrite       (ex_mem_memwrite),///
              .IORead         (ex_mem_ioread),///
              .IOWrite        (ex_mem_iowrite),////
              
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
              .S_format       (s_format),
              .L_format       (l_format),
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
              .clock          (clock),
              .reset          (reset),
              .opcplus4       (wb_opcplus4),
              .Instruction    (id_instruction),
              .wb_data        (wb_data),
              .waddr          (wb_waddr),
              
              .read_data_1    (read_data_1),     // rs
              .read_data_2    (read_data_2),     // rt
              .write_address_0(addr0),           // rt
              .write_address_1(addr1),           // rd
              .write_data     (write_register_data),
              .write_register_address(write_address),
              .rs             (rs),
              .rd_value       (rd_value),
              .Jump_PC        (jump_PC),
              .Jal            (wb_jal),
              .Jalr           (wb_jalr),
              .Bgezal         (wb_bgezal),
              .Bltzal         (wb_bltzal),
              .Negative       (wb_negative),
              .RegWrite       (wb_regwrite),
              .Sign_extend    (sign_extend)
          );
          
          // ����load-use
          hazard hazard(
              .ex_MemRead     (ex_memread||ex_mem_ioread),
              .ex_Mfc0        (ex_mem_mfc0),
              .id_rt          (addr0),
              .id_rs          (rs),
              .ex_rt          (ex_address),
              .PC_IFWrite     (pcwrite),
              .ID_EX_stall    (id_ex_stall)
          );
         
          // rtd,A,B,NPC,E,cmd 
          ID_EX ID_EX(
              .cpu_clk        (clock),
              .ex_stall       (ex_stall),
              .flush          (cp0_wen),////
              .reset          (reset),
              .stall          (id_ex_stall),
              .ID_backFromEret(id_backFromEret),
              .ID_opcplus4    (id_opcplus4),
              .IF_ID_PC       (id_ex_pc),
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
              .ID_rd_value    (rd_value),
              .ID_RegDst      (regdst),
              .ID_Sftmd       (sftmd),    
              .ID_DivSel      (divsel),
              .ID_I_format    (i_format),
              .ID_S_format    (s_format),
              .ID_L_format    (l_format),
              .ID_Jr          (jr),
              .ID_Jmp         (jmp),
              .ID_Jal         (jal),
              .ID_Jalr        (jalr),
          
              .ID_RegWrite    (regwrite),      
              //.ID_MemIOtoReg  (memoriotoreg),
              //.ID_MemWrite    (memwrite),
              //.ID_MemRead     (memread),
              //.ID_IORead      (ioread),
              //.ID_IOWrite     (iowrite),
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
              
              .ID_Mfc0        (mfc0),
              .ID_Mtc0        (mtc0),
              .ID_Break       (break),
              .ID_Syscall     (syscall),
              .ID_Eret        (eret),
              .ID_Reserved_instruction(reserved_instruction),
              
              .EX_MEM_opcplus4(ex_mem_opcplus4),
              .EX_MEM_PC      (ex_mem_pc),
              .EX_dataA       (ex_dataA),
              .EX_dataB       (ex_dataB),
              .EX_ALUOp       (ex_aluop),
              .EX_ALUSrc      (ex_alusrc),
              .EX_address0    (ex_address0),
              .EX_address1    (ex_address1), 
              .EX_rs          (ex_rs),
              .EX_MEM_rd_value(ex_rd_value),
              .EX_func        (ex_func),
              .EX_op          (ex_op),
              .EX_shamt       (ex_shamt),
              .EX_Sign_extend (ex_sign_extend),
              .EX_RegDst      (ex_regdst),
              .EX_Sftmd       (ex_sftmd),    
              .EX_DivSel      (ex_divsel),
              .EX_I_format    (ex_i_format),
              .EX_S_format    (ex_s_format),
              .EX_L_format    (ex_l_format),
              .EX_Jr          (ex_jr),
              .EX_MEM_Jmp     (ex_mem_jmp),
              .EX_MEM_Jal     (ex_mem_jal),
              .EX_MEM_Jalr    (ex_mem_jalr),
          
              .EX_MEM_RegWrite(ex_mem_regwrite),      //��ȥEX_MEM
              //.EX_MEM_MemIOtoReg(ex_mem_memoriotoreg),
              //.EX_MEM_MemWrite(ex_mem_memwrite),
              //.EX_MemRead     (ex_memread),
              //.EX_MEM_IORead  (ex_mem_ioread),
              //.EX_MEM_IOWrite (ex_mem_iowrite),
              .EX_MEM_Memory_sign (ex_mem_memory_sign),
              .EX_MEM_Memory_data_width(ex_mem_memory_data_width),
              
              .EX_backFromEret(ex_backFromEret),
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
              .EX_MEM_Mtlo    (ex_mem_mtlo),
              
              .EX_MEM_Mfc0    (ex_mem_mfc0),
              .EX_MEM_Mtc0    (ex_mem_mtc0),
              .EX_MEM_Break   (ex_mem_break),
              .EX_MEM_Syscall (ex_mem_syscall),
              .EX_MEM_Eret    (ex_mem_eret),
              .EX_MEM_Reserved_instruction(ex_mem_reserved_instruction)
          );
      
          forwarding forwarding(
              .EX_rs          (ex_rs),            // rs
              .EX_rt          (ex_address0),      // rt
              .EX_Mflo        (ex_mem_mflo),
              .EX_Mfhi        (ex_mem_mfhi),
              
              .ID_rs          (rs),                // ID��
              .ID_rt          (addr0),            
              .ID_Mflo        (mflo),
              .ID_Mfhi        (mfhi),
              
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
              .MEM_WB_waddr   (write_address),
              .MEM_WB_Mtlo    (wb_mtlo),
              .MEM_WB_Mthi    (wb_mthi),
              
              //����Mfc0,Mtc0 ��rd�����
              .EX_rd          (ex_address1),
              
              .ALUSrcA        (ex_alusrcA),       
              .ALUSrcB        (ex_alusrcB),
              .ALUSrcF        (ex_alusrcF),
              .ALUSrcC        (alusrcC),
              .ALUSrcD        (alusrcD)
          );
      
          Executs32 execute(
              .clock          (clock), 
              .PC_plus_4      (wb_opcplus4),////????
              .Read_data_1    (ex_dataA),
              .Read_data_2    (ex_dataB),
              .read_rd_value  (ex_rd_value),
              .address0       (ex_address0),
              .address1       (ex_address1),
              .RegDst         (ex_regdst),
              .ALUOp          (ex_aluop),
              .Sign_extend    (ex_sign_extend),
              .Func           (ex_func),// func
              .Op             (ex_op),//op code
              .Shamt          (ex_shamt),
              .ALUSrc         (ex_alusrc), 
              .ALUSrcA        (ex_alusrcA),
              .ALUSrcB        (ex_alusrcB),
              .ALUSrcF        (ex_alusrcF),
              .EX_MEM_ALU_result(mem_aluresult),
              .WB_data        (write_register_data), 
              .I_format       (ex_i_format),
              .Sftmd          (ex_sftmd),
              .DivSel         (ex_divsel),
              .opcplus4       (ex_mem_opcplus4),
              .Jrn            (ex_jr),
              .Jal            (ex_mem_jal),
              .Jalr           (ex_mem_jalr),
              
              .Mfhi           (ex_mem_mfhi),
              .Mflo           (ex_mem_mflo),
              .Mthi           (ex_mem_mthi),
              .Mtlo           (ex_mem_mtlo),
              
              .ex_stall       (ex_stall),
              
              .Zero           (zero),
              .Positive       (positive),
              .Negative       (negative),
              .Overflow       (overflow),     
              .Divide_zero    (div_zero),
              .address        (ex_address),
              
              .rt_value       (rt_value),
              .rd_value       (ex_mem_rd_value),
              .ALU_Result     (alu_result),
              .Add_Result     (add_result)
          );
          
          // rtd,T,B,C,cmd 
          EX_MEM EX_MEM(
              .reset          (reset),
              .flush          (cp0_wen),
              .ex_stall       (ex_stall),
              .clock          (clock),
              
              .EX_Zero        (zero),
              .EX_Positive    (positive),
              .EX_Negative    (negative),
              .EX_rd          (ex_mem_rd_value),
              .EX_rt_value    (rt_value),
              
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
              
              .EX_Overflow    (overflow),
              .EX_Divide_zero (div_zero),
              .ID_EX_Mfc0     (ex_mem_mfc0),
              .ID_EX_Mtc0     (ex_mem_mtc0),
              .ID_EX_Break    (ex_mem_break),
              .ID_EX_Syscall  (ex_mem_syscall),
              .ID_EX_Eret     (ex_mem_eret),
              .ID_EX_Reserved_instruction(ex_mem_reserved_instruction),
              .EX_backFromEret(ex_backFromEret),
              
              .ID_EX_RegWrite (ex_mem_regwrite),
              .ID_EX_MemIOtoReg(ex_mem_memoriotoreg),
              .ID_EX_MemWrite (ex_mem_memwrite),
              .ID_EX_MemRead  (ex_memread),
              .ID_EX_IORead   (ex_mem_ioread),
              .ID_EX_IOWrite  (ex_mem_iowrite),
              .ID_EX_Memory_sign(ex_mem_memory_sign),
              .ID_EX_Memory_data_width(ex_mem_memory_data_width),
              .ID_EX_opcplus4 (ex_mem_opcplus4),
              .ID_EX_PC       (ex_mem_pc),
              
              //.EX_Add_Result  (add_result),    
              .EX_ALU_Result  (alu_result),   
              //.EX_Read_data_2 (rt_value),   
              .EX_Write_Address(ex_address),
      
              .MEM_WB_Zero    (mem_wb_zero),
              .MEM_WB_Negative(mem_wb_negative),
              .MEM_WB_Positive(mem_wb_positive),
              .MEM_WB_rd      (mem_wb_rd_value),
              //.MEM_WB_rt_value(mem_dataB),
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
              .MEM_WB_PC      (mem_wb_pc),
              
              .MEM_WB_Mfhi    (mem_wb_mfhi),
              .MEM_WB_Mflo    (mem_wb_mflo),
              .MEM_WB_Mthi    (mem_wb_mthi),
              .MEM_WB_Mtlo    (mem_wb_mtlo),
             
              .MEM_WB_Overflow(mem_wb_overflow),
              .MEM_WB_Divide_zero(mem_wb_divide_zero),
              .MEM_WB_Mfc0    (mem_wb_mfc0),
              .MEM_WB_Mtc0    (mem_wb_mtc0),
              .MEM_WB_Break   (mem_wb_break),
              .MEM_WB_Syscall (mem_wb_syscall),
              .MEM_WB_Eret    (mem_wb_eret),
              .MEM_WB_Reserved_instruction(mem_wb_reserved_instruction),
              .MEM_backFromEret(mem_backFromEret),
              
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
              .mread_data     (mread_data),
              .ioread_data    (ioread_data),
              .rdata          (memoriodata),            // ouput,mread_data��ioread_dataѡ��һ
              .wdata          (mem_dataB),
              .write_data     (write_data),
              .timerCtrl      (timerctrl),            // 2��16λ��ʱ/������
              .keyboardCtrl   (keyboardctrl),         // 4��4���̿�����
              .digtalTubeCtrl (digitaltubectrl),      // 8λ7�������
              .BuzzerCtrl     (buzzerctrl),           // ������
              .WatchdogCtrl   (wdtctrl),              // ���Ź�
              .PWMCtrl        (pwmctrl),              // PWM�����ȵ���
              .LEDCtrl        (ledctrl),
              .SwitchCtrl     (switchctrl)
          );
          
          MEM_WB MEM_WB(
             .reset           (reset),
             .flush           (cp0_wen),
             .clock           (clock),
             .EX_MEM_RegWrite (mem_wb_regwrite),
             .EX_MEM_MemIOtoReg(mem_wb_memoriotoreg),
             .EX_MEM_opcplus4 (mem_wb_opcplus4),
             .EX_MEM_PC       (mem_wb_pc),
             .MEM_ALU_Result  (mem_aluresult),  
             .MEM_MemorIOData (memoriodata),
             .EX_MEM_waddr    (mem_wb_waddr),
             .EX_MEM_rd       (mem_wb_rd_value),
             .EX_MEM_rt_value (mem_dataB),
             
             .EX_MEM_Mfhi     (mem_wb_mfhi),
             .EX_MEM_Mflo     (mem_wb_mflo),
             .EX_MEM_Mthi     (mem_wb_mthi),
             .EX_MEM_Mtlo     (mem_wb_mtlo),
             
             .EX_MEM_Overflow(mem_wb_overflow),
             .EX_MEM_Divide_zero(mem_wb_divide_zero),
             .EX_MEM_Mfc0    (mem_wb_mfc0),
             .EX_MEM_Mtc0    (mem_wb_mtc0),
             .EX_MEM_Break   (mem_wb_break),
             .EX_MEM_Syscall (mem_wb_syscall),
             .EX_MEM_Eret    (mem_wb_eret),
             .EX_MEM_Reserved_instruction(mem_wb_reserved_instruction),
             .MEM_backFromEret(mem_backFromEret),
             
             .EX_MEM_Jal      (mem_wb_jal),
             .EX_MEM_Jalr     (mem_wb_jalr),
             .EX_MEM_Bgezal   (mem_wb_bgezal),
             .EX_MEM_Bltzal   (mem_wb_bltzal),
             .EX_MEM_Negative (mem_wb_negative),
             
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
             .WB_Negative     (wb_negative),
             
             .WB_Overflow     (wb_overflow),
             .WB_Divide_zero  (wb_divide_zero),
             .WB_Mfc0         (wb_mfc0),
             .WB_Mtc0         (wb_mtc0),
             .WB_Break        (wb_break),
             .WB_Syscall      (wb_syscall),
             .WB_Eret         (wb_eret),
             .WB_Reserved_instruction(wb_reserved_instruction),
             .WB_backFromEret (wb_backFromEret),
             
             .WB_opcplus4     (wb_opcplus4),
             .WB_PC           (wb_pc),
             .WB_ALU_Result   (wb_aluresult),
             .WB_MemorIOData  (wb_memoriodata),
             .WB_rd           (cp0_rd_value),
             .WB_rt_value     (cp0_rt_value),
             .WB_waddr        (wb_waddr)
          );
          
          CP0 CP0(
             .reset           (reset),
             .clock           (clock),
                         
             .Overflow        (wb_overflow),
             .Divide_zero     (wb_divide_zero),
             .Reserved_instruction (wb_reserved_instruction),
             .Mfc0            (wb_mfc0),       
             .Mtc0            (wb_mtc0),
             .Break           (wb_break),
             .Syscall         (wb_syscall),
             .Eret            (wb_eret),
             .ExternalInterrupt(interrupt),
             .backFromEret    (wb_backFromEret),
             .memError        (mem_error),
             
             .PC              (wb_pc),
             .rt_value        (cp0_rt_value),
             .rd              (cp0_rd_value[4:0]),
             .cp0_wen         (cp0_wen),
             ///.cp0_mfc0        (cp0_mfc0),
             .cp0_data_out    (cp0_data),
             .cp0_pc_out      (cp0_pc_data)
          );
          
          wb wb(
              //.cp0_wen        (cp0_wen),
              .read_data      (wb_memoriodata),    //��DATA RAM or I/O portȡ��������
              .ALU_result     (wb_aluresult),
              .cp0_data_in    (cp0_data),
              .Mfc0           (wb_mfc0),///
              .MemIOtoReg     (wb_memoriotoreg),
              .wb_data        (wb_data)
          );
endmodule
