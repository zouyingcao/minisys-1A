.DATA 0X0

.TEXT 0X0000
start:
	lui	$t0,0xFFFF		# 0:$8=0xFFFF0000
	ori	$t0,$t0,0xF000	# 4:$8=0xFFFFF000
watchdog:				# �ں�һ��16 λ��ʱ����ϵͳ��λ�����ֵΪ 0FFFFH��֮��ÿʱ�Ӽ���ֵ�� 1��������0 ��ʱ����CPU��4��ʱ�����ڵ�RESET�źţ�ͬʱ����ֵ�ָ��� 0FFFFH �����������
	sw $zero,0xC50($t0) 	# ֻҪд�ö˿ھͻ����ü���
lop:
	beq $at,$at,lop