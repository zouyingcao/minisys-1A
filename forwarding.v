`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/19 11:20:57
// Design Name: 
// Module Name: forwarding
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


module forwarding(
    input	[4:0]	rs,		    // rs
    input	[4:0]	rt,		    // rt
    input           Mflo,
    input           Mfhi,
    input           ALUSrc,     // 是否选择扩展后的立即数
    //处理数据转发
    input           EX_MEM_RegWrite,
    input   [4:0]   EX_MEM_waddr,
    input           EX_MEM_Mtlo,
    input           EX_MEM_Mthi,
     
    input           MEM_WB_RegWrite,
    input   [4:0]   MEM_WB_waddr,
    input           MEM_WB_Mtlo,
    input           MEM_WB_Mthi,

    output  [1:0]   ALUSrcA,
    output  [1:0]   ALUSrcB
    );
    // 01:register(rs),01;EX_MEM_xxx,10:MEM_WB_xxx
    assign ALUSrcA[0] = (EX_MEM_RegWrite && rs==EX_MEM_waddr) 
                        || (Mflo && EX_MEM_Mtlo)    // 当前读LO,上一条指令写LO，不管上上条是否指令写LO，取的都是上一条的结果
                        || (Mfhi && EX_MEM_Mthi);   
    assign ALUSrcA[1] = (MEM_WB_RegWrite && rs==MEM_WB_waddr && rs!=EX_MEM_waddr)   
                        || (Mflo && !EX_MEM_Mtlo && MEM_WB_Mtlo) || (Mfhi && !EX_MEM_Mthi && MEM_WB_Mthi);// 只与上上条相关
    
    // 00:register(rt),11:imm32,01:EX_MEM_xxx,10:MEM_WB_xxx
    assign ALUSrcB[0] = (ALUSrc == 1)? 1:EX_MEM_RegWrite && rt==EX_MEM_waddr;
    assign ALUSrcB[1] = (ALUSrc == 1)? 1:MEM_WB_RegWrite && rt==MEM_WB_waddr && EX_MEM_waddr!=rt;
    
endmodule
