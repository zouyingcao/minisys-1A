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
	input           clock,
    
    input           Overflow,
    input           Divide_zero,
    input           Reserved_instruction,
    input           Mfc0,           // 特权指令
    input           Mtc0,
    input           Break,
    input           Syscall,
    input           Eret,
    input [5:0]     ExternalInterrupt,
    input           backFromEret,//上一条指令是Eret

    input [31:0]    PC,
    input [4:0]     rd,
    input [31:0]    rt_value,     //写的数据 
    output reg      cp0_wen,
    output reg[31:0] cp0_data_out,
    output reg[31:0] cp0_pc_out
    );
    wire [4:0] causeExcCode;
    reg wen;
    reg [31:0] cp0[0:31];   // cp0包含32个寄存器
    reg status_IE;          // 中断屏蔽
    reg [1:0] status_KSU;   // 
    
    //外部中断优先于内部中断
    assign causeExcCode = (ExternalInterrupt[0]===1'b1) ? 5'b00000 :   // 键盘外部中断
                          (ExternalInterrupt[1]===1'b1) ? 5'b01101 :   // button S1
                          (ExternalInterrupt[2]===1'b1) ? 5'b01110 :   // button S2
                          (ExternalInterrupt[3]===1'b1) ? 5'b01111 :   // button S3
                          (ExternalInterrupt[4]===1'b1) ? 5'b10000 :   // button S4
                          (ExternalInterrupt[5]===1'b1) ? 5'b10001 :   // button S5
                          (Syscall===1'b1) ? 5'b01000 :                // 系统调用 syscall
                          (Divide_zero===1'b1) ? 5'b00111:             // 除零错误
                          (Break===1'b1) ? 5'b01001 :                  // 绝对断点指令 break
                          (Reserved_instruction===1'b1) ? 5'b01010 :   // 保留指令,cpu执行到一条未定义的指令
                          (Overflow===1'b1) ?  5'b01100 :              // 算术溢出，有符号运算加减溢出
                          5'b11111;  
    integer i;                
    always @(negedge clock) begin
        if(reset) begin
            for(i=0;i<32;i=i+1)
                cp0[i] = 0; 
            cp0[12][0] = 1'b1;
            cp0[12][15:10] = 6'b111111;
        end
        wen = (causeExcCode!=5'b11111)&&(!backFromEret)&&cp0[12][0];//cp0[12][0]非中断无效
        cp0_wen = wen||Eret;  
        if(Mtc0===1'b1) begin
            cp0[rd] = rt_value;
        end else if(Eret===1'b1) begin
            // Step1. 恢复 CP0.Status.KSU 的原始值
            cp0[12][4:3] = status_KSU;
            // Step2. 恢复 CP0.Status.IE
            //cp0[12][0] = status_IE;
            cp0[12][0] = 1'b1;
            // Step3. PC<-EPC
            cp0_pc_out = cp0[14];
        end else if(wen===1'b1) begin // 中断响应的过程
            // Step1. 保存 CP0.Status.IE
            // status_IE = cp0[12][0];
            // Step2. CP0.Status.IE<-0 （屏蔽中断）
            cp0[12][0] = 1'b0;
            // Step3. 保存 CP0.Status.KSU
            status_KSU = cp0[12][4:3];
            // Step4. CP0.Status.KSU<-0（进核心层）,KSU-CPU 特权级，0 为核心级，2 为用户级
            cp0[12][4:3] = 2'b00;
            // Step5. 根据中断、异常信号或执行的是 Break 或 SysCall 指令，填写 CP0.Cause.ExcCode
            cp0[13][6:2] = causeExcCode;
            // Step6. EPC<-PC（保存返回地址）
            cp0[14] = PC;
            // Step7. PC<-中断处理程序入口地址（所有中断和异常只有一个入口地址，32'h0x0000F500）
            cp0_pc_out = 32'h0000F500;
        end
    end 
    
    always @(*) begin
        if(reset) begin // 初始化对cp0寄存器全部赋值0
            cp0_data_out = 32'h00000000;
        end else begin
            if(Mfc0===1'b1) begin
                cp0_data_out = cp0[rd];
            end 
        end
    end
    
endmodule
