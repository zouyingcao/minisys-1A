`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module Ifetc32 (
    // for multicycle
    input   [1:0]   Wpc,
    input           Wir,
    //
	input			reset,				// ��λ�ź�(�ߵ�ƽ��Ч)
	input           PCWrite,
    input			clock,				// ʱ��(22MHz)

    input   [25:0]  Jump_PC,            // ����ID��ָ���е�address����
    input	[31:0]	Read_data_1,		// �������뵥Ԫ��jrָ���õĵ�ַ
    input           JR,
    input           J,
    input           IFBranch,
    input           nBranch, 
    input   [31:0]  ID_opcplus4,
    
    output reg[31:0]PC,              
    output  [31:0]  opcplus4,			// jalָ��ר�õ�PC+4
    output  [31:0]  Instruction,        // ���ָ�����ģ��
    // output  [31:0]  PC_plus_4_out,   // (pc+4)��ִ�е�Ԫ
    // ROM Pinouts
	output	[13:0]	rom_adr_o,			// ������ROM��Ԫ��ȡָ��ַ
	input	[31:0]	Jpadr,				// �ӳ���ROM��Ԫ�л�ȡ��ָ��
	// �ж����
	input   [31:0]  interrupt_PC,
	input           flush
);
    
    wire [31:0] PC_plus_4;
    reg [31:0] next_PC;		                 // ����ָ���PC����һ����PC+4)
   
    assign Instruction = Jpadr;              // ȡ��ָ��
    assign rom_adr_o = PC[15:2];             
    assign PC_plus_4 = {PC[31:2] + 1,2'b00}; // PC+4
    assign opcplus4 = {2'b00,PC_plus_4[31:2]}; // PC+4������jal��$31=PC+4��������λ�Դ���Ĵ���
    // assign PC_plus_4_out = PC_plus_4;

    wire [15:0] offset = Instruction[15:0];
    wire sign = offset[15];
    
    // next_PC������2λ���PC���Ӷ���֤ǿ�ƶ���
    always @* begin               
        if(nBranch) next_PC = ID_opcplus4;          // ID�η�֧Ԥ��ʧ�ܣ���������תָ���ת
        else if(JR) next_PC = Read_data_1;          // jr,jalr: PC��(rs),ID�δ���
        else if(J)                                  // j,jal
            next_PC = {6'b0000,Jump_PC};            // (Zero-Extend)address<<2��������������չ,������λ�Ľ��
        else if(IFBranch)                           // IF��Ԥ����ת��������
            next_PC = {2'b00,PC_plus_4[31:2]}+{{16{sign}},offset}; // (PC)��(PC)+4+((Sign-Extend)offset<<2),������λ�Ľ��
        else if(flush) next_PC = interrupt_PC>>2;   // ��������λ
        else next_PC = {2'b00,PC_plus_4[31:2]};     // һ�����
    end
    
    always @(negedge clock) begin                   // ʱ���½��ظ���PC
        if(reset) PC = 32'h00000000;
        else if(PCWrite)PC = next_PC<<2;            // ȷ����4�ı���
    end
    
    /*
	// ROM Pinouts
	assign rom_adr_o = next_PC;   // ������ROM��ȡָ��ַ
    assign PC_plus_4 = {PC[15:2]+1,2'b0};
    
    reg [31:0] IR;
    always @(negedge clock) begin
        if(reset) IR<=0;
        else if(Wir) IR<=Jpadr;
        else IR<=IR;
    end
    
    assign Instruction = IR;    //�ӳ���ROM������ָ��
    assign PC_plus_4_out = PC;
     
    always @(negedge clock) begin 
        if(reset) PC <= 32'b0;      
        else begin
            case(Wpc)
                2'b01: if(Jmp||Jal) begin
                        opcplus4 = {2'b00,PC_plus_4[31:2]};
                        next_PC = {4'b0000,IR[27:0]<<2};
                        end
                    else next_PC = Read_data_1; // jr
                2'b10: PC[31:0] = {next_PC[29:0],2'b00};
                2'b11: next_PC = Add_result;// beq||bne
            endcase
        end
    end
 */
    
endmodule
