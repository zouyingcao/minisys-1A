.DATA 0X0

.TEXT 0X0000
start:
	lui	$t0,0xFFFF		# 0:$8=0xFFFF0000
	ori	$t0,$t0,0xF000	# 4:$8=0xFFFFF000
	addi	$t1,$zero,0xc3		# 低 8bit 有效,写数码管的有效信号
	ori	$t2,$zero,0xABCD	# 
	ori	$t3,$zero,0x1234	# 
digitalTube:
	sw	$t1,0xC04($t0)	# 
	sw	$t2,0xC00($t0)	# 16bit,写低位 4 个数码管的值
	sw	$t3,0xC02($t0)	# 16bit,写高位 4 个数码管的值
	j	digitalTube
	