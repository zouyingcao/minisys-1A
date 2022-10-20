`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: czy
// 
// Create Date: 2022/10/12 16:42:58
// Design Name: 
// Module Name: IF_ID
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

// IR��NPC
module IF_ID(
    input cpu_clk,
    input reset,
    input PCWrite,
    input [31:0] IF_PC,              //ȡָ��Ԫ���PC
    input [31:0] IF_opcplus4,        //ȡָ��Ԫ��������PC+4
    input [31:0] IF_instruction,     //ȡָ��Ԫ���ָ��
    output reg[31:0] ID_PC,         //���뵥Ԫ����PC
    output reg[31:0] ID_opcplus4,
    output reg[31:0] ID_instruction,//���뵥Ԫ����ָ��
    // ������ˮ����ͣ�Լ��쳣����
    input stall,                    // ��ˮ����ͣ�ź�
    input clean                     // IF/ID�Ĵ�������ź�
    );
    
    always @(posedge cpu_clk) begin
        if(reset)begin
            ID_PC = 32'd0;
            ID_instruction = 32'd0;
            ID_opcplus4 = 32'd0;
        end else if(clean)begin
            ID_PC = 32'd0;
            ID_instruction = 32'd0;
            ID_opcplus4 = 32'd0;
        end if(stall) begin
            ID_PC = ID_PC;
            ID_instruction = ID_instruction;
            ID_opcplus4 = ID_opcplus4;
        end else if(PCWrite) begin
            ID_PC = IF_PC;
            ID_instruction = IF_instruction;
            ID_opcplus4 = IF_opcplus4;
        end           
    end
endmodule
