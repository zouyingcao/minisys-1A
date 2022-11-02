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

// 可考虑交叉存储器的设计，便于字节访问、半字访问和字访问
module dmemory4x8(
    input			ram_clk_i,
    input			ram_wen_i,		// 来自控制单元
    input   [1:0]   ram_dat_width,
    input           ram_sign,
    input	[15:0]	ram_adr_i,		// 来自memorio模块，源头是来自执行单元算出的alu_result,存储地址
    input	[31:0]	ram_dat_i,		// 来自译码单元的read_data2
    output   reg   bit_error,
    output reg[31:0]ram_dat_o,		// 从存储器中获得的数据
	// UART Programmer Pinouts
	input           upg_rst_i,      // UPG reset (Active High)
	input           upg_clk_i,      // UPG ram_clk_i (10MHz)
	input           upg_wen_i,		// UPG write enable
	input	[13:0]	upg_adr_i,		// UPG write address
	input	[31:0]	upg_dat_i,		// UPG write data
	input           upg_done_i      // 1 if programming is finished
    );
    
    wire ram_clk = ram_clk_i;	    // 因为使用Block ram的固有延迟，RAM的地址线来不及在时钟上升沿准备好,
                                    // 使得时钟上升沿数据读出有误，所以采用反相时钟，使得读出数据比地址准
                                    // 备好要晚大约半个时钟，从而得到正确地址。
                                 
    // kickOff = 1的时候CPU 正常工作，否则就是串口下载程序。
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
                ram_wen[1:0] = {2{(ram_adr_i[1]==1'b0)&&ram_wen_i}};//读写RAM #0, #1
                ram_wen[3:2] = {2{(ram_adr_i[1]==1'b1)&&ram_wen_i}};//读写RAM #2, #3
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
