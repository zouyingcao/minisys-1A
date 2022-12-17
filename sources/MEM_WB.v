`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/12 17:29:16
// Design Name: 
// Module Name: MEM_WB
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


module MEM_WB(
    input reset,
    input flush,
    input clock,
    input EX_MEM_RegWrite,
    input EX_MEM_MemIOtoReg,
    input EX_MEM_Mfhi,
    input EX_MEM_Mflo,
    input EX_MEM_Mthi,
    input EX_MEM_Mtlo,
    input [31:0] EX_MEM_opcplus4,
    input [31:0] EX_MEM_PC,
    input [31:0] MEM_ALU_Result,    // ALU计算的数据结果
    input [31:0] MEM_MemorIOData,
    input [31:0] EX_MEM_rt_value,
    input [4:0] EX_MEM_waddr,
    input [31:0] EX_MEM_rd,
    input EX_MEM_Jal,
    input EX_MEM_Jalr,
    input EX_MEM_Bgezal,
    input EX_MEM_Bltzal,
    input EX_MEM_Negative,
    
    input EX_MEM_Overflow,
    input EX_MEM_Divide_zero,
    input EX_MEM_Mfc0,
    input EX_MEM_Mtc0,
    input EX_MEM_Syscall,
    input EX_MEM_Break,
    input EX_MEM_Eret,
    input EX_MEM_Reserved_instruction,
    
    input MEM_backFromEret,
    output reg WB_backFromEret,
    
    output reg WB_RegWrite,
    output reg WB_MemIOtoReg,
    
    output reg WB_Mfhi,
    output reg WB_Mflo,
    output reg WB_Mthi,
    output reg WB_Mtlo,
    
    output reg WB_Jal,
    output reg WB_Jalr,
    output reg WB_Bgezal,
    output reg WB_Bltzal,
    output reg WB_Negative,
    
    output reg WB_Overflow,
    output reg WB_Divide_zero,
    output reg WB_Mfc0,
    output reg WB_Mtc0,
    output reg WB_Syscall,
    output reg WB_Break,
    output reg WB_Eret,
    output reg WB_Reserved_instruction,
    
    output reg[31:0] WB_opcplus4,
    output reg[31:0] WB_PC,
    output reg[31:0] WB_ALU_Result,
    output reg[31:0] WB_MemorIOData,
    output reg[31:0] WB_rt_value,
    output reg[31:0] WB_rd,
    output reg[4:0]  WB_waddr
    
    );
    always @(negedge clock or posedge reset) begin
        WB_backFromEret = MEM_backFromEret;
        WB_rd = EX_MEM_rd;
        if(reset||flush) begin
            WB_RegWrite = 1'b0;
            WB_MemIOtoReg = 1'b0;
            WB_Mfhi = 1'b0;
            WB_Mflo = 1'b0;
            WB_Mthi = 1'b0;
            WB_Mtlo = 1'b0;
            
            WB_Jal = 1'b0;
            WB_Jalr = 1'b0;
            WB_Bgezal = 1'b0;
            WB_Bltzal = 1'b0;
            WB_Negative = 1'b0;
            
            WB_Overflow = 1'b0;
            WB_Divide_zero = 1'b0;
            WB_Mfc0 = 1'b0;
            WB_Mtc0 = 1'b0;
            WB_Syscall = 1'b0;
            WB_Break = 1'b0;
            WB_Eret = 1'b0;
            WB_Reserved_instruction = 1'b0;
            
            WB_opcplus4 = 32'd0;
            WB_PC = 32'd0;
            WB_ALU_Result = 32'd0;
            WB_MemorIOData = 32'd0;
            WB_waddr = 5'd0;
            WB_rt_value = 32'd0;
            //WB_rd = EX_MEM_rd;
        end else begin
            WB_RegWrite = EX_MEM_RegWrite;
            WB_MemIOtoReg = EX_MEM_MemIOtoReg;
            WB_Mfhi = EX_MEM_Mfhi;
            WB_Mflo = EX_MEM_Mflo;
            WB_Mthi = EX_MEM_Mthi;
            WB_Mtlo = EX_MEM_Mtlo;
            
            WB_Jal = EX_MEM_Jal;
            WB_Jalr = EX_MEM_Jalr;
            WB_Bgezal = EX_MEM_Bgezal;
            WB_Bltzal = EX_MEM_Bltzal;
            WB_Negative = EX_MEM_Negative;
            
            WB_Overflow = EX_MEM_Overflow;
            WB_Divide_zero = EX_MEM_Divide_zero;
            WB_Mfc0 = EX_MEM_Mfc0;
            WB_Mtc0 = EX_MEM_Mtc0;
            WB_Syscall = EX_MEM_Syscall;
            WB_Break = EX_MEM_Break;
            WB_Eret = EX_MEM_Eret;
            WB_Reserved_instruction = EX_MEM_Reserved_instruction;
            
            WB_opcplus4 = EX_MEM_opcplus4;
            WB_PC = EX_MEM_PC;
            WB_ALU_Result = MEM_ALU_Result;
            WB_MemorIOData = MEM_MemorIOData;
            WB_waddr = EX_MEM_waddr;
            WB_rt_value = EX_MEM_rt_value;
            //WB_rd = EX_MEM_rd;
        end
    end
endmodule
