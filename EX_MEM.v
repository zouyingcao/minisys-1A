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
    
    input ID_EX_MemWrite,
    input ID_EX_Memory_sign,
    input [1:0] ID_EX_Memory_data_width,
    input [31:0] EX_Add_Result,     // ACU计算后的PC值
    input [31:0] EX_ALU_Result,	    // ALU计算的数据结果
    input [31:0] EX_Read_data_2,    // 32位寄存器2的值
    input [4:0]  EX_Wirte_Address,

    output reg IF_Zero,
    output reg IF_Positive,
    output reg IF_Negative,
    
    output reg IF_Beq,             //所有分支
    output reg IF_Bne,             
    output reg IF_Bgez,            
    output reg IF_Bgtz,
    output reg IF_Bltz,     
    output reg IF_Blez,        
    output reg IF_Bgezal,         
    output reg IF_Bltzal,
        
    output reg MEM_MemWrite,
    output reg MEM_Memory_sign,
    output reg [1:0] MEM_Memory_data_width,
    output reg MEM_WB_RegWrite,
    output reg MEM_WB_MemIOtoReg,
    
    output reg MEM_WB_Mfhi,
    output reg MEM_WB_Mflo,
    output reg MEM_WB_Mthi,
    output reg MEM_WB_Mtlo,
    
    output reg[31:0] IF_Branch_PC,
    output reg[31:0] MEM_ALU_Result,
    output reg[31:0] MEM_Data_In,
    output reg[4:0]  MEM_WB_Waddr
    );
    
endmodule
