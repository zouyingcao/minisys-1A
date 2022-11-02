`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/24 17:23:44
// Design Name: 
// Module Name: timer
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


module timer(
    input clock,
    input reset,
    input pluse0,
    input pluse1,
    input read_enable,              // ���ź�
    input write_enable,             // д�ź�
    input timerCtrl,                // ��ʱ��/������Ƭѡ�ź�
    input [2:0] address,            // ��ʽ�Ĵ�����0/2����ʼֵ�Ĵ�����4/6
    input[15:0] write_data_in,      // д��CTCģ�������
    output reg[15:0] read_data_out,// ��CTCģ�����CPU������
    output reg CTC0_output,        // �͵�ƽ��Ч
    output reg CTC1_output
    );
    reg [15:0] CNT0,CNT1;           // ��ǰֵ�Ĵ���(ֻ���Ĵ���)��0XFFFFFC24, 0XFFFFFC26��
    reg [15:0] init0,init1;         // ��ʼֵ�Ĵ���(ֻд�Ĵ���)��0XFFFFFC24, 0XFFFFFC26��
    reg [15:0] mode0,mode1;         // ��ʽ�Ĵ���(ֻд�Ĵ���)��0XFFFFFC20, 0XFFFFFC22��
    reg [15:0] status0,status1;     // ״̬�Ĵ���(ֻ���Ĵ���)��0XFFFFFC20, 0XFFFFFC22��

    always @(posedge clock) begin
        if(reset == 1) begin
            CTC0_output = 1'b1;
            CTC1_output = 1'b1;
            init0 = 16'h0000;
            init1 = 16'h0000;
            CNT0 = init0;
            CNT1 = init1;
            mode0 = 16'h0000;
            mode1 = 16'h0000;
            status0 = 16'h0000;
            status1 = 16'h0000;
        end else if(read_enable == 1)begin
            case(address) // �����ֻ���Ĵ����ķ���
                3'b000: begin
                    read_data_out = status0;
                    status0 = 16'h0000;
                end
                3'b010: begin
                    read_data_out = status1;
                    status1 = 16'h0000; // ״̬�Ĵ����ڱ���ȡ������
                end
                3'b100:read_data_out = CNT0;
                3'b110:read_data_out = CNT1;
            endcase
        end else if(write_enable==1) begin
            case(address) // �����ֻ���Ĵ����ķ���
                3'b000: begin
                    mode0 = write_data_in;
                    status0[15] = 1'b0;// ��ʽ�Ĵ������ú�û��д������ʼֵʱ��״̬�Ĵ�����Чλ��0
                    end
                3'b010: begin
                    mode1 = write_data_in;
                    status1[15] = 1'b0;
                    end
                3'b100: begin 
                    init0 = write_data_in;
                    CNT0 = init0;
                    status0[15] = 1'b1;// д�ü�����ʼֵ��״̬�Ĵ�����Чλ��1
                    end
                3'b110:begin
                    init1 = write_data_in;
                    CNT1 = init1;
                    status1[15] = 1'b1;
                    end
            endcase
        end
    end

    always @(posedge clock) begin
        if(status0[15])begin                // ��ʱ/������Ч
            CNT0 <= CNT0 - 16'd1;           // ��ǰֵ-1
            if (mode0[0] == 1'b0) begin     // ��ʱģʽ  
                if (CNT0 == 16'd1) begin   
                    status0[15] = 1'b0;     // ��ʾ��ʱ��Ч
                    status0[0] = 1'b1;      // ��ʾ��ʱ��
                    CTC0_output = 1'b0;     // ��ʱ��ʽ�У���ʱ�������¼�ʱ������1��������1��ʱ������״̬�Ĵ�������Ӧλ��������Ӧ��COUT�����һ��ʱ�ӵĵ͵�ƽ��ƽʱCOUT�Ǹߵ�ƽ��
                end
            end else begin                  // ����ģʽ
                if (CNT0 == 16'd0) begin    
                    status0[15] = 1'b0;     // ��ʾ������Ч
                    status0[1] = 1'b1;      // ��ʾ������
                    //CTC0_output = 1'b0;
                end
            end
        end
    end
    
    always @(negedge clock) begin
        if (CTC0_output == 1'b0) begin
            if (mode0[1] == 1'b1) begin // �ظ�ģʽ
                status0[15] = 1'b1;
                status0[0] = 1'b0; 
                CNT0 = init0;
                CTC0_output = 1'b1;
            end else begin // ���ظ�ģʽ
                status0[15] = 1'b0;
                CNT0 = 16'h0000;
            end
        end
    end
    
    always @(posedge clock) begin
        if(status1[15])begin            // ��ʱ/������Ч
            CNT1 <= CNT1 - 16'd1;           // ��ǰֵ-1
            if (mode1[0] == 1'b0) begin     // ��ʱģʽ  
                if (CNT1 == 16'd1) begin    // ����״̬�Ĵ�����ЧλΪ0��
                    status1[15] = 1'b0;     // ��ʾ��ʱ��Ч
                    status1[0] = 1'b1;      // ��ʾ��ʱ��
                    CTC1_output = 1'b0;     
                end
            end else begin                  // ����ģʽ
                if (CNT1 == 16'd0) begin    // ����״̬�Ĵ�����ЧλΪ0��������λΪ1
                    status1[15] = 1'b0;     // ��ʾ������Ч
                    status1[1] = 1'b1;      // ��ʾ������
                    //CTC1_output = 1'b0;
                end
            end
        end
    end
    
    // �ظ�ģʽ���
    always @(negedge clock) begin
        if (CTC1_output == 1'b0) begin
            if (mode1[1] == 1'b1) begin // �ظ�ģʽ
                status1[15] = 1'b1;
                status1[0] = 1'b0; 
                CNT1 = init1;
                CTC1_output = 1'b1;
        end else begin // ���ظ�ģʽ
                status1[15] = 1'b0;
                CNT1 = 16'h0000;
            end
        end
    end
  
endmodule
