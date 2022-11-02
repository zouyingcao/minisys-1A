`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/23 20:36:20
// Design Name: 
// Module Name: PWM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// �����ȵ�����
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module PWM(
    input clock,
    input reset,
    input write_enable,//д�ź�
    input pwmCtrl,//PWMƬѡ�ź�
    input [15:0] write_data_in,
    input [2:0] address,//��PWMģ��ĵ�ַ�Ͷˣ��˴�Ϊ30/32/34��
    output reg PWM_output
    );
    reg [15:0] maximum;     // ���ֵ�Ĵ�����0XFFFFFC30��
    reg [15:0] threshold;   // �ԱȼĴ�����0XFFFFFC32��
    reg [15:0] control;     // ���ƼĴ�����0XFFFFFC34��
    reg [15:0] counter;     // ������
    always @(posedge clock)
        begin
           if (reset == 1) begin
               maximum = 16'hFFFF;//�����������ֵ��Ĭ��Ϊ 0XFFFF��
               threshold = 16'h7FFF;//�Ա�ֵ��Ĭ��Ϊ 0X7FFF��
               counter = 16'h0000;
               control = 16'h0000;
               PWM_output = 1'bx;
           end else if (write_enable) begin
               case (address)
                   3'd0: maximum = write_data_in;
                   3'd2: threshold = write_data_in;
                   3'd4: control = write_data_in;
               endcase
           end else if (control[0] == 1) begin         //�������,��0λҪ��1����ʾ����PWM��������Σ�����λ��0
               if (counter >= maximum) begin
                   counter = 16'h0000;
                   PWM_output = 1'b1;
               end else begin
                   counter = counter + 1'b1;
                   if (counter > threshold)
                       PWM_output = 1'b0;
                   else
                       PWM_output = 1'b1;
               end
           end else if(control[0]==0) 
                PWM_output = 1'bx;
       end
endmodule
