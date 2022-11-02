`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module control32 (
    input   [31:0]  Instruction,
    input           s_format,
    input           l_format,
    input   [21:0]  Alu_resultHigh,     // ��������Ҫ�Ӷ˿ڻ�洢�������ݵ��Ĵ���,LW��SW��������ַΪAlu_Result,Alu_resultHigh = Alu_result[31:10];
    
    output			RegDST,				// Ϊ1����Ŀ�ļĴ�����rd������Ŀ�ļĴ�����rt
    output			ALUSrc,				// Ϊ1�����ڶ�������������������beq��bne���⣩
    output			MemIOtoReg,			// Ϊ1������Ҫ�Ӵ洢�������ݵ��Ĵ���
    output			RegWrite,			// Ϊ1������ָ����Ҫд�Ĵ���
    output			MemWrite,			// Ϊ1������ָ����Ҫд�洢��,sw��Alu_resultHigh������ȫ1(ȫ1��ʾIO��
    output          MemRead,            // �洢����
    output          IORead,             // IO��
    output          IOWrite,            // IOд
    
    output			Jmp,				// Ϊ1������Jָ��
    output			Jal,				// Ϊ1������Jalָ��
    output          Jrn,                // Ϊ1������ǰָ����jr
    output          Jalr,               // Jalr
    
    output          Beq,                // Ϊ1������Beqָ��,ԭΪBranch
    output          Bne,                // Ϊ1������Bneָ��,ԭΪnBranch
    output          Bgez,
    output          Bgtz,
    output          Blez,
    output          Bltz,
    output          Bgezal,
    output          Bltzal,
    
    output          Mfhi,
    output          Mflo,
    output          Mfc0,
    output          Mthi,
    output          Mtlo,
    output          Mtc0,
    
    output			I_format,			// Ϊ1������ָ���ǳ�beq��bne��LW��SW֮�������I-����ָ��
    output          S_format,           // ��ʾд�洢��
    output          L_format,           // ��ʾ�Ӵ洢����������
    output			Sftmd,				// Ϊ1��������λָ��
    output          DivSel,
    output	[1:0]	ALUOp,				// ��R-���ͻ�I_format=1ʱλ1Ϊ1, beq��bneָ����λ0Ϊ1
    output          Memory_sign,        // lb/lbu/lh/lhu�Ĵ���
    output  [1:0]   Memory_data_width,  // ��д�洢�������ݿ��(00/01/11)
    //�ж�/�쳣���
    output          Break,
    output          Syscall,
    output          Eret,
    output          Reserved_instruction // ����ָ�δʵ�ֵ�ָ�          
);
   
    wire R_format;		// Ϊ1��ʾ��R-����ָ��
    reg [2:0] state;
    reg [2:0] next_state;
    parameter [2:0] sinit = 3'b000,//
            sif = 3'b001,//ȡָ
            sid = 3'b010,//����
            sexe = 3'b011,//ִ��
            smem = 3'b100,//�洢
            swb = 3'b101;//��д
    
    wire[5:0]   op,func;
    wire[4:0]   rs,rt,rd,shamt;
    
    assign op = Instruction[31:26];        
    assign rs = Instruction[25:21]; 
    assign rt = Instruction[20:16];
    assign rd = Instruction[15:11];
    assign shamt = Instruction[10:6];  
    assign func = Instruction[5:0]; 
    
    //R��ָ��:
    assign R_format = (op==6'b000000||op==6'b010000);        //R��ָ��(mfc0,mtc0,eretΪop==6'b010000)
    assign Jrn = (op==6'b000000 && rt==5'b00000 && rd==5'b00000 && shamt==5'b00000 && func==6'b001000);
    assign Jalr = (op==6'b000000 && rt==5'b00000 && shamt==5'b00000 && func==6'b001001);
    
    assign Mfhi = (op==6'b000000 && rs==5'b00000 && rt==5'b00000 && shamt==5'b00000 && func==6'b010000);
    assign Mflo = (op==6'b000000 && rs==5'b00000 && rt==5'b00000 && shamt==5'b00000 && func==6'b010010);
    assign Mthi = (op==6'b000000 && rt==5'b00000 && rd==5'b00000 && shamt==5'b00000 && func==6'b010001);
    assign Mtlo = (op==6'b000000 && rt==5'b00000 && rd==5'b00000 && shamt==5'b00000 && func==6'b010011);
    assign Mfc0 = (op==6'b010000 && rs==5'b00000 && shamt==5'b00000 && func[5:3]==3'b000);
    assign Mtc0 = (op==6'b010000 && rs==5'b00100 && shamt==5'b00000 && func[5:3]==3'b000);
    
    assign Break = (op==6'b000000 && func==6'b001101);
    assign Syscall = (op==6'b000000 && func==6'b001100);
    assign Eret = (Instruction==32'b010000_10000000000000000000_011000);//���жϻ����쳣�з���
    
    //I��ָ��:I_format+Branch+nBranch+Lw+Sw
    assign I_format = (op[5:3] == 3'b001);   //001xxx��I��ָ��
    assign L_format = (op[5:3] == 3'b100);   //�Ӵ洢���ж�����
    assign S_format = (op[5:2] == 4'b1010);  //д�洢��
    
    assign Beq = (op==6'b000100);            //beqָ��
    assign Bne = (op==6'b000101);            //bneָ��
    assign Bgez = (op==6'b000001&&rt==5'b00001);
    assign Bgtz = (op==6'b000111&&rt==5'b00000);
    assign Blez = (op==6'b000110&&rt==5'b00000);
    assign Bltz = (op==6'b000001&&rt==5'b00000);
    assign Bgezal = (op==6'b000001&&rt==5'b10001);
    assign Bltzal = (op==6'b000001&&rt==5'b10000);
    //assign Branch = Beq||Bne||Bgez||Bgtz||Blez||Bltz||Bgezal||Bltzal;
   
    //J��ָ��
    assign Jmp = (op==6'b000010)? 1'b1:1'b0;            //jָ��
    assign Jal = (op==6'b000011)? 1'b1:1'b0;            //jalָ��

    assign MemRead = l_format&&(Alu_resultHigh!=22'b1111111111111111111111);    
    assign IORead = l_format&&(Alu_resultHigh==22'b1111111111111111111111);     
    assign MemWrite = s_format&&(Alu_resultHigh!=22'b1111111111111111111111);   
    assign IOWrite = s_format&&(Alu_resultHigh==22'b1111111111111111111111);   
    assign MemIOtoReg = l_format;
    
    assign Sftmd = (op==6'b000000&&(func[5:2]==4'b0001&&shamt==5'b00000||func[5:2]==4'b0000&&rs==5'b00000));//sll,srl,sra,sllv,srlv,srav
    assign DivSel = (op==6'b000000&&func[5:1]==5'b01101);
    assign ALUSrc = I_format||L_format||S_format;
    assign ALUOp = {(R_format || I_format),(Beq || Bne || Bgez || Bgtz || Blez ||Bltz || Bgezal || Bltzal)};  // ��R��type����Ҫ��������32λ��չ��ָ��1λΪ1,beq��bneָ����0λΪ1
    assign Memory_sign = !op[2];
    assign Memory_data_width = op[1:0];
    
    wire valueLogicR = (op==6'b000000&&shamt==5'b00000&&func[5:3]==3'b100);//add,addu,sub,subu,and,or,xor,nor
    wire mulAndDiv = (op==6'b000000&&rd==5'b00000&&shamt==5'b00000&&func[5:2]==4'b0110);//mult,multu,div,divu
    wire Rcmp = (op==6'b000000&&shamt==5'b00000&&func[5:1]==5'b10101);//slt,sltu
    wire R31 = valueLogicR||mulAndDiv||Mfhi||Mflo||Mthi||Mtlo||Mfc0||Mtc0||Sftmd||Jrn||Jalr||Break||Syscall||Eret;
    wire valueLogicI = (I_format&&((op==6'b001111)?(rs==5'b00000):1'b1));//addi,addiu,andi,ori,xori,lui,slti,sltiu
    wire L5 = (I_format&&(!(op[2:0]==3'b111||op[2:0]==3'b110||op[2:0]==3'b010)));//lb,lbu,lh,lhu,lw
    wire S3 = (S_format&&op[1:0]!=2'b10);//sb,sh,sw
    wire I24 = valueLogicI||L5||S3||Beq||Bne||Bgez||Bgtz||Blez||Bltz||Bgezal||Bltzal;
    wire J2 = Jmp||Jal;
    assign Reserved_instruction = !(R31||I24||J2);//����ָ�δʵ�ֵ�ָ��쳣
    
    //assign Wir = (state==sif);
    //assign Waluresult = (state==sexe);
    
    //assign RegWrite = (R_format&&!Jrn)||I_format||Lw||Jal;     
    //assign RegWrite = ((state==sid)&Jal)|(state==swb);
    //assign RegDST = R_format && (state == swb);                               //˵��Ŀ����rd��������rt
    assign RegWrite = R_format? (func[5:3]==3'b100||func[5:1]==5'b10101||Mfhi||Mflo||Mfc0||Sftmd||Jalr):
                                (I_format||L_format||Bgezal||Bltzal||Jal);
    assign RegDST = Mfc0 ? 0:R_format;    // ֻ��Rָ���ȥMfc0ʱΪrd   
    
    /*assign MemWrite = S_format&&(Alu_resultHigh!=22'b1111111111111111111111)&&(state==smem);   ///
    assign IOWrite = S_format&&(Alu_resultHigh==22'b1111111111111111111111)&&(state==smem);    ///
    assign MemIOtoReg = L_format&&(state==swb); // Opcode==6'b100011*/
    
    /*    
    always @* begin
        Wpc = 2'b00;
        case(state)
            sinit:next_state = sif;
            sif:begin
                Wpc = 2'b01;
                next_state = sid;
                end
            sid:
                if(Jmp|Jal|Jrn) begin
                    Wpc = 2'b10;
                    next_state = sif;//J��ָ��
                    end
                else next_state = sexe;
            sexe: 
                if(L_format||S_format)next_state = smem;
                else if(Bne||Beq) begin
                        if((Beq&&Zero)||(Bne&&!Zero))
                            Wpc = 2'b11;
                        next_state=sif;
                        end
                    else next_state = swb;
            smem: if(L_format) next_state = swb;
                else next_state = sif;
            swb: next_state = sif;
            default: next_state=sinit;
        endcase
    end
    
    always @(negedge clock or posedge reset) begin
        if(reset) begin
            state <= sinit;
        end else begin
            state <= next_state;
        end
    end
    */
endmodule
