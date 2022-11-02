.DATA 0X0

.TEXT 0X0000
start:
	lui	$t0,0xFFFF		# 0:$8=0xFFFF0000
	ori	$t0,$t0,0xF000	# 4:$8=0xFFFFF000
watchdog:				# 内含一个16 位定时器，系统复位后计数值为 0FFFFH，之后每时钟计数值减 1，当减到0 的时候，向CPU发4个时钟周期的RESET信号，同时计数值恢复到 0FFFFH 并继续计数�
	sw $zero,0xC50($t0) 	# 只要写该端口就会重置计数
lop:
	beq $at,$at,lop