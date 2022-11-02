`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: czy
// 
// Create Date: 2022/10/12 16:42:58
// Design Name: 
// Module Name: IF_ID
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

// IR与NPC
module IF_ID(
    input cpu_clk,
    input reset,
    input flush,                      // IF/ID寄存器清空信号
    input PCWrite,
    input [31:0] IF_PC,               
    input [31:0] IF_opcplus4,         //取指单元输出锁存的PC+4
    input [31:0] IF_instruction,      //取指单元输出指令
    output reg[31:0] ID_EX_PC,       
    output reg[31:0] ID_opcplus4,
    output reg[31:0] ID_instruction  
    );
    
    always @(negedge cpu_clk or posedge reset) begin
        if(reset)begin
            ID_EX_PC = 32'd0;
            ID_instruction = 32'd0;
            ID_opcplus4 = 32'd0;
        end else if(flush)begin
            ID_EX_PC = 32'd0;
            ID_instruction = 32'd0;
            ID_opcplus4 = 32'd0;
        end else if(PCWrite) begin
            ID_EX_PC = IF_PC;
            ID_instruction = IF_instruction;
            ID_opcplus4 = IF_opcplus4;
        end           
    end
endmodule
