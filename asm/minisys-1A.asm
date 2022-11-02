.DATA 0X0

.TEXT 0X0000
start: 
	lui 	$t0,0xffff		# 00:$8=0xffff0000
	addiu $t1,$zero,61	# 04:$9=61=111101=0x3d
	andi	$t2,$a1,2		# 08:$10=$5&2=0
	xori	$t3,$a1,6		# 0c:$11=$5^6=101|110=3
	ori	$t4,$a1,12	# 10:$12=$5|12=13=0xd
	add	$t2,$t0,$t1	# 14:$10=$8+$9=0xffff003d(负数)
	addu $t3,$t0,$t1	# 18:$11=0xffff003d,无符号加
	sub	$t2,$t0,$t1	# 1c:$10=$8-$9=-2^12-61=0xfffeffc3(负数)
	subu	$t3,$t0,$t1	# 20:$11=0xfffeffc3,无符号减
	addi	$t2,$t0,6		# 24:$10=$8+6=0xffff0006
	mult	$t0,$t1		# 28:有符号乘法
	mfhi	$t2			# 2c:$10=0xffffffff
	mflo	$t3			# 30:$11=0xffc30000
	multu $t0,$t1		# 34:无符号乘法
	mfhi	$t2			# 38:$10=0x0000003c
	mflo	$t3			# 3c:$11=0xffc30000
	or	$t2,$t0,$t1	# 40:$10=$8|$9=0xffff003d
	nor	$t2,$t0,$t1	# 44:$10=~($8|$9)=0x0000ffc2
	xor   $t2,$t0,$t1	# 48:$10=$8^$8=0xffff003d
	and	$t2,$t0,$t1	# 4c:$10=$8&$9=0x0
	div	$t0,$t1		# 50:有符号除法
	mfhi	$t2			# 54:$10=0xffffffea
	mflo	$t3			# 58:$11=0xffffbce
	divu	$t0,$t1		# 5c:无符号除法
	mthi	$a0			# 60:$hi=0x4
	mtlo	$a1			# 64:$lo=0x5
	slt	$t2,$t0,$t1	# 68:$10=0x1
	sltu	$t2,$t0,$t1	# 6c:$10=0x0
	slti	$t2,$t0,0xf	# 70:$10=0x1
	sltiu	$t2,$t0,0xf	# 74:$10=0x0
	sll	$t3,$at,6		# 78:$11=1000000=0x40
	srl	$t3,$t0,1		# 7c:$11=0x7fff80000
	jal 	first			# 80
	j	start			# 84
first: 
	sra	$t3,$t0,2		# 88:$11=0xffffc000
	sllv	$t3,$t0,$a0	# 8c:$11=0xfff0000
	srlv	$t3,$t0,$a0	# 90:$11=0x0ffff000
	srav	$t3,$t0,$a0	# 94:$11=0xfffff000
	lb 	$t2,4($zero) 	# 98:$10=Memory[4/4]=0xffffffaa,低八位符号扩展
	lbu 	$t2,4($zero)	# 9c:$10=Memory[4/4]=0x000000aa,低八位零扩展
	lh	$t2,12($a0)	# a0:$10=Memory[16/4]=0xffffaaaa,低16位符号扩展
	lhu	$t2,12($a0)	# a4:$10=Memory[16/4]=0x0000aaaa,低16位零扩展
	sb	$a3,16($zero)	# a8:Memory[16/4]的第一个字节=($7)7..0
	lw	$t2,16($zero)	# ac:$10=0x0aaaaa07
	sh	$t3,16($zero)	# b0:Memory[16/4]=($11)15..0
	lw	$t2,16($zero)	# b4:$10=0x0aaaf000
	sw	$t1,22($a2)	# b8:Memory[28/4]=0x3d
	lw	$t4,22($a2)	# bc:$12=0x3d
lop:
	beq	$t4,$at,lop	# c0:if $12=$1,jump lop,不分支
lop1:
	sub	$t4,$t4,$a1	# c4:$12=$12-4
	bne	$t4,$at,lop1	# c8:if $12≠$1,jump lop1
	beq	$at,$at,lop2	# cc:if $1=$1,jump lop2
	nop				# d0
	nop				# d4
lop2:
	bgez $zero,1		# d8:if $zero≥0,jump PC+4+1<<2
	jr	$zero		# dc:PC=0
	bgtz	$t0,1		# e0:if $8>0,jump PC+4+1<<2, 不分支
	blez	$t0,1		# e4:if $8≤0,jump PC+4+1<<2
	j	first			# e8:
	bltz	$t4,1		# ec:if $12<0,jump PC+4+1<<2,不分支
	bgezal $t4,2		# f0:if $12≥0,jump PC+4+2<<2,PC=f4
	jal 	start			# f4
	nop				# f8
	bltzal $zero,3		# fc
	j	lop3			# 100
	nop				# 104
	nop				# 108
lop3:
	jalr	$30,$zero	# 10c

	