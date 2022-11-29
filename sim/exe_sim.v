`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/08/07 21:58:34
// Design Name: 
// Module Name: exe_sim
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


module exe_sim(
    );
   // input
   reg            clock = 1'b0;
   reg    [31:0]  PC_plus_4 = 32'd0;          // PC+4
   reg    [31:0]  Read_data_1 = 32'd0;        // 从译码单元的Read_data_1中来
   reg    [31:0]  Read_data_2 = 32'd0;        // 从译码单元的Read_data_2中来
   reg    [1:0]   ALUOp = 2'b00;              // 来自控制单元的运算指令控制编码
   reg    [31:0]  Sign_extend = 32'd0;        // 从译码单元来的扩展后的立即数
   reg    [5:0]   Func = 6'b000000;           // 取指单元来的r-类型指令功能码,r-form instructions[5:0]
   reg    [5:0]   Op = 6'b000000;             // 取指单元来的操作码
   reg    [4:0]   Shamt = 5'b00000;           // 来自取指单元的instruction[10:6]，指定移位次数
   reg    [4:0]   address0 = 5'b00000;        // rt(i_format)
   reg    [4:0]   address1 = 5'b00000;        // rd
   reg            Sftmd = 1'b0;               // 来自控制单元的，表明是移位指令
   reg            DivSel = 1'b0;
   reg            ALUSrc = 1'b0;
   reg    [1:0]   ALUSrcA = 2'b00;            
   reg    [1:0]   ALUSrcB = 2'b00;
   reg            I_format = 1'b0;            // 来自控制单元，表明是除beq, bne, LW, SW之外的I-类型指令
   reg            Jrn = 1'b0;                 // 来自控制单元，书名是JR指令
   reg            RegDst = 1'b0;
   reg            Mfhi = 1'b0;                //是否为读写HI/LO寄存器的指令
   reg            Mflo = 1'b0;
   reg            Mthi = 1'b0;
   reg            Mtlo = 1'b0;            
   // forwarding
   reg   [31:0]  EX_MEM_ALU_result = 32'd0;   // 与前一条指令存在写后读冒险
   reg   [31:0]  WB_data = 32'd0;             // 只与前前条指令存在冒险
   
   // output
   wire		   Zero;				// 为1表明计算值为0 
   wire          Positive;           // rs是否为正
   wire          Negative;           // rs是否为负
   wire          Overflow;           // 是否产生加减法溢出
   wire          Divide_zero;        // 是否除0
   wire[4:0]     address;   
   wire[31:0]    ALU_Result;            // 计算的数据结果
   wire[31:0]    rt_value;
   wire[4:0]     rd;
   wire[31:0]    Add_Result;            // 计算的地址结果    

   Executs32 Uexe(clock,PC_plus_4,Read_data_1,Read_data_2,ALUOp,Sign_extend,
                     Func,Op,Shamt,address0,address1,Sftmd,DivSel,ALUSrc,
                     ALUSrcA,ALUSrcB,I_format,Jrn,RegDst,Mfhi,Mflo,Mthi,Mtlo,
                     EX_MEM_ALU_result,WB_data,Zero,Positive,Negative,Overflow,
                     Divide_zero,address,ALU_Result,rt_value,rd,Add_Result
                     );
    //要晚一个半时钟周期看到结果
    initial begin
       #200 begin   //lui 	$8,0xffff
                Sftmd = 1'b1;
                RegDst = 1'b1;
            end
       #200 begin   //lui 	$8,0xffff
                Sftmd = 1'b0;
                RegDst = 1'b0;
                
                Read_data_2 = 32'h00000008;
                ALUOp = 2'd2;
                Sign_extend = 32'hffffffff;  
                Func = 6'h3f;
                Op = 6'h0f;
                Shamt = 5'h1f;
                address0 = 5'h8;
                address1 = 5'h1f;
                ALUSrc = 1'b1;
                ALUSrcA = 2'd1;
                I_format = 1'b1;
            end 
       #200 begin   //addiu $9,$0,61 
                Read_data_2 = 32'h00000009;
                ALUOp = 2'd2;
                Sign_extend = 32'h0000003d;  
                Func = 6'h3d;
                Op = 6'h09;
                Shamt = 5'h00;
                address0 = 5'h09;
                address1 = 5'h00;
                ALUSrc = 1'b1;
                ALUSrcA = 2'd2;
                I_format = 1'b1;
                EX_MEM_ALU_result = 32'hffff0000;
            end 
       #200 begin   //andi	$10,$5,2 
                PC_plus_4 = 32'h00000001;
                Read_data_1 = 32'h00000005;
                Read_data_2 = 32'h0000000a;
                ALUOp = 2'd2;
                Sign_extend = 32'h00000002;  
                Func = 6'h02;
                Op = 6'h0c;
                Shamt = 5'h00;
                address0 = 5'h0a;
                address1 = 5'h00;
                ALUSrc = 1'b1;
                ALUSrcA = 2'd0;
                I_format = 1'b1;
                EX_MEM_ALU_result = 32'h0000003d;
                WB_data = 32'hffff0000;
            end 
       #200 begin   //mult	$8,$9
                PC_plus_4 = 32'h00000002;
                Read_data_1 = 32'hffff0000;
                Read_data_2 = 32'h00000009;
                ALUOp = 2'd2;
                Sign_extend = 32'h00000018;  
                Func = 6'h18;
                Op = 6'h00;
                Shamt = 5'h00;
                address0 = 5'h09;
                address1 = 5'h00;
                ALUSrc = 1'b0;
                ALUSrcA = 2'd0;
                ALUSrcB = 2'd2;
                I_format = 1'b0;
                RegDst = 1'b1;
                EX_MEM_ALU_result = 32'h00000000;
                WB_data = 32'h0000003d;
            end
       #200 begin   //mfhi	$10
                PC_plus_4 = 32'h00000003;
                Read_data_1 = 32'h00000000;
                Read_data_2 = 32'h00000000;
                ALUOp = 2'd2;
                Sign_extend = 32'h00005010;  
                Func = 6'h10;
                Op = 6'h00;
                Shamt = 5'h00;
                address0 = 5'h00;
                address1 = 5'h0a;
                ALUSrc = 1'b0;
                ALUSrcA = 2'd0;
                ALUSrcB = 2'd0;
                I_format = 1'b0;
                RegDst = 1'b1;
                Mfhi = 1'b1;
                EX_MEM_ALU_result = 32'hffff003d;
                WB_data = 32'h00000000;
            end
       #200 begin   //mflo	$11
                PC_plus_4 = 32'h00000004;
                Read_data_1 = 32'h00000000;
                Read_data_2 = 32'h00000000;
                ALUOp = 2'd2;
                Sign_extend = 32'h00005812;  
                Func = 6'h12;
                Op = 6'h00;
                Shamt = 5'h00;
                address0 = 5'h00;
                address1 = 5'h0b;
                ALUSrc = 1'b0;
                ALUSrcA = 2'd0;
                ALUSrcB = 2'd0;
                I_format = 1'b0;
                RegDst = 1'b1;
                Mfhi = 1'b0;
                Mflo = 1'b1;
                EX_MEM_ALU_result = 32'hffffffff;
                WB_data = 32'hffff003d;
            end 
       #200 begin   //sll	$11,$1,6
                PC_plus_4 = 32'h00000005;
                Read_data_1 = 32'h00000000;
                Read_data_2 = 32'h00000001;
                ALUOp = 2'd2;
                Sign_extend = 32'h00005980;  
                Func = 6'h00;
                Op = 6'h00;
                Shamt = 5'h06;
                address0 = 5'h01;
                address1 = 5'h0b;
                Sftmd = 1'b1;
                ALUSrc = 1'b0;
                ALUSrcA = 2'd0;
                ALUSrcB = 2'd0;
                I_format = 1'b0;
                RegDst = 1'b1;
                Mfhi = 1'b0;
                Mflo = 1'b0;
                EX_MEM_ALU_result = 32'hffc30000;
                WB_data = 32'hffffffff;
             end
       #200 begin   //beq	$12,$1,lop
                PC_plus_4 = 32'h00000006;
                Read_data_1 = 32'h0000000c;
                Read_data_2 = 32'h00000001;
                ALUOp = 2'd1;
                Sign_extend = 32'hfffffff;  
                Func = 6'h3f;
                Op = 6'h04;
                Shamt = 5'h1f;
                address0 = 5'h01;
                address1 = 5'h1f;
                Sftmd = 1'b0;
                ALUSrc = 1'b0;
                ALUSrcA = 2'd0;
                ALUSrcB = 2'd0;
                I_format = 1'b0;
                RegDst = 1'b0;
                Mfhi = 1'b0;
                Mflo = 1'b0;
                EX_MEM_ALU_result = 32'h00000040;
                WB_data = 32'hffc30000;
             end
      end
endmodule
