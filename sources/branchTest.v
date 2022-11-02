`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/20 15:57:20
// Design Name: 
// Module Name: branchTest
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 位于ID段，用于分支预测　检测是否满足分支条件
// 在流水线中提前分支指令的执行过程，从而减少需要清除的指令数
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module branchTest(
    input   [5:0]   IF_op,
    // 有条件跳转 ID段传入
    input           Beq,
    input           Bne,
    input           Bgez,
    input           Bgtz,
    input           Blez,
    input           Bltz,
    input           Bgezal,
    input           Bltzal,
    
    input			Jmp,			
    input           Jal,                
    input           Jrn,
    input           Jalr,
    
    input           ALUSrc,
    input   [1:0]   ALUSrcC,
    input   [1:0]   ALUSrcD,
    input	[31:0]	read_data_1,//register[rs]
    input	[31:0]	read_data_2,//register[rt]
    input	[31:0]	Sign_extend,
    input   [31:0]  EX_ALU_result,
    input   [31:0]  MEM_ALU_result,  
    input   [31:0]  WB_data,
    
    output          nBranch,
    output          IFBranch,
    output          J,
    output          JR,
    output          IF_Flush,
    output   [31:0] rs
    );
    
    wire [31:0] rt;
    assign rs = (ALUSrcC==2'b00) ? read_data_1 : (ALUSrcC==2'b01) ? 
    EX_ALU_result : (ALUSrcC==2'b10) ? MEM_ALU_result : WB_data;
    assign rt = (ALUSrc==1) ? Sign_extend: (ALUSrcD==2'b00) ? read_data_2 : 
    (ALUSrcD==2'b01) ? EX_ALU_result: (ALUSrcD==2'b10) ? MEM_ALU_result : WB_data;
    
    wire Zero,Negative,Positive;
    assign Zero = rs==rt;
    assign Negative = rs[31]==1'b1;
    assign Positive = (rs[31]==1'b0&&rs!=32'd0);
    
    // 有条件跳转,条件不成立时
    assign nBranch = (Beq&&!Zero)||(Bne&&Zero)||
            (Bgez&&Negative)||(Bgtz&&!Positive)||
            (Blez&&Positive)||(Bltz&&!Negative)||
            (Bgezal&&Negative)||(Bltzal&&!Negative); // (PC)←(PC)+4+((Sign-Extend)offset<<2)
    
    assign JR = Jalr||Jrn;
    assign J = Jmp||Jal;
    
    // assign IF_Flush = nBranch||JR||J;   // ID段发现预测跳转失败　或　IF段无条件跳转
    assign IF_Flush = nBranch;
    assign IFBranch = IF_op==6'b000100||IF_op==6'b000101||IF_op==6'b000111||IF_op==6'b000110||IF_op==6'b000001;

endmodule
