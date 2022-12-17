`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/12/14 11:48:02
// Design Name: 
// Module Name: button
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


module button(
    input clock,
    input [4:0] button,
    output reg[4:0] button_interrupt
    );
    reg        state;
    reg[15:0]  count;

    initial begin
         state = 1'b0;
    end
    
    always @(posedge clock) begin
        case(state)
            1'b0:begin
                count = 16'd0;
                button_interrupt = 5'b00000;
                if(button!=5'b00000)
                    state = 1'b1;
            end
            1'b1:begin // ȥ������
                if(count != 16'h6612)//Լ100ms
                    count = count + 8'd1;
                else if(button == 5'b00000) begin  //�����ʱ��ȫΪ0 ˵�������� ���߰�ť�ſ��� �ص���ʼ״̬
                    state = 1'b0;
                    count = 16'd0;
                end else begin  //�����Ȼ��ȫΪ0 ˵�������button���� �����ж�
                    button_interrupt = button;
                end
            end
       endcase
    end

endmodule
