`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/19 11:23:04
// Design Name: 
// Module Name: hazard
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


module hazard(
    input   ex_MemRead,
    input   [4:0]   id_rt,
    input   [4:0]   id_rs,
    input   [4:0]   ex_rt,

    output  ID_EX_stall,
    output  PC_IFWrite
    );

    // load-use √∞œ’
    assign ID_EX_stall = (ex_MemRead===1'b1) && (id_rs==ex_rt|| id_rt==ex_rt);
    assign PC_IFWrite = ~ID_EX_stall;

endmodule
