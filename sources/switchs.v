`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module switchs (
    input			switrst,		// ��λ�ź�
    input			switclk,		// ʱ���ź�
    input			switchcs,		// ��memorio���ģ��ɵ�����λ�γɵ�switchƬѡ�ź�  !!!!!!!!!!!!!!!!!
    input	[1:0]	switchaddr,		// ��switchģ��ĵ�ַ�Ͷ�  !!!!!!!!!!!!!!!
    input			switchread,		// ���ź�
    output reg[15:0]switchrdata,	// �͵�CPU�Ĳ��뿪��ֵע����������ֻ��16��
    input	[23:0]	switch_i		// �Ӱ��϶���24λ��������
);
    always@(posedge switclk or posedge switrst) begin
        if(switrst)
            switchrdata=24'h000000;
        else if(switchcs&&switchread) begin
            if(switchaddr==2'b00)  
                switchrdata[15:0]=switch_i[15:0];
            else if(switchaddr==2'b10) // 0xFFFFC62,24λ���ݵĸ�8λ���ݶ�Ӧ��ɫ��RLD
                switchrdata[15:0]={8'd0,switch_i[23:16]};
        end   
    end
endmodule
