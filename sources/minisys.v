`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module minisys (
    input			fpga_rst,	        // 板上的Reset信号，高电平复位
    input			fpga_clk,           // 板上的100MHz时钟信号
    //2个16位定时/计数器、4×4键盘控制器、8位7段数码管控制器
    //16位LED输出、16位拨码开关输入、PWM控制、看门狗控制器的设计
    input   [4:0]   button,             // 五个按钮开关（S1-S5)
    input	[23:0]	switch2N4,	        // 拨码开关输入
    input   [3:0]   keyboardIn,         // 键盘输入线(列线)  
    output  [3:0]   keyboardOut,        // 键盘输出线(行线) 
    output	[23:0]	led2N4,             // LED结果输出到板上
    output  [7:0]   digitalTube,        // 8位7段数码管控制器
    output  [7:0]   digitalTubeEnable,  // 数码管使能信号A0-A7(低电平有效)
    output          pwmOut,             // PWM控制器
    output          wdtOut,             // 看门狗
    output          buzzerOut          // 蜂鸣管
	// UART Programmer Pinouts
//	input           start_pg,           // 接板上的S3按键做下载启动键
//	input           rx,                 // UART接收
//	output          tx                  // UART发送
);
    // cpuclk分频器输出
    wire cpu_clk;                       // cpu_clk: 分频后时钟供给系统
    wire upg_clk;                       // 用于Uart的clock

    // UART Programmer相关
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
        .clk_in1         (fpga_clk),    // 100MHz, 板上时钟
        .clk_out1        (cpu_clk),     // CPU Clock (22MHz), 主时钟
        .clk_out2        (upg_clk)      // UPG Clock (10MHz), 用于串口下载
    );
        
//    uart_bmpg_0 uartpg (                // 此模块已经接好，只作为串口下载的附件，可不去关注
//        .upg_clk_i        (upg_clk),    // 10MHz   
//        .upg_rst_i        (upg_rst),    // 高电平有效
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
    
    //按键去抖
    wire [4:0] button_interrupt;
    button button5(
        .button(button),
        .clock(cpu_clk),
        .button_interrupt(button_interrupt)
    ); 
       
    // 程序ROM单元输出
    wire [31:0] rom_dat;                // 给取指单元的指令
    
    // damemory输出
    wire [31:0] memread_data;	        // RAM中读取的数据
    wire bit_error;
    
    // cpu输出
    wire [13:0] rom_adr;                // 给程序ROM单元的取指地址
	wire [31:0] address;               // address to DMEM
    wire [31:0] write_data;	            // 写RAM或IO的数据
    wire [1:0] mem_memory_data_width;
	wire mem_iowrite,mem_ioread,mem_memwrite,mem_memory_sign;
    wire switchctrl,keyboardctrl,timerctrl,ledctrl,digitaltubectrl,buzzerctrl,pwmctrl,wdtctrl;
	
	// 中断相关
    wire [5:0] interrupt;
    wire keyboard_interrupt;
	
	// 接口相关
    wire ctc0_output,ctc1_output;
    wire [15:0] ioread_data_keyboard,ioread_data_switch,ioread_data_timer;
    wire [15:0] ioread_data;           // 读IO的数据
	
	// 指令存储器IMEM:输入PC，读出指令
	programrom ROM (
		// Program ROM Pinouts
		.rom_clk_i		(cpu_clk),	    // 给CPU的22MHz的主时钟
		.rom_adr_i		(rom_adr),		// 取指单元给ROM的地址（PC/4）
		.Jpadr			(rom_dat)	    // ROM中读的数据（指令）output
		// UART Programmer Pinouts, 以下是串口下载所用，可不必关注
//		.upg_rst_i		(upg_rst),		// UPG reset (高电平有效)
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
        .rom_instruction(rom_dat),          // 指令寄存器读出的指令
        .mread_data     (memread_data),     // 从DRAM/IO读入的数据
        .ioread_data    (ioread_data),      // 从DRAM/IO读入的数据
        .interrupt      (interrupt),        // 外部中断信号 共六根
        //output
        .iaddr          (rom_adr),          // 给指令寄存器的地址
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
        .ram_wen_i	    (mem_memwrite),			// 来自控制单元
        .ram_adr_i		(address[15:0]),	    // 来自memorio模块，源头是来自执行单元算出的alu_result
        .ram_dat_i		(write_data),		    // 来自译码单元的read_data2
		.ram_dat_width  (mem_memory_data_width),
		.ram_sign       (mem_memory_sign),
		.ram_dat_o		(memread_data),		         // 从存储器中获得的数据
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
        .button         (button_interrupt),     // 除S3外的四个按钮开关（S1-S5)
        .keyboardIn     (keyboard_interrupt),  // 键盘中断
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
        .switch_i       (switch2N4),//input,从板上读的24位开关数据
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
