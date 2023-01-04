.DATA 0X0

.TEXT 0X0000
start:
	lui	$28,0xFFFF		# 0:$8=0xFFFF0000
	ori	$28,$28,0xF000	# 4:$8=0xFFFFF000
	sw 	$1,0xC60($28)	# 14
watchdog:				# 内含一个16 位定时器，系统复位后计数值为 0FFFFH，之后每时钟计数值减 1，当减到0 的时候，向CPU发4个时钟周期的RESET信号，同时计数值恢复到 0FFFFH 并继续计数�
	sw 	$zero,0xC50($28) 	# 20:只要写该端口就会重置计数
loop:
	lw 	$t1,0xC12($28)	# 24
	bne 	$t1,$1,loop		# 28
	lw	$t1,0xC10($28)	# 2c:取数
	sw 	$t1,0xC60($28)	# 
	j	loop