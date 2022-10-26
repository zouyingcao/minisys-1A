`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module Executs32 (
    //
    input           clock,
    input           reset,
    input           Waluresult,         // дAluresult���ź�
    //   
    input   [31:0]  PC_plus_4,           // PC+4
    input	[31:0]	Read_data_1,		// �����뵥Ԫ��Read_data_1����
    input	[31:0]	Read_data_2,		// �����뵥Ԫ��Read_data_2����
    input   [1:0]   ALUOp,              // ���Կ��Ƶ�Ԫ������ָ����Ʊ���
    input	[31:0]	Sign_extend,		// �����뵥Ԫ������չ���������
    input	[5:0]	Func,	            // ȡָ��Ԫ����r-����ָ�����,r-form instructions[5:0]
    input	[5:0]	Op,			        // ȡָ��Ԫ���Ĳ�����
    input	[4:0]	Shamt,				// ����ȡָ��Ԫ��instruction[10:6]��ָ����λ����
    input	[4:0]	address0,		    // rt(i_format)
    input	[4:0]	address1,		    // rd
    input			Sftmd,				// ���Կ��Ƶ�Ԫ�ģ���������λָ��
    input           DivSel,
    input	[1:0]	ALUSrcA,			
    input   [1:0]   ALUSrcB,
    input			I_format,			// ���Կ��Ƶ�Ԫ�������ǳ�beq, bne, LW, SW֮���I-����ָ��
    input			Jrn,				// ���Կ��Ƶ�Ԫ��������JRָ��
    input           RegDst,
    
    input           Mfhi,               //�Ƿ�Ϊ��дHI/LO�Ĵ�����ָ��
    input           Mflo,
    input           Mthi,
    input           Mtlo,            
    
    // forwarding
    input   [31:0]  EX_MEM_ALU_result,  // ��ǰһ��ָ�����д���ð��
    input   [31:0]  WB_data,            // ֻ��ǰǰ��ָ�����ð��
    
    output			Zero,				// Ϊ1��������ֵΪ0 
    output          Positive,           // rs�Ƿ�Ϊ��
    output          Negative,           // rs�Ƿ�Ϊ��
    output          Overflow,           // �Ƿ�����Ӽ������
    output  reg    Divide_zero,        // �Ƿ��0
    
    output  [4:0]   address,   
    output reg[31:0]ALU_Result,			// ��������ݽ��
    output	[31:0]	rt_value,
    output  [4:0]   rd,
    output	[31:0]	Add_Result			// ����ĵ�ַ���     
);

    wire[31:0] Ainput,Binput;
    reg[31:0] Sinput;
    reg[31:0] ALU_output_mux;
    wire[2:0] ALU_ctl;
    wire[5:0] Exe_code;   
    
    wire mult,multu,div,divu;
    wire[63:0] mul_signed_result;
    wire[63:0] mul_unsigned_result;
    wire[31:0] div_signed_result;
    wire[31:0] div_unsigned_result;
    wire div_dout_tvalid;
    wire divu_dout_tvalid;
    wire div_zero;
    wire divu_zero;
    
    // 00:register(rs),01:EX_MEM_xxx,10:MEM_WB_xxx
    assign Ainput = (ALUSrcA==2'b00) ? Read_data_1 : (ALUSrcA==2'b01) ? EX_MEM_ALU_result : WB_data;
    // 00:register(rt),11:imm32,01:EX_MEM_xxx,10:MEM_WB_xxx
    assign Binput = (ALUSrcB==2'b00) ? Read_data_2 : (ALUSrcB==2'b01) ? EX_MEM_ALU_result : (ALUSrcB==2'b10) ? WB_data : Sign_extend[31:0]; 
    assign rt_value = Binput;
    
    assign Exe_code = (I_format==0) ? Func:{3'b000,Op[2:0]};
    assign ALU_ctl[0] = (Exe_code[0] | Exe_code[3]) & ALUOp[1]; 
    assign ALU_ctl[1] = ((!Exe_code[2]) | (!ALUOp[1]));
    assign ALU_ctl[2] = (Exe_code[1] & ALUOp[1]) | ALUOp[0];
    assign address = RegDst ? address1 : address0;
    assign rd = address1;
    
    always @(negedge clock or posedge reset) begin
        if(reset) ALU_Result = 32'd0;
        else if(Waluresult) begin
            if(((ALU_ctl[2:1]==2'b11) && (I_format==1))||((ALU_ctl==3'b111) && (Exe_code[3]==1))) // ����SLT��
                ALU_Result = {31'd0,ALU_output_mux[31]};    // ����λΪ1˵��(rs)<(rt)
            else if((ALU_ctl==3'b101) && (I_format==1))     // lui
                ALU_Result[31:0] = {Binput,16'd0};          
            else if(Sftmd==1) ALU_Result = Sinput;          // ��λ
            else  ALU_Result = ALU_output_mux[31:0];        // otherwise
        end
    end

	always @* begin  // 6����λָ��
       if(Sftmd)
        case(Func[2:0])
            3'b000:Sinput = Binput<<Shamt;      // Sll rd,rt,shamt  00000
            3'b010:Sinput = Binput>>Shamt;      // Srl rd,rt,shamt  00010
            3'b100:Sinput = Binput<<Ainput;     // Sllv rd,rt,rs 000100
            3'b110:Sinput = Binput>>Ainput;     // Srlv rd,rt,rs 000110
            3'b011:Sinput = $signed(Binput)>>>Shamt;     // Sra rd,rt,shamt 00011
            3'b111:Sinput = $signed(Binput)>>>Ainput;    // Srav rd,rt,rs 00111        
            default:Sinput = Binput;
        endcase
       else Sinput = Binput;
    end
 
    assign Add_Result = PC_plus_4[31:0] + {Sign_extend[29:0],2'b00};    // ��ȡָ��Ԫ��Ϊbeq��bneָ�����ת��ַ ������
    
    assign Zero = (ALU_output_mux[31:0]== 32'h00000000) ? 1'b1 : 1'b0;
    assign Positive = (Read_data_1[31]==1'b0&&!Zero);
    assign Negative = Read_data_1[31];
    assign Overflow = (ALU_ctl[1:0] != 2'b10) ? 1'b0 : //�������з��żӼ����򲻲���Overflow
                              (ALU_ctl[2] == 1'b0)
                              ? (Ainput[31] == Binput[31] && Ainput[31] != ALU_output_mux[31])  //ͬ�����,����ķ�����֮�෴,��OF=1,����OF=0
                              : (Ainput[31] != Binput[31] && Binput[31] == ALU_output_mux[31]); //������,����ķ����������ͬ,��OF=1,����OF=0
    
    always @(ALU_ctl or Ainput or Binput) begin //���������߼�����
        case(ALU_ctl)
            3'b000:ALU_output_mux = Ainput & Binput;                    // and,andi
            3'b001:ALU_output_mux = Ainput | Binput;                    // or,ori
            3'b010:ALU_output_mux = $signed(Ainput) + $signed(Binput);  // add,addi,lw,sw,lbu,lb,lj,lhu,sb,sh
            3'b011:ALU_output_mux = Ainput + Binput;                    // addu,addiu
            3'b100:ALU_output_mux = Ainput ^ Binput;                    // xor,xori
            3'b101:ALU_output_mux = ~(Ainput | Binput);                 // nor,lui
            3'b110:ALU_output_mux = $signed(Ainput) - $signed(Binput);  // sub,slt,slti,beq,bne
            3'b111:ALU_output_mux = Ainput - Binput;                    // subu,sltiu,sltu
            default:ALU_output_mux = 32'h00000000;
        endcase
    end
    
    reg[31:0]   hi,lo;
    assign mult = (Op==6'b000000&&Func==6'b011000);
    assign multu = (Op==6'b000000&&Func==6'b011001);
    assign div = (Op==6'b000000&&Func==6'b011010);
    assign divu = (Op==6'b000000&&Func==6'b011011);
  
    // �з��ų˷�
    multiplier_signed mul_signed(
        .CLK(clock),
        .A(Ainput),
        .B(Binput),
        .P(mul_signed_result)
    );
    
    // �޷��ų˷�
    multiplier_unsigned mul_unsigned(
        .CLK(clock),
        .A(Ainput),
        .B(Binput),
        .P(mul_unsigned_result)
    );
    
    // �з��ų���
    div_signed div_signed(
        .aclk(clock),                                  
        .s_axis_divisor_tvalid(DivSel),                // ����tvalid
        .s_axis_divisor_tdata(Binput),                 
        .s_axis_dividend_tvalid(DivSel),               // ������tvalid
        .s_axis_dividend_tdata(Ainput),                
        .m_axis_dout_tvalid(div_dout_tvalid),          // �������ʱtvalid��1
        .m_axis_dout_tuser(div_zero),                  // ����
        .m_axis_dout_tdata(div_signed_result)          // (32{��},32{����})
    );
    
    // �޷��ų���
    div_unsigned div_unsigned(
        .aclk(clock),                                  
        .s_axis_divisor_tvalid(DivSel),                 // ����tvalid
        .s_axis_divisor_tdata(Binput),                 
        .s_axis_dividend_tvalid(DivSel),                // ������tvalid
        .s_axis_dividend_tdata(Ainput),                
        .m_axis_dout_tvalid(divu_dout_tvalid),          // �������ʱtvalid��1
        .m_axis_dout_tuser(divu_zero),                  // ����
        .m_axis_dout_tdata(div_unsigned_result)         // (32{��},32{����})
    );
    
    always @* begin  // �˳�����/mt��ֵ���д��HI/LO
         if(Mthi)   hi = Ainput;//(rs)
         else if(Mtlo)  lo = Ainput;
         else if(mult)  {hi,lo} <= mul_signed_result;
         else if(multu) {hi,lo} <= mul_unsigned_result;
         else if(DivSel) begin
            if(div) begin 
                if(div_dout_tvalid)
                    {lo,hi} <= div_signed_result;
                Divide_zero = div_zero;
            end else if(divu) begin
                if(divu_dout_tvalid)
                    {lo,hi} <= div_unsigned_result;
                Divide_zero = divu_zero;
            end
         end
    end
    
    always @* begin
        if(Mfhi)
            ALU_Result = hi;
        else if(Mflo)
            ALU_Result = lo;
        else if(((ALU_ctl==3'b111) && (Exe_code[3]==1))||((ALU_ctl[2:1]==2'b11) && (I_format==1))) //slt,sltu,slti,sltiu ��������SLT�������
            ALU_Result = {31'd0,ALU_output_mux[31]};    // ����λΪ1˵��(rs)<(rt)
        else if((ALU_ctl==3'b101) && (I_format==1)) 
            ALU_Result[31:0] = {Binput,16'd0};          // lui data
        else if(Sftmd) ALU_Result = Sinput;             //  ��λ
        else  ALU_Result = ALU_output_mux[31:0];        // otherwise
    end
endmodule
