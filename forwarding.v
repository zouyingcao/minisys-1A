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
    input	[4:0]	ID_rs,		    // 用于分支的源操作数,rs
    input	[4:0]	ID_rt,		    // rt
    input           ID_Mflo,
    input           ID_Mfhi,
    input           ID_ALUSrc,     
    
    input	[4:0]	EX_rs,		    // 非分支
    input   [4:0]   EX_rt,        
    input           EX_Mflo,
    input           EX_Mfhi,
    input           EX_ALUSrc,     // 是否选择扩展后的立即数
    
    //用于分支源数据
    input           ID_EX_RegWrite,
    input   [4:0]   ID_EX_waddr,
    input           ID_EX_Mtlo,
    input           ID_EX_Mthi,   
    
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
    output  [1:0]   ALUSrcB,
    output  [1:0]   ALUSrcC,
    output  [1:0]   ALUSrcD//,
    //output  [1:0]   ALUSrcE
    );
    // 01:register(rs),01;EX_MEM_xxx,10:MEM_WB_xxx
    assign ALUSrcA[0] = (EX_MEM_RegWrite && EX_rs==EX_MEM_waddr) 
                        || (EX_Mflo && EX_MEM_Mtlo)    // 当前读LO,上一条指令写LO，不管上上条是否指令写LO，取的都是上一条的结果
                        || (EX_Mfhi && EX_MEM_Mthi);   
    assign ALUSrcA[1] = (MEM_WB_RegWrite && EX_rs==MEM_WB_waddr && !(EX_MEM_RegWrite && EX_rs==EX_MEM_waddr))   
                        || (EX_Mflo && !EX_MEM_Mtlo && MEM_WB_Mtlo) || (EX_Mfhi && !EX_MEM_Mthi && MEM_WB_Mthi);// 只与上上条相关
    
    // 00:register(rt),11:imm32,01:EX_MEM_xxx,10:MEM_WB_xxx
    assign ALUSrcB[0] = (EX_ALUSrc == 1)? 1:EX_MEM_RegWrite && EX_rt==EX_MEM_waddr;
    assign ALUSrcB[1] = (EX_ALUSrc == 1)? 1:MEM_WB_RegWrite && EX_rt==MEM_WB_waddr && EX_MEM_waddr!=EX_rt;
    
    // 用于分支指令源数据
    assign ALUSrcC = 
        ((ID_EX_RegWrite && ID_rs==ID_EX_waddr) || (ID_Mflo && ID_EX_Mtlo) || (ID_Mfhi && ID_EX_Mthi)) ? 2'b01:
        ((EX_MEM_RegWrite && ID_rs==EX_MEM_waddr) || (ID_Mflo && EX_MEM_Mtlo) || (ID_Mfhi && EX_MEM_Mthi)) ? 2'b10:
        ((MEM_WB_RegWrite && ID_rs==MEM_WB_waddr) || (ID_Mflo && MEM_WB_Mtlo ) || (ID_Mfhi && MEM_WB_Mthi)) ? 2'b11:
        2'b00;
    
    assign ALUSrcD = 
        (ID_EX_RegWrite && ID_rt==ID_EX_waddr) ? 2'b01:
        (EX_MEM_RegWrite && ID_rt==EX_MEM_waddr) ? 2'b10:
        (MEM_WB_RegWrite && ID_rt==MEM_WB_waddr) ? 2'b11:
        2'b00;
    
    // 用于jalr和jr的分支跳转地址（rs）
    // assign ALUSrcE = ;
endmodule
