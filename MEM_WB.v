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
    input clock,
    input EX_MEM_RegWrite,
    input EX_MEM_MemIOtoReg,
    input EX_MEM_Mfhi,
    input EX_MEM_Mflo,
    input EX_MEM_Mthi,
    input EX_MEM_Mtlo,
    input [31:0] EX_MEM_opcplus4,
    input [31:0] MEM_ALU_Result,    // ALU计算的数据结果
    input [31:0] MEM_MemData,
    input [4:0] EX_MEM_waddr,
    input EX_MEM_Jal,
    input EX_MEM_Jalr,
    input EX_MEM_Bgezal,
    input EX_MEM_Bltzal,
    input EX_MEM_Negative,
    
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
    
    output reg[31:0] WB_opcplus4,
    output reg[31:0] WB_ALU_Result,
    output reg[31:0] WB_MemData,
    output reg[4:0]  WB_waddr
    
    );
endmodule
