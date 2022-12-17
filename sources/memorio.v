`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module memorio (
    input	[31:0]	caddress,		// from alu_result in executs32
    input			memread,		// read memory, from control32
    input			memwrite,		// write memory, from control32
    input			ioread,			// read IO, from control32
    input			iowrite,		// write IO, from control32
    input	[31:0]	mread_data,		// data from memory
    input	[15:0]	ioread_data,	// data from io,16 bits
    input	[31:0]	wdata,			// the data from idecode32,that want to write memory or io
    output	[31:0]	rdata,			// data from memory or IO that want to read into register
    output reg[31:0]write_data,		// data to memory or I/O
    output	[31:0]	address,		// address to mAddress and I/O
    output          timerCtrl,      // 2��16λ��ʱ/������
    output          keyboardCtrl,   // 4��4���̿�����
    output          digtalTubeCtrl, // 8λ7�������
    output          BuzzerCtrl,     // ������
    output          WatchdogCtrl,   // ���Ź�
    output          PWMCtrl,        // PWM�����ȵ���
    output			LEDCtrl,		// LED CS 
    output			SwitchCtrl		// Switch CS ���뿪��
);
    assign  address = caddress;
    // ����ȡ����������IO�����������չ
    assign  rdata = (memread==1) ? mread_data : {16'h0000,ioread_data[15:0]};
    // �Ƿ�ΪIO����
    wire iorw;
    assign  iorw = (iowrite||ioread);
	
	// �ӿڵĵ�ַ
	assign digtalTubeCtrl = ((iorw==1) && (caddress[31:4] == 28'hFFFFFC0)) ? 1'b1:1'b0;
	assign keyboardCtrl = ((iorw==1) && (caddress[31:4] == 28'hFFFFFC1)) ? 1'b1:1'b0;
	assign timerCtrl = ((iorw==1) && (caddress[31:4] == 28'hFFFFFC2)) ? 1'b1:1'b0;
	assign PWMCtrl = ((iorw==1) && (caddress[31:4] == 28'hFFFFFC3)) ? 1'b1:1'b0;
    assign WatchdogCtrl = ((iorw==1) && (caddress[31:4] == 28'hFFFFFC5)) ? 1'b1:1'b0;
    assign LEDCtrl = ((iorw==1) && (caddress[31:4] == 28'hFFFFFC6)) ? 1'b1:1'b0;
    assign SwitchCtrl = ((iorw==1) && (caddress[31:4] == 28'hFFFFFC7)) ? 1'b1:1'b0;
	assign BuzzerCtrl = ((iorw==1) && (caddress[31:4] == 28'hFFFFFD1)) ? 1'b1:1'b0;
	
    always @(*) begin
        if(memwrite||iowrite) begin
            write_data = wdata;
        end else begin
            write_data = 32'hZZZZZZZZ;
        end
    end
endmodule