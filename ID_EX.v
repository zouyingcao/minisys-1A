`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: czy
// 
// Create Date: 2022/10/12 17:24:54
// Design Name: 
// Module Name: ID_EX
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 流水级ID-EX之间的寄存器
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ID_EX(
    input cpu_clk,
    input reset,
    input stall,
    input [31:0] ID_opcplus4,
    input [31:0] ID_dataA,
    input [31:0] ID_dataB,
    input [1:0]  ID_ALUOp,
    input        ID_ALUSrc,
    input [5:0]  ID_func,
    input [5:0]  ID_op,
    input [4:0]  ID_shamt,
    input [31:0] ID_Sign_extend,
    input [4:0]  ID_address0,
    input [4:0]  ID_address1,
    input [4:0]  ID_rs,
    input ID_RegDst,
    input ID_Sftmd,	
    input ID_DivSel,
    input ID_I_format,
    input ID_Jr,
    input ID_Jalr,
    input ID_Jmp,
    input ID_Jal,
    
    input ID_RegWrite,      //传去EX_MEM
    input ID_MemIOtoReg,
    input ID_MemWrite,
    input ID_MemRead,
    input ID_Memory_sign,
    input [1:0] ID_Memory_data_width,
    
    input ID_Beq,             //所有分支
    input ID_Bne,             
    input ID_Bgez,            
    input ID_Bgtz, 
    input ID_Bltz,    
    input ID_Blez,        
    input ID_Bgezal,         
    input ID_Bltzal,
         
    input ID_Mflo,
    input ID_Mfhi,
    input ID_Mtlo,
    input ID_Mthi,
    
    output reg[31:0] EX_opcplus4,
    output reg[31:0] EX_dataA,
    output reg[31:0] EX_dataB,
    output reg[1:0]  EX_ALUOp,
    output reg       EX_ALUSrc,
    output reg[4:0]  EX_address0,
    output reg[4:0]  EX_address1,
    output reg[4:0]  EX_rs,
    output reg[5:0]  EX_func,
    output reg[5:0]  EX_op,
    output reg[4:0]  EX_shamt,
    output reg[31:0] EX_Sign_extend,
    output reg EX_RegDst,
    output reg EX_Sftmd,    
    output reg EX_DivSel,
    output reg EX_I_format,
    output reg EX_Jr,
    output reg EX_MEM_Jalr,
    output reg EX_MEM_Jmp,
    output reg EX_MEM_Jal,
    
    output reg EX_MEM_RegWrite,      //传去EX_MEM
    output reg EX_MEM_MemIOtoReg,
    output reg EX_MEM_MemWrite,
    output reg EX_MemRead,
    output reg EX_MEM_Memory_sign,
    output reg [1:0] EX_MEM_Memory_data_width,
    
    output reg EX_MEM_Beq,             //所有分支
    output reg EX_MEM_Bne,             
    output reg EX_MEM_Bgez,            
    output reg EX_MEM_Bgtz,  
    output reg EX_MEM_Bltz,   
    output reg EX_MEM_Blez,        
    output reg EX_MEM_Bgezal,         
    output reg EX_MEM_Bltzal,
    
    output reg EX_MEM_Mflo,
    output reg EX_MEM_Mfhi,
    output reg EX_MEM_Mtlo,
    output reg EX_MEM_Mthi
    );
    
    always @(posedge cpu_clk) begin
        if(reset)begin
            EX_opcplus4 = 32'd0;
            EX_dataA = 32'd0;
            EX_dataB = 32'd0;
            EX_ALUOp = 2'd0;
            EX_ALUSrc = 1'd0;
            EX_address0 = 5'd0;
            EX_address1 = 5'd0;
            EX_rs = 5'd0;
            EX_func = 6'd0;
            EX_op = 6'd0;
            EX_shamt = 5'd0;
            EX_Sign_extend = 32'd0;
            EX_RegDst = 1'd0;
            EX_Sftmd = 1'd0;    
            EX_DivSel = 1'd0;
            EX_I_format = 1'd0;
            EX_Jr = 1'd0;
            EX_MEM_Jalr = 1'd0;
            EX_MEM_Jmp = 1'd0;
            EX_MEM_Jal = 1'd0;
        
            EX_MEM_RegWrite = 1'd0;
            EX_MEM_MemIOtoReg = 1'd0;
            EX_MEM_MemWrite = 1'd0;
            EX_MemRead = 1'd0;
            EX_MEM_Memory_sign = 1'd0;
            EX_MEM_Memory_data_width = 2'd0;
        
            EX_MEM_Beq = 1'd0;
            EX_MEM_Bne = 1'd0;             
            EX_MEM_Bgez = 1'd0;            
            EX_MEM_Bgtz = 1'd0;  
            EX_MEM_Bltz = 1'd0;   
            EX_MEM_Blez = 1'd0;        
            EX_MEM_Bgezal = 1'd0;         
            EX_MEM_Bltzal = 1'd0;
        
            EX_MEM_Mflo = 1'd0;
            EX_MEM_Mfhi = 1'd0;
            EX_MEM_Mtlo = 1'd0;
            EX_MEM_Mthi = 1'd0;
        
        end else if(stall)begin
            EX_opcplus4 = ID_opcplus4;
            EX_dataA = ID_dataA;
            EX_dataB = ID_dataB;
            EX_ALUOp = 2'd0;
            EX_ALUSrc = 1'd0;
            EX_address0 = ID_address0;
            EX_address1 = ID_address1;
            EX_rs = ID_rs;
            EX_func = ID_func;
            EX_op = ID_op;
            EX_shamt = ID_shamt;
            EX_Sign_extend = ID_Sign_extend;
            EX_RegDst = 1'd0;
            EX_Sftmd = 1'd0;    
            EX_DivSel = 1'd0;
            EX_I_format = 1'd0;
            EX_Jr = 1'd0;
            EX_MEM_Jalr = 1'd0;
            EX_MEM_Jmp = 1'd0;
            EX_MEM_Jal = 1'd0;
        
            EX_MEM_RegWrite = 1'd0;
            EX_MEM_MemIOtoReg = 1'd0;
            EX_MEM_MemWrite = 1'd0;
            EX_MemRead = 1'd0;
            EX_MEM_Memory_sign = 1'd0;
            EX_MEM_Memory_data_width = 2'd0;
        
            EX_MEM_Beq = 1'd0;
            EX_MEM_Bne = 1'd0;             
            EX_MEM_Bgez = 1'd0;            
            EX_MEM_Bgtz = 1'd0;  
            EX_MEM_Bltz = 1'd0;   
            EX_MEM_Blez = 1'd0;        
            EX_MEM_Bgezal = 1'd0;         
            EX_MEM_Bltzal = 1'd0;
        
            EX_MEM_Mflo = 1'd0;
            EX_MEM_Mfhi = 1'd0;
            EX_MEM_Mtlo = 1'd0;
            EX_MEM_Mthi = 1'd0;
        end else begin
            EX_opcplus4 = ID_opcplus4;
            EX_dataA = ID_dataA;
            EX_dataB = ID_dataB;
            EX_ALUOp = ID_ALUOp;
            EX_ALUSrc = ID_ALUSrc;
            EX_address0 = ID_address0;
            EX_address1 = ID_address1;
            EX_rs = ID_rs;
            EX_func = ID_func;
            EX_op = ID_op;
            EX_shamt = ID_shamt;
            EX_Sign_extend = ID_Sign_extend;
            EX_RegDst = ID_RegDst;
            EX_Sftmd = ID_RegDst;    
            EX_DivSel = ID_DivSel;   
            EX_I_format = ID_I_format;
            EX_Jr = ID_Jr;
            EX_MEM_Jalr = ID_Jalr;
            EX_MEM_Jmp = ID_Jmp;
            EX_MEM_Jal = ID_Jal;
            
            EX_MEM_RegWrite = ID_RegWrite;      //传去EX_MEM
            EX_MEM_MemIOtoReg = ID_MemIOtoReg;
            EX_MEM_MemWrite = ID_MemWrite;
            EX_MemRead = ID_MemRead;
            EX_MEM_Memory_sign = ID_Memory_sign;
            EX_MEM_Memory_data_width = ID_Memory_data_width;
        
            EX_MEM_Beq = ID_Beq;
            EX_MEM_Bne = ID_Bne;             
            EX_MEM_Bgez = ID_Bgez;            
            EX_MEM_Bgtz = ID_Bgtz;  
            EX_MEM_Bltz = ID_Bltz;   
            EX_MEM_Blez = ID_Blez;        
            EX_MEM_Bgezal = ID_Bgezal;         
            EX_MEM_Bltzal = ID_Bltzal;
        
            EX_MEM_Mflo = ID_Mflo;
            EX_MEM_Mfhi = ID_Mfhi;
            EX_MEM_Mtlo = ID_Mtlo;
            EX_MEM_Mthi = ID_Mthi;
        end           
    end
endmodule
