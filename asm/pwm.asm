.DATA 0X0

.TEXT 0X0000
start:
	lui	$t0,0xFFFF		# 0:$8=0xFFFF0000
	ori	$t0,$t0,0xF000	# 4:$8=0xFFFFF000
	addi	$t1,$zero,0xFF		
pwm:
	sw 	$t1,0xC30($t0)	# 写最大值寄存器
	sw 	$t2,0xC32($t0)	# 写对比寄存器
	nop
	nop
	sw 	$at,0xC34($t0)	# 低1bit有效,写控制寄存器(0无效,1有效)