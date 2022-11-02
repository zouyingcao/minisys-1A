.DATA 0X0

.TEXT 0X0000
start:
	lui	$t0,0xFFFF		# 0:$8=0xFFFF0000
	ori	$t0,$t0,0xF000	# 4:$8=0xFFFFF000
ledAndSwitch: 				# switch2N4 = 24'h5a078f
	lw 	$t1,0xC70($t0)	# 8:读前16个拨码开关到$9
	sw	$t1,0xC60($t0)	# c:用$9的低16bit中,低8bit写绿灯,高8bit写黄灯
	lw 	$t1,0xC72($t0)	# 10:其中低8bit有效,读后8个拨码开关
	sw	$t1,0xC62($t0)	# 14:其中低 8bit 有效,写红灯
	j	ledAndSwitch