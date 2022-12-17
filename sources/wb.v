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
    input  [31:0]   cp0_data_in,
    input           MemIOtoReg,  
    input           Mfc0,      
    output [31:0]   wb_data
    );
    //||cp0_wen===1'b1
    assign wb_data = (Mfc0===1'b1) ? cp0_data_in : MemIOtoReg ? read_data : ALU_result;
    
endmodule
