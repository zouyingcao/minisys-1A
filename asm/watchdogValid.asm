.DATA 0X0

.TEXT 0X0000
start:
	lui	$28,0xFFFF		# 0:$8=0xFFFF0000
	ori	$28,$28,0xF000	# 4:$8=0xFFFFF000
	sw 	$1,0xC60($28)	# 14
watchdog:				# ÄÚº¬Ò»¸ö16 Î»¶¨Ê±Æ÷£¬ÏµÍ³¸´Î»ºó¼ÆÊýÖµÎª 0FFFFH£¬Ö®ºóÃ¿Ê±ÖÓ¼ÆÊýÖµ¼õ 1£¬µ±¼õµ½0 µÄÊ±ºò£¬ÏòCPU·¢4¸öÊ±ÖÓÖÜÆÚµÄRESETÐÅºÅ£¬Í¬Ê±¼ÆÊýÖµ»Ö¸´µ½ 0FFFFH ²¢¼ÌÐø¼ÆÊý¡
	sw 	$zero,0xC50($28) 	# 20:Ö»ÒªÐ´¸Ã¶Ë¿Ú¾Í»áÖØÖÃ¼ÆÊý
loop:
	lw 	$t1,0xC12($28)	# 24
	bne 	$t1,$1,loop		# 28
	lw	$t1,0xC10($28)	# 2c:È¡Êý
	sw 	$t1,0xC60($28)	# 
	j	loop