.DATA 0X0

.TEXT 0X0000
start:
	lui	$t0,0xFFFF		# 0:$8=0xFFFF0000
	ori	$t0,$t0,0xF000	# 4:$8=0xFFFFF000
buzzer:
	sw 	$at,0xD10($t0)	# 写蜂鸣器状态(0无效,1有效)
	nop
	nop
	sw 	$zero,0xD10($t0)	# 使用结束后需要 sw 0xFD10 关掉蜂鸣器