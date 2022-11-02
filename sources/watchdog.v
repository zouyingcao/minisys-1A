`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/24 10:36:50
// Design Name: 
// Module Name: watchdog
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


module watchdog(
    input clock,
    input reset,
    input write_enable,                 // д�ź�
    input watchdogCtrl,                 // WDTƬѡ�ź�
    output reg WDT_output               // ֪ͨCPU��λ
    );
    reg[15:0]   counter;                //������
    reg[2:0]    mini_cnt;               //С��������ʹ�ø�λ�źų���4��ʱ��
    always @(posedge clock) begin
        if (reset == 1) begin
            counter = 16'hFFFF;
            mini_cnt = 3'b000;
            WDT_output = 1'b0;
        end else begin
            if (counter == 16'd0) begin //�Ѿ�������0
                counter = 16'hFFFF;
                mini_cnt = 3'b100;      //�� CPU �� 4 ��ʱ�����ڵ� RESET �ź�
                WDT_output = 1'b1;
            end else
                counter = counter - 1'b1;
            if (mini_cnt == 3'b000)
                WDT_output = 1'b0;
            else
                mini_cnt = mini_cnt - 1'b1;
            if (write_enable) begin
                counter = 16'hFFFF;
                mini_cnt = 3'b000;
                WDT_output = 1'b0;
            end
        end
    end
endmodule
