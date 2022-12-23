`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/08/08 14:26:34
// Design Name: 
// Module Name: ram_sim
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


module ram_sim(
    );
    // input
    reg		  ram_clk_i=1'b0;
    reg       ram_wen_i=1'b0;        // ���Կ��Ƶ�Ԫ
    reg[1:0]  ram_dat_width=2'b0;
    reg       ram_sign=1'b0;
    reg[15:0] ram_adr_i=16'h0000;        // ����memorioģ�飬Դͷ������ִ�е�Ԫ�����alu_result,�洢��ַ
    reg[31:0] ram_dat_i=32'h00000000;        // �������뵥Ԫ��read_data2
    
    // output
    wire bit_error;
    wire[31:0] ram_dat_o;        // �Ӵ洢���л�õ�����

    dmemory4x8 Uram(ram_clk_i,ram_wen_i,ram_dat_width,ram_sign,
    ram_adr_i,ram_dat_i,bit_error,ram_dat_o);

    initial begin
      #100 begin ram_sign=1'b1; end
      #100 begin ram_adr_i=16'h0004; end
      #100 begin ram_sign=1'b0; end
      #200 begin ram_adr_i=16'h0008; end
      #100 begin ram_dat_width=2'b1; ram_sign=1'b1; ram_adr_i=16'h0010; end
      #100 begin ram_dat_width=2'b0; ram_sign=1'b0; ram_adr_i=16'h0014; end
      #100 begin ram_dat_width=2'b1; ram_adr_i=16'h0010; end
      #100 begin ram_wen_i=1'b1; ram_dat_width=2'b0; ram_sign=1'b1; ram_adr_i=16'h0010; ram_dat_i=32'h00000007; end
      #100 begin ram_wen_i=1'b0; ram_dat_width=2'd3; ram_adr_i=16'h0010; end

    end
    always #50 ram_clk_i = ~ram_clk_i;            
endmodule
