.DATA 0X0

.TEXT 0X0000
start:
	lui	$t0,0xFFFF		# 0:$8=0xFFFF0000
	ori	$t0,$t0,0xF000	# 4:$8=0xFFFFF000
keyboard:					# keyboardIn = 4'b1010
	#  lw	$t3,0xC12($t0)
	lw	$t1,0xC10($t0)	
	sw	$t1,0xC60($t0)	# ledœ‘ ækeyboard∞¥º¸÷µ
	j	keyboard