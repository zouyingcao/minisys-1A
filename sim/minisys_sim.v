`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/08/26 15:07:19
// Design Name: 
// Module Name: minisys_sim
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


module minisys_sim(

    );
    // input
    reg prst = 1'b1;
    reg pclk = 1'b0;
    reg [23:0] switch2N4;   
    reg [3:0] keyboardIn;
    // output
    wire [23:0] led2N4;   
    wire [3:0] keyboardOut;
    wire [7:0] digitalTube,digitalTubeEnable;
    wire pwmOut,wdtOut,buzzerOut;
    minisys my_minisys(
        .fpga_rst(prst),
        .fpga_clk(pclk),
        .switch2N4(switch2N4),         
        .led2N4(led2N4),                        // LED������������
        .keyboardIn(keyboardIn),                // ����������(����)
        .keyboardOut(keyboardOut),              // ���������(����) 
        .digitalTube(digitalTube),              // 8λ7������ܿ�����
        .digitalTubeEnable(digitalTubeEnable),  // �����ʹ���ź�A0-A7(�͵�ƽ��Ч)
        .pwmOut(pwmOut),           // PWM������
        .wdtOut(wdtOut),           // ���Ź�
        .buzzerOut(buzzerOut),     // ������
        // UART Programmer Pinouts
        .start_pg(1'b0),           // �Ӱ��ϵ�S3����������������
        .rx(1'b0),                 // UART����
        .tx()                      // UART����
    );
    
    initial begin
        #500  prst = 1'b0;
        switch2N4 = 24'h5a078f;   
        keyboardIn = 4'b1010;
    end
    always #5 pclk = ~pclk;
    
endmodule
