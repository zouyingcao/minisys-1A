`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module Ifetc32 (
    // for multicycle
    input   [1:0]   Wpc,
    input           Wir,
    //
	input			reset,				// 复位信号(高电平有效)
	input           PCWrite,
    input			clock,				// 时钟(22MHz)

    input   [25:0]  Jump_PC,            // 来自ID，指令中的address部分
    input	[31:0]	Read_data_1,		// 来自译码单元，jr指令用的地址
    input           JR,
    input           J,
    input           IFBranch,
    input           nBranch, 
    input   [31:0]  ID_opcplus4,
    
    output reg[31:0]PC,              
    output  [31:0]  opcplus4,			// jal指令专用的PC+4
    output  [31:0]  Instruction,        // 输出指令到其他模块
    // output  [31:0]  PC_plus_4_out,   // (pc+4)送执行单元
    // ROM Pinouts
	output	[13:0]	rom_adr_o,			// 给程序ROM单元的取指地址
	input	[31:0]	Jpadr,				// 从程序ROM单元中获取的指令
	// 中断相关
	input   [31:0]  interrupt_PC,
	input           flush
);
    
    wire [31:0] PC_plus_4;
    reg [31:0] next_PC;		                 // 下条指令的PC（不一定是PC+4)
   
    assign Instruction = Jpadr;              // 取出指令
    assign rom_adr_o = PC[15:2];             
    assign PC_plus_4 = {PC[31:2] + 1,2'b00}; // PC+4
    assign opcplus4 = {2'b00,PC_plus_4[31:2]}; // PC+4，用于jal，$31=PC+4，右移两位以存入寄存器
    // assign PC_plus_4_out = PC_plus_4;

    wire [15:0] offset = Instruction[15:0];
    wire sign = offset[15];
    
    // next_PC是右移2位后的PC，从而保证强制对齐
    always @* begin               
        if(nBranch) next_PC = ID_opcplus4;          // ID段分支预测失败，有条件跳转指令不跳转
        else if(JR) next_PC = Read_data_1;          // jr,jalr: PC←(rs),ID段传入
        else if(J)                                  // j,jal
            next_PC = {6'b0000,Jump_PC};            // (Zero-Extend)address<<2，先左移再零扩展,右移两位的结果
        else if(IFBranch)                           // IF段预测跳转条件成立
            next_PC = {2'b00,PC_plus_4[31:2]}+{{16{sign}},offset}; // (PC)←(PC)+4+((Sign-Extend)offset<<2),右移两位的结果
        else if(flush) next_PC = interrupt_PC>>2;   // 先右移两位
        else next_PC = {2'b00,PC_plus_4[31:2]};     // 一般情况
    end
    
    always @(negedge clock) begin                   // 时钟下降沿更改PC
        if(reset) PC = 32'h00000000;
        else if(PCWrite)PC = next_PC<<2;            // 确保是4的倍数
    end
    
    /*
	// ROM Pinouts
	assign rom_adr_o = next_PC;   // 给程序ROM的取指地址
    assign PC_plus_4 = {PC[15:2]+1,2'b0};
    
    reg [31:0] IR;
    always @(negedge clock) begin
        if(reset) IR<=0;
        else if(Wir) IR<=Jpadr;
        else IR<=IR;
    end
    
    assign Instruction = IR;    //从程序ROM中来的指令
    assign PC_plus_4_out = PC;
     
    always @(negedge clock) begin 
        if(reset) PC <= 32'b0;      
        else begin
            case(Wpc)
                2'b01: if(Jmp||Jal) begin
                        opcplus4 = {2'b00,PC_plus_4[31:2]};
                        next_PC = {4'b0000,IR[27:0]<<2};
                        end
                    else next_PC = Read_data_1; // jr
                2'b10: PC[31:0] = {next_PC[29:0],2'b00};
                2'b11: next_PC = Add_result;// beq||bne
            endcase
        end
    end
 */
    
endmodule
