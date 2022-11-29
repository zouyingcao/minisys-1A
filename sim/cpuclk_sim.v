`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/07/28 23:51:45
// Design Name: 
// Module Name: cpuclk_sim
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


module cpuclk_sim(

    );
    //  INPUT
    reg pclk = 0;
    //output
    wire clock1;
    wire clock2;
    
    cpuclk UCLK(
        .clk_in1(pclk),    //100MHz
        .clk_out1(clock1),   //cpu_clk,22
        .clk_out2(clock2)   //upg_clk,10
    );
    
    always #5 pclk = ~pclk;  //5ns一个翻转，一个周期10ns，即100MHz
endmodule
