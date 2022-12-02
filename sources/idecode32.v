`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module Idecode32 (
	input			reset,
    input			clock,
    input  [31:0]   opcplus4,      
    input  [31:0]	Instruction,	// ȡָ��Ԫ����ָ��
    input  [31:0]	wb_data,		// ��DATA RAM or I/O portȡ��������
    input  [31:0]	ALU_result,		// ��ִ�е�Ԫ��������Ľ������Ҫ��չ��������32λ
    input  [4:0]    waddr,
    
    input			Jal,			// jal
    input			Jalr,			// jalr 
    input           Bgezal,
    input           Bltzal,
    input           Negative,
    input			RegWrite,		
    
    output [25:0]   Jump_PC,
    output [31:0]   read_data_1,    // ����ĵ�һ������
    output [31:0]   read_data_2,    // ����ĵڶ�������
    output [4:0]    write_address_1,// r-formָ��Ҫд�ļĴ����ĺţ�rd��
    output [4:0]    write_address_0,// i-formָ��Ҫд�ļĴ����ĺ�(rt)
    output [31:0]   write_data,     // Ҫд��Ĵ���������
    output [4:0]    write_register_address, //��ַ��Ҫд�ļĴ����ĺ�
    output [31:0]	Sign_extend,	// ���뵥Ԫ�������չ���32λ������
    output [4:0]    rs              // rs
);
    
    reg[31:0] register[0:31];			        // �Ĵ����鹲32��32λ�Ĵ���

    wire[4:0] rt;                               // Ҫ���ĵڶ����Ĵ����ĺţ�rt��
    wire[15:0] Instruction_immediate_value;     // ָ���е�������
    wire[5:0] opcode;                           // ָ����
    
    assign opcode = Instruction[31:26];	                        // op
    assign rs = Instruction[25:21];                             // rs
    assign rt = Instruction[20:16];                             // rt
    assign write_address_1 = Instruction[15:11];                // rd
    assign write_address_0 = rt;                                // rt(i-form)
    assign Instruction_immediate_value = Instruction[15:0];     // immediate
    assign Jump_PC = Instruction[25:0];                         // address
    
    wire sign;                                  // ȡ����λ��ֵ
    assign sign = Instruction[15];
    // andi,ori,xori,sltui����չ, ���������չ
    assign Sign_extend = (opcode==6'b001100||opcode==6'b001101||opcode==6'b001110||opcode==6'b001011) ? {16'd0,Instruction_immediate_value} : {{16{sign}},Instruction_immediate_value};
    
    assign read_data_1 = register[rs];
    assign read_data_2 = register[rt];
    assign write_data = (Jal || Jalr || Bgezal || Bltzal) ? opcplus4 : wb_data; // ($31)��(PC)+4(jal,bgezal,bltzal)��(rd)��(PC)+4(jalr)
    assign write_register_address = (Jal || (Bgezal && !Negative) || (Bltzal && Negative))? 5'd31:(Bgezal||Bltzal)?5'd0: waddr;
//    always @* begin                              // �������ָ����ָͬ���µ�Ŀ��Ĵ���
//        if (Jal || (Bgezal && !Negative)|| (Bltzal && Negative))
//            write_register_address =  5'd31;
//        else if (Bgezal||Bltzal)
//            write_register_address = 5'd0; // ��Ч
//        else 
//            write_register_address = waddr;
//    end
    
    integer i;
    always @(posedge clock) begin       // ������дĿ��Ĵ���
        if(reset==1) begin              // ��ʼ���Ĵ�����
            for(i=0;i<32;i=i+1) register[i] <= i;
        end else if(RegWrite==1) begin  // ע��Ĵ���0�����0
            if(write_register_address != 5'b00000)
                register[write_register_address] = write_data;
        end
    end

endmodule
