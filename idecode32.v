`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module Idecode32 (
	input			reset,
    input			clock,
    input  [31:0]   opcplus4,       // ����ȡָ��Ԫ��JAL����
    input  [31:0]	Instruction,	// ȡָ��Ԫ����ָ��
    input  [31:0]	wb_data,		// ��DATA RAM or I/O portȡ��������
    input  [31:0]	ALU_result,		// ��ִ�е�Ԫ��������Ľ������Ҫ��չ��������32λ
    input  [4:0]    waddr,
    
    input			Jal,			// jal
    input			Jalr,			// jalr 
    input           Bgezal,
    input           Bltzal,
    input			RegWrite,		
    output [25:0]   Jump_PC,
    output [31:0]   read_data_1,    // ����ĵ�һ������
    output [31:0]   read_data_2,    // ����ĵڶ�������
    output [4:0]    write_address_1,// r-formָ��Ҫд�ļĴ����ĺţ�rd��
    output [4:0]    write_address_0,// i-formָ��Ҫд�ļĴ����ĺ�(rt)
    output [31:0]	Sign_extend,	// ���뵥Ԫ�������չ���32λ������
    output [4:0]    rs,             // rs
    
    input           Positive,
    input           Negative,
    input           Overflow,
    input           Divide_zero,
    input           Reserved_instruction,
    input           Mfc0,           // ��Ȩָ��
    input           Mtc0,
    input           Break,
    input           Syscall,
    input           Eret,
    input  [31:0]   cp0_data_in,
    output          cp0_wen,
    output [31:0]   cp0_data_out,
    output [4:0]    causeExcCode
    
    
);
    
    reg[31:0] register[0:31];			     // �Ĵ����鹲32��32λ�Ĵ���
    reg[4:0] write_register_address;        // Ҫд�ļĴ����ĺ�
    reg[31:0] write_data;                   // Ҫд�Ĵ��������ݷ�����

    wire[4:0] rt;       // Ҫ���ĵڶ����Ĵ����ĺţ�rt��
    wire[15:0] Instruction_immediate_value;  // ָ���е�������
    wire[5:0] opcode;                        // ָ����
    
    assign opcode = Instruction[31:26];	                        // op
    assign rs = Instruction[25:21];                             // rs
    assign rt = Instruction[20:16];                             // rt
    assign write_address_1 = Instruction[15:11];                // rd
    assign write_address_0 = rt;                                // rt(i-form)
    assign Instruction_immediate_value = Instruction[15:0];     // immediate
    assign Jump_PC = Instruction[25:0];                         // address
    
    wire sign;                                            // ȡ����λ��ֵ
    assign sign = Instruction[15];
    // andi,ori,xori,sltui����չ, ���������չ
    assign Sign_extend = (opcode==6'b001100||opcode==6'b001101||opcode==6'b001110||opcode==6'b001011) ? {16'd0,Instruction_immediate_value} : {{16{sign}},Instruction_immediate_value};
    
    assign read_data_1 = register[rs];
    assign read_data_2 = register[rt];
    
    always @* begin                                            //�������ָ����ָͬ���µ�Ŀ��Ĵ���
        if(Jal || (Bgezal && !Negative) || (Bltzal && Negative))
            write_register_address = 5'd31;
        else if(Bgezal||Bltzal)
            write_register_address = 5'd0;//��Ч
        else 
            write_register_address = waddr;
    end
    
    always @* begin  //������̻�������ʵ�ֽṹͼ�����µĶ�·ѡ����,׼��Ҫд������
         if(Jal || Jalr || Bgezal || Bltzal)
            write_data = opcplus4;      //($31)��(PC)+4��(rd)��(PC)+4
        else
            write_data = wb_data;
     end
    
    integer i;
    always @(posedge clock) begin       // ������дĿ��Ĵ���
        if(reset==1) begin              // ��ʼ���Ĵ�����
            for(i=0;i<32;i=i+1) register[i] <= i;
        end else if(RegWrite==1) begin  // ע��Ĵ���0�����0
            if(write_register_address != 5'b00000)
                register[write_register_address] = write_data;
        end
    end
    
    assign causeExcCode = (Syscall) ? 5'b01000 : //ϵͳ���� syscall
                          (Break) ? 5'b01001 : //���Զϵ�ָ��   break
                          (Reserved_instruction) ? 5'b01010 : // ����ָ��,cpuִ�е�һ��δ�����ָ��
                          (Overflow) ?  5'b01100 : //����������з�������Ӽ����
                          // (keyboardbreak) ? 5'b00000 : //�ⲿ�ж� 
                          5'b11111;  
    assign cp0_wen = (Mfc0 || Mtc0 || Break || Syscall || Overflow || Divide_zero || Reserved_instruction);
    assign cp0_data_out = cp0_wen ? write_data:32'd0;
    
endmodule
