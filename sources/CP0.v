`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/14 10:04:15
// Design Name: 
// Module Name: CP0
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

// д�ؽ׶�
 module CP0(
	input			reset,
    
    input           Overflow,
    input           Divide_zero,
    input           Reserved_instruction,
    input           Mfc0,           // ��Ȩָ��
    input           Mtc0,
    input           Break,
    input           Syscall,
    input           Eret,
    input           ExternalInterrupt,

    input [31:0]    PC,
    input [4:0]     rd,
    input [31:0]    rt_value,     //д������ 
    output          cp0_wen,
    output reg[31:0] cp0_data_out
    );
    wire [4:0] causeExcCode;
    wire wen;
    assign causeExcCode = (Syscall) ? 5'b01000 :                // ϵͳ���� syscall
                          (Divide_zero) ? 5'b00111:             // �������
                          (Break) ? 5'b01001 :                  // ���Զϵ�ָ�� break
                          (Reserved_instruction) ? 5'b01010 :   // ����ָ��,cpuִ�е�һ��δ�����ָ��
                          (Overflow) ?  5'b01100 :              // ����������з�������Ӽ����
                          (ExternalInterrupt) ? 5'b00000 :      // �ⲿ�ж� 
                          5'b11111;  
    
    reg [31:0] cp0[0:31];   // cp0����32���Ĵ���
    reg cause_IE;           //
    reg [1:0] status_KSU;   // 
    assign wen = (causeExcCode!=5'b11111)&&cp0[12][0];
    assign cp0_wen = wen||Eret;
           
    integer i;
    always @(*) begin
        if(reset) begin // ��ʼ����cp0�Ĵ���ȫ����ֵ0
            for(i=0;i<32;i=i+1)    
                cp0[i] = 0; 
        end else if(Mtc0) begin
            cp0[rd] = rt_value;
        end else if(Eret) begin
            // Step1. �ָ� CP0.Status.KSU ��ԭʼֵ
            cp0[12][4:3] = status_KSU;
            // Step2. �ָ� CP0.Cause.IE
            cp0[13][0] = cause_IE;
            // Step3. PC<-EPC
            cp0_data_out = cp0[14];
        end else if(wen) begin // �ж���Ӧ�Ĺ���
             // Step1. ���� CP0.Cause.IE
             cause_IE = cp0[13][0];
             // Step2. CP0.Cause.IE<-0 �������жϣ�
             cp0[13][0] = 1'b0;
             // Step3. ���� CP0.Status.KSU
             status_KSU = cp0[12][4:3];
             // Step4. CP0.Status.KSU<-0�������Ĳ㣩,KSU��CPU ��Ȩ����0 Ϊ���ļ���2 Ϊ�û���
             cp0[12][4:3] = 2'b00;
             // Step5. �����жϡ��쳣�źŻ�ִ�е��� Break �� SysCall ָ���д CP0.Cause.ExcCode
             cp0[13][6:2] = causeExcCode;
             // Step6. EPC<-PC�����淵�ص�ַ��
             cp0[14] = PC;
             // Step7. PC<-�жϴ��������ڵ�ַ�������жϺ��쳣ֻ��һ����ڵ�ַ��32'h0x0000F000��
             cp0_data_out = 32'h0000F500;
        end
    end
    
    // Mfc0
    always @(*) begin
        if(reset)
            cp0_data_out = 32'h00000000;
        else if(Mfc0) 
            cp0_data_out = cp0[rd];
    end
    
endmodule
