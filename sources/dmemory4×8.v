`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/18 14:15:50
// Design Name: 
// Module Name: dmemory4*8
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

// �ɿ��ǽ���洢������ƣ������ֽڷ��ʡ����ַ��ʺ��ַ���
module dmemory4x8(
    input			ram_clk_i,
    input			ram_wen_i,		// ���Կ��Ƶ�Ԫ
    input   [1:0]   ram_dat_width,
    input           ram_sign,
    input	[15:0]	ram_adr_i,		// ����memorioģ�飬Դͷ������ִ�е�Ԫ�����alu_result,�洢��ַ
    input	[31:0]	ram_dat_i,		// �������뵥Ԫ��read_data2
    output   reg   bit_error,
    output reg[31:0]ram_dat_o,		// �Ӵ洢���л�õ�����
	// UART Programmer Pinouts
	input           upg_rst_i,      // UPG reset (Active High)
	input           upg_clk_i,      // UPG ram_clk_i (10MHz)
	input           upg_wen_i,		// UPG write enable
	input	[13:0]	upg_adr_i,		// UPG write address
	input	[31:0]	upg_dat_i,		// UPG write data
	input           upg_done_i      // 1 if programming is finished
    );
    
    wire ram_clk = ram_clk_i;	    // ��Ϊʹ��Block ram�Ĺ����ӳ٣�RAM�ĵ�ַ����������ʱ��������׼����,
                                    // ʹ��ʱ�����������ݶ����������Բ��÷���ʱ�ӣ�ʹ�ö������ݱȵ�ַ׼
                                    // ����Ҫ���Լ���ʱ�ӣ��Ӷ��õ���ȷ��ַ��
                                 
    // kickOff = 1��ʱ��CPU ����������������Ǵ������س���
    wire kickOff = upg_rst_i | (~upg_rst_i & upg_done_i);
    reg [3:0] ram_wen;
    wire [7:0] ram_data0,ram_data1,ram_data2,ram_data3;
    
    always @(*) begin
        ram_wen = 4'd0;
        bit_error = 1'b0;
        case(ram_dat_width)
            2'b00:begin
                ram_wen[0] = (ram_adr_i[1:0]==2'b00)&&ram_wen_i;
                ram_wen[1] = (ram_adr_i[1:0]==2'b01)&&ram_wen_i;
                ram_wen[2] = (ram_adr_i[1:0]==2'b10)&&ram_wen_i;
                ram_wen[3] = (ram_adr_i[1:0]==2'b11)&&ram_wen_i;
            end
            2'b01:begin
                bit_error = ram_adr_i[0]&&ram_wen_i;
                ram_wen[1:0] = {2{(ram_adr_i[1]==1'b0)&&ram_wen_i}};//��дRAM #0, #1
                ram_wen[3:2] = {2{(ram_adr_i[1]==1'b1)&&ram_wen_i}};//��дRAM #2, #3
            end
            2'b11:begin 
                bit_error = (!(ram_adr_i[1:0]==2'b00))&&ram_wen_i;
                ram_wen = {4{ram_wen_i}}; // update
            end 
            default:bit_error = ram_wen_i;// 2'b10
        endcase
    end
    
    ram0 ram0 (
        .clka     (kickOff ?    ram_clk      : upg_clk_i),
        .wea      (kickOff ?    ram_wen[0]    : upg_wen_i),
        .addra    (kickOff ?    ram_adr_i[15:2]: upg_adr_i),
        .dina     (kickOff ?    ram_dat_i[7:0]: upg_dat_i[7:0]),
        .douta    (ram_data0)
    );
    ram1 ram1 (
        .clka     (kickOff ?    ram_clk      : upg_clk_i),
        .wea      (kickOff ?    ram_wen[1]    : upg_wen_i),
        .addra    (kickOff ?    ram_adr_i[15:2]: upg_adr_i),
        .dina     (kickOff ?    ram_dat_i[15:8]: upg_dat_i[15:8]),
        .douta    (ram_data1)
    );
    ram2 ram2 (
        .clka     (kickOff ?    ram_clk      : upg_clk_i),
        .wea      (kickOff ?    ram_wen[2]    : upg_wen_i),
        .addra    (kickOff ?    ram_adr_i[15:2]: upg_adr_i),
        .dina     (kickOff ?    ram_dat_i[23:16]: upg_dat_i[23:16]),
        .douta    (ram_data2)
    );
    ram3 ram3 (
        .clka     (kickOff ?    ram_clk      : upg_clk_i),
        .wea      (kickOff ?    ram_wen[3]    : upg_wen_i),
        .addra    (kickOff ?    ram_adr_i[15:2]: upg_adr_i),
        .dina     (kickOff ?    ram_dat_i[31:24]: upg_dat_i[31:24]),
        .douta    (ram_data3)
    );  
    
    always @(*) begin
        case(ram_dat_width)
            2'b00:begin
                case(ram_adr_i[1:0])
                    2'b00:begin ram_dat_o[7:0] = ram_data0;end
                    2'b01:begin ram_dat_o[7:0] = ram_data1;end
                    2'b10:begin ram_dat_o[7:0] = ram_data2;end
                    2'b11:begin ram_dat_o[7:0] = ram_data3;end
                endcase
                ram_dat_o[31:8] = {24{ram_sign & ram_dat_o[7]}};
            end
            2'b01:begin
                case(ram_adr_i[1])
                   1'b0:begin ram_dat_o[15:0] = {ram_data1,ram_data0};end
                   1'b1:begin ram_dat_o[15:0] = {ram_data3,ram_data2};end
                endcase
                ram_dat_o[31:16] = {16{ram_sign & ram_dat_o[15]}};
            end
            2'b11:
                if(!bit_error)
                    ram_dat_o = {ram_data3,ram_data2,ram_data1,ram_data0};
        endcase
    end
    
endmodule
