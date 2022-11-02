`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module ioread (
    input			reset,					// ��λ�ź� 
    input			ioread,					// �ӿ���������I/O����
    input			switchCtrl,				// ��memorio������ַ�߶��߻�õĲ��뿪��ģ��Ƭѡ
    input	[15:0]	ioread_data_switch,		// ���������Ķ����ݣ��˴����Բ��뿪��
    input           keyboardCtrl,
    input   [15:0]  ioread_data_keyboard,
    input           timerCtrl,
    input   [15:0]  ioread_data_timer,
    output reg[15:0] ioread_data	       // ���������������͸�memorio
);
    
    always @* begin
        if(reset == 1)
            ioread_data = 16'b0000000000000000;
        else if(ioread == 1) begin
            if(switchCtrl == 1)
                ioread_data = ioread_data_switch;
            if(keyboardCtrl)
                ioread_data = ioread_data_keyboard;
            if(timerCtrl)
                ioread_data = ioread_data_timer;
            else   ioread_data = ioread_data;
        end
    end
endmodule
