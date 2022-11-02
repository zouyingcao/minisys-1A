`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/24 10:42:39
// Design Name: 
// Module Name: keyboard
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// ����ɨ��
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module keyboard(
    input clock,
    input reset,
    input read_enable,              // ���ź�
    input keyboardCtrl,             // ����Ƭѡ�ź�
    input [3:0] column,
    input [2:0] address,            // ��keyboardģ��ĵ�ַ�Ͷ�
    output reg[15:0] read_data_output, // �͵�CPU��4x4����ֵ
    output reg[3:0] row
    );
    reg [7:0] count;
    reg [15:0] value;
    reg [2:0]  state;

    always @(posedge clock or posedge reset)
    begin
        if (reset == 1) begin
            read_data_output = 16'd0;
            count = 8'd0;
            value = 16'd0;
            state = 4'd0;
            row = 4'd0;
        end else begin
            case(state)
                3'b000:begin
                    row = 4'b0000;
                    count = 8'd0;
                    if(column!=4'b1111)
                        state = 3'b001;
                end
                3'b001:begin // ȥ������
                    if(count != 8'd200)
                        count = count + 8'd1;
                    else if(column == 4'b1111) begin  //�����ʱ������ȫΪ1 ˵�������� �ص���ʼ״̬
                        state = 3'b000;
                        count = 8'd0;
                    end else begin  //�����Ȼ��ȫΪ1 ˵������м�λ���� ��ʼɨ����
                        row = 4'b1110;// �ӵ�һ�п�ʼɨ��
                        state = 3'b010;
                    end
                end
                3'b010:begin // ��һ��(0,F,E,D)
                    if(column == 4'b1111)begin
                        row = 4'b1101;
                        state = 3'b011;
                    end else begin
                        state = 3'b000;
                        value[3:0] = column;
                        value[7:4] = row;
                        if(column == 4'b1110)
                            value[11:8] = 4'hD;
                        else if(column == 4'b1101)
                            value[11:8] = 4'hF;
                        else if(column == 4'b1011)
                            value[11:8] = 4'h0;
                        else if(column == 4'b0111)
                            value[11:8] = 4'hE;
                    end
                end 
                3'b011:begin // �ڶ���(7,8,9,C)
                    if(column == 4'b1111)begin
                        row = 4'b1011;
                        state = 3'b100;
                    end else begin
                        state = 3'b000;
                        value[3:0] = column;
                        value[7:4] = row;
                        if(column == 4'b1110)
                            value[11:8] = 4'hC;
                        else if(column == 4'b1101)
                            value[11:8] = 4'h9;
                        else if(column == 4'b1011)
                            value[11:8] = 4'h8;
                        else if(column == 4'b0111)
                            value[11:8] = 4'h7;
                    end
                end   
                3'b100:begin // ������(4,5,6,B)
                    if(column == 4'b1111)begin
                        row = 4'b0111;
                        state = 3'b101;
                    end else begin
                        state = 3'b000;
                        value[3:0] = column;
                        value[7:4] = row;
                        if(column == 4'b1110)
                            value[11:8] = 4'hB;
                        else if(column == 4'b1101)
                            value[11:8] = 4'h6;
                        else if(column == 4'b1011)
                            value[11:8] = 4'h5;
                        else if(column == 4'b0111)
                            value[11:8] = 4'h4;
                    end
                end  
                3'b101:begin // ������(1,2,3,A)
                    if(column == 4'b1111)begin
                        row = 4'b0000;
                        state = 3'b000;
                    end else begin
                        state = 3'b000;
                        value[3:0] = column;
                        value[7:4] = row;
                        if(column == 4'b1110)
                            value[11:8] = 4'hA;
                        else if(column == 4'b1101)
                            value[11:8] = 4'h3;
                        else if(column == 4'b1011)
                            value[11:8] = 4'h2;
                        else if(column == 4'b0111)
                            value[11:8] = 4'h1;
                    end
                end  
            endcase

        if (read_enable == 1)
            case (address)
                3'b000: read_data_output = value; // {4'd0,column,row,value},��ֵ�Ĵ���(0FFFFFC10H)
                3'b010: // ״̬�Ĵ���(0XFFFFFC12)
                    read_data_output = (state > 3'd1) ? 16'd1:16'd0;
                default: read_data_output = 16'hZZZZ;
            endcase
        end
    end
endmodule
