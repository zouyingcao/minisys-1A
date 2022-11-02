.DATA 0X0

.TEXT 0X0000
start:
	lui	$t0,0xFFFF		# 0:$8=0xFFFF0000
	ori	$t0,$t0,0xF000	# 4:$8=0xFFFFF000
watchdog:				# ÄÚº¬Ò»¸ö16 Î»¶¨Ê±Æ÷£¬ÏµÍ³¸´Î»ºó¼ÆÊýÖµÎª 0FFFFH£¬Ö®ºóÃ¿Ê±ÖÓ¼ÆÊýÖµ¼õ 1£¬µ±¼õµ½0 µÄÊ±ºò£¬ÏòCPU·¢4¸öÊ±ÖÓÖÜÆÚµÄRESETÐÅºÅ£¬Í¬Ê±¼ÆÊýÖµ»Ö¸´µ½ 0FFFFH ²¢¼ÌÐø¼ÆÊý¡
	sw $zero,0xC50($t0) 	# Ö»ÒªÐ´¸Ã¶Ë¿Ú¾Í»áÖØÖÃ¼ÆÊý
lop:
	beq $at,$at,lop