`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/12/10 14:20:36
// Design Name: 
// Module Name: interrupt
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


module interrupt(
    input   [4:0]   button,             // �����ť���أ�S1-S5)
    input           keyboardIn,         // ����������(����)  
    output  [5:0]   interrupt
    );
   
    assign interrupt[0] = keyboardIn;   // keyboard ���ȼ����
    assign interrupt[1] = button[0];    // S1 ��
    assign interrupt[2] = button[1];    // S2 ��
    assign interrupt[3] = button[2];    // S3 ��
    assign interrupt[4] = button[3];    // S4 ��
    assign interrupt[5] = button[4];    // S5 ��
endmodule
