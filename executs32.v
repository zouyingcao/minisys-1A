`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module Executs32 (
    //
    input           clock,
    input           reset,
    input           Waluresult,         // 写Aluresult的信号
    //   
    input   [31:0]  PC_plus_4,           // PC+4
    input	[31:0]	Read_data_1,		// 从译码单元的Read_data_1中来
    input	[31:0]	Read_data_2,		// 从译码单元的Read_data_2中来
    input   [1:0]   ALUOp,              // 来自控制单元的运算指令控制编码
    input	[31:0]	Sign_extend,		// 从译码单元来的扩展后的立即数
    input	[5:0]	Func,	            // 取指单元来的r-类型指令功能码,r-form instructions[5:0]
    input	[5:0]	Op,			        // 取指单元来的操作码
    input	[4:0]	Shamt,				// 来自取指单元的instruction[10:6]，指定移位次数
    input	[4:0]	address0,		    // rt(i_format)
    input	[4:0]	address1,		    // rd
    input			Sftmd,				// 来自控制单元的，表明是移位指令
    input           DivSel,
    input	[1:0]	ALUSrcA,			
    input   [1:0]   ALUSrcB,
    input			I_format,			// 来自控制单元，表明是除beq, bne, LW, SW之外的I-类型指令
    input			Jrn,				// 来自控制单元，书名是JR指令
    input           RegDst,
    
    input           Mfhi,               //是否为读写HI/LO寄存器的指令
    input           Mflo,
    input           Mthi,
    input           Mtlo,            
    
    // forwarding
    input   [31:0]  EX_MEM_ALU_result,  // 与前一条指令存在写后读冒险
    input   [31:0]  WB_data,            // 只与前前条指令存在冒险
    
    output			Zero,				// 为1表明计算值为0 
    output          Positive,           // rs是否为正
    output          Negative,           // rs是否为负
    output          Overflow,           // 是否产生加减法溢出
    output  reg    Divide_zero,        // 是否除0
    
    output  [4:0]   address,   
    output reg[31:0]ALU_Result,			// 计算的数据结果
    output	[31:0]	rt_value,
    output  [4:0]   rd,
    output	[31:0]	Add_Result			// 计算的地址结果     
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
            if(((ALU_ctl[2:1]==2'b11) && (I_format==1))||((ALU_ctl==3'b111) && (Exe_code[3]==1))) // 所有SLT类
                ALU_Result = {31'd0,ALU_output_mux[31]};    // 符号位为1说明(rs)<(rt)
            else if((ALU_ctl==3'b101) && (I_format==1))     // lui
                ALU_Result[31:0] = {Binput,16'd0};          
            else if(Sftmd==1) ALU_Result = Sinput;          // 移位
            else  ALU_Result = ALU_output_mux[31:0];        // otherwise
        end
    end

	always @* begin  // 6种移位指令
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
 
    assign Add_Result = PC_plus_4[31:0] + {Sign_extend[29:0],2'b00};    // 给取指单元作为beq和bne指令的跳转地址 ？？？
    
    assign Zero = (ALU_output_mux[31:0]== 32'h00000000) ? 1'b1 : 1'b0;
    assign Positive = (Read_data_1[31]==1'b0&&!Zero);
    assign Negative = Read_data_1[31];
    assign Overflow = (ALU_ctl[1:0] != 2'b10) ? 1'b0 : //若不是有符号加减，则不产生Overflow
                              (ALU_ctl[2] == 1'b0)
                              ? (Ainput[31] == Binput[31] && Ainput[31] != ALU_output_mux[31])  //同号相加,结果的符号与之相反,则OF=1,否则OF=0
                              : (Ainput[31] != Binput[31] && Binput[31] == ALU_output_mux[31]); //异号相减,结果的符号与减数相同,则OF=1,否则OF=0
    
    always @(ALU_ctl or Ainput or Binput) begin //进行算数逻辑运算
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
  
    // 有符号乘法
    multiplier_signed mul_signed(
        .CLK(clock),
        .A(Ainput),
        .B(Binput),
        .P(mul_signed_result)
    );
    
    // 无符号乘法
    multiplier_unsigned mul_unsigned(
        .CLK(clock),
        .A(Ainput),
        .B(Binput),
        .P(mul_unsigned_result)
    );
    
    // 有符号除法
    div_signed div_signed(
        .aclk(clock),                                  
        .s_axis_divisor_tvalid(DivSel),                // 除数tvalid
        .s_axis_divisor_tdata(Binput),                 
        .s_axis_dividend_tvalid(DivSel),               // 被除数tvalid
        .s_axis_dividend_tdata(Ainput),                
        .m_axis_dout_tvalid(div_dout_tvalid),          // 产生结果时tvalid变1
        .m_axis_dout_tuser(div_zero),                  // 除零
        .m_axis_dout_tdata(div_signed_result)          // (32{商},32{余数})
    );
    
    // 无符号除法
    div_unsigned div_unsigned(
        .aclk(clock),                                  
        .s_axis_divisor_tvalid(DivSel),                 // 除数tvalid
        .s_axis_divisor_tdata(Binput),                 
        .s_axis_dividend_tvalid(DivSel),                // 被除数tvalid
        .s_axis_dividend_tdata(Ainput),                
        .m_axis_dout_tvalid(divu_dout_tvalid),          // 产生结果时tvalid变1
        .m_axis_dout_tuser(divu_zero),                  // 除零
        .m_axis_dout_tdata(div_unsigned_result)         // (32{商},32{余数})
    );
    
    always @* begin  // 乘除运算/mt赋值结果写入HI/LO
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
        else if(((ALU_ctl==3'b111) && (Exe_code[3]==1))||((ALU_ctl[2:1]==2'b11) && (I_format==1))) //slt,sltu,slti,sltiu 处理所有SLT类的问题
            ALU_Result = {31'd0,ALU_output_mux[31]};    // 符号位为1说明(rs)<(rt)
        else if((ALU_ctl==3'b101) && (I_format==1)) 
            ALU_Result[31:0] = {Binput,16'd0};          // lui data
        else if(Sftmd) ALU_Result = Sinput;             //  移位
        else  ALU_Result = ALU_output_mux[31:0];        // otherwise
    end
endmodule
