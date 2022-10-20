`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/19 16:44:03
// Design Name: 
// Module Name: wb
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


module wb(
    input  [31:0]	read_data,		// ��DATA RAM or I/O portȡ��������
    input  [31:0]   ALU_result,     // ��ִ�е�Ԫ��������Ľ������Ҫ��չ��������32λ
    input           MemIOtoReg,        
    output [31:0]   wb_data
    );
    
    assign wb_data = MemIOtoReg ? read_data : ALU_result;
    
endmodule
