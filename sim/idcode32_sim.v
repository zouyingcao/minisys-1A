`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/29 10:27:17
// Design Name: 
// Module Name: idcode32_sim
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


module idcode32_sim(
    );
    // input 
    reg        reset = 1'b1;
    reg        clock = 1'b0;
    reg[31:0]  opcplus4 = 32'h00000000;         // 来自取指单元，JAL中用
    reg[31:0]  Instruction = 32'h00000000;      // 取指单元来的指令，add $7,$2,$3
    reg[31:0]  wb_data = 32'h00000000;          // 从DATA RAM or I/O port取出的数据        
    reg[31:0]  ALU_result = 32'h00000000;       // 从执行单元来的运算的结果，需要扩展立即数到32位
    reg[4:0]   waddr = 5'b00000;                    

    reg        Jal = 1'b0; 
    reg        Jalr = 1'b0; 
    reg        Bgezal = 1'b0;
    reg        Bltzal = 1'b0;
    reg        Negative = 1'b0;
    reg        RegWrite = 1'b0;  
    
    // output
    wire [25:0]   Jump_PC;
    wire [31:0]   read_data_1;    // 输出的第一操作数
    wire [31:0]   read_data_2;    // 输出的第二操作数
    wire [4:0]    write_address_1;// r-form指令要写的寄存器的号（rd）
    wire [4:0]    write_address_0;// i-form指令要写的寄存器的号(rt)
    wire [31:0]   write_data;     // 要写入寄存器的数据
    wire [31:0]   Sign_extend;    // 译码单元输出的扩展后的32位立即数
    wire [4:0]    rs;             // rs
    
    Idecode32 Uid(reset,clock,opcplus4,Instruction,wb_data,
                     ALU_result,waddr,Jal,Jalr,Bgezal,Bltzal,Negative,RegWrite,
                     Jump_PC,read_data_1,read_data_2,write_address_1,write_address_0,
                     write_data,Sign_extend,rs);

    initial begin
        #200   reset = 1'b0;
        #200   begin Instruction = 32'h3c08ffff;  //lui 	$8,0xffff
               end
        #100   begin Instruction = 32'h2409003d;  //addiu $9,$0,61
               end
        #100   begin Instruction = 32'h01095020;  //add	$10,$8,$9
                     RegWrite = 1'b1;
               end
        #100   begin Instruction = 32'h0c000005;  //jal 	lop1
                     opcplus4 = 32'h00000001; 
                     wb_data = 32'hffff0000;
                     waddr = 5'h8;
               end
        #100   begin Instruction = 32'h00000000;
                     opcplus4 = 32'h00000002; 
                     wb_data = 32'h0000003d;
                     waddr = 5'h9;
               end
        #100   begin Instruction = 32'h05910002;  //bgezal $12,2
                     opcplus4 = 32'h00000003;
                     wb_data = 32'hffff003d;
                     waddr = 5'ha; 
               end
        #100   begin Instruction = 32'h04100003;  //bltzal $0,3
                     opcplus4 = 32'h00000004;
                     wb_data = 32'h00000000;
                     waddr = 5'h0; 
                     Jal=1'b1;
               end
        #100   begin Instruction = 32'h00000000;
                     opcplus4 = 32'h00000000; 
                     wb_data = 32'h00000030;
                     waddr = 5'h0;
                     Jal=1'b0;
               end
        #100   begin Instruction = 32'h0000f009;  //jalr	$30,$0
                     opcplus4 = 32'h00000006;
                     wb_data = 32'hfffffffb;
                     waddr = 5'h11; 
                     Bgezal=1'b1;
               end
        #100   begin Instruction = 32'h00000000;  //jalr	$30,$0
                     opcplus4 = 32'h00000009;
                     wb_data = 32'hfffffff0;
                     waddr = 5'h10; 
                     Bgezal=1'b0;
                     Bltzal=1'b1;
               end
        #100   begin Instruction = 32'h3c08ffff; 
                     opcplus4 = 32'h00000000;
                     wb_data = 32'h00000000;
                     waddr = 5'h00; 
                     Bltzal=1'b0;
               end
        #100   begin 
                     opcplus4 = 32'h0000000a;
                     waddr = 5'h1e;
                     Jalr=1'b1;
               end
    end 
    always #50 clock = ~clock;            
    //要延迟三个半周期看到写的结果
endmodule
