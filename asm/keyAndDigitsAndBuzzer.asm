.DATA 0X0

.TEXT 0X0000
start:
	lui	$28,0xFFFF		# 0:$8=0xFFFF0000
	ori	$28,$28,0xF000	# 4:$8=0xFFFFF000
buzzer:
	lw 	$t1,0xC12($28)	# 8
	bne 	$t1,$1,buzzer		# c
	lw	$t1,0xC10($28)	# 10:ȡ��
	addi	$t2,$0,0xFFFF		# 14
	sw	$t2,0xC04($28)	# 18:�����ʹ��
	addi 	$t2,$0,0x6120		# 1c
delay:
	sw 	$t1,0xC00($28)	# 20
	sub 	$t2,$t2,$1		# 24
	bgtz	$t2,delay			# 28
loop:
	sw 	$1,0xD10($28)	# 2c:д������״̬(0��Ч,1��Ч)
	sub	$t1,$t1,$1		# 30
	bgtz	$t1,loop			# 34
	sw 	$zero,0xD10($28)	# 38:ʹ�ý�������Ҫ sw 0xFD10 �ص�������