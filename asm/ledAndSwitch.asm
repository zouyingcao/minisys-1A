.DATA 0X0

.TEXT 0X0000
start:
	lui	$t0,0xFFFF		# 0:$8=0xFFFF0000
	ori	$t0,$t0,0xF000	# 4:$8=0xFFFFF000
ledAndSwitch: 				# switch2N4 = 24'h5a078f
	lw 	$t1,0xC70($t0)	# 8:��ǰ16�����뿪�ص�$9
	sw	$t1,0xC60($t0)	# c:��$9�ĵ�16bit��,��8bitд�̵�,��8bitд�Ƶ�
	lw 	$t1,0xC72($t0)	# 10:���е�8bit��Ч,����8�����뿪��
	sw	$t1,0xC62($t0)	# 14:���е� 8bit ��Ч,д���
	j	ledAndSwitch