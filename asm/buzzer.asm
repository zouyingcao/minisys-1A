.DATA 0X0

.TEXT 0X0000
start:
	lui	$t0,0xFFFF		# 0:$8=0xFFFF0000
	ori	$t0,$t0,0xF000	# 4:$8=0xFFFFF000
buzzer:
	sw 	$at,0xD10($t0)	# д������״̬(0��Ч,1��Ч)
	nop
	nop
	sw 	$zero,0xD10($t0)	# ʹ�ý�������Ҫ sw 0xFD10 �ص�������