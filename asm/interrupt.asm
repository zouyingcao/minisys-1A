.DATA 0X0

.TEXT 0xF500				# pc/4=15680
start:
	lui	$28,0xFFFF		# F500:$8=0xFFFF0000
	ori	$28,$28,0xF000	# F504:$8=0xFFFFF000
	ori 	$1,$zero,13		# F508
	mfc0 $5,$1,0			# F50c
	srl 	$5,$5,2			# F510
	ori 	$2,$zero,0x0		# F514
	beq 	$5,$2,keyInterrupt	# F518:数码管随键盘显示
	ori 	$2,$zero,0xD		# F51c
	beq 	$5,$2,s1Interrupt	# F520:清空数码管显示
	j	s1Interrupt
keyInterrupt:
	lw	$4,0xC10($28)	# F524:读键盘键值
	ori	$1,$0,0xFF0F		# F528
	ori 	$3,$zero,0		# F52C
	ori	$2,$zero,0x6120	# F530
loop2:
	addi	$3,$3,1			# F534
	sw    $1,0xC04($28)	# F538:数码管控制寄存器，8位数码管全亮，小数点只显示低4位
	bne 	$3,$2,loop2		# F53c
	ori 	$3,$zero,0		# F540
loop3:
	addi	$3,$3,1			# F544
	sw   	$4,0xC00($28)	# F548:显示在数码管低四位
	bne 	$3,$2,loop3		# F54c
	eret					# F550
s1Interrupt:
	ori	$1,$0,0xFFFF		# F554:数码管均有效
	ori	$3,$zero,0		# F558
	ori	$2,$zero,0x6120	# F55c
loop4:
	addi	$3,$3,1			# F560
	sw   	$1,0xC04($28)	# F564
	bne 	$3,$2,loop4		# F568
	ori	$3,$zero,0		# F56c
loop5:
	addi	$3,$3,1			# F570
	sw   	$0,0xC00($28)	# F574:显示在数码管低四位
	bne 	$3,$2,loop5		# F578
	ori	$3,$zero,0		# F57c
loop6:
	addi	$3,$3,1			# F580
	sw   	$0,0xC02($28)	# F584:显示在数码管高四位
	bne 	$3,$2,loop6		# F588
	eret					# F58c
