`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/24 10:42:39
// Design Name: 
// Module Name: keyboard
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 行列扫描
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module keyboard(
    input clock,
    input reset,
    input read_enable,              // 读信号
    input keyboardCtrl,             // 键盘片选信号
    input [3:0] column,
    input [2:0] address,            // 到keyboard模块的地址低端
    output reg[15:0] read_data_output, // 送到CPU的4x4键盘值
    output reg[3:0] row
    );
    reg [15:0] count;
    reg [15:0] value;
    reg [2:0]  state;

    always @(negedge clock or posedge reset)
    begin
        if (keyboardCtrl == 0 || reset == 1) begin
            read_data_output = 16'h0000;
            count = 16'h0000;
            value = 16'h0000;
            state = 4'b0000;
            row = 4'b0000;
        end else begin
            case(state)
                3'b000:begin
                    row = 4'b0000;
                    count = 16'd0;
                    if(column!=4'b1111)
                        state = 3'b001;
                end
                3'b001:begin // 去抖处理
                    if(count != 20000)
                        count <= count + 16'd1;
                    else if(column == 4'b1111) begin  //如果这时候行线全为1 说明抖动了 回到初始状态
                        state = 3'b000;
                        count = 16'd0;
                    end else begin  //如果仍然不全为1 说明真的有键位输入 开始扫描行
                        row = 4'b1110;// 从第一行开始扫描
                        state = 3'b010;
                    end
                end
                3'b010:begin // 第一行(0,F,E,D)
                    if(column == 4'b1111)begin
                        row = 4'b1101;
                        state = 3'b011;
                    end else begin
                        state = 3'b000;
                        value[3:0] = column;
                        value[7:4] = row;
                        if(column == 4'b1110)
                            value[11:8] = 4'hD;
                        else if(column == 4'b1101)
                            value[11:8] = 4'hF;
                        else if(column == 4'b1011)
                            value[11:8] = 4'h0;
                        else if(column == 4'b0111)
                            value[11:8] = 4'hE;
                    end
                end 
                3'b011:begin // 第二行(7,8,9,C)
                    if(column == 4'b1111)begin
                        row = 4'b1011;
                        state = 3'b100;
                    end else begin
                        state = 3'b000;
                        value[3:0] = column;
                        value[7:4] = row;
                        if(column == 4'b1110)
                            value[11:8] = 4'hC;
                        else if(column == 4'b1101)
                            value[11:8] = 4'h9;
                        else if(column == 4'b1011)
                            value[11:8] = 4'h8;
                        else if(column == 4'b0111)
                            value[11:8] = 4'h7;
                    end
                end   
                3'b100:begin // 第三行(4,5,6,B)
                    if(column == 4'b1111)begin
                        row = 4'b0111;
                        state = 3'b101;
                    end else begin
                        state = 3'b000;
                        value[3:0] = column;
                        value[7:4] = row;
                        if(column == 4'b1110)
                            value[11:8] = 4'hB;
                        else if(column == 4'b1101)
                            value[11:8] = 4'h6;
                        else if(column == 4'b1011)
                            value[11:8] = 4'h5;
                        else if(column == 4'b0111)
                            value[11:8] = 4'h4;
                    end
                end  
                3'b101:begin // 第四行(1,2,3,A)
                    if(column == 4'b1111)begin
                        row = 4'b0000;
                        state = 3'b000;
                    end else begin
                        state = 3'b000;
                        value[3:0] = column;
                        value[7:4] = row;
                        if(column == 4'b1110)
                            value[11:8] = 4'hA;
                        else if(column == 4'b1101)
                            value[11:8] = 4'h3;
                        else if(column == 4'b1011)
                            value[11:8] = 4'h2;
                        else if(column == 4'b0111)
                            value[11:8] = 4'h1;
                    end
                end  
            endcase

        if (read_enable == 1)
            case (address)
                3'b000: read_data_output = value; // {4'd0,column,row,value},键值寄存器(0FFFFFC10H)
                3'b010: // 状态寄存器(0XFFFFFC12)
                    read_data_output = (state > 3'd1) ? 16'd1:16'd0;
                default: read_data_output = 16'hZZZZ;
            endcase
        end
    end
endmodule
