.DATA 0X0

.TEXT 0X0000
start:
	lui	$t0,0xFFFF		# $8=0xFFFF0000
	ori	$t0,$t0,0xF000	# $8=0xFFFFF000
	addi	$t1,$zero,0x2		# $9=0x2
	addi	$t2,$zero,0x6		# $10=0x6
timer:
	sw 	$t1,0xC20($t0)	# дCTC0��ʽ�Ĵ���(��ʱor ����,�ظ�or ���ظ�), e.g., ��ʱ�ظ�
	sw 	$t2,0xC24($t0)	# дCTC0��ʼֵ�Ĵ���
lop:	
	sub	$t3,$t3,$at
	bne	$t3,$zero,lop
	lw	$t3,0xC24($t0)	# ��CTC0����ֵ
lop1:
	sub	$t4,$t4,$a1
	bne	$t4,$zero,lop1
	lw	$t1,0xC20($t0)	# ��CTC0״̬������