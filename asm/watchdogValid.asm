.DATA 0X0

.TEXT 0X0000
start:
	lui	$28,0xFFFF		# 0:$8=0xFFFF0000
	ori	$28,$28,0xF000	# 4:$8=0xFFFFF000
	sw 	$1,0xC60($28)	# 14
watchdog:				# �ں�һ��16 λ��ʱ����ϵͳ��λ�����ֵΪ 0FFFFH��֮��ÿʱ�Ӽ���ֵ�� 1��������0 ��ʱ����CPU��4��ʱ�����ڵ�RESET�źţ�ͬʱ����ֵ�ָ��� 0FFFFH �����������
	sw 	$zero,0xC50($28) 	# 20:ֻҪд�ö˿ھͻ����ü���
loop:
	lw 	$t1,0xC12($28)	# 24
	bne 	$t1,$1,loop		# 28
	lw	$t1,0xC10($28)	# 2c:ȡ��
	sw 	$t1,0xC60($28)	# 
	j	loop