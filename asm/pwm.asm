.DATA 0X0

.TEXT 0X0000
start:
	lui	$t0,0xFFFF		# 0:$8=0xFFFF0000
	ori	$t0,$t0,0xF000	# 4:$8=0xFFFFF000
	addi	$t1,$zero,0xFF		
pwm:
	sw 	$t1,0xC30($t0)	# д���ֵ�Ĵ���
	sw 	$t2,0xC32($t0)	# д�ԱȼĴ���
	nop
	nop
	sw 	$at,0xC34($t0)	# ��1bit��Ч,д���ƼĴ���(0��Ч,1��Ч)