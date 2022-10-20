`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module Idecode32 (
	input			reset,
    input			clock,
    input  [31:0]   opcplus4,       // 来自取指单元，JAL中用
    input  [31:0]	Instruction,	// 取指单元来的指令
    input  [31:0]	wb_data,		// 从DATA RAM or I/O port取出的数据
    input  [31:0]	ALU_result,		// 从执行单元来的运算的结果，需要扩展立即数到32位
    input  [4:0]    waddr,
    
    input			Jal,			// jal
    input			Jalr,			// jalr 
    input           Bgezal,
    input           Bltzal,
    input			RegWrite,		
    output [25:0]   Jump_PC,
    output [31:0]   read_data_1,    // 输出的第一操作数
    output [31:0]   read_data_2,    // 输出的第二操作数
    output [4:0]    write_address_1,// r-form指令要写的寄存器的号（rd）
    output [4:0]    write_address_0,// i-form指令要写的寄存器的号(rt)
    output [31:0]	Sign_extend,	// 译码单元输出的扩展后的32位立即数
    output [4:0]    rs,             // rs
    
    input           Positive,
    input           Negative,
    input           Overflow,
    input           Divide_zero,
    input           Reserved_instruction,
    input           Mfc0,           // 特权指令
    input           Mtc0,
    input           Break,
    input           Syscall,
    input           Eret,
    input  [31:0]   cp0_data_in,
    output          cp0_wen,
    output [31:0]   cp0_data_out,
    output [4:0]    causeExcCode
    
    
);
    
    reg[31:0] register[0:31];			     // 寄存器组共32个32位寄存器
    reg[4:0] write_register_address;        // 要写的寄存器的号
    reg[31:0] write_data;                   // 要写寄存器的数据放这里

    wire[4:0] rt;       // 要读的第二个寄存器的号（rt）
    wire[15:0] Instruction_immediate_value;  // 指令中的立即数
    wire[5:0] opcode;                        // 指令码
    
    assign opcode = Instruction[31:26];	                        // op
    assign rs = Instruction[25:21];                             // rs
    assign rt = Instruction[20:16];                             // rt
    assign write_address_1 = Instruction[15:11];                // rd
    assign write_address_0 = rt;                                // rt(i-form)
    assign Instruction_immediate_value = Instruction[15:0];     // immediate
    assign Jump_PC = Instruction[25:0];                         // address
    
    wire sign;                                            // 取符号位的值
    assign sign = Instruction[15];
    // andi,ori,xori,sltui零扩展, 其余符号扩展
    assign Sign_extend = (opcode==6'b001100||opcode==6'b001101||opcode==6'b001110||opcode==6'b001011) ? {16'd0,Instruction_immediate_value} : {{16{sign}},Instruction_immediate_value};
    
    assign read_data_1 = register[rs];
    assign read_data_2 = register[rt];
    
    always @* begin                                            //这个进程指定不同指令下的目标寄存器
        if(Jal || (Bgezal && !Negative) || (Bltzal && Negative))
            write_register_address = 5'd31;
        else if(Bgezal||Bltzal)
            write_register_address = 5'd0;//无效
        else 
            write_register_address = waddr;
    end
    
    always @* begin  //这个进程基本上是实现结构图中右下的多路选择器,准备要写的数据
         if(Jal || Jalr || Bgezal || Bltzal)
            write_data = opcplus4;      //($31)←(PC)+4或(rd)←(PC)+4
        else
            write_data = wb_data;
     end
    
    integer i;
    always @(posedge clock) begin       // 本进程写目标寄存器
        if(reset==1) begin              // 初始化寄存器组
            for(i=0;i<32;i=i+1) register[i] <= i;
        end else if(RegWrite==1) begin  // 注意寄存器0恒等于0
            if(write_register_address != 5'b00000)
                register[write_register_address] = write_data;
        end
    end
    
    assign causeExcCode = (Syscall) ? 5'b01000 : //系统调用 syscall
                          (Break) ? 5'b01001 : //绝对断点指令   break
                          (Reserved_instruction) ? 5'b01010 : // 保留指令,cpu执行到一条未定义的指令
                          (Overflow) ?  5'b01100 : //算术溢出，有符号运算加减溢出
                          // (keyboardbreak) ? 5'b00000 : //外部中断 
                          5'b11111;  
    assign cp0_wen = (Mfc0 || Mtc0 || Break || Syscall || Overflow || Divide_zero || Reserved_instruction);
    assign cp0_data_out = cp0_wen ? write_data:32'd0;
    
endmodule
