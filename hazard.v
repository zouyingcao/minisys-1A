`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/19 11:23:04
// Design Name: 
// Module Name: hazard
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


module hazard(
//    input   clk,
    input   ex_MemRead,
    input   [4:0]   id_rt,
    input   [4:0]   id_rs,
    input   [4:0]   ex_rt,
//    input EX_MEM_Bgez,
//    input EX_MEM_Bgtz,
//    input EX_MEM_Blez,
//    input EX_MEM_Bltz,
//    input EX_MEM_Positive,
//    input EX_MEM_Negative,
//    input EX_MEM_Jalr,
//    input EX_MEM_Jal,
//    input EX_MEM_Zero,
//    input EX_MEM_Jmp,
//    input EX_MEM_Beq,
//    input EX_MEM_Bne,
    
//    output  reg[1:0] bubble
        output reg ID_EX_stall,
        output reg PC_IFWrite
    );
//    initial bubble = 2'd0;
    
//    always @(negedge clk)
//        begin
//            if(ex_MemRead && (id_rs==ex_rt|| id_rt==ex_rt) && bubble == 0) bubble = 1;// 当前指令与上一条指令load-use
//            else if(bubble!=0 ) bubble = bubble - 2'b01;
//            else bubble = 0;
//            if( EX_MEM_Jmp || EX_MEM_Jalr || EX_MEM_Jalr || 
//            (EX_MEM_Bne&&!EX_MEM_Zero) || (EX_MEM_Beq&&EX_MEM_Zero) ||
//            (EX_MEM_Bgez && !EX_MEM_Negative) || (EX_MEM_Bltz && EX_MEM_Negative) ||
//            (EX_MEM_Bgtz && EX_MEM_Positive) || (EX_MEM_Blez && !EX_MEM_Positive)) 
//                bubble=0;
//        end
    always @(*) begin
        if(ex_MemRead && (id_rs==ex_rt|| id_rt==ex_rt)) begin
            ID_EX_stall = 1;
            PC_IFWrite = 0;
        end else begin
            ID_EX_stall = 0;
            PC_IFWrite = 1;
        end
    end

endmodule
