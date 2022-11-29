`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/17 21:00:51
// Design Name: 
// Module Name: ifetc32_sim
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


module ifetc32_sim(

    );
    // input
    
//    reg[1:0]   Wpc = 2'b00;
//    reg        Wir = 1'b0;
    
    reg        reset = 1'b1;
    reg        PCWrite = 1'b0;
    reg        clock = 1'b0;
    
    reg   [25:0]  Jump_PC = 25'd0;              // 来自ID，指令中的address部分, //((Zero-Extend) address<<2)
    reg   [31:0]  Read_data_1 = 32'h00000000;   // 来自译码单元，jr指令用的地址
    reg           JR = 1'b0;
    reg           J = 1'b0;
    reg           IFBranch = 1'b0;
    reg           nBranch = 1'b0;
    reg   [31:0]  ID_opcplus4 = 32'h00000000;
    
    reg	   [31:0]  Jpadr=32'h00000000;		    // 从程序ROM单元中获取的指令
    // 中断相关
    reg   [31:0]  interrupt_PC=32'h00000000;
    reg           cp0_wen=1'b0;

    // output
    wire  [31:0]  PC;  
    wire  [31:0]  opcplus4;            // jal指令专用的PC+4
    wire  [31:0]  Instruction;         // 输出指令到其他模块
    // output  [31:0]  PC_plus_4_out,   // (pc+4)送执行单元
    // ROM Pinouts
    wire  [13:0]  rom_adr_o;           // 给程序ROM单元的取指地址
        
    Ifetc32 Uifetch(
        .reset          (reset),
        .PCWrite        (PCWrite),
        .clock          (clock),
        .Jump_PC        (Jump_PC),
        .Read_data_1    (Read_data_1),
        .JR             (JR),
        .J              (J),
        .IFBranch       (IFBranch),
        .nBranch        (nBranch),
        .ID_opcplus4    (ID_opcplus4),
        .Jpadr          (Jpadr),
        .interrupt_PC   (interrupt_PC),
        .cp0_wen        (cp0_wen),
        
        .PC             (PC),
        .opcplus4       (opcplus4),
        .Instruction    (Instruction),
        .rom_adr_o      (rom_adr_o)
    );

    initial begin
        begin Jpadr=32'h00430820; PCWrite=1'b1; end                                             //add
        #100   reset = 1'b0;
        #50    begin  Jpadr=32'h1181ffff; nBranch=1'b1; ID_opcplus4=32'd2; end                  //beq
        #200   begin Jpadr=32'h01044022; nBranch=1'b0; end                                      //sub
        #100   begin Jpadr=32'h1500fffe; IFBranch=1'b1; end                                     //bne
        #100   begin Jpadr=32'h01044022; IFBranch=1'b0; end                                     //sub
        #100   begin Jpadr=32'h1500fffe; nBranch=1'b1; ID_opcplus4=32'd4; end                   //bne
        #100   begin Jpadr=32'h10210002; nBranch=1'b0; IFBranch=1'b1; end                       //beq
        #100   begin Jpadr=32'h04010001; IFBranch=1'b1; end                                     //bgez
        #100   begin Jpadr=32'h19200001; IFBranch=1'b0; nBranch=1'b1; ID_opcplus4=32'd10; end   //blez
        #100   begin Jpadr=32'h1d200001; nBranch=1'b0; IFBranch=1'b1; end                       //bgtz
        #100   begin Jpadr=32'h05800001; IFBranch=1'b0; nBranch=1'b1; ID_opcplus4=32'd13; end   //blez
        #100   begin Jpadr=32'h05910002; nBranch=1'b0; IFBranch=1'b1; end                       //bgezal
        #100   begin Jpadr=32'h05300003; IFBranch=1'b0; nBranch=1'b1; ID_opcplus4=32'd17; end   //blez
        #100   begin Jpadr=32'h08000014; nBranch=1'b0; J=1'b1; Jump_PC=32'h0000014; end         //j
        #100   begin Jpadr=32'h0000f009; J=1'b0; JR=1'b1; Read_data_1=32'd0; end                //jalr
        #100   JR=1'b0;
    end
    always #50 clock = ~clock;            
endmodule
