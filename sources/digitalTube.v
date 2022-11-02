`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/24 13:45:37
// Design Name: 
// Module Name: digitalTube
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// ͨ��ˢ��Ƶ�ʿ�������Ϊ 500Hz��Ҳ���� 2ms ˢ��һ�Ρ�
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module digitalTube(
    input clock,
    input reset,
    input write_enable,             // д�ź�
    input digitalTubeCtrl,          // �����Ƭѡ�ź�
    input [15:0] write_data_in,     // д������ܵ�����
    input [2:0] address,            // ��keyboardģ��ĵ�ַ�Ͷˣ��˴�Ϊ00/02/04��
    output reg[7:0] enable,        // 8λ λʹ�� �ź�A0-A7���͵�ƽ��Ч
    output reg[7:0] value          // 8λ ��ʹ�� �ź�CA-DP���͵�ƽ��Ч
    );
    
    reg [15:0] lowData;             // ����λ���������
    reg [15:0] highData;            // ����λ���������
    reg [15:0] specialDisplay;      // ������ʾ�Ĵ���
    reg [7:0] choose;
    reg [3:0] datatmp;
    //��Ƶ������ˢ�����ʣ�����������ʾ��ȫ/��������
    reg        refresh;
    reg[7:0]   counter;

    
    initial begin
         counter = 8'd0;
         refresh = 1'b0;
         lowData = 16'd0;
         highData = 16'd0;
         specialDisplay = 16'd0;
         choose = 8'b00000001;
    end
     
    always @(posedge clock)
    begin
        if (counter != 8'd0)
             counter = counter - 1'd1;
        else begin
             counter = 8'd25;
             refresh = ~refresh;
        end
    end
    
    always @(posedge refresh) begin
        if(choose==8'b10000000)
            choose=8'b00000001;
        else choose=choose<<1;
        enable=~(choose&specialDisplay[15:8]); // ������ʾ�Ĵ����ĸ߰�λ��ʾ��Ӧ�˸������Ҫ��ʾ��1��ʾҪ��ʾ����
    end
    always @(choose)
        begin
            case(choose) // value[0]��DP
                8'b00000001:begin datatmp=lowData[3:0];value[0]=~specialDisplay[0];end
                8'b00000010:begin datatmp=lowData[7:4];value[0]=~specialDisplay[1];end
                8'b00000100:begin datatmp=lowData[11:8];value[0]=~specialDisplay[2];end
                8'b00001000:begin datatmp=lowData[15:12];value[0]=~specialDisplay[3];end
                8'b00010000:begin datatmp=highData[3:0];value[0]=~specialDisplay[4];end
                8'b00100000:begin datatmp=highData[7:4];value[0]=~specialDisplay[5];end
                8'b01000000:begin datatmp=highData[11:8];value[0]=~specialDisplay[6];end
                8'b10000000:begin datatmp=highData[15:12];value[0]=~specialDisplay[7];end
            default:datatmp=4'b0000;
            endcase
        end
    always @(datatmp)
        begin
            case (datatmp)
                4'b0000: value[7:1] = 7'b0000001;// CA��CB��CC������CG,�͵�ƽ��Ч
                4'b0001: value[7:1] = 7'b1001111;
                4'b0010: value[7:1] = 7'b0010010;
                4'b0011: value[7:1] = 7'b0000110;
                4'b0100: value[7:1] = 7'b1001100;
                4'b0101: value[7:1] = 7'b0100100;
                4'b0110: value[7:1] = 7'b0100000;
                4'b0111: value[7:1] = 7'b0001111;
                4'b1000: value[7:1] = 7'b0000000;
                4'b1001: value[7:1] = 7'b0000100;
                4'b1010: value[7:1] = 7'b0001000;
                4'b1011: value[7:1] = 7'b1100000;
                4'b1100: value[7:1] = 7'b0110001;
                4'b1101: value[7:1] = 7'b1000010;
                4'b1110: value[7:1] = 7'b0110000;
                4'b1111: value[7:1] = 7'b0111000;
            endcase
        end
    always @(posedge refresh or posedge reset) begin
        if (digitalTubeCtrl == 0 || reset == 1) begin
            value = 8'hff;
            enable = 8'hff;
        end else
            if (write_enable == 1)
            case (address)
                3'b000: lowData = write_data_in;
                3'b010: highData = write_data_in;
                3'b100: specialDisplay = write_data_in;
            endcase
    end
endmodule
