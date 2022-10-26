`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/12 17:28:53
// Design Name: 
// Module Name: EX_MEM
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


module EX_MEM(
    input reset,
    input clock,
    input EX_Zero,
    input EX_Positive,
    input EX_Negative,
    input [4:0] EX_rd,
    input [31:0] EX_rt_value,
    
    input EX_Jr,
    input ID_EX_Jalr,
    input ID_EX_Jmp,
    input ID_EX_Jal,
    
    input ID_EX_Beq,             //所有分支
    input ID_EX_Bne,             
    input ID_EX_Bgez,            
    input ID_EX_Bgtz,
    input ID_EX_Bltz,     
    input ID_EX_Blez,        
    input ID_EX_Bgezal,         
    input ID_EX_Bltzal,         
    
    input ID_EX_RegWrite,
    input ID_EX_MemIOtoReg,
    
    input ID_EX_Mfhi,
    input ID_EX_Mflo,
    input ID_EX_Mthi,
    input ID_EX_Mtlo,
    
    input EX_Divide_zero,
    input EX_Overflow,
    input ID_EX_Overflow,
    input ID_EX_Mfc0,
    input ID_EX_Mtc0,
    input ID_EX_Syscall,
    input ID_EX_Break,
    input ID_EX_Eret,
    input ID_EX_Reserved_intruction,
    
    input ID_EX_MemWrite,
    input ID_EX_MemRead,
    input ID_EX_IOWrite,
    input ID_EX_IORead,
    input ID_EX_Memory_sign,
    input [1:0] ID_EX_Memory_data_width,
    input [31:0] ID_EX_opcplus4,
    input [31:0] ID_EX_PC,
    //input [31:0] EX_Add_Result,     // ACU计算后的PC值
    input [31:0] EX_ALU_Result,	    // ALU计算的数据结果
    input [4:0]  EX_Write_Address,

    output reg MEM_WB_Zero,
    output reg MEM_WB_Positive,
    output reg MEM_WB_Negative,
    output reg[4:0] MEM_WB_rd,
    
    output reg MEM_WB_Jr,
    output reg MEM_WB_Jalr,
    output reg MEM_WB_Jmp,
    output reg MEM_WB_Jal,
    
    output reg MEM_WB_Beq,             //所有分支
    output reg MEM_WB_Bne,             
    output reg MEM_WB_Bgez,            
    output reg MEM_WB_Bgtz,
    output reg MEM_WB_Bltz,     
    output reg MEM_WB_Blez,        
    output reg MEM_WB_Bgezal,         
    output reg MEM_WB_Bltzal,
        
    output reg MEM_MemWrite,
    output reg MEM_IOWrite,
    output reg MEM_MemRead,
    output reg MEM_IORead,
    output reg MEM_Memory_sign,
    output reg [1:0] MEM_Memory_data_width,
    output reg MEM_WB_RegWrite,
    output reg MEM_WB_MemIOtoReg,
    
    output reg MEM_WB_Mfhi,
    output reg MEM_WB_Mflo,
    output reg MEM_WB_Mthi,
    output reg MEM_WB_Mtlo,
    
    output reg MEM_WB_Divide_zero,
    output reg MEM_WB_Overflow,
    output reg MEM_WB_Mfc0,
    output reg MEM_WB_Mtc0,
    output reg MEM_WB_Syscall,
    output reg MEM_WB_Break,
    output reg MEM_WB_Eret,
    output reg MEM_WB_Reserved_intruction,
    
    //output reg[31:0] IF_Branch_PC,
    output reg[31:0] MEM_WB_opcplus4,
    output reg[31:0] MEM_WB_PC,
    output reg[31:0] MEM_ALU_Result,
    output reg[31:0] MEM_Data_In,
    output reg[4:0]  MEM_WB_Waddr
    );
    always @(negedge clock) begin
        if(reset)begin
            MEM_WB_Zero = 1'd0;
            MEM_WB_Positive = 1'd0;
            MEM_WB_Negative = 1'd0;
            MEM_WB_rd = 5'd0;
            
            MEM_WB_Jr = 1'd0;
            MEM_WB_Jalr = 1'd0;
            MEM_WB_Jmp = 1'd0;
            MEM_WB_Jal = 1'd0;
            
            MEM_WB_Beq = 1'd0;
            MEM_WB_Bne = 1'd0;
            MEM_WB_Bgez = 1'd0;
            MEM_WB_Bgtz = 1'd0;
            MEM_WB_Bltz = 1'd0;
            MEM_WB_Blez = 1'd0;
            MEM_WB_Bgezal = 1'd0; 
            MEM_WB_Bltzal = 1'd0;
            
            MEM_MemWrite = 1'd0;
            MEM_IOWrite = 1'd0;
            MEM_MemRead = 1'd0;
            MEM_IORead = 1'd0;
            MEM_Memory_sign = 1'd0;
            MEM_Memory_data_width = 2'd0;
            MEM_WB_RegWrite = 1'd0;
            MEM_WB_MemIOtoReg = 1'd0;
            
            MEM_WB_Mfhi = 1'd0;
            MEM_WB_Mflo = 1'd0;
            MEM_WB_Mthi = 1'd0;
            MEM_WB_Mtlo = 1'd0;
            
            MEM_WB_Divide_zero = 1'd0;
            MEM_WB_Overflow = 1'd0;
            MEM_WB_Mfc0 = 1'd0;
            MEM_WB_Mtc0 = 1'd0;
            MEM_WB_Syscall = 1'd0;
            MEM_WB_Break = 1'd0;
            MEM_WB_Eret = 1'd0;
            MEM_WB_Reserved_intruction = 1'd0;
            
            MEM_WB_opcplus4 = 32'd0;
            MEM_WB_PC = 32'd0;
            MEM_ALU_Result = 32'd0;
            MEM_Data_In = 32'd0;
            MEM_WB_Waddr = 5'd0;
        end else begin
            MEM_WB_Zero = EX_Zero;
            MEM_WB_Positive = EX_Positive;
            MEM_WB_Negative = EX_Negative;
            MEM_WB_rd = EX_rd;
            
            MEM_WB_Jr = EX_Jr;
            MEM_WB_Jalr = ID_EX_Jalr;
            MEM_WB_Jmp = ID_EX_Jmp;
            MEM_WB_Jal = ID_EX_Jal;
            
            MEM_WB_Beq = ID_EX_Beq;
            MEM_WB_Bne = ID_EX_Bne;
            MEM_WB_Bgez = ID_EX_Bgez;
            MEM_WB_Bgtz = ID_EX_Bgtz;
            MEM_WB_Bltz = ID_EX_Bltz;
            MEM_WB_Blez = ID_EX_Blez;
            MEM_WB_Bgezal = ID_EX_Bgezal; 
            MEM_WB_Bltzal = ID_EX_Bltzal;
            
            MEM_MemWrite = ID_EX_MemWrite;
            MEM_IOWrite = ID_EX_IOWrite;
            MEM_MemRead = ID_EX_MemRead;
            MEM_IORead = ID_EX_IORead;
            MEM_Memory_sign = ID_EX_Memory_sign;
            MEM_Memory_data_width = ID_EX_Memory_data_width;
            MEM_WB_RegWrite = ID_EX_RegWrite;
            MEM_WB_MemIOtoReg = ID_EX_MemIOtoReg;
            
            MEM_WB_Mfhi = ID_EX_Mfhi;
            MEM_WB_Mflo = ID_EX_Mflo;
            MEM_WB_Mthi = ID_EX_Mthi;
            MEM_WB_Mtlo = ID_EX_Mtlo;
            
            MEM_WB_Divide_zero = EX_Divide_zero;
            MEM_WB_Overflow = EX_Overflow;
            MEM_WB_Mfc0 = ID_EX_Mfc0;
            MEM_WB_Mtc0 = ID_EX_Mtc0;
            MEM_WB_Syscall = ID_EX_Syscall;
            MEM_WB_Break = ID_EX_Break;
            MEM_WB_Eret = ID_EX_Eret;
            MEM_WB_Reserved_intruction = ID_EX_Reserved_intruction;
            
            MEM_WB_opcplus4 = ID_EX_opcplus4;
            MEM_WB_PC = ID_EX_PC;
            MEM_ALU_Result = EX_ALU_Result;
            MEM_Data_In = EX_rt_value;
            MEM_WB_Waddr = EX_Write_Address;
        end
    end
endmodule
