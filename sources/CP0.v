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
    
    input           Overflow,
    input           Divide_zero,
    input           Reserved_instruction,
    input           Mfc0,           // 特权指令
    input           Mtc0,
    input           Break,
    input           Syscall,
    input           Eret,
    input           ExternalInterrupt,

    input [31:0]    PC,
    input [4:0]     rd,
    input [31:0]    rt_value,     //写的数据 
    output          cp0_wen,
    output reg[31:0] cp0_data_out
    );
    wire [4:0] causeExcCode;
    wire wen;
    assign causeExcCode = (Syscall) ? 5'b01000 :                // 系统调用 syscall
                          (Divide_zero) ? 5'b00111:             // 除零错误
                          (Break) ? 5'b01001 :                  // 绝对断点指令 break
                          (Reserved_instruction) ? 5'b01010 :   // 保留指令,cpu执行到一条未定义的指令
                          (Overflow) ?  5'b01100 :              // 算术溢出，有符号运算加减溢出
                          (ExternalInterrupt) ? 5'b00000 :      // 外部中断 
                          5'b11111;  
    
    reg [31:0] cp0[0:31];   // cp0包含32个寄存器
    reg cause_IE;           //
    reg [1:0] status_KSU;   // 
    assign wen = (causeExcCode!=5'b11111)&&cp0[12][0];
    assign cp0_wen = wen||Eret;
           
    integer i;
    always @(*) begin
        if(reset) begin // 初始化对cp0寄存器全部赋值0
            for(i=0;i<32;i=i+1)    
                cp0[i] = 0; 
        end else if(Mtc0) begin
            cp0[rd] = rt_value;
        end else if(Eret) begin
            // Step1. 恢复 CP0.Status.KSU 的原始值
            cp0[12][4:3] = status_KSU;
            // Step2. 恢复 CP0.Cause.IE
            cp0[13][0] = cause_IE;
            // Step3. PC<-EPC
            cp0_data_out = cp0[14];
        end else if(wen) begin // 中断响应的过程
             // Step1. 保存 CP0.Cause.IE
             cause_IE = cp0[13][0];
             // Step2. CP0.Cause.IE<-0 （屏蔽中断）
             cp0[13][0] = 1'b0;
             // Step3. 保存 CP0.Status.KSU
             status_KSU = cp0[12][4:3];
             // Step4. CP0.Status.KSU<-0（进核心层）,KSU—CPU 特权级，0 为核心级，2 为用户级
             cp0[12][4:3] = 2'b00;
             // Step5. 根据中断、异常信号或执行的是 Break 或 SysCall 指令，填写 CP0.Cause.ExcCode
             cp0[13][6:2] = causeExcCode;
             // Step6. EPC<-PC（保存返回地址）
             cp0[14] = PC;
             // Step7. PC<-中断处理程序入口地址（所有中断和异常只有一个入口地址，32'h0x0000F000）
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
