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
    input write_enable,     // 写信号
    input buzzerCtrl,       // 蜂鸣器片选信号
    input [15:0] write_data_in,
    output reg buzzer_output
    );
    reg[8:0]   maximum;         
    reg[8:0]   counter;
    always @(posedge clock) begin
        if (reset == 1) begin
            counter = 8'h00;
            maximum = 8'hFF; // 蜂鸣器持续时间
            buzzer_output = 1'b0;
        end else if (write_enable) 
            buzzer_output = (write_data_in!=32'd0);
        if (buzzer_output == 1'b1) begin    
            if (counter == maximum) begin
                counter = 8'd0;
                buzzer_output = ~buzzer_output;
            end else
                counter = counter + 8'd1;
        end
    end
endmodule
