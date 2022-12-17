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
    input  [31:0]	read_data,		// 从DATA RAM or I/O port取出的数据
    input  [31:0]   ALU_result,     // 从执行单元来的运算的结果，需要扩展立即数到32位
    input  [31:0]   cp0_data_in,
    input           MemIOtoReg,  
    input           Mfc0,      
    output [31:0]   wb_data
    );
    //||cp0_wen===1'b1
    assign wb_data = (Mfc0===1'b1) ? cp0_data_in : MemIOtoReg ? read_data : ALU_result;
    
endmodule
