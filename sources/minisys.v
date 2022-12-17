`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module minisys (
    input			fpga_rst,	        // ���ϵ�Reset�źţ��ߵ�ƽ��λ
    input			fpga_clk,           // ���ϵ�100MHzʱ���ź�
    //2��16λ��ʱ/��������4��4���̿�������8λ7������ܿ�����
    //16λLED�����16λ���뿪�����롢PWM���ơ����Ź������������
    input   [4:0]   button,             // �����ť���أ�S1-S5)
    input	[23:0]	switch2N4,	        // ���뿪������
    input   [3:0]   keyboardIn,         // ����������(����)  
    output  [3:0]   keyboardOut,        // ���������(����) 
    output	[23:0]	led2N4,             // LED������������
    output  [7:0]   digitalTube,        // 8λ7������ܿ�����
    output  [7:0]   digitalTubeEnable,  // �����ʹ���ź�A0-A7(�͵�ƽ��Ч)
    output          pwmOut,             // PWM������
    output          wdtOut,             // ���Ź�
    output          buzzerOut          // ������
	// UART Programmer Pinouts
//	input           start_pg,           // �Ӱ��ϵ�S3����������������
//	input           rx,                 // UART����
//	output          tx                  // UART����
);
    // cpuclk��Ƶ�����
    wire cpu_clk;                       // cpu_clk: ��Ƶ��ʱ�ӹ���ϵͳ
    wire upg_clk;                       // ����Uart��clock

    // UART Programmer���
//    wire upg_clk_o, upg_wen_o, upg_done_o;
//    wire [14:0] upg_adr_o;
//    wire [31:0] upg_dat_o;  
      
//    wire spg_bufg;
//    BUFG U1(.I(button[0]), .O(spg_bufg));
    
    // Generate UART Programmer reset signal
//    reg upg_rst;
//    always @ (posedge fpga_clk) begin
//        if (spg_bufg)    upg_rst = 1;
//        if (fpga_rst)    upg_rst = 1;
//    end
    
    wire rst;
    //assign rst = fpga_rst | !upg_rst;
    assign rst = fpga_rst;

    cpuclk cpuclk (
        .clk_in1         (fpga_clk),    // 100MHz, ����ʱ��
        .clk_out1        (cpu_clk),     // CPU Clock (22MHz), ��ʱ��
        .clk_out2        (upg_clk)      // UPG Clock (10MHz), ���ڴ�������
    );
        
//    uart_bmpg_0 uartpg (                // ��ģ���Ѿ��Ӻã�ֻ��Ϊ�������صĸ������ɲ�ȥ��ע
//        .upg_clk_i        (upg_clk),    // 10MHz   
//        .upg_rst_i        (upg_rst),    // �ߵ�ƽ��Ч
//         // blkram signals
//         .upg_clk_o       (upg_clk_o),
//         .upg_wen_o       (upg_wen_o),
//         .upg_adr_o       (upg_adr_o),
//         .upg_dat_o       (upg_dat_o),
//         .upg_done_o      (upg_done_o),
//         // uart signals
//         .upg_rx_i        (rx),
//         .upg_tx_o        (tx)
//    );
    
    //����ȥ��
    wire [4:0] button_interrupt;
    button button5(
        .button(button),
        .clock(cpu_clk),
        .button_interrupt(button_interrupt)
    ); 
       
    // ����ROM��Ԫ���
    wire [31:0] rom_dat;                // ��ȡָ��Ԫ��ָ��
    
    // damemory���
    wire [31:0] memread_data;	        // RAM�ж�ȡ������
    wire bit_error;
    
    // cpu���
    wire [13:0] rom_adr;                // ������ROM��Ԫ��ȡָ��ַ
	wire [31:0] address;               // address to DMEM
    wire [31:0] write_data;	            // дRAM��IO������
    wire [1:0] mem_memory_data_width;
	wire mem_iowrite,mem_ioread,mem_memwrite,mem_memory_sign;
    wire switchctrl,keyboardctrl,timerctrl,ledctrl,digitaltubectrl,buzzerctrl,pwmctrl,wdtctrl;
	
	// �ж����
    wire [5:0] interrupt;
    wire keyboard_interrupt;
	
	// �ӿ����
    wire ctc0_output,ctc1_output;
    wire [15:0] ioread_data_keyboard,ioread_data_switch,ioread_data_timer;
    wire [15:0] ioread_data;           // ��IO������
	
	// ָ��洢��IMEM:����PC������ָ��
	programrom ROM (
		// Program ROM Pinouts
		.rom_clk_i		(cpu_clk),	    // ��CPU��22MHz����ʱ��
		.rom_adr_i		(rom_adr),		// ȡָ��Ԫ��ROM�ĵ�ַ��PC/4��
		.Jpadr			(rom_dat)	    // ROM�ж������ݣ�ָ�output
		// UART Programmer Pinouts, �����Ǵ����������ã��ɲ��ع�ע
//		.upg_rst_i		(upg_rst),		// UPG reset (�ߵ�ƽ��Ч)
//		.upg_clk_i		(upg_clk_o),	// UPG clock (10MHz)
//		.upg_wen_i		(upg_wen_o & !upg_adr_o[14]),	// UPG write enable
//		.upg_adr_i		(upg_adr_o[13:0]),	// UPG write address
//		.upg_dat_i		(upg_dat_o),	    // UPG write data
//		.upg_done_i		(upg_done_o)	    // 1 if programming is finished
	);

    cpu cpu(
        .reset          (rst),
        .clock          (cpu_clk),
        // input
        .rom_instruction(rom_dat),          // ָ��Ĵ���������ָ��
        .mread_data     (memread_data),     // ��DRAM/IO���������
        .ioread_data    (ioread_data),      // ��DRAM/IO���������
        .interrupt      (interrupt),        // �ⲿ�ж��ź� ������
        //output
        .iaddr          (rom_adr),          // ��ָ��Ĵ����ĵ�ַ
        .write_data     (write_data),       // 
        .address        (address),
        .mem_memwrite   (mem_memwrite),
        .mem_memory_sign(mem_memory_sign),
        .mem_memory_data_width(mem_memory_data_width),
    
        .mem_iowrite    (mem_iowrite),
        .mem_ioread     (mem_ioread),
        .ledctrl        (ledctrl),
        .switchctrl     (switchctrl),
        .timerctrl      (timerctrl),     
        .keyboardctrl   (keyboardctrl),    
        .digitaltubectrl(digitaltubectrl),    
        .buzzerctrl     (buzzerctrl),  
        .wdtctrl        (wdtctrl),   
        .pwmctrl        (pwmctrl)
    );
    
    ioread multiioread(
        .reset          (rst),
        .ioread         (mem_ioread),
        
        .switchCtrl     (switchctrl),
        .keyboardCtrl   (keyboardctrl),
        .timerCtrl      (timerctrl),
        
        .ioread_data_switch(ioread_data_switch),
        .ioread_data_keyboard(ioread_data_keyboard),
        .ioread_data_timer(ioread_data_timer),
        
        .ioread_data    (ioread_data)
    );
  
    dmemory4x8 memory (
        .ram_clk_i		(cpu_clk),
        .ram_wen_i	    (mem_memwrite),			// ���Կ��Ƶ�Ԫ
        .ram_adr_i		(address[15:0]),	    // ����memorioģ�飬Դͷ������ִ�е�Ԫ�����alu_result
        .ram_dat_i		(write_data),		    // �������뵥Ԫ��read_data2
		.ram_dat_width  (mem_memory_data_width),
		.ram_sign       (mem_memory_sign),
		.ram_dat_o		(memread_data),		         // �Ӵ洢���л�õ�����
		.bit_error      (bit_error)
		// UART Programmer Pinouts
//		.upg_rst_i		(upg_rst),			         // UPG reset (Active High)
//		.upg_clk_i		(upg_clk_o),		         // UPG clock (10MHz)
//		.upg_wen_i		(upg_wen_o & upg_adr_o[14]), // UPG write enable
//		.upg_adr_i		(upg_adr_o[13:0]),	         // UPG write address
//		.upg_dat_i		(upg_dat_o),		         // UPG write data
//		.upg_done_i		(upg_done_o)		         // 1 if programming is finished
    );  
    
    interrupt INTRPT(
        .button         (button_interrupt),     // ��S3����ĸ���ť���أ�S1-S5)
        .keyboardIn     (keyboard_interrupt),  // �����ж�
        .interrupt      (interrupt)
    );
    
    // interface
    leds led24(
        .ledrst         (rst),
        .led_clk        (cpu_clk),
        .ledwrite       (mem_iowrite && ledctrl),
        .ledcs          (ledctrl),
        .ledaddr        (address[1:0]),
        .ledwdata       (write_data[15:0]),
        .ledout         (led2N4)
    );
    
    switchs switch24(
        .switrst        (rst),
        .switclk        (cpu_clk),
        .switchread     (mem_ioread && switchctrl),
        .switchaddr     (address[1:0]),
        .switchcs       (switchctrl),
        .switch_i       (switch2N4),//input,�Ӱ��϶���24λ��������
        .switchrdata    (ioread_data_switch)//output
    );

    keyboard keyboard(
        .clock          (cpu_clk),
        .reset          (rst),
        .read_enable    (mem_ioread && keyboardctrl),
        .address        (address[2:0]),
        .column         (keyboardIn),
        .row            (keyboardOut),
        .interrupt      (keyboard_interrupt),
        .read_data_output(ioread_data_keyboard)//output
    );

    digitalTube digitaltube(
        .clock          (cpu_clk),
        .reset          (rst),
        .write_enable   (mem_iowrite && digitaltubectrl),
        .address        (address[2:0]),
        .write_data_in  (write_data[15:0]),
        .enable         (digitalTubeEnable),
        .value          (digitalTube)
    );
    
    PWM pwm(
        .clock          (cpu_clk),
        .reset          (rst),
        .write_enable   (mem_iowrite && pwmctrl),
        .address        (address[2:0]),
        .write_data_in  (write_data[15:0]),
        .PWM_output     (pwmOut)
    );
    
    timer timer(
        .clock          (cpu_clk),
        .reset          (rst),
        .read_enable    (mem_ioread && timerctrl),
        .write_enable   (mem_iowrite && timerctrl),
        .address        (address[2:0]),
        .write_data_in  (write_data[15:0]),
        .read_data_out  (ioread_data_timer),
        .CTC0_output    (ctc0_output),
        .CTC1_output    (ctc1_output)
    );
    
    watchdog wdt(
        .clock          (cpu_clk),
        .reset          (rst),
        .write_enable   (mem_iowrite && wdtctrl),
        .WDT_output     (wdtOut)
    );
    
    buzzer buzzer(
        .clock          (cpu_clk),
        .reset          (rst),
        .write_enable   (mem_iowrite && buzzerctrl),
        .write_data_in  (write_data[15:0]),
        .buzzer_output  (buzzerOut)
    );
endmodule
