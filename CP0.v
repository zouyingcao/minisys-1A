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

// 写回阶段
 module CP0(
	input			reset,
    input			clock,
    input           wen,         //使能
    input [31:0]    PC,
    input [4:0]     write_address,
    input [4:0]     ExcCode,
    input [31:0]    data_in,     //写的数据
    input           Mfc0,        //特权指令
    input           Mtc0,
    input           Eret,
    
    output reg[0:0] cause_IE,
    output reg[1:0] status_KSU,
    
    input [4:0]      read_address, 
    output reg[31:0] data_out
    );
    
    reg [31:0] cp0[0:31];  // cp0包含32个寄存器
    wire [31:0] cause = cp0[13];
    wire [31:0] status = cp0[12];
    wire [31:0] epc = cp0[14];
                       
    integer i;
    always @(*) begin
        if(reset) // 初始化对cp0寄存器全部赋值0
            for(i=0;i<32;i=i+1)    
                cp0[i]<= 0;   
        else begin
            if(Eret) begin
                // Step1. 恢复 CP0.Status.KSU 的原始值
                cp0[12][4:3] = cause_IE;
                // Step2. 恢复 CP0.Cause.IE
                cp0[13][0] = status_KSU;
                // Step3. PC?EPC
                data_out = cp0[14];
            end else if(wen) begin
                 // Step1. 保存 CP0.Cause.IE
                 cause_IE = cause[0];
                 // Step2. CP0.Cause.IE?0 （屏蔽中断）
                 cp0[13][0] = 1'b0;
                 // Step3. 保存 CP0.Status.KSU
                 status_KSU = status[4:3];
                 // Step4. CP0.Status.KSU?0（进核心层）,KSU——CPU 特权级，0 为核心级，2 为用户级
                 cp0[12][4:3] = 2'd0;
                 // Step5. 根据中断、异常信号或执行的是 Break 或 SysCall 指令，填写 CP0.Cause.ExcCode
                 cp0[13][6:2] = ExcCode;
                 // Step6. EPC?PC（保存返回地址）
                 cp0[14] = PC;
                 // Step7. PC?中断处理程序入口地址（所有中断和异常只有一个入口地址，32'h0x0000F000）
                 
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
