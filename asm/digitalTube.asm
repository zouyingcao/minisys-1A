.DATA 0X0

.TEXT 0X0000
start:
	lui	$t0,0xFFFF		# 0:$8=0xFFFF0000
	ori	$t0,$t0,0xF000	# 4:$8=0xFFFFF000
	addi	$t1,$zero,0xc3		# �� 8bit ��Ч,д����ܵ���Ч�ź�
	ori	$t2,$zero,0xABCD	# 
	ori	$t3,$zero,0x1234	# 
digitalTube:
	sw	$t1,0xC04($t0)	# 
	sw	$t2,0xC00($t0)	# 16bit,д��λ 4 ������ܵ�ֵ
	sw	$t3,0xC02($t0)	# 16bit,д��λ 4 ������ܵ�ֵ
	j	digitalTube
	