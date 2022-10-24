`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module ioread (
    input			reset,					// 复位信号 
    input			ioRead,					// 从控制器来的I/O读，
    input			switchCtrl,				// 从memorio经过地址高端线获得的拨码开关模块片选
    input	[15:0]	ioread_data_switch,		// 从外设来的读数据，此处来自拨码开关
    input           keyboardCtrl,
    input   [15:0]  ioread_data_keyboard,
    input           timerCtrl,
    input   [15:0]  ioread_data_timer,
    output	[15:0]	ioread_data				// 将外设来的数据送给memorio
);
    
    reg[15:0] ioread_data;
    
    always @* begin
        if(reset == 1)
            ioread_data = 16'b0000000000000000;
        else if(ioRead == 1) begin
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
