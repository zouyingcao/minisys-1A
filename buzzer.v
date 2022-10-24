`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/24 15:42:01
// Design Name: 
// Module Name: buzzer
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


module buzzer(
    input clock,
    input reset,
    input write_enable,     // д�ź�
    input buzzerCtrl,       // ������Ƭѡ�ź�
    input [15:0] write_data_in,
    output reg buzzer_output
    );
    reg[15:0]   maximum;         
    reg[15:0]   counter;
    always @(negedge clock) begin
        if (buzzerCtrl == 0 || reset == 1) begin
            counter = 16'h0000;
            maximum = 16'hFFFF; // ����������ʱ��
            buzzer_output = 1'b0;
        end else if (write_enable) 
            buzzer_output = write_data_in!=32'd0;
        if (buzzer_output == 1'b1) begin    
            if (counter == maximum) begin
                counter = 1'b0;
                buzzer_output = ~buzzer_output;
            end else
                counter = counter + 1'b1;
        end
    end
endmodule
