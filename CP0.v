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
    input			clock,
    input           wen,         //ʹ��
    input [31:0]    PC,
    input [4:0]     write_address,
    input [4:0]     ExcCode,
    input [31:0]    data_in,     //д������
    input           Mfc0,        //��Ȩָ��
    input           Mtc0,
    input           Eret,
    
    output reg[0:0] cause_IE,
    output reg[1:0] status_KSU,
    
    input [4:0]      read_address, 
    output reg[31:0] data_out
    );
    
    reg [31:0] cp0[0:31];  // cp0����32���Ĵ���
    wire [31:0] cause = cp0[13];
    wire [31:0] status = cp0[12];
    wire [31:0] epc = cp0[14];
                       
    integer i;
    always @(*) begin
        if(reset) // ��ʼ����cp0�Ĵ���ȫ����ֵ0
            for(i=0;i<32;i=i+1)    
                cp0[i]<= 0;   
        else begin
            if(Eret) begin
                // Step1. �ָ� CP0.Status.KSU ��ԭʼֵ
                cp0[12][4:3] = cause_IE;
                // Step2. �ָ� CP0.Cause.IE
                cp0[13][0] = status_KSU;
                // Step3. PC?EPC
                data_out = cp0[14];
            end else if(wen) begin
                 // Step1. ���� CP0.Cause.IE
                 cause_IE = cause[0];
                 // Step2. CP0.Cause.IE?0 �������жϣ�
                 cp0[13][0] = 1'b0;
                 // Step3. ���� CP0.Status.KSU
                 status_KSU = status[4:3];
                 // Step4. CP0.Status.KSU?0�������Ĳ㣩,KSU����CPU ��Ȩ����0 Ϊ���ļ���2 Ϊ�û���
                 cp0[12][4:3] = 2'd0;
                 // Step5. �����жϡ��쳣�źŻ�ִ�е��� Break �� SysCall ָ���д CP0.Cause.ExcCode
                 cp0[13][6:2] = ExcCode;
                 // Step6. EPC?PC�����淵�ص�ַ��
                 cp0[14] = PC;
                 // Step7. PC?�жϴ��������ڵ�ַ�������жϺ��쳣ֻ��һ����ڵ�ַ��32'h0x0000F000��
                 
                 if(Mtc0)
                    cp0[write_address] = data_in;
            end
        end
    end
    
    // Mfc0
    always @(*) begin
        if(reset)
            data_out = 32'h00000000;
        else if(Mfc0) 
            data_out = cp0[read_address];
    end
    
endmodule
