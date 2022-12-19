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
    input [3:0] column,
    input [2:0] address,            // ��keyboardģ��ĵ�ַ�Ͷ�
    output interrupt,
    output reg[15:0] read_data_output, // �͵�CPU��4x4����ֵ
    output reg[3:0] row
    );
    reg [15:0] count;
    reg [15:0] value;
    reg [2:0]  state;
    assign interrupt = state>3'd1;
    always @(negedge clock or posedge reset)
    begin
        if (reset == 1) begin
            count = 16'd0;
            value = 16'd0;
            state = 4'd0;
            row = 4'd0;
        end else begin
            case(state)
                3'b000:begin
                    row = 4'b0000;
                    count = 16'd0;
                    if(column!=4'b1111)
                        state = 3'b001;
                end
                3'b001:begin // ȥ������
                    if(count != 16'd1000) // 20ms��1000
                        count = count + 16'd1;
                    else if(column == 4'b1111) begin  //�����ʱ������ȫΪ1 ˵�������� �ص���ʼ״̬
                        state = 3'b000;
                        count = 16'd0;
                    end else begin  //�����Ȼ��ȫΪ1 ˵������м�λ���� ��ʼɨ����
                        row = 4'b1110;// �ӵ�һ�п�ʼɨ��
                        state = 3'b010;
                    end
                end
                3'b010:begin // ��һ��(1,2,3,A)
                    if(column == 4'b1111)begin
                        row = 4'b1101;
                        state = 3'b011;
                    end else begin
                        //state = 3'b000;
                        value[3:0] = row;
                        value[7:4] = column;
                        if(column == 4'b1110)
                            value[11:8] = 4'h1;
                        else if(column == 4'b1101)
                            value[11:8] = 4'h4;
                        else if(column == 4'b1011)
                            value[11:8] = 4'h7;
                        else if(column == 4'b0111)
                            value[11:8] = 4'hE;
                    end
                end 
                3'b011:begin // �ڶ���(4,5,6,B)
                    if(column == 4'b1111)begin
                        row = 4'b1011;
                        state = 3'b100;
                    end else begin
                        //state = 3'b000;
                        value[3:0] = row;
                        value[7:4] = column;
                        if(column == 4'b1110)
                            value[11:8] = 4'h2;
                        else if(column == 4'b1101)
                            value[11:8] = 4'h5;
                        else if(column == 4'b1011)
                            value[11:8] = 4'h8;
                        else if(column == 4'b0111)
                            value[11:8] = 4'h0;
                    end
                end   
                3'b100:begin // ������(7,8,9,C)
                    if(column == 4'b1111)begin
                        row = 4'b0111;
                        state = 3'b101;
                    end else begin
                        //state = 3'b000;
                        value[3:0] = row;
                        value[7:4] = column;
                        if(column == 4'b1110)
                            value[11:8] = 4'h3;
                        else if(column == 4'b1101)
                            value[11:8] = 4'h6;
                        else if(column == 4'b1011)
                            value[11:8] = 4'h9;
                        else if(column == 4'b0111)
                            value[11:8] = 4'hF;
                    end
                end  
                3'b101:begin // ������(*/E,0,#/F,D)
                    if(column == 4'b1111)begin
                        row = 4'b0000;
                        state = 3'b000;
                    end else begin
                        //state = 3'b000;
                        value[3:0] = row;
                        value[7:4] = column;
                        if(column == 4'b1110)
                            value[11:8] = 4'hA;
                        else if(column == 4'b1101)
                            value[11:8] = 4'hB;
                        else if(column == 4'b1011)
                            value[11:8] = 4'hC;
                        else if(column == 4'b0111)
                            value[11:8] = 4'hD;
                    end
                end  
            endcase
        end
     end
     always @(*)begin
        if (read_enable == 1)
        case (address)
            3'b000: read_data_output = {4'd0,value[11:0]};//{12'd0,value[11:8]}; // {4'd0,value,��,��},��ֵ�Ĵ���(0FFFFFC10H)
            3'b010: // ״̬�Ĵ���(0XFFFFFC12)
                read_data_output = (state > 3'd1) ? 16'd1:16'd0;
        endcase
     end
endmodule
