	j	min_caml_start

#----------------------------------------------------------------------
#
# lib_asm.s
#
#----------------------------------------------------------------------

# * create_array
min_caml_create_array:
	add $r5, $r3, $r2
	mov $r3, $r2
CREATE_ARRAY_LOOP:
	blt  $r2, $r5, CREATE_ARRAY_CONTINUE
	jr $r29
CREATE_ARRAY_CONTINUE:
	sti $r4, $r2, 0	
	addi $r2, $r2, 1	
	j CREATE_ARRAY_LOOP

# * create_float_array
min_caml_create_float_array:
	add $r4, $r3, $r2
	mov $r3, $r2
CREATE_FLOAT_ARRAY_LOOP:
	blt $r2, $r4, CREATE_FLOAT_ARRAY_CONTINUE
	jr $r29
CREATE_FLOAT_ARRAY_CONTINUE:
	fsti $f0, $r2, 0
	addi $r2, $r2, 1
	j CREATE_FLOAT_ARRAY_LOOP

# * floor		$f0 + MAGICF - MAGICF
min_caml_floor:
	fmov $f1, $f0
	# $f4 <- 0.0
	# fset $f4, 0.0
	fmvhi $f4, 0
	fmvlo $f4, 0
	fblt $f0, $f4, FLOOR_NEGATIVE	# if ($f4 <= $f0) goto FLOOR_PISITIVE
FLOOR_POSITIVE:
	# $f2 <- 8388608.0(0x4b000000)
	fmvhi $f2, 19200
	fmvlo $f2, 0
	fblt $f2, $f0, FLOOR_POSITIVE_RET
FLOOR_POSITIVE_MAIN:
	fmov $f1, $f0
	fadd $f0, $f0, $f2
	fsti $f0, $r1, 0
	ldi $r4, $r1, 0
	fsub $f0, $f0, $f2
	fsti $f0, $r1, 0
	ldi $r4, $r1, 0
	fblt $f1, $f0, FLOOR_POSITIVE_RET
	jr $r29
FLOOR_POSITIVE_RET:
	# $f3 <- 1.0
	# fset $f3, 1.0
	fmvhi $f3, 16256
	fmvlo $f3, 0
	fsub $f0, $f0, $f3
	jr $r29
FLOOR_NEGATIVE:
	fneg $f0, $f0
	# $f2 <- 8388608.0(0x4b000000)
	fmvhi $f2, 19200
	fmvlo $f2, 0
	fblt $f2, $f0, FLOOR_NEGATIVE_RET
FLOOR_NEGATIVE_MAIN:
	fadd $f0, $f0, $f2
	fsub $f0, $f0, $f2
	fneg $f1, $f1
	fblt $f0, $f1, FLOOR_NEGATIVE_PRE_RET
	j FLOOR_NEGATIVE_RET
FLOOR_NEGATIVE_PRE_RET:
	fadd $f0, $f0, $f2
	# $f3 <- 1.0
	# fset $f3, 1.0
	fmvhi $f3, 16256
	fmvlo $f3, 0
	fadd $f0, $f0, $f3
	fsub $f0, $f0, $f2
FLOOR_NEGATIVE_RET:
	fneg $f0, $f0
	jr $r29
	
min_caml_ceil:
	fneg $f0, $f0
	sti $r29, $r1, 0
	addi $r1, $r1, -1
	jal min_caml_floor
	addi $r1, $r1, 1
	ldi $r29, $r1, 0
	fneg $f0, $f0
	jr $r29

# * float_of_int
min_caml_float_of_int:
	blt $r3, $r0, ITOF_NEGATIVE_MAIN		# if ($r0 <= $r3) goto ITOF_MAIN
ITOF_MAIN:
	# $f1 <- 8388608.0(0x4b000000)
	fmvhi $f1, 19200
	fmvlo $f1, 0
	# $r4 <- 0x4b000000
	mvhi $r4, 19200
	mvlo $r4, 0
	# $r5 <- 0x00800000
	mvhi $r5, 128
	mvlo $r5, 0
	blt $r3, $r5, ITOF_SMALL
ITOF_BIG:
	# $f2 <- 0.0
	# fset $f2, 0.0
	fmvhi $f2, 0
	fmvlo $f2, 0
ITOF_LOOP:
	sub $r3, $r3, $r5
	fadd $f2, $f2, $f1
	blt $r3, $r5, ITOF_RET
	j ITOF_LOOP
ITOF_RET:
	add $r3, $r3, $r4
	sti $r3, $r1, 0
	fldi $f0, $r1, 0
	fsub $f0, $f0, $f1
	fadd $f0, $f0, $f2
	jr $r29
ITOF_SMALL:
	add $r3, $r3, $r4
	sti $r3, $r1, 0
	fldi $f0, $r1, 0
	fsub $f0, $f0, $f1
	jr $r29
ITOF_NEGATIVE_MAIN:
	sub $r3, $r0, $r3
	sti $r29, $r1, 0
	addi $r1, $r1, -1
	jal ITOF_MAIN
	addi $r1, $r1, 1
	ldi $r29, $r1, 0
	fneg $f0, $f0
	jr $r29

# * int_of_float
min_caml_int_of_float:
	# $f1 <- 0.0
	# fset $f1, 0.0
	fmvhi $f1, 0
	fmvlo $f1, 0
	fblt $f0, $f1, FTOI_NEGATIVE_MAIN			# if (0.0 <= $f0) goto FTOI_MAIN
FTOI_POSITIVE_MAIN:
	sti $r29, $r1, 0
	addi $r1, $r1, -1
	jal min_caml_floor
	addi $r1, $r1, 1
	ldi $r29, $r1, 0
	# $f2 <- 8388608.0(0x4b000000)
	fmvhi $f2, 19200
	fmvlo $f2, 0
	# $r4 <- 0x4b000000
	mvhi $r4, 19200
	mvlo $r4, 0
	fblt $f0, $f2, FTOI_SMALL		# if (MAGICF <= $f0) goto FTOI_BIG
	# $r5 <- 0x00800000
	mvhi $r5, 128
	mvlo $r5, 0
	mov $r3, $r0
FTOI_LOOP:
	fsub $f0, $f0, $f2
	add $r3, $r3, $r5
	fblt $f0, $f2, FTOI_RET
	j FTOI_LOOP
FTOI_RET:
	fadd $f0, $f0, $f2
	fsti $f0, $r1, 0
	ldi $r5, $r1, 0
	sub $r5, $r5, $r4
	add $r3, $r5, $r3
	jr $r29
FTOI_SMALL:
	fadd $f0, $f0, $f2
	fsti $f0, $r1, 0
	ldi $r3, $r1, 0
	sub $r3, $r3, $r4
	jr $r29
FTOI_NEGATIVE_MAIN:
	fneg $f0, $f0
	sti $r29, $r1, 0
	addi $r1, $r1, -1
	jal FTOI_POSITIVE_MAIN
	addi $r1, $r1, 1
	ldi $r29, $r1, 0
	sub $r3, $r0, $r3
	jr $r29
	
# * truncate
min_caml_truncate:
	j min_caml_int_of_float
	
# ビッグエンディアン
min_caml_read_int:
	add $r3, $r0, $r0
	# 24 - 31
	inputb $r4
	add $r3, $r3, $r4
	slli $r3, $r3, 8
	# 16 - 23
	inputb $r4
	add $r3, $r3, $r4
	slli $r3, $r3, 8
	# 8 - 15
	inputb $r4
	add $r3, $r3, $r4
	slli $r3, $r3, 8
	# 0 - 7
	inputb $r4
	add $r3, $r3, $r4
	jr $r29

min_caml_read_float:
	sti $r29, $r1, 0
	addi $r1, $r1, -1
	jal min_caml_read_int
	addi $r1, $r1, 1
	ldi $r29, $r1, 0
	sti $r3, $r1, 0
	fldi $f0, $r1, 0
	jr $r29

#----------------------------------------------------------------------
#
# lib_asm.s
#
#----------------------------------------------------------------------


min_caml_start:
	mvhi	$r2, 0
	mvlo	$r2, 593
	addi	$r30, $r0, 1
	sub	$r31, $r0, $r30
	# 0.000000
	fmvhi	$f16, 0
	fmvlo	$f16, 0
	# 1.000000
	fmvhi	$f17, 16256
	fmvlo	$f17, 0
	# 255.000000
	fmvhi	$f18, 17279
	fmvlo	$f18, 0
	# -1.000000
	fmvhi	$f19, 49024
	fmvlo	$f19, 0
	# 0.500000
	fmvhi	$f20, 16128
	fmvlo	$f20, 0
	# 3.141593
	fmvhi	$f21, 16457
	fmvlo	$f21, 4058
	# 15.000000
	fmvhi	$f22, 16752
	fmvlo	$f22, 0
	# 30.000000
	fmvhi	$f23, 16880
	fmvlo	$f23, 0
	# 10.000000
	fmvhi	$f24, 16672
	fmvlo	$f24, 0
	# 0.100000
	fmvhi	$f25, 15820
	fmvlo	$f25, 52420
	# 1000000000.000000
	fmvhi	$f26, 20078
	fmvlo	$f26, 27432
	# -0.100000
	fmvhi	$f27, 48588
	fmvlo	$f27, 52420
	# 100000000.000000
	fmvhi	$f28, 19646
	fmvlo	$f28, 48160
	# 0.900000
	fmvhi	$f29, 16230
	fmvlo	$f29, 26206
	# 0.200000
	fmvhi	$f30, 15948
	fmvlo	$f30, 52420
	# 0.300000
	fmvhi	$f31, 16025
	fmvlo	$f31, 39321
	# 2.000000
	fmvhi	$f10, 16384
	fmvlo	$f10, 0
	addi	$r3, $r0, 1
	addi	$r4, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 591
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 1
	addi	$r4, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 590
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 1
	addi	$r4, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 589
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 1
	addi	$r4, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 588
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 1
	addi	$r4, $r0, 1
	sti	$r2, $r0, 593
	addi	$r2, $r0, 587
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 1
	addi	$r4, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 586
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 1
	addi	$r4, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 585
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 584
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r4, $r3
	ldi	$r2, $r0, 593
	addi	$r6, $r0, 60
	addi	$r10, $r0, 0
	addi	$r9, $r0, 0
	addi	$r8, $r0, 0
	addi	$r7, $r0, 0
	addi	$r5, $r0, 0
	mov	$r3, $r2
	addi	$r2, $r2, 11
	sti	$r4, $r3, 10
	sti	$r4, $r3, 9
	sti	$r4, $r3, 8
	sti	$r4, $r3, 7
	sti	$r5, $r3, 6
	sti	$r4, $r3, 5
	sti	$r4, $r3, 4
	sti	$r7, $r3, 3
	sti	$r8, $r3, 2
	sti	$r9, $r3, 1
	sti	$r10, $r3, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 524
	mov	$r4, $r3
	mov	$r3, $r6
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 521
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 518
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 515
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 1
	sti	$r2, $r0, 593
	addi	$r2, $r0, 514
	fmov	$f0, $f18
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r6, $r0, 50
	addi	$r3, $r0, 1
	addi	$r4, $r0, -1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r4, $r3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 464
	mov	$r3, $r6
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r6, $r0, 1
	addi	$r3, $r0, 1
	ldi	$r4, $r0, 464
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r4, $r3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 463
	mov	$r3, $r6
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 1
	sti	$r2, $r0, 593
	addi	$r2, $r0, 462
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 1
	addi	$r4, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 461
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 1
	sti	$r2, $r0, 593
	addi	$r2, $r0, 460
	fmov	$f0, $f26
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 457
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 1
	addi	$r4, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 456
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 453
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 450
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 447
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 444
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 2
	addi	$r4, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 442
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 2
	addi	$r4, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 440
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 1
	sti	$r2, $r0, 593
	addi	$r2, $r0, 439
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 436
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 433
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 430
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 427
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 424
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 421
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 420
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r7, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 419
	subi	$r4, $r0, -420
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r4, $r3
	ldi	$r2, $r0, 593
	addi	$r6, $r0, 0
	mov	$r3, $r2
	addi	$r2, $r2, 2
	sti	$r4, $r3, 1
	sti	$r7, $r3, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 418
	mov	$r4, $r3
	mov	$r3, $r6
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 5
	sti	$r2, $r0, 593
	addi	$r2, $r0, 413
	subi	$r4, $r0, -418
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 412
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 409
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r6, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 60
	sti	$r2, $r0, 593
	addi	$r2, $r0, 349
	subi	$r4, $r0, -412
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r4, $r3
	ldi	$r2, $r0, 593
	sti	$r2, $r0, 593
	addi	$r2, $r0, 347
	mov	$r3, $r2
	addi	$r2, $r2, 2
	sti	$r4, $r3, 1
	sti	$r6, $r3, 0
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 346
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r6, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 345
	subi	$r4, $r0, -346
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	sti	$r2, $r0, 593
	addi	$r2, $r0, 343
	mov	$r4, $r2
	addi	$r2, $r2, 2
	sti	$r3, $r4, 1
	sti	$r6, $r4, 0
	ldi	$r2, $r0, 593
	addi	$r6, $r0, 180
	addi	$r5, $r0, 0
	mov	$r3, $r2
	addi	$r2, $r2, 3
	fsti	$f16, $r3, 2
	sti	$r4, $r3, 1
	sti	$r5, $r3, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 163
	mov	$r4, $r3
	mov	$r3, $r6
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 1
	addi	$r4, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 162
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 128
	addi	$r4, $r0, 128
	sti	$r3, $r0, 442
	sti	$r4, $r0, 443
	addi	$r4, $r0, 64
	sti	$r4, $r0, 440
	addi	$r4, $r0, 64
	sti	$r4, $r0, 441
	# 128.000000
	fmvhi	$f3, 17152
	fmvlo	$f3, 0
	itof	$f0, $r3
	fdiv	$f0, $f3, $f0
	fsti	$f0, $r0, 439
	ldi	$r12, $r0, 442
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 159
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r11, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 156
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 5
	sti	$r2, $r0, 593
	addi	$r2, $r0, 151
	subi	$r4, $r0, -156
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r10, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 152
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 153
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 154
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 155
	addi	$r3, $r0, 5
	addi	$r4, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 146
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r9, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 5
	addi	$r4, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 141
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r8, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 138
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 5
	sti	$r2, $r0, 593
	addi	$r2, $r0, 133
	subi	$r4, $r0, -138
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r7, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 134
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 135
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 136
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 137
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 130
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 5
	sti	$r2, $r0, 593
	addi	$r2, $r0, 125
	subi	$r4, $r0, -130
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r6, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 126
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 127
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 128
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 129
	addi	$r3, $r0, 1
	addi	$r4, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 124
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r13, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 121
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 5
	sti	$r2, $r0, 593
	addi	$r2, $r0, 116
	subi	$r4, $r0, -121
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r5, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 117
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 118
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 119
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 120
	mov	$r3, $r2
	addi	$r2, $r2, 8
	sti	$r5, $r3, 7
	sti	$r13, $r3, 6
	sti	$r6, $r3, 5
	sti	$r7, $r3, 4
	sti	$r8, $r3, 3
	sti	$r9, $r3, 2
	sti	$r10, $r3, 1
	sti	$r11, $r3, 0
	mov	$r4, $r3
	mov	$r3, $r12
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r10, $r3
	sti	$r10, $r0, 115
	ldi	$r3, $r0, 442
	subi	$r9, $r3, 2
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	init_line_elements.3016
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r15, $r3
	sti	$r15, $r0, 114
	ldi	$r12, $r0, 442
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 111
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r11, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 108
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 5
	sti	$r2, $r0, 593
	addi	$r2, $r0, 103
	subi	$r4, $r0, -108
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r10, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 104
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 105
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 106
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 107
	addi	$r3, $r0, 5
	addi	$r4, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 98
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r9, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 5
	addi	$r4, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 93
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r8, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 90
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 5
	sti	$r2, $r0, 593
	addi	$r2, $r0, 85
	subi	$r4, $r0, -90
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r7, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 86
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 87
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 88
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 89
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 82
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 5
	sti	$r2, $r0, 593
	addi	$r2, $r0, 77
	subi	$r4, $r0, -82
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r6, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 78
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 79
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 80
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 81
	addi	$r3, $r0, 1
	addi	$r4, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 76
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r13, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 73
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 5
	sti	$r2, $r0, 593
	addi	$r2, $r0, 68
	subi	$r4, $r0, -73
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r5, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 69
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 70
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 71
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 72
	mov	$r3, $r2
	addi	$r2, $r2, 8
	sti	$r5, $r3, 7
	sti	$r13, $r3, 6
	sti	$r6, $r3, 5
	sti	$r7, $r3, 4
	sti	$r8, $r3, 3
	sti	$r9, $r3, 2
	sti	$r10, $r3, 1
	sti	$r11, $r3, 0
	mov	$r4, $r3
	mov	$r3, $r12
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r10, $r3
	sti	$r10, $r0, 67
	ldi	$r3, $r0, 442
	subi	$r9, $r3, 2
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	init_line_elements.3016
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r17, $r3
	sti	$r17, $r0, 66
	ldi	$r12, $r0, 442
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 63
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r11, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 60
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 5
	sti	$r2, $r0, 593
	addi	$r2, $r0, 55
	subi	$r4, $r0, -60
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r10, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 56
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 57
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 58
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 59
	addi	$r3, $r0, 5
	addi	$r4, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 50
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r9, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 5
	addi	$r4, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 45
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r8, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 42
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 5
	sti	$r2, $r0, 593
	addi	$r2, $r0, 37
	subi	$r4, $r0, -42
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r7, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 38
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 39
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 40
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 41
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 34
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 5
	sti	$r2, $r0, 593
	addi	$r2, $r0, 29
	subi	$r4, $r0, -34
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r6, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 30
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 31
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 32
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 33
	addi	$r3, $r0, 1
	addi	$r4, $r0, 0
	sti	$r2, $r0, 593
	addi	$r2, $r0, 28
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r13, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 25
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 5
	sti	$r2, $r0, 593
	addi	$r2, $r0, 20
	subi	$r4, $r0, -25
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r5, $r3
	ldi	$r2, $r0, 593
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 21
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 22
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 23
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r0, 24
	mov	$r3, $r2
	addi	$r2, $r2, 8
	sti	$r5, $r3, 7
	sti	$r13, $r3, 6
	sti	$r6, $r3, 5
	sti	$r7, $r3, 4
	sti	$r8, $r3, 3
	sti	$r9, $r3, 2
	sti	$r10, $r3, 1
	sti	$r11, $r3, 0
	mov	$r4, $r3
	mov	$r3, $r12
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r10, $r3
	sti	$r10, $r0, 19
	ldi	$r3, $r0, 442
	subi	$r9, $r3, 2
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	init_line_elements.3016
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r18, $r3
	sti	$r18, $r0, 18
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.41560
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.41562
	addi	$r3, $r0, 0
	j	ble_cont.41563
ble_else.41562:
	addi	$r3, $r0, 1
ble_cont.41563:
	j	ble_cont.41561
ble_else.41560:
	addi	$r3, $r0, 1
ble_cont.41561:
	beq	$r3, $r0, bne_else.41564
	addi	$r6, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_float_token1.2534
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	j	bne_cont.41565
bne_else.41564:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.41566
	j	bne_cont.41567
bne_else.41566:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.41567:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_float_token1.2534
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
bne_cont.41565:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.41568
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.41569
bne_else.41568:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.41570
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.41572
	addi	$r4, $r0, 0
	j	ble_cont.41573
ble_else.41572:
	addi	$r4, $r0, 1
ble_cont.41573:
	j	ble_cont.41571
ble_else.41570:
	addi	$r4, $r0, 1
ble_cont.41571:
	beq	$r4, $r0, bne_else.41574
	addi	$r4, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_float_token2.2537
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	j	bne_cont.41575
bne_else.41574:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_float_token2.2537
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
bne_cont.41575:
	ldi	$r3, $r0, 589
	itof	$f4, $r3
	ldi	$r3, $r0, 588
	itof	$f3, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f3, $f0
	fadd	$f0, $f4, $f0
bne_cont.41569:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.41576
	fneg	$f1, $f0
	j	bne_cont.41577
bne_else.41576:
	fmov	$f1, $f0
bne_cont.41577:
	fsti	$f1, $r0, 521
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.41578
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.41580
	addi	$r3, $r0, 0
	j	ble_cont.41581
ble_else.41580:
	addi	$r3, $r0, 1
ble_cont.41581:
	j	ble_cont.41579
ble_else.41578:
	addi	$r3, $r0, 1
ble_cont.41579:
	beq	$r3, $r0, bne_else.41582
	addi	$r6, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_float_token1.2534
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	j	bne_cont.41583
bne_else.41582:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.41584
	j	bne_cont.41585
bne_else.41584:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.41585:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_float_token1.2534
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
bne_cont.41583:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.41586
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.41587
bne_else.41586:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.41588
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.41590
	addi	$r4, $r0, 0
	j	ble_cont.41591
ble_else.41590:
	addi	$r4, $r0, 1
ble_cont.41591:
	j	ble_cont.41589
ble_else.41588:
	addi	$r4, $r0, 1
ble_cont.41589:
	beq	$r4, $r0, bne_else.41592
	addi	$r4, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_float_token2.2537
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	j	bne_cont.41593
bne_else.41592:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_float_token2.2537
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
bne_cont.41593:
	ldi	$r3, $r0, 589
	itof	$f4, $r3
	ldi	$r3, $r0, 588
	itof	$f3, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f3, $f0
	fadd	$f0, $f4, $f0
bne_cont.41587:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.41594
	fneg	$f1, $f0
	j	bne_cont.41595
bne_else.41594:
	fmov	$f1, $f0
bne_cont.41595:
	fsti	$f1, $r0, 522
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.41596
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.41598
	addi	$r3, $r0, 0
	j	ble_cont.41599
ble_else.41598:
	addi	$r3, $r0, 1
ble_cont.41599:
	j	ble_cont.41597
ble_else.41596:
	addi	$r3, $r0, 1
ble_cont.41597:
	beq	$r3, $r0, bne_else.41600
	addi	$r6, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_float_token1.2534
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	j	bne_cont.41601
bne_else.41600:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.41602
	j	bne_cont.41603
bne_else.41602:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.41603:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_float_token1.2534
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
bne_cont.41601:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.41604
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.41605
bne_else.41604:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.41606
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.41608
	addi	$r4, $r0, 0
	j	ble_cont.41609
ble_else.41608:
	addi	$r4, $r0, 1
ble_cont.41609:
	j	ble_cont.41607
ble_else.41606:
	addi	$r4, $r0, 1
ble_cont.41607:
	beq	$r4, $r0, bne_else.41610
	addi	$r4, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_float_token2.2537
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	j	bne_cont.41611
bne_else.41610:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_float_token2.2537
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
bne_cont.41611:
	ldi	$r3, $r0, 589
	itof	$f4, $r3
	ldi	$r3, $r0, 588
	itof	$f3, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f3, $f0
	fadd	$f0, $f4, $f0
bne_cont.41605:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.41612
	fneg	$f1, $f0
	j	bne_cont.41613
bne_else.41612:
	fmov	$f1, $f0
bne_cont.41613:
	fsti	$f1, $r0, 523
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.41614
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.41616
	addi	$r3, $r0, 0
	j	ble_cont.41617
ble_else.41616:
	addi	$r3, $r0, 1
ble_cont.41617:
	j	ble_cont.41615
ble_else.41614:
	addi	$r3, $r0, 1
ble_cont.41615:
	beq	$r3, $r0, bne_else.41618
	addi	$r6, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_float_token1.2534
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	j	bne_cont.41619
bne_else.41618:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.41620
	j	bne_cont.41621
bne_else.41620:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.41621:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_float_token1.2534
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
bne_cont.41619:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.41622
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.41623
bne_else.41622:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.41624
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.41626
	addi	$r4, $r0, 0
	j	ble_cont.41627
ble_else.41626:
	addi	$r4, $r0, 1
ble_cont.41627:
	j	ble_cont.41625
ble_else.41624:
	addi	$r4, $r0, 1
ble_cont.41625:
	beq	$r4, $r0, bne_else.41628
	addi	$r4, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_float_token2.2537
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	j	bne_cont.41629
bne_else.41628:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_float_token2.2537
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
bne_cont.41629:
	ldi	$r3, $r0, 589
	itof	$f4, $r3
	ldi	$r3, $r0, 588
	itof	$f3, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f3, $f0
	fadd	$f0, $f4, $f0
bne_cont.41623:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.41630
	fneg	$f1, $f0
	j	bne_cont.41631
bne_else.41630:
	fmov	$f1, $f0
bne_cont.41631:
	# 0.017453
	fmvhi	$f5, 15502
	fmvlo	$f5, 64045
	fmul	$f0, $f1, $f5
	sti	$r15, $r1, 0
	sti	$r18, $r1, -1
	sti	$r17, $r1, -2
	fsti	$f10, $r1, -3
	fsti	$f5, $r1, -4
	fsti	$f0, $r1, -5
	fcos	$f3, $f0
	fldi	$f0, $r1, -5
	fsti	$f3, $r1, -6
	fsin	$f4, $f0
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.41632
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.41634
	addi	$r3, $r0, 0
	j	ble_cont.41635
ble_else.41634:
	addi	$r3, $r0, 1
ble_cont.41635:
	j	ble_cont.41633
ble_else.41632:
	addi	$r3, $r0, 1
ble_cont.41633:
	beq	$r3, $r0, bne_else.41636
	addi	$r6, $r0, 0
	sti	$r29, $r1, -8
	subi	$r1, $r1, 9
	jal	read_float_token1.2534
	addi	$r1, $r1, 9
	ldi	$r29, $r1, -8
	j	bne_cont.41637
bne_else.41636:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.41638
	j	bne_cont.41639
bne_else.41638:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.41639:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -8
	subi	$r1, $r1, 9
	jal	read_float_token1.2534
	addi	$r1, $r1, 9
	ldi	$r29, $r1, -8
bne_cont.41637:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.41640
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.41641
bne_else.41640:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.41642
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.41644
	addi	$r4, $r0, 0
	j	ble_cont.41645
ble_else.41644:
	addi	$r4, $r0, 1
ble_cont.41645:
	j	ble_cont.41643
ble_else.41642:
	addi	$r4, $r0, 1
ble_cont.41643:
	beq	$r4, $r0, bne_else.41646
	addi	$r4, $r0, 0
	sti	$r29, $r1, -8
	subi	$r1, $r1, 9
	jal	read_float_token2.2537
	addi	$r1, $r1, 9
	ldi	$r29, $r1, -8
	j	bne_cont.41647
bne_else.41646:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -8
	subi	$r1, $r1, 9
	jal	read_float_token2.2537
	addi	$r1, $r1, 9
	ldi	$r29, $r1, -8
bne_cont.41647:
	ldi	$r3, $r0, 589
	itof	$f7, $r3
	ldi	$r3, $r0, 588
	itof	$f6, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f6, $f0
	fadd	$f0, $f7, $f0
bne_cont.41641:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.41648
	fneg	$f1, $f0
	j	bne_cont.41649
bne_else.41648:
	fmov	$f1, $f0
bne_cont.41649:
	fldi	$f5, $r1, -4
	fmul	$f0, $f1, $f5
	fsti	$f4, $r1, -7
	fsti	$f0, $r1, -8
	fcos	$f2, $f0
	fldi	$f0, $r1, -8
	fsti	$f2, $r1, -9
	fsin	$f0, $f0
	fldi	$f3, $r1, -6
	fmul	$f6, $f3, $f0
	# 200.000000
	fmvhi	$f1, 17224
	fmvlo	$f1, 0
	fmul	$f6, $f6, $f1
	fsti	$f6, $r0, 424
	# -200.000000
	fmvhi	$f6, 49992
	fmvlo	$f6, 0
	fldi	$f4, $r1, -7
	fmul	$f6, $f4, $f6
	fsti	$f6, $r0, 425
	fldi	$f2, $r1, -9
	fmul	$f6, $f3, $f2
	fmul	$f1, $f6, $f1
	fsti	$f1, $r0, 426
	fsti	$f2, $r0, 430
	fsti	$f16, $r0, 431
	fneg	$f1, $f0
	fsti	$f1, $r0, 432
	fneg	$f4, $f4
	fmul	$f0, $f4, $f0
	fsti	$f0, $r0, 427
	fneg	$f3, $f3
	fsti	$f3, $r0, 428
	fmul	$f0, $f4, $f2
	fsti	$f0, $r0, 429
	fldi	$f1, $r0, 521
	fldi	$f0, $r0, 424
	fsub	$f0, $f1, $f0
	fsti	$f0, $r0, 518
	fldi	$f1, $r0, 522
	fldi	$f0, $r0, 425
	fsub	$f0, $f1, $f0
	fsti	$f0, $r0, 519
	fldi	$f1, $r0, 523
	fldi	$f0, $r0, 426
	fsub	$f0, $f1, $f0
	fsti	$f0, $r0, 520
	addi	$r3, $r0, 0
	sti	$r3, $r0, 591
	addi	$r3, $r0, 0
	sti	$r3, $r0, 590
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.41650
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.41652
	addi	$r3, $r0, 0
	j	ble_cont.41653
ble_else.41652:
	addi	$r3, $r0, 1
ble_cont.41653:
	j	ble_cont.41651
ble_else.41650:
	addi	$r3, $r0, 1
ble_cont.41651:
	beq	$r3, $r0, bne_else.41654
	addi	$r6, $r0, 0
	sti	$r29, $r1, -11
	subi	$r1, $r1, 12
	jal	read_int_token.2525
	addi	$r1, $r1, 12
	ldi	$r29, $r1, -11
	j	bne_cont.41655
bne_else.41654:
	ldi	$r3, $r0, 590
	beq	$r3, $r0, bne_else.41656
	j	bne_cont.41657
bne_else.41656:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 590
bne_cont.41657:
	ldi	$r3, $r0, 591
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 591
	addi	$r6, $r0, 1
	sti	$r29, $r1, -11
	subi	$r1, $r1, 12
	jal	read_int_token.2525
	addi	$r1, $r1, 12
	ldi	$r29, $r1, -11
bne_cont.41655:
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.41658
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.41660
	addi	$r3, $r0, 0
	j	ble_cont.41661
ble_else.41660:
	addi	$r3, $r0, 1
ble_cont.41661:
	j	ble_cont.41659
ble_else.41658:
	addi	$r3, $r0, 1
ble_cont.41659:
	beq	$r3, $r0, bne_else.41662
	addi	$r6, $r0, 0
	sti	$r29, $r1, -11
	subi	$r1, $r1, 12
	jal	read_float_token1.2534
	addi	$r1, $r1, 12
	ldi	$r29, $r1, -11
	j	bne_cont.41663
bne_else.41662:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.41664
	j	bne_cont.41665
bne_else.41664:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.41665:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -11
	subi	$r1, $r1, 12
	jal	read_float_token1.2534
	addi	$r1, $r1, 12
	ldi	$r29, $r1, -11
bne_cont.41663:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.41666
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.41667
bne_else.41666:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.41668
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.41670
	addi	$r4, $r0, 0
	j	ble_cont.41671
ble_else.41670:
	addi	$r4, $r0, 1
ble_cont.41671:
	j	ble_cont.41669
ble_else.41668:
	addi	$r4, $r0, 1
ble_cont.41669:
	beq	$r4, $r0, bne_else.41672
	addi	$r4, $r0, 0
	sti	$r29, $r1, -11
	subi	$r1, $r1, 12
	jal	read_float_token2.2537
	addi	$r1, $r1, 12
	ldi	$r29, $r1, -11
	j	bne_cont.41673
bne_else.41672:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -11
	subi	$r1, $r1, 12
	jal	read_float_token2.2537
	addi	$r1, $r1, 12
	ldi	$r29, $r1, -11
bne_cont.41673:
	ldi	$r3, $r0, 589
	itof	$f4, $r3
	ldi	$r3, $r0, 588
	itof	$f3, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f3, $f0
	fadd	$f0, $f4, $f0
bne_cont.41667:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.41674
	fneg	$f1, $f0
	j	bne_cont.41675
bne_else.41674:
	fmov	$f1, $f0
bne_cont.41675:
	fldi	$f5, $r1, -4
	fmul	$f0, $f1, $f5
	fsti	$f0, $r1, -10
	fsin	$f1, $f0
	fneg	$f1, $f1
	fsti	$f1, $r0, 516
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.41676
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.41678
	addi	$r3, $r0, 0
	j	ble_cont.41679
ble_else.41678:
	addi	$r3, $r0, 1
ble_cont.41679:
	j	ble_cont.41677
ble_else.41676:
	addi	$r3, $r0, 1
ble_cont.41677:
	beq	$r3, $r0, bne_else.41680
	addi	$r6, $r0, 0
	sti	$r29, $r1, -12
	subi	$r1, $r1, 13
	jal	read_float_token1.2534
	addi	$r1, $r1, 13
	ldi	$r29, $r1, -12
	j	bne_cont.41681
bne_else.41680:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.41682
	j	bne_cont.41683
bne_else.41682:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.41683:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -12
	subi	$r1, $r1, 13
	jal	read_float_token1.2534
	addi	$r1, $r1, 13
	ldi	$r29, $r1, -12
bne_cont.41681:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.41684
	ldi	$r3, $r0, 589
	itof	$f1, $r3
	j	bne_cont.41685
bne_else.41684:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.41686
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.41688
	addi	$r4, $r0, 0
	j	ble_cont.41689
ble_else.41688:
	addi	$r4, $r0, 1
ble_cont.41689:
	j	ble_cont.41687
ble_else.41686:
	addi	$r4, $r0, 1
ble_cont.41687:
	beq	$r4, $r0, bne_else.41690
	addi	$r4, $r0, 0
	sti	$r29, $r1, -12
	subi	$r1, $r1, 13
	jal	read_float_token2.2537
	addi	$r1, $r1, 13
	ldi	$r29, $r1, -12
	j	bne_cont.41691
bne_else.41690:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -12
	subi	$r1, $r1, 13
	jal	read_float_token2.2537
	addi	$r1, $r1, 13
	ldi	$r29, $r1, -12
bne_cont.41691:
	ldi	$r3, $r0, 589
	itof	$f4, $r3
	ldi	$r3, $r0, 588
	itof	$f3, $r3
	ldi	$r3, $r0, 587
	itof	$f1, $r3
	fdiv	$f1, $f3, $f1
	fadd	$f1, $f4, $f1
bne_cont.41685:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.41692
	fneg	$f2, $f1
	j	bne_cont.41693
bne_else.41692:
	fmov	$f2, $f1
bne_cont.41693:
	fldi	$f5, $r1, -4
	fmul	$f1, $f2, $f5
	fldi	$f0, $r1, -10
	fsti	$f1, $r1, -11
	fcos	$f2, $f0
	fldi	$f1, $r1, -11
	fsti	$f2, $r1, -12
	fsin	$f0, $f1
	fldi	$f2, $r1, -12
	fmul	$f0, $f2, $f0
	fsti	$f0, $r0, 515
	fldi	$f1, $r1, -11
	fcos	$f0, $f1
	fldi	$f2, $r1, -12
	fmul	$f0, $f2, $f0
	fsti	$f0, $r0, 517
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.41694
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.41696
	addi	$r3, $r0, 0
	j	ble_cont.41697
ble_else.41696:
	addi	$r3, $r0, 1
ble_cont.41697:
	j	ble_cont.41695
ble_else.41694:
	addi	$r3, $r0, 1
ble_cont.41695:
	beq	$r3, $r0, bne_else.41698
	addi	$r6, $r0, 0
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	read_float_token1.2534
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	j	bne_cont.41699
bne_else.41698:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.41700
	j	bne_cont.41701
bne_else.41700:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.41701:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	read_float_token1.2534
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
bne_cont.41699:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.41702
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.41703
bne_else.41702:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.41704
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.41706
	addi	$r4, $r0, 0
	j	ble_cont.41707
ble_else.41706:
	addi	$r4, $r0, 1
ble_cont.41707:
	j	ble_cont.41705
ble_else.41704:
	addi	$r4, $r0, 1
ble_cont.41705:
	beq	$r4, $r0, bne_else.41708
	addi	$r4, $r0, 0
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	read_float_token2.2537
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	j	bne_cont.41709
bne_else.41708:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	read_float_token2.2537
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
bne_cont.41709:
	ldi	$r3, $r0, 589
	itof	$f4, $r3
	ldi	$r3, $r0, 588
	itof	$f3, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f3, $f0
	fadd	$f0, $f4, $f0
bne_cont.41703:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.41710
	fneg	$f1, $f0
	j	bne_cont.41711
bne_else.41710:
	fmov	$f1, $f0
bne_cont.41711:
	fsti	$f1, $r0, 514
	addi	$r16, $r0, 0
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	read_object.2727
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	addi	$r3, $r0, 0
	sti	$r3, $r0, 591
	addi	$r3, $r0, 0
	sti	$r3, $r0, 590
	inputb	$r5
	addi	$r10, $r0, 48
	blt	$r5, $r10, ble_else.41712
	addi	$r10, $r0, 57
	blt	$r10, $r5, ble_else.41714
	addi	$r10, $r0, 0
	j	ble_cont.41715
ble_else.41714:
	addi	$r10, $r0, 1
ble_cont.41715:
	j	ble_cont.41713
ble_else.41712:
	addi	$r10, $r0, 1
ble_cont.41713:
	beq	$r10, $r0, bne_else.41716
	addi	$r6, $r0, 0
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	read_int_token.2525
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	mov	$r10, $r3
	j	bne_cont.41717
bne_else.41716:
	ldi	$r3, $r0, 590
	beq	$r3, $r0, bne_else.41718
	j	bne_cont.41719
bne_else.41718:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 590
bne_cont.41719:
	ldi	$r3, $r0, 591
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 591
	addi	$r6, $r0, 1
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	read_int_token.2525
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	mov	$r10, $r3
bne_cont.41717:
	beq	$r10, $r31, bne_else.41720
	addi	$r8, $r0, 1
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	read_net_item.2731
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	sti	$r10, $r3, 0
	j	bne_cont.41721
bne_else.41720:
	addi	$r3, $r0, 1
	addi	$r4, $r0, -1
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	min_caml_create_array
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
bne_cont.41721:
	sti	$r3, $r0, 17
	ldi	$r4, $r3, 0
	beq	$r4, $r31, bne_else.41722
	sti	$r3, $r0, 464
	addi	$r11, $r0, 1
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	read_and_network.2735
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	j	bne_cont.41723
bne_else.41722:
bne_cont.41723:
	addi	$r3, $r0, 0
	sti	$r3, $r0, 591
	addi	$r3, $r0, 0
	sti	$r3, $r0, 590
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.41724
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.41726
	addi	$r3, $r0, 0
	j	ble_cont.41727
ble_else.41726:
	addi	$r3, $r0, 1
ble_cont.41727:
	j	ble_cont.41725
ble_else.41724:
	addi	$r3, $r0, 1
ble_cont.41725:
	beq	$r3, $r0, bne_else.41728
	addi	$r6, $r0, 0
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	read_int_token.2525
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	j	bne_cont.41729
bne_else.41728:
	ldi	$r3, $r0, 590
	beq	$r3, $r0, bne_else.41730
	j	bne_cont.41731
bne_else.41730:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 590
bne_cont.41731:
	ldi	$r3, $r0, 591
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 591
	addi	$r6, $r0, 1
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	read_int_token.2525
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
bne_cont.41729:
	beq	$r3, $r31, bne_else.41732
	addi	$r8, $r0, 1
	sti	$r3, $r1, -13
	sti	$r29, $r1, -15
	subi	$r1, $r1, 16
	jal	read_net_item.2731
	addi	$r1, $r1, 16
	ldi	$r29, $r1, -15
	mov	$r4, $r3
	ldi	$r3, $r1, -13
	sti	$r3, $r4, 0
	j	bne_cont.41733
bne_else.41732:
	addi	$r3, $r0, 1
	addi	$r4, $r0, -1
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	min_caml_create_array
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	mov	$r4, $r3
bne_cont.41733:
	sti	$r4, $r0, 16
	ldi	$r3, $r4, 0
	beq	$r3, $r31, bne_else.41734
	addi	$r11, $r0, 1
	sti	$r4, $r1, -13
	sti	$r29, $r1, -15
	subi	$r1, $r1, 16
	jal	read_or_network.2733
	addi	$r1, $r1, 16
	ldi	$r29, $r1, -15
	ldi	$r4, $r1, -13
	sti	$r4, $r3, 0
	j	bne_cont.41735
bne_else.41734:
	addi	$r3, $r0, 1
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	min_caml_create_array
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
bne_cont.41735:
	sti	$r3, $r0, 463
	addi	$r3, $r0, 80
	outputb	$r3
	addi	$r3, $r0, 51
	outputb	$r3
	addi	$r3, $r0, 10
	outputb	$r3
	ldi	$r4, $r0, 442
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	print_int.2559
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	addi	$r3, $r0, 32
	outputb	$r3
	ldi	$r4, $r0, 443
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	print_int.2559
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	addi	$r3, $r0, 32
	outputb	$r3
	addi	$r4, $r0, 255
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	print_int.2559
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	addi	$r3, $r0, 10
	outputb	$r3
	addi	$r6, $r0, 120
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 13
	fmov	$f0, $f16
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	min_caml_create_float_array
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	mov	$r7, $r3
	ldi	$r2, $r0, 593
	ldi	$r3, $r0, 585
	subi	$r4, $r0, -13
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	min_caml_create_array
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	mov	$r4, $r3
	sti	$r4, $r0, 12
	mov	$r3, $r2
	addi	$r2, $r2, 2
	sti	$r4, $r3, 1
	sti	$r7, $r3, 0
	mov	$r4, $r3
	mov	$r3, $r6
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	min_caml_create_array
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	sti	$r3, $r0, 417
	ldi	$r6, $r0, 417
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 9
	fmov	$f0, $f16
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	min_caml_create_float_array
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	mov	$r7, $r3
	ldi	$r2, $r0, 593
	ldi	$r3, $r0, 585
	subi	$r4, $r0, -9
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	min_caml_create_array
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	mov	$r4, $r3
	sti	$r4, $r0, 8
	mov	$r3, $r2
	addi	$r2, $r2, 2
	sti	$r4, $r3, 1
	sti	$r7, $r3, 0
	sti	$r3, $r6, 118
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 5
	fmov	$f0, $f16
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	min_caml_create_float_array
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	mov	$r7, $r3
	ldi	$r2, $r0, 593
	ldi	$r3, $r0, 585
	subi	$r4, $r0, -5
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	min_caml_create_array
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	mov	$r4, $r3
	sti	$r4, $r0, 4
	mov	$r3, $r2
	addi	$r2, $r2, 2
	sti	$r4, $r3, 1
	sti	$r7, $r3, 0
	sti	$r3, $r6, 117
	addi	$r3, $r0, 3
	sti	$r2, $r0, 593
	addi	$r2, $r0, 1
	fmov	$f0, $f16
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	min_caml_create_float_array
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	mov	$r7, $r3
	ldi	$r2, $r0, 593
	ldi	$r3, $r0, 585
	subi	$r4, $r0, -1
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	min_caml_create_array
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	mov	$r4, $r3
	sti	$r4, $r0, 0
	mov	$r3, $r2
	addi	$r2, $r2, 2
	sti	$r4, $r3, 1
	sti	$r7, $r3, 0
	sti	$r3, $r6, 116
	addi	$r7, $r0, 115
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	create_dirvec_elements.3043
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	addi	$r8, $r0, 3
	sti	$r29, $r1, -14
	subi	$r1, $r1, 15
	jal	create_dirvecs.3046
	addi	$r1, $r1, 15
	ldi	$r29, $r1, -14
	addi	$r3, $r0, 9
	addi	$r5, $r0, 0
	addi	$r7, $r0, 0
	sti	$r5, $r1, -13
	itof	$f0, $r3
	fmul	$f0, $f0, $f30
	fsub	$f1, $f0, $f29
	addi	$r3, $r0, 4
	fsti	$f1, $r1, -14
	itof	$f0, $r3
	fmul	$f0, $f0, $f30
	fsub	$f2, $f0, $f29
	addi	$r3, $r0, 0
	fldi	$f1, $r1, -14
	ldi	$r5, $r1, -13
	sti	$r7, $r1, -15
	fsti	$f0, $r1, -16
	mov	$r4, $r7
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -18
	subi	$r1, $r1, 19
	jal	calc_dirvec.3024
	addi	$r1, $r1, 19
	ldi	$r29, $r1, -18
	fldi	$f0, $r1, -16
	fadd	$f2, $f0, $f25
	addi	$r3, $r0, 0
	addi	$r4, $r0, 2
	fldi	$f1, $r1, -14
	ldi	$r5, $r1, -13
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -18
	subi	$r1, $r1, 19
	jal	calc_dirvec.3024
	addi	$r1, $r1, 19
	ldi	$r29, $r1, -18
	addi	$r3, $r0, 3
	addi	$r5, $r0, 1
	sti	$r5, $r1, -17
	itof	$f0, $r3
	fmul	$f0, $f0, $f30
	fsub	$f2, $f0, $f29
	addi	$r3, $r0, 0
	fldi	$f1, $r1, -14
	ldi	$r5, $r1, -17
	ldi	$r7, $r1, -15
	fsti	$f0, $r1, -18
	mov	$r4, $r7
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -20
	subi	$r1, $r1, 21
	jal	calc_dirvec.3024
	addi	$r1, $r1, 21
	ldi	$r29, $r1, -20
	fldi	$f0, $r1, -18
	fadd	$f2, $f0, $f25
	addi	$r3, $r0, 0
	addi	$r4, $r0, 2
	fldi	$f1, $r1, -14
	ldi	$r5, $r1, -17
	sti	$r4, $r1, -19
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -21
	subi	$r1, $r1, 22
	jal	calc_dirvec.3024
	addi	$r1, $r1, 22
	ldi	$r29, $r1, -21
	addi	$r3, $r0, 2
	addi	$r5, $r0, 2
	sti	$r5, $r1, -20
	itof	$f0, $r3
	fmul	$f0, $f0, $f30
	fsub	$f2, $f0, $f29
	addi	$r3, $r0, 0
	fldi	$f1, $r1, -14
	ldi	$r5, $r1, -20
	ldi	$r7, $r1, -15
	fsti	$f0, $r1, -21
	mov	$r4, $r7
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -23
	subi	$r1, $r1, 24
	jal	calc_dirvec.3024
	addi	$r1, $r1, 24
	ldi	$r29, $r1, -23
	fldi	$f0, $r1, -21
	fadd	$f2, $f0, $f25
	addi	$r3, $r0, 0
	fldi	$f1, $r1, -14
	ldi	$r5, $r1, -20
	ldi	$r4, $r1, -19
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -23
	subi	$r1, $r1, 24
	jal	calc_dirvec.3024
	addi	$r1, $r1, 24
	ldi	$r29, $r1, -23
	addi	$r6, $r0, 1
	addi	$r5, $r0, 3
	fldi	$f1, $r1, -14
	ldi	$r7, $r1, -15
	mov	$r4, $r7
	sti	$r29, $r1, -23
	subi	$r1, $r1, 24
	jal	calc_dirvecs.3032
	addi	$r1, $r1, 24
	ldi	$r29, $r1, -23
	addi	$r7, $r0, 8
	addi	$r6, $r0, 2
	addi	$r4, $r0, 4
	sti	$r29, $r1, -23
	subi	$r1, $r1, 24
	jal	calc_dirvec_rows.3037
	addi	$r1, $r1, 24
	ldi	$r29, $r1, -23
	ldi	$r12, $r0, 417
	ldi	$r8, $r12, 119
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -23
	subi	$r1, $r1, 24
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 24
	ldi	$r29, $r1, -23
	ldi	$r8, $r12, 118
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -23
	subi	$r1, $r1, 24
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 24
	ldi	$r29, $r1, -23
	ldi	$r8, $r12, 117
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -23
	subi	$r1, $r1, 24
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 24
	ldi	$r29, $r1, -23
	ldi	$r8, $r12, 116
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -23
	subi	$r1, $r1, 24
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 24
	ldi	$r29, $r1, -23
	ldi	$r8, $r12, 115
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -23
	subi	$r1, $r1, 24
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 24
	ldi	$r29, $r1, -23
	ldi	$r8, $r12, 114
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -23
	subi	$r1, $r1, 24
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 24
	ldi	$r29, $r1, -23
	ldi	$r8, $r12, 113
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -23
	subi	$r1, $r1, 24
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 24
	ldi	$r29, $r1, -23
	addi	$r13, $r0, 112
	sti	$r29, $r1, -23
	subi	$r1, $r1, 24
	jal	init_dirvec_constants.3048
	addi	$r1, $r1, 24
	ldi	$r29, $r1, -23
	addi	$r14, $r0, 3
	sti	$r29, $r1, -23
	subi	$r1, $r1, 24
	jal	init_vecset_constants.3051
	addi	$r1, $r1, 24
	ldi	$r29, $r1, -23
	fldi	$f0, $r0, 515
	fsti	$f0, $r0, 409
	fldi	$f0, $r0, 516
	fsti	$f0, $r0, 410
	fldi	$f0, $r0, 517
	fsti	$f0, $r0, 411
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	subi	$r8, $r0, -347
	sti	$r29, $r1, -23
	subi	$r1, $r1, 24
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 24
	ldi	$r29, $r1, -23
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	blt	$r6, $r0, bge_else.41736
	slli	$r3, $r6, 0
	ldi	$r3, $r3, 524
	ldi	$r4, $r3, 2
	addi	$r5, $r0, 2
	beq	$r4, $r5, bne_else.41738
	j	bne_cont.41739
bne_else.41738:
	ldi	$r4, $r3, 7
	fldi	$f0, $r4, 0
	fblt	$f0, $f17, fbge_else.41740
	j	fbge_cont.41741
fbge_else.41740:
	ldi	$r5, $r3, 1
	beq	$r5, $r30, bne_else.41742
	addi	$r4, $r0, 2
	beq	$r5, $r4, bne_else.41744
	j	bne_cont.41745
bne_else.41744:
	slli	$r4, $r6, 2
	addi	$r12, $r4, 1
	ldi	$r13, $r0, 162
	fsub	$f9, $f17, $f0
	ldi	$r3, $r3, 4
	fldi	$f6, $r0, 515
	fldi	$f7, $r3, 0
	fmul	$f2, $f6, $f7
	fldi	$f3, $r0, 516
	fldi	$f1, $r3, 1
	fmul	$f0, $f3, $f1
	fadd	$f5, $f2, $f0
	fldi	$f4, $r0, 517
	fldi	$f2, $r3, 2
	fmul	$f0, $f4, $f2
	fadd	$f0, $f5, $f0
	fldi	$f10, $r1, -3
	fmul	$f5, $f10, $f7
	fmul	$f5, $f5, $f0
	fsub	$f5, $f5, $f6
	fmul	$f1, $f10, $f1
	fmul	$f1, $f1, $f0
	fsub	$f3, $f1, $f3
	fmul	$f1, $f10, $f2
	fmul	$f0, $f1, $f0
	fsub	$f1, $f0, $f4
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -23
	subi	$r1, $r1, 24
	jal	min_caml_create_float_array
	addi	$r1, $r1, 24
	ldi	$r29, $r1, -23
	mov	$r6, $r3
	ldi	$r3, $r0, 585
	mov	$r4, $r6
	sti	$r29, $r1, -23
	subi	$r1, $r1, 24
	jal	min_caml_create_array
	addi	$r1, $r1, 24
	ldi	$r29, $r1, -23
	mov	$r4, $r2
	addi	$r2, $r2, 2
	sti	$r3, $r4, 1
	sti	$r6, $r4, 0
	fsti	$f5, $r6, 0
	fsti	$f3, $r6, 1
	fsti	$f1, $r6, 2
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r4, $r1, -22
	mov	$r8, $r4
	sti	$r29, $r1, -24
	subi	$r1, $r1, 25
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 25
	ldi	$r29, $r1, -24
	mov	$r3, $r2
	addi	$r2, $r2, 3
	fsti	$f9, $r3, 2
	ldi	$r4, $r1, -22
	sti	$r4, $r3, 1
	sti	$r12, $r3, 0
	slli	$r4, $r13, 0
	sti	$r3, $r4, 163
	addi	$r3, $r13, 1
	sti	$r3, $r0, 162
bne_cont.41745:
	j	bne_cont.41743
bne_else.41742:
	slli	$r12, $r6, 2
	ldi	$r13, $r0, 162
	fldi	$f0, $r4, 0
	fsub	$f12, $f17, $f0
	fldi	$f1, $r0, 515
	fneg	$f11, $f1
	fldi	$f10, $r0, 516
	fneg	$f10, $f10
	fldi	$f9, $r0, 517
	fneg	$f9, $f9
	addi	$r14, $r12, 1
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -23
	subi	$r1, $r1, 24
	jal	min_caml_create_float_array
	addi	$r1, $r1, 24
	ldi	$r29, $r1, -23
	mov	$r6, $r3
	ldi	$r3, $r0, 585
	mov	$r4, $r6
	sti	$r29, $r1, -23
	subi	$r1, $r1, 24
	jal	min_caml_create_array
	addi	$r1, $r1, 24
	ldi	$r29, $r1, -23
	mov	$r4, $r2
	addi	$r2, $r2, 2
	sti	$r3, $r4, 1
	sti	$r6, $r4, 0
	fsti	$f1, $r6, 0
	fsti	$f10, $r6, 1
	fsti	$f9, $r6, 2
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r4, $r1, -22
	mov	$r8, $r4
	sti	$r29, $r1, -24
	subi	$r1, $r1, 25
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 25
	ldi	$r29, $r1, -24
	mov	$r3, $r2
	addi	$r2, $r2, 3
	fsti	$f12, $r3, 2
	ldi	$r4, $r1, -22
	sti	$r4, $r3, 1
	sti	$r14, $r3, 0
	slli	$r4, $r13, 0
	sti	$r3, $r4, 163
	addi	$r16, $r13, 1
	addi	$r14, $r12, 2
	fldi	$f1, $r0, 516
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -24
	subi	$r1, $r1, 25
	jal	min_caml_create_float_array
	addi	$r1, $r1, 25
	ldi	$r29, $r1, -24
	mov	$r6, $r3
	ldi	$r3, $r0, 585
	mov	$r4, $r6
	sti	$r29, $r1, -24
	subi	$r1, $r1, 25
	jal	min_caml_create_array
	addi	$r1, $r1, 25
	ldi	$r29, $r1, -24
	mov	$r4, $r2
	addi	$r2, $r2, 2
	sti	$r3, $r4, 1
	sti	$r6, $r4, 0
	fsti	$f11, $r6, 0
	fsti	$f1, $r6, 1
	fsti	$f9, $r6, 2
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r4, $r1, -23
	mov	$r8, $r4
	sti	$r29, $r1, -25
	subi	$r1, $r1, 26
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 26
	ldi	$r29, $r1, -25
	mov	$r3, $r2
	addi	$r2, $r2, 3
	fsti	$f12, $r3, 2
	ldi	$r4, $r1, -23
	sti	$r4, $r3, 1
	sti	$r14, $r3, 0
	slli	$r4, $r16, 0
	sti	$r3, $r4, 163
	addi	$r14, $r13, 2
	addi	$r12, $r12, 3
	fldi	$f1, $r0, 517
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -25
	subi	$r1, $r1, 26
	jal	min_caml_create_float_array
	addi	$r1, $r1, 26
	ldi	$r29, $r1, -25
	mov	$r6, $r3
	ldi	$r3, $r0, 585
	mov	$r4, $r6
	sti	$r29, $r1, -25
	subi	$r1, $r1, 26
	jal	min_caml_create_array
	addi	$r1, $r1, 26
	ldi	$r29, $r1, -25
	mov	$r4, $r2
	addi	$r2, $r2, 2
	sti	$r3, $r4, 1
	sti	$r6, $r4, 0
	fsti	$f11, $r6, 0
	fsti	$f10, $r6, 1
	fsti	$f1, $r6, 2
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r4, $r1, -24
	mov	$r8, $r4
	sti	$r29, $r1, -26
	subi	$r1, $r1, 27
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 27
	ldi	$r29, $r1, -26
	mov	$r3, $r2
	addi	$r2, $r2, 3
	fsti	$f12, $r3, 2
	ldi	$r4, $r1, -24
	sti	$r4, $r3, 1
	sti	$r12, $r3, 0
	slli	$r4, $r14, 0
	sti	$r3, $r4, 163
	addi	$r3, $r13, 3
	sti	$r3, $r0, 162
bne_cont.41743:
fbge_cont.41741:
bne_cont.41739:
	j	bge_cont.41737
bge_else.41736:
bge_cont.41737:
	addi	$r7, $r0, 0
	fldi	$f3, $r0, 439
	ldi	$r3, $r0, 441
	sub	$r3, $r0, $r3
	itof	$f0, $r3
	fmul	$f0, $f3, $f0
	fldi	$f1, $r0, 427
	fmul	$f2, $f0, $f1
	fldi	$f1, $r0, 424
	fadd	$f5, $f2, $f1
	fldi	$f1, $r0, 428
	fmul	$f2, $f0, $f1
	fldi	$f1, $r0, 425
	fadd	$f4, $f2, $f1
	fldi	$f1, $r0, 429
	fmul	$f1, $f0, $f1
	fldi	$f0, $r0, 426
	fadd	$f3, $f1, $f0
	ldi	$r3, $r0, 442
	subi	$r6, $r3, 1
	ldi	$r17, $r1, -2
	mov	$r3, $r7
	mov	$r7, $r17
	sti	$r29, $r1, -23
	subi	$r1, $r1, 24
	jal	pretrace_pixels.2989
	addi	$r1, $r1, 24
	ldi	$r29, $r1, -23
	addi	$r16, $r0, 0
	addi	$r7, $r0, 2
	ldi	$r3, $r0, 443
	blt	$r16, $r3, ble_else.41746
	j	ble_cont.41747
ble_else.41746:
	subi	$r3, $r3, 1
	sti	$r16, $r1, -22
	blt	$r16, $r3, ble_else.41748
	j	ble_cont.41749
ble_else.41748:
	addi	$r4, $r0, 1
	fldi	$f3, $r0, 439
	ldi	$r3, $r0, 441
	sub	$r3, $r4, $r3
	itof	$f0, $r3
	fmul	$f0, $f3, $f0
	fldi	$f1, $r0, 427
	fmul	$f2, $f0, $f1
	fldi	$f1, $r0, 424
	fadd	$f5, $f2, $f1
	fldi	$f1, $r0, 428
	fmul	$f2, $f0, $f1
	fldi	$f1, $r0, 425
	fadd	$f4, $f2, $f1
	fldi	$f1, $r0, 429
	fmul	$f1, $f0, $f1
	fldi	$f0, $r0, 426
	fadd	$f3, $f1, $f0
	ldi	$r3, $r0, 442
	subi	$r6, $r3, 1
	ldi	$r18, $r1, -1
	mov	$r3, $r7
	mov	$r7, $r18
	sti	$r29, $r1, -24
	subi	$r1, $r1, 25
	jal	pretrace_pixels.2989
	addi	$r1, $r1, 25
	ldi	$r29, $r1, -24
ble_cont.41749:
	addi	$r3, $r0, 0
	ldi	$r16, $r1, -22
	ldi	$r15, $r1, 0
	ldi	$r17, $r1, -2
	ldi	$r18, $r1, -1
	mov	$r19, $r18
	mov	$r18, $r15
	mov	$r15, $r3
	sti	$r29, $r1, -24
	subi	$r1, $r1, 25
	jal	scan_pixel.3000
	addi	$r1, $r1, 25
	ldi	$r29, $r1, -24
	addi	$r16, $r0, 1
	addi	$r3, $r0, 4
	ldi	$r17, $r1, -2
	ldi	$r18, $r1, -1
	ldi	$r15, $r1, 0
	mov	$r7, $r17
	mov	$r17, $r15
	sti	$r29, $r1, -24
	subi	$r1, $r1, 25
	jal	scan_line.3006
	addi	$r1, $r1, 25
	ldi	$r29, $r1, -24
ble_cont.41747:
	addi	$r0, $r0, 0
	halt

#---------------------------------------------------------------------
# args = [$r6, $r5]
# fargs = []
# ret type = Int
#---------------------------------------------------------------------
read_int_token.2525:
	inputb	$r4
	addi	$r3, $r0, 48
	blt	$r4, $r3, ble_else.41750
	addi	$r3, $r0, 57
	blt	$r3, $r4, ble_else.41752
	addi	$r3, $r0, 0
	j	ble_cont.41753
ble_else.41752:
	addi	$r3, $r0, 1
ble_cont.41753:
	j	ble_cont.41751
ble_else.41750:
	addi	$r3, $r0, 1
ble_cont.41751:
	beq	$r3, $r0, bne_else.41754
	beq	$r6, $r0, bne_else.41755
	ldi	$r3, $r0, 590
	beq	$r3, $r30, bne_else.41756
	ldi	$r3, $r0, 591
	sub	$r3, $r0, $r3
	jr	$r29
bne_else.41756:
	ldi	$r3, $r0, 591
	jr	$r29
bne_else.41755:
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.41757
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.41759
	addi	$r3, $r0, 0
	j	ble_cont.41760
ble_else.41759:
	addi	$r3, $r0, 1
ble_cont.41760:
	j	ble_cont.41758
ble_else.41757:
	addi	$r3, $r0, 1
ble_cont.41758:
	beq	$r3, $r0, bne_else.41761
	addi	$r6, $r0, 0
	j	read_int_token.2525
bne_else.41761:
	ldi	$r3, $r0, 590
	beq	$r3, $r0, bne_else.41762
	j	bne_cont.41763
bne_else.41762:
	addi	$r3, $r0, 45
	beq	$r4, $r3, bne_else.41764
	addi	$r3, $r0, 1
	sti	$r3, $r0, 590
	j	bne_cont.41765
bne_else.41764:
	addi	$r3, $r0, -1
	sti	$r3, $r0, 590
bne_cont.41765:
bne_cont.41763:
	ldi	$r3, $r0, 591
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 591
	addi	$r6, $r0, 1
	j	read_int_token.2525
bne_else.41754:
	ldi	$r3, $r0, 590
	beq	$r3, $r0, bne_else.41766
	j	bne_cont.41767
bne_else.41766:
	addi	$r3, $r0, 45
	beq	$r5, $r3, bne_else.41768
	addi	$r3, $r0, 1
	sti	$r3, $r0, 590
	j	bne_cont.41769
bne_else.41768:
	addi	$r3, $r0, -1
	sti	$r3, $r0, 590
bne_cont.41769:
bne_cont.41767:
	ldi	$r3, $r0, 591
	slli	$r5, $r3, 3
	slli	$r3, $r3, 1
	add	$r5, $r5, $r3
	subi	$r3, $r4, 48
	add	$r3, $r5, $r3
	sti	$r3, $r0, 591
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.41770
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.41772
	addi	$r3, $r0, 0
	j	ble_cont.41773
ble_else.41772:
	addi	$r3, $r0, 1
ble_cont.41773:
	j	ble_cont.41771
ble_else.41770:
	addi	$r3, $r0, 1
ble_cont.41771:
	beq	$r3, $r0, bne_else.41774
	ldi	$r3, $r0, 590
	beq	$r3, $r30, bne_else.41775
	ldi	$r3, $r0, 591
	sub	$r3, $r0, $r3
	jr	$r29
bne_else.41775:
	ldi	$r3, $r0, 591
	jr	$r29
bne_else.41774:
	ldi	$r3, $r0, 590
	beq	$r3, $r0, bne_else.41776
	j	bne_cont.41777
bne_else.41776:
	addi	$r3, $r0, 45
	beq	$r4, $r3, bne_else.41778
	addi	$r3, $r0, 1
	sti	$r3, $r0, 590
	j	bne_cont.41779
bne_else.41778:
	addi	$r3, $r0, -1
	sti	$r3, $r0, 590
bne_cont.41779:
bne_cont.41777:
	ldi	$r3, $r0, 591
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 591
	addi	$r6, $r0, 1
	j	read_int_token.2525

#---------------------------------------------------------------------
# args = [$r6, $r5]
# fargs = []
# ret type = Int
#---------------------------------------------------------------------
read_float_token1.2534:
	inputb	$r4
	addi	$r3, $r0, 48
	blt	$r4, $r3, ble_else.41780
	addi	$r3, $r0, 57
	blt	$r3, $r4, ble_else.41782
	addi	$r3, $r0, 0
	j	ble_cont.41783
ble_else.41782:
	addi	$r3, $r0, 1
ble_cont.41783:
	j	ble_cont.41781
ble_else.41780:
	addi	$r3, $r0, 1
ble_cont.41781:
	beq	$r3, $r0, bne_else.41784
	beq	$r6, $r0, bne_else.41785
	mov	$r3, $r4
	jr	$r29
bne_else.41785:
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.41786
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.41788
	addi	$r3, $r0, 0
	j	ble_cont.41789
ble_else.41788:
	addi	$r3, $r0, 1
ble_cont.41789:
	j	ble_cont.41787
ble_else.41786:
	addi	$r3, $r0, 1
ble_cont.41787:
	beq	$r3, $r0, bne_else.41790
	addi	$r6, $r0, 0
	j	read_float_token1.2534
bne_else.41790:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.41791
	j	bne_cont.41792
bne_else.41791:
	addi	$r3, $r0, 45
	beq	$r4, $r3, bne_else.41793
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
	j	bne_cont.41794
bne_else.41793:
	addi	$r3, $r0, -1
	sti	$r3, $r0, 586
bne_cont.41794:
bne_cont.41792:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	j	read_float_token1.2534
bne_else.41784:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.41795
	j	bne_cont.41796
bne_else.41795:
	addi	$r3, $r0, 45
	beq	$r5, $r3, bne_else.41797
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
	j	bne_cont.41798
bne_else.41797:
	addi	$r3, $r0, -1
	sti	$r3, $r0, 586
bne_cont.41798:
bne_cont.41796:
	ldi	$r3, $r0, 589
	slli	$r5, $r3, 3
	slli	$r3, $r3, 1
	add	$r5, $r5, $r3
	subi	$r3, $r4, 48
	add	$r3, $r5, $r3
	sti	$r3, $r0, 589
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.41799
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.41801
	addi	$r3, $r0, 0
	j	ble_cont.41802
ble_else.41801:
	addi	$r3, $r0, 1
ble_cont.41802:
	j	ble_cont.41800
ble_else.41799:
	addi	$r3, $r0, 1
ble_cont.41800:
	beq	$r3, $r0, bne_else.41803
	mov	$r3, $r5
	jr	$r29
bne_else.41803:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.41804
	j	bne_cont.41805
bne_else.41804:
	addi	$r3, $r0, 45
	beq	$r4, $r3, bne_else.41806
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
	j	bne_cont.41807
bne_else.41806:
	addi	$r3, $r0, -1
	sti	$r3, $r0, 586
bne_cont.41807:
bne_cont.41805:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	j	read_float_token1.2534

#---------------------------------------------------------------------
# args = [$r4]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
read_float_token2.2537:
	inputb	$r3
	addi	$r5, $r0, 48
	blt	$r3, $r5, ble_else.41808
	addi	$r5, $r0, 57
	blt	$r5, $r3, ble_else.41810
	addi	$r5, $r0, 0
	j	ble_cont.41811
ble_else.41810:
	addi	$r5, $r0, 1
ble_cont.41811:
	j	ble_cont.41809
ble_else.41808:
	addi	$r5, $r0, 1
ble_cont.41809:
	beq	$r5, $r0, bne_else.41812
	beq	$r4, $r0, bne_else.41813
	jr	$r29
bne_else.41813:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.41815
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.41817
	addi	$r4, $r0, 0
	j	ble_cont.41818
ble_else.41817:
	addi	$r4, $r0, 1
ble_cont.41818:
	j	ble_cont.41816
ble_else.41815:
	addi	$r4, $r0, 1
ble_cont.41816:
	beq	$r4, $r0, bne_else.41819
	addi	$r4, $r0, 0
	j	read_float_token2.2537
bne_else.41819:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	j	read_float_token2.2537
bne_else.41812:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.41820
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.41822
	addi	$r4, $r0, 0
	j	ble_cont.41823
ble_else.41822:
	addi	$r4, $r0, 1
ble_cont.41823:
	j	ble_cont.41821
ble_else.41820:
	addi	$r4, $r0, 1
ble_cont.41821:
	beq	$r4, $r0, bne_else.41824
	jr	$r29
bne_else.41824:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	j	read_float_token2.2537

#---------------------------------------------------------------------
# args = [$r4, $r6, $r9, $r10]
# fargs = []
# ret type = Int
#---------------------------------------------------------------------
div_binary_search.2547:
	add	$r3, $r9, $r10
	srai	$r5, $r3, 1
	mul	$r7, $r5, $r6
	sub	$r3, $r10, $r9
	blt	$r30, $r3, ble_else.41826
	mov	$r3, $r9
	jr	$r29
ble_else.41826:
	blt	$r7, $r4, ble_else.41827
	beq	$r7, $r4, bne_else.41828
	add	$r3, $r9, $r5
	srai	$r7, $r3, 1
	mul	$r8, $r7, $r6
	sub	$r3, $r5, $r9
	blt	$r30, $r3, ble_else.41829
	mov	$r3, $r9
	jr	$r29
ble_else.41829:
	blt	$r8, $r4, ble_else.41830
	beq	$r8, $r4, bne_else.41831
	add	$r3, $r9, $r7
	srai	$r8, $r3, 1
	mul	$r5, $r8, $r6
	sub	$r3, $r7, $r9
	blt	$r30, $r3, ble_else.41832
	mov	$r3, $r9
	jr	$r29
ble_else.41832:
	blt	$r5, $r4, ble_else.41833
	beq	$r5, $r4, bne_else.41834
	add	$r3, $r9, $r8
	srai	$r5, $r3, 1
	mul	$r7, $r5, $r6
	sub	$r3, $r8, $r9
	blt	$r30, $r3, ble_else.41835
	mov	$r3, $r9
	jr	$r29
ble_else.41835:
	blt	$r7, $r4, ble_else.41836
	beq	$r7, $r4, bne_else.41837
	mov	$r10, $r5
	j	div_binary_search.2547
bne_else.41837:
	mov	$r3, $r5
	jr	$r29
ble_else.41836:
	mov	$r10, $r8
	mov	$r9, $r5
	j	div_binary_search.2547
bne_else.41834:
	mov	$r3, $r8
	jr	$r29
ble_else.41833:
	add	$r3, $r8, $r7
	srai	$r5, $r3, 1
	mul	$r9, $r5, $r6
	sub	$r3, $r7, $r8
	blt	$r30, $r3, ble_else.41838
	mov	$r3, $r8
	jr	$r29
ble_else.41838:
	blt	$r9, $r4, ble_else.41839
	beq	$r9, $r4, bne_else.41840
	mov	$r10, $r5
	mov	$r9, $r8
	j	div_binary_search.2547
bne_else.41840:
	mov	$r3, $r5
	jr	$r29
ble_else.41839:
	mov	$r10, $r7
	mov	$r9, $r5
	j	div_binary_search.2547
bne_else.41831:
	mov	$r3, $r7
	jr	$r29
ble_else.41830:
	add	$r3, $r7, $r5
	srai	$r8, $r3, 1
	mul	$r9, $r8, $r6
	sub	$r3, $r5, $r7
	blt	$r30, $r3, ble_else.41841
	mov	$r3, $r7
	jr	$r29
ble_else.41841:
	blt	$r9, $r4, ble_else.41842
	beq	$r9, $r4, bne_else.41843
	add	$r3, $r7, $r8
	srai	$r5, $r3, 1
	mul	$r9, $r5, $r6
	sub	$r3, $r8, $r7
	blt	$r30, $r3, ble_else.41844
	mov	$r3, $r7
	jr	$r29
ble_else.41844:
	blt	$r9, $r4, ble_else.41845
	beq	$r9, $r4, bne_else.41846
	mov	$r10, $r5
	mov	$r9, $r7
	j	div_binary_search.2547
bne_else.41846:
	mov	$r3, $r5
	jr	$r29
ble_else.41845:
	mov	$r10, $r8
	mov	$r9, $r5
	j	div_binary_search.2547
bne_else.41843:
	mov	$r3, $r8
	jr	$r29
ble_else.41842:
	add	$r3, $r8, $r5
	srai	$r7, $r3, 1
	mul	$r9, $r7, $r6
	sub	$r3, $r5, $r8
	blt	$r30, $r3, ble_else.41847
	mov	$r3, $r8
	jr	$r29
ble_else.41847:
	blt	$r9, $r4, ble_else.41848
	beq	$r9, $r4, bne_else.41849
	mov	$r10, $r7
	mov	$r9, $r8
	j	div_binary_search.2547
bne_else.41849:
	mov	$r3, $r7
	jr	$r29
ble_else.41848:
	mov	$r10, $r5
	mov	$r9, $r7
	j	div_binary_search.2547
bne_else.41828:
	mov	$r3, $r5
	jr	$r29
ble_else.41827:
	add	$r3, $r5, $r10
	srai	$r8, $r3, 1
	mul	$r7, $r8, $r6
	sub	$r3, $r10, $r5
	blt	$r30, $r3, ble_else.41850
	mov	$r3, $r5
	jr	$r29
ble_else.41850:
	blt	$r7, $r4, ble_else.41851
	beq	$r7, $r4, bne_else.41852
	add	$r3, $r5, $r8
	srai	$r7, $r3, 1
	mul	$r9, $r7, $r6
	sub	$r3, $r8, $r5
	blt	$r30, $r3, ble_else.41853
	mov	$r3, $r5
	jr	$r29
ble_else.41853:
	blt	$r9, $r4, ble_else.41854
	beq	$r9, $r4, bne_else.41855
	add	$r3, $r5, $r7
	srai	$r8, $r3, 1
	mul	$r9, $r8, $r6
	sub	$r3, $r7, $r5
	blt	$r30, $r3, ble_else.41856
	mov	$r3, $r5
	jr	$r29
ble_else.41856:
	blt	$r9, $r4, ble_else.41857
	beq	$r9, $r4, bne_else.41858
	mov	$r10, $r8
	mov	$r9, $r5
	j	div_binary_search.2547
bne_else.41858:
	mov	$r3, $r8
	jr	$r29
ble_else.41857:
	mov	$r10, $r7
	mov	$r9, $r8
	j	div_binary_search.2547
bne_else.41855:
	mov	$r3, $r7
	jr	$r29
ble_else.41854:
	add	$r3, $r7, $r8
	srai	$r5, $r3, 1
	mul	$r9, $r5, $r6
	sub	$r3, $r8, $r7
	blt	$r30, $r3, ble_else.41859
	mov	$r3, $r7
	jr	$r29
ble_else.41859:
	blt	$r9, $r4, ble_else.41860
	beq	$r9, $r4, bne_else.41861
	mov	$r10, $r5
	mov	$r9, $r7
	j	div_binary_search.2547
bne_else.41861:
	mov	$r3, $r5
	jr	$r29
ble_else.41860:
	mov	$r10, $r8
	mov	$r9, $r5
	j	div_binary_search.2547
bne_else.41852:
	mov	$r3, $r8
	jr	$r29
ble_else.41851:
	add	$r3, $r8, $r10
	srai	$r7, $r3, 1
	mul	$r5, $r7, $r6
	sub	$r3, $r10, $r8
	blt	$r30, $r3, ble_else.41862
	mov	$r3, $r8
	jr	$r29
ble_else.41862:
	blt	$r5, $r4, ble_else.41863
	beq	$r5, $r4, bne_else.41864
	add	$r3, $r8, $r7
	srai	$r5, $r3, 1
	mul	$r9, $r5, $r6
	sub	$r3, $r7, $r8
	blt	$r30, $r3, ble_else.41865
	mov	$r3, $r8
	jr	$r29
ble_else.41865:
	blt	$r9, $r4, ble_else.41866
	beq	$r9, $r4, bne_else.41867
	mov	$r10, $r5
	mov	$r9, $r8
	j	div_binary_search.2547
bne_else.41867:
	mov	$r3, $r5
	jr	$r29
ble_else.41866:
	mov	$r10, $r7
	mov	$r9, $r5
	j	div_binary_search.2547
bne_else.41864:
	mov	$r3, $r7
	jr	$r29
ble_else.41863:
	add	$r3, $r7, $r10
	srai	$r5, $r3, 1
	mul	$r8, $r5, $r6
	sub	$r3, $r10, $r7
	blt	$r30, $r3, ble_else.41868
	mov	$r3, $r7
	jr	$r29
ble_else.41868:
	blt	$r8, $r4, ble_else.41869
	beq	$r8, $r4, bne_else.41870
	mov	$r10, $r5
	mov	$r9, $r7
	j	div_binary_search.2547
bne_else.41870:
	mov	$r3, $r5
	jr	$r29
ble_else.41869:
	mov	$r9, $r5
	j	div_binary_search.2547

#---------------------------------------------------------------------
# args = [$r4]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
print_int.2559:
	blt	$r4, $r0, bge_else.41871
	mvhi	$r3, 1525
	mvlo	$r3, 57600
	blt	$r3, $r4, ble_else.41872
	beq	$r3, $r4, bne_else.41874
	addi	$r5, $r0, 0
	j	bne_cont.41875
bne_else.41874:
	addi	$r5, $r0, 1
bne_cont.41875:
	j	ble_cont.41873
ble_else.41872:
	mvhi	$r3, 3051
	mvlo	$r3, 49664
	blt	$r3, $r4, ble_else.41876
	beq	$r3, $r4, bne_else.41878
	addi	$r5, $r0, 1
	j	bne_cont.41879
bne_else.41878:
	addi	$r5, $r0, 2
bne_cont.41879:
	j	ble_cont.41877
ble_else.41876:
	addi	$r5, $r0, 2
ble_cont.41877:
ble_cont.41873:
	mvhi	$r3, 1525
	mvlo	$r3, 57600
	mul	$r3, $r5, $r3
	sub	$r4, $r4, $r3
	blt	$r0, $r5, ble_else.41880
	addi	$r13, $r0, 0
	j	ble_cont.41881
ble_else.41880:
	addi	$r3, $r0, 48
	add	$r3, $r3, $r5
	outputb	$r3
	addi	$r13, $r0, 1
ble_cont.41881:
	mvhi	$r6, 152
	mvlo	$r6, 38528
	addi	$r12, $r0, 0
	addi	$r10, $r0, 10
	addi	$r9, $r0, 5
	mvhi	$r5, 762
	mvlo	$r5, 61568
	sti	$r4, $r1, 0
	blt	$r5, $r4, ble_else.41882
	beq	$r5, $r4, bne_else.41884
	addi	$r11, $r0, 2
	mvhi	$r5, 305
	mvlo	$r5, 11520
	blt	$r5, $r4, ble_else.41886
	beq	$r5, $r4, bne_else.41888
	addi	$r9, $r0, 1
	mvhi	$r5, 152
	mvlo	$r5, 38528
	blt	$r5, $r4, ble_else.41890
	beq	$r5, $r4, bne_else.41892
	mov	$r10, $r9
	mov	$r9, $r12
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	div_binary_search.2547
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.41893
bne_else.41892:
	addi	$r3, $r0, 1
bne_cont.41893:
	j	ble_cont.41891
ble_else.41890:
	mov	$r10, $r11
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	div_binary_search.2547
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
ble_cont.41891:
	j	bne_cont.41889
bne_else.41888:
	addi	$r3, $r0, 2
bne_cont.41889:
	j	ble_cont.41887
ble_else.41886:
	addi	$r10, $r0, 3
	mvhi	$r5, 457
	mvlo	$r5, 50048
	blt	$r5, $r4, ble_else.41894
	beq	$r5, $r4, bne_else.41896
	mov	$r9, $r11
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	div_binary_search.2547
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.41897
bne_else.41896:
	addi	$r3, $r0, 3
bne_cont.41897:
	j	ble_cont.41895
ble_else.41894:
	mov	$r27, $r10
	mov	$r10, $r9
	mov	$r9, $r27
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	div_binary_search.2547
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
ble_cont.41895:
ble_cont.41887:
	j	bne_cont.41885
bne_else.41884:
	addi	$r3, $r0, 5
bne_cont.41885:
	j	ble_cont.41883
ble_else.41882:
	addi	$r11, $r0, 7
	mvhi	$r5, 1068
	mvlo	$r5, 7552
	blt	$r5, $r4, ble_else.41898
	beq	$r5, $r4, bne_else.41900
	addi	$r10, $r0, 6
	mvhi	$r5, 915
	mvlo	$r5, 34560
	blt	$r5, $r4, ble_else.41902
	beq	$r5, $r4, bne_else.41904
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	div_binary_search.2547
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.41905
bne_else.41904:
	addi	$r3, $r0, 6
bne_cont.41905:
	j	ble_cont.41903
ble_else.41902:
	mov	$r9, $r10
	mov	$r10, $r11
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	div_binary_search.2547
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
ble_cont.41903:
	j	bne_cont.41901
bne_else.41900:
	addi	$r3, $r0, 7
bne_cont.41901:
	j	ble_cont.41899
ble_else.41898:
	addi	$r9, $r0, 8
	mvhi	$r5, 1220
	mvlo	$r5, 46080
	blt	$r5, $r4, ble_else.41906
	beq	$r5, $r4, bne_else.41908
	mov	$r10, $r9
	mov	$r9, $r11
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	div_binary_search.2547
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.41909
bne_else.41908:
	addi	$r3, $r0, 8
bne_cont.41909:
	j	ble_cont.41907
ble_else.41906:
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	div_binary_search.2547
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
ble_cont.41907:
ble_cont.41899:
ble_cont.41883:
	mvhi	$r5, 152
	mvlo	$r5, 38528
	mul	$r5, $r3, $r5
	ldi	$r4, $r1, 0
	sub	$r4, $r4, $r5
	blt	$r0, $r3, ble_else.41910
	beq	$r13, $r0, bne_else.41912
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r14, $r0, 1
	j	bne_cont.41913
bne_else.41912:
	addi	$r14, $r0, 0
bne_cont.41913:
	j	ble_cont.41911
ble_else.41910:
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r14, $r0, 1
ble_cont.41911:
	mvhi	$r6, 15
	mvlo	$r6, 16960
	addi	$r12, $r0, 0
	addi	$r10, $r0, 10
	addi	$r9, $r0, 5
	mvhi	$r5, 76
	mvlo	$r5, 19264
	sti	$r4, $r1, -1
	blt	$r5, $r4, ble_else.41914
	beq	$r5, $r4, bne_else.41916
	addi	$r11, $r0, 2
	mvhi	$r5, 30
	mvlo	$r5, 33920
	blt	$r5, $r4, ble_else.41918
	beq	$r5, $r4, bne_else.41920
	addi	$r9, $r0, 1
	mvhi	$r5, 15
	mvlo	$r5, 16960
	blt	$r5, $r4, ble_else.41922
	beq	$r5, $r4, bne_else.41924
	mov	$r10, $r9
	mov	$r9, $r12
	sti	$r29, $r1, -3
	subi	$r1, $r1, 4
	jal	div_binary_search.2547
	addi	$r1, $r1, 4
	ldi	$r29, $r1, -3
	j	bne_cont.41925
bne_else.41924:
	addi	$r3, $r0, 1
bne_cont.41925:
	j	ble_cont.41923
ble_else.41922:
	mov	$r10, $r11
	sti	$r29, $r1, -3
	subi	$r1, $r1, 4
	jal	div_binary_search.2547
	addi	$r1, $r1, 4
	ldi	$r29, $r1, -3
ble_cont.41923:
	j	bne_cont.41921
bne_else.41920:
	addi	$r3, $r0, 2
bne_cont.41921:
	j	ble_cont.41919
ble_else.41918:
	addi	$r10, $r0, 3
	mvhi	$r5, 45
	mvlo	$r5, 50880
	blt	$r5, $r4, ble_else.41926
	beq	$r5, $r4, bne_else.41928
	mov	$r9, $r11
	sti	$r29, $r1, -3
	subi	$r1, $r1, 4
	jal	div_binary_search.2547
	addi	$r1, $r1, 4
	ldi	$r29, $r1, -3
	j	bne_cont.41929
bne_else.41928:
	addi	$r3, $r0, 3
bne_cont.41929:
	j	ble_cont.41927
ble_else.41926:
	mov	$r27, $r10
	mov	$r10, $r9
	mov	$r9, $r27
	sti	$r29, $r1, -3
	subi	$r1, $r1, 4
	jal	div_binary_search.2547
	addi	$r1, $r1, 4
	ldi	$r29, $r1, -3
ble_cont.41927:
ble_cont.41919:
	j	bne_cont.41917
bne_else.41916:
	addi	$r3, $r0, 5
bne_cont.41917:
	j	ble_cont.41915
ble_else.41914:
	addi	$r11, $r0, 7
	mvhi	$r5, 106
	mvlo	$r5, 53184
	blt	$r5, $r4, ble_else.41930
	beq	$r5, $r4, bne_else.41932
	addi	$r10, $r0, 6
	mvhi	$r5, 91
	mvlo	$r5, 36224
	blt	$r5, $r4, ble_else.41934
	beq	$r5, $r4, bne_else.41936
	sti	$r29, $r1, -3
	subi	$r1, $r1, 4
	jal	div_binary_search.2547
	addi	$r1, $r1, 4
	ldi	$r29, $r1, -3
	j	bne_cont.41937
bne_else.41936:
	addi	$r3, $r0, 6
bne_cont.41937:
	j	ble_cont.41935
ble_else.41934:
	mov	$r9, $r10
	mov	$r10, $r11
	sti	$r29, $r1, -3
	subi	$r1, $r1, 4
	jal	div_binary_search.2547
	addi	$r1, $r1, 4
	ldi	$r29, $r1, -3
ble_cont.41935:
	j	bne_cont.41933
bne_else.41932:
	addi	$r3, $r0, 7
bne_cont.41933:
	j	ble_cont.41931
ble_else.41930:
	addi	$r9, $r0, 8
	mvhi	$r5, 122
	mvlo	$r5, 4608
	blt	$r5, $r4, ble_else.41938
	beq	$r5, $r4, bne_else.41940
	mov	$r10, $r9
	mov	$r9, $r11
	sti	$r29, $r1, -3
	subi	$r1, $r1, 4
	jal	div_binary_search.2547
	addi	$r1, $r1, 4
	ldi	$r29, $r1, -3
	j	bne_cont.41941
bne_else.41940:
	addi	$r3, $r0, 8
bne_cont.41941:
	j	ble_cont.41939
ble_else.41938:
	sti	$r29, $r1, -3
	subi	$r1, $r1, 4
	jal	div_binary_search.2547
	addi	$r1, $r1, 4
	ldi	$r29, $r1, -3
ble_cont.41939:
ble_cont.41931:
ble_cont.41915:
	mvhi	$r5, 15
	mvlo	$r5, 16960
	mul	$r5, $r3, $r5
	ldi	$r4, $r1, -1
	sub	$r4, $r4, $r5
	blt	$r0, $r3, ble_else.41942
	beq	$r14, $r0, bne_else.41944
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r13, $r0, 1
	j	bne_cont.41945
bne_else.41944:
	addi	$r13, $r0, 0
bne_cont.41945:
	j	ble_cont.41943
ble_else.41942:
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r13, $r0, 1
ble_cont.41943:
	mvhi	$r6, 1
	mvlo	$r6, 34464
	addi	$r12, $r0, 0
	addi	$r10, $r0, 10
	addi	$r9, $r0, 5
	mvhi	$r5, 7
	mvlo	$r5, 41248
	sti	$r4, $r1, -2
	blt	$r5, $r4, ble_else.41946
	beq	$r5, $r4, bne_else.41948
	addi	$r11, $r0, 2
	mvhi	$r5, 3
	mvlo	$r5, 3392
	blt	$r5, $r4, ble_else.41950
	beq	$r5, $r4, bne_else.41952
	addi	$r9, $r0, 1
	mvhi	$r5, 1
	mvlo	$r5, 34464
	blt	$r5, $r4, ble_else.41954
	beq	$r5, $r4, bne_else.41956
	mov	$r10, $r9
	mov	$r9, $r12
	sti	$r29, $r1, -4
	subi	$r1, $r1, 5
	jal	div_binary_search.2547
	addi	$r1, $r1, 5
	ldi	$r29, $r1, -4
	j	bne_cont.41957
bne_else.41956:
	addi	$r3, $r0, 1
bne_cont.41957:
	j	ble_cont.41955
ble_else.41954:
	mov	$r10, $r11
	sti	$r29, $r1, -4
	subi	$r1, $r1, 5
	jal	div_binary_search.2547
	addi	$r1, $r1, 5
	ldi	$r29, $r1, -4
ble_cont.41955:
	j	bne_cont.41953
bne_else.41952:
	addi	$r3, $r0, 2
bne_cont.41953:
	j	ble_cont.41951
ble_else.41950:
	addi	$r10, $r0, 3
	mvhi	$r5, 4
	mvlo	$r5, 37856
	blt	$r5, $r4, ble_else.41958
	beq	$r5, $r4, bne_else.41960
	mov	$r9, $r11
	sti	$r29, $r1, -4
	subi	$r1, $r1, 5
	jal	div_binary_search.2547
	addi	$r1, $r1, 5
	ldi	$r29, $r1, -4
	j	bne_cont.41961
bne_else.41960:
	addi	$r3, $r0, 3
bne_cont.41961:
	j	ble_cont.41959
ble_else.41958:
	mov	$r27, $r10
	mov	$r10, $r9
	mov	$r9, $r27
	sti	$r29, $r1, -4
	subi	$r1, $r1, 5
	jal	div_binary_search.2547
	addi	$r1, $r1, 5
	ldi	$r29, $r1, -4
ble_cont.41959:
ble_cont.41951:
	j	bne_cont.41949
bne_else.41948:
	addi	$r3, $r0, 5
bne_cont.41949:
	j	ble_cont.41947
ble_else.41946:
	addi	$r11, $r0, 7
	mvhi	$r5, 10
	mvlo	$r5, 44640
	blt	$r5, $r4, ble_else.41962
	beq	$r5, $r4, bne_else.41964
	addi	$r10, $r0, 6
	mvhi	$r5, 9
	mvlo	$r5, 10176
	blt	$r5, $r4, ble_else.41966
	beq	$r5, $r4, bne_else.41968
	sti	$r29, $r1, -4
	subi	$r1, $r1, 5
	jal	div_binary_search.2547
	addi	$r1, $r1, 5
	ldi	$r29, $r1, -4
	j	bne_cont.41969
bne_else.41968:
	addi	$r3, $r0, 6
bne_cont.41969:
	j	ble_cont.41967
ble_else.41966:
	mov	$r9, $r10
	mov	$r10, $r11
	sti	$r29, $r1, -4
	subi	$r1, $r1, 5
	jal	div_binary_search.2547
	addi	$r1, $r1, 5
	ldi	$r29, $r1, -4
ble_cont.41967:
	j	bne_cont.41965
bne_else.41964:
	addi	$r3, $r0, 7
bne_cont.41965:
	j	ble_cont.41963
ble_else.41962:
	addi	$r9, $r0, 8
	mvhi	$r5, 12
	mvlo	$r5, 13568
	blt	$r5, $r4, ble_else.41970
	beq	$r5, $r4, bne_else.41972
	mov	$r10, $r9
	mov	$r9, $r11
	sti	$r29, $r1, -4
	subi	$r1, $r1, 5
	jal	div_binary_search.2547
	addi	$r1, $r1, 5
	ldi	$r29, $r1, -4
	j	bne_cont.41973
bne_else.41972:
	addi	$r3, $r0, 8
bne_cont.41973:
	j	ble_cont.41971
ble_else.41970:
	sti	$r29, $r1, -4
	subi	$r1, $r1, 5
	jal	div_binary_search.2547
	addi	$r1, $r1, 5
	ldi	$r29, $r1, -4
ble_cont.41971:
ble_cont.41963:
ble_cont.41947:
	mvhi	$r5, 1
	mvlo	$r5, 34464
	mul	$r5, $r3, $r5
	ldi	$r4, $r1, -2
	sub	$r4, $r4, $r5
	blt	$r0, $r3, ble_else.41974
	beq	$r13, $r0, bne_else.41976
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r14, $r0, 1
	j	bne_cont.41977
bne_else.41976:
	addi	$r14, $r0, 0
bne_cont.41977:
	j	ble_cont.41975
ble_else.41974:
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r14, $r0, 1
ble_cont.41975:
	addi	$r6, $r0, 10000
	addi	$r12, $r0, 0
	addi	$r10, $r0, 10
	addi	$r9, $r0, 5
	mvhi	$r5, 0
	mvlo	$r5, 50000
	sti	$r4, $r1, -3
	blt	$r5, $r4, ble_else.41978
	beq	$r5, $r4, bne_else.41980
	addi	$r11, $r0, 2
	addi	$r5, $r0, 20000
	blt	$r5, $r4, ble_else.41982
	beq	$r5, $r4, bne_else.41984
	addi	$r9, $r0, 1
	addi	$r5, $r0, 10000
	blt	$r5, $r4, ble_else.41986
	beq	$r5, $r4, bne_else.41988
	mov	$r10, $r9
	mov	$r9, $r12
	sti	$r29, $r1, -5
	subi	$r1, $r1, 6
	jal	div_binary_search.2547
	addi	$r1, $r1, 6
	ldi	$r29, $r1, -5
	j	bne_cont.41989
bne_else.41988:
	addi	$r3, $r0, 1
bne_cont.41989:
	j	ble_cont.41987
ble_else.41986:
	mov	$r10, $r11
	sti	$r29, $r1, -5
	subi	$r1, $r1, 6
	jal	div_binary_search.2547
	addi	$r1, $r1, 6
	ldi	$r29, $r1, -5
ble_cont.41987:
	j	bne_cont.41985
bne_else.41984:
	addi	$r3, $r0, 2
bne_cont.41985:
	j	ble_cont.41983
ble_else.41982:
	addi	$r10, $r0, 3
	addi	$r5, $r0, 30000
	blt	$r5, $r4, ble_else.41990
	beq	$r5, $r4, bne_else.41992
	mov	$r9, $r11
	sti	$r29, $r1, -5
	subi	$r1, $r1, 6
	jal	div_binary_search.2547
	addi	$r1, $r1, 6
	ldi	$r29, $r1, -5
	j	bne_cont.41993
bne_else.41992:
	addi	$r3, $r0, 3
bne_cont.41993:
	j	ble_cont.41991
ble_else.41990:
	mov	$r27, $r10
	mov	$r10, $r9
	mov	$r9, $r27
	sti	$r29, $r1, -5
	subi	$r1, $r1, 6
	jal	div_binary_search.2547
	addi	$r1, $r1, 6
	ldi	$r29, $r1, -5
ble_cont.41991:
ble_cont.41983:
	j	bne_cont.41981
bne_else.41980:
	addi	$r3, $r0, 5
bne_cont.41981:
	j	ble_cont.41979
ble_else.41978:
	addi	$r11, $r0, 7
	mvhi	$r5, 1
	mvlo	$r5, 4464
	blt	$r5, $r4, ble_else.41994
	beq	$r5, $r4, bne_else.41996
	addi	$r10, $r0, 6
	mvhi	$r5, 0
	mvlo	$r5, 60000
	blt	$r5, $r4, ble_else.41998
	beq	$r5, $r4, bne_else.42000
	sti	$r29, $r1, -5
	subi	$r1, $r1, 6
	jal	div_binary_search.2547
	addi	$r1, $r1, 6
	ldi	$r29, $r1, -5
	j	bne_cont.42001
bne_else.42000:
	addi	$r3, $r0, 6
bne_cont.42001:
	j	ble_cont.41999
ble_else.41998:
	mov	$r9, $r10
	mov	$r10, $r11
	sti	$r29, $r1, -5
	subi	$r1, $r1, 6
	jal	div_binary_search.2547
	addi	$r1, $r1, 6
	ldi	$r29, $r1, -5
ble_cont.41999:
	j	bne_cont.41997
bne_else.41996:
	addi	$r3, $r0, 7
bne_cont.41997:
	j	ble_cont.41995
ble_else.41994:
	addi	$r9, $r0, 8
	mvhi	$r5, 1
	mvlo	$r5, 14464
	blt	$r5, $r4, ble_else.42002
	beq	$r5, $r4, bne_else.42004
	mov	$r10, $r9
	mov	$r9, $r11
	sti	$r29, $r1, -5
	subi	$r1, $r1, 6
	jal	div_binary_search.2547
	addi	$r1, $r1, 6
	ldi	$r29, $r1, -5
	j	bne_cont.42005
bne_else.42004:
	addi	$r3, $r0, 8
bne_cont.42005:
	j	ble_cont.42003
ble_else.42002:
	sti	$r29, $r1, -5
	subi	$r1, $r1, 6
	jal	div_binary_search.2547
	addi	$r1, $r1, 6
	ldi	$r29, $r1, -5
ble_cont.42003:
ble_cont.41995:
ble_cont.41979:
	addi	$r5, $r0, 10000
	mul	$r5, $r3, $r5
	ldi	$r4, $r1, -3
	sub	$r4, $r4, $r5
	blt	$r0, $r3, ble_else.42006
	beq	$r14, $r0, bne_else.42008
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r13, $r0, 1
	j	bne_cont.42009
bne_else.42008:
	addi	$r13, $r0, 0
bne_cont.42009:
	j	ble_cont.42007
ble_else.42006:
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r13, $r0, 1
ble_cont.42007:
	addi	$r6, $r0, 1000
	addi	$r12, $r0, 0
	addi	$r10, $r0, 10
	addi	$r9, $r0, 5
	addi	$r5, $r0, 5000
	sti	$r4, $r1, -4
	blt	$r5, $r4, ble_else.42010
	beq	$r5, $r4, bne_else.42012
	addi	$r11, $r0, 2
	addi	$r5, $r0, 2000
	blt	$r5, $r4, ble_else.42014
	beq	$r5, $r4, bne_else.42016
	addi	$r9, $r0, 1
	addi	$r5, $r0, 1000
	blt	$r5, $r4, ble_else.42018
	beq	$r5, $r4, bne_else.42020
	mov	$r10, $r9
	mov	$r9, $r12
	sti	$r29, $r1, -6
	subi	$r1, $r1, 7
	jal	div_binary_search.2547
	addi	$r1, $r1, 7
	ldi	$r29, $r1, -6
	j	bne_cont.42021
bne_else.42020:
	addi	$r3, $r0, 1
bne_cont.42021:
	j	ble_cont.42019
ble_else.42018:
	mov	$r10, $r11
	sti	$r29, $r1, -6
	subi	$r1, $r1, 7
	jal	div_binary_search.2547
	addi	$r1, $r1, 7
	ldi	$r29, $r1, -6
ble_cont.42019:
	j	bne_cont.42017
bne_else.42016:
	addi	$r3, $r0, 2
bne_cont.42017:
	j	ble_cont.42015
ble_else.42014:
	addi	$r10, $r0, 3
	addi	$r5, $r0, 3000
	blt	$r5, $r4, ble_else.42022
	beq	$r5, $r4, bne_else.42024
	mov	$r9, $r11
	sti	$r29, $r1, -6
	subi	$r1, $r1, 7
	jal	div_binary_search.2547
	addi	$r1, $r1, 7
	ldi	$r29, $r1, -6
	j	bne_cont.42025
bne_else.42024:
	addi	$r3, $r0, 3
bne_cont.42025:
	j	ble_cont.42023
ble_else.42022:
	mov	$r27, $r10
	mov	$r10, $r9
	mov	$r9, $r27
	sti	$r29, $r1, -6
	subi	$r1, $r1, 7
	jal	div_binary_search.2547
	addi	$r1, $r1, 7
	ldi	$r29, $r1, -6
ble_cont.42023:
ble_cont.42015:
	j	bne_cont.42013
bne_else.42012:
	addi	$r3, $r0, 5
bne_cont.42013:
	j	ble_cont.42011
ble_else.42010:
	addi	$r11, $r0, 7
	addi	$r5, $r0, 7000
	blt	$r5, $r4, ble_else.42026
	beq	$r5, $r4, bne_else.42028
	addi	$r10, $r0, 6
	addi	$r5, $r0, 6000
	blt	$r5, $r4, ble_else.42030
	beq	$r5, $r4, bne_else.42032
	sti	$r29, $r1, -6
	subi	$r1, $r1, 7
	jal	div_binary_search.2547
	addi	$r1, $r1, 7
	ldi	$r29, $r1, -6
	j	bne_cont.42033
bne_else.42032:
	addi	$r3, $r0, 6
bne_cont.42033:
	j	ble_cont.42031
ble_else.42030:
	mov	$r9, $r10
	mov	$r10, $r11
	sti	$r29, $r1, -6
	subi	$r1, $r1, 7
	jal	div_binary_search.2547
	addi	$r1, $r1, 7
	ldi	$r29, $r1, -6
ble_cont.42031:
	j	bne_cont.42029
bne_else.42028:
	addi	$r3, $r0, 7
bne_cont.42029:
	j	ble_cont.42027
ble_else.42026:
	addi	$r9, $r0, 8
	addi	$r5, $r0, 8000
	blt	$r5, $r4, ble_else.42034
	beq	$r5, $r4, bne_else.42036
	mov	$r10, $r9
	mov	$r9, $r11
	sti	$r29, $r1, -6
	subi	$r1, $r1, 7
	jal	div_binary_search.2547
	addi	$r1, $r1, 7
	ldi	$r29, $r1, -6
	j	bne_cont.42037
bne_else.42036:
	addi	$r3, $r0, 8
bne_cont.42037:
	j	ble_cont.42035
ble_else.42034:
	sti	$r29, $r1, -6
	subi	$r1, $r1, 7
	jal	div_binary_search.2547
	addi	$r1, $r1, 7
	ldi	$r29, $r1, -6
ble_cont.42035:
ble_cont.42027:
ble_cont.42011:
	muli	$r5, $r3, 1000
	ldi	$r4, $r1, -4
	sub	$r4, $r4, $r5
	blt	$r0, $r3, ble_else.42038
	beq	$r13, $r0, bne_else.42040
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r14, $r0, 1
	j	bne_cont.42041
bne_else.42040:
	addi	$r14, $r0, 0
bne_cont.42041:
	j	ble_cont.42039
ble_else.42038:
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r14, $r0, 1
ble_cont.42039:
	addi	$r6, $r0, 100
	addi	$r12, $r0, 0
	addi	$r10, $r0, 10
	addi	$r9, $r0, 5
	addi	$r5, $r0, 500
	sti	$r4, $r1, -5
	blt	$r5, $r4, ble_else.42042
	beq	$r5, $r4, bne_else.42044
	addi	$r11, $r0, 2
	addi	$r5, $r0, 200
	blt	$r5, $r4, ble_else.42046
	beq	$r5, $r4, bne_else.42048
	addi	$r9, $r0, 1
	addi	$r5, $r0, 100
	blt	$r5, $r4, ble_else.42050
	beq	$r5, $r4, bne_else.42052
	mov	$r10, $r9
	mov	$r9, $r12
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	div_binary_search.2547
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
	j	bne_cont.42053
bne_else.42052:
	addi	$r3, $r0, 1
bne_cont.42053:
	j	ble_cont.42051
ble_else.42050:
	mov	$r10, $r11
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	div_binary_search.2547
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
ble_cont.42051:
	j	bne_cont.42049
bne_else.42048:
	addi	$r3, $r0, 2
bne_cont.42049:
	j	ble_cont.42047
ble_else.42046:
	addi	$r10, $r0, 3
	addi	$r5, $r0, 300
	blt	$r5, $r4, ble_else.42054
	beq	$r5, $r4, bne_else.42056
	mov	$r9, $r11
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	div_binary_search.2547
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
	j	bne_cont.42057
bne_else.42056:
	addi	$r3, $r0, 3
bne_cont.42057:
	j	ble_cont.42055
ble_else.42054:
	mov	$r27, $r10
	mov	$r10, $r9
	mov	$r9, $r27
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	div_binary_search.2547
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
ble_cont.42055:
ble_cont.42047:
	j	bne_cont.42045
bne_else.42044:
	addi	$r3, $r0, 5
bne_cont.42045:
	j	ble_cont.42043
ble_else.42042:
	addi	$r11, $r0, 7
	addi	$r5, $r0, 700
	blt	$r5, $r4, ble_else.42058
	beq	$r5, $r4, bne_else.42060
	addi	$r10, $r0, 6
	addi	$r5, $r0, 600
	blt	$r5, $r4, ble_else.42062
	beq	$r5, $r4, bne_else.42064
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	div_binary_search.2547
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
	j	bne_cont.42065
bne_else.42064:
	addi	$r3, $r0, 6
bne_cont.42065:
	j	ble_cont.42063
ble_else.42062:
	mov	$r9, $r10
	mov	$r10, $r11
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	div_binary_search.2547
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
ble_cont.42063:
	j	bne_cont.42061
bne_else.42060:
	addi	$r3, $r0, 7
bne_cont.42061:
	j	ble_cont.42059
ble_else.42058:
	addi	$r9, $r0, 8
	addi	$r5, $r0, 800
	blt	$r5, $r4, ble_else.42066
	beq	$r5, $r4, bne_else.42068
	mov	$r10, $r9
	mov	$r9, $r11
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	div_binary_search.2547
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
	j	bne_cont.42069
bne_else.42068:
	addi	$r3, $r0, 8
bne_cont.42069:
	j	ble_cont.42067
ble_else.42066:
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	div_binary_search.2547
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
ble_cont.42067:
ble_cont.42059:
ble_cont.42043:
	muli	$r5, $r3, 100
	ldi	$r4, $r1, -5
	sub	$r4, $r4, $r5
	blt	$r0, $r3, ble_else.42070
	beq	$r14, $r0, bne_else.42072
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r13, $r0, 1
	j	bne_cont.42073
bne_else.42072:
	addi	$r13, $r0, 0
bne_cont.42073:
	j	ble_cont.42071
ble_else.42070:
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r13, $r0, 1
ble_cont.42071:
	addi	$r6, $r0, 10
	addi	$r12, $r0, 0
	addi	$r10, $r0, 10
	addi	$r9, $r0, 5
	addi	$r5, $r0, 50
	sti	$r4, $r1, -6
	blt	$r5, $r4, ble_else.42074
	beq	$r5, $r4, bne_else.42076
	addi	$r11, $r0, 2
	addi	$r5, $r0, 20
	blt	$r5, $r4, ble_else.42078
	beq	$r5, $r4, bne_else.42080
	addi	$r9, $r0, 1
	addi	$r5, $r0, 10
	blt	$r5, $r4, ble_else.42082
	beq	$r5, $r4, bne_else.42084
	mov	$r10, $r9
	mov	$r9, $r12
	sti	$r29, $r1, -8
	subi	$r1, $r1, 9
	jal	div_binary_search.2547
	addi	$r1, $r1, 9
	ldi	$r29, $r1, -8
	j	bne_cont.42085
bne_else.42084:
	addi	$r3, $r0, 1
bne_cont.42085:
	j	ble_cont.42083
ble_else.42082:
	mov	$r10, $r11
	sti	$r29, $r1, -8
	subi	$r1, $r1, 9
	jal	div_binary_search.2547
	addi	$r1, $r1, 9
	ldi	$r29, $r1, -8
ble_cont.42083:
	j	bne_cont.42081
bne_else.42080:
	addi	$r3, $r0, 2
bne_cont.42081:
	j	ble_cont.42079
ble_else.42078:
	addi	$r10, $r0, 3
	addi	$r5, $r0, 30
	blt	$r5, $r4, ble_else.42086
	beq	$r5, $r4, bne_else.42088
	mov	$r9, $r11
	sti	$r29, $r1, -8
	subi	$r1, $r1, 9
	jal	div_binary_search.2547
	addi	$r1, $r1, 9
	ldi	$r29, $r1, -8
	j	bne_cont.42089
bne_else.42088:
	addi	$r3, $r0, 3
bne_cont.42089:
	j	ble_cont.42087
ble_else.42086:
	mov	$r27, $r10
	mov	$r10, $r9
	mov	$r9, $r27
	sti	$r29, $r1, -8
	subi	$r1, $r1, 9
	jal	div_binary_search.2547
	addi	$r1, $r1, 9
	ldi	$r29, $r1, -8
ble_cont.42087:
ble_cont.42079:
	j	bne_cont.42077
bne_else.42076:
	addi	$r3, $r0, 5
bne_cont.42077:
	j	ble_cont.42075
ble_else.42074:
	addi	$r11, $r0, 7
	addi	$r5, $r0, 70
	blt	$r5, $r4, ble_else.42090
	beq	$r5, $r4, bne_else.42092
	addi	$r10, $r0, 6
	addi	$r5, $r0, 60
	blt	$r5, $r4, ble_else.42094
	beq	$r5, $r4, bne_else.42096
	sti	$r29, $r1, -8
	subi	$r1, $r1, 9
	jal	div_binary_search.2547
	addi	$r1, $r1, 9
	ldi	$r29, $r1, -8
	j	bne_cont.42097
bne_else.42096:
	addi	$r3, $r0, 6
bne_cont.42097:
	j	ble_cont.42095
ble_else.42094:
	mov	$r9, $r10
	mov	$r10, $r11
	sti	$r29, $r1, -8
	subi	$r1, $r1, 9
	jal	div_binary_search.2547
	addi	$r1, $r1, 9
	ldi	$r29, $r1, -8
ble_cont.42095:
	j	bne_cont.42093
bne_else.42092:
	addi	$r3, $r0, 7
bne_cont.42093:
	j	ble_cont.42091
ble_else.42090:
	addi	$r9, $r0, 8
	addi	$r5, $r0, 80
	blt	$r5, $r4, ble_else.42098
	beq	$r5, $r4, bne_else.42100
	mov	$r10, $r9
	mov	$r9, $r11
	sti	$r29, $r1, -8
	subi	$r1, $r1, 9
	jal	div_binary_search.2547
	addi	$r1, $r1, 9
	ldi	$r29, $r1, -8
	j	bne_cont.42101
bne_else.42100:
	addi	$r3, $r0, 8
bne_cont.42101:
	j	ble_cont.42099
ble_else.42098:
	sti	$r29, $r1, -8
	subi	$r1, $r1, 9
	jal	div_binary_search.2547
	addi	$r1, $r1, 9
	ldi	$r29, $r1, -8
ble_cont.42099:
ble_cont.42091:
ble_cont.42075:
	muli	$r5, $r3, 10
	ldi	$r4, $r1, -6
	sub	$r4, $r4, $r5
	blt	$r0, $r3, ble_else.42102
	beq	$r13, $r0, bne_else.42104
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r5, $r0, 1
	j	bne_cont.42105
bne_else.42104:
	addi	$r5, $r0, 0
bne_cont.42105:
	j	ble_cont.42103
ble_else.42102:
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r5, $r0, 1
ble_cont.42103:
	addi	$r3, $r0, 48
	add	$r3, $r3, $r4
	outputb	$r3
	jr	$r29
bge_else.41871:
	addi	$r3, $r0, 45
	outputb	$r3
	sub	$r4, $r0, $r4
	j	print_int.2559

#---------------------------------------------------------------------
# args = [$r16]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
read_object.2727:
	addi	$r3, $r0, 60
	blt	$r16, $r3, ble_else.42106
	jr	$r29
ble_else.42106:
	addi	$r3, $r0, 0
	sti	$r3, $r0, 591
	addi	$r3, $r0, 0
	sti	$r3, $r0, 590
	inputb	$r5
	addi	$r14, $r0, 48
	blt	$r5, $r14, ble_else.42108
	addi	$r14, $r0, 57
	blt	$r14, $r5, ble_else.42110
	addi	$r14, $r0, 0
	j	ble_cont.42111
ble_else.42110:
	addi	$r14, $r0, 1
ble_cont.42111:
	j	ble_cont.42109
ble_else.42108:
	addi	$r14, $r0, 1
ble_cont.42109:
	beq	$r14, $r0, bne_else.42112
	addi	$r6, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_int_token.2525
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r14, $r3
	j	bne_cont.42113
bne_else.42112:
	ldi	$r3, $r0, 590
	beq	$r3, $r0, bne_else.42114
	j	bne_cont.42115
bne_else.42114:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 590
bne_cont.42115:
	ldi	$r3, $r0, 591
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 591
	addi	$r6, $r0, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_int_token.2525
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r14, $r3
bne_cont.42113:
	sti	$r16, $r1, 0
	beq	$r14, $r31, bne_else.42116
	addi	$r3, $r0, 0
	sti	$r3, $r0, 591
	addi	$r3, $r0, 0
	sti	$r3, $r0, 590
	inputb	$r5
	addi	$r11, $r0, 48
	blt	$r5, $r11, ble_else.42118
	addi	$r11, $r0, 57
	blt	$r11, $r5, ble_else.42120
	addi	$r11, $r0, 0
	j	ble_cont.42121
ble_else.42120:
	addi	$r11, $r0, 1
ble_cont.42121:
	j	ble_cont.42119
ble_else.42118:
	addi	$r11, $r0, 1
ble_cont.42119:
	beq	$r11, $r0, bne_else.42122
	addi	$r6, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_int_token.2525
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	mov	$r11, $r3
	j	bne_cont.42123
bne_else.42122:
	ldi	$r3, $r0, 590
	beq	$r3, $r0, bne_else.42124
	j	bne_cont.42125
bne_else.42124:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 590
bne_cont.42125:
	ldi	$r3, $r0, 591
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 591
	addi	$r6, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_int_token.2525
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	mov	$r11, $r3
bne_cont.42123:
	addi	$r3, $r0, 0
	sti	$r3, $r0, 591
	addi	$r3, $r0, 0
	sti	$r3, $r0, 590
	inputb	$r5
	addi	$r15, $r0, 48
	blt	$r5, $r15, ble_else.42126
	addi	$r15, $r0, 57
	blt	$r15, $r5, ble_else.42128
	addi	$r15, $r0, 0
	j	ble_cont.42129
ble_else.42128:
	addi	$r15, $r0, 1
ble_cont.42129:
	j	ble_cont.42127
ble_else.42126:
	addi	$r15, $r0, 1
ble_cont.42127:
	beq	$r15, $r0, bne_else.42130
	addi	$r6, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_int_token.2525
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	mov	$r15, $r3
	j	bne_cont.42131
bne_else.42130:
	ldi	$r3, $r0, 590
	beq	$r3, $r0, bne_else.42132
	j	bne_cont.42133
bne_else.42132:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 590
bne_cont.42133:
	ldi	$r3, $r0, 591
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 591
	addi	$r6, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_int_token.2525
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	mov	$r15, $r3
bne_cont.42131:
	addi	$r3, $r0, 0
	sti	$r3, $r0, 591
	addi	$r3, $r0, 0
	sti	$r3, $r0, 590
	inputb	$r5
	addi	$r13, $r0, 48
	blt	$r5, $r13, ble_else.42134
	addi	$r13, $r0, 57
	blt	$r13, $r5, ble_else.42136
	addi	$r13, $r0, 0
	j	ble_cont.42137
ble_else.42136:
	addi	$r13, $r0, 1
ble_cont.42137:
	j	ble_cont.42135
ble_else.42134:
	addi	$r13, $r0, 1
ble_cont.42135:
	beq	$r13, $r0, bne_else.42138
	addi	$r6, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_int_token.2525
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	mov	$r13, $r3
	j	bne_cont.42139
bne_else.42138:
	ldi	$r3, $r0, 590
	beq	$r3, $r0, bne_else.42140
	j	bne_cont.42141
bne_else.42140:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 590
bne_cont.42141:
	ldi	$r3, $r0, 591
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 591
	addi	$r6, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_int_token.2525
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	mov	$r13, $r3
bne_cont.42139:
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	min_caml_create_float_array
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	mov	$r8, $r3
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.42142
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.42144
	addi	$r3, $r0, 0
	j	ble_cont.42145
ble_else.42144:
	addi	$r3, $r0, 1
ble_cont.42145:
	j	ble_cont.42143
ble_else.42142:
	addi	$r3, $r0, 1
ble_cont.42143:
	beq	$r3, $r0, bne_else.42146
	addi	$r6, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42147
bne_else.42146:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.42148
	j	bne_cont.42149
bne_else.42148:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.42149:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42147:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.42150
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.42151
bne_else.42150:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.42152
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.42154
	addi	$r4, $r0, 0
	j	ble_cont.42155
ble_else.42154:
	addi	$r4, $r0, 1
ble_cont.42155:
	j	ble_cont.42153
ble_else.42152:
	addi	$r4, $r0, 1
ble_cont.42153:
	beq	$r4, $r0, bne_else.42156
	addi	$r4, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42157
bne_else.42156:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42157:
	ldi	$r3, $r0, 589
	itof	$f4, $r3
	ldi	$r3, $r0, 588
	itof	$f3, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f3, $f0
	fadd	$f0, $f4, $f0
bne_cont.42151:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.42158
	fneg	$f1, $f0
	j	bne_cont.42159
bne_else.42158:
	fmov	$f1, $f0
bne_cont.42159:
	fsti	$f1, $r8, 0
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.42160
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.42162
	addi	$r3, $r0, 0
	j	ble_cont.42163
ble_else.42162:
	addi	$r3, $r0, 1
ble_cont.42163:
	j	ble_cont.42161
ble_else.42160:
	addi	$r3, $r0, 1
ble_cont.42161:
	beq	$r3, $r0, bne_else.42164
	addi	$r6, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42165
bne_else.42164:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.42166
	j	bne_cont.42167
bne_else.42166:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.42167:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42165:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.42168
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.42169
bne_else.42168:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.42170
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.42172
	addi	$r4, $r0, 0
	j	ble_cont.42173
ble_else.42172:
	addi	$r4, $r0, 1
ble_cont.42173:
	j	ble_cont.42171
ble_else.42170:
	addi	$r4, $r0, 1
ble_cont.42171:
	beq	$r4, $r0, bne_else.42174
	addi	$r4, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42175
bne_else.42174:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42175:
	ldi	$r3, $r0, 589
	itof	$f4, $r3
	ldi	$r3, $r0, 588
	itof	$f3, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f3, $f0
	fadd	$f0, $f4, $f0
bne_cont.42169:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.42176
	fneg	$f1, $f0
	j	bne_cont.42177
bne_else.42176:
	fmov	$f1, $f0
bne_cont.42177:
	fsti	$f1, $r8, 1
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.42178
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.42180
	addi	$r3, $r0, 0
	j	ble_cont.42181
ble_else.42180:
	addi	$r3, $r0, 1
ble_cont.42181:
	j	ble_cont.42179
ble_else.42178:
	addi	$r3, $r0, 1
ble_cont.42179:
	beq	$r3, $r0, bne_else.42182
	addi	$r6, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42183
bne_else.42182:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.42184
	j	bne_cont.42185
bne_else.42184:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.42185:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42183:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.42186
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.42187
bne_else.42186:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.42188
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.42190
	addi	$r4, $r0, 0
	j	ble_cont.42191
ble_else.42190:
	addi	$r4, $r0, 1
ble_cont.42191:
	j	ble_cont.42189
ble_else.42188:
	addi	$r4, $r0, 1
ble_cont.42189:
	beq	$r4, $r0, bne_else.42192
	addi	$r4, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42193
bne_else.42192:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42193:
	ldi	$r3, $r0, 589
	itof	$f4, $r3
	ldi	$r3, $r0, 588
	itof	$f3, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f3, $f0
	fadd	$f0, $f4, $f0
bne_cont.42187:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.42194
	fneg	$f1, $f0
	j	bne_cont.42195
bne_else.42194:
	fmov	$f1, $f0
bne_cont.42195:
	fsti	$f1, $r8, 2
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	min_caml_create_float_array
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	mov	$r12, $r3
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.42196
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.42198
	addi	$r3, $r0, 0
	j	ble_cont.42199
ble_else.42198:
	addi	$r3, $r0, 1
ble_cont.42199:
	j	ble_cont.42197
ble_else.42196:
	addi	$r3, $r0, 1
ble_cont.42197:
	beq	$r3, $r0, bne_else.42200
	addi	$r6, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42201
bne_else.42200:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.42202
	j	bne_cont.42203
bne_else.42202:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.42203:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42201:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.42204
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.42205
bne_else.42204:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.42206
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.42208
	addi	$r4, $r0, 0
	j	ble_cont.42209
ble_else.42208:
	addi	$r4, $r0, 1
ble_cont.42209:
	j	ble_cont.42207
ble_else.42206:
	addi	$r4, $r0, 1
ble_cont.42207:
	beq	$r4, $r0, bne_else.42210
	addi	$r4, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42211
bne_else.42210:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42211:
	ldi	$r3, $r0, 589
	itof	$f4, $r3
	ldi	$r3, $r0, 588
	itof	$f3, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f3, $f0
	fadd	$f0, $f4, $f0
bne_cont.42205:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.42212
	fneg	$f1, $f0
	j	bne_cont.42213
bne_else.42212:
	fmov	$f1, $f0
bne_cont.42213:
	fsti	$f1, $r12, 0
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.42214
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.42216
	addi	$r3, $r0, 0
	j	ble_cont.42217
ble_else.42216:
	addi	$r3, $r0, 1
ble_cont.42217:
	j	ble_cont.42215
ble_else.42214:
	addi	$r3, $r0, 1
ble_cont.42215:
	beq	$r3, $r0, bne_else.42218
	addi	$r6, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42219
bne_else.42218:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.42220
	j	bne_cont.42221
bne_else.42220:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.42221:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42219:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.42222
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.42223
bne_else.42222:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.42224
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.42226
	addi	$r4, $r0, 0
	j	ble_cont.42227
ble_else.42226:
	addi	$r4, $r0, 1
ble_cont.42227:
	j	ble_cont.42225
ble_else.42224:
	addi	$r4, $r0, 1
ble_cont.42225:
	beq	$r4, $r0, bne_else.42228
	addi	$r4, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42229
bne_else.42228:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42229:
	ldi	$r3, $r0, 589
	itof	$f4, $r3
	ldi	$r3, $r0, 588
	itof	$f3, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f3, $f0
	fadd	$f0, $f4, $f0
bne_cont.42223:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.42230
	fneg	$f1, $f0
	j	bne_cont.42231
bne_else.42230:
	fmov	$f1, $f0
bne_cont.42231:
	fsti	$f1, $r12, 1
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.42232
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.42234
	addi	$r3, $r0, 0
	j	ble_cont.42235
ble_else.42234:
	addi	$r3, $r0, 1
ble_cont.42235:
	j	ble_cont.42233
ble_else.42232:
	addi	$r3, $r0, 1
ble_cont.42233:
	beq	$r3, $r0, bne_else.42236
	addi	$r6, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42237
bne_else.42236:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.42238
	j	bne_cont.42239
bne_else.42238:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.42239:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42237:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.42240
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.42241
bne_else.42240:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.42242
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.42244
	addi	$r4, $r0, 0
	j	ble_cont.42245
ble_else.42244:
	addi	$r4, $r0, 1
ble_cont.42245:
	j	ble_cont.42243
ble_else.42242:
	addi	$r4, $r0, 1
ble_cont.42243:
	beq	$r4, $r0, bne_else.42246
	addi	$r4, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42247
bne_else.42246:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42247:
	ldi	$r3, $r0, 589
	itof	$f4, $r3
	ldi	$r3, $r0, 588
	itof	$f3, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f3, $f0
	fadd	$f0, $f4, $f0
bne_cont.42241:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.42248
	fneg	$f1, $f0
	j	bne_cont.42249
bne_else.42248:
	fmov	$f1, $f0
bne_cont.42249:
	fsti	$f1, $r12, 2
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.42250
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.42252
	addi	$r3, $r0, 0
	j	ble_cont.42253
ble_else.42252:
	addi	$r3, $r0, 1
ble_cont.42253:
	j	ble_cont.42251
ble_else.42250:
	addi	$r3, $r0, 1
ble_cont.42251:
	beq	$r3, $r0, bne_else.42254
	addi	$r6, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42255
bne_else.42254:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.42256
	j	bne_cont.42257
bne_else.42256:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.42257:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42255:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.42258
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.42259
bne_else.42258:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.42260
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.42262
	addi	$r4, $r0, 0
	j	ble_cont.42263
ble_else.42262:
	addi	$r4, $r0, 1
ble_cont.42263:
	j	ble_cont.42261
ble_else.42260:
	addi	$r4, $r0, 1
ble_cont.42261:
	beq	$r4, $r0, bne_else.42264
	addi	$r4, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42265
bne_else.42264:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42265:
	ldi	$r3, $r0, 589
	itof	$f4, $r3
	ldi	$r3, $r0, 588
	itof	$f3, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f3, $f0
	fadd	$f0, $f4, $f0
bne_cont.42259:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.42266
	fneg	$f4, $f0
	j	bne_cont.42267
bne_else.42266:
	fmov	$f4, $f0
bne_cont.42267:
	addi	$r3, $r0, 2
	fmov	$f0, $f16
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	min_caml_create_float_array
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	mov	$r10, $r3
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.42268
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.42270
	addi	$r3, $r0, 0
	j	ble_cont.42271
ble_else.42270:
	addi	$r3, $r0, 1
ble_cont.42271:
	j	ble_cont.42269
ble_else.42268:
	addi	$r3, $r0, 1
ble_cont.42269:
	beq	$r3, $r0, bne_else.42272
	addi	$r6, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42273
bne_else.42272:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.42274
	j	bne_cont.42275
bne_else.42274:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.42275:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42273:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.42276
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.42277
bne_else.42276:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.42278
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.42280
	addi	$r4, $r0, 0
	j	ble_cont.42281
ble_else.42280:
	addi	$r4, $r0, 1
ble_cont.42281:
	j	ble_cont.42279
ble_else.42278:
	addi	$r4, $r0, 1
ble_cont.42279:
	beq	$r4, $r0, bne_else.42282
	addi	$r4, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42283
bne_else.42282:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42283:
	ldi	$r3, $r0, 589
	itof	$f5, $r3
	ldi	$r3, $r0, 588
	itof	$f3, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f3, $f0
	fadd	$f0, $f5, $f0
bne_cont.42277:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.42284
	fneg	$f1, $f0
	j	bne_cont.42285
bne_else.42284:
	fmov	$f1, $f0
bne_cont.42285:
	fsti	$f1, $r10, 0
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.42286
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.42288
	addi	$r3, $r0, 0
	j	ble_cont.42289
ble_else.42288:
	addi	$r3, $r0, 1
ble_cont.42289:
	j	ble_cont.42287
ble_else.42286:
	addi	$r3, $r0, 1
ble_cont.42287:
	beq	$r3, $r0, bne_else.42290
	addi	$r6, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42291
bne_else.42290:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.42292
	j	bne_cont.42293
bne_else.42292:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.42293:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42291:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.42294
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.42295
bne_else.42294:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.42296
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.42298
	addi	$r4, $r0, 0
	j	ble_cont.42299
ble_else.42298:
	addi	$r4, $r0, 1
ble_cont.42299:
	j	ble_cont.42297
ble_else.42296:
	addi	$r4, $r0, 1
ble_cont.42297:
	beq	$r4, $r0, bne_else.42300
	addi	$r4, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42301
bne_else.42300:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42301:
	ldi	$r3, $r0, 589
	itof	$f5, $r3
	ldi	$r3, $r0, 588
	itof	$f3, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f3, $f0
	fadd	$f0, $f5, $f0
bne_cont.42295:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.42302
	fneg	$f1, $f0
	j	bne_cont.42303
bne_else.42302:
	fmov	$f1, $f0
bne_cont.42303:
	fsti	$f1, $r10, 1
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	min_caml_create_float_array
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	mov	$r9, $r3
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.42304
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.42306
	addi	$r3, $r0, 0
	j	ble_cont.42307
ble_else.42306:
	addi	$r3, $r0, 1
ble_cont.42307:
	j	ble_cont.42305
ble_else.42304:
	addi	$r3, $r0, 1
ble_cont.42305:
	beq	$r3, $r0, bne_else.42308
	addi	$r6, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42309
bne_else.42308:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.42310
	j	bne_cont.42311
bne_else.42310:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.42311:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42309:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.42312
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.42313
bne_else.42312:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.42314
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.42316
	addi	$r4, $r0, 0
	j	ble_cont.42317
ble_else.42316:
	addi	$r4, $r0, 1
ble_cont.42317:
	j	ble_cont.42315
ble_else.42314:
	addi	$r4, $r0, 1
ble_cont.42315:
	beq	$r4, $r0, bne_else.42318
	addi	$r4, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42319
bne_else.42318:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42319:
	ldi	$r3, $r0, 589
	itof	$f5, $r3
	ldi	$r3, $r0, 588
	itof	$f3, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f3, $f0
	fadd	$f0, $f5, $f0
bne_cont.42313:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.42320
	fneg	$f1, $f0
	j	bne_cont.42321
bne_else.42320:
	fmov	$f1, $f0
bne_cont.42321:
	fsti	$f1, $r9, 0
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.42322
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.42324
	addi	$r3, $r0, 0
	j	ble_cont.42325
ble_else.42324:
	addi	$r3, $r0, 1
ble_cont.42325:
	j	ble_cont.42323
ble_else.42322:
	addi	$r3, $r0, 1
ble_cont.42323:
	beq	$r3, $r0, bne_else.42326
	addi	$r6, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42327
bne_else.42326:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.42328
	j	bne_cont.42329
bne_else.42328:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.42329:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42327:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.42330
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.42331
bne_else.42330:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.42332
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.42334
	addi	$r4, $r0, 0
	j	ble_cont.42335
ble_else.42334:
	addi	$r4, $r0, 1
ble_cont.42335:
	j	ble_cont.42333
ble_else.42332:
	addi	$r4, $r0, 1
ble_cont.42333:
	beq	$r4, $r0, bne_else.42336
	addi	$r4, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42337
bne_else.42336:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42337:
	ldi	$r3, $r0, 589
	itof	$f5, $r3
	ldi	$r3, $r0, 588
	itof	$f3, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f3, $f0
	fadd	$f0, $f5, $f0
bne_cont.42331:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.42338
	fneg	$f1, $f0
	j	bne_cont.42339
bne_else.42338:
	fmov	$f1, $f0
bne_cont.42339:
	fsti	$f1, $r9, 1
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.42340
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.42342
	addi	$r3, $r0, 0
	j	ble_cont.42343
ble_else.42342:
	addi	$r3, $r0, 1
ble_cont.42343:
	j	ble_cont.42341
ble_else.42340:
	addi	$r3, $r0, 1
ble_cont.42341:
	beq	$r3, $r0, bne_else.42344
	addi	$r6, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42345
bne_else.42344:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.42346
	j	bne_cont.42347
bne_else.42346:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.42347:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42345:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.42348
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.42349
bne_else.42348:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.42350
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.42352
	addi	$r4, $r0, 0
	j	ble_cont.42353
ble_else.42352:
	addi	$r4, $r0, 1
ble_cont.42353:
	j	ble_cont.42351
ble_else.42350:
	addi	$r4, $r0, 1
ble_cont.42351:
	beq	$r4, $r0, bne_else.42354
	addi	$r4, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42355
bne_else.42354:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42355:
	ldi	$r3, $r0, 589
	itof	$f5, $r3
	ldi	$r3, $r0, 588
	itof	$f3, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f3, $f0
	fadd	$f0, $f5, $f0
bne_cont.42349:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.42356
	fneg	$f1, $f0
	j	bne_cont.42357
bne_else.42356:
	fmov	$f1, $f0
bne_cont.42357:
	fsti	$f1, $r9, 2
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	min_caml_create_float_array
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	mov	$r7, $r3
	beq	$r13, $r0, bne_else.42358
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.42360
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.42362
	addi	$r3, $r0, 0
	j	ble_cont.42363
ble_else.42362:
	addi	$r3, $r0, 1
ble_cont.42363:
	j	ble_cont.42361
ble_else.42360:
	addi	$r3, $r0, 1
ble_cont.42361:
	beq	$r3, $r0, bne_else.42364
	addi	$r6, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42365
bne_else.42364:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.42366
	j	bne_cont.42367
bne_else.42366:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.42367:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42365:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.42368
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.42369
bne_else.42368:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.42370
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.42372
	addi	$r4, $r0, 0
	j	ble_cont.42373
ble_else.42372:
	addi	$r4, $r0, 1
ble_cont.42373:
	j	ble_cont.42371
ble_else.42370:
	addi	$r4, $r0, 1
ble_cont.42371:
	beq	$r4, $r0, bne_else.42374
	addi	$r4, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42375
bne_else.42374:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42375:
	ldi	$r3, $r0, 589
	itof	$f5, $r3
	ldi	$r3, $r0, 588
	itof	$f3, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f3, $f0
	fadd	$f0, $f5, $f0
bne_cont.42369:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.42376
	fneg	$f1, $f0
	j	bne_cont.42377
bne_else.42376:
	fmov	$f1, $f0
bne_cont.42377:
	# 0.017453
	fmvhi	$f3, 15502
	fmvlo	$f3, 64045
	fmul	$f0, $f1, $f3
	fsti	$f0, $r7, 0
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.42378
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.42380
	addi	$r3, $r0, 0
	j	ble_cont.42381
ble_else.42380:
	addi	$r3, $r0, 1
ble_cont.42381:
	j	ble_cont.42379
ble_else.42378:
	addi	$r3, $r0, 1
ble_cont.42379:
	beq	$r3, $r0, bne_else.42382
	addi	$r6, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42383
bne_else.42382:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.42384
	j	bne_cont.42385
bne_else.42384:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.42385:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42383:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.42386
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.42387
bne_else.42386:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.42388
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.42390
	addi	$r4, $r0, 0
	j	ble_cont.42391
ble_else.42390:
	addi	$r4, $r0, 1
ble_cont.42391:
	j	ble_cont.42389
ble_else.42388:
	addi	$r4, $r0, 1
ble_cont.42389:
	beq	$r4, $r0, bne_else.42392
	addi	$r4, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42393
bne_else.42392:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42393:
	ldi	$r3, $r0, 589
	itof	$f6, $r3
	ldi	$r3, $r0, 588
	itof	$f5, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f5, $f0
	fadd	$f0, $f6, $f0
bne_cont.42387:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.42394
	fneg	$f1, $f0
	j	bne_cont.42395
bne_else.42394:
	fmov	$f1, $f0
bne_cont.42395:
	fmul	$f0, $f1, $f3
	fsti	$f0, $r7, 1
	addi	$r3, $r0, 0
	sti	$r3, $r0, 589
	addi	$r3, $r0, 0
	sti	$r3, $r0, 588
	addi	$r3, $r0, 1
	sti	$r3, $r0, 587
	addi	$r3, $r0, 0
	sti	$r3, $r0, 586
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.42396
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.42398
	addi	$r3, $r0, 0
	j	ble_cont.42399
ble_else.42398:
	addi	$r3, $r0, 1
ble_cont.42399:
	j	ble_cont.42397
ble_else.42396:
	addi	$r3, $r0, 1
ble_cont.42397:
	beq	$r3, $r0, bne_else.42400
	addi	$r6, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42401
bne_else.42400:
	ldi	$r3, $r0, 586
	beq	$r3, $r0, bne_else.42402
	j	bne_cont.42403
bne_else.42402:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 586
bne_cont.42403:
	ldi	$r3, $r0, 589
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 589
	addi	$r6, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token1.2534
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42401:
	addi	$r4, $r0, 46
	beq	$r3, $r4, bne_else.42404
	ldi	$r3, $r0, 589
	itof	$f0, $r3
	j	bne_cont.42405
bne_else.42404:
	inputb	$r3
	addi	$r4, $r0, 48
	blt	$r3, $r4, ble_else.42406
	addi	$r4, $r0, 57
	blt	$r4, $r3, ble_else.42408
	addi	$r4, $r0, 0
	j	ble_cont.42409
ble_else.42408:
	addi	$r4, $r0, 1
ble_cont.42409:
	j	ble_cont.42407
ble_else.42406:
	addi	$r4, $r0, 1
ble_cont.42407:
	beq	$r4, $r0, bne_else.42410
	addi	$r4, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42411
bne_else.42410:
	ldi	$r4, $r0, 588
	slli	$r5, $r4, 3
	slli	$r4, $r4, 1
	add	$r4, $r5, $r4
	subi	$r3, $r3, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 588
	ldi	$r3, $r0, 587
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r3, $r4, $r3
	sti	$r3, $r0, 587
	addi	$r4, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_float_token2.2537
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42411:
	ldi	$r3, $r0, 589
	itof	$f6, $r3
	ldi	$r3, $r0, 588
	itof	$f5, $r3
	ldi	$r3, $r0, 587
	itof	$f0, $r3
	fdiv	$f0, $f5, $f0
	fadd	$f0, $f6, $f0
bne_cont.42405:
	ldi	$r3, $r0, 586
	beq	$r3, $r30, bne_else.42412
	fneg	$f1, $f0
	j	bne_cont.42413
bne_else.42412:
	fmov	$f1, $f0
bne_cont.42413:
	fmul	$f0, $f1, $f3
	fsti	$f0, $r7, 2
	j	bne_cont.42359
bne_else.42358:
bne_cont.42359:
	addi	$r5, $r0, 2
	beq	$r11, $r5, bne_else.42414
	fblt	$f4, $f16, fbge_else.42416
	addi	$r5, $r0, 0
	j	fbge_cont.42417
fbge_else.42416:
	addi	$r5, $r0, 1
fbge_cont.42417:
	j	bne_cont.42415
bne_else.42414:
	addi	$r5, $r0, 1
bne_cont.42415:
	addi	$r3, $r0, 4
	fmov	$f0, $f16
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	min_caml_create_float_array
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	mov	$r4, $r3
	mov	$r3, $r2
	addi	$r2, $r2, 11
	sti	$r4, $r3, 10
	sti	$r7, $r3, 9
	sti	$r9, $r3, 8
	sti	$r10, $r3, 7
	sti	$r5, $r3, 6
	sti	$r12, $r3, 5
	sti	$r8, $r3, 4
	sti	$r13, $r3, 3
	sti	$r15, $r3, 2
	sti	$r11, $r3, 1
	sti	$r14, $r3, 0
	slli	$r4, $r16, 0
	sti	$r3, $r4, 524
	addi	$r3, $r0, 3
	beq	$r11, $r3, bne_else.42418
	addi	$r3, $r0, 2
	beq	$r11, $r3, bne_else.42420
	j	bne_cont.42421
bne_else.42420:
	fldi	$f2, $r8, 0
	fmul	$f1, $f2, $f2
	fldi	$f0, $r8, 1
	fmul	$f0, $f0, $f0
	fadd	$f1, $f1, $f0
	fldi	$f0, $r8, 2
	fmul	$f0, $f0, $f0
	fadd	$f0, $f1, $f0
	fsqrt	$f1, $f0
	fbeq	$f1, $f16, fbne_else.42422
	fblt	$f4, $f16, fbge_else.42424
	fdiv	$f0, $f19, $f1
	j	fbge_cont.42425
fbge_else.42424:
	fdiv	$f0, $f17, $f1
fbge_cont.42425:
	j	fbne_cont.42423
fbne_else.42422:
	fmov	$f0, $f17
fbne_cont.42423:
	fmul	$f1, $f2, $f0
	fsti	$f1, $r8, 0
	fldi	$f1, $r8, 1
	fmul	$f1, $f1, $f0
	fsti	$f1, $r8, 1
	fldi	$f1, $r8, 2
	fmul	$f0, $f1, $f0
	fsti	$f0, $r8, 2
bne_cont.42421:
	j	bne_cont.42419
bne_else.42418:
	fldi	$f1, $r8, 0
	fbeq	$f1, $f16, fbne_else.42426
	fbeq	$f1, $f16, fbne_else.42428
	fblt	$f16, $f1, fbge_else.42430
	fmov	$f0, $f19
	j	fbge_cont.42431
fbge_else.42430:
	fmov	$f0, $f17
fbge_cont.42431:
	j	fbne_cont.42429
fbne_else.42428:
	fmov	$f0, $f16
fbne_cont.42429:
	fmul	$f1, $f1, $f1
	fdiv	$f0, $f0, $f1
	j	fbne_cont.42427
fbne_else.42426:
	fmov	$f0, $f16
fbne_cont.42427:
	fsti	$f0, $r8, 0
	fldi	$f1, $r8, 1
	fbeq	$f1, $f16, fbne_else.42432
	fbeq	$f1, $f16, fbne_else.42434
	fblt	$f16, $f1, fbge_else.42436
	fmov	$f0, $f19
	j	fbge_cont.42437
fbge_else.42436:
	fmov	$f0, $f17
fbge_cont.42437:
	j	fbne_cont.42435
fbne_else.42434:
	fmov	$f0, $f16
fbne_cont.42435:
	fmul	$f1, $f1, $f1
	fdiv	$f0, $f0, $f1
	j	fbne_cont.42433
fbne_else.42432:
	fmov	$f0, $f16
fbne_cont.42433:
	fsti	$f0, $r8, 1
	fldi	$f1, $r8, 2
	fbeq	$f1, $f16, fbne_else.42438
	fbeq	$f1, $f16, fbne_else.42440
	fblt	$f16, $f1, fbge_else.42442
	fmov	$f0, $f19
	j	fbge_cont.42443
fbge_else.42442:
	fmov	$f0, $f17
fbge_cont.42443:
	j	fbne_cont.42441
fbne_else.42440:
	fmov	$f0, $f16
fbne_cont.42441:
	fmul	$f1, $f1, $f1
	fdiv	$f0, $f0, $f1
	j	fbne_cont.42439
fbne_else.42438:
	fmov	$f0, $f16
fbne_cont.42439:
	fsti	$f0, $r8, 2
bne_cont.42419:
	beq	$r13, $r0, bne_else.42444
	fldi	$f0, $r7, 0
	sti	$r8, $r1, -1
	sti	$r7, $r1, -2
	fsti	$f0, $r1, -3
	fcos	$f4, $f0
	fldi	$f0, $r1, -3
	fsti	$f4, $r1, -4
	fsin	$f2, $f0
	ldi	$r7, $r1, -2
	fldi	$f0, $r7, 1
	fsti	$f2, $r1, -5
	fsti	$f0, $r1, -6
	fcos	$f3, $f0
	fldi	$f0, $r1, -6
	fsti	$f3, $r1, -7
	fsin	$f6, $f0
	ldi	$r7, $r1, -2
	fldi	$f0, $r7, 2
	fsti	$f6, $r1, -8
	fsti	$f0, $r1, -9
	fcos	$f1, $f0
	fldi	$f0, $r1, -9
	fsti	$f1, $r1, -10
	fsin	$f0, $f0
	fldi	$f1, $r1, -10
	fldi	$f3, $r1, -7
	fmul	$f13, $f3, $f1
	fldi	$f6, $r1, -8
	fldi	$f2, $r1, -5
	fmul	$f9, $f2, $f6
	fmul	$f7, $f9, $f1
	fldi	$f4, $r1, -4
	fmul	$f5, $f4, $f0
	fsub	$f11, $f7, $f5
	fmul	$f5, $f4, $f6
	fmul	$f8, $f5, $f1
	fmul	$f7, $f2, $f0
	fadd	$f8, $f8, $f7
	fmul	$f12, $f3, $f0
	fmul	$f9, $f9, $f0
	fmul	$f7, $f4, $f1
	fadd	$f9, $f9, $f7
	fmul	$f5, $f5, $f0
	fmul	$f0, $f2, $f1
	fsub	$f7, $f5, $f0
	fneg	$f10, $f6
	fmul	$f6, $f2, $f3
	fmul	$f5, $f4, $f3
	ldi	$r8, $r1, -1
	fldi	$f0, $r8, 0
	fldi	$f2, $r8, 1
	fldi	$f3, $r8, 2
	fmul	$f1, $f13, $f13
	fmul	$f4, $f0, $f1
	fmul	$f1, $f12, $f12
	fmul	$f1, $f2, $f1
	fadd	$f4, $f4, $f1
	fmul	$f1, $f10, $f10
	fmul	$f1, $f3, $f1
	fadd	$f1, $f4, $f1
	fsti	$f1, $r8, 0
	fmul	$f1, $f11, $f11
	fmul	$f4, $f0, $f1
	fmul	$f1, $f9, $f9
	fmul	$f1, $f2, $f1
	fadd	$f4, $f4, $f1
	fmul	$f1, $f6, $f6
	fmul	$f1, $f3, $f1
	fadd	$f1, $f4, $f1
	fsti	$f1, $r8, 1
	fmul	$f1, $f8, $f8
	fmul	$f4, $f0, $f1
	fmul	$f1, $f7, $f7
	fmul	$f1, $f2, $f1
	fadd	$f4, $f4, $f1
	fmul	$f1, $f5, $f5
	fmul	$f1, $f3, $f1
	fadd	$f1, $f4, $f1
	fsti	$f1, $r8, 2
	# 2.000000
	fmvhi	$f4, 16384
	fmvlo	$f4, 0
	fmul	$f1, $f0, $f11
	fmul	$f14, $f1, $f8
	fmul	$f1, $f2, $f9
	fmul	$f1, $f1, $f7
	fadd	$f14, $f14, $f1
	fmul	$f1, $f3, $f6
	fmul	$f1, $f1, $f5
	fadd	$f1, $f14, $f1
	fmul	$f1, $f4, $f1
	ldi	$r7, $r1, -2
	fsti	$f1, $r7, 0
	fmul	$f1, $f0, $f13
	fmul	$f8, $f1, $f8
	fmul	$f0, $f2, $f12
	fmul	$f2, $f0, $f7
	fadd	$f7, $f8, $f2
	fmul	$f3, $f3, $f10
	fmul	$f2, $f3, $f5
	fadd	$f2, $f7, $f2
	fmul	$f2, $f4, $f2
	fsti	$f2, $r7, 1
	fmul	$f1, $f1, $f11
	fmul	$f0, $f0, $f9
	fadd	$f1, $f1, $f0
	fmul	$f0, $f3, $f6
	fadd	$f0, $f1, $f0
	fmul	$f0, $f4, $f0
	fsti	$f0, $r7, 2
	j	bne_cont.42445
bne_else.42444:
bne_cont.42445:
	addi	$r3, $r0, 1
	j	bne_cont.42117
bne_else.42116:
	addi	$r3, $r0, 0
bne_cont.42117:
	beq	$r3, $r0, bne_else.42446
	ldi	$r16, $r1, 0
	addi	$r16, $r16, 1
	j	read_object.2727
bne_else.42446:
	ldi	$r16, $r1, 0
	sti	$r16, $r0, 585
	jr	$r29

#---------------------------------------------------------------------
# args = [$r8]
# fargs = []
# ret type = Array(Int)
#---------------------------------------------------------------------
read_net_item.2731:
	addi	$r3, $r0, 0
	sti	$r3, $r0, 591
	addi	$r3, $r0, 0
	sti	$r3, $r0, 590
	inputb	$r4
	addi	$r7, $r0, 48
	blt	$r4, $r7, ble_else.42448
	addi	$r7, $r0, 57
	blt	$r7, $r4, ble_else.42450
	addi	$r7, $r0, 0
	j	ble_cont.42451
ble_else.42450:
	addi	$r7, $r0, 1
ble_cont.42451:
	j	ble_cont.42449
ble_else.42448:
	addi	$r7, $r0, 1
ble_cont.42449:
	beq	$r7, $r0, bne_else.42452
	inputb	$r5
	addi	$r7, $r0, 48
	blt	$r5, $r7, ble_else.42454
	addi	$r7, $r0, 57
	blt	$r7, $r5, ble_else.42456
	addi	$r7, $r0, 0
	j	ble_cont.42457
ble_else.42456:
	addi	$r7, $r0, 1
ble_cont.42457:
	j	ble_cont.42455
ble_else.42454:
	addi	$r7, $r0, 1
ble_cont.42455:
	beq	$r7, $r0, bne_else.42458
	addi	$r6, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_int_token.2525
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r7, $r3
	j	bne_cont.42459
bne_else.42458:
	ldi	$r3, $r0, 590
	beq	$r3, $r0, bne_else.42460
	j	bne_cont.42461
bne_else.42460:
	addi	$r3, $r0, 45
	beq	$r4, $r3, bne_else.42462
	addi	$r3, $r0, 1
	sti	$r3, $r0, 590
	j	bne_cont.42463
bne_else.42462:
	addi	$r3, $r0, -1
	sti	$r3, $r0, 590
bne_cont.42463:
bne_cont.42461:
	ldi	$r3, $r0, 591
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 591
	addi	$r6, $r0, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_int_token.2525
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r7, $r3
bne_cont.42459:
	j	bne_cont.42453
bne_else.42452:
	ldi	$r3, $r0, 590
	beq	$r3, $r0, bne_else.42464
	j	bne_cont.42465
bne_else.42464:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 590
bne_cont.42465:
	ldi	$r3, $r0, 591
	slli	$r5, $r3, 3
	slli	$r3, $r3, 1
	add	$r5, $r5, $r3
	subi	$r3, $r4, 48
	add	$r3, $r5, $r3
	sti	$r3, $r0, 591
	inputb	$r5
	addi	$r7, $r0, 48
	blt	$r5, $r7, ble_else.42466
	addi	$r7, $r0, 57
	blt	$r7, $r5, ble_else.42468
	addi	$r7, $r0, 0
	j	ble_cont.42469
ble_else.42468:
	addi	$r7, $r0, 1
ble_cont.42469:
	j	ble_cont.42467
ble_else.42466:
	addi	$r7, $r0, 1
ble_cont.42467:
	beq	$r7, $r0, bne_else.42470
	ldi	$r7, $r0, 590
	beq	$r7, $r30, bne_else.42472
	ldi	$r7, $r0, 591
	sub	$r7, $r0, $r7
	j	bne_cont.42473
bne_else.42472:
	ldi	$r7, $r0, 591
bne_cont.42473:
	j	bne_cont.42471
bne_else.42470:
	ldi	$r3, $r0, 590
	beq	$r3, $r0, bne_else.42474
	j	bne_cont.42475
bne_else.42474:
	addi	$r3, $r0, 45
	beq	$r4, $r3, bne_else.42476
	addi	$r3, $r0, 1
	sti	$r3, $r0, 590
	j	bne_cont.42477
bne_else.42476:
	addi	$r3, $r0, -1
	sti	$r3, $r0, 590
bne_cont.42477:
bne_cont.42475:
	ldi	$r3, $r0, 591
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 591
	addi	$r6, $r0, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_int_token.2525
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r7, $r3
bne_cont.42471:
bne_cont.42453:
	beq	$r7, $r31, bne_else.42478
	addi	$r9, $r8, 1
	addi	$r3, $r0, 0
	sti	$r3, $r0, 591
	addi	$r3, $r0, 0
	sti	$r3, $r0, 590
	inputb	$r5
	addi	$r4, $r0, 48
	blt	$r5, $r4, ble_else.42479
	addi	$r4, $r0, 57
	blt	$r4, $r5, ble_else.42481
	addi	$r4, $r0, 0
	j	ble_cont.42482
ble_else.42481:
	addi	$r4, $r0, 1
ble_cont.42482:
	j	ble_cont.42480
ble_else.42479:
	addi	$r4, $r0, 1
ble_cont.42480:
	beq	$r4, $r0, bne_else.42483
	addi	$r6, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_int_token.2525
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r4, $r3
	j	bne_cont.42484
bne_else.42483:
	ldi	$r3, $r0, 590
	beq	$r3, $r0, bne_else.42485
	j	bne_cont.42486
bne_else.42485:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 590
bne_cont.42486:
	ldi	$r3, $r0, 591
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 591
	addi	$r6, $r0, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_int_token.2525
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r4, $r3
bne_cont.42484:
	sti	$r7, $r1, 0
	sti	$r8, $r1, -1
	beq	$r4, $r31, bne_else.42487
	addi	$r3, $r9, 1
	sti	$r4, $r1, -2
	sti	$r9, $r1, -3
	mov	$r8, $r3
	sti	$r29, $r1, -5
	subi	$r1, $r1, 6
	jal	read_net_item.2731
	addi	$r1, $r1, 6
	ldi	$r29, $r1, -5
	ldi	$r9, $r1, -3
	slli	$r5, $r9, 0
	ldi	$r4, $r1, -2
	str	$r4, $r3, $r5
	j	bne_cont.42488
bne_else.42487:
	addi	$r3, $r9, 1
	addi	$r4, $r0, -1
	sti	$r29, $r1, -3
	subi	$r1, $r1, 4
	jal	min_caml_create_array
	addi	$r1, $r1, 4
	ldi	$r29, $r1, -3
bne_cont.42488:
	ldi	$r8, $r1, -1
	slli	$r4, $r8, 0
	ldi	$r7, $r1, 0
	str	$r7, $r3, $r4
	jr	$r29
bne_else.42478:
	addi	$r3, $r8, 1
	addi	$r4, $r0, -1
	j	min_caml_create_array

#---------------------------------------------------------------------
# args = [$r11]
# fargs = []
# ret type = Array(Array(Int))
#---------------------------------------------------------------------
read_or_network.2733:
	addi	$r3, $r0, 0
	sti	$r3, $r0, 591
	addi	$r3, $r0, 0
	sti	$r3, $r0, 590
	inputb	$r5
	addi	$r3, $r0, 48
	blt	$r5, $r3, ble_else.42489
	addi	$r3, $r0, 57
	blt	$r3, $r5, ble_else.42491
	addi	$r3, $r0, 0
	j	ble_cont.42492
ble_else.42491:
	addi	$r3, $r0, 1
ble_cont.42492:
	j	ble_cont.42490
ble_else.42489:
	addi	$r3, $r0, 1
ble_cont.42490:
	beq	$r3, $r0, bne_else.42493
	addi	$r6, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_int_token.2525
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	j	bne_cont.42494
bne_else.42493:
	ldi	$r3, $r0, 590
	beq	$r3, $r0, bne_else.42495
	j	bne_cont.42496
bne_else.42495:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 590
bne_cont.42496:
	ldi	$r3, $r0, 591
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 591
	addi	$r6, $r0, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_int_token.2525
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
bne_cont.42494:
	beq	$r3, $r31, bne_else.42497
	addi	$r8, $r0, 1
	sti	$r3, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_net_item.2731
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	mov	$r5, $r3
	ldi	$r3, $r1, 0
	sti	$r3, $r5, 0
	j	bne_cont.42498
bne_else.42497:
	addi	$r3, $r0, 1
	addi	$r4, $r0, -1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r5, $r3
bne_cont.42498:
	ldi	$r3, $r5, 0
	beq	$r3, $r31, bne_else.42499
	addi	$r10, $r11, 1
	addi	$r3, $r0, 0
	sti	$r3, $r0, 591
	addi	$r3, $r0, 0
	sti	$r3, $r0, 590
	inputb	$r7
	addi	$r3, $r0, 48
	blt	$r7, $r3, ble_else.42500
	addi	$r3, $r0, 57
	blt	$r3, $r7, ble_else.42502
	addi	$r3, $r0, 0
	j	ble_cont.42503
ble_else.42502:
	addi	$r3, $r0, 1
ble_cont.42503:
	j	ble_cont.42501
ble_else.42500:
	addi	$r3, $r0, 1
ble_cont.42501:
	sti	$r5, $r1, 0
	beq	$r3, $r0, bne_else.42504
	addi	$r6, $r0, 0
	mov	$r5, $r7
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_int_token.2525
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.42505
bne_else.42504:
	ldi	$r3, $r0, 590
	beq	$r3, $r0, bne_else.42506
	j	bne_cont.42507
bne_else.42506:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 590
bne_cont.42507:
	ldi	$r3, $r0, 591
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r7, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 591
	addi	$r6, $r0, 1
	mov	$r5, $r7
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	read_int_token.2525
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42505:
	beq	$r3, $r31, bne_else.42508
	addi	$r8, $r0, 1
	sti	$r3, $r1, -1
	sti	$r29, $r1, -3
	subi	$r1, $r1, 4
	jal	read_net_item.2731
	addi	$r1, $r1, 4
	ldi	$r29, $r1, -3
	mov	$r4, $r3
	ldi	$r3, $r1, -1
	sti	$r3, $r4, 0
	j	bne_cont.42509
bne_else.42508:
	addi	$r3, $r0, 1
	addi	$r4, $r0, -1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	min_caml_create_array
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	mov	$r4, $r3
bne_cont.42509:
	ldi	$r3, $r4, 0
	sti	$r11, $r1, -1
	beq	$r3, $r31, bne_else.42510
	addi	$r3, $r10, 1
	sti	$r4, $r1, -2
	sti	$r10, $r1, -3
	mov	$r11, $r3
	sti	$r29, $r1, -5
	subi	$r1, $r1, 6
	jal	read_or_network.2733
	addi	$r1, $r1, 6
	ldi	$r29, $r1, -5
	ldi	$r10, $r1, -3
	slli	$r6, $r10, 0
	ldi	$r4, $r1, -2
	str	$r4, $r3, $r6
	j	bne_cont.42511
bne_else.42510:
	addi	$r3, $r10, 1
	sti	$r29, $r1, -3
	subi	$r1, $r1, 4
	jal	min_caml_create_array
	addi	$r1, $r1, 4
	ldi	$r29, $r1, -3
bne_cont.42511:
	ldi	$r11, $r1, -1
	slli	$r4, $r11, 0
	ldi	$r5, $r1, 0
	str	$r5, $r3, $r4
	jr	$r29
bne_else.42499:
	addi	$r3, $r11, 1
	mov	$r4, $r5
	j	min_caml_create_array

#---------------------------------------------------------------------
# args = [$r11]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
read_and_network.2735:
	addi	$r3, $r0, 0
	sti	$r3, $r0, 591
	addi	$r3, $r0, 0
	sti	$r3, $r0, 590
	inputb	$r4
	addi	$r10, $r0, 48
	blt	$r4, $r10, ble_else.42512
	addi	$r10, $r0, 57
	blt	$r10, $r4, ble_else.42514
	addi	$r10, $r0, 0
	j	ble_cont.42515
ble_else.42514:
	addi	$r10, $r0, 1
ble_cont.42515:
	j	ble_cont.42513
ble_else.42512:
	addi	$r10, $r0, 1
ble_cont.42513:
	beq	$r10, $r0, bne_else.42516
	inputb	$r5
	addi	$r10, $r0, 48
	blt	$r5, $r10, ble_else.42518
	addi	$r10, $r0, 57
	blt	$r10, $r5, ble_else.42520
	addi	$r10, $r0, 0
	j	ble_cont.42521
ble_else.42520:
	addi	$r10, $r0, 1
ble_cont.42521:
	j	ble_cont.42519
ble_else.42518:
	addi	$r10, $r0, 1
ble_cont.42519:
	beq	$r10, $r0, bne_else.42522
	addi	$r6, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_int_token.2525
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r10, $r3
	j	bne_cont.42523
bne_else.42522:
	ldi	$r3, $r0, 590
	beq	$r3, $r0, bne_else.42524
	j	bne_cont.42525
bne_else.42524:
	addi	$r3, $r0, 45
	beq	$r4, $r3, bne_else.42526
	addi	$r3, $r0, 1
	sti	$r3, $r0, 590
	j	bne_cont.42527
bne_else.42526:
	addi	$r3, $r0, -1
	sti	$r3, $r0, 590
bne_cont.42527:
bne_cont.42525:
	ldi	$r3, $r0, 591
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 591
	addi	$r6, $r0, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_int_token.2525
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r10, $r3
bne_cont.42523:
	j	bne_cont.42517
bne_else.42516:
	ldi	$r3, $r0, 590
	beq	$r3, $r0, bne_else.42528
	j	bne_cont.42529
bne_else.42528:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 590
bne_cont.42529:
	ldi	$r3, $r0, 591
	slli	$r5, $r3, 3
	slli	$r3, $r3, 1
	add	$r5, $r5, $r3
	subi	$r3, $r4, 48
	add	$r3, $r5, $r3
	sti	$r3, $r0, 591
	inputb	$r5
	addi	$r10, $r0, 48
	blt	$r5, $r10, ble_else.42530
	addi	$r10, $r0, 57
	blt	$r10, $r5, ble_else.42532
	addi	$r10, $r0, 0
	j	ble_cont.42533
ble_else.42532:
	addi	$r10, $r0, 1
ble_cont.42533:
	j	ble_cont.42531
ble_else.42530:
	addi	$r10, $r0, 1
ble_cont.42531:
	beq	$r10, $r0, bne_else.42534
	ldi	$r10, $r0, 590
	beq	$r10, $r30, bne_else.42536
	ldi	$r10, $r0, 591
	sub	$r10, $r0, $r10
	j	bne_cont.42537
bne_else.42536:
	ldi	$r10, $r0, 591
bne_cont.42537:
	j	bne_cont.42535
bne_else.42534:
	ldi	$r3, $r0, 590
	beq	$r3, $r0, bne_else.42538
	j	bne_cont.42539
bne_else.42538:
	addi	$r3, $r0, 45
	beq	$r4, $r3, bne_else.42540
	addi	$r3, $r0, 1
	sti	$r3, $r0, 590
	j	bne_cont.42541
bne_else.42540:
	addi	$r3, $r0, -1
	sti	$r3, $r0, 590
bne_cont.42541:
bne_cont.42539:
	ldi	$r3, $r0, 591
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 591
	addi	$r6, $r0, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_int_token.2525
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r10, $r3
bne_cont.42535:
bne_cont.42517:
	beq	$r10, $r31, bne_else.42542
	addi	$r3, $r0, 0
	sti	$r3, $r0, 591
	addi	$r3, $r0, 0
	sti	$r3, $r0, 590
	inputb	$r5
	addi	$r12, $r0, 48
	blt	$r5, $r12, ble_else.42544
	addi	$r12, $r0, 57
	blt	$r12, $r5, ble_else.42546
	addi	$r12, $r0, 0
	j	ble_cont.42547
ble_else.42546:
	addi	$r12, $r0, 1
ble_cont.42547:
	j	ble_cont.42545
ble_else.42544:
	addi	$r12, $r0, 1
ble_cont.42545:
	beq	$r12, $r0, bne_else.42548
	addi	$r6, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_int_token.2525
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r12, $r3
	j	bne_cont.42549
bne_else.42548:
	ldi	$r3, $r0, 590
	beq	$r3, $r0, bne_else.42550
	j	bne_cont.42551
bne_else.42550:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 590
bne_cont.42551:
	ldi	$r3, $r0, 591
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 591
	addi	$r6, $r0, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_int_token.2525
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r12, $r3
bne_cont.42549:
	beq	$r12, $r31, bne_else.42552
	addi	$r8, $r0, 2
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_net_item.2731
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r12, $r3, 1
	j	bne_cont.42553
bne_else.42552:
	addi	$r3, $r0, 2
	addi	$r4, $r0, -1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
bne_cont.42553:
	sti	$r10, $r3, 0
	j	bne_cont.42543
bne_else.42542:
	addi	$r3, $r0, 1
	addi	$r4, $r0, -1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
bne_cont.42543:
	ldi	$r4, $r3, 0
	beq	$r4, $r31, bne_else.42554
	slli	$r4, $r11, 0
	sti	$r3, $r4, 464
	addi	$r11, $r11, 1
	addi	$r3, $r0, 0
	sti	$r3, $r0, 591
	addi	$r3, $r0, 0
	sti	$r3, $r0, 590
	inputb	$r5
	addi	$r10, $r0, 48
	blt	$r5, $r10, ble_else.42555
	addi	$r10, $r0, 57
	blt	$r10, $r5, ble_else.42557
	addi	$r10, $r0, 0
	j	ble_cont.42558
ble_else.42557:
	addi	$r10, $r0, 1
ble_cont.42558:
	j	ble_cont.42556
ble_else.42555:
	addi	$r10, $r0, 1
ble_cont.42556:
	beq	$r10, $r0, bne_else.42559
	addi	$r6, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_int_token.2525
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r10, $r3
	j	bne_cont.42560
bne_else.42559:
	ldi	$r3, $r0, 590
	beq	$r3, $r0, bne_else.42561
	j	bne_cont.42562
bne_else.42561:
	addi	$r3, $r0, 1
	sti	$r3, $r0, 590
bne_cont.42562:
	ldi	$r3, $r0, 591
	slli	$r4, $r3, 3
	slli	$r3, $r3, 1
	add	$r4, $r4, $r3
	subi	$r3, $r5, 48
	add	$r3, $r4, $r3
	sti	$r3, $r0, 591
	addi	$r6, $r0, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_int_token.2525
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r10, $r3
bne_cont.42560:
	beq	$r10, $r31, bne_else.42563
	addi	$r8, $r0, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	read_net_item.2731
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r10, $r3, 0
	j	bne_cont.42564
bne_else.42563:
	addi	$r3, $r0, 1
	addi	$r4, $r0, -1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
bne_cont.42564:
	ldi	$r4, $r3, 0
	beq	$r4, $r31, bne_else.42565
	slli	$r4, $r11, 0
	sti	$r3, $r4, 464
	addi	$r11, $r11, 1
	j	read_and_network.2735
bne_else.42565:
	jr	$r29
bne_else.42554:
	jr	$r29

#---------------------------------------------------------------------
# args = [$r8, $r6]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
iter_setup_dirvec_constants.2832:
	blt	$r6, $r0, bge_else.42568
	slli	$r3, $r6, 0
	ldi	$r10, $r3, 524
	ldi	$r7, $r8, 1
	ldi	$r5, $r8, 0
	ldi	$r3, $r10, 1
	beq	$r3, $r30, bne_else.42569
	addi	$r4, $r0, 2
	beq	$r3, $r4, bne_else.42571
	addi	$r3, $r0, 5
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	fldi	$f0, $r5, 0
	fldi	$f1, $r5, 1
	fldi	$f2, $r5, 2
	fmul	$f3, $f0, $f0
	ldi	$r4, $r10, 4
	fldi	$f5, $r4, 0
	fmul	$f4, $f3, $f5
	fmul	$f3, $f1, $f1
	fldi	$f6, $r4, 1
	fmul	$f3, $f3, $f6
	fadd	$f7, $f4, $f3
	fmul	$f3, $f2, $f2
	fldi	$f4, $r4, 2
	fmul	$f3, $f3, $f4
	fadd	$f7, $f7, $f3
	ldi	$r9, $r10, 3
	beq	$r9, $r0, bne_else.42573
	fmul	$f8, $f1, $f2
	ldi	$r4, $r10, 9
	fldi	$f3, $r4, 0
	fmul	$f3, $f8, $f3
	fadd	$f8, $f7, $f3
	fmul	$f7, $f2, $f0
	fldi	$f3, $r4, 1
	fmul	$f3, $f7, $f3
	fadd	$f8, $f8, $f3
	fmul	$f7, $f0, $f1
	fldi	$f3, $r4, 2
	fmul	$f3, $f7, $f3
	fadd	$f3, $f8, $f3
	j	bne_cont.42574
bne_else.42573:
	fmov	$f3, $f7
bne_cont.42574:
	fmul	$f0, $f0, $f5
	fneg	$f0, $f0
	fmul	$f1, $f1, $f6
	fneg	$f1, $f1
	fmul	$f2, $f2, $f4
	fneg	$f2, $f2
	fsti	$f3, $r3, 0
	beq	$r9, $r0, bne_else.42575
	fldi	$f5, $r5, 2
	ldi	$r4, $r10, 9
	fldi	$f4, $r4, 1
	fmul	$f6, $f5, $f4
	fldi	$f5, $r5, 1
	fldi	$f4, $r4, 2
	fmul	$f4, $f5, $f4
	fadd	$f4, $f6, $f4
	fmul	$f4, $f4, $f20
	fsub	$f0, $f0, $f4
	fsti	$f0, $r3, 1
	fldi	$f4, $r5, 2
	fldi	$f0, $r4, 0
	fmul	$f5, $f4, $f0
	fldi	$f4, $r5, 0
	fldi	$f0, $r4, 2
	fmul	$f0, $f4, $f0
	fadd	$f0, $f5, $f0
	fmul	$f0, $f0, $f20
	fsub	$f0, $f1, $f0
	fsti	$f0, $r3, 2
	fldi	$f1, $r5, 1
	fldi	$f0, $r4, 0
	fmul	$f4, $f1, $f0
	fldi	$f1, $r5, 0
	fldi	$f0, $r4, 1
	fmul	$f0, $f1, $f0
	fadd	$f0, $f4, $f0
	fmul	$f0, $f0, $f20
	fsub	$f0, $f2, $f0
	fsti	$f0, $r3, 3
	j	bne_cont.42576
bne_else.42575:
	fsti	$f0, $r3, 1
	fsti	$f1, $r3, 2
	fsti	$f2, $r3, 3
bne_cont.42576:
	fbeq	$f3, $f16, fbne_else.42577
	fdiv	$f0, $f17, $f3
	fsti	$f0, $r3, 4
	j	fbne_cont.42578
fbne_else.42577:
fbne_cont.42578:
	slli	$r4, $r6, 0
	str	$r3, $r7, $r4
	j	bne_cont.42572
bne_else.42571:
	addi	$r3, $r0, 4
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	fldi	$f1, $r5, 0
	ldi	$r4, $r10, 4
	fldi	$f0, $r4, 0
	fmul	$f2, $f1, $f0
	fldi	$f1, $r5, 1
	fldi	$f0, $r4, 1
	fmul	$f0, $f1, $f0
	fadd	$f2, $f2, $f0
	fldi	$f1, $r5, 2
	fldi	$f0, $r4, 2
	fmul	$f0, $f1, $f0
	fadd	$f0, $f2, $f0
	fblt	$f16, $f0, fbge_else.42579
	fsti	$f16, $r3, 0
	j	fbge_cont.42580
fbge_else.42579:
	fdiv	$f1, $f19, $f0
	fsti	$f1, $r3, 0
	fldi	$f1, $r4, 0
	fdiv	$f1, $f1, $f0
	fneg	$f1, $f1
	fsti	$f1, $r3, 1
	fldi	$f1, $r4, 1
	fdiv	$f1, $f1, $f0
	fneg	$f1, $f1
	fsti	$f1, $r3, 2
	fldi	$f1, $r4, 2
	fdiv	$f0, $f1, $f0
	fneg	$f0, $f0
	fsti	$f0, $r3, 3
fbge_cont.42580:
	slli	$r4, $r6, 0
	str	$r3, $r7, $r4
bne_cont.42572:
	j	bne_cont.42570
bne_else.42569:
	addi	$r3, $r0, 6
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	fldi	$f0, $r5, 0
	fbeq	$f0, $f16, fbne_else.42581
	ldi	$r4, $r10, 6
	fblt	$f0, $f16, fbge_else.42583
	addi	$r11, $r0, 0
	j	fbge_cont.42584
fbge_else.42583:
	addi	$r11, $r0, 1
fbge_cont.42584:
	ldi	$r9, $r10, 4
	fldi	$f1, $r9, 0
	beq	$r4, $r11, bne_else.42585
	fmov	$f0, $f1
	j	bne_cont.42586
bne_else.42585:
	fneg	$f0, $f1
bne_cont.42586:
	fsti	$f0, $r3, 0
	fldi	$f0, $r5, 0
	fdiv	$f0, $f17, $f0
	fsti	$f0, $r3, 1
	j	fbne_cont.42582
fbne_else.42581:
	fsti	$f16, $r3, 1
fbne_cont.42582:
	fldi	$f0, $r5, 1
	fbeq	$f0, $f16, fbne_else.42587
	ldi	$r4, $r10, 6
	fblt	$f0, $f16, fbge_else.42589
	addi	$r11, $r0, 0
	j	fbge_cont.42590
fbge_else.42589:
	addi	$r11, $r0, 1
fbge_cont.42590:
	ldi	$r9, $r10, 4
	fldi	$f1, $r9, 1
	beq	$r4, $r11, bne_else.42591
	fmov	$f0, $f1
	j	bne_cont.42592
bne_else.42591:
	fneg	$f0, $f1
bne_cont.42592:
	fsti	$f0, $r3, 2
	fldi	$f0, $r5, 1
	fdiv	$f0, $f17, $f0
	fsti	$f0, $r3, 3
	j	fbne_cont.42588
fbne_else.42587:
	fsti	$f16, $r3, 3
fbne_cont.42588:
	fldi	$f0, $r5, 2
	fbeq	$f0, $f16, fbne_else.42593
	ldi	$r4, $r10, 6
	fblt	$f0, $f16, fbge_else.42595
	addi	$r11, $r0, 0
	j	fbge_cont.42596
fbge_else.42595:
	addi	$r11, $r0, 1
fbge_cont.42596:
	ldi	$r9, $r10, 4
	fldi	$f1, $r9, 2
	beq	$r4, $r11, bne_else.42597
	fmov	$f0, $f1
	j	bne_cont.42598
bne_else.42597:
	fneg	$f0, $f1
bne_cont.42598:
	fsti	$f0, $r3, 4
	fldi	$f0, $r5, 2
	fdiv	$f0, $f17, $f0
	fsti	$f0, $r3, 5
	j	fbne_cont.42594
fbne_else.42593:
	fsti	$f16, $r3, 5
fbne_cont.42594:
	slli	$r4, $r6, 0
	str	$r3, $r7, $r4
bne_cont.42570:
	subi	$r6, $r6, 1
	j	iter_setup_dirvec_constants.2832
bge_else.42568:
	jr	$r29

#---------------------------------------------------------------------
# args = [$r3, $r4]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
setup_startp_constants.2837:
	blt	$r4, $r0, bge_else.42600
	slli	$r5, $r4, 0
	ldi	$r5, $r5, 524
	ldi	$r8, $r5, 10
	ldi	$r7, $r5, 1
	fldi	$f1, $r3, 0
	ldi	$r6, $r5, 5
	fldi	$f0, $r6, 0
	fsub	$f0, $f1, $f0
	fsti	$f0, $r8, 0
	fldi	$f1, $r3, 1
	fldi	$f0, $r6, 1
	fsub	$f0, $f1, $f0
	fsti	$f0, $r8, 1
	fldi	$f1, $r3, 2
	fldi	$f0, $r6, 2
	fsub	$f0, $f1, $f0
	fsti	$f0, $r8, 2
	addi	$r6, $r0, 2
	beq	$r7, $r6, bne_else.42601
	addi	$r6, $r0, 2
	blt	$r6, $r7, ble_else.42603
	j	ble_cont.42604
ble_else.42603:
	fldi	$f2, $r8, 0
	fldi	$f1, $r8, 1
	fldi	$f0, $r8, 2
	fmul	$f4, $f2, $f2
	ldi	$r6, $r5, 4
	fldi	$f3, $r6, 0
	fmul	$f5, $f4, $f3
	fmul	$f4, $f1, $f1
	fldi	$f3, $r6, 1
	fmul	$f3, $f4, $f3
	fadd	$f5, $f5, $f3
	fmul	$f4, $f0, $f0
	fldi	$f3, $r6, 2
	fmul	$f3, $f4, $f3
	fadd	$f4, $f5, $f3
	ldi	$r6, $r5, 3
	beq	$r6, $r0, bne_else.42605
	fmul	$f5, $f1, $f0
	ldi	$r5, $r5, 9
	fldi	$f3, $r5, 0
	fmul	$f3, $f5, $f3
	fadd	$f4, $f4, $f3
	fmul	$f3, $f0, $f2
	fldi	$f0, $r5, 1
	fmul	$f0, $f3, $f0
	fadd	$f4, $f4, $f0
	fmul	$f1, $f2, $f1
	fldi	$f0, $r5, 2
	fmul	$f3, $f1, $f0
	fadd	$f3, $f4, $f3
	j	bne_cont.42606
bne_else.42605:
	fmov	$f3, $f4
bne_cont.42606:
	addi	$r5, $r0, 3
	beq	$r7, $r5, bne_else.42607
	fmov	$f0, $f3
	j	bne_cont.42608
bne_else.42607:
	fsub	$f0, $f3, $f17
bne_cont.42608:
	fsti	$f0, $r8, 3
ble_cont.42604:
	j	bne_cont.42602
bne_else.42601:
	ldi	$r5, $r5, 4
	fldi	$f1, $r8, 0
	fldi	$f3, $r8, 1
	fldi	$f2, $r8, 2
	fldi	$f0, $r5, 0
	fmul	$f1, $f0, $f1
	fldi	$f0, $r5, 1
	fmul	$f0, $f0, $f3
	fadd	$f1, $f1, $f0
	fldi	$f0, $r5, 2
	fmul	$f0, $f0, $f2
	fadd	$f0, $f1, $f0
	fsti	$f0, $r8, 3
bne_cont.42602:
	subi	$r8, $r4, 1
	blt	$r8, $r0, bge_else.42609
	slli	$r4, $r8, 0
	ldi	$r4, $r4, 524
	ldi	$r7, $r4, 10
	ldi	$r6, $r4, 1
	fldi	$f1, $r3, 0
	ldi	$r5, $r4, 5
	fldi	$f0, $r5, 0
	fsub	$f0, $f1, $f0
	fsti	$f0, $r7, 0
	fldi	$f1, $r3, 1
	fldi	$f0, $r5, 1
	fsub	$f0, $f1, $f0
	fsti	$f0, $r7, 1
	fldi	$f1, $r3, 2
	fldi	$f0, $r5, 2
	fsub	$f0, $f1, $f0
	fsti	$f0, $r7, 2
	addi	$r5, $r0, 2
	beq	$r6, $r5, bne_else.42610
	addi	$r5, $r0, 2
	blt	$r5, $r6, ble_else.42612
	j	ble_cont.42613
ble_else.42612:
	fldi	$f2, $r7, 0
	fldi	$f1, $r7, 1
	fldi	$f0, $r7, 2
	fmul	$f4, $f2, $f2
	ldi	$r5, $r4, 4
	fldi	$f3, $r5, 0
	fmul	$f5, $f4, $f3
	fmul	$f4, $f1, $f1
	fldi	$f3, $r5, 1
	fmul	$f3, $f4, $f3
	fadd	$f5, $f5, $f3
	fmul	$f4, $f0, $f0
	fldi	$f3, $r5, 2
	fmul	$f3, $f4, $f3
	fadd	$f4, $f5, $f3
	ldi	$r5, $r4, 3
	beq	$r5, $r0, bne_else.42614
	fmul	$f5, $f1, $f0
	ldi	$r4, $r4, 9
	fldi	$f3, $r4, 0
	fmul	$f3, $f5, $f3
	fadd	$f4, $f4, $f3
	fmul	$f3, $f0, $f2
	fldi	$f0, $r4, 1
	fmul	$f0, $f3, $f0
	fadd	$f4, $f4, $f0
	fmul	$f1, $f2, $f1
	fldi	$f0, $r4, 2
	fmul	$f3, $f1, $f0
	fadd	$f3, $f4, $f3
	j	bne_cont.42615
bne_else.42614:
	fmov	$f3, $f4
bne_cont.42615:
	addi	$r4, $r0, 3
	beq	$r6, $r4, bne_else.42616
	fmov	$f0, $f3
	j	bne_cont.42617
bne_else.42616:
	fsub	$f0, $f3, $f17
bne_cont.42617:
	fsti	$f0, $r7, 3
ble_cont.42613:
	j	bne_cont.42611
bne_else.42610:
	ldi	$r4, $r4, 4
	fldi	$f1, $r7, 0
	fldi	$f3, $r7, 1
	fldi	$f2, $r7, 2
	fldi	$f0, $r4, 0
	fmul	$f1, $f0, $f1
	fldi	$f0, $r4, 1
	fmul	$f0, $f0, $f3
	fadd	$f1, $f1, $f0
	fldi	$f0, $r4, 2
	fmul	$f0, $f0, $f2
	fadd	$f0, $f1, $f0
	fsti	$f0, $r7, 3
bne_cont.42611:
	subi	$r4, $r8, 1
	j	setup_startp_constants.2837
bge_else.42609:
	jr	$r29
bge_else.42600:
	jr	$r29

#---------------------------------------------------------------------
# args = [$r5, $r4]
# fargs = [$f5, $f4, $f3]
# ret type = Bool
#---------------------------------------------------------------------
check_all_inside.2862:
	slli	$r3, $r5, 0
	ldr	$r6, $r4, $r3
	beq	$r6, $r31, bne_else.42620
	slli	$r3, $r6, 0
	ldi	$r7, $r3, 524
	ldi	$r3, $r7, 5
	fldi	$f0, $r3, 0
	fsub	$f0, $f5, $f0
	fldi	$f1, $r3, 1
	fsub	$f2, $f4, $f1
	fldi	$f1, $r3, 2
	fsub	$f1, $f3, $f1
	ldi	$r6, $r7, 1
	beq	$r6, $r30, bne_else.42621
	addi	$r3, $r0, 2
	beq	$r6, $r3, bne_else.42623
	fmul	$f7, $f0, $f0
	ldi	$r3, $r7, 4
	fldi	$f6, $r3, 0
	fmul	$f8, $f7, $f6
	fmul	$f7, $f2, $f2
	fldi	$f6, $r3, 1
	fmul	$f6, $f7, $f6
	fadd	$f8, $f8, $f6
	fmul	$f7, $f1, $f1
	fldi	$f6, $r3, 2
	fmul	$f6, $f7, $f6
	fadd	$f7, $f8, $f6
	ldi	$r3, $r7, 3
	beq	$r3, $r0, bne_else.42625
	fmul	$f8, $f2, $f1
	ldi	$r3, $r7, 9
	fldi	$f6, $r3, 0
	fmul	$f6, $f8, $f6
	fadd	$f7, $f7, $f6
	fmul	$f6, $f1, $f0
	fldi	$f1, $r3, 1
	fmul	$f1, $f6, $f1
	fadd	$f7, $f7, $f1
	fmul	$f1, $f0, $f2
	fldi	$f0, $r3, 2
	fmul	$f6, $f1, $f0
	fadd	$f6, $f7, $f6
	j	bne_cont.42626
bne_else.42625:
	fmov	$f6, $f7
bne_cont.42626:
	addi	$r3, $r0, 3
	beq	$r6, $r3, bne_else.42627
	fmov	$f0, $f6
	j	bne_cont.42628
bne_else.42627:
	fsub	$f0, $f6, $f17
bne_cont.42628:
	ldi	$r3, $r7, 6
	fblt	$f0, $f16, fbge_else.42629
	addi	$r6, $r0, 0
	j	fbge_cont.42630
fbge_else.42629:
	addi	$r6, $r0, 1
fbge_cont.42630:
	beq	$r3, $r6, bne_else.42631
	addi	$r3, $r0, 0
	j	bne_cont.42632
bne_else.42631:
	addi	$r3, $r0, 1
bne_cont.42632:
	j	bne_cont.42624
bne_else.42623:
	ldi	$r3, $r7, 4
	fldi	$f6, $r3, 0
	fmul	$f6, $f6, $f0
	fldi	$f0, $r3, 1
	fmul	$f0, $f0, $f2
	fadd	$f2, $f6, $f0
	fldi	$f0, $r3, 2
	fmul	$f0, $f0, $f1
	fadd	$f0, $f2, $f0
	ldi	$r3, $r7, 6
	fblt	$f0, $f16, fbge_else.42633
	addi	$r6, $r0, 0
	j	fbge_cont.42634
fbge_else.42633:
	addi	$r6, $r0, 1
fbge_cont.42634:
	beq	$r3, $r6, bne_else.42635
	addi	$r3, $r0, 0
	j	bne_cont.42636
bne_else.42635:
	addi	$r3, $r0, 1
bne_cont.42636:
bne_cont.42624:
	j	bne_cont.42622
bne_else.42621:
	fblt	$f0, $f16, fbge_else.42637
	fmov	$f6, $f0
	j	fbge_cont.42638
fbge_else.42637:
	fneg	$f6, $f0
fbge_cont.42638:
	ldi	$r3, $r7, 4
	fldi	$f0, $r3, 0
	fblt	$f6, $f0, fbge_else.42639
	addi	$r6, $r0, 0
	j	fbge_cont.42640
fbge_else.42639:
	fblt	$f2, $f16, fbge_else.42641
	fmov	$f0, $f2
	j	fbge_cont.42642
fbge_else.42641:
	fneg	$f0, $f2
fbge_cont.42642:
	fldi	$f2, $r3, 1
	fblt	$f0, $f2, fbge_else.42643
	addi	$r6, $r0, 0
	j	fbge_cont.42644
fbge_else.42643:
	fblt	$f1, $f16, fbge_else.42645
	fmov	$f0, $f1
	j	fbge_cont.42646
fbge_else.42645:
	fneg	$f0, $f1
fbge_cont.42646:
	fldi	$f1, $r3, 2
	fblt	$f0, $f1, fbge_else.42647
	addi	$r6, $r0, 0
	j	fbge_cont.42648
fbge_else.42647:
	addi	$r6, $r0, 1
fbge_cont.42648:
fbge_cont.42644:
fbge_cont.42640:
	beq	$r6, $r0, bne_else.42649
	ldi	$r3, $r7, 6
	j	bne_cont.42650
bne_else.42649:
	ldi	$r3, $r7, 6
	beq	$r3, $r0, bne_else.42651
	addi	$r3, $r0, 0
	j	bne_cont.42652
bne_else.42651:
	addi	$r3, $r0, 1
bne_cont.42652:
bne_cont.42650:
bne_cont.42622:
	beq	$r3, $r0, bne_else.42653
	addi	$r3, $r0, 0
	jr	$r29
bne_else.42653:
	addi	$r7, $r5, 1
	slli	$r3, $r7, 0
	ldr	$r5, $r4, $r3
	beq	$r5, $r31, bne_else.42654
	slli	$r3, $r5, 0
	ldi	$r6, $r3, 524
	ldi	$r3, $r6, 5
	fldi	$f0, $r3, 0
	fsub	$f0, $f5, $f0
	fldi	$f1, $r3, 1
	fsub	$f2, $f4, $f1
	fldi	$f1, $r3, 2
	fsub	$f1, $f3, $f1
	ldi	$r5, $r6, 1
	beq	$r5, $r30, bne_else.42655
	addi	$r3, $r0, 2
	beq	$r5, $r3, bne_else.42657
	fmul	$f7, $f0, $f0
	ldi	$r3, $r6, 4
	fldi	$f6, $r3, 0
	fmul	$f8, $f7, $f6
	fmul	$f7, $f2, $f2
	fldi	$f6, $r3, 1
	fmul	$f6, $f7, $f6
	fadd	$f8, $f8, $f6
	fmul	$f7, $f1, $f1
	fldi	$f6, $r3, 2
	fmul	$f6, $f7, $f6
	fadd	$f7, $f8, $f6
	ldi	$r3, $r6, 3
	beq	$r3, $r0, bne_else.42659
	fmul	$f8, $f2, $f1
	ldi	$r3, $r6, 9
	fldi	$f6, $r3, 0
	fmul	$f6, $f8, $f6
	fadd	$f7, $f7, $f6
	fmul	$f6, $f1, $f0
	fldi	$f1, $r3, 1
	fmul	$f1, $f6, $f1
	fadd	$f7, $f7, $f1
	fmul	$f1, $f0, $f2
	fldi	$f0, $r3, 2
	fmul	$f6, $f1, $f0
	fadd	$f6, $f7, $f6
	j	bne_cont.42660
bne_else.42659:
	fmov	$f6, $f7
bne_cont.42660:
	addi	$r3, $r0, 3
	beq	$r5, $r3, bne_else.42661
	fmov	$f0, $f6
	j	bne_cont.42662
bne_else.42661:
	fsub	$f0, $f6, $f17
bne_cont.42662:
	ldi	$r3, $r6, 6
	fblt	$f0, $f16, fbge_else.42663
	addi	$r5, $r0, 0
	j	fbge_cont.42664
fbge_else.42663:
	addi	$r5, $r0, 1
fbge_cont.42664:
	beq	$r3, $r5, bne_else.42665
	addi	$r3, $r0, 0
	j	bne_cont.42666
bne_else.42665:
	addi	$r3, $r0, 1
bne_cont.42666:
	j	bne_cont.42658
bne_else.42657:
	ldi	$r3, $r6, 4
	fldi	$f6, $r3, 0
	fmul	$f6, $f6, $f0
	fldi	$f0, $r3, 1
	fmul	$f0, $f0, $f2
	fadd	$f2, $f6, $f0
	fldi	$f0, $r3, 2
	fmul	$f0, $f0, $f1
	fadd	$f0, $f2, $f0
	ldi	$r3, $r6, 6
	fblt	$f0, $f16, fbge_else.42667
	addi	$r5, $r0, 0
	j	fbge_cont.42668
fbge_else.42667:
	addi	$r5, $r0, 1
fbge_cont.42668:
	beq	$r3, $r5, bne_else.42669
	addi	$r3, $r0, 0
	j	bne_cont.42670
bne_else.42669:
	addi	$r3, $r0, 1
bne_cont.42670:
bne_cont.42658:
	j	bne_cont.42656
bne_else.42655:
	fblt	$f0, $f16, fbge_else.42671
	fmov	$f6, $f0
	j	fbge_cont.42672
fbge_else.42671:
	fneg	$f6, $f0
fbge_cont.42672:
	ldi	$r3, $r6, 4
	fldi	$f0, $r3, 0
	fblt	$f6, $f0, fbge_else.42673
	addi	$r5, $r0, 0
	j	fbge_cont.42674
fbge_else.42673:
	fblt	$f2, $f16, fbge_else.42675
	fmov	$f0, $f2
	j	fbge_cont.42676
fbge_else.42675:
	fneg	$f0, $f2
fbge_cont.42676:
	fldi	$f2, $r3, 1
	fblt	$f0, $f2, fbge_else.42677
	addi	$r5, $r0, 0
	j	fbge_cont.42678
fbge_else.42677:
	fblt	$f1, $f16, fbge_else.42679
	fmov	$f0, $f1
	j	fbge_cont.42680
fbge_else.42679:
	fneg	$f0, $f1
fbge_cont.42680:
	fldi	$f1, $r3, 2
	fblt	$f0, $f1, fbge_else.42681
	addi	$r5, $r0, 0
	j	fbge_cont.42682
fbge_else.42681:
	addi	$r5, $r0, 1
fbge_cont.42682:
fbge_cont.42678:
fbge_cont.42674:
	beq	$r5, $r0, bne_else.42683
	ldi	$r3, $r6, 6
	j	bne_cont.42684
bne_else.42683:
	ldi	$r3, $r6, 6
	beq	$r3, $r0, bne_else.42685
	addi	$r3, $r0, 0
	j	bne_cont.42686
bne_else.42685:
	addi	$r3, $r0, 1
bne_cont.42686:
bne_cont.42684:
bne_cont.42656:
	beq	$r3, $r0, bne_else.42687
	addi	$r3, $r0, 0
	jr	$r29
bne_else.42687:
	addi	$r5, $r7, 1
	j	check_all_inside.2862
bne_else.42654:
	addi	$r3, $r0, 1
	jr	$r29
bne_else.42620:
	addi	$r3, $r0, 1
	jr	$r29

#---------------------------------------------------------------------
# args = [$r8, $r4]
# fargs = []
# ret type = Bool
#---------------------------------------------------------------------
shadow_check_and_group.2868:
	slli	$r3, $r8, 0
	ldr	$r9, $r4, $r3
	beq	$r9, $r31, bne_else.42688
	slli	$r3, $r9, 0
	ldi	$r6, $r3, 524
	fldi	$f1, $r0, 457
	ldi	$r3, $r6, 5
	fldi	$f0, $r3, 0
	fsub	$f3, $f1, $f0
	fldi	$f1, $r0, 458
	fldi	$f0, $r3, 1
	fsub	$f4, $f1, $f0
	fldi	$f1, $r0, 459
	fldi	$f0, $r3, 2
	fsub	$f2, $f1, $f0
	slli	$r3, $r9, 0
	ldi	$r7, $r3, 349
	ldi	$r5, $r6, 1
	beq	$r5, $r30, bne_else.42689
	addi	$r3, $r0, 2
	beq	$r5, $r3, bne_else.42691
	fldi	$f0, $r7, 0
	fbeq	$f0, $f16, fbne_else.42693
	fldi	$f1, $r7, 1
	fmul	$f5, $f1, $f3
	fldi	$f1, $r7, 2
	fmul	$f1, $f1, $f4
	fadd	$f5, $f5, $f1
	fldi	$f1, $r7, 3
	fmul	$f1, $f1, $f2
	fadd	$f1, $f5, $f1
	fmul	$f6, $f3, $f3
	ldi	$r3, $r6, 4
	fldi	$f5, $r3, 0
	fmul	$f7, $f6, $f5
	fmul	$f6, $f4, $f4
	fldi	$f5, $r3, 1
	fmul	$f5, $f6, $f5
	fadd	$f7, $f7, $f5
	fmul	$f6, $f2, $f2
	fldi	$f5, $r3, 2
	fmul	$f5, $f6, $f5
	fadd	$f6, $f7, $f5
	ldi	$r3, $r6, 3
	beq	$r3, $r0, bne_else.42695
	fmul	$f7, $f4, $f2
	ldi	$r3, $r6, 9
	fldi	$f5, $r3, 0
	fmul	$f5, $f7, $f5
	fadd	$f6, $f6, $f5
	fmul	$f5, $f2, $f3
	fldi	$f2, $r3, 1
	fmul	$f2, $f5, $f2
	fadd	$f6, $f6, $f2
	fmul	$f3, $f3, $f4
	fldi	$f2, $r3, 2
	fmul	$f5, $f3, $f2
	fadd	$f5, $f6, $f5
	j	bne_cont.42696
bne_else.42695:
	fmov	$f5, $f6
bne_cont.42696:
	addi	$r3, $r0, 3
	beq	$r5, $r3, bne_else.42697
	fmov	$f2, $f5
	j	bne_cont.42698
bne_else.42697:
	fsub	$f2, $f5, $f17
bne_cont.42698:
	fmul	$f3, $f1, $f1
	fmul	$f0, $f0, $f2
	fsub	$f0, $f3, $f0
	fblt	$f16, $f0, fbge_else.42699
	addi	$r3, $r0, 0
	j	fbge_cont.42700
fbge_else.42699:
	ldi	$r3, $r6, 6
	beq	$r3, $r0, bne_else.42701
	fsqrt	$f0, $f0
	fadd	$f1, $f1, $f0
	fldi	$f0, $r7, 4
	fmul	$f0, $f1, $f0
	fsti	$f0, $r0, 462
	j	bne_cont.42702
bne_else.42701:
	fsqrt	$f0, $f0
	fsub	$f1, $f1, $f0
	fldi	$f0, $r7, 4
	fmul	$f0, $f1, $f0
	fsti	$f0, $r0, 462
bne_cont.42702:
	addi	$r3, $r0, 1
fbge_cont.42700:
	j	fbne_cont.42694
fbne_else.42693:
	addi	$r3, $r0, 0
fbne_cont.42694:
	j	bne_cont.42692
bne_else.42691:
	fldi	$f0, $r7, 0
	fblt	$f0, $f16, fbge_else.42703
	addi	$r3, $r0, 0
	j	fbge_cont.42704
fbge_else.42703:
	fldi	$f0, $r7, 1
	fmul	$f1, $f0, $f3
	fldi	$f0, $r7, 2
	fmul	$f0, $f0, $f4
	fadd	$f1, $f1, $f0
	fldi	$f0, $r7, 3
	fmul	$f0, $f0, $f2
	fadd	$f0, $f1, $f0
	fsti	$f0, $r0, 462
	addi	$r3, $r0, 1
fbge_cont.42704:
bne_cont.42692:
	j	bne_cont.42690
bne_else.42689:
	fldi	$f0, $r7, 0
	fsub	$f0, $f0, $f3
	fldi	$f1, $r7, 1
	fmul	$f0, $f0, $f1
	fldi	$f5, $r0, 410
	fmul	$f5, $f0, $f5
	fadd	$f6, $f5, $f4
	fblt	$f6, $f16, fbge_else.42705
	fmov	$f5, $f6
	j	fbge_cont.42706
fbge_else.42705:
	fneg	$f5, $f6
fbge_cont.42706:
	ldi	$r5, $r6, 4
	fldi	$f6, $r5, 1
	fblt	$f5, $f6, fbge_else.42707
	addi	$r3, $r0, 0
	j	fbge_cont.42708
fbge_else.42707:
	fldi	$f5, $r0, 411
	fmul	$f5, $f0, $f5
	fadd	$f6, $f5, $f2
	fblt	$f6, $f16, fbge_else.42709
	fmov	$f5, $f6
	j	fbge_cont.42710
fbge_else.42709:
	fneg	$f5, $f6
fbge_cont.42710:
	fldi	$f6, $r5, 2
	fblt	$f5, $f6, fbge_else.42711
	addi	$r3, $r0, 0
	j	fbge_cont.42712
fbge_else.42711:
	fbeq	$f1, $f16, fbne_else.42713
	addi	$r3, $r0, 1
	j	fbne_cont.42714
fbne_else.42713:
	addi	$r3, $r0, 0
fbne_cont.42714:
fbge_cont.42712:
fbge_cont.42708:
	beq	$r3, $r0, bne_else.42715
	fsti	$f0, $r0, 462
	addi	$r3, $r0, 1
	j	bne_cont.42716
bne_else.42715:
	fldi	$f0, $r7, 2
	fsub	$f0, $f0, $f4
	fldi	$f1, $r7, 3
	fmul	$f0, $f0, $f1
	fldi	$f5, $r0, 409
	fmul	$f5, $f0, $f5
	fadd	$f6, $f5, $f3
	fblt	$f6, $f16, fbge_else.42717
	fmov	$f5, $f6
	j	fbge_cont.42718
fbge_else.42717:
	fneg	$f5, $f6
fbge_cont.42718:
	fldi	$f6, $r5, 0
	fblt	$f5, $f6, fbge_else.42719
	addi	$r3, $r0, 0
	j	fbge_cont.42720
fbge_else.42719:
	fldi	$f5, $r0, 411
	fmul	$f5, $f0, $f5
	fadd	$f6, $f5, $f2
	fblt	$f6, $f16, fbge_else.42721
	fmov	$f5, $f6
	j	fbge_cont.42722
fbge_else.42721:
	fneg	$f5, $f6
fbge_cont.42722:
	fldi	$f6, $r5, 2
	fblt	$f5, $f6, fbge_else.42723
	addi	$r3, $r0, 0
	j	fbge_cont.42724
fbge_else.42723:
	fbeq	$f1, $f16, fbne_else.42725
	addi	$r3, $r0, 1
	j	fbne_cont.42726
fbne_else.42725:
	addi	$r3, $r0, 0
fbne_cont.42726:
fbge_cont.42724:
fbge_cont.42720:
	beq	$r3, $r0, bne_else.42727
	fsti	$f0, $r0, 462
	addi	$r3, $r0, 2
	j	bne_cont.42728
bne_else.42727:
	fldi	$f0, $r7, 4
	fsub	$f0, $f0, $f2
	fldi	$f1, $r7, 5
	fmul	$f0, $f0, $f1
	fldi	$f2, $r0, 409
	fmul	$f2, $f0, $f2
	fadd	$f3, $f2, $f3
	fblt	$f3, $f16, fbge_else.42729
	fmov	$f2, $f3
	j	fbge_cont.42730
fbge_else.42729:
	fneg	$f2, $f3
fbge_cont.42730:
	fldi	$f3, $r5, 0
	fblt	$f2, $f3, fbge_else.42731
	addi	$r3, $r0, 0
	j	fbge_cont.42732
fbge_else.42731:
	fldi	$f2, $r0, 410
	fmul	$f2, $f0, $f2
	fadd	$f3, $f2, $f4
	fblt	$f3, $f16, fbge_else.42733
	fmov	$f2, $f3
	j	fbge_cont.42734
fbge_else.42733:
	fneg	$f2, $f3
fbge_cont.42734:
	fldi	$f3, $r5, 1
	fblt	$f2, $f3, fbge_else.42735
	addi	$r3, $r0, 0
	j	fbge_cont.42736
fbge_else.42735:
	fbeq	$f1, $f16, fbne_else.42737
	addi	$r3, $r0, 1
	j	fbne_cont.42738
fbne_else.42737:
	addi	$r3, $r0, 0
fbne_cont.42738:
fbge_cont.42736:
fbge_cont.42732:
	beq	$r3, $r0, bne_else.42739
	fsti	$f0, $r0, 462
	addi	$r3, $r0, 3
	j	bne_cont.42740
bne_else.42739:
	addi	$r3, $r0, 0
bne_cont.42740:
bne_cont.42728:
bne_cont.42716:
bne_cont.42690:
	fldi	$f0, $r0, 462
	beq	$r3, $r0, bne_else.42741
	# -0.200000
	fmvhi	$f1, 48716
	fmvlo	$f1, 52420
	fblt	$f0, $f1, fbge_else.42743
	addi	$r3, $r0, 0
	j	fbge_cont.42744
fbge_else.42743:
	addi	$r3, $r0, 1
fbge_cont.42744:
	j	bne_cont.42742
bne_else.42741:
	addi	$r3, $r0, 0
bne_cont.42742:
	beq	$r3, $r0, bne_else.42745
	# 0.010000
	fmvhi	$f1, 15395
	fmvlo	$f1, 55050
	fadd	$f0, $f0, $f1
	fldi	$f1, $r0, 515
	fmul	$f2, $f1, $f0
	fldi	$f1, $r0, 457
	fadd	$f5, $f2, $f1
	fldi	$f1, $r0, 516
	fmul	$f2, $f1, $f0
	fldi	$f1, $r0, 458
	fadd	$f4, $f2, $f1
	fldi	$f1, $r0, 517
	fmul	$f1, $f1, $f0
	fldi	$f0, $r0, 459
	fadd	$f3, $f1, $f0
	ldi	$r5, $r4, 0
	sti	$r4, $r1, 0
	beq	$r5, $r31, bne_else.42746
	slli	$r3, $r5, 0
	ldi	$r6, $r3, 524
	ldi	$r3, $r6, 5
	fldi	$f0, $r3, 0
	fsub	$f0, $f5, $f0
	fldi	$f1, $r3, 1
	fsub	$f2, $f4, $f1
	fldi	$f1, $r3, 2
	fsub	$f1, $f3, $f1
	ldi	$r5, $r6, 1
	beq	$r5, $r30, bne_else.42748
	addi	$r3, $r0, 2
	beq	$r5, $r3, bne_else.42750
	fmul	$f7, $f0, $f0
	ldi	$r3, $r6, 4
	fldi	$f6, $r3, 0
	fmul	$f8, $f7, $f6
	fmul	$f7, $f2, $f2
	fldi	$f6, $r3, 1
	fmul	$f6, $f7, $f6
	fadd	$f8, $f8, $f6
	fmul	$f7, $f1, $f1
	fldi	$f6, $r3, 2
	fmul	$f6, $f7, $f6
	fadd	$f7, $f8, $f6
	ldi	$r3, $r6, 3
	beq	$r3, $r0, bne_else.42752
	fmul	$f8, $f2, $f1
	ldi	$r3, $r6, 9
	fldi	$f6, $r3, 0
	fmul	$f6, $f8, $f6
	fadd	$f7, $f7, $f6
	fmul	$f6, $f1, $f0
	fldi	$f1, $r3, 1
	fmul	$f1, $f6, $f1
	fadd	$f7, $f7, $f1
	fmul	$f1, $f0, $f2
	fldi	$f0, $r3, 2
	fmul	$f6, $f1, $f0
	fadd	$f6, $f7, $f6
	j	bne_cont.42753
bne_else.42752:
	fmov	$f6, $f7
bne_cont.42753:
	addi	$r3, $r0, 3
	beq	$r5, $r3, bne_else.42754
	fmov	$f0, $f6
	j	bne_cont.42755
bne_else.42754:
	fsub	$f0, $f6, $f17
bne_cont.42755:
	ldi	$r3, $r6, 6
	fblt	$f0, $f16, fbge_else.42756
	addi	$r5, $r0, 0
	j	fbge_cont.42757
fbge_else.42756:
	addi	$r5, $r0, 1
fbge_cont.42757:
	beq	$r3, $r5, bne_else.42758
	addi	$r3, $r0, 0
	j	bne_cont.42759
bne_else.42758:
	addi	$r3, $r0, 1
bne_cont.42759:
	j	bne_cont.42751
bne_else.42750:
	ldi	$r3, $r6, 4
	fldi	$f6, $r3, 0
	fmul	$f6, $f6, $f0
	fldi	$f0, $r3, 1
	fmul	$f0, $f0, $f2
	fadd	$f2, $f6, $f0
	fldi	$f0, $r3, 2
	fmul	$f0, $f0, $f1
	fadd	$f0, $f2, $f0
	ldi	$r3, $r6, 6
	fblt	$f0, $f16, fbge_else.42760
	addi	$r5, $r0, 0
	j	fbge_cont.42761
fbge_else.42760:
	addi	$r5, $r0, 1
fbge_cont.42761:
	beq	$r3, $r5, bne_else.42762
	addi	$r3, $r0, 0
	j	bne_cont.42763
bne_else.42762:
	addi	$r3, $r0, 1
bne_cont.42763:
bne_cont.42751:
	j	bne_cont.42749
bne_else.42748:
	fblt	$f0, $f16, fbge_else.42764
	fmov	$f6, $f0
	j	fbge_cont.42765
fbge_else.42764:
	fneg	$f6, $f0
fbge_cont.42765:
	ldi	$r3, $r6, 4
	fldi	$f0, $r3, 0
	fblt	$f6, $f0, fbge_else.42766
	addi	$r5, $r0, 0
	j	fbge_cont.42767
fbge_else.42766:
	fblt	$f2, $f16, fbge_else.42768
	fmov	$f0, $f2
	j	fbge_cont.42769
fbge_else.42768:
	fneg	$f0, $f2
fbge_cont.42769:
	fldi	$f2, $r3, 1
	fblt	$f0, $f2, fbge_else.42770
	addi	$r5, $r0, 0
	j	fbge_cont.42771
fbge_else.42770:
	fblt	$f1, $f16, fbge_else.42772
	fmov	$f0, $f1
	j	fbge_cont.42773
fbge_else.42772:
	fneg	$f0, $f1
fbge_cont.42773:
	fldi	$f1, $r3, 2
	fblt	$f0, $f1, fbge_else.42774
	addi	$r5, $r0, 0
	j	fbge_cont.42775
fbge_else.42774:
	addi	$r5, $r0, 1
fbge_cont.42775:
fbge_cont.42771:
fbge_cont.42767:
	beq	$r5, $r0, bne_else.42776
	ldi	$r3, $r6, 6
	j	bne_cont.42777
bne_else.42776:
	ldi	$r3, $r6, 6
	beq	$r3, $r0, bne_else.42778
	addi	$r3, $r0, 0
	j	bne_cont.42779
bne_else.42778:
	addi	$r3, $r0, 1
bne_cont.42779:
bne_cont.42777:
bne_cont.42749:
	beq	$r3, $r0, bne_else.42780
	addi	$r3, $r0, 0
	j	bne_cont.42781
bne_else.42780:
	addi	$r5, $r0, 1
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	check_all_inside.2862
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42781:
	j	bne_cont.42747
bne_else.42746:
	addi	$r3, $r0, 1
bne_cont.42747:
	beq	$r3, $r0, bne_else.42782
	addi	$r3, $r0, 1
	jr	$r29
bne_else.42782:
	addi	$r8, $r8, 1
	ldi	$r4, $r1, 0
	j	shadow_check_and_group.2868
bne_else.42745:
	slli	$r3, $r9, 0
	ldi	$r3, $r3, 524
	ldi	$r3, $r3, 6
	beq	$r3, $r0, bne_else.42783
	addi	$r8, $r8, 1
	j	shadow_check_and_group.2868
bne_else.42783:
	addi	$r3, $r0, 0
	jr	$r29
bne_else.42688:
	addi	$r3, $r0, 0
	jr	$r29

#---------------------------------------------------------------------
# args = [$r11, $r10]
# fargs = []
# ret type = Bool
#---------------------------------------------------------------------
shadow_check_one_or_group.2871:
	slli	$r3, $r11, 0
	ldr	$r4, $r10, $r3
	beq	$r4, $r31, bne_else.42784
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	beq	$r3, $r0, bne_else.42785
	addi	$r3, $r0, 1
	jr	$r29
bne_else.42785:
	addi	$r11, $r11, 1
	slli	$r3, $r11, 0
	ldr	$r4, $r10, $r3
	beq	$r4, $r31, bne_else.42786
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	beq	$r3, $r0, bne_else.42787
	addi	$r3, $r0, 1
	jr	$r29
bne_else.42787:
	addi	$r11, $r11, 1
	slli	$r3, $r11, 0
	ldr	$r4, $r10, $r3
	beq	$r4, $r31, bne_else.42788
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	beq	$r3, $r0, bne_else.42789
	addi	$r3, $r0, 1
	jr	$r29
bne_else.42789:
	addi	$r11, $r11, 1
	slli	$r3, $r11, 0
	ldr	$r4, $r10, $r3
	beq	$r4, $r31, bne_else.42790
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	beq	$r3, $r0, bne_else.42791
	addi	$r3, $r0, 1
	jr	$r29
bne_else.42791:
	addi	$r11, $r11, 1
	slli	$r3, $r11, 0
	ldr	$r4, $r10, $r3
	beq	$r4, $r31, bne_else.42792
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	beq	$r3, $r0, bne_else.42793
	addi	$r3, $r0, 1
	jr	$r29
bne_else.42793:
	addi	$r11, $r11, 1
	slli	$r3, $r11, 0
	ldr	$r4, $r10, $r3
	beq	$r4, $r31, bne_else.42794
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	beq	$r3, $r0, bne_else.42795
	addi	$r3, $r0, 1
	jr	$r29
bne_else.42795:
	addi	$r11, $r11, 1
	slli	$r3, $r11, 0
	ldr	$r4, $r10, $r3
	beq	$r4, $r31, bne_else.42796
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	beq	$r3, $r0, bne_else.42797
	addi	$r3, $r0, 1
	jr	$r29
bne_else.42797:
	addi	$r11, $r11, 1
	slli	$r3, $r11, 0
	ldr	$r4, $r10, $r3
	beq	$r4, $r31, bne_else.42798
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	beq	$r3, $r0, bne_else.42799
	addi	$r3, $r0, 1
	jr	$r29
bne_else.42799:
	addi	$r11, $r11, 1
	j	shadow_check_one_or_group.2871
bne_else.42798:
	addi	$r3, $r0, 0
	jr	$r29
bne_else.42796:
	addi	$r3, $r0, 0
	jr	$r29
bne_else.42794:
	addi	$r3, $r0, 0
	jr	$r29
bne_else.42792:
	addi	$r3, $r0, 0
	jr	$r29
bne_else.42790:
	addi	$r3, $r0, 0
	jr	$r29
bne_else.42788:
	addi	$r3, $r0, 0
	jr	$r29
bne_else.42786:
	addi	$r3, $r0, 0
	jr	$r29
bne_else.42784:
	addi	$r3, $r0, 0
	jr	$r29

#---------------------------------------------------------------------
# args = [$r12, $r13]
# fargs = []
# ret type = Bool
#---------------------------------------------------------------------
shadow_check_one_or_matrix.2874:
	slli	$r3, $r12, 0
	ldr	$r10, $r13, $r3
	ldi	$r4, $r10, 0
	beq	$r4, $r31, bne_else.42800
	addi	$r3, $r0, 99
	sti	$r10, $r1, 0
	beq	$r4, $r3, bne_else.42801
	slli	$r3, $r4, 0
	ldi	$r5, $r3, 524
	fldi	$f1, $r0, 457
	ldi	$r3, $r5, 5
	fldi	$f0, $r3, 0
	fsub	$f3, $f1, $f0
	fldi	$f1, $r0, 458
	fldi	$f0, $r3, 1
	fsub	$f4, $f1, $f0
	fldi	$f1, $r0, 459
	fldi	$f0, $r3, 2
	fsub	$f2, $f1, $f0
	slli	$r3, $r4, 0
	ldi	$r6, $r3, 349
	ldi	$r4, $r5, 1
	beq	$r4, $r30, bne_else.42803
	addi	$r3, $r0, 2
	beq	$r4, $r3, bne_else.42805
	fldi	$f0, $r6, 0
	fbeq	$f0, $f16, fbne_else.42807
	fldi	$f1, $r6, 1
	fmul	$f5, $f1, $f3
	fldi	$f1, $r6, 2
	fmul	$f1, $f1, $f4
	fadd	$f5, $f5, $f1
	fldi	$f1, $r6, 3
	fmul	$f1, $f1, $f2
	fadd	$f1, $f5, $f1
	fmul	$f6, $f3, $f3
	ldi	$r3, $r5, 4
	fldi	$f5, $r3, 0
	fmul	$f7, $f6, $f5
	fmul	$f6, $f4, $f4
	fldi	$f5, $r3, 1
	fmul	$f5, $f6, $f5
	fadd	$f7, $f7, $f5
	fmul	$f6, $f2, $f2
	fldi	$f5, $r3, 2
	fmul	$f5, $f6, $f5
	fadd	$f6, $f7, $f5
	ldi	$r3, $r5, 3
	beq	$r3, $r0, bne_else.42809
	fmul	$f7, $f4, $f2
	ldi	$r3, $r5, 9
	fldi	$f5, $r3, 0
	fmul	$f5, $f7, $f5
	fadd	$f6, $f6, $f5
	fmul	$f5, $f2, $f3
	fldi	$f2, $r3, 1
	fmul	$f2, $f5, $f2
	fadd	$f6, $f6, $f2
	fmul	$f3, $f3, $f4
	fldi	$f2, $r3, 2
	fmul	$f5, $f3, $f2
	fadd	$f5, $f6, $f5
	j	bne_cont.42810
bne_else.42809:
	fmov	$f5, $f6
bne_cont.42810:
	addi	$r3, $r0, 3
	beq	$r4, $r3, bne_else.42811
	fmov	$f2, $f5
	j	bne_cont.42812
bne_else.42811:
	fsub	$f2, $f5, $f17
bne_cont.42812:
	fmul	$f3, $f1, $f1
	fmul	$f0, $f0, $f2
	fsub	$f0, $f3, $f0
	fblt	$f16, $f0, fbge_else.42813
	addi	$r3, $r0, 0
	j	fbge_cont.42814
fbge_else.42813:
	ldi	$r3, $r5, 6
	beq	$r3, $r0, bne_else.42815
	fsqrt	$f0, $f0
	fadd	$f1, $f1, $f0
	fldi	$f0, $r6, 4
	fmul	$f0, $f1, $f0
	fsti	$f0, $r0, 462
	j	bne_cont.42816
bne_else.42815:
	fsqrt	$f0, $f0
	fsub	$f1, $f1, $f0
	fldi	$f0, $r6, 4
	fmul	$f0, $f1, $f0
	fsti	$f0, $r0, 462
bne_cont.42816:
	addi	$r3, $r0, 1
fbge_cont.42814:
	j	fbne_cont.42808
fbne_else.42807:
	addi	$r3, $r0, 0
fbne_cont.42808:
	j	bne_cont.42806
bne_else.42805:
	fldi	$f0, $r6, 0
	fblt	$f0, $f16, fbge_else.42817
	addi	$r3, $r0, 0
	j	fbge_cont.42818
fbge_else.42817:
	fldi	$f0, $r6, 1
	fmul	$f1, $f0, $f3
	fldi	$f0, $r6, 2
	fmul	$f0, $f0, $f4
	fadd	$f1, $f1, $f0
	fldi	$f0, $r6, 3
	fmul	$f0, $f0, $f2
	fadd	$f0, $f1, $f0
	fsti	$f0, $r0, 462
	addi	$r3, $r0, 1
fbge_cont.42818:
bne_cont.42806:
	j	bne_cont.42804
bne_else.42803:
	fldi	$f0, $r6, 0
	fsub	$f0, $f0, $f3
	fldi	$f1, $r6, 1
	fmul	$f0, $f0, $f1
	fldi	$f5, $r0, 410
	fmul	$f5, $f0, $f5
	fadd	$f6, $f5, $f4
	fblt	$f6, $f16, fbge_else.42819
	fmov	$f5, $f6
	j	fbge_cont.42820
fbge_else.42819:
	fneg	$f5, $f6
fbge_cont.42820:
	ldi	$r4, $r5, 4
	fldi	$f6, $r4, 1
	fblt	$f5, $f6, fbge_else.42821
	addi	$r3, $r0, 0
	j	fbge_cont.42822
fbge_else.42821:
	fldi	$f5, $r0, 411
	fmul	$f5, $f0, $f5
	fadd	$f6, $f5, $f2
	fblt	$f6, $f16, fbge_else.42823
	fmov	$f5, $f6
	j	fbge_cont.42824
fbge_else.42823:
	fneg	$f5, $f6
fbge_cont.42824:
	fldi	$f6, $r4, 2
	fblt	$f5, $f6, fbge_else.42825
	addi	$r3, $r0, 0
	j	fbge_cont.42826
fbge_else.42825:
	fbeq	$f1, $f16, fbne_else.42827
	addi	$r3, $r0, 1
	j	fbne_cont.42828
fbne_else.42827:
	addi	$r3, $r0, 0
fbne_cont.42828:
fbge_cont.42826:
fbge_cont.42822:
	beq	$r3, $r0, bne_else.42829
	fsti	$f0, $r0, 462
	addi	$r3, $r0, 1
	j	bne_cont.42830
bne_else.42829:
	fldi	$f0, $r6, 2
	fsub	$f0, $f0, $f4
	fldi	$f1, $r6, 3
	fmul	$f0, $f0, $f1
	fldi	$f5, $r0, 409
	fmul	$f5, $f0, $f5
	fadd	$f6, $f5, $f3
	fblt	$f6, $f16, fbge_else.42831
	fmov	$f5, $f6
	j	fbge_cont.42832
fbge_else.42831:
	fneg	$f5, $f6
fbge_cont.42832:
	fldi	$f6, $r4, 0
	fblt	$f5, $f6, fbge_else.42833
	addi	$r3, $r0, 0
	j	fbge_cont.42834
fbge_else.42833:
	fldi	$f5, $r0, 411
	fmul	$f5, $f0, $f5
	fadd	$f6, $f5, $f2
	fblt	$f6, $f16, fbge_else.42835
	fmov	$f5, $f6
	j	fbge_cont.42836
fbge_else.42835:
	fneg	$f5, $f6
fbge_cont.42836:
	fldi	$f6, $r4, 2
	fblt	$f5, $f6, fbge_else.42837
	addi	$r3, $r0, 0
	j	fbge_cont.42838
fbge_else.42837:
	fbeq	$f1, $f16, fbne_else.42839
	addi	$r3, $r0, 1
	j	fbne_cont.42840
fbne_else.42839:
	addi	$r3, $r0, 0
fbne_cont.42840:
fbge_cont.42838:
fbge_cont.42834:
	beq	$r3, $r0, bne_else.42841
	fsti	$f0, $r0, 462
	addi	$r3, $r0, 2
	j	bne_cont.42842
bne_else.42841:
	fldi	$f0, $r6, 4
	fsub	$f1, $f0, $f2
	fldi	$f0, $r6, 5
	fmul	$f5, $f1, $f0
	fldi	$f1, $r0, 409
	fmul	$f1, $f5, $f1
	fadd	$f2, $f1, $f3
	fblt	$f2, $f16, fbge_else.42843
	fmov	$f1, $f2
	j	fbge_cont.42844
fbge_else.42843:
	fneg	$f1, $f2
fbge_cont.42844:
	fldi	$f2, $r4, 0
	fblt	$f1, $f2, fbge_else.42845
	addi	$r3, $r0, 0
	j	fbge_cont.42846
fbge_else.42845:
	fldi	$f1, $r0, 410
	fmul	$f1, $f5, $f1
	fadd	$f2, $f1, $f4
	fblt	$f2, $f16, fbge_else.42847
	fmov	$f1, $f2
	j	fbge_cont.42848
fbge_else.42847:
	fneg	$f1, $f2
fbge_cont.42848:
	fldi	$f2, $r4, 1
	fblt	$f1, $f2, fbge_else.42849
	addi	$r3, $r0, 0
	j	fbge_cont.42850
fbge_else.42849:
	fbeq	$f0, $f16, fbne_else.42851
	addi	$r3, $r0, 1
	j	fbne_cont.42852
fbne_else.42851:
	addi	$r3, $r0, 0
fbne_cont.42852:
fbge_cont.42850:
fbge_cont.42846:
	beq	$r3, $r0, bne_else.42853
	fsti	$f5, $r0, 462
	addi	$r3, $r0, 3
	j	bne_cont.42854
bne_else.42853:
	addi	$r3, $r0, 0
bne_cont.42854:
bne_cont.42842:
bne_cont.42830:
bne_cont.42804:
	beq	$r3, $r0, bne_else.42855
	fldi	$f0, $r0, 462
	fblt	$f0, $f27, fbge_else.42857
	addi	$r3, $r0, 0
	j	fbge_cont.42858
fbge_else.42857:
	ldi	$r4, $r10, 1
	beq	$r4, $r31, bne_else.42859
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	beq	$r3, $r0, bne_else.42861
	addi	$r3, $r0, 1
	j	bne_cont.42862
bne_else.42861:
	ldi	$r4, $r10, 2
	beq	$r4, $r31, bne_else.42863
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	beq	$r3, $r0, bne_else.42865
	addi	$r3, $r0, 1
	j	bne_cont.42866
bne_else.42865:
	ldi	$r4, $r10, 3
	beq	$r4, $r31, bne_else.42867
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	beq	$r3, $r0, bne_else.42869
	addi	$r3, $r0, 1
	j	bne_cont.42870
bne_else.42869:
	ldi	$r4, $r10, 4
	beq	$r4, $r31, bne_else.42871
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	beq	$r3, $r0, bne_else.42873
	addi	$r3, $r0, 1
	j	bne_cont.42874
bne_else.42873:
	ldi	$r4, $r10, 5
	beq	$r4, $r31, bne_else.42875
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	beq	$r3, $r0, bne_else.42877
	addi	$r3, $r0, 1
	j	bne_cont.42878
bne_else.42877:
	ldi	$r4, $r10, 6
	beq	$r4, $r31, bne_else.42879
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	beq	$r3, $r0, bne_else.42881
	addi	$r3, $r0, 1
	j	bne_cont.42882
bne_else.42881:
	ldi	$r4, $r10, 7
	beq	$r4, $r31, bne_else.42883
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	beq	$r3, $r0, bne_else.42885
	addi	$r3, $r0, 1
	j	bne_cont.42886
bne_else.42885:
	addi	$r11, $r0, 8
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	shadow_check_one_or_group.2871
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42886:
	j	bne_cont.42884
bne_else.42883:
	addi	$r3, $r0, 0
bne_cont.42884:
bne_cont.42882:
	j	bne_cont.42880
bne_else.42879:
	addi	$r3, $r0, 0
bne_cont.42880:
bne_cont.42878:
	j	bne_cont.42876
bne_else.42875:
	addi	$r3, $r0, 0
bne_cont.42876:
bne_cont.42874:
	j	bne_cont.42872
bne_else.42871:
	addi	$r3, $r0, 0
bne_cont.42872:
bne_cont.42870:
	j	bne_cont.42868
bne_else.42867:
	addi	$r3, $r0, 0
bne_cont.42868:
bne_cont.42866:
	j	bne_cont.42864
bne_else.42863:
	addi	$r3, $r0, 0
bne_cont.42864:
bne_cont.42862:
	j	bne_cont.42860
bne_else.42859:
	addi	$r3, $r0, 0
bne_cont.42860:
	beq	$r3, $r0, bne_else.42887
	addi	$r3, $r0, 1
	j	bne_cont.42888
bne_else.42887:
	addi	$r3, $r0, 0
bne_cont.42888:
fbge_cont.42858:
	j	bne_cont.42856
bne_else.42855:
	addi	$r3, $r0, 0
bne_cont.42856:
	j	bne_cont.42802
bne_else.42801:
	addi	$r3, $r0, 1
bne_cont.42802:
	beq	$r3, $r0, bne_else.42889
	ldi	$r10, $r1, 0
	ldi	$r4, $r10, 1
	beq	$r4, $r31, bne_else.42890
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	beq	$r3, $r0, bne_else.42892
	addi	$r3, $r0, 1
	j	bne_cont.42893
bne_else.42892:
	ldi	$r4, $r10, 2
	beq	$r4, $r31, bne_else.42894
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	beq	$r3, $r0, bne_else.42896
	addi	$r3, $r0, 1
	j	bne_cont.42897
bne_else.42896:
	ldi	$r4, $r10, 3
	beq	$r4, $r31, bne_else.42898
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	beq	$r3, $r0, bne_else.42900
	addi	$r3, $r0, 1
	j	bne_cont.42901
bne_else.42900:
	ldi	$r4, $r10, 4
	beq	$r4, $r31, bne_else.42902
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	beq	$r3, $r0, bne_else.42904
	addi	$r3, $r0, 1
	j	bne_cont.42905
bne_else.42904:
	ldi	$r4, $r10, 5
	beq	$r4, $r31, bne_else.42906
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	beq	$r3, $r0, bne_else.42908
	addi	$r3, $r0, 1
	j	bne_cont.42909
bne_else.42908:
	ldi	$r4, $r10, 6
	beq	$r4, $r31, bne_else.42910
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	beq	$r3, $r0, bne_else.42912
	addi	$r3, $r0, 1
	j	bne_cont.42913
bne_else.42912:
	ldi	$r4, $r10, 7
	beq	$r4, $r31, bne_else.42914
	slli	$r3, $r4, 0
	ldi	$r4, $r3, 464
	addi	$r8, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	shadow_check_and_group.2868
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	beq	$r3, $r0, bne_else.42916
	addi	$r3, $r0, 1
	j	bne_cont.42917
bne_else.42916:
	addi	$r11, $r0, 8
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	shadow_check_one_or_group.2871
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
bne_cont.42917:
	j	bne_cont.42915
bne_else.42914:
	addi	$r3, $r0, 0
bne_cont.42915:
bne_cont.42913:
	j	bne_cont.42911
bne_else.42910:
	addi	$r3, $r0, 0
bne_cont.42911:
bne_cont.42909:
	j	bne_cont.42907
bne_else.42906:
	addi	$r3, $r0, 0
bne_cont.42907:
bne_cont.42905:
	j	bne_cont.42903
bne_else.42902:
	addi	$r3, $r0, 0
bne_cont.42903:
bne_cont.42901:
	j	bne_cont.42899
bne_else.42898:
	addi	$r3, $r0, 0
bne_cont.42899:
bne_cont.42897:
	j	bne_cont.42895
bne_else.42894:
	addi	$r3, $r0, 0
bne_cont.42895:
bne_cont.42893:
	j	bne_cont.42891
bne_else.42890:
	addi	$r3, $r0, 0
bne_cont.42891:
	beq	$r3, $r0, bne_else.42918
	addi	$r3, $r0, 1
	jr	$r29
bne_else.42918:
	addi	$r12, $r12, 1
	j	shadow_check_one_or_matrix.2874
bne_else.42889:
	addi	$r12, $r12, 1
	j	shadow_check_one_or_matrix.2874
bne_else.42800:
	addi	$r3, $r0, 0
	jr	$r29

#---------------------------------------------------------------------
# args = [$r11, $r4, $r9]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
solve_each_element.2877:
	slli	$r3, $r11, 0
	ldr	$r10, $r4, $r3
	beq	$r10, $r31, bne_else.42919
	slli	$r3, $r10, 0
	ldi	$r7, $r3, 524
	fldi	$f1, $r0, 436
	ldi	$r3, $r7, 5
	fldi	$f0, $r3, 0
	fsub	$f7, $f1, $f0
	fldi	$f1, $r0, 437
	fldi	$f0, $r3, 1
	fsub	$f8, $f1, $f0
	fldi	$f1, $r0, 438
	fldi	$f0, $r3, 2
	fsub	$f6, $f1, $f0
	ldi	$r3, $r7, 1
	beq	$r3, $r30, bne_else.42920
	addi	$r8, $r0, 2
	beq	$r3, $r8, bne_else.42922
	fldi	$f2, $r9, 0
	fldi	$f3, $r9, 1
	fldi	$f1, $r9, 2
	fmul	$f0, $f2, $f2
	ldi	$r5, $r7, 4
	fldi	$f11, $r5, 0
	fmul	$f4, $f0, $f11
	fmul	$f0, $f3, $f3
	fldi	$f13, $r5, 1
	fmul	$f0, $f0, $f13
	fadd	$f4, $f4, $f0
	fmul	$f0, $f1, $f1
	fldi	$f12, $r5, 2
	fmul	$f0, $f0, $f12
	fadd	$f0, $f4, $f0
	ldi	$r6, $r7, 3
	beq	$r6, $r0, bne_else.42924
	fmul	$f5, $f3, $f1
	ldi	$r5, $r7, 9
	fldi	$f4, $r5, 0
	fmul	$f4, $f5, $f4
	fadd	$f4, $f0, $f4
	fmul	$f5, $f1, $f2
	fldi	$f0, $r5, 1
	fmul	$f0, $f5, $f0
	fadd	$f4, $f4, $f0
	fmul	$f5, $f2, $f3
	fldi	$f0, $r5, 2
	fmul	$f10, $f5, $f0
	fadd	$f10, $f4, $f10
	j	bne_cont.42925
bne_else.42924:
	fmov	$f10, $f0
bne_cont.42925:
	fbeq	$f10, $f16, fbne_else.42926
	fmul	$f0, $f2, $f7
	fmul	$f0, $f0, $f11
	fmul	$f4, $f3, $f8
	fmul	$f4, $f4, $f13
	fadd	$f0, $f0, $f4
	fmul	$f4, $f1, $f6
	fmul	$f4, $f4, $f12
	fadd	$f9, $f0, $f4
	beq	$r6, $r0, bne_else.42928
	fmul	$f4, $f1, $f8
	fmul	$f0, $f3, $f6
	fadd	$f4, $f4, $f0
	ldi	$r5, $r7, 9
	fldi	$f0, $r5, 0
	fmul	$f5, $f4, $f0
	fmul	$f4, $f2, $f6
	fmul	$f0, $f1, $f7
	fadd	$f1, $f4, $f0
	fldi	$f0, $r5, 1
	fmul	$f0, $f1, $f0
	fadd	$f0, $f5, $f0
	fmul	$f1, $f2, $f8
	fmul	$f2, $f3, $f7
	fadd	$f2, $f1, $f2
	fldi	$f1, $r5, 2
	fmul	$f1, $f2, $f1
	fadd	$f0, $f0, $f1
	fmul	$f4, $f0, $f20
	fadd	$f4, $f9, $f4
	j	bne_cont.42929
bne_else.42928:
	fmov	$f4, $f9
bne_cont.42929:
	fmul	$f0, $f7, $f7
	fmul	$f1, $f0, $f11
	fmul	$f0, $f8, $f8
	fmul	$f0, $f0, $f13
	fadd	$f1, $f1, $f0
	fmul	$f0, $f6, $f6
	fmul	$f0, $f0, $f12
	fadd	$f1, $f1, $f0
	beq	$r6, $r0, bne_else.42930
	fmul	$f2, $f8, $f6
	ldi	$r5, $r7, 9
	fldi	$f0, $r5, 0
	fmul	$f0, $f2, $f0
	fadd	$f2, $f1, $f0
	fmul	$f1, $f6, $f7
	fldi	$f0, $r5, 1
	fmul	$f0, $f1, $f0
	fadd	$f2, $f2, $f0
	fmul	$f1, $f7, $f8
	fldi	$f0, $r5, 2
	fmul	$f0, $f1, $f0
	fadd	$f0, $f2, $f0
	j	bne_cont.42931
bne_else.42930:
	fmov	$f0, $f1
bne_cont.42931:
	addi	$r5, $r0, 3
	beq	$r3, $r5, bne_else.42932
	fmov	$f1, $f0
	j	bne_cont.42933
bne_else.42932:
	fsub	$f1, $f0, $f17
bne_cont.42933:
	fmul	$f2, $f4, $f4
	fmul	$f0, $f10, $f1
	fsub	$f0, $f2, $f0
	fblt	$f16, $f0, fbge_else.42934
	addi	$r8, $r0, 0
	j	fbge_cont.42935
fbge_else.42934:
	fsqrt	$f0, $f0
	ldi	$r3, $r7, 6
	beq	$r3, $r0, bne_else.42936
	fmov	$f1, $f0
	j	bne_cont.42937
bne_else.42936:
	fneg	$f1, $f0
bne_cont.42937:
	fsub	$f0, $f1, $f4
	fdiv	$f0, $f0, $f10
	fsti	$f0, $r0, 462
	addi	$r8, $r0, 1
fbge_cont.42935:
	j	fbne_cont.42927
fbne_else.42926:
	addi	$r8, $r0, 0
fbne_cont.42927:
	j	bne_cont.42923
bne_else.42922:
	ldi	$r3, $r7, 4
	fldi	$f0, $r9, 0
	fldi	$f1, $r3, 0
	fmul	$f3, $f0, $f1
	fldi	$f2, $r9, 1
	fldi	$f0, $r3, 1
	fmul	$f2, $f2, $f0
	fadd	$f4, $f3, $f2
	fldi	$f2, $r9, 2
	fldi	$f3, $r3, 2
	fmul	$f2, $f2, $f3
	fadd	$f2, $f4, $f2
	fblt	$f16, $f2, fbge_else.42938
	addi	$r8, $r0, 0
	j	fbge_cont.42939
fbge_else.42938:
	fmul	$f1, $f1, $f7
	fmul	$f0, $f0, $f8
	fadd	$f1, $f1, $f0
	fmul	$f0, $f3, $f6
	fadd	$f0, $f1, $f0
	fneg	$f0, $f0
	fdiv	$f0, $f0, $f2
	fsti	$f0, $r0, 462
	addi	$r8, $r0, 1
fbge_cont.42939:
bne_cont.42923:
	j	bne_cont.42921
bne_else.42920:
	fldi	$f2, $r9, 0
	fbeq	$f2, $f16, fbne_else.42940
	ldi	$r5, $r7, 4
	ldi	$r3, $r7, 6
	fblt	$f2, $f16, fbge_else.42942
	addi	$r6, $r0, 0
	j	fbge_cont.42943
fbge_else.42942:
	addi	$r6, $r0, 1
fbge_cont.42943:
	fldi	$f1, $r5, 0
	beq	$r3, $r6, bne_else.42944
	fmov	$f0, $f1
	j	bne_cont.42945
bne_else.42944:
	fneg	$f0, $f1
bne_cont.42945:
	fsub	$f0, $f0, $f7
	fdiv	$f0, $f0, $f2
	fldi	$f1, $r9, 1
	fmul	$f1, $f0, $f1
	fadd	$f2, $f1, $f8
	fblt	$f2, $f16, fbge_else.42946
	fmov	$f1, $f2
	j	fbge_cont.42947
fbge_else.42946:
	fneg	$f1, $f2
fbge_cont.42947:
	fldi	$f2, $r5, 1
	fblt	$f1, $f2, fbge_else.42948
	addi	$r8, $r0, 0
	j	fbge_cont.42949
fbge_else.42948:
	fldi	$f1, $r9, 2
	fmul	$f1, $f0, $f1
	fadd	$f2, $f1, $f6
	fblt	$f2, $f16, fbge_else.42950
	fmov	$f1, $f2
	j	fbge_cont.42951
fbge_else.42950:
	fneg	$f1, $f2
fbge_cont.42951:
	fldi	$f2, $r5, 2
	fblt	$f1, $f2, fbge_else.42952
	addi	$r8, $r0, 0
	j	fbge_cont.42953
fbge_else.42952:
	fsti	$f0, $r0, 462
	addi	$r8, $r0, 1
fbge_cont.42953:
fbge_cont.42949:
	j	fbne_cont.42941
fbne_else.42940:
	addi	$r8, $r0, 0
fbne_cont.42941:
	beq	$r8, $r0, bne_else.42954
	addi	$r8, $r0, 1
	j	bne_cont.42955
bne_else.42954:
	fldi	$f2, $r9, 1
	fbeq	$f2, $f16, fbne_else.42956
	ldi	$r5, $r7, 4
	ldi	$r3, $r7, 6
	fblt	$f2, $f16, fbge_else.42958
	addi	$r6, $r0, 0
	j	fbge_cont.42959
fbge_else.42958:
	addi	$r6, $r0, 1
fbge_cont.42959:
	fldi	$f1, $r5, 1
	beq	$r3, $r6, bne_else.42960
	fmov	$f0, $f1
	j	bne_cont.42961
bne_else.42960:
	fneg	$f0, $f1
bne_cont.42961:
	fsub	$f0, $f0, $f8
	fdiv	$f0, $f0, $f2
	fldi	$f1, $r9, 2
	fmul	$f1, $f0, $f1
	fadd	$f2, $f1, $f6
	fblt	$f2, $f16, fbge_else.42962
	fmov	$f1, $f2
	j	fbge_cont.42963
fbge_else.42962:
	fneg	$f1, $f2
fbge_cont.42963:
	fldi	$f2, $r5, 2
	fblt	$f1, $f2, fbge_else.42964
	addi	$r8, $r0, 0
	j	fbge_cont.42965
fbge_else.42964:
	fldi	$f1, $r9, 0
	fmul	$f1, $f0, $f1
	fadd	$f2, $f1, $f7
	fblt	$f2, $f16, fbge_else.42966
	fmov	$f1, $f2
	j	fbge_cont.42967
fbge_else.42966:
	fneg	$f1, $f2
fbge_cont.42967:
	fldi	$f2, $r5, 0
	fblt	$f1, $f2, fbge_else.42968
	addi	$r8, $r0, 0
	j	fbge_cont.42969
fbge_else.42968:
	fsti	$f0, $r0, 462
	addi	$r8, $r0, 1
fbge_cont.42969:
fbge_cont.42965:
	j	fbne_cont.42957
fbne_else.42956:
	addi	$r8, $r0, 0
fbne_cont.42957:
	beq	$r8, $r0, bne_else.42970
	addi	$r8, $r0, 2
	j	bne_cont.42971
bne_else.42970:
	fldi	$f2, $r9, 2
	fbeq	$f2, $f16, fbne_else.42972
	ldi	$r5, $r7, 4
	ldi	$r3, $r7, 6
	fblt	$f2, $f16, fbge_else.42974
	addi	$r6, $r0, 0
	j	fbge_cont.42975
fbge_else.42974:
	addi	$r6, $r0, 1
fbge_cont.42975:
	fldi	$f1, $r5, 2
	beq	$r3, $r6, bne_else.42976
	fmov	$f0, $f1
	j	bne_cont.42977
bne_else.42976:
	fneg	$f0, $f1
bne_cont.42977:
	fsub	$f0, $f0, $f6
	fdiv	$f2, $f0, $f2
	fldi	$f0, $r9, 0
	fmul	$f0, $f2, $f0
	fadd	$f1, $f0, $f7
	fblt	$f1, $f16, fbge_else.42978
	fmov	$f0, $f1
	j	fbge_cont.42979
fbge_else.42978:
	fneg	$f0, $f1
fbge_cont.42979:
	fldi	$f1, $r5, 0
	fblt	$f0, $f1, fbge_else.42980
	addi	$r8, $r0, 0
	j	fbge_cont.42981
fbge_else.42980:
	fldi	$f0, $r9, 1
	fmul	$f0, $f2, $f0
	fadd	$f1, $f0, $f8
	fblt	$f1, $f16, fbge_else.42982
	fmov	$f0, $f1
	j	fbge_cont.42983
fbge_else.42982:
	fneg	$f0, $f1
fbge_cont.42983:
	fldi	$f1, $r5, 1
	fblt	$f0, $f1, fbge_else.42984
	addi	$r8, $r0, 0
	j	fbge_cont.42985
fbge_else.42984:
	fsti	$f2, $r0, 462
	addi	$r8, $r0, 1
fbge_cont.42985:
fbge_cont.42981:
	j	fbne_cont.42973
fbne_else.42972:
	addi	$r8, $r0, 0
fbne_cont.42973:
	beq	$r8, $r0, bne_else.42986
	addi	$r8, $r0, 3
	j	bne_cont.42987
bne_else.42986:
	addi	$r8, $r0, 0
bne_cont.42987:
bne_cont.42971:
bne_cont.42955:
bne_cont.42921:
	beq	$r8, $r0, bne_else.42988
	fldi	$f0, $r0, 462
	sti	$r4, $r1, 0
	fblt	$f16, $f0, fbge_else.42989
	j	fbge_cont.42990
fbge_else.42989:
	fldi	$f1, $r0, 460
	fblt	$f0, $f1, fbge_else.42991
	j	fbge_cont.42992
fbge_else.42991:
	# 0.010000
	fmvhi	$f1, 15395
	fmvlo	$f1, 55050
	fadd	$f9, $f0, $f1
	fldi	$f0, $r9, 0
	fmul	$f1, $f0, $f9
	fldi	$f0, $r0, 436
	fadd	$f5, $f1, $f0
	fldi	$f0, $r9, 1
	fmul	$f1, $f0, $f9
	fldi	$f0, $r0, 437
	fadd	$f4, $f1, $f0
	fldi	$f0, $r9, 2
	fmul	$f1, $f0, $f9
	fldi	$f0, $r0, 438
	fadd	$f3, $f1, $f0
	ldi	$r5, $r4, 0
	fsti	$f3, $r1, -1
	fsti	$f4, $r1, -2
	fsti	$f5, $r1, -3
	beq	$r5, $r31, bne_else.42993
	slli	$r3, $r5, 0
	ldi	$r6, $r3, 524
	ldi	$r3, $r6, 5
	fldi	$f0, $r3, 0
	fsub	$f0, $f5, $f0
	fldi	$f1, $r3, 1
	fsub	$f2, $f4, $f1
	fldi	$f1, $r3, 2
	fsub	$f1, $f3, $f1
	ldi	$r5, $r6, 1
	beq	$r5, $r30, bne_else.42995
	addi	$r3, $r0, 2
	beq	$r5, $r3, bne_else.42997
	fmul	$f7, $f0, $f0
	ldi	$r3, $r6, 4
	fldi	$f6, $r3, 0
	fmul	$f8, $f7, $f6
	fmul	$f7, $f2, $f2
	fldi	$f6, $r3, 1
	fmul	$f6, $f7, $f6
	fadd	$f8, $f8, $f6
	fmul	$f7, $f1, $f1
	fldi	$f6, $r3, 2
	fmul	$f6, $f7, $f6
	fadd	$f7, $f8, $f6
	ldi	$r3, $r6, 3
	beq	$r3, $r0, bne_else.42999
	fmul	$f8, $f2, $f1
	ldi	$r3, $r6, 9
	fldi	$f6, $r3, 0
	fmul	$f6, $f8, $f6
	fadd	$f7, $f7, $f6
	fmul	$f6, $f1, $f0
	fldi	$f1, $r3, 1
	fmul	$f1, $f6, $f1
	fadd	$f7, $f7, $f1
	fmul	$f1, $f0, $f2
	fldi	$f0, $r3, 2
	fmul	$f6, $f1, $f0
	fadd	$f6, $f7, $f6
	j	bne_cont.43000
bne_else.42999:
	fmov	$f6, $f7
bne_cont.43000:
	addi	$r3, $r0, 3
	beq	$r5, $r3, bne_else.43001
	fmov	$f0, $f6
	j	bne_cont.43002
bne_else.43001:
	fsub	$f0, $f6, $f17
bne_cont.43002:
	ldi	$r3, $r6, 6
	fblt	$f0, $f16, fbge_else.43003
	addi	$r5, $r0, 0
	j	fbge_cont.43004
fbge_else.43003:
	addi	$r5, $r0, 1
fbge_cont.43004:
	beq	$r3, $r5, bne_else.43005
	addi	$r3, $r0, 0
	j	bne_cont.43006
bne_else.43005:
	addi	$r3, $r0, 1
bne_cont.43006:
	j	bne_cont.42998
bne_else.42997:
	ldi	$r3, $r6, 4
	fldi	$f6, $r3, 0
	fmul	$f6, $f6, $f0
	fldi	$f0, $r3, 1
	fmul	$f0, $f0, $f2
	fadd	$f2, $f6, $f0
	fldi	$f0, $r3, 2
	fmul	$f0, $f0, $f1
	fadd	$f0, $f2, $f0
	ldi	$r3, $r6, 6
	fblt	$f0, $f16, fbge_else.43007
	addi	$r5, $r0, 0
	j	fbge_cont.43008
fbge_else.43007:
	addi	$r5, $r0, 1
fbge_cont.43008:
	beq	$r3, $r5, bne_else.43009
	addi	$r3, $r0, 0
	j	bne_cont.43010
bne_else.43009:
	addi	$r3, $r0, 1
bne_cont.43010:
bne_cont.42998:
	j	bne_cont.42996
bne_else.42995:
	fblt	$f0, $f16, fbge_else.43011
	fmov	$f6, $f0
	j	fbge_cont.43012
fbge_else.43011:
	fneg	$f6, $f0
fbge_cont.43012:
	ldi	$r3, $r6, 4
	fldi	$f0, $r3, 0
	fblt	$f6, $f0, fbge_else.43013
	addi	$r5, $r0, 0
	j	fbge_cont.43014
fbge_else.43013:
	fblt	$f2, $f16, fbge_else.43015
	fmov	$f0, $f2
	j	fbge_cont.43016
fbge_else.43015:
	fneg	$f0, $f2
fbge_cont.43016:
	fldi	$f2, $r3, 1
	fblt	$f0, $f2, fbge_else.43017
	addi	$r5, $r0, 0
	j	fbge_cont.43018
fbge_else.43017:
	fblt	$f1, $f16, fbge_else.43019
	fmov	$f0, $f1
	j	fbge_cont.43020
fbge_else.43019:
	fneg	$f0, $f1
fbge_cont.43020:
	fldi	$f1, $r3, 2
	fblt	$f0, $f1, fbge_else.43021
	addi	$r5, $r0, 0
	j	fbge_cont.43022
fbge_else.43021:
	addi	$r5, $r0, 1
fbge_cont.43022:
fbge_cont.43018:
fbge_cont.43014:
	beq	$r5, $r0, bne_else.43023
	ldi	$r3, $r6, 6
	j	bne_cont.43024
bne_else.43023:
	ldi	$r3, $r6, 6
	beq	$r3, $r0, bne_else.43025
	addi	$r3, $r0, 0
	j	bne_cont.43026
bne_else.43025:
	addi	$r3, $r0, 1
bne_cont.43026:
bne_cont.43024:
bne_cont.42996:
	beq	$r3, $r0, bne_else.43027
	addi	$r3, $r0, 0
	j	bne_cont.43028
bne_else.43027:
	addi	$r5, $r0, 1
	sti	$r29, $r1, -5
	subi	$r1, $r1, 6
	jal	check_all_inside.2862
	addi	$r1, $r1, 6
	ldi	$r29, $r1, -5
bne_cont.43028:
	j	bne_cont.42994
bne_else.42993:
	addi	$r3, $r0, 1
bne_cont.42994:
	beq	$r3, $r0, bne_else.43029
	fsti	$f9, $r0, 460
	fldi	$f5, $r1, -3
	fsti	$f5, $r0, 457
	fldi	$f4, $r1, -2
	fsti	$f4, $r0, 458
	fldi	$f3, $r1, -1
	fsti	$f3, $r0, 459
	sti	$r10, $r0, 456
	sti	$r8, $r0, 461
	j	bne_cont.43030
bne_else.43029:
bne_cont.43030:
fbge_cont.42992:
fbge_cont.42990:
	addi	$r11, $r11, 1
	ldi	$r4, $r1, 0
	j	solve_each_element.2877
bne_else.42988:
	slli	$r3, $r10, 0
	ldi	$r3, $r3, 524
	ldi	$r3, $r3, 6
	beq	$r3, $r0, bne_else.43031
	addi	$r11, $r11, 1
	j	solve_each_element.2877
bne_else.43031:
	jr	$r29
bne_else.42919:
	jr	$r29

#---------------------------------------------------------------------
# args = [$r13, $r12, $r9]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
solve_one_or_network.2881:
	slli	$r3, $r13, 0
	ldr	$r3, $r12, $r3
	beq	$r3, $r31, bne_else.43034
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	sti	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	addi	$r13, $r13, 1
	slli	$r3, $r13, 0
	ldr	$r3, $r12, $r3
	beq	$r3, $r31, bne_else.43035
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	addi	$r13, $r13, 1
	slli	$r3, $r13, 0
	ldr	$r3, $r12, $r3
	beq	$r3, $r31, bne_else.43036
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	addi	$r13, $r13, 1
	slli	$r3, $r13, 0
	ldr	$r3, $r12, $r3
	beq	$r3, $r31, bne_else.43037
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	addi	$r13, $r13, 1
	slli	$r3, $r13, 0
	ldr	$r3, $r12, $r3
	beq	$r3, $r31, bne_else.43038
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	addi	$r13, $r13, 1
	slli	$r3, $r13, 0
	ldr	$r3, $r12, $r3
	beq	$r3, $r31, bne_else.43039
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	addi	$r13, $r13, 1
	slli	$r3, $r13, 0
	ldr	$r3, $r12, $r3
	beq	$r3, $r31, bne_else.43040
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	addi	$r13, $r13, 1
	slli	$r3, $r13, 0
	ldr	$r3, $r12, $r3
	beq	$r3, $r31, bne_else.43041
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	addi	$r13, $r13, 1
	ldi	$r9, $r1, 0
	j	solve_one_or_network.2881
bne_else.43041:
	jr	$r29
bne_else.43040:
	jr	$r29
bne_else.43039:
	jr	$r29
bne_else.43038:
	jr	$r29
bne_else.43037:
	jr	$r29
bne_else.43036:
	jr	$r29
bne_else.43035:
	jr	$r29
bne_else.43034:
	jr	$r29

#---------------------------------------------------------------------
# args = [$r14, $r15, $r9]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
trace_or_matrix.2885:
	slli	$r3, $r14, 0
	ldr	$r12, $r15, $r3
	ldi	$r3, $r12, 0
	beq	$r3, $r31, bne_else.43050
	addi	$r4, $r0, 99
	sti	$r9, $r1, 0
	beq	$r3, $r4, bne_else.43051
	slli	$r3, $r3, 0
	ldi	$r6, $r3, 524
	fldi	$f1, $r0, 436
	ldi	$r3, $r6, 5
	fldi	$f0, $r3, 0
	fsub	$f7, $f1, $f0
	fldi	$f1, $r0, 437
	fldi	$f0, $r3, 1
	fsub	$f8, $f1, $f0
	fldi	$f1, $r0, 438
	fldi	$f0, $r3, 2
	fsub	$f6, $f1, $f0
	ldi	$r4, $r6, 1
	beq	$r4, $r30, bne_else.43053
	addi	$r3, $r0, 2
	beq	$r4, $r3, bne_else.43055
	fldi	$f2, $r9, 0
	fldi	$f3, $r9, 1
	fldi	$f1, $r9, 2
	fmul	$f0, $f2, $f2
	ldi	$r3, $r6, 4
	fldi	$f11, $r3, 0
	fmul	$f4, $f0, $f11
	fmul	$f0, $f3, $f3
	fldi	$f13, $r3, 1
	fmul	$f0, $f0, $f13
	fadd	$f4, $f4, $f0
	fmul	$f0, $f1, $f1
	fldi	$f12, $r3, 2
	fmul	$f0, $f0, $f12
	fadd	$f0, $f4, $f0
	ldi	$r5, $r6, 3
	beq	$r5, $r0, bne_else.43057
	fmul	$f5, $f3, $f1
	ldi	$r3, $r6, 9
	fldi	$f4, $r3, 0
	fmul	$f4, $f5, $f4
	fadd	$f4, $f0, $f4
	fmul	$f5, $f1, $f2
	fldi	$f0, $r3, 1
	fmul	$f0, $f5, $f0
	fadd	$f4, $f4, $f0
	fmul	$f5, $f2, $f3
	fldi	$f0, $r3, 2
	fmul	$f10, $f5, $f0
	fadd	$f10, $f4, $f10
	j	bne_cont.43058
bne_else.43057:
	fmov	$f10, $f0
bne_cont.43058:
	fbeq	$f10, $f16, fbne_else.43059
	fmul	$f0, $f2, $f7
	fmul	$f4, $f0, $f11
	fmul	$f0, $f3, $f8
	fmul	$f0, $f0, $f13
	fadd	$f4, $f4, $f0
	fmul	$f0, $f1, $f6
	fmul	$f0, $f0, $f12
	fadd	$f9, $f4, $f0
	beq	$r5, $r0, bne_else.43061
	fmul	$f4, $f1, $f8
	fmul	$f0, $f3, $f6
	fadd	$f4, $f4, $f0
	ldi	$r3, $r6, 9
	fldi	$f0, $r3, 0
	fmul	$f5, $f4, $f0
	fmul	$f4, $f2, $f6
	fmul	$f0, $f1, $f7
	fadd	$f1, $f4, $f0
	fldi	$f0, $r3, 1
	fmul	$f0, $f1, $f0
	fadd	$f0, $f5, $f0
	fmul	$f2, $f2, $f8
	fmul	$f1, $f3, $f7
	fadd	$f2, $f2, $f1
	fldi	$f1, $r3, 2
	fmul	$f1, $f2, $f1
	fadd	$f0, $f0, $f1
	fmul	$f4, $f0, $f20
	fadd	$f4, $f9, $f4
	j	bne_cont.43062
bne_else.43061:
	fmov	$f4, $f9
bne_cont.43062:
	fmul	$f0, $f7, $f7
	fmul	$f1, $f0, $f11
	fmul	$f0, $f8, $f8
	fmul	$f0, $f0, $f13
	fadd	$f1, $f1, $f0
	fmul	$f0, $f6, $f6
	fmul	$f0, $f0, $f12
	fadd	$f1, $f1, $f0
	beq	$r5, $r0, bne_else.43063
	fmul	$f2, $f8, $f6
	ldi	$r3, $r6, 9
	fldi	$f0, $r3, 0
	fmul	$f0, $f2, $f0
	fadd	$f2, $f1, $f0
	fmul	$f1, $f6, $f7
	fldi	$f0, $r3, 1
	fmul	$f0, $f1, $f0
	fadd	$f2, $f2, $f0
	fmul	$f1, $f7, $f8
	fldi	$f0, $r3, 2
	fmul	$f0, $f1, $f0
	fadd	$f0, $f2, $f0
	j	bne_cont.43064
bne_else.43063:
	fmov	$f0, $f1
bne_cont.43064:
	addi	$r3, $r0, 3
	beq	$r4, $r3, bne_else.43065
	fmov	$f1, $f0
	j	bne_cont.43066
bne_else.43065:
	fsub	$f1, $f0, $f17
bne_cont.43066:
	fmul	$f2, $f4, $f4
	fmul	$f0, $f10, $f1
	fsub	$f0, $f2, $f0
	fblt	$f16, $f0, fbge_else.43067
	addi	$r3, $r0, 0
	j	fbge_cont.43068
fbge_else.43067:
	fsqrt	$f0, $f0
	ldi	$r3, $r6, 6
	beq	$r3, $r0, bne_else.43069
	fmov	$f1, $f0
	j	bne_cont.43070
bne_else.43069:
	fneg	$f1, $f0
bne_cont.43070:
	fsub	$f0, $f1, $f4
	fdiv	$f0, $f0, $f10
	fsti	$f0, $r0, 462
	addi	$r3, $r0, 1
fbge_cont.43068:
	j	fbne_cont.43060
fbne_else.43059:
	addi	$r3, $r0, 0
fbne_cont.43060:
	j	bne_cont.43056
bne_else.43055:
	ldi	$r3, $r6, 4
	fldi	$f0, $r9, 0
	fldi	$f4, $r3, 0
	fmul	$f1, $f0, $f4
	fldi	$f0, $r9, 1
	fldi	$f3, $r3, 1
	fmul	$f0, $f0, $f3
	fadd	$f2, $f1, $f0
	fldi	$f0, $r9, 2
	fldi	$f1, $r3, 2
	fmul	$f0, $f0, $f1
	fadd	$f0, $f2, $f0
	fblt	$f16, $f0, fbge_else.43071
	addi	$r3, $r0, 0
	j	fbge_cont.43072
fbge_else.43071:
	fmul	$f4, $f4, $f7
	fmul	$f2, $f3, $f8
	fadd	$f2, $f4, $f2
	fmul	$f1, $f1, $f6
	fadd	$f1, $f2, $f1
	fneg	$f1, $f1
	fdiv	$f0, $f1, $f0
	fsti	$f0, $r0, 462
	addi	$r3, $r0, 1
fbge_cont.43072:
bne_cont.43056:
	j	bne_cont.43054
bne_else.43053:
	fldi	$f2, $r9, 0
	fbeq	$f2, $f16, fbne_else.43073
	ldi	$r4, $r6, 4
	ldi	$r3, $r6, 6
	fblt	$f2, $f16, fbge_else.43075
	addi	$r5, $r0, 0
	j	fbge_cont.43076
fbge_else.43075:
	addi	$r5, $r0, 1
fbge_cont.43076:
	fldi	$f1, $r4, 0
	beq	$r3, $r5, bne_else.43077
	fmov	$f0, $f1
	j	bne_cont.43078
bne_else.43077:
	fneg	$f0, $f1
bne_cont.43078:
	fsub	$f0, $f0, $f7
	fdiv	$f2, $f0, $f2
	fldi	$f0, $r9, 1
	fmul	$f0, $f2, $f0
	fadd	$f1, $f0, $f8
	fblt	$f1, $f16, fbge_else.43079
	fmov	$f0, $f1
	j	fbge_cont.43080
fbge_else.43079:
	fneg	$f0, $f1
fbge_cont.43080:
	fldi	$f1, $r4, 1
	fblt	$f0, $f1, fbge_else.43081
	addi	$r3, $r0, 0
	j	fbge_cont.43082
fbge_else.43081:
	fldi	$f0, $r9, 2
	fmul	$f0, $f2, $f0
	fadd	$f1, $f0, $f6
	fblt	$f1, $f16, fbge_else.43083
	fmov	$f0, $f1
	j	fbge_cont.43084
fbge_else.43083:
	fneg	$f0, $f1
fbge_cont.43084:
	fldi	$f1, $r4, 2
	fblt	$f0, $f1, fbge_else.43085
	addi	$r3, $r0, 0
	j	fbge_cont.43086
fbge_else.43085:
	fsti	$f2, $r0, 462
	addi	$r3, $r0, 1
fbge_cont.43086:
fbge_cont.43082:
	j	fbne_cont.43074
fbne_else.43073:
	addi	$r3, $r0, 0
fbne_cont.43074:
	beq	$r3, $r0, bne_else.43087
	addi	$r3, $r0, 1
	j	bne_cont.43088
bne_else.43087:
	fldi	$f2, $r9, 1
	fbeq	$f2, $f16, fbne_else.43089
	ldi	$r4, $r6, 4
	ldi	$r3, $r6, 6
	fblt	$f2, $f16, fbge_else.43091
	addi	$r5, $r0, 0
	j	fbge_cont.43092
fbge_else.43091:
	addi	$r5, $r0, 1
fbge_cont.43092:
	fldi	$f1, $r4, 1
	beq	$r3, $r5, bne_else.43093
	fmov	$f0, $f1
	j	bne_cont.43094
bne_else.43093:
	fneg	$f0, $f1
bne_cont.43094:
	fsub	$f0, $f0, $f8
	fdiv	$f2, $f0, $f2
	fldi	$f0, $r9, 2
	fmul	$f0, $f2, $f0
	fadd	$f1, $f0, $f6
	fblt	$f1, $f16, fbge_else.43095
	fmov	$f0, $f1
	j	fbge_cont.43096
fbge_else.43095:
	fneg	$f0, $f1
fbge_cont.43096:
	fldi	$f1, $r4, 2
	fblt	$f0, $f1, fbge_else.43097
	addi	$r3, $r0, 0
	j	fbge_cont.43098
fbge_else.43097:
	fldi	$f0, $r9, 0
	fmul	$f0, $f2, $f0
	fadd	$f1, $f0, $f7
	fblt	$f1, $f16, fbge_else.43099
	fmov	$f0, $f1
	j	fbge_cont.43100
fbge_else.43099:
	fneg	$f0, $f1
fbge_cont.43100:
	fldi	$f1, $r4, 0
	fblt	$f0, $f1, fbge_else.43101
	addi	$r3, $r0, 0
	j	fbge_cont.43102
fbge_else.43101:
	fsti	$f2, $r0, 462
	addi	$r3, $r0, 1
fbge_cont.43102:
fbge_cont.43098:
	j	fbne_cont.43090
fbne_else.43089:
	addi	$r3, $r0, 0
fbne_cont.43090:
	beq	$r3, $r0, bne_else.43103
	addi	$r3, $r0, 2
	j	bne_cont.43104
bne_else.43103:
	fldi	$f2, $r9, 2
	fbeq	$f2, $f16, fbne_else.43105
	ldi	$r4, $r6, 4
	ldi	$r3, $r6, 6
	fblt	$f2, $f16, fbge_else.43107
	addi	$r5, $r0, 0
	j	fbge_cont.43108
fbge_else.43107:
	addi	$r5, $r0, 1
fbge_cont.43108:
	fldi	$f1, $r4, 2
	beq	$r3, $r5, bne_else.43109
	fmov	$f0, $f1
	j	bne_cont.43110
bne_else.43109:
	fneg	$f0, $f1
bne_cont.43110:
	fsub	$f0, $f0, $f6
	fdiv	$f2, $f0, $f2
	fldi	$f0, $r9, 0
	fmul	$f0, $f2, $f0
	fadd	$f1, $f0, $f7
	fblt	$f1, $f16, fbge_else.43111
	fmov	$f0, $f1
	j	fbge_cont.43112
fbge_else.43111:
	fneg	$f0, $f1
fbge_cont.43112:
	fldi	$f1, $r4, 0
	fblt	$f0, $f1, fbge_else.43113
	addi	$r3, $r0, 0
	j	fbge_cont.43114
fbge_else.43113:
	fldi	$f0, $r9, 1
	fmul	$f0, $f2, $f0
	fadd	$f1, $f0, $f8
	fblt	$f1, $f16, fbge_else.43115
	fmov	$f0, $f1
	j	fbge_cont.43116
fbge_else.43115:
	fneg	$f0, $f1
fbge_cont.43116:
	fldi	$f1, $r4, 1
	fblt	$f0, $f1, fbge_else.43117
	addi	$r3, $r0, 0
	j	fbge_cont.43118
fbge_else.43117:
	fsti	$f2, $r0, 462
	addi	$r3, $r0, 1
fbge_cont.43118:
fbge_cont.43114:
	j	fbne_cont.43106
fbne_else.43105:
	addi	$r3, $r0, 0
fbne_cont.43106:
	beq	$r3, $r0, bne_else.43119
	addi	$r3, $r0, 3
	j	bne_cont.43120
bne_else.43119:
	addi	$r3, $r0, 0
bne_cont.43120:
bne_cont.43104:
bne_cont.43088:
bne_cont.43054:
	beq	$r3, $r0, bne_else.43121
	fldi	$f0, $r0, 462
	fldi	$f1, $r0, 460
	fblt	$f0, $f1, fbge_else.43123
	j	fbge_cont.43124
fbge_else.43123:
	ldi	$r3, $r12, 1
	beq	$r3, $r31, bne_else.43125
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r12, 2
	beq	$r3, $r31, bne_else.43127
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r12, 3
	beq	$r3, $r31, bne_else.43129
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r12, 4
	beq	$r3, $r31, bne_else.43131
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r12, 5
	beq	$r3, $r31, bne_else.43133
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r12, 6
	beq	$r3, $r31, bne_else.43135
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r12, 7
	beq	$r3, $r31, bne_else.43137
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	addi	$r13, $r0, 8
	ldi	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_one_or_network.2881
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.43138
bne_else.43137:
bne_cont.43138:
	j	bne_cont.43136
bne_else.43135:
bne_cont.43136:
	j	bne_cont.43134
bne_else.43133:
bne_cont.43134:
	j	bne_cont.43132
bne_else.43131:
bne_cont.43132:
	j	bne_cont.43130
bne_else.43129:
bne_cont.43130:
	j	bne_cont.43128
bne_else.43127:
bne_cont.43128:
	j	bne_cont.43126
bne_else.43125:
bne_cont.43126:
fbge_cont.43124:
	j	bne_cont.43122
bne_else.43121:
bne_cont.43122:
	j	bne_cont.43052
bne_else.43051:
	ldi	$r3, $r12, 1
	beq	$r3, $r31, bne_else.43139
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r12, 2
	beq	$r3, $r31, bne_else.43141
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r12, 3
	beq	$r3, $r31, bne_else.43143
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r12, 4
	beq	$r3, $r31, bne_else.43145
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r12, 5
	beq	$r3, $r31, bne_else.43147
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r12, 6
	beq	$r3, $r31, bne_else.43149
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r12, 7
	beq	$r3, $r31, bne_else.43151
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element.2877
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	addi	$r13, $r0, 8
	ldi	$r9, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_one_or_network.2881
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.43152
bne_else.43151:
bne_cont.43152:
	j	bne_cont.43150
bne_else.43149:
bne_cont.43150:
	j	bne_cont.43148
bne_else.43147:
bne_cont.43148:
	j	bne_cont.43146
bne_else.43145:
bne_cont.43146:
	j	bne_cont.43144
bne_else.43143:
bne_cont.43144:
	j	bne_cont.43142
bne_else.43141:
bne_cont.43142:
	j	bne_cont.43140
bne_else.43139:
bne_cont.43140:
bne_cont.43052:
	addi	$r14, $r14, 1
	ldi	$r9, $r1, 0
	j	trace_or_matrix.2885
bne_else.43050:
	jr	$r29

#---------------------------------------------------------------------
# args = [$r11, $r4, $r10]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
solve_each_element_fast.2891:
	ldi	$r5, $r10, 0
	slli	$r3, $r11, 0
	ldr	$r9, $r4, $r3
	beq	$r9, $r31, bne_else.43154
	slli	$r3, $r9, 0
	ldi	$r12, $r3, 524
	ldi	$r6, $r12, 10
	fldi	$f3, $r6, 0
	fldi	$f4, $r6, 1
	fldi	$f2, $r6, 2
	ldi	$r7, $r10, 1
	slli	$r3, $r9, 0
	ldr	$r7, $r7, $r3
	ldi	$r3, $r12, 1
	beq	$r3, $r30, bne_else.43155
	addi	$r8, $r0, 2
	beq	$r3, $r8, bne_else.43157
	fldi	$f0, $r7, 0
	fbeq	$f0, $f16, fbne_else.43159
	fldi	$f1, $r7, 1
	fmul	$f3, $f1, $f3
	fldi	$f1, $r7, 2
	fmul	$f1, $f1, $f4
	fadd	$f3, $f3, $f1
	fldi	$f1, $r7, 3
	fmul	$f1, $f1, $f2
	fadd	$f1, $f3, $f1
	fldi	$f2, $r6, 3
	fmul	$f3, $f1, $f1
	fmul	$f0, $f0, $f2
	fsub	$f0, $f3, $f0
	fblt	$f16, $f0, fbge_else.43161
	addi	$r8, $r0, 0
	j	fbge_cont.43162
fbge_else.43161:
	ldi	$r3, $r12, 6
	beq	$r3, $r0, bne_else.43163
	fsqrt	$f0, $f0
	fadd	$f1, $f1, $f0
	fldi	$f0, $r7, 4
	fmul	$f0, $f1, $f0
	fsti	$f0, $r0, 462
	j	bne_cont.43164
bne_else.43163:
	fsqrt	$f0, $f0
	fsub	$f1, $f1, $f0
	fldi	$f0, $r7, 4
	fmul	$f0, $f1, $f0
	fsti	$f0, $r0, 462
bne_cont.43164:
	addi	$r8, $r0, 1
fbge_cont.43162:
	j	fbne_cont.43160
fbne_else.43159:
	addi	$r8, $r0, 0
fbne_cont.43160:
	j	bne_cont.43158
bne_else.43157:
	fldi	$f1, $r7, 0
	fblt	$f1, $f16, fbge_else.43165
	addi	$r8, $r0, 0
	j	fbge_cont.43166
fbge_else.43165:
	fldi	$f0, $r6, 3
	fmul	$f0, $f1, $f0
	fsti	$f0, $r0, 462
	addi	$r8, $r0, 1
fbge_cont.43166:
bne_cont.43158:
	j	bne_cont.43156
bne_else.43155:
	fldi	$f0, $r7, 0
	fsub	$f0, $f0, $f3
	fldi	$f1, $r7, 1
	fmul	$f0, $f0, $f1
	fldi	$f5, $r5, 1
	fmul	$f5, $f0, $f5
	fadd	$f6, $f5, $f4
	fblt	$f6, $f16, fbge_else.43167
	fmov	$f5, $f6
	j	fbge_cont.43168
fbge_else.43167:
	fneg	$f5, $f6
fbge_cont.43168:
	ldi	$r3, $r12, 4
	fldi	$f6, $r3, 1
	fblt	$f5, $f6, fbge_else.43169
	addi	$r8, $r0, 0
	j	fbge_cont.43170
fbge_else.43169:
	fldi	$f5, $r5, 2
	fmul	$f5, $f0, $f5
	fadd	$f6, $f5, $f2
	fblt	$f6, $f16, fbge_else.43171
	fmov	$f5, $f6
	j	fbge_cont.43172
fbge_else.43171:
	fneg	$f5, $f6
fbge_cont.43172:
	fldi	$f6, $r3, 2
	fblt	$f5, $f6, fbge_else.43173
	addi	$r8, $r0, 0
	j	fbge_cont.43174
fbge_else.43173:
	fbeq	$f1, $f16, fbne_else.43175
	addi	$r8, $r0, 1
	j	fbne_cont.43176
fbne_else.43175:
	addi	$r8, $r0, 0
fbne_cont.43176:
fbge_cont.43174:
fbge_cont.43170:
	beq	$r8, $r0, bne_else.43177
	fsti	$f0, $r0, 462
	addi	$r8, $r0, 1
	j	bne_cont.43178
bne_else.43177:
	fldi	$f0, $r7, 2
	fsub	$f0, $f0, $f4
	fldi	$f1, $r7, 3
	fmul	$f0, $f0, $f1
	fldi	$f5, $r5, 0
	fmul	$f5, $f0, $f5
	fadd	$f6, $f5, $f3
	fblt	$f6, $f16, fbge_else.43179
	fmov	$f5, $f6
	j	fbge_cont.43180
fbge_else.43179:
	fneg	$f5, $f6
fbge_cont.43180:
	fldi	$f6, $r3, 0
	fblt	$f5, $f6, fbge_else.43181
	addi	$r8, $r0, 0
	j	fbge_cont.43182
fbge_else.43181:
	fldi	$f5, $r5, 2
	fmul	$f5, $f0, $f5
	fadd	$f6, $f5, $f2
	fblt	$f6, $f16, fbge_else.43183
	fmov	$f5, $f6
	j	fbge_cont.43184
fbge_else.43183:
	fneg	$f5, $f6
fbge_cont.43184:
	fldi	$f6, $r3, 2
	fblt	$f5, $f6, fbge_else.43185
	addi	$r8, $r0, 0
	j	fbge_cont.43186
fbge_else.43185:
	fbeq	$f1, $f16, fbne_else.43187
	addi	$r8, $r0, 1
	j	fbne_cont.43188
fbne_else.43187:
	addi	$r8, $r0, 0
fbne_cont.43188:
fbge_cont.43186:
fbge_cont.43182:
	beq	$r8, $r0, bne_else.43189
	fsti	$f0, $r0, 462
	addi	$r8, $r0, 2
	j	bne_cont.43190
bne_else.43189:
	fldi	$f0, $r7, 4
	fsub	$f0, $f0, $f2
	fldi	$f1, $r7, 5
	fmul	$f0, $f0, $f1
	fldi	$f2, $r5, 0
	fmul	$f2, $f0, $f2
	fadd	$f3, $f2, $f3
	fblt	$f3, $f16, fbge_else.43191
	fmov	$f2, $f3
	j	fbge_cont.43192
fbge_else.43191:
	fneg	$f2, $f3
fbge_cont.43192:
	fldi	$f3, $r3, 0
	fblt	$f2, $f3, fbge_else.43193
	addi	$r8, $r0, 0
	j	fbge_cont.43194
fbge_else.43193:
	fldi	$f2, $r5, 1
	fmul	$f2, $f0, $f2
	fadd	$f3, $f2, $f4
	fblt	$f3, $f16, fbge_else.43195
	fmov	$f2, $f3
	j	fbge_cont.43196
fbge_else.43195:
	fneg	$f2, $f3
fbge_cont.43196:
	fldi	$f3, $r3, 1
	fblt	$f2, $f3, fbge_else.43197
	addi	$r8, $r0, 0
	j	fbge_cont.43198
fbge_else.43197:
	fbeq	$f1, $f16, fbne_else.43199
	addi	$r8, $r0, 1
	j	fbne_cont.43200
fbne_else.43199:
	addi	$r8, $r0, 0
fbne_cont.43200:
fbge_cont.43198:
fbge_cont.43194:
	beq	$r8, $r0, bne_else.43201
	fsti	$f0, $r0, 462
	addi	$r8, $r0, 3
	j	bne_cont.43202
bne_else.43201:
	addi	$r8, $r0, 0
bne_cont.43202:
bne_cont.43190:
bne_cont.43178:
bne_cont.43156:
	beq	$r8, $r0, bne_else.43203
	fldi	$f0, $r0, 462
	sti	$r4, $r1, 0
	fblt	$f16, $f0, fbge_else.43204
	j	fbge_cont.43205
fbge_else.43204:
	fldi	$f1, $r0, 460
	fblt	$f0, $f1, fbge_else.43206
	j	fbge_cont.43207
fbge_else.43206:
	# 0.010000
	fmvhi	$f1, 15395
	fmvlo	$f1, 55050
	fadd	$f9, $f0, $f1
	fldi	$f0, $r5, 0
	fmul	$f1, $f0, $f9
	fldi	$f0, $r0, 433
	fadd	$f5, $f1, $f0
	fldi	$f0, $r5, 1
	fmul	$f1, $f0, $f9
	fldi	$f0, $r0, 434
	fadd	$f4, $f1, $f0
	fldi	$f0, $r5, 2
	fmul	$f1, $f0, $f9
	fldi	$f0, $r0, 435
	fadd	$f3, $f1, $f0
	ldi	$r5, $r4, 0
	fsti	$f3, $r1, -1
	fsti	$f4, $r1, -2
	fsti	$f5, $r1, -3
	beq	$r5, $r31, bne_else.43208
	slli	$r3, $r5, 0
	ldi	$r6, $r3, 524
	ldi	$r3, $r6, 5
	fldi	$f0, $r3, 0
	fsub	$f0, $f5, $f0
	fldi	$f1, $r3, 1
	fsub	$f2, $f4, $f1
	fldi	$f1, $r3, 2
	fsub	$f1, $f3, $f1
	ldi	$r5, $r6, 1
	beq	$r5, $r30, bne_else.43210
	addi	$r3, $r0, 2
	beq	$r5, $r3, bne_else.43212
	fmul	$f7, $f0, $f0
	ldi	$r3, $r6, 4
	fldi	$f6, $r3, 0
	fmul	$f8, $f7, $f6
	fmul	$f7, $f2, $f2
	fldi	$f6, $r3, 1
	fmul	$f6, $f7, $f6
	fadd	$f8, $f8, $f6
	fmul	$f7, $f1, $f1
	fldi	$f6, $r3, 2
	fmul	$f6, $f7, $f6
	fadd	$f7, $f8, $f6
	ldi	$r3, $r6, 3
	beq	$r3, $r0, bne_else.43214
	fmul	$f8, $f2, $f1
	ldi	$r3, $r6, 9
	fldi	$f6, $r3, 0
	fmul	$f6, $f8, $f6
	fadd	$f7, $f7, $f6
	fmul	$f6, $f1, $f0
	fldi	$f1, $r3, 1
	fmul	$f1, $f6, $f1
	fadd	$f7, $f7, $f1
	fmul	$f1, $f0, $f2
	fldi	$f0, $r3, 2
	fmul	$f6, $f1, $f0
	fadd	$f6, $f7, $f6
	j	bne_cont.43215
bne_else.43214:
	fmov	$f6, $f7
bne_cont.43215:
	addi	$r3, $r0, 3
	beq	$r5, $r3, bne_else.43216
	fmov	$f0, $f6
	j	bne_cont.43217
bne_else.43216:
	fsub	$f0, $f6, $f17
bne_cont.43217:
	ldi	$r3, $r6, 6
	fblt	$f0, $f16, fbge_else.43218
	addi	$r5, $r0, 0
	j	fbge_cont.43219
fbge_else.43218:
	addi	$r5, $r0, 1
fbge_cont.43219:
	beq	$r3, $r5, bne_else.43220
	addi	$r3, $r0, 0
	j	bne_cont.43221
bne_else.43220:
	addi	$r3, $r0, 1
bne_cont.43221:
	j	bne_cont.43213
bne_else.43212:
	ldi	$r3, $r6, 4
	fldi	$f6, $r3, 0
	fmul	$f6, $f6, $f0
	fldi	$f0, $r3, 1
	fmul	$f0, $f0, $f2
	fadd	$f2, $f6, $f0
	fldi	$f0, $r3, 2
	fmul	$f0, $f0, $f1
	fadd	$f0, $f2, $f0
	ldi	$r3, $r6, 6
	fblt	$f0, $f16, fbge_else.43222
	addi	$r5, $r0, 0
	j	fbge_cont.43223
fbge_else.43222:
	addi	$r5, $r0, 1
fbge_cont.43223:
	beq	$r3, $r5, bne_else.43224
	addi	$r3, $r0, 0
	j	bne_cont.43225
bne_else.43224:
	addi	$r3, $r0, 1
bne_cont.43225:
bne_cont.43213:
	j	bne_cont.43211
bne_else.43210:
	fblt	$f0, $f16, fbge_else.43226
	fmov	$f6, $f0
	j	fbge_cont.43227
fbge_else.43226:
	fneg	$f6, $f0
fbge_cont.43227:
	ldi	$r3, $r6, 4
	fldi	$f0, $r3, 0
	fblt	$f6, $f0, fbge_else.43228
	addi	$r5, $r0, 0
	j	fbge_cont.43229
fbge_else.43228:
	fblt	$f2, $f16, fbge_else.43230
	fmov	$f0, $f2
	j	fbge_cont.43231
fbge_else.43230:
	fneg	$f0, $f2
fbge_cont.43231:
	fldi	$f2, $r3, 1
	fblt	$f0, $f2, fbge_else.43232
	addi	$r5, $r0, 0
	j	fbge_cont.43233
fbge_else.43232:
	fblt	$f1, $f16, fbge_else.43234
	fmov	$f0, $f1
	j	fbge_cont.43235
fbge_else.43234:
	fneg	$f0, $f1
fbge_cont.43235:
	fldi	$f1, $r3, 2
	fblt	$f0, $f1, fbge_else.43236
	addi	$r5, $r0, 0
	j	fbge_cont.43237
fbge_else.43236:
	addi	$r5, $r0, 1
fbge_cont.43237:
fbge_cont.43233:
fbge_cont.43229:
	beq	$r5, $r0, bne_else.43238
	ldi	$r3, $r6, 6
	j	bne_cont.43239
bne_else.43238:
	ldi	$r3, $r6, 6
	beq	$r3, $r0, bne_else.43240
	addi	$r3, $r0, 0
	j	bne_cont.43241
bne_else.43240:
	addi	$r3, $r0, 1
bne_cont.43241:
bne_cont.43239:
bne_cont.43211:
	beq	$r3, $r0, bne_else.43242
	addi	$r3, $r0, 0
	j	bne_cont.43243
bne_else.43242:
	addi	$r5, $r0, 1
	sti	$r29, $r1, -5
	subi	$r1, $r1, 6
	jal	check_all_inside.2862
	addi	$r1, $r1, 6
	ldi	$r29, $r1, -5
bne_cont.43243:
	j	bne_cont.43209
bne_else.43208:
	addi	$r3, $r0, 1
bne_cont.43209:
	beq	$r3, $r0, bne_else.43244
	fsti	$f9, $r0, 460
	fldi	$f5, $r1, -3
	fsti	$f5, $r0, 457
	fldi	$f4, $r1, -2
	fsti	$f4, $r0, 458
	fldi	$f3, $r1, -1
	fsti	$f3, $r0, 459
	sti	$r9, $r0, 456
	sti	$r8, $r0, 461
	j	bne_cont.43245
bne_else.43244:
bne_cont.43245:
fbge_cont.43207:
fbge_cont.43205:
	addi	$r11, $r11, 1
	ldi	$r4, $r1, 0
	j	solve_each_element_fast.2891
bne_else.43203:
	slli	$r3, $r9, 0
	ldi	$r3, $r3, 524
	ldi	$r3, $r3, 6
	beq	$r3, $r0, bne_else.43246
	addi	$r11, $r11, 1
	j	solve_each_element_fast.2891
bne_else.43246:
	jr	$r29
bne_else.43154:
	jr	$r29

#---------------------------------------------------------------------
# args = [$r14, $r13, $r10]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
solve_one_or_network_fast.2895:
	slli	$r3, $r14, 0
	ldr	$r3, $r13, $r3
	beq	$r3, $r31, bne_else.43249
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	sti	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	addi	$r14, $r14, 1
	slli	$r3, $r14, 0
	ldr	$r3, $r13, $r3
	beq	$r3, $r31, bne_else.43250
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	addi	$r14, $r14, 1
	slli	$r3, $r14, 0
	ldr	$r3, $r13, $r3
	beq	$r3, $r31, bne_else.43251
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	addi	$r14, $r14, 1
	slli	$r3, $r14, 0
	ldr	$r3, $r13, $r3
	beq	$r3, $r31, bne_else.43252
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	addi	$r14, $r14, 1
	slli	$r3, $r14, 0
	ldr	$r3, $r13, $r3
	beq	$r3, $r31, bne_else.43253
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	addi	$r14, $r14, 1
	slli	$r3, $r14, 0
	ldr	$r3, $r13, $r3
	beq	$r3, $r31, bne_else.43254
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	addi	$r14, $r14, 1
	slli	$r3, $r14, 0
	ldr	$r3, $r13, $r3
	beq	$r3, $r31, bne_else.43255
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	addi	$r14, $r14, 1
	slli	$r3, $r14, 0
	ldr	$r3, $r13, $r3
	beq	$r3, $r31, bne_else.43256
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	addi	$r14, $r14, 1
	ldi	$r10, $r1, 0
	j	solve_one_or_network_fast.2895
bne_else.43256:
	jr	$r29
bne_else.43255:
	jr	$r29
bne_else.43254:
	jr	$r29
bne_else.43253:
	jr	$r29
bne_else.43252:
	jr	$r29
bne_else.43251:
	jr	$r29
bne_else.43250:
	jr	$r29
bne_else.43249:
	jr	$r29

#---------------------------------------------------------------------
# args = [$r15, $r16, $r10]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
trace_or_matrix_fast.2899:
	slli	$r3, $r15, 0
	ldr	$r13, $r16, $r3
	ldi	$r3, $r13, 0
	beq	$r3, $r31, bne_else.43265
	addi	$r4, $r0, 99
	sti	$r10, $r1, 0
	beq	$r3, $r4, bne_else.43266
	slli	$r4, $r3, 0
	ldi	$r6, $r4, 524
	ldi	$r5, $r6, 10
	fldi	$f3, $r5, 0
	fldi	$f4, $r5, 1
	fldi	$f2, $r5, 2
	ldi	$r4, $r10, 1
	slli	$r3, $r3, 0
	ldr	$r7, $r4, $r3
	ldi	$r4, $r6, 1
	beq	$r4, $r30, bne_else.43268
	addi	$r3, $r0, 2
	beq	$r4, $r3, bne_else.43270
	fldi	$f5, $r7, 0
	fbeq	$f5, $f16, fbne_else.43272
	fldi	$f0, $r7, 1
	fmul	$f1, $f0, $f3
	fldi	$f0, $r7, 2
	fmul	$f0, $f0, $f4
	fadd	$f1, $f1, $f0
	fldi	$f0, $r7, 3
	fmul	$f0, $f0, $f2
	fadd	$f1, $f1, $f0
	fldi	$f0, $r5, 3
	fmul	$f2, $f1, $f1
	fmul	$f0, $f5, $f0
	fsub	$f0, $f2, $f0
	fblt	$f16, $f0, fbge_else.43274
	addi	$r3, $r0, 0
	j	fbge_cont.43275
fbge_else.43274:
	ldi	$r3, $r6, 6
	beq	$r3, $r0, bne_else.43276
	fsqrt	$f0, $f0
	fadd	$f1, $f1, $f0
	fldi	$f0, $r7, 4
	fmul	$f0, $f1, $f0
	fsti	$f0, $r0, 462
	j	bne_cont.43277
bne_else.43276:
	fsqrt	$f0, $f0
	fsub	$f1, $f1, $f0
	fldi	$f0, $r7, 4
	fmul	$f0, $f1, $f0
	fsti	$f0, $r0, 462
bne_cont.43277:
	addi	$r3, $r0, 1
fbge_cont.43275:
	j	fbne_cont.43273
fbne_else.43272:
	addi	$r3, $r0, 0
fbne_cont.43273:
	j	bne_cont.43271
bne_else.43270:
	fldi	$f1, $r7, 0
	fblt	$f1, $f16, fbge_else.43278
	addi	$r3, $r0, 0
	j	fbge_cont.43279
fbge_else.43278:
	fldi	$f0, $r5, 3
	fmul	$f0, $f1, $f0
	fsti	$f0, $r0, 462
	addi	$r3, $r0, 1
fbge_cont.43279:
bne_cont.43271:
	j	bne_cont.43269
bne_else.43268:
	ldi	$r4, $r10, 0
	fldi	$f0, $r7, 0
	fsub	$f0, $f0, $f3
	fldi	$f1, $r7, 1
	fmul	$f0, $f0, $f1
	fldi	$f5, $r4, 1
	fmul	$f5, $f0, $f5
	fadd	$f6, $f5, $f4
	fblt	$f6, $f16, fbge_else.43280
	fmov	$f5, $f6
	j	fbge_cont.43281
fbge_else.43280:
	fneg	$f5, $f6
fbge_cont.43281:
	ldi	$r5, $r6, 4
	fldi	$f6, $r5, 1
	fblt	$f5, $f6, fbge_else.43282
	addi	$r3, $r0, 0
	j	fbge_cont.43283
fbge_else.43282:
	fldi	$f5, $r4, 2
	fmul	$f5, $f0, $f5
	fadd	$f6, $f5, $f2
	fblt	$f6, $f16, fbge_else.43284
	fmov	$f5, $f6
	j	fbge_cont.43285
fbge_else.43284:
	fneg	$f5, $f6
fbge_cont.43285:
	fldi	$f6, $r5, 2
	fblt	$f5, $f6, fbge_else.43286
	addi	$r3, $r0, 0
	j	fbge_cont.43287
fbge_else.43286:
	fbeq	$f1, $f16, fbne_else.43288
	addi	$r3, $r0, 1
	j	fbne_cont.43289
fbne_else.43288:
	addi	$r3, $r0, 0
fbne_cont.43289:
fbge_cont.43287:
fbge_cont.43283:
	beq	$r3, $r0, bne_else.43290
	fsti	$f0, $r0, 462
	addi	$r3, $r0, 1
	j	bne_cont.43291
bne_else.43290:
	fldi	$f0, $r7, 2
	fsub	$f1, $f0, $f4
	fldi	$f0, $r7, 3
	fmul	$f6, $f1, $f0
	fldi	$f1, $r4, 0
	fmul	$f1, $f6, $f1
	fadd	$f5, $f1, $f3
	fblt	$f5, $f16, fbge_else.43292
	fmov	$f1, $f5
	j	fbge_cont.43293
fbge_else.43292:
	fneg	$f1, $f5
fbge_cont.43293:
	fldi	$f5, $r5, 0
	fblt	$f1, $f5, fbge_else.43294
	addi	$r3, $r0, 0
	j	fbge_cont.43295
fbge_else.43294:
	fldi	$f1, $r4, 2
	fmul	$f1, $f6, $f1
	fadd	$f5, $f1, $f2
	fblt	$f5, $f16, fbge_else.43296
	fmov	$f1, $f5
	j	fbge_cont.43297
fbge_else.43296:
	fneg	$f1, $f5
fbge_cont.43297:
	fldi	$f5, $r5, 2
	fblt	$f1, $f5, fbge_else.43298
	addi	$r3, $r0, 0
	j	fbge_cont.43299
fbge_else.43298:
	fbeq	$f0, $f16, fbne_else.43300
	addi	$r3, $r0, 1
	j	fbne_cont.43301
fbne_else.43300:
	addi	$r3, $r0, 0
fbne_cont.43301:
fbge_cont.43299:
fbge_cont.43295:
	beq	$r3, $r0, bne_else.43302
	fsti	$f6, $r0, 462
	addi	$r3, $r0, 2
	j	bne_cont.43303
bne_else.43302:
	fldi	$f0, $r7, 4
	fsub	$f0, $f0, $f2
	fldi	$f5, $r7, 5
	fmul	$f2, $f0, $f5
	fldi	$f0, $r4, 0
	fmul	$f0, $f2, $f0
	fadd	$f1, $f0, $f3
	fblt	$f1, $f16, fbge_else.43304
	fmov	$f0, $f1
	j	fbge_cont.43305
fbge_else.43304:
	fneg	$f0, $f1
fbge_cont.43305:
	fldi	$f1, $r5, 0
	fblt	$f0, $f1, fbge_else.43306
	addi	$r3, $r0, 0
	j	fbge_cont.43307
fbge_else.43306:
	fldi	$f0, $r4, 1
	fmul	$f0, $f2, $f0
	fadd	$f1, $f0, $f4
	fblt	$f1, $f16, fbge_else.43308
	fmov	$f0, $f1
	j	fbge_cont.43309
fbge_else.43308:
	fneg	$f0, $f1
fbge_cont.43309:
	fldi	$f1, $r5, 1
	fblt	$f0, $f1, fbge_else.43310
	addi	$r3, $r0, 0
	j	fbge_cont.43311
fbge_else.43310:
	fbeq	$f5, $f16, fbne_else.43312
	addi	$r3, $r0, 1
	j	fbne_cont.43313
fbne_else.43312:
	addi	$r3, $r0, 0
fbne_cont.43313:
fbge_cont.43311:
fbge_cont.43307:
	beq	$r3, $r0, bne_else.43314
	fsti	$f2, $r0, 462
	addi	$r3, $r0, 3
	j	bne_cont.43315
bne_else.43314:
	addi	$r3, $r0, 0
bne_cont.43315:
bne_cont.43303:
bne_cont.43291:
bne_cont.43269:
	beq	$r3, $r0, bne_else.43316
	fldi	$f0, $r0, 462
	fldi	$f1, $r0, 460
	fblt	$f0, $f1, fbge_else.43318
	j	fbge_cont.43319
fbge_else.43318:
	ldi	$r3, $r13, 1
	beq	$r3, $r31, bne_else.43320
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r13, 2
	beq	$r3, $r31, bne_else.43322
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r13, 3
	beq	$r3, $r31, bne_else.43324
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r13, 4
	beq	$r3, $r31, bne_else.43326
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r13, 5
	beq	$r3, $r31, bne_else.43328
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r13, 6
	beq	$r3, $r31, bne_else.43330
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r13, 7
	beq	$r3, $r31, bne_else.43332
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	addi	$r14, $r0, 8
	ldi	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_one_or_network_fast.2895
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.43333
bne_else.43332:
bne_cont.43333:
	j	bne_cont.43331
bne_else.43330:
bne_cont.43331:
	j	bne_cont.43329
bne_else.43328:
bne_cont.43329:
	j	bne_cont.43327
bne_else.43326:
bne_cont.43327:
	j	bne_cont.43325
bne_else.43324:
bne_cont.43325:
	j	bne_cont.43323
bne_else.43322:
bne_cont.43323:
	j	bne_cont.43321
bne_else.43320:
bne_cont.43321:
fbge_cont.43319:
	j	bne_cont.43317
bne_else.43316:
bne_cont.43317:
	j	bne_cont.43267
bne_else.43266:
	ldi	$r3, $r13, 1
	beq	$r3, $r31, bne_else.43334
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r13, 2
	beq	$r3, $r31, bne_else.43336
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r13, 3
	beq	$r3, $r31, bne_else.43338
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r13, 4
	beq	$r3, $r31, bne_else.43340
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r13, 5
	beq	$r3, $r31, bne_else.43342
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r13, 6
	beq	$r3, $r31, bne_else.43344
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	ldi	$r3, $r13, 7
	beq	$r3, $r31, bne_else.43346
	slli	$r3, $r3, 0
	ldi	$r4, $r3, 464
	addi	$r11, $r0, 0
	ldi	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_each_element_fast.2891
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	addi	$r14, $r0, 8
	ldi	$r10, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	solve_one_or_network_fast.2895
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	j	bne_cont.43347
bne_else.43346:
bne_cont.43347:
	j	bne_cont.43345
bne_else.43344:
bne_cont.43345:
	j	bne_cont.43343
bne_else.43342:
bne_cont.43343:
	j	bne_cont.43341
bne_else.43340:
bne_cont.43341:
	j	bne_cont.43339
bne_else.43338:
bne_cont.43339:
	j	bne_cont.43337
bne_else.43336:
bne_cont.43337:
	j	bne_cont.43335
bne_else.43334:
bne_cont.43335:
bne_cont.43267:
	addi	$r15, $r15, 1
	ldi	$r10, $r1, 0
	j	trace_or_matrix_fast.2899
bne_else.43265:
	jr	$r29

#---------------------------------------------------------------------
# args = [$r17, $r19]
# fargs = [$f11, $f10]
# ret type = Unit
#---------------------------------------------------------------------
trace_reflections.2921:
	blt	$r17, $r0, bge_else.43349
	slli	$r3, $r17, 0
	ldi	$r20, $r3, 163
	ldi	$r18, $r20, 1
	fsti	$f26, $r0, 460
	addi	$r15, $r0, 0
	ldi	$r16, $r0, 463
	mov	$r10, $r18
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	trace_or_matrix_fast.2899
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	fldi	$f0, $r0, 460
	fblt	$f27, $f0, fbge_else.43350
	addi	$r3, $r0, 0
	j	fbge_cont.43351
fbge_else.43350:
	fblt	$f0, $f28, fbge_else.43352
	addi	$r3, $r0, 0
	j	fbge_cont.43353
fbge_else.43352:
	addi	$r3, $r0, 1
fbge_cont.43353:
fbge_cont.43351:
	beq	$r3, $r0, bne_else.43354
	ldi	$r3, $r0, 456
	slli	$r4, $r3, 2
	ldi	$r3, $r0, 461
	add	$r3, $r4, $r3
	ldi	$r4, $r20, 0
	beq	$r3, $r4, bne_else.43356
	j	bne_cont.43357
bne_else.43356:
	addi	$r12, $r0, 0
	ldi	$r13, $r0, 463
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	shadow_check_one_or_matrix.2874
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	beq	$r3, $r0, bne_else.43358
	j	bne_cont.43359
bne_else.43358:
	ldi	$r3, $r18, 0
	fldi	$f0, $r0, 453
	fldi	$f2, $r3, 0
	fmul	$f1, $f0, $f2
	fldi	$f0, $r0, 454
	fldi	$f4, $r3, 1
	fmul	$f0, $f0, $f4
	fadd	$f1, $f1, $f0
	fldi	$f0, $r0, 455
	fldi	$f3, $r3, 2
	fmul	$f0, $f0, $f3
	fadd	$f1, $f1, $f0
	fldi	$f0, $r20, 2
	fmul	$f5, $f0, $f11
	fmul	$f1, $f5, $f1
	fldi	$f5, $r19, 0
	fmul	$f5, $f5, $f2
	fldi	$f2, $r19, 1
	fmul	$f2, $f2, $f4
	fadd	$f4, $f5, $f2
	fldi	$f2, $r19, 2
	fmul	$f2, $f2, $f3
	fadd	$f2, $f4, $f2
	fmul	$f0, $f0, $f2
	fblt	$f16, $f1, fbge_else.43360
	j	fbge_cont.43361
fbge_else.43360:
	fldi	$f3, $r0, 444
	fldi	$f2, $r0, 450
	fmul	$f2, $f1, $f2
	fadd	$f2, $f3, $f2
	fsti	$f2, $r0, 444
	fldi	$f3, $r0, 445
	fldi	$f2, $r0, 451
	fmul	$f2, $f1, $f2
	fadd	$f2, $f3, $f2
	fsti	$f2, $r0, 445
	fldi	$f3, $r0, 446
	fldi	$f2, $r0, 452
	fmul	$f1, $f1, $f2
	fadd	$f1, $f3, $f1
	fsti	$f1, $r0, 446
fbge_cont.43361:
	fblt	$f16, $f0, fbge_else.43362
	j	fbge_cont.43363
fbge_else.43362:
	fmul	$f0, $f0, $f0
	fmul	$f0, $f0, $f0
	fmul	$f0, $f0, $f10
	fldi	$f1, $r0, 444
	fadd	$f1, $f1, $f0
	fsti	$f1, $r0, 444
	fldi	$f1, $r0, 445
	fadd	$f1, $f1, $f0
	fsti	$f1, $r0, 445
	fldi	$f1, $r0, 446
	fadd	$f0, $f1, $f0
	fsti	$f0, $r0, 446
fbge_cont.43363:
bne_cont.43359:
bne_cont.43357:
	j	bne_cont.43355
bne_else.43354:
bne_cont.43355:
	subi	$r17, $r17, 1
	j	trace_reflections.2921
bge_else.43349:
	jr	$r29

#---------------------------------------------------------------------
# args = [$r21, $r19, $r22]
# fargs = [$f14, $f12]
# ret type = Unit
#---------------------------------------------------------------------
trace_ray.2926:
	addi	$r3, $r0, 4
	blt	$r3, $r21, ble_else.43365
	ldi	$r24, $r22, 2
	fsti	$f26, $r0, 460
	addi	$r14, $r0, 0
	ldi	$r15, $r0, 463
	fsti	$f12, $r1, 0
	mov	$r9, $r19
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	trace_or_matrix.2885
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	fldi	$f0, $r0, 460
	fblt	$f27, $f0, fbge_else.43366
	addi	$r3, $r0, 0
	j	fbge_cont.43367
fbge_else.43366:
	fblt	$f0, $f28, fbge_else.43368
	addi	$r3, $r0, 0
	j	fbge_cont.43369
fbge_else.43368:
	addi	$r3, $r0, 1
fbge_cont.43369:
fbge_cont.43367:
	beq	$r3, $r0, bne_else.43370
	ldi	$r5, $r0, 456
	slli	$r3, $r5, 0
	ldi	$r4, $r3, 524
	ldi	$r25, $r4, 2
	ldi	$r23, $r4, 7
	fldi	$f0, $r23, 0
	fmul	$f11, $f0, $f14
	ldi	$r3, $r4, 1
	beq	$r3, $r30, bne_else.43371
	addi	$r6, $r0, 2
	beq	$r3, $r6, bne_else.43373
	fldi	$f1, $r0, 457
	ldi	$r3, $r4, 5
	fldi	$f0, $r3, 0
	fsub	$f4, $f1, $f0
	fldi	$f1, $r0, 458
	fldi	$f0, $r3, 1
	fsub	$f3, $f1, $f0
	fldi	$f1, $r0, 459
	fldi	$f0, $r3, 2
	fsub	$f0, $f1, $f0
	ldi	$r3, $r4, 4
	fldi	$f1, $r3, 0
	fmul	$f2, $f4, $f1
	fldi	$f1, $r3, 1
	fmul	$f6, $f3, $f1
	fldi	$f1, $r3, 2
	fmul	$f7, $f0, $f1
	ldi	$r3, $r4, 3
	beq	$r3, $r0, bne_else.43375
	ldi	$r3, $r4, 9
	fldi	$f1, $r3, 2
	fmul	$f5, $f3, $f1
	fldi	$f1, $r3, 1
	fmul	$f1, $f0, $f1
	fadd	$f1, $f5, $f1
	fmul	$f1, $f1, $f20
	fadd	$f1, $f2, $f1
	fsti	$f1, $r0, 453
	fldi	$f1, $r3, 2
	fmul	$f2, $f4, $f1
	fldi	$f1, $r3, 0
	fmul	$f0, $f0, $f1
	fadd	$f0, $f2, $f0
	fmul	$f0, $f0, $f20
	fadd	$f0, $f6, $f0
	fsti	$f0, $r0, 454
	fldi	$f0, $r3, 1
	fmul	$f1, $f4, $f0
	fldi	$f0, $r3, 0
	fmul	$f0, $f3, $f0
	fadd	$f0, $f1, $f0
	fmul	$f0, $f0, $f20
	fadd	$f0, $f7, $f0
	fsti	$f0, $r0, 455
	j	bne_cont.43376
bne_else.43375:
	fsti	$f2, $r0, 453
	fsti	$f6, $r0, 454
	fsti	$f7, $r0, 455
bne_cont.43376:
	ldi	$r3, $r4, 6
	fldi	$f2, $r0, 453
	fmul	$f1, $f2, $f2
	fldi	$f0, $r0, 454
	fmul	$f0, $f0, $f0
	fadd	$f1, $f1, $f0
	fldi	$f0, $r0, 455
	fmul	$f0, $f0, $f0
	fadd	$f0, $f1, $f0
	fsqrt	$f1, $f0
	fbeq	$f1, $f16, fbne_else.43377
	beq	$r3, $r0, bne_else.43379
	fdiv	$f0, $f19, $f1
	j	bne_cont.43380
bne_else.43379:
	fdiv	$f0, $f17, $f1
bne_cont.43380:
	j	fbne_cont.43378
fbne_else.43377:
	fmov	$f0, $f17
fbne_cont.43378:
	fmul	$f1, $f2, $f0
	fsti	$f1, $r0, 453
	fldi	$f1, $r0, 454
	fmul	$f1, $f1, $f0
	fsti	$f1, $r0, 454
	fldi	$f1, $r0, 455
	fmul	$f0, $f1, $f0
	fsti	$f0, $r0, 455
	j	bne_cont.43374
bne_else.43373:
	ldi	$r3, $r4, 4
	fldi	$f0, $r3, 0
	fneg	$f0, $f0
	fsti	$f0, $r0, 453
	fldi	$f0, $r3, 1
	fneg	$f0, $f0
	fsti	$f0, $r0, 454
	fldi	$f0, $r3, 2
	fneg	$f0, $f0
	fsti	$f0, $r0, 455
bne_cont.43374:
	j	bne_cont.43372
bne_else.43371:
	ldi	$r3, $r0, 461
	fsti	$f16, $r0, 453
	fsti	$f16, $r0, 454
	fsti	$f16, $r0, 455
	subi	$r6, $r3, 1
	slli	$r3, $r6, 0
	fldr	$f1, $r19, $r3
	fbeq	$f1, $f16, fbne_else.43381
	fblt	$f16, $f1, fbge_else.43383
	fmov	$f0, $f19
	j	fbge_cont.43384
fbge_else.43383:
	fmov	$f0, $f17
fbge_cont.43384:
	j	fbne_cont.43382
fbne_else.43381:
	fmov	$f0, $f16
fbne_cont.43382:
	fneg	$f0, $f0
	slli	$r3, $r6, 0
	fsti	$f0, $r3, 453
bne_cont.43372:
	fldi	$f0, $r0, 457
	fsti	$f0, $r0, 436
	fldi	$f0, $r0, 458
	fsti	$f0, $r0, 437
	fldi	$f0, $r0, 459
	fsti	$f0, $r0, 438
	ldi	$r3, $r4, 0
	ldi	$r6, $r4, 8
	fldi	$f0, $r6, 0
	fsti	$f0, $r0, 450
	fldi	$f0, $r6, 1
	fsti	$f0, $r0, 451
	fldi	$f0, $r6, 2
	fsti	$f0, $r0, 452
	sti	$r25, $r1, -1
	fsti	$f14, $r1, -2
	sti	$r19, $r1, -3
	fsti	$f11, $r1, -4
	sti	$r23, $r1, -5
	sti	$r22, $r1, -6
	sti	$r24, $r1, -7
	sti	$r21, $r1, -8
	sti	$r5, $r1, -9
	beq	$r3, $r30, bne_else.43385
	addi	$r6, $r0, 2
	beq	$r3, $r6, bne_else.43387
	addi	$r6, $r0, 3
	beq	$r3, $r6, bne_else.43389
	addi	$r6, $r0, 4
	beq	$r3, $r6, bne_else.43391
	j	bne_cont.43392
bne_else.43391:
	fldi	$f1, $r0, 457
	ldi	$r6, $r4, 5
	fldi	$f0, $r6, 0
	fsub	$f1, $f1, $f0
	ldi	$r7, $r4, 4
	fldi	$f0, $r7, 0
	fsqrt	$f0, $f0
	fmul	$f1, $f1, $f0
	fldi	$f2, $r0, 459
	fldi	$f0, $r6, 2
	fsub	$f2, $f2, $f0
	fldi	$f0, $r7, 2
	fsqrt	$f0, $f0
	fmul	$f2, $f2, $f0
	fmul	$f3, $f1, $f1
	fmul	$f0, $f2, $f2
	fadd	$f5, $f3, $f0
	fblt	$f1, $f16, fbge_else.43393
	fmov	$f0, $f1
	j	fbge_cont.43394
fbge_else.43393:
	fneg	$f0, $f1
fbge_cont.43394:
	# 0.000100
	fmvhi	$f6, 14545
	fmvlo	$f6, 46863
	fsti	$f6, $r1, -10
	fsti	$f5, $r1, -11
	sti	$r7, $r1, -12
	sti	$r6, $r1, -13
	fblt	$f0, $f6, fbge_else.43395
	fdiv	$f1, $f2, $f1
	fblt	$f1, $f16, fbge_else.43397
	fmov	$f0, $f1
	j	fbge_cont.43398
fbge_else.43397:
	fneg	$f0, $f1
fbge_cont.43398:
	fatan	$f0, $f0
	fmul	$f0, $f0, $f23
	fdiv	$f0, $f0, $f21
	j	fbge_cont.43396
fbge_else.43395:
	fmov	$f0, $f22
fbge_cont.43396:
	fsti	$f0, $r1, -14
	floor	$f1, $f0
	fldi	$f0, $r1, -14
	fsub	$f7, $f0, $f1
	fldi	$f1, $r0, 458
	ldi	$r6, $r1, -13
	fldi	$f0, $r6, 1
	fsub	$f1, $f1, $f0
	ldi	$r7, $r1, -12
	fldi	$f0, $r7, 1
	fsqrt	$f0, $f0
	fmul	$f1, $f1, $f0
	fldi	$f5, $r1, -11
	fblt	$f5, $f16, fbge_else.43399
	fmov	$f0, $f5
	j	fbge_cont.43400
fbge_else.43399:
	fneg	$f0, $f5
fbge_cont.43400:
	fldi	$f6, $r1, -10
	fsti	$f7, $r1, -15
	fblt	$f0, $f6, fbge_else.43401
	fdiv	$f1, $f1, $f5
	fblt	$f1, $f16, fbge_else.43403
	fmov	$f0, $f1
	j	fbge_cont.43404
fbge_else.43403:
	fneg	$f0, $f1
fbge_cont.43404:
	fatan	$f0, $f0
	fmul	$f0, $f0, $f23
	fdiv	$f0, $f0, $f21
	j	fbge_cont.43402
fbge_else.43401:
	fmov	$f0, $f22
fbge_cont.43402:
	fsti	$f0, $r1, -16
	floor	$f1, $f0
	fldi	$f0, $r1, -16
	fsub	$f0, $f0, $f1
	# 0.150000
	fmvhi	$f2, 15897
	fmvlo	$f2, 39321
	fldi	$f7, $r1, -15
	fsub	$f1, $f20, $f7
	fmul	$f1, $f1, $f1
	fsub	$f1, $f2, $f1
	fsub	$f0, $f20, $f0
	fmul	$f0, $f0, $f0
	fsub	$f1, $f1, $f0
	fblt	$f1, $f16, fbge_else.43405
	fmov	$f0, $f1
	j	fbge_cont.43406
fbge_else.43405:
	fmov	$f0, $f16
fbge_cont.43406:
	fmul	$f0, $f18, $f0
	fdiv	$f0, $f0, $f31
	fsti	$f0, $r0, 452
bne_cont.43392:
	j	bne_cont.43390
bne_else.43389:
	fldi	$f1, $r0, 457
	ldi	$r3, $r4, 5
	fldi	$f0, $r3, 0
	fsub	$f1, $f1, $f0
	fldi	$f2, $r0, 459
	fldi	$f0, $r3, 2
	fsub	$f0, $f2, $f0
	fmul	$f1, $f1, $f1
	fmul	$f0, $f0, $f0
	fadd	$f0, $f1, $f0
	fsqrt	$f0, $f0
	fdiv	$f0, $f0, $f24
	fsti	$f0, $r1, -10
	floor	$f1, $f0
	fldi	$f0, $r1, -10
	fsub	$f0, $f0, $f1
	fmul	$f0, $f0, $f21
	fcos	$f0, $f0
	fmul	$f0, $f0, $f0
	fmul	$f1, $f0, $f18
	fsti	$f1, $r0, 451
	fsub	$f0, $f17, $f0
	fmul	$f0, $f0, $f18
	fsti	$f0, $r0, 452
bne_cont.43390:
	j	bne_cont.43388
bne_else.43387:
	fldi	$f1, $r0, 458
	# 0.250000
	fmvhi	$f0, 16000
	fmvlo	$f0, 0
	fmul	$f0, $f1, $f0
	fsin	$f0, $f0
	fmul	$f0, $f0, $f0
	fmul	$f1, $f18, $f0
	fsti	$f1, $r0, 450
	fsub	$f0, $f17, $f0
	fmul	$f0, $f18, $f0
	fsti	$f0, $r0, 451
bne_cont.43388:
	j	bne_cont.43386
bne_else.43385:
	fldi	$f1, $r0, 457
	ldi	$r6, $r4, 5
	fldi	$f0, $r6, 0
	fsub	$f7, $f1, $f0
	# 0.050000
	fmvhi	$f5, 15692
	fmvlo	$f5, 52420
	fmul	$f0, $f7, $f5
	floor	$f0, $f0
	# 20.000000
	fmvhi	$f6, 16800
	fmvlo	$f6, 0
	fmul	$f0, $f0, $f6
	fsub	$f7, $f7, $f0
	fldi	$f1, $r0, 459
	fldi	$f0, $r6, 2
	fsub	$f8, $f1, $f0
	fmul	$f0, $f8, $f5
	floor	$f0, $f0
	fmul	$f0, $f0, $f6
	fsub	$f0, $f8, $f0
	fblt	$f7, $f24, fbge_else.43407
	fblt	$f0, $f24, fbge_else.43409
	fmov	$f7, $f18
	j	fbge_cont.43410
fbge_else.43409:
	fmov	$f7, $f16
fbge_cont.43410:
	j	fbge_cont.43408
fbge_else.43407:
	fblt	$f0, $f24, fbge_else.43411
	fmov	$f7, $f16
	j	fbge_cont.43412
fbge_else.43411:
	fmov	$f7, $f18
fbge_cont.43412:
fbge_cont.43408:
	fsti	$f7, $r0, 451
bne_cont.43386:
	ldi	$r5, $r1, -9
	slli	$r4, $r5, 2
	ldi	$r3, $r0, 461
	add	$r4, $r4, $r3
	ldi	$r21, $r1, -8
	slli	$r3, $r21, 0
	ldi	$r24, $r1, -7
	str	$r4, $r24, $r3
	ldi	$r22, $r1, -6
	ldi	$r4, $r22, 1
	slli	$r3, $r21, 0
	ldr	$r3, $r4, $r3
	fldi	$f0, $r0, 457
	fsti	$f0, $r3, 0
	fldi	$f0, $r0, 458
	fsti	$f0, $r3, 1
	fldi	$f0, $r0, 459
	fsti	$f0, $r3, 2
	ldi	$r4, $r22, 3
	ldi	$r23, $r1, -5
	fldi	$f0, $r23, 0
	fblt	$f0, $f20, fbge_else.43413
	addi	$r5, $r0, 1
	slli	$r3, $r21, 0
	str	$r5, $r4, $r3
	ldi	$r4, $r22, 4
	slli	$r3, $r21, 0
	ldr	$r3, $r4, $r3
	fldi	$f0, $r0, 450
	fsti	$f0, $r3, 0
	fldi	$f0, $r0, 451
	fsti	$f0, $r3, 1
	fldi	$f0, $r0, 452
	fsti	$f0, $r3, 2
	slli	$r3, $r21, 0
	ldr	$r3, $r4, $r3
	# 0.003906
	fmvhi	$f0, 15232
	fmvlo	$f0, 0
	fldi	$f11, $r1, -4
	fmul	$f0, $f0, $f11
	fldi	$f1, $r3, 0
	fmul	$f1, $f1, $f0
	fsti	$f1, $r3, 0
	fldi	$f1, $r3, 1
	fmul	$f1, $f1, $f0
	fsti	$f1, $r3, 1
	fldi	$f1, $r3, 2
	fmul	$f0, $f1, $f0
	fsti	$f0, $r3, 2
	ldi	$r4, $r22, 7
	slli	$r3, $r21, 0
	ldr	$r3, $r4, $r3
	fldi	$f0, $r0, 453
	fsti	$f0, $r3, 0
	fldi	$f0, $r0, 454
	fsti	$f0, $r3, 1
	fldi	$f0, $r0, 455
	fsti	$f0, $r3, 2
	j	fbge_cont.43414
fbge_else.43413:
	addi	$r5, $r0, 0
	slli	$r3, $r21, 0
	str	$r5, $r4, $r3
fbge_cont.43414:
	# -2.000000
	fmvhi	$f0, 49152
	fmvlo	$f0, 0
	ldi	$r19, $r1, -3
	fldi	$f2, $r19, 0
	fldi	$f1, $r0, 453
	fmul	$f5, $f2, $f1
	fldi	$f4, $r19, 1
	fldi	$f3, $r0, 454
	fmul	$f3, $f4, $f3
	fadd	$f5, $f5, $f3
	fldi	$f4, $r19, 2
	fldi	$f3, $r0, 455
	fmul	$f3, $f4, $f3
	fadd	$f3, $f5, $f3
	fmul	$f0, $f0, $f3
	fmul	$f1, $f0, $f1
	fadd	$f1, $f2, $f1
	fsti	$f1, $r19, 0
	fldi	$f2, $r19, 1
	fldi	$f1, $r0, 454
	fmul	$f1, $f0, $f1
	fadd	$f1, $f2, $f1
	fsti	$f1, $r19, 1
	fldi	$f2, $r19, 2
	fldi	$f1, $r0, 455
	fmul	$f0, $f0, $f1
	fadd	$f0, $f2, $f0
	fsti	$f0, $r19, 2
	fldi	$f0, $r23, 1
	fldi	$f14, $r1, -2
	fmul	$f10, $f14, $f0
	addi	$r12, $r0, 0
	ldi	$r13, $r0, 463
	sti	$r29, $r1, -11
	subi	$r1, $r1, 12
	jal	shadow_check_one_or_matrix.2874
	addi	$r1, $r1, 12
	ldi	$r29, $r1, -11
	beq	$r3, $r0, bne_else.43415
	j	bne_cont.43416
bne_else.43415:
	fldi	$f1, $r0, 453
	fldi	$f0, $r0, 515
	fmul	$f2, $f1, $f0
	fldi	$f1, $r0, 454
	fldi	$f3, $r0, 516
	fmul	$f1, $f1, $f3
	fadd	$f4, $f2, $f1
	fldi	$f1, $r0, 455
	fldi	$f2, $r0, 517
	fmul	$f1, $f1, $f2
	fadd	$f1, $f4, $f1
	fneg	$f1, $f1
	fldi	$f11, $r1, -4
	fmul	$f1, $f1, $f11
	fldi	$f4, $r19, 0
	fmul	$f4, $f4, $f0
	fldi	$f0, $r19, 1
	fmul	$f0, $f0, $f3
	fadd	$f3, $f4, $f0
	fldi	$f0, $r19, 2
	fmul	$f0, $f0, $f2
	fadd	$f0, $f3, $f0
	fneg	$f0, $f0
	fblt	$f16, $f1, fbge_else.43417
	j	fbge_cont.43418
fbge_else.43417:
	fldi	$f3, $r0, 444
	fldi	$f2, $r0, 450
	fmul	$f2, $f1, $f2
	fadd	$f2, $f3, $f2
	fsti	$f2, $r0, 444
	fldi	$f3, $r0, 445
	fldi	$f2, $r0, 451
	fmul	$f2, $f1, $f2
	fadd	$f2, $f3, $f2
	fsti	$f2, $r0, 445
	fldi	$f3, $r0, 446
	fldi	$f2, $r0, 452
	fmul	$f1, $f1, $f2
	fadd	$f1, $f3, $f1
	fsti	$f1, $r0, 446
fbge_cont.43418:
	fblt	$f16, $f0, fbge_else.43419
	j	fbge_cont.43420
fbge_else.43419:
	fmul	$f0, $f0, $f0
	fmul	$f0, $f0, $f0
	fmul	$f0, $f0, $f10
	fldi	$f1, $r0, 444
	fadd	$f1, $f1, $f0
	fsti	$f1, $r0, 444
	fldi	$f1, $r0, 445
	fadd	$f1, $f1, $f0
	fsti	$f1, $r0, 445
	fldi	$f1, $r0, 446
	fadd	$f0, $f1, $f0
	fsti	$f0, $r0, 446
fbge_cont.43420:
bne_cont.43416:
	fldi	$f0, $r0, 457
	fsti	$f0, $r0, 433
	fldi	$f0, $r0, 458
	fsti	$f0, $r0, 434
	fldi	$f0, $r0, 459
	fsti	$f0, $r0, 435
	ldi	$r3, $r0, 585
	subi	$r7, $r3, 1
	blt	$r7, $r0, bge_else.43421
	slli	$r3, $r7, 0
	ldi	$r3, $r3, 524
	ldi	$r6, $r3, 10
	ldi	$r5, $r3, 1
	fldi	$f1, $r0, 457
	ldi	$r4, $r3, 5
	fldi	$f0, $r4, 0
	fsub	$f0, $f1, $f0
	fsti	$f0, $r6, 0
	fldi	$f1, $r0, 458
	fldi	$f0, $r4, 1
	fsub	$f0, $f1, $f0
	fsti	$f0, $r6, 1
	fldi	$f1, $r0, 459
	fldi	$f0, $r4, 2
	fsub	$f0, $f1, $f0
	fsti	$f0, $r6, 2
	addi	$r4, $r0, 2
	beq	$r5, $r4, bne_else.43423
	addi	$r4, $r0, 2
	blt	$r4, $r5, ble_else.43425
	j	ble_cont.43426
ble_else.43425:
	fldi	$f2, $r6, 0
	fldi	$f1, $r6, 1
	fldi	$f0, $r6, 2
	fmul	$f4, $f2, $f2
	ldi	$r4, $r3, 4
	fldi	$f3, $r4, 0
	fmul	$f5, $f4, $f3
	fmul	$f4, $f1, $f1
	fldi	$f3, $r4, 1
	fmul	$f3, $f4, $f3
	fadd	$f5, $f5, $f3
	fmul	$f4, $f0, $f0
	fldi	$f3, $r4, 2
	fmul	$f3, $f4, $f3
	fadd	$f4, $f5, $f3
	ldi	$r4, $r3, 3
	beq	$r4, $r0, bne_else.43427
	fmul	$f5, $f1, $f0
	ldi	$r3, $r3, 9
	fldi	$f3, $r3, 0
	fmul	$f3, $f5, $f3
	fadd	$f4, $f4, $f3
	fmul	$f3, $f0, $f2
	fldi	$f0, $r3, 1
	fmul	$f0, $f3, $f0
	fadd	$f4, $f4, $f0
	fmul	$f1, $f2, $f1
	fldi	$f0, $r3, 2
	fmul	$f3, $f1, $f0
	fadd	$f3, $f4, $f3
	j	bne_cont.43428
bne_else.43427:
	fmov	$f3, $f4
bne_cont.43428:
	addi	$r3, $r0, 3
	beq	$r5, $r3, bne_else.43429
	fmov	$f0, $f3
	j	bne_cont.43430
bne_else.43429:
	fsub	$f0, $f3, $f17
bne_cont.43430:
	fsti	$f0, $r6, 3
ble_cont.43426:
	j	bne_cont.43424
bne_else.43423:
	ldi	$r3, $r3, 4
	fldi	$f1, $r6, 0
	fldi	$f3, $r6, 1
	fldi	$f2, $r6, 2
	fldi	$f0, $r3, 0
	fmul	$f1, $f0, $f1
	fldi	$f0, $r3, 1
	fmul	$f0, $f0, $f3
	fadd	$f1, $f1, $f0
	fldi	$f0, $r3, 2
	fmul	$f0, $f0, $f2
	fadd	$f0, $f1, $f0
	fsti	$f0, $r6, 3
bne_cont.43424:
	subi	$r4, $r7, 1
	subi	$r3, $r0, -457
	sti	$r29, $r1, -11
	subi	$r1, $r1, 12
	jal	setup_startp_constants.2837
	addi	$r1, $r1, 12
	ldi	$r29, $r1, -11
	j	bge_cont.43422
bge_else.43421:
bge_cont.43422:
	ldi	$r3, $r0, 162
	subi	$r17, $r3, 1
	fldi	$f11, $r1, -4
	sti	$r29, $r1, -11
	subi	$r1, $r1, 12
	jal	trace_reflections.2921
	addi	$r1, $r1, 12
	ldi	$r29, $r1, -11
	fblt	$f25, $f14, fbge_else.43431
	jr	$r29
fbge_else.43431:
	addi	$r3, $r0, 4
	blt	$r21, $r3, ble_else.43433
	j	ble_cont.43434
ble_else.43433:
	addi	$r3, $r21, 1
	addi	$r4, $r0, -1
	slli	$r3, $r3, 0
	str	$r4, $r24, $r3
ble_cont.43434:
	addi	$r3, $r0, 2
	ldi	$r25, $r1, -1
	beq	$r25, $r3, bne_else.43435
	jr	$r29
bne_else.43435:
	fldi	$f0, $r23, 0
	fsub	$f0, $f17, $f0
	fmul	$f14, $f14, $f0
	addi	$r21, $r21, 1
	fldi	$f0, $r0, 460
	fldi	$f12, $r1, 0
	fadd	$f12, $f12, $f0
	ldi	$r19, $r1, -3
	j	trace_ray.2926
bne_else.43370:
	addi	$r4, $r0, -1
	slli	$r3, $r21, 0
	str	$r4, $r24, $r3
	beq	$r21, $r0, bne_else.43437
	fldi	$f1, $r19, 0
	fldi	$f0, $r0, 515
	fmul	$f2, $f1, $f0
	fldi	$f1, $r19, 1
	fldi	$f0, $r0, 516
	fmul	$f0, $f1, $f0
	fadd	$f2, $f2, $f0
	fldi	$f1, $r19, 2
	fldi	$f0, $r0, 517
	fmul	$f0, $f1, $f0
	fadd	$f0, $f2, $f0
	fneg	$f0, $f0
	fblt	$f16, $f0, fbge_else.43438
	jr	$r29
fbge_else.43438:
	fmul	$f1, $f0, $f0
	fmul	$f0, $f1, $f0
	fmul	$f1, $f0, $f14
	fldi	$f0, $r0, 514
	fmul	$f0, $f1, $f0
	fldi	$f1, $r0, 444
	fadd	$f1, $f1, $f0
	fsti	$f1, $r0, 444
	fldi	$f1, $r0, 445
	fadd	$f1, $f1, $f0
	fsti	$f1, $r0, 445
	fldi	$f1, $r0, 446
	fadd	$f0, $f1, $f0
	fsti	$f0, $r0, 446
	jr	$r29
bne_else.43437:
	jr	$r29
ble_else.43365:
	jr	$r29

#---------------------------------------------------------------------
# args = [$r19, $r18, $r20, $r17]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
iter_trace_diffuse_rays.2935:
	blt	$r17, $r0, bge_else.43443
	slli	$r3, $r17, 0
	ldr	$r3, $r19, $r3
	ldi	$r3, $r3, 0
	fldi	$f1, $r3, 0
	fldi	$f0, $r18, 0
	fmul	$f2, $f1, $f0
	fldi	$f1, $r3, 1
	fldi	$f0, $r18, 1
	fmul	$f0, $f1, $f0
	fadd	$f2, $f2, $f0
	fldi	$f1, $r3, 2
	fldi	$f0, $r18, 2
	fmul	$f0, $f1, $f0
	fadd	$f0, $f2, $f0
	sti	$r20, $r1, 0
	sti	$r18, $r1, -1
	sti	$r19, $r1, -2
	sti	$r17, $r1, -3
	fblt	$f0, $f16, fbge_else.43444
	slli	$r3, $r17, 0
	ldr	$r10, $r19, $r3
	# 150.000000
	fmvhi	$f1, 17174
	fmvlo	$f1, 0
	fdiv	$f10, $f0, $f1
	fsti	$f26, $r0, 460
	addi	$r15, $r0, 0
	ldi	$r16, $r0, 463
	sti	$r10, $r1, -4
	sti	$r29, $r1, -6
	subi	$r1, $r1, 7
	jal	trace_or_matrix_fast.2899
	addi	$r1, $r1, 7
	ldi	$r29, $r1, -6
	fldi	$f0, $r0, 460
	fblt	$f27, $f0, fbge_else.43446
	addi	$r3, $r0, 0
	j	fbge_cont.43447
fbge_else.43446:
	fblt	$f0, $f28, fbge_else.43448
	addi	$r3, $r0, 0
	j	fbge_cont.43449
fbge_else.43448:
	addi	$r3, $r0, 1
fbge_cont.43449:
fbge_cont.43447:
	beq	$r3, $r0, bne_else.43450
	ldi	$r3, $r0, 456
	slli	$r3, $r3, 0
	ldi	$r14, $r3, 524
	ldi	$r10, $r1, -4
	ldi	$r4, $r10, 0
	ldi	$r3, $r14, 1
	beq	$r3, $r30, bne_else.43452
	addi	$r4, $r0, 2
	beq	$r3, $r4, bne_else.43454
	fldi	$f1, $r0, 457
	ldi	$r3, $r14, 5
	fldi	$f0, $r3, 0
	fsub	$f4, $f1, $f0
	fldi	$f1, $r0, 458
	fldi	$f0, $r3, 1
	fsub	$f3, $f1, $f0
	fldi	$f1, $r0, 459
	fldi	$f0, $r3, 2
	fsub	$f0, $f1, $f0
	ldi	$r3, $r14, 4
	fldi	$f1, $r3, 0
	fmul	$f2, $f4, $f1
	fldi	$f1, $r3, 1
	fmul	$f6, $f3, $f1
	fldi	$f1, $r3, 2
	fmul	$f7, $f0, $f1
	ldi	$r3, $r14, 3
	beq	$r3, $r0, bne_else.43456
	ldi	$r3, $r14, 9
	fldi	$f1, $r3, 2
	fmul	$f5, $f3, $f1
	fldi	$f1, $r3, 1
	fmul	$f1, $f0, $f1
	fadd	$f1, $f5, $f1
	fmul	$f1, $f1, $f20
	fadd	$f1, $f2, $f1
	fsti	$f1, $r0, 453
	fldi	$f1, $r3, 2
	fmul	$f2, $f4, $f1
	fldi	$f1, $r3, 0
	fmul	$f0, $f0, $f1
	fadd	$f0, $f2, $f0
	fmul	$f0, $f0, $f20
	fadd	$f0, $f6, $f0
	fsti	$f0, $r0, 454
	fldi	$f0, $r3, 1
	fmul	$f1, $f4, $f0
	fldi	$f0, $r3, 0
	fmul	$f0, $f3, $f0
	fadd	$f0, $f1, $f0
	fmul	$f0, $f0, $f20
	fadd	$f0, $f7, $f0
	fsti	$f0, $r0, 455
	j	bne_cont.43457
bne_else.43456:
	fsti	$f2, $r0, 453
	fsti	$f6, $r0, 454
	fsti	$f7, $r0, 455
bne_cont.43457:
	ldi	$r3, $r14, 6
	fldi	$f2, $r0, 453
	fmul	$f1, $f2, $f2
	fldi	$f0, $r0, 454
	fmul	$f0, $f0, $f0
	fadd	$f1, $f1, $f0
	fldi	$f0, $r0, 455
	fmul	$f0, $f0, $f0
	fadd	$f0, $f1, $f0
	fsqrt	$f1, $f0
	fbeq	$f1, $f16, fbne_else.43458
	beq	$r3, $r0, bne_else.43460
	fdiv	$f0, $f19, $f1
	j	bne_cont.43461
bne_else.43460:
	fdiv	$f0, $f17, $f1
bne_cont.43461:
	j	fbne_cont.43459
fbne_else.43458:
	fmov	$f0, $f17
fbne_cont.43459:
	fmul	$f1, $f2, $f0
	fsti	$f1, $r0, 453
	fldi	$f1, $r0, 454
	fmul	$f1, $f1, $f0
	fsti	$f1, $r0, 454
	fldi	$f1, $r0, 455
	fmul	$f0, $f1, $f0
	fsti	$f0, $r0, 455
	j	bne_cont.43455
bne_else.43454:
	ldi	$r3, $r14, 4
	fldi	$f0, $r3, 0
	fneg	$f0, $f0
	fsti	$f0, $r0, 453
	fldi	$f0, $r3, 1
	fneg	$f0, $f0
	fsti	$f0, $r0, 454
	fldi	$f0, $r3, 2
	fneg	$f0, $f0
	fsti	$f0, $r0, 455
bne_cont.43455:
	j	bne_cont.43453
bne_else.43452:
	ldi	$r3, $r0, 461
	fsti	$f16, $r0, 453
	fsti	$f16, $r0, 454
	fsti	$f16, $r0, 455
	subi	$r5, $r3, 1
	slli	$r3, $r5, 0
	fldr	$f1, $r4, $r3
	fbeq	$f1, $f16, fbne_else.43462
	fblt	$f16, $f1, fbge_else.43464
	fmov	$f0, $f19
	j	fbge_cont.43465
fbge_else.43464:
	fmov	$f0, $f17
fbge_cont.43465:
	j	fbne_cont.43463
fbne_else.43462:
	fmov	$f0, $f16
fbne_cont.43463:
	fneg	$f0, $f0
	slli	$r3, $r5, 0
	fsti	$f0, $r3, 453
bne_cont.43453:
	ldi	$r3, $r14, 0
	ldi	$r4, $r14, 8
	fldi	$f0, $r4, 0
	fsti	$f0, $r0, 450
	fldi	$f0, $r4, 1
	fsti	$f0, $r0, 451
	fldi	$f0, $r4, 2
	fsti	$f0, $r0, 452
	sti	$r14, $r1, -5
	fsti	$f10, $r1, -6
	beq	$r3, $r30, bne_else.43466
	addi	$r4, $r0, 2
	beq	$r3, $r4, bne_else.43468
	addi	$r4, $r0, 3
	beq	$r3, $r4, bne_else.43470
	addi	$r4, $r0, 4
	beq	$r3, $r4, bne_else.43472
	j	bne_cont.43473
bne_else.43472:
	fldi	$f1, $r0, 457
	ldi	$r5, $r14, 5
	fldi	$f0, $r5, 0
	fsub	$f1, $f1, $f0
	ldi	$r6, $r14, 4
	fldi	$f0, $r6, 0
	fsqrt	$f0, $f0
	fmul	$f1, $f1, $f0
	fldi	$f2, $r0, 459
	fldi	$f0, $r5, 2
	fsub	$f2, $f2, $f0
	fldi	$f0, $r6, 2
	fsqrt	$f0, $f0
	fmul	$f2, $f2, $f0
	fmul	$f3, $f1, $f1
	fmul	$f0, $f2, $f2
	fadd	$f5, $f3, $f0
	fblt	$f1, $f16, fbge_else.43474
	fmov	$f0, $f1
	j	fbge_cont.43475
fbge_else.43474:
	fneg	$f0, $f1
fbge_cont.43475:
	# 0.000100
	fmvhi	$f6, 14545
	fmvlo	$f6, 46863
	fsti	$f6, $r1, -7
	fsti	$f5, $r1, -8
	sti	$r6, $r1, -9
	sti	$r5, $r1, -10
	fblt	$f0, $f6, fbge_else.43476
	fdiv	$f1, $f2, $f1
	fblt	$f1, $f16, fbge_else.43478
	fmov	$f0, $f1
	j	fbge_cont.43479
fbge_else.43478:
	fneg	$f0, $f1
fbge_cont.43479:
	fatan	$f0, $f0
	fmul	$f0, $f0, $f23
	fdiv	$f0, $f0, $f21
	j	fbge_cont.43477
fbge_else.43476:
	fmov	$f0, $f22
fbge_cont.43477:
	fsti	$f0, $r1, -11
	floor	$f1, $f0
	fldi	$f0, $r1, -11
	fsub	$f7, $f0, $f1
	fldi	$f1, $r0, 458
	ldi	$r5, $r1, -10
	fldi	$f0, $r5, 1
	fsub	$f1, $f1, $f0
	ldi	$r6, $r1, -9
	fldi	$f0, $r6, 1
	fsqrt	$f0, $f0
	fmul	$f1, $f1, $f0
	fldi	$f5, $r1, -8
	fblt	$f5, $f16, fbge_else.43480
	fmov	$f0, $f5
	j	fbge_cont.43481
fbge_else.43480:
	fneg	$f0, $f5
fbge_cont.43481:
	fldi	$f6, $r1, -7
	fsti	$f7, $r1, -12
	fblt	$f0, $f6, fbge_else.43482
	fdiv	$f1, $f1, $f5
	fblt	$f1, $f16, fbge_else.43484
	fmov	$f0, $f1
	j	fbge_cont.43485
fbge_else.43484:
	fneg	$f0, $f1
fbge_cont.43485:
	fatan	$f0, $f0
	fmul	$f6, $f0, $f23
	fdiv	$f6, $f6, $f21
	j	fbge_cont.43483
fbge_else.43482:
	fmov	$f6, $f22
fbge_cont.43483:
	floor	$f0, $f6
	fsub	$f0, $f6, $f0
	# 0.150000
	fmvhi	$f2, 15897
	fmvlo	$f2, 39321
	fldi	$f7, $r1, -12
	fsub	$f1, $f20, $f7
	fmul	$f1, $f1, $f1
	fsub	$f1, $f2, $f1
	fsub	$f0, $f20, $f0
	fmul	$f0, $f0, $f0
	fsub	$f1, $f1, $f0
	fblt	$f1, $f16, fbge_else.43486
	fmov	$f0, $f1
	j	fbge_cont.43487
fbge_else.43486:
	fmov	$f0, $f16
fbge_cont.43487:
	fmul	$f0, $f18, $f0
	fdiv	$f0, $f0, $f31
	fsti	$f0, $r0, 452
bne_cont.43473:
	j	bne_cont.43471
bne_else.43470:
	fldi	$f1, $r0, 457
	ldi	$r3, $r14, 5
	fldi	$f0, $r3, 0
	fsub	$f1, $f1, $f0
	fldi	$f2, $r0, 459
	fldi	$f0, $r3, 2
	fsub	$f0, $f2, $f0
	fmul	$f1, $f1, $f1
	fmul	$f0, $f0, $f0
	fadd	$f0, $f1, $f0
	fsqrt	$f0, $f0
	fdiv	$f0, $f0, $f24
	fsti	$f0, $r1, -7
	floor	$f1, $f0
	fldi	$f0, $r1, -7
	fsub	$f0, $f0, $f1
	fmul	$f0, $f0, $f21
	fcos	$f0, $f0
	fmul	$f0, $f0, $f0
	fmul	$f1, $f0, $f18
	fsti	$f1, $r0, 451
	fsub	$f0, $f17, $f0
	fmul	$f0, $f0, $f18
	fsti	$f0, $r0, 452
bne_cont.43471:
	j	bne_cont.43469
bne_else.43468:
	fldi	$f1, $r0, 458
	# 0.250000
	fmvhi	$f0, 16000
	fmvlo	$f0, 0
	fmul	$f0, $f1, $f0
	fsin	$f0, $f0
	fmul	$f0, $f0, $f0
	fmul	$f1, $f18, $f0
	fsti	$f1, $r0, 450
	fsub	$f0, $f17, $f0
	fmul	$f0, $f18, $f0
	fsti	$f0, $r0, 451
bne_cont.43469:
	j	bne_cont.43467
bne_else.43466:
	fldi	$f1, $r0, 457
	ldi	$r5, $r14, 5
	fldi	$f0, $r5, 0
	fsub	$f5, $f1, $f0
	# 0.050000
	fmvhi	$f8, 15692
	fmvlo	$f8, 52420
	fmul	$f0, $f5, $f8
	floor	$f0, $f0
	# 20.000000
	fmvhi	$f7, 16800
	fmvlo	$f7, 0
	fmul	$f0, $f0, $f7
	fsub	$f6, $f5, $f0
	fldi	$f1, $r0, 459
	fldi	$f0, $r5, 2
	fsub	$f5, $f1, $f0
	fmul	$f0, $f5, $f8
	floor	$f0, $f0
	fmul	$f0, $f0, $f7
	fsub	$f1, $f5, $f0
	fblt	$f6, $f24, fbge_else.43488
	fblt	$f1, $f24, fbge_else.43490
	fmov	$f0, $f18
	j	fbge_cont.43491
fbge_else.43490:
	fmov	$f0, $f16
fbge_cont.43491:
	j	fbge_cont.43489
fbge_else.43488:
	fblt	$f1, $f24, fbge_else.43492
	fmov	$f0, $f16
	j	fbge_cont.43493
fbge_else.43492:
	fmov	$f0, $f18
fbge_cont.43493:
fbge_cont.43489:
	fsti	$f0, $r0, 451
bne_cont.43467:
	addi	$r12, $r0, 0
	ldi	$r13, $r0, 463
	sti	$r29, $r1, -8
	subi	$r1, $r1, 9
	jal	shadow_check_one_or_matrix.2874
	addi	$r1, $r1, 9
	ldi	$r29, $r1, -8
	beq	$r3, $r0, bne_else.43494
	j	bne_cont.43495
bne_else.43494:
	fldi	$f1, $r0, 453
	fldi	$f0, $r0, 515
	fmul	$f2, $f1, $f0
	fldi	$f1, $r0, 454
	fldi	$f0, $r0, 516
	fmul	$f0, $f1, $f0
	fadd	$f2, $f2, $f0
	fldi	$f1, $r0, 455
	fldi	$f0, $r0, 517
	fmul	$f0, $f1, $f0
	fadd	$f1, $f2, $f0
	fneg	$f1, $f1
	fblt	$f16, $f1, fbge_else.43496
	fmov	$f0, $f16
	j	fbge_cont.43497
fbge_else.43496:
	fmov	$f0, $f1
fbge_cont.43497:
	fldi	$f10, $r1, -6
	fmul	$f1, $f10, $f0
	ldi	$r14, $r1, -5
	ldi	$r3, $r14, 7
	fldi	$f0, $r3, 0
	fmul	$f0, $f1, $f0
	fldi	$f2, $r0, 447
	fldi	$f1, $r0, 450
	fmul	$f1, $f0, $f1
	fadd	$f1, $f2, $f1
	fsti	$f1, $r0, 447
	fldi	$f2, $r0, 448
	fldi	$f1, $r0, 451
	fmul	$f1, $f0, $f1
	fadd	$f1, $f2, $f1
	fsti	$f1, $r0, 448
	fldi	$f2, $r0, 449
	fldi	$f1, $r0, 452
	fmul	$f0, $f0, $f1
	fadd	$f0, $f2, $f0
	fsti	$f0, $r0, 449
bne_cont.43495:
	j	bne_cont.43451
bne_else.43450:
bne_cont.43451:
	j	fbge_cont.43445
fbge_else.43444:
	addi	$r3, $r17, 1
	slli	$r3, $r3, 0
	ldr	$r10, $r19, $r3
	# -150.000000
	fmvhi	$f1, 49942
	fmvlo	$f1, 0
	fdiv	$f10, $f0, $f1
	fsti	$f26, $r0, 460
	addi	$r15, $r0, 0
	ldi	$r16, $r0, 463
	sti	$r10, $r1, -4
	sti	$r29, $r1, -6
	subi	$r1, $r1, 7
	jal	trace_or_matrix_fast.2899
	addi	$r1, $r1, 7
	ldi	$r29, $r1, -6
	fldi	$f0, $r0, 460
	fblt	$f27, $f0, fbge_else.43498
	addi	$r3, $r0, 0
	j	fbge_cont.43499
fbge_else.43498:
	fblt	$f0, $f28, fbge_else.43500
	addi	$r3, $r0, 0
	j	fbge_cont.43501
fbge_else.43500:
	addi	$r3, $r0, 1
fbge_cont.43501:
fbge_cont.43499:
	beq	$r3, $r0, bne_else.43502
	ldi	$r3, $r0, 456
	slli	$r3, $r3, 0
	ldi	$r14, $r3, 524
	ldi	$r10, $r1, -4
	ldi	$r4, $r10, 0
	ldi	$r3, $r14, 1
	beq	$r3, $r30, bne_else.43504
	addi	$r4, $r0, 2
	beq	$r3, $r4, bne_else.43506
	fldi	$f1, $r0, 457
	ldi	$r3, $r14, 5
	fldi	$f0, $r3, 0
	fsub	$f4, $f1, $f0
	fldi	$f1, $r0, 458
	fldi	$f0, $r3, 1
	fsub	$f3, $f1, $f0
	fldi	$f1, $r0, 459
	fldi	$f0, $r3, 2
	fsub	$f0, $f1, $f0
	ldi	$r3, $r14, 4
	fldi	$f1, $r3, 0
	fmul	$f2, $f4, $f1
	fldi	$f1, $r3, 1
	fmul	$f6, $f3, $f1
	fldi	$f1, $r3, 2
	fmul	$f7, $f0, $f1
	ldi	$r3, $r14, 3
	beq	$r3, $r0, bne_else.43508
	ldi	$r3, $r14, 9
	fldi	$f1, $r3, 2
	fmul	$f5, $f3, $f1
	fldi	$f1, $r3, 1
	fmul	$f1, $f0, $f1
	fadd	$f1, $f5, $f1
	fmul	$f1, $f1, $f20
	fadd	$f1, $f2, $f1
	fsti	$f1, $r0, 453
	fldi	$f1, $r3, 2
	fmul	$f2, $f4, $f1
	fldi	$f1, $r3, 0
	fmul	$f0, $f0, $f1
	fadd	$f0, $f2, $f0
	fmul	$f0, $f0, $f20
	fadd	$f0, $f6, $f0
	fsti	$f0, $r0, 454
	fldi	$f0, $r3, 1
	fmul	$f1, $f4, $f0
	fldi	$f0, $r3, 0
	fmul	$f0, $f3, $f0
	fadd	$f0, $f1, $f0
	fmul	$f0, $f0, $f20
	fadd	$f0, $f7, $f0
	fsti	$f0, $r0, 455
	j	bne_cont.43509
bne_else.43508:
	fsti	$f2, $r0, 453
	fsti	$f6, $r0, 454
	fsti	$f7, $r0, 455
bne_cont.43509:
	ldi	$r3, $r14, 6
	fldi	$f2, $r0, 453
	fmul	$f1, $f2, $f2
	fldi	$f0, $r0, 454
	fmul	$f0, $f0, $f0
	fadd	$f1, $f1, $f0
	fldi	$f0, $r0, 455
	fmul	$f0, $f0, $f0
	fadd	$f0, $f1, $f0
	fsqrt	$f1, $f0
	fbeq	$f1, $f16, fbne_else.43510
	beq	$r3, $r0, bne_else.43512
	fdiv	$f0, $f19, $f1
	j	bne_cont.43513
bne_else.43512:
	fdiv	$f0, $f17, $f1
bne_cont.43513:
	j	fbne_cont.43511
fbne_else.43510:
	fmov	$f0, $f17
fbne_cont.43511:
	fmul	$f1, $f2, $f0
	fsti	$f1, $r0, 453
	fldi	$f1, $r0, 454
	fmul	$f1, $f1, $f0
	fsti	$f1, $r0, 454
	fldi	$f1, $r0, 455
	fmul	$f0, $f1, $f0
	fsti	$f0, $r0, 455
	j	bne_cont.43507
bne_else.43506:
	ldi	$r3, $r14, 4
	fldi	$f0, $r3, 0
	fneg	$f0, $f0
	fsti	$f0, $r0, 453
	fldi	$f0, $r3, 1
	fneg	$f0, $f0
	fsti	$f0, $r0, 454
	fldi	$f0, $r3, 2
	fneg	$f0, $f0
	fsti	$f0, $r0, 455
bne_cont.43507:
	j	bne_cont.43505
bne_else.43504:
	ldi	$r3, $r0, 461
	fsti	$f16, $r0, 453
	fsti	$f16, $r0, 454
	fsti	$f16, $r0, 455
	subi	$r5, $r3, 1
	slli	$r3, $r5, 0
	fldr	$f1, $r4, $r3
	fbeq	$f1, $f16, fbne_else.43514
	fblt	$f16, $f1, fbge_else.43516
	fmov	$f0, $f19
	j	fbge_cont.43517
fbge_else.43516:
	fmov	$f0, $f17
fbge_cont.43517:
	j	fbne_cont.43515
fbne_else.43514:
	fmov	$f0, $f16
fbne_cont.43515:
	fneg	$f0, $f0
	slli	$r3, $r5, 0
	fsti	$f0, $r3, 453
bne_cont.43505:
	ldi	$r3, $r14, 0
	ldi	$r4, $r14, 8
	fldi	$f0, $r4, 0
	fsti	$f0, $r0, 450
	fldi	$f0, $r4, 1
	fsti	$f0, $r0, 451
	fldi	$f0, $r4, 2
	fsti	$f0, $r0, 452
	sti	$r14, $r1, -5
	fsti	$f10, $r1, -6
	beq	$r3, $r30, bne_else.43518
	addi	$r4, $r0, 2
	beq	$r3, $r4, bne_else.43520
	addi	$r4, $r0, 3
	beq	$r3, $r4, bne_else.43522
	addi	$r4, $r0, 4
	beq	$r3, $r4, bne_else.43524
	j	bne_cont.43525
bne_else.43524:
	fldi	$f1, $r0, 457
	ldi	$r5, $r14, 5
	fldi	$f0, $r5, 0
	fsub	$f1, $f1, $f0
	ldi	$r6, $r14, 4
	fldi	$f0, $r6, 0
	fsqrt	$f0, $f0
	fmul	$f1, $f1, $f0
	fldi	$f2, $r0, 459
	fldi	$f0, $r5, 2
	fsub	$f2, $f2, $f0
	fldi	$f0, $r6, 2
	fsqrt	$f0, $f0
	fmul	$f2, $f2, $f0
	fmul	$f3, $f1, $f1
	fmul	$f0, $f2, $f2
	fadd	$f5, $f3, $f0
	fblt	$f1, $f16, fbge_else.43526
	fmov	$f0, $f1
	j	fbge_cont.43527
fbge_else.43526:
	fneg	$f0, $f1
fbge_cont.43527:
	# 0.000100
	fmvhi	$f6, 14545
	fmvlo	$f6, 46863
	fsti	$f6, $r1, -7
	fsti	$f5, $r1, -8
	sti	$r6, $r1, -9
	sti	$r5, $r1, -10
	fblt	$f0, $f6, fbge_else.43528
	fdiv	$f1, $f2, $f1
	fblt	$f1, $f16, fbge_else.43530
	fmov	$f0, $f1
	j	fbge_cont.43531
fbge_else.43530:
	fneg	$f0, $f1
fbge_cont.43531:
	fatan	$f0, $f0
	fmul	$f0, $f0, $f23
	fdiv	$f0, $f0, $f21
	j	fbge_cont.43529
fbge_else.43528:
	fmov	$f0, $f22
fbge_cont.43529:
	fsti	$f0, $r1, -11
	floor	$f1, $f0
	fldi	$f0, $r1, -11
	fsub	$f7, $f0, $f1
	fldi	$f1, $r0, 458
	ldi	$r5, $r1, -10
	fldi	$f0, $r5, 1
	fsub	$f1, $f1, $f0
	ldi	$r6, $r1, -9
	fldi	$f0, $r6, 1
	fsqrt	$f0, $f0
	fmul	$f1, $f1, $f0
	fldi	$f5, $r1, -8
	fblt	$f5, $f16, fbge_else.43532
	fmov	$f0, $f5
	j	fbge_cont.43533
fbge_else.43532:
	fneg	$f0, $f5
fbge_cont.43533:
	fldi	$f6, $r1, -7
	fsti	$f7, $r1, -12
	fblt	$f0, $f6, fbge_else.43534
	fdiv	$f1, $f1, $f5
	fblt	$f1, $f16, fbge_else.43536
	fmov	$f0, $f1
	j	fbge_cont.43537
fbge_else.43536:
	fneg	$f0, $f1
fbge_cont.43537:
	fatan	$f0, $f0
	fmul	$f6, $f0, $f23
	fdiv	$f6, $f6, $f21
	j	fbge_cont.43535
fbge_else.43534:
	fmov	$f6, $f22
fbge_cont.43535:
	floor	$f0, $f6
	fsub	$f0, $f6, $f0
	# 0.150000
	fmvhi	$f2, 15897
	fmvlo	$f2, 39321
	fldi	$f7, $r1, -12
	fsub	$f1, $f20, $f7
	fmul	$f1, $f1, $f1
	fsub	$f1, $f2, $f1
	fsub	$f0, $f20, $f0
	fmul	$f0, $f0, $f0
	fsub	$f1, $f1, $f0
	fblt	$f1, $f16, fbge_else.43538
	fmov	$f0, $f1
	j	fbge_cont.43539
fbge_else.43538:
	fmov	$f0, $f16
fbge_cont.43539:
	fmul	$f0, $f18, $f0
	fdiv	$f0, $f0, $f31
	fsti	$f0, $r0, 452
bne_cont.43525:
	j	bne_cont.43523
bne_else.43522:
	fldi	$f1, $r0, 457
	ldi	$r3, $r14, 5
	fldi	$f0, $r3, 0
	fsub	$f1, $f1, $f0
	fldi	$f2, $r0, 459
	fldi	$f0, $r3, 2
	fsub	$f0, $f2, $f0
	fmul	$f1, $f1, $f1
	fmul	$f0, $f0, $f0
	fadd	$f0, $f1, $f0
	fsqrt	$f0, $f0
	fdiv	$f0, $f0, $f24
	fsti	$f0, $r1, -7
	floor	$f1, $f0
	fldi	$f0, $r1, -7
	fsub	$f0, $f0, $f1
	fmul	$f0, $f0, $f21
	fcos	$f0, $f0
	fmul	$f0, $f0, $f0
	fmul	$f1, $f0, $f18
	fsti	$f1, $r0, 451
	fsub	$f0, $f17, $f0
	fmul	$f0, $f0, $f18
	fsti	$f0, $r0, 452
bne_cont.43523:
	j	bne_cont.43521
bne_else.43520:
	fldi	$f1, $r0, 458
	# 0.250000
	fmvhi	$f0, 16000
	fmvlo	$f0, 0
	fmul	$f0, $f1, $f0
	fsin	$f0, $f0
	fmul	$f0, $f0, $f0
	fmul	$f1, $f18, $f0
	fsti	$f1, $r0, 450
	fsub	$f0, $f17, $f0
	fmul	$f0, $f18, $f0
	fsti	$f0, $r0, 451
bne_cont.43521:
	j	bne_cont.43519
bne_else.43518:
	fldi	$f1, $r0, 457
	ldi	$r5, $r14, 5
	fldi	$f0, $r5, 0
	fsub	$f5, $f1, $f0
	# 0.050000
	fmvhi	$f8, 15692
	fmvlo	$f8, 52420
	fmul	$f0, $f5, $f8
	floor	$f0, $f0
	# 20.000000
	fmvhi	$f7, 16800
	fmvlo	$f7, 0
	fmul	$f0, $f0, $f7
	fsub	$f6, $f5, $f0
	fldi	$f1, $r0, 459
	fldi	$f0, $r5, 2
	fsub	$f5, $f1, $f0
	fmul	$f0, $f5, $f8
	floor	$f0, $f0
	fmul	$f0, $f0, $f7
	fsub	$f1, $f5, $f0
	fblt	$f6, $f24, fbge_else.43540
	fblt	$f1, $f24, fbge_else.43542
	fmov	$f0, $f18
	j	fbge_cont.43543
fbge_else.43542:
	fmov	$f0, $f16
fbge_cont.43543:
	j	fbge_cont.43541
fbge_else.43540:
	fblt	$f1, $f24, fbge_else.43544
	fmov	$f0, $f16
	j	fbge_cont.43545
fbge_else.43544:
	fmov	$f0, $f18
fbge_cont.43545:
fbge_cont.43541:
	fsti	$f0, $r0, 451
bne_cont.43519:
	addi	$r12, $r0, 0
	ldi	$r13, $r0, 463
	sti	$r29, $r1, -8
	subi	$r1, $r1, 9
	jal	shadow_check_one_or_matrix.2874
	addi	$r1, $r1, 9
	ldi	$r29, $r1, -8
	beq	$r3, $r0, bne_else.43546
	j	bne_cont.43547
bne_else.43546:
	fldi	$f1, $r0, 453
	fldi	$f0, $r0, 515
	fmul	$f2, $f1, $f0
	fldi	$f1, $r0, 454
	fldi	$f0, $r0, 516
	fmul	$f0, $f1, $f0
	fadd	$f2, $f2, $f0
	fldi	$f1, $r0, 455
	fldi	$f0, $r0, 517
	fmul	$f0, $f1, $f0
	fadd	$f1, $f2, $f0
	fneg	$f1, $f1
	fblt	$f16, $f1, fbge_else.43548
	fmov	$f0, $f16
	j	fbge_cont.43549
fbge_else.43548:
	fmov	$f0, $f1
fbge_cont.43549:
	fldi	$f10, $r1, -6
	fmul	$f1, $f10, $f0
	ldi	$r14, $r1, -5
	ldi	$r3, $r14, 7
	fldi	$f0, $r3, 0
	fmul	$f0, $f1, $f0
	fldi	$f2, $r0, 447
	fldi	$f1, $r0, 450
	fmul	$f1, $f0, $f1
	fadd	$f1, $f2, $f1
	fsti	$f1, $r0, 447
	fldi	$f2, $r0, 448
	fldi	$f1, $r0, 451
	fmul	$f1, $f0, $f1
	fadd	$f1, $f2, $f1
	fsti	$f1, $r0, 448
	fldi	$f2, $r0, 449
	fldi	$f1, $r0, 452
	fmul	$f0, $f0, $f1
	fadd	$f0, $f2, $f0
	fsti	$f0, $r0, 449
bne_cont.43547:
	j	bne_cont.43503
bne_else.43502:
bne_cont.43503:
fbge_cont.43445:
	ldi	$r17, $r1, -3
	subi	$r17, $r17, 2
	ldi	$r19, $r1, -2
	ldi	$r18, $r1, -1
	ldi	$r20, $r1, 0
	j	iter_trace_diffuse_rays.2935
bge_else.43443:
	jr	$r29

#---------------------------------------------------------------------
# args = [$r11, $r10]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
do_without_neighbors.2957:
	addi	$r3, $r0, 4
	blt	$r3, $r10, ble_else.43551
	ldi	$r4, $r11, 2
	slli	$r3, $r10, 0
	ldr	$r3, $r4, $r3
	blt	$r3, $r0, bge_else.43552
	ldi	$r4, $r11, 3
	slli	$r3, $r10, 0
	ldr	$r3, $r4, $r3
	sti	$r11, $r1, 0
	beq	$r3, $r0, bne_else.43553
	ldi	$r4, $r11, 5
	ldi	$r5, $r11, 7
	ldi	$r6, $r11, 1
	ldi	$r12, $r11, 4
	slli	$r3, $r10, 0
	ldr	$r3, $r4, $r3
	fldi	$f0, $r3, 0
	fsti	$f0, $r0, 447
	fldi	$f0, $r3, 1
	fsti	$f0, $r0, 448
	fldi	$f0, $r3, 2
	fsti	$f0, $r0, 449
	ldi	$r3, $r11, 6
	ldi	$r9, $r3, 0
	slli	$r3, $r10, 0
	ldr	$r18, $r5, $r3
	slli	$r3, $r10, 0
	ldr	$r20, $r6, $r3
	sti	$r12, $r1, -1
	sti	$r10, $r1, -2
	sti	$r18, $r1, -3
	sti	$r20, $r1, -4
	sti	$r9, $r1, -5
	beq	$r9, $r0, bne_else.43555
	ldi	$r19, $r0, 413
	fldi	$f0, $r20, 0
	fsti	$f0, $r0, 433
	fldi	$f0, $r20, 1
	fsti	$f0, $r0, 434
	fldi	$f0, $r20, 2
	fsti	$f0, $r0, 435
	ldi	$r3, $r0, 585
	subi	$r7, $r3, 1
	blt	$r7, $r0, bge_else.43557
	slli	$r3, $r7, 0
	ldi	$r3, $r3, 524
	ldi	$r6, $r3, 10
	ldi	$r5, $r3, 1
	fldi	$f1, $r20, 0
	ldi	$r4, $r3, 5
	fldi	$f0, $r4, 0
	fsub	$f0, $f1, $f0
	fsti	$f0, $r6, 0
	fldi	$f1, $r20, 1
	fldi	$f0, $r4, 1
	fsub	$f0, $f1, $f0
	fsti	$f0, $r6, 1
	fldi	$f1, $r20, 2
	fldi	$f0, $r4, 2
	fsub	$f0, $f1, $f0
	fsti	$f0, $r6, 2
	addi	$r4, $r0, 2
	beq	$r5, $r4, bne_else.43559
	addi	$r4, $r0, 2
	blt	$r4, $r5, ble_else.43561
	j	ble_cont.43562
ble_else.43561:
	fldi	$f2, $r6, 0
	fldi	$f1, $r6, 1
	fldi	$f0, $r6, 2
	fmul	$f4, $f2, $f2
	ldi	$r4, $r3, 4
	fldi	$f3, $r4, 0
	fmul	$f5, $f4, $f3
	fmul	$f4, $f1, $f1
	fldi	$f3, $r4, 1
	fmul	$f3, $f4, $f3
	fadd	$f5, $f5, $f3
	fmul	$f4, $f0, $f0
	fldi	$f3, $r4, 2
	fmul	$f3, $f4, $f3
	fadd	$f4, $f5, $f3
	ldi	$r4, $r3, 3
	beq	$r4, $r0, bne_else.43563
	fmul	$f5, $f1, $f0
	ldi	$r3, $r3, 9
	fldi	$f3, $r3, 0
	fmul	$f3, $f5, $f3
	fadd	$f4, $f4, $f3
	fmul	$f3, $f0, $f2
	fldi	$f0, $r3, 1
	fmul	$f0, $f3, $f0
	fadd	$f4, $f4, $f0
	fmul	$f1, $f2, $f1
	fldi	$f0, $r3, 2
	fmul	$f3, $f1, $f0
	fadd	$f3, $f4, $f3
	j	bne_cont.43564
bne_else.43563:
	fmov	$f3, $f4
bne_cont.43564:
	addi	$r3, $r0, 3
	beq	$r5, $r3, bne_else.43565
	fmov	$f0, $f3
	j	bne_cont.43566
bne_else.43565:
	fsub	$f0, $f3, $f17
bne_cont.43566:
	fsti	$f0, $r6, 3
ble_cont.43562:
	j	bne_cont.43560
bne_else.43559:
	ldi	$r3, $r3, 4
	fldi	$f1, $r6, 0
	fldi	$f3, $r6, 1
	fldi	$f2, $r6, 2
	fldi	$f0, $r3, 0
	fmul	$f1, $f0, $f1
	fldi	$f0, $r3, 1
	fmul	$f0, $f0, $f3
	fadd	$f1, $f1, $f0
	fldi	$f0, $r3, 2
	fmul	$f0, $f0, $f2
	fadd	$f0, $f1, $f0
	fsti	$f0, $r6, 3
bne_cont.43560:
	subi	$r4, $r7, 1
	mov	$r3, $r20
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	setup_startp_constants.2837
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
	j	bge_cont.43558
bge_else.43557:
bge_cont.43558:
	addi	$r17, $r0, 118
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	iter_trace_diffuse_rays.2935
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
	j	bne_cont.43556
bne_else.43555:
bne_cont.43556:
	ldi	$r9, $r1, -5
	beq	$r9, $r30, bne_else.43567
	ldi	$r19, $r0, 414
	ldi	$r20, $r1, -4
	fldi	$f0, $r20, 0
	fsti	$f0, $r0, 433
	fldi	$f0, $r20, 1
	fsti	$f0, $r0, 434
	fldi	$f0, $r20, 2
	fsti	$f0, $r0, 435
	ldi	$r3, $r0, 585
	subi	$r7, $r3, 1
	blt	$r7, $r0, bge_else.43569
	slli	$r3, $r7, 0
	ldi	$r3, $r3, 524
	ldi	$r6, $r3, 10
	ldi	$r5, $r3, 1
	fldi	$f1, $r20, 0
	ldi	$r4, $r3, 5
	fldi	$f0, $r4, 0
	fsub	$f0, $f1, $f0
	fsti	$f0, $r6, 0
	fldi	$f1, $r20, 1
	fldi	$f0, $r4, 1
	fsub	$f0, $f1, $f0
	fsti	$f0, $r6, 1
	fldi	$f1, $r20, 2
	fldi	$f0, $r4, 2
	fsub	$f0, $f1, $f0
	fsti	$f0, $r6, 2
	addi	$r4, $r0, 2
	beq	$r5, $r4, bne_else.43571
	addi	$r4, $r0, 2
	blt	$r4, $r5, ble_else.43573
	j	ble_cont.43574
ble_else.43573:
	fldi	$f2, $r6, 0
	fldi	$f1, $r6, 1
	fldi	$f0, $r6, 2
	fmul	$f4, $f2, $f2
	ldi	$r4, $r3, 4
	fldi	$f3, $r4, 0
	fmul	$f5, $f4, $f3
	fmul	$f4, $f1, $f1
	fldi	$f3, $r4, 1
	fmul	$f3, $f4, $f3
	fadd	$f5, $f5, $f3
	fmul	$f4, $f0, $f0
	fldi	$f3, $r4, 2
	fmul	$f3, $f4, $f3
	fadd	$f4, $f5, $f3
	ldi	$r4, $r3, 3
	beq	$r4, $r0, bne_else.43575
	fmul	$f5, $f1, $f0
	ldi	$r3, $r3, 9
	fldi	$f3, $r3, 0
	fmul	$f3, $f5, $f3
	fadd	$f4, $f4, $f3
	fmul	$f3, $f0, $f2
	fldi	$f0, $r3, 1
	fmul	$f0, $f3, $f0
	fadd	$f4, $f4, $f0
	fmul	$f1, $f2, $f1
	fldi	$f0, $r3, 2
	fmul	$f3, $f1, $f0
	fadd	$f3, $f4, $f3
	j	bne_cont.43576
bne_else.43575:
	fmov	$f3, $f4
bne_cont.43576:
	addi	$r3, $r0, 3
	beq	$r5, $r3, bne_else.43577
	fmov	$f0, $f3
	j	bne_cont.43578
bne_else.43577:
	fsub	$f0, $f3, $f17
bne_cont.43578:
	fsti	$f0, $r6, 3
ble_cont.43574:
	j	bne_cont.43572
bne_else.43571:
	ldi	$r3, $r3, 4
	fldi	$f1, $r6, 0
	fldi	$f3, $r6, 1
	fldi	$f2, $r6, 2
	fldi	$f0, $r3, 0
	fmul	$f1, $f0, $f1
	fldi	$f0, $r3, 1
	fmul	$f0, $f0, $f3
	fadd	$f1, $f1, $f0
	fldi	$f0, $r3, 2
	fmul	$f0, $f0, $f2
	fadd	$f0, $f1, $f0
	fsti	$f0, $r6, 3
bne_cont.43572:
	subi	$r4, $r7, 1
	mov	$r3, $r20
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	setup_startp_constants.2837
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
	j	bge_cont.43570
bge_else.43569:
bge_cont.43570:
	addi	$r17, $r0, 118
	ldi	$r18, $r1, -3
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	iter_trace_diffuse_rays.2935
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
	j	bne_cont.43568
bne_else.43567:
bne_cont.43568:
	addi	$r3, $r0, 2
	ldi	$r9, $r1, -5
	beq	$r9, $r3, bne_else.43579
	ldi	$r19, $r0, 415
	ldi	$r20, $r1, -4
	fldi	$f0, $r20, 0
	fsti	$f0, $r0, 433
	fldi	$f0, $r20, 1
	fsti	$f0, $r0, 434
	fldi	$f0, $r20, 2
	fsti	$f0, $r0, 435
	ldi	$r3, $r0, 585
	subi	$r7, $r3, 1
	blt	$r7, $r0, bge_else.43581
	slli	$r3, $r7, 0
	ldi	$r3, $r3, 524
	ldi	$r6, $r3, 10
	ldi	$r5, $r3, 1
	fldi	$f1, $r20, 0
	ldi	$r4, $r3, 5
	fldi	$f0, $r4, 0
	fsub	$f0, $f1, $f0
	fsti	$f0, $r6, 0
	fldi	$f1, $r20, 1
	fldi	$f0, $r4, 1
	fsub	$f0, $f1, $f0
	fsti	$f0, $r6, 1
	fldi	$f1, $r20, 2
	fldi	$f0, $r4, 2
	fsub	$f0, $f1, $f0
	fsti	$f0, $r6, 2
	addi	$r4, $r0, 2
	beq	$r5, $r4, bne_else.43583
	addi	$r4, $r0, 2
	blt	$r4, $r5, ble_else.43585
	j	ble_cont.43586
ble_else.43585:
	fldi	$f2, $r6, 0
	fldi	$f1, $r6, 1
	fldi	$f0, $r6, 2
	fmul	$f4, $f2, $f2
	ldi	$r4, $r3, 4
	fldi	$f3, $r4, 0
	fmul	$f5, $f4, $f3
	fmul	$f4, $f1, $f1
	fldi	$f3, $r4, 1
	fmul	$f3, $f4, $f3
	fadd	$f5, $f5, $f3
	fmul	$f4, $f0, $f0
	fldi	$f3, $r4, 2
	fmul	$f3, $f4, $f3
	fadd	$f4, $f5, $f3
	ldi	$r4, $r3, 3
	beq	$r4, $r0, bne_else.43587
	fmul	$f5, $f1, $f0
	ldi	$r3, $r3, 9
	fldi	$f3, $r3, 0
	fmul	$f3, $f5, $f3
	fadd	$f4, $f4, $f3
	fmul	$f3, $f0, $f2
	fldi	$f0, $r3, 1
	fmul	$f0, $f3, $f0
	fadd	$f4, $f4, $f0
	fmul	$f1, $f2, $f1
	fldi	$f0, $r3, 2
	fmul	$f3, $f1, $f0
	fadd	$f3, $f4, $f3
	j	bne_cont.43588
bne_else.43587:
	fmov	$f3, $f4
bne_cont.43588:
	addi	$r3, $r0, 3
	beq	$r5, $r3, bne_else.43589
	fmov	$f0, $f3
	j	bne_cont.43590
bne_else.43589:
	fsub	$f0, $f3, $f17
bne_cont.43590:
	fsti	$f0, $r6, 3
ble_cont.43586:
	j	bne_cont.43584
bne_else.43583:
	ldi	$r3, $r3, 4
	fldi	$f1, $r6, 0
	fldi	$f3, $r6, 1
	fldi	$f2, $r6, 2
	fldi	$f0, $r3, 0
	fmul	$f1, $f0, $f1
	fldi	$f0, $r3, 1
	fmul	$f0, $f0, $f3
	fadd	$f1, $f1, $f0
	fldi	$f0, $r3, 2
	fmul	$f0, $f0, $f2
	fadd	$f0, $f1, $f0
	fsti	$f0, $r6, 3
bne_cont.43584:
	subi	$r4, $r7, 1
	mov	$r3, $r20
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	setup_startp_constants.2837
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
	j	bge_cont.43582
bge_else.43581:
bge_cont.43582:
	addi	$r17, $r0, 118
	ldi	$r18, $r1, -3
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	iter_trace_diffuse_rays.2935
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
	j	bne_cont.43580
bne_else.43579:
bne_cont.43580:
	addi	$r3, $r0, 3
	ldi	$r9, $r1, -5
	beq	$r9, $r3, bne_else.43591
	ldi	$r19, $r0, 416
	ldi	$r20, $r1, -4
	fldi	$f0, $r20, 0
	fsti	$f0, $r0, 433
	fldi	$f0, $r20, 1
	fsti	$f0, $r0, 434
	fldi	$f0, $r20, 2
	fsti	$f0, $r0, 435
	ldi	$r3, $r0, 585
	subi	$r7, $r3, 1
	blt	$r7, $r0, bge_else.43593
	slli	$r3, $r7, 0
	ldi	$r3, $r3, 524
	ldi	$r6, $r3, 10
	ldi	$r5, $r3, 1
	fldi	$f1, $r20, 0
	ldi	$r4, $r3, 5
	fldi	$f0, $r4, 0
	fsub	$f0, $f1, $f0
	fsti	$f0, $r6, 0
	fldi	$f1, $r20, 1
	fldi	$f0, $r4, 1
	fsub	$f0, $f1, $f0
	fsti	$f0, $r6, 1
	fldi	$f1, $r20, 2
	fldi	$f0, $r4, 2
	fsub	$f0, $f1, $f0
	fsti	$f0, $r6, 2
	addi	$r4, $r0, 2
	beq	$r5, $r4, bne_else.43595
	addi	$r4, $r0, 2
	blt	$r4, $r5, ble_else.43597
	j	ble_cont.43598
ble_else.43597:
	fldi	$f2, $r6, 0
	fldi	$f1, $r6, 1
	fldi	$f0, $r6, 2
	fmul	$f4, $f2, $f2
	ldi	$r4, $r3, 4
	fldi	$f3, $r4, 0
	fmul	$f5, $f4, $f3
	fmul	$f4, $f1, $f1
	fldi	$f3, $r4, 1
	fmul	$f3, $f4, $f3
	fadd	$f5, $f5, $f3
	fmul	$f4, $f0, $f0
	fldi	$f3, $r4, 2
	fmul	$f3, $f4, $f3
	fadd	$f4, $f5, $f3
	ldi	$r4, $r3, 3
	beq	$r4, $r0, bne_else.43599
	fmul	$f5, $f1, $f0
	ldi	$r3, $r3, 9
	fldi	$f3, $r3, 0
	fmul	$f3, $f5, $f3
	fadd	$f4, $f4, $f3
	fmul	$f3, $f0, $f2
	fldi	$f0, $r3, 1
	fmul	$f0, $f3, $f0
	fadd	$f4, $f4, $f0
	fmul	$f1, $f2, $f1
	fldi	$f0, $r3, 2
	fmul	$f3, $f1, $f0
	fadd	$f3, $f4, $f3
	j	bne_cont.43600
bne_else.43599:
	fmov	$f3, $f4
bne_cont.43600:
	addi	$r3, $r0, 3
	beq	$r5, $r3, bne_else.43601
	fmov	$f0, $f3
	j	bne_cont.43602
bne_else.43601:
	fsub	$f0, $f3, $f17
bne_cont.43602:
	fsti	$f0, $r6, 3
ble_cont.43598:
	j	bne_cont.43596
bne_else.43595:
	ldi	$r3, $r3, 4
	fldi	$f1, $r6, 0
	fldi	$f3, $r6, 1
	fldi	$f2, $r6, 2
	fldi	$f0, $r3, 0
	fmul	$f1, $f0, $f1
	fldi	$f0, $r3, 1
	fmul	$f0, $f0, $f3
	fadd	$f1, $f1, $f0
	fldi	$f0, $r3, 2
	fmul	$f0, $f0, $f2
	fadd	$f0, $f1, $f0
	fsti	$f0, $r6, 3
bne_cont.43596:
	subi	$r4, $r7, 1
	mov	$r3, $r20
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	setup_startp_constants.2837
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
	j	bge_cont.43594
bge_else.43593:
bge_cont.43594:
	addi	$r17, $r0, 118
	ldi	$r18, $r1, -3
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	iter_trace_diffuse_rays.2935
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
	j	bne_cont.43592
bne_else.43591:
bne_cont.43592:
	addi	$r3, $r0, 4
	ldi	$r9, $r1, -5
	beq	$r9, $r3, bne_else.43603
	ldi	$r19, $r0, 417
	ldi	$r20, $r1, -4
	fldi	$f0, $r20, 0
	fsti	$f0, $r0, 433
	fldi	$f0, $r20, 1
	fsti	$f0, $r0, 434
	fldi	$f0, $r20, 2
	fsti	$f0, $r0, 435
	ldi	$r3, $r0, 585
	subi	$r7, $r3, 1
	blt	$r7, $r0, bge_else.43605
	slli	$r3, $r7, 0
	ldi	$r3, $r3, 524
	ldi	$r6, $r3, 10
	ldi	$r5, $r3, 1
	fldi	$f1, $r20, 0
	ldi	$r4, $r3, 5
	fldi	$f0, $r4, 0
	fsub	$f0, $f1, $f0
	fsti	$f0, $r6, 0
	fldi	$f1, $r20, 1
	fldi	$f0, $r4, 1
	fsub	$f0, $f1, $f0
	fsti	$f0, $r6, 1
	fldi	$f1, $r20, 2
	fldi	$f0, $r4, 2
	fsub	$f0, $f1, $f0
	fsti	$f0, $r6, 2
	addi	$r4, $r0, 2
	beq	$r5, $r4, bne_else.43607
	addi	$r4, $r0, 2
	blt	$r4, $r5, ble_else.43609
	j	ble_cont.43610
ble_else.43609:
	fldi	$f2, $r6, 0
	fldi	$f1, $r6, 1
	fldi	$f0, $r6, 2
	fmul	$f4, $f2, $f2
	ldi	$r4, $r3, 4
	fldi	$f3, $r4, 0
	fmul	$f5, $f4, $f3
	fmul	$f4, $f1, $f1
	fldi	$f3, $r4, 1
	fmul	$f3, $f4, $f3
	fadd	$f5, $f5, $f3
	fmul	$f4, $f0, $f0
	fldi	$f3, $r4, 2
	fmul	$f3, $f4, $f3
	fadd	$f4, $f5, $f3
	ldi	$r4, $r3, 3
	beq	$r4, $r0, bne_else.43611
	fmul	$f5, $f1, $f0
	ldi	$r3, $r3, 9
	fldi	$f3, $r3, 0
	fmul	$f3, $f5, $f3
	fadd	$f4, $f4, $f3
	fmul	$f3, $f0, $f2
	fldi	$f0, $r3, 1
	fmul	$f0, $f3, $f0
	fadd	$f4, $f4, $f0
	fmul	$f1, $f2, $f1
	fldi	$f0, $r3, 2
	fmul	$f3, $f1, $f0
	fadd	$f3, $f4, $f3
	j	bne_cont.43612
bne_else.43611:
	fmov	$f3, $f4
bne_cont.43612:
	addi	$r3, $r0, 3
	beq	$r5, $r3, bne_else.43613
	fmov	$f0, $f3
	j	bne_cont.43614
bne_else.43613:
	fsub	$f0, $f3, $f17
bne_cont.43614:
	fsti	$f0, $r6, 3
ble_cont.43610:
	j	bne_cont.43608
bne_else.43607:
	ldi	$r3, $r3, 4
	fldi	$f1, $r6, 0
	fldi	$f3, $r6, 1
	fldi	$f2, $r6, 2
	fldi	$f0, $r3, 0
	fmul	$f1, $f0, $f1
	fldi	$f0, $r3, 1
	fmul	$f0, $f0, $f3
	fadd	$f1, $f1, $f0
	fldi	$f0, $r3, 2
	fmul	$f0, $f0, $f2
	fadd	$f0, $f1, $f0
	fsti	$f0, $r6, 3
bne_cont.43608:
	subi	$r4, $r7, 1
	mov	$r3, $r20
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	setup_startp_constants.2837
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
	j	bge_cont.43606
bge_else.43605:
bge_cont.43606:
	addi	$r17, $r0, 118
	ldi	$r18, $r1, -3
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	iter_trace_diffuse_rays.2935
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
	j	bne_cont.43604
bne_else.43603:
bne_cont.43604:
	ldi	$r10, $r1, -2
	slli	$r3, $r10, 0
	ldi	$r12, $r1, -1
	ldr	$r3, $r12, $r3
	fldi	$f2, $r0, 444
	fldi	$f1, $r3, 0
	fldi	$f0, $r0, 447
	fmul	$f0, $f1, $f0
	fadd	$f0, $f2, $f0
	fsti	$f0, $r0, 444
	fldi	$f2, $r0, 445
	fldi	$f1, $r3, 1
	fldi	$f0, $r0, 448
	fmul	$f0, $f1, $f0
	fadd	$f0, $f2, $f0
	fsti	$f0, $r0, 445
	fldi	$f2, $r0, 446
	fldi	$f1, $r3, 2
	fldi	$f0, $r0, 449
	fmul	$f0, $f1, $f0
	fadd	$f0, $f2, $f0
	fsti	$f0, $r0, 446
	j	bne_cont.43554
bne_else.43553:
bne_cont.43554:
	addi	$r10, $r10, 1
	ldi	$r11, $r1, 0
	j	do_without_neighbors.2957
bge_else.43552:
	jr	$r29
ble_else.43551:
	jr	$r29

#---------------------------------------------------------------------
# args = [$r4, $r11, $r9, $r5, $r8, $r10]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
try_exploit_neighbors.2973:
	slli	$r3, $r4, 0
	ldr	$r6, $r5, $r3
	addi	$r3, $r0, 4
	blt	$r3, $r10, ble_else.43617
	ldi	$r7, $r6, 2
	slli	$r3, $r10, 0
	ldr	$r3, $r7, $r3
	blt	$r3, $r0, bge_else.43618
	slli	$r7, $r4, 0
	ldr	$r7, $r9, $r7
	ldi	$r13, $r7, 2
	slli	$r12, $r10, 0
	ldr	$r12, $r13, $r12
	beq	$r12, $r3, bne_else.43619
	addi	$r12, $r0, 0
	j	bne_cont.43620
bne_else.43619:
	slli	$r12, $r4, 0
	ldr	$r12, $r8, $r12
	ldi	$r13, $r12, 2
	slli	$r12, $r10, 0
	ldr	$r12, $r13, $r12
	beq	$r12, $r3, bne_else.43621
	addi	$r12, $r0, 0
	j	bne_cont.43622
bne_else.43621:
	subi	$r12, $r4, 1
	slli	$r12, $r12, 0
	ldr	$r12, $r5, $r12
	ldi	$r13, $r12, 2
	slli	$r12, $r10, 0
	ldr	$r12, $r13, $r12
	beq	$r12, $r3, bne_else.43623
	addi	$r12, $r0, 0
	j	bne_cont.43624
bne_else.43623:
	addi	$r12, $r4, 1
	slli	$r12, $r12, 0
	ldr	$r12, $r5, $r12
	ldi	$r13, $r12, 2
	slli	$r12, $r10, 0
	ldr	$r12, $r13, $r12
	beq	$r12, $r3, bne_else.43625
	addi	$r12, $r0, 0
	j	bne_cont.43626
bne_else.43625:
	addi	$r12, $r0, 1
bne_cont.43626:
bne_cont.43624:
bne_cont.43622:
bne_cont.43620:
	beq	$r12, $r0, bne_else.43627
	ldi	$r12, $r6, 3
	slli	$r3, $r10, 0
	ldr	$r3, $r12, $r3
	beq	$r3, $r0, bne_else.43628
	ldi	$r7, $r7, 5
	subi	$r3, $r4, 1
	slli	$r3, $r3, 0
	ldr	$r3, $r5, $r3
	ldi	$r12, $r3, 5
	ldi	$r6, $r6, 5
	addi	$r3, $r4, 1
	slli	$r3, $r3, 0
	ldr	$r3, $r5, $r3
	ldi	$r13, $r3, 5
	slli	$r3, $r4, 0
	ldr	$r3, $r8, $r3
	ldi	$r14, $r3, 5
	slli	$r3, $r10, 0
	ldr	$r3, $r7, $r3
	fldi	$f0, $r3, 0
	fsti	$f0, $r0, 447
	fldi	$f0, $r3, 1
	fsti	$f0, $r0, 448
	fldi	$f0, $r3, 2
	fsti	$f0, $r0, 449
	slli	$r3, $r10, 0
	ldr	$r3, $r12, $r3
	fldi	$f1, $r0, 447
	fldi	$f0, $r3, 0
	fadd	$f0, $f1, $f0
	fsti	$f0, $r0, 447
	fldi	$f1, $r0, 448
	fldi	$f0, $r3, 1
	fadd	$f0, $f1, $f0
	fsti	$f0, $r0, 448
	fldi	$f1, $r0, 449
	fldi	$f0, $r3, 2
	fadd	$f0, $f1, $f0
	fsti	$f0, $r0, 449
	slli	$r3, $r10, 0
	ldr	$r3, $r6, $r3
	fldi	$f1, $r0, 447
	fldi	$f0, $r3, 0
	fadd	$f0, $f1, $f0
	fsti	$f0, $r0, 447
	fldi	$f1, $r0, 448
	fldi	$f0, $r3, 1
	fadd	$f0, $f1, $f0
	fsti	$f0, $r0, 448
	fldi	$f1, $r0, 449
	fldi	$f0, $r3, 2
	fadd	$f0, $f1, $f0
	fsti	$f0, $r0, 449
	slli	$r3, $r10, 0
	ldr	$r3, $r13, $r3
	fldi	$f1, $r0, 447
	fldi	$f0, $r3, 0
	fadd	$f0, $f1, $f0
	fsti	$f0, $r0, 447
	fldi	$f1, $r0, 448
	fldi	$f0, $r3, 1
	fadd	$f0, $f1, $f0
	fsti	$f0, $r0, 448
	fldi	$f1, $r0, 449
	fldi	$f0, $r3, 2
	fadd	$f0, $f1, $f0
	fsti	$f0, $r0, 449
	slli	$r3, $r10, 0
	ldr	$r3, $r14, $r3
	fldi	$f1, $r0, 447
	fldi	$f0, $r3, 0
	fadd	$f0, $f1, $f0
	fsti	$f0, $r0, 447
	fldi	$f1, $r0, 448
	fldi	$f0, $r3, 1
	fadd	$f0, $f1, $f0
	fsti	$f0, $r0, 448
	fldi	$f1, $r0, 449
	fldi	$f0, $r3, 2
	fadd	$f0, $f1, $f0
	fsti	$f0, $r0, 449
	slli	$r3, $r4, 0
	ldr	$r3, $r5, $r3
	ldi	$r6, $r3, 4
	slli	$r3, $r10, 0
	ldr	$r3, $r6, $r3
	fldi	$f2, $r0, 444
	fldi	$f1, $r3, 0
	fldi	$f0, $r0, 447
	fmul	$f0, $f1, $f0
	fadd	$f0, $f2, $f0
	fsti	$f0, $r0, 444
	fldi	$f2, $r0, 445
	fldi	$f1, $r3, 1
	fldi	$f0, $r0, 448
	fmul	$f0, $f1, $f0
	fadd	$f0, $f2, $f0
	fsti	$f0, $r0, 445
	fldi	$f2, $r0, 446
	fldi	$f1, $r3, 2
	fldi	$f0, $r0, 449
	fmul	$f0, $f1, $f0
	fadd	$f0, $f2, $f0
	fsti	$f0, $r0, 446
	j	bne_cont.43629
bne_else.43628:
bne_cont.43629:
	addi	$r10, $r10, 1
	j	try_exploit_neighbors.2973
bne_else.43627:
	slli	$r3, $r4, 0
	ldr	$r11, $r5, $r3
	j	do_without_neighbors.2957
bge_else.43618:
	jr	$r29
ble_else.43617:
	jr	$r29

#---------------------------------------------------------------------
# args = [$r10, $r9]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
pretrace_diffuse_rays.2986:
	addi	$r3, $r0, 4
	blt	$r3, $r9, ble_else.43632
	ldi	$r4, $r10, 2
	slli	$r3, $r9, 0
	ldr	$r3, $r4, $r3
	blt	$r3, $r0, bge_else.43633
	ldi	$r4, $r10, 3
	slli	$r3, $r9, 0
	ldr	$r3, $r4, $r3
	beq	$r3, $r0, bne_else.43634
	ldi	$r3, $r10, 6
	ldi	$r3, $r3, 0
	fsti	$f16, $r0, 447
	fsti	$f16, $r0, 448
	fsti	$f16, $r0, 449
	ldi	$r4, $r10, 7
	ldi	$r5, $r10, 1
	slli	$r3, $r3, 0
	ldi	$r19, $r3, 413
	slli	$r3, $r9, 0
	ldr	$r18, $r4, $r3
	slli	$r3, $r9, 0
	ldr	$r20, $r5, $r3
	fldi	$f0, $r20, 0
	fsti	$f0, $r0, 433
	fldi	$f0, $r20, 1
	fsti	$f0, $r0, 434
	fldi	$f0, $r20, 2
	fsti	$f0, $r0, 435
	ldi	$r3, $r0, 585
	subi	$r7, $r3, 1
	blt	$r7, $r0, bge_else.43636
	slli	$r3, $r7, 0
	ldi	$r3, $r3, 524
	ldi	$r6, $r3, 10
	ldi	$r5, $r3, 1
	fldi	$f1, $r20, 0
	ldi	$r4, $r3, 5
	fldi	$f0, $r4, 0
	fsub	$f0, $f1, $f0
	fsti	$f0, $r6, 0
	fldi	$f1, $r20, 1
	fldi	$f0, $r4, 1
	fsub	$f0, $f1, $f0
	fsti	$f0, $r6, 1
	fldi	$f1, $r20, 2
	fldi	$f0, $r4, 2
	fsub	$f0, $f1, $f0
	fsti	$f0, $r6, 2
	addi	$r4, $r0, 2
	beq	$r5, $r4, bne_else.43638
	addi	$r4, $r0, 2
	blt	$r4, $r5, ble_else.43640
	j	ble_cont.43641
ble_else.43640:
	fldi	$f2, $r6, 0
	fldi	$f1, $r6, 1
	fldi	$f0, $r6, 2
	fmul	$f4, $f2, $f2
	ldi	$r4, $r3, 4
	fldi	$f3, $r4, 0
	fmul	$f5, $f4, $f3
	fmul	$f4, $f1, $f1
	fldi	$f3, $r4, 1
	fmul	$f3, $f4, $f3
	fadd	$f5, $f5, $f3
	fmul	$f4, $f0, $f0
	fldi	$f3, $r4, 2
	fmul	$f3, $f4, $f3
	fadd	$f4, $f5, $f3
	ldi	$r4, $r3, 3
	beq	$r4, $r0, bne_else.43642
	fmul	$f5, $f1, $f0
	ldi	$r3, $r3, 9
	fldi	$f3, $r3, 0
	fmul	$f3, $f5, $f3
	fadd	$f4, $f4, $f3
	fmul	$f3, $f0, $f2
	fldi	$f0, $r3, 1
	fmul	$f0, $f3, $f0
	fadd	$f4, $f4, $f0
	fmul	$f1, $f2, $f1
	fldi	$f0, $r3, 2
	fmul	$f3, $f1, $f0
	fadd	$f3, $f4, $f3
	j	bne_cont.43643
bne_else.43642:
	fmov	$f3, $f4
bne_cont.43643:
	addi	$r3, $r0, 3
	beq	$r5, $r3, bne_else.43644
	fmov	$f0, $f3
	j	bne_cont.43645
bne_else.43644:
	fsub	$f0, $f3, $f17
bne_cont.43645:
	fsti	$f0, $r6, 3
ble_cont.43641:
	j	bne_cont.43639
bne_else.43638:
	ldi	$r3, $r3, 4
	fldi	$f1, $r6, 0
	fldi	$f3, $r6, 1
	fldi	$f2, $r6, 2
	fldi	$f0, $r3, 0
	fmul	$f1, $f0, $f1
	fldi	$f0, $r3, 1
	fmul	$f0, $f0, $f3
	fadd	$f1, $f1, $f0
	fldi	$f0, $r3, 2
	fmul	$f0, $f0, $f2
	fadd	$f0, $f1, $f0
	fsti	$f0, $r6, 3
bne_cont.43639:
	subi	$r4, $r7, 1
	mov	$r3, $r20
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	setup_startp_constants.2837
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	j	bge_cont.43637
bge_else.43636:
bge_cont.43637:
	addi	$r17, $r0, 118
	sti	$r9, $r1, 0
	sti	$r10, $r1, -1
	sti	$r29, $r1, -3
	subi	$r1, $r1, 4
	jal	iter_trace_diffuse_rays.2935
	addi	$r1, $r1, 4
	ldi	$r29, $r1, -3
	ldi	$r10, $r1, -1
	ldi	$r4, $r10, 5
	ldi	$r9, $r1, 0
	slli	$r3, $r9, 0
	ldr	$r3, $r4, $r3
	fldi	$f0, $r0, 447
	fsti	$f0, $r3, 0
	fldi	$f0, $r0, 448
	fsti	$f0, $r3, 1
	fldi	$f0, $r0, 449
	fsti	$f0, $r3, 2
	j	bne_cont.43635
bne_else.43634:
bne_cont.43635:
	addi	$r9, $r9, 1
	j	pretrace_diffuse_rays.2986
bge_else.43633:
	jr	$r29
ble_else.43632:
	jr	$r29

#---------------------------------------------------------------------
# args = [$r7, $r6, $r3]
# fargs = [$f5, $f4, $f3]
# ret type = Unit
#---------------------------------------------------------------------
pretrace_pixels.2989:
	blt	$r6, $r0, bge_else.43648
	fldi	$f6, $r0, 439
	ldi	$r4, $r0, 440
	sub	$r8, $r6, $r4
	sti	$r3, $r1, 0
	itof	$f0, $r8
	fmul	$f0, $f6, $f0
	fldi	$f1, $r0, 430
	fmul	$f1, $f0, $f1
	fadd	$f1, $f1, $f5
	fsti	$f1, $r0, 421
	fldi	$f1, $r0, 431
	fmul	$f1, $f0, $f1
	fadd	$f1, $f1, $f4
	fsti	$f1, $r0, 422
	fldi	$f1, $r0, 432
	fmul	$f0, $f0, $f1
	fadd	$f0, $f0, $f3
	fsti	$f0, $r0, 423
	fldi	$f1, $r0, 421
	fmul	$f2, $f1, $f1
	fldi	$f0, $r0, 422
	fmul	$f0, $f0, $f0
	fadd	$f2, $f2, $f0
	fldi	$f0, $r0, 423
	fmul	$f0, $f0, $f0
	fadd	$f0, $f2, $f0
	fsqrt	$f2, $f0
	fbeq	$f2, $f16, fbne_else.43649
	fdiv	$f0, $f17, $f2
	j	fbne_cont.43650
fbne_else.43649:
	fmov	$f0, $f17
fbne_cont.43650:
	fmul	$f1, $f1, $f0
	fsti	$f1, $r0, 421
	fldi	$f1, $r0, 422
	fmul	$f1, $f1, $f0
	fsti	$f1, $r0, 422
	fldi	$f1, $r0, 423
	fmul	$f0, $f1, $f0
	fsti	$f0, $r0, 423
	fsti	$f16, $r0, 444
	fsti	$f16, $r0, 445
	fsti	$f16, $r0, 446
	fldi	$f0, $r0, 518
	fsti	$f0, $r0, 436
	fldi	$f0, $r0, 519
	fsti	$f0, $r0, 437
	fldi	$f0, $r0, 520
	fsti	$f0, $r0, 438
	addi	$r21, $r0, 0
	slli	$r4, $r6, 0
	ldr	$r22, $r7, $r4
	subi	$r19, $r0, -421
	fsti	$f3, $r1, -1
	fsti	$f4, $r1, -2
	fsti	$f5, $r1, -3
	sti	$r7, $r1, -4
	sti	$r6, $r1, -5
	fmov	$f12, $f16
	fmov	$f14, $f17
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	trace_ray.2926
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
	ldi	$r6, $r1, -5
	slli	$r4, $r6, 0
	ldi	$r7, $r1, -4
	ldr	$r4, $r7, $r4
	ldi	$r4, $r4, 0
	fldi	$f0, $r0, 444
	fsti	$f0, $r4, 0
	fldi	$f0, $r0, 445
	fsti	$f0, $r4, 1
	fldi	$f0, $r0, 446
	fsti	$f0, $r4, 2
	slli	$r4, $r6, 0
	ldr	$r4, $r7, $r4
	ldi	$r4, $r4, 6
	ldi	$r3, $r1, 0
	sti	$r3, $r4, 0
	slli	$r4, $r6, 0
	ldr	$r10, $r7, $r4
	addi	$r9, $r0, 0
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	pretrace_diffuse_rays.2986
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
	ldi	$r6, $r1, -5
	subi	$r6, $r6, 1
	ldi	$r3, $r1, 0
	addi	$r4, $r3, 1
	addi	$r3, $r0, 5
	blt	$r4, $r3, ble_else.43651
	subi	$r3, $r4, 5
	j	ble_cont.43652
ble_else.43651:
	mov	$r3, $r4
ble_cont.43652:
	fldi	$f5, $r1, -3
	fldi	$f4, $r1, -2
	fldi	$f3, $r1, -1
	ldi	$r7, $r1, -4
	j	pretrace_pixels.2989
bge_else.43648:
	jr	$r29

#---------------------------------------------------------------------
# args = [$r15, $r16, $r18, $r17, $r19]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
scan_pixel.3000:
	ldi	$r3, $r0, 442
	blt	$r15, $r3, ble_else.43654
	jr	$r29
ble_else.43654:
	slli	$r3, $r15, 0
	ldr	$r3, $r17, $r3
	ldi	$r3, $r3, 0
	fldi	$f0, $r3, 0
	fsti	$f0, $r0, 444
	fldi	$f0, $r3, 1
	fsti	$f0, $r0, 445
	fldi	$f0, $r3, 2
	fsti	$f0, $r0, 446
	ldi	$r4, $r0, 443
	addi	$r3, $r16, 1
	blt	$r3, $r4, ble_else.43656
	addi	$r3, $r0, 0
	j	ble_cont.43657
ble_else.43656:
	blt	$r0, $r16, ble_else.43658
	addi	$r3, $r0, 0
	j	ble_cont.43659
ble_else.43658:
	ldi	$r4, $r0, 442
	addi	$r3, $r15, 1
	blt	$r3, $r4, ble_else.43660
	addi	$r3, $r0, 0
	j	ble_cont.43661
ble_else.43660:
	blt	$r0, $r15, ble_else.43662
	addi	$r3, $r0, 0
	j	ble_cont.43663
ble_else.43662:
	addi	$r3, $r0, 1
ble_cont.43663:
ble_cont.43661:
ble_cont.43659:
ble_cont.43657:
	sti	$r19, $r1, 0
	sti	$r17, $r1, -1
	sti	$r18, $r1, -2
	sti	$r16, $r1, -3
	sti	$r15, $r1, -4
	beq	$r3, $r0, bne_else.43664
	addi	$r10, $r0, 0
	mov	$r8, $r19
	mov	$r5, $r17
	mov	$r9, $r18
	mov	$r11, $r16
	mov	$r4, $r15
	sti	$r29, $r1, -6
	subi	$r1, $r1, 7
	jal	try_exploit_neighbors.2973
	addi	$r1, $r1, 7
	ldi	$r29, $r1, -6
	j	bne_cont.43665
bne_else.43664:
	slli	$r3, $r15, 0
	ldr	$r11, $r17, $r3
	addi	$r10, $r0, 0
	sti	$r29, $r1, -6
	subi	$r1, $r1, 7
	jal	do_without_neighbors.2957
	addi	$r1, $r1, 7
	ldi	$r29, $r1, -6
bne_cont.43665:
	fldi	$f0, $r0, 444
	ftoi	$r3, $f0
	addi	$r4, $r0, 255
	blt	$r4, $r3, ble_else.43666
	blt	$r3, $r0, bge_else.43668
	mov	$r4, $r3
	j	bge_cont.43669
bge_else.43668:
	addi	$r4, $r0, 0
bge_cont.43669:
	j	ble_cont.43667
ble_else.43666:
	addi	$r4, $r0, 255
ble_cont.43667:
	sti	$r29, $r1, -6
	subi	$r1, $r1, 7
	jal	print_int.2559
	addi	$r1, $r1, 7
	ldi	$r29, $r1, -6
	addi	$r3, $r0, 32
	outputb	$r3
	fldi	$f0, $r0, 445
	ftoi	$r3, $f0
	addi	$r4, $r0, 255
	blt	$r4, $r3, ble_else.43670
	blt	$r3, $r0, bge_else.43672
	mov	$r4, $r3
	j	bge_cont.43673
bge_else.43672:
	addi	$r4, $r0, 0
bge_cont.43673:
	j	ble_cont.43671
ble_else.43670:
	addi	$r4, $r0, 255
ble_cont.43671:
	sti	$r29, $r1, -6
	subi	$r1, $r1, 7
	jal	print_int.2559
	addi	$r1, $r1, 7
	ldi	$r29, $r1, -6
	addi	$r3, $r0, 32
	outputb	$r3
	fldi	$f0, $r0, 446
	ftoi	$r3, $f0
	addi	$r4, $r0, 255
	blt	$r4, $r3, ble_else.43674
	blt	$r3, $r0, bge_else.43676
	mov	$r4, $r3
	j	bge_cont.43677
bge_else.43676:
	addi	$r4, $r0, 0
bge_cont.43677:
	j	ble_cont.43675
ble_else.43674:
	addi	$r4, $r0, 255
ble_cont.43675:
	sti	$r29, $r1, -6
	subi	$r1, $r1, 7
	jal	print_int.2559
	addi	$r1, $r1, 7
	ldi	$r29, $r1, -6
	addi	$r3, $r0, 10
	outputb	$r3
	ldi	$r15, $r1, -4
	addi	$r15, $r15, 1
	ldi	$r16, $r1, -3
	ldi	$r18, $r1, -2
	ldi	$r17, $r1, -1
	ldi	$r19, $r1, 0
	j	scan_pixel.3000

#---------------------------------------------------------------------
# args = [$r16, $r7, $r18, $r17, $r3]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
scan_line.3006:
	ldi	$r4, $r0, 443
	blt	$r16, $r4, ble_else.43678
	jr	$r29
ble_else.43678:
	subi	$r4, $r4, 1
	sti	$r3, $r1, 0
	sti	$r17, $r1, -1
	sti	$r18, $r1, -2
	sti	$r7, $r1, -3
	sti	$r16, $r1, -4
	blt	$r16, $r4, ble_else.43680
	j	ble_cont.43681
ble_else.43680:
	addi	$r5, $r16, 1
	fldi	$f3, $r0, 439
	ldi	$r4, $r0, 441
	sub	$r6, $r5, $r4
	itof	$f0, $r6
	fmul	$f0, $f3, $f0
	fldi	$f1, $r0, 427
	fmul	$f2, $f0, $f1
	fldi	$f1, $r0, 424
	fadd	$f5, $f2, $f1
	fldi	$f1, $r0, 428
	fmul	$f2, $f0, $f1
	fldi	$f1, $r0, 425
	fadd	$f4, $f2, $f1
	fldi	$f1, $r0, 429
	fmul	$f1, $f0, $f1
	fldi	$f0, $r0, 426
	fadd	$f3, $f1, $f0
	ldi	$r4, $r0, 442
	subi	$r6, $r4, 1
	ldi	$r3, $r1, 0
	mov	$r7, $r17
	sti	$r29, $r1, -6
	subi	$r1, $r1, 7
	jal	pretrace_pixels.2989
	addi	$r1, $r1, 7
	ldi	$r29, $r1, -6
ble_cont.43681:
	addi	$r15, $r0, 0
	ldi	$r16, $r1, -4
	ldi	$r7, $r1, -3
	ldi	$r18, $r1, -2
	ldi	$r17, $r1, -1
	mov	$r19, $r17
	mov	$r17, $r18
	mov	$r18, $r7
	sti	$r29, $r1, -6
	subi	$r1, $r1, 7
	jal	scan_pixel.3000
	addi	$r1, $r1, 7
	ldi	$r29, $r1, -6
	ldi	$r16, $r1, -4
	addi	$r16, $r16, 1
	ldi	$r3, $r1, 0
	addi	$r4, $r3, 2
	addi	$r3, $r0, 5
	blt	$r4, $r3, ble_else.43682
	subi	$r3, $r4, 5
	j	ble_cont.43683
ble_else.43682:
	mov	$r3, $r4
ble_cont.43683:
	ldi	$r4, $r0, 443
	blt	$r16, $r4, ble_else.43684
	jr	$r29
ble_else.43684:
	subi	$r4, $r4, 1
	sti	$r3, $r1, -5
	sti	$r16, $r1, -6
	blt	$r16, $r4, ble_else.43686
	j	ble_cont.43687
ble_else.43686:
	addi	$r5, $r16, 1
	fldi	$f3, $r0, 439
	ldi	$r4, $r0, 441
	sub	$r6, $r5, $r4
	itof	$f0, $r6
	fmul	$f0, $f3, $f0
	fldi	$f1, $r0, 427
	fmul	$f2, $f0, $f1
	fldi	$f1, $r0, 424
	fadd	$f5, $f2, $f1
	fldi	$f1, $r0, 428
	fmul	$f2, $f0, $f1
	fldi	$f1, $r0, 425
	fadd	$f4, $f2, $f1
	fldi	$f1, $r0, 429
	fmul	$f1, $f0, $f1
	fldi	$f0, $r0, 426
	fadd	$f3, $f1, $f0
	ldi	$r4, $r0, 442
	subi	$r6, $r4, 1
	ldi	$r7, $r1, -3
	ldi	$r3, $r1, -5
	sti	$r29, $r1, -8
	subi	$r1, $r1, 9
	jal	pretrace_pixels.2989
	addi	$r1, $r1, 9
	ldi	$r29, $r1, -8
ble_cont.43687:
	addi	$r15, $r0, 0
	ldi	$r16, $r1, -6
	ldi	$r18, $r1, -2
	ldi	$r17, $r1, -1
	ldi	$r7, $r1, -3
	mov	$r19, $r7
	sti	$r29, $r1, -8
	subi	$r1, $r1, 9
	jal	scan_pixel.3000
	addi	$r1, $r1, 9
	ldi	$r29, $r1, -8
	ldi	$r16, $r1, -6
	addi	$r16, $r16, 1
	ldi	$r3, $r1, -5
	addi	$r4, $r3, 2
	addi	$r3, $r0, 5
	blt	$r4, $r3, ble_else.43688
	subi	$r3, $r4, 5
	j	ble_cont.43689
ble_else.43688:
	mov	$r3, $r4
ble_cont.43689:
	ldi	$r17, $r1, -1
	ldi	$r7, $r1, -3
	ldi	$r18, $r1, -2
	mov	$r27, $r17
	mov	$r17, $r18
	mov	$r18, $r7
	mov	$r7, $r27
	j	scan_line.3006

#---------------------------------------------------------------------
# args = [$r10, $r9]
# fargs = []
# ret type = Array((Array(Float) * Array(Array(Float)) * Array(Int) * Array(Bool) * Array(Array(Float)) * Array(Array(Float)) * Array(Int) * Array(Array(Float))))
#---------------------------------------------------------------------
init_line_elements.3016:
	blt	$r9, $r0, bge_else.43690
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r13, $r3
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r4, $r3
	addi	$r3, $r0, 5
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r8, $r3
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r8, 1
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r8, 2
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r8, 3
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r8, 4
	addi	$r3, $r0, 5
	addi	$r4, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r12, $r3
	addi	$r3, $r0, 5
	addi	$r4, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r11, $r3
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r4, $r3
	addi	$r3, $r0, 5
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r7, $r3
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r7, 1
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r7, 2
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r7, 3
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r7, 4
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r4, $r3
	addi	$r3, $r0, 5
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r6, $r3
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r6, 1
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r6, 2
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r6, 3
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r6, 4
	addi	$r3, $r0, 1
	addi	$r4, $r0, 0
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r14, $r3
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r4, $r3
	addi	$r3, $r0, 5
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r5, $r3
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r5, 1
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r5, 2
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r5, 3
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	sti	$r3, $r5, 4
	mov	$r3, $r2
	addi	$r2, $r2, 8
	sti	$r5, $r3, 7
	sti	$r14, $r3, 6
	sti	$r6, $r3, 5
	sti	$r7, $r3, 4
	sti	$r11, $r3, 3
	sti	$r12, $r3, 2
	sti	$r8, $r3, 1
	sti	$r13, $r3, 0
	slli	$r4, $r9, 0
	str	$r3, $r10, $r4
	subi	$r9, $r9, 1
	j	init_line_elements.3016
bge_else.43690:
	mov	$r3, $r10
	jr	$r29

#---------------------------------------------------------------------
# args = [$r3, $r5, $r4]
# fargs = [$f4, $f3, $f2, $f1]
# ret type = Unit
#---------------------------------------------------------------------
calc_dirvec.3024:
	addi	$r6, $r0, 5
	blt	$r3, $r6, ble_else.43691
	fmul	$f1, $f4, $f4
	fmul	$f0, $f3, $f3
	fadd	$f0, $f1, $f0
	fadd	$f0, $f0, $f17
	fsqrt	$f0, $f0
	fdiv	$f2, $f4, $f0
	fdiv	$f1, $f3, $f0
	fdiv	$f0, $f17, $f0
	slli	$r3, $r5, 0
	ldi	$r5, $r3, 413
	slli	$r3, $r4, 0
	ldr	$r3, $r5, $r3
	ldi	$r3, $r3, 0
	fsti	$f2, $r3, 0
	fsti	$f1, $r3, 1
	fsti	$f0, $r3, 2
	addi	$r3, $r4, 40
	slli	$r3, $r3, 0
	ldr	$r3, $r5, $r3
	ldi	$r3, $r3, 0
	fneg	$f4, $f1
	fsti	$f2, $r3, 0
	fsti	$f0, $r3, 1
	fsti	$f4, $r3, 2
	addi	$r3, $r4, 80
	slli	$r3, $r3, 0
	ldr	$r3, $r5, $r3
	ldi	$r3, $r3, 0
	fneg	$f3, $f2
	fsti	$f0, $r3, 0
	fsti	$f3, $r3, 1
	fsti	$f4, $r3, 2
	addi	$r3, $r4, 1
	slli	$r3, $r3, 0
	ldr	$r3, $r5, $r3
	ldi	$r3, $r3, 0
	fneg	$f0, $f0
	fsti	$f3, $r3, 0
	fsti	$f4, $r3, 1
	fsti	$f0, $r3, 2
	addi	$r3, $r4, 41
	slli	$r3, $r3, 0
	ldr	$r3, $r5, $r3
	ldi	$r3, $r3, 0
	fsti	$f3, $r3, 0
	fsti	$f0, $r3, 1
	fsti	$f1, $r3, 2
	addi	$r3, $r4, 81
	slli	$r3, $r3, 0
	ldr	$r3, $r5, $r3
	ldi	$r3, $r3, 0
	fsti	$f0, $r3, 0
	fsti	$f2, $r3, 1
	fsti	$f1, $r3, 2
	jr	$r29
ble_else.43691:
	fmul	$f0, $f3, $f3
	fadd	$f0, $f0, $f25
	fsqrt	$f3, $f0
	fdiv	$f0, $f17, $f3
	sti	$r4, $r1, 0
	sti	$r5, $r1, -1
	fsti	$f1, $r1, -2
	sti	$r3, $r1, -3
	fsti	$f3, $r1, -4
	fsti	$f2, $r1, -5
	fatan	$f0, $f0
	fldi	$f2, $r1, -5
	fmul	$f0, $f0, $f2
	ftan	$f0, $f0
	fldi	$f3, $r1, -4
	fmul	$f4, $f0, $f3
	ldi	$r3, $r1, -3
	addi	$r3, $r3, 1
	fmul	$f0, $f4, $f4
	fadd	$f0, $f0, $f25
	fsqrt	$f3, $f0
	fdiv	$f0, $f17, $f3
	fsti	$f4, $r1, -6
	sti	$r3, $r1, -7
	fsti	$f3, $r1, -8
	fatan	$f0, $f0
	fldi	$f1, $r1, -2
	fmul	$f0, $f0, $f1
	ftan	$f0, $f0
	fldi	$f3, $r1, -8
	fmul	$f3, $f0, $f3
	fldi	$f4, $r1, -6
	fldi	$f2, $r1, -5
	fldi	$f1, $r1, -2
	ldi	$r3, $r1, -7
	ldi	$r5, $r1, -1
	ldi	$r4, $r1, 0
	j	calc_dirvec.3024

#---------------------------------------------------------------------
# args = [$r6, $r5, $r4]
# fargs = [$f1]
# ret type = Unit
#---------------------------------------------------------------------
calc_dirvecs.3032:
	blt	$r6, $r0, bge_else.43693
	fsti	$f1, $r1, 0
	sti	$r4, $r1, -1
	sti	$r5, $r1, -2
	itof	$f0, $r6
	fmul	$f0, $f0, $f30
	fsub	$f2, $f0, $f29
	addi	$r3, $r0, 0
	fldi	$f1, $r1, 0
	ldi	$r5, $r1, -2
	ldi	$r4, $r1, -1
	sti	$r6, $r1, -3
	fsti	$f0, $r1, -4
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -6
	subi	$r1, $r1, 7
	jal	calc_dirvec.3024
	addi	$r1, $r1, 7
	ldi	$r29, $r1, -6
	fldi	$f0, $r1, -4
	fadd	$f2, $f0, $f25
	addi	$r3, $r0, 0
	ldi	$r4, $r1, -1
	addi	$r7, $r4, 2
	fldi	$f1, $r1, 0
	ldi	$r5, $r1, -2
	sti	$r7, $r1, -5
	mov	$r4, $r7
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	calc_dirvec.3024
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
	ldi	$r6, $r1, -3
	subi	$r6, $r6, 1
	ldi	$r5, $r1, -2
	addi	$r3, $r5, 1
	addi	$r5, $r0, 5
	blt	$r3, $r5, ble_else.43694
	subi	$r5, $r3, 5
	j	ble_cont.43695
ble_else.43694:
	mov	$r5, $r3
ble_cont.43695:
	blt	$r6, $r0, bge_else.43696
	sti	$r5, $r1, -6
	itof	$f0, $r6
	fmul	$f0, $f0, $f30
	fsub	$f2, $f0, $f29
	addi	$r3, $r0, 0
	fldi	$f1, $r1, 0
	ldi	$r5, $r1, -6
	ldi	$r4, $r1, -1
	sti	$r6, $r1, -7
	fsti	$f0, $r1, -8
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -10
	subi	$r1, $r1, 11
	jal	calc_dirvec.3024
	addi	$r1, $r1, 11
	ldi	$r29, $r1, -10
	fldi	$f0, $r1, -8
	fadd	$f2, $f0, $f25
	addi	$r3, $r0, 0
	fldi	$f1, $r1, 0
	ldi	$r5, $r1, -6
	ldi	$r7, $r1, -5
	mov	$r4, $r7
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -10
	subi	$r1, $r1, 11
	jal	calc_dirvec.3024
	addi	$r1, $r1, 11
	ldi	$r29, $r1, -10
	ldi	$r6, $r1, -7
	subi	$r6, $r6, 1
	ldi	$r5, $r1, -6
	addi	$r3, $r5, 1
	addi	$r5, $r0, 5
	blt	$r3, $r5, ble_else.43697
	subi	$r5, $r3, 5
	j	ble_cont.43698
ble_else.43697:
	mov	$r5, $r3
ble_cont.43698:
	blt	$r6, $r0, bge_else.43699
	sti	$r5, $r1, -9
	itof	$f0, $r6
	fmul	$f0, $f0, $f30
	fsub	$f2, $f0, $f29
	addi	$r3, $r0, 0
	fldi	$f1, $r1, 0
	ldi	$r5, $r1, -9
	ldi	$r4, $r1, -1
	sti	$r6, $r1, -10
	fsti	$f0, $r1, -11
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -13
	subi	$r1, $r1, 14
	jal	calc_dirvec.3024
	addi	$r1, $r1, 14
	ldi	$r29, $r1, -13
	fldi	$f0, $r1, -11
	fadd	$f2, $f0, $f25
	addi	$r3, $r0, 0
	fldi	$f1, $r1, 0
	ldi	$r5, $r1, -9
	ldi	$r7, $r1, -5
	mov	$r4, $r7
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -13
	subi	$r1, $r1, 14
	jal	calc_dirvec.3024
	addi	$r1, $r1, 14
	ldi	$r29, $r1, -13
	ldi	$r6, $r1, -10
	subi	$r6, $r6, 1
	ldi	$r5, $r1, -9
	addi	$r3, $r5, 1
	addi	$r5, $r0, 5
	blt	$r3, $r5, ble_else.43700
	subi	$r5, $r3, 5
	j	ble_cont.43701
ble_else.43700:
	mov	$r5, $r3
ble_cont.43701:
	blt	$r6, $r0, bge_else.43702
	sti	$r5, $r1, -12
	itof	$f0, $r6
	fmul	$f0, $f0, $f30
	fsub	$f2, $f0, $f29
	addi	$r3, $r0, 0
	fldi	$f1, $r1, 0
	ldi	$r5, $r1, -12
	ldi	$r4, $r1, -1
	sti	$r6, $r1, -13
	fsti	$f0, $r1, -14
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -16
	subi	$r1, $r1, 17
	jal	calc_dirvec.3024
	addi	$r1, $r1, 17
	ldi	$r29, $r1, -16
	fldi	$f0, $r1, -14
	fadd	$f2, $f0, $f25
	addi	$r3, $r0, 0
	fldi	$f1, $r1, 0
	ldi	$r5, $r1, -12
	ldi	$r7, $r1, -5
	mov	$r4, $r7
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -16
	subi	$r1, $r1, 17
	jal	calc_dirvec.3024
	addi	$r1, $r1, 17
	ldi	$r29, $r1, -16
	ldi	$r6, $r1, -13
	subi	$r6, $r6, 1
	ldi	$r5, $r1, -12
	addi	$r5, $r5, 1
	addi	$r3, $r0, 5
	blt	$r5, $r3, ble_else.43703
	subi	$r3, $r5, 5
	j	ble_cont.43704
ble_else.43703:
	mov	$r3, $r5
ble_cont.43704:
	fldi	$f1, $r1, 0
	ldi	$r4, $r1, -1
	mov	$r5, $r3
	j	calc_dirvecs.3032
bge_else.43702:
	jr	$r29
bge_else.43699:
	jr	$r29
bge_else.43696:
	jr	$r29
bge_else.43693:
	jr	$r29

#---------------------------------------------------------------------
# args = [$r7, $r6, $r4]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
calc_dirvec_rows.3037:
	blt	$r7, $r0, bge_else.43709
	sti	$r4, $r1, 0
	itof	$f0, $r7
	fmul	$f0, $f0, $f30
	fsub	$f1, $f0, $f29
	addi	$r3, $r0, 4
	fsti	$f1, $r1, -1
	itof	$f0, $r3
	fmul	$f0, $f0, $f30
	fsub	$f7, $f0, $f29
	addi	$r3, $r0, 0
	fldi	$f1, $r1, -1
	ldi	$r4, $r1, 0
	fsti	$f7, $r1, -2
	sti	$r7, $r1, -3
	sti	$r6, $r1, -4
	fsti	$f0, $r1, -5
	mov	$r5, $r6
	fmov	$f2, $f7
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	calc_dirvec.3024
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
	fldi	$f0, $r1, -5
	fadd	$f6, $f0, $f25
	addi	$r3, $r0, 0
	ldi	$r4, $r1, 0
	addi	$r9, $r4, 2
	fldi	$f1, $r1, -1
	ldi	$r6, $r1, -4
	fsti	$f6, $r1, -6
	sti	$r9, $r1, -7
	mov	$r4, $r9
	mov	$r5, $r6
	fmov	$f2, $f6
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -9
	subi	$r1, $r1, 10
	jal	calc_dirvec.3024
	addi	$r1, $r1, 10
	ldi	$r29, $r1, -9
	addi	$r8, $r0, 3
	ldi	$r6, $r1, -4
	addi	$r3, $r6, 1
	addi	$r5, $r0, 5
	blt	$r3, $r5, ble_else.43710
	subi	$r5, $r3, 5
	j	ble_cont.43711
ble_else.43710:
	mov	$r5, $r3
ble_cont.43711:
	sti	$r5, $r1, -8
	itof	$f0, $r8
	fmul	$f0, $f0, $f30
	fsub	$f5, $f0, $f29
	addi	$r3, $r0, 0
	fldi	$f1, $r1, -1
	ldi	$r5, $r1, -8
	ldi	$r4, $r1, 0
	fsti	$f5, $r1, -9
	fsti	$f0, $r1, -10
	fmov	$f2, $f5
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -12
	subi	$r1, $r1, 13
	jal	calc_dirvec.3024
	addi	$r1, $r1, 13
	ldi	$r29, $r1, -12
	fldi	$f0, $r1, -10
	fadd	$f4, $f0, $f25
	addi	$r3, $r0, 0
	fldi	$f1, $r1, -1
	ldi	$r5, $r1, -8
	ldi	$r9, $r1, -7
	fsti	$f4, $r1, -11
	mov	$r4, $r9
	fmov	$f2, $f4
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -13
	subi	$r1, $r1, 14
	jal	calc_dirvec.3024
	addi	$r1, $r1, 14
	ldi	$r29, $r1, -13
	addi	$r8, $r0, 2
	ldi	$r5, $r1, -8
	addi	$r3, $r5, 1
	addi	$r5, $r0, 5
	blt	$r3, $r5, ble_else.43712
	subi	$r5, $r3, 5
	j	ble_cont.43713
ble_else.43712:
	mov	$r5, $r3
ble_cont.43713:
	sti	$r5, $r1, -12
	itof	$f0, $r8
	fmul	$f0, $f0, $f30
	fsub	$f3, $f0, $f29
	addi	$r3, $r0, 0
	fldi	$f1, $r1, -1
	ldi	$r5, $r1, -12
	ldi	$r4, $r1, 0
	fsti	$f3, $r1, -13
	fsti	$f0, $r1, -14
	fmov	$f2, $f3
	fmov	$f4, $f16
	fmov	$f3, $f16
	sti	$r29, $r1, -16
	subi	$r1, $r1, 17
	jal	calc_dirvec.3024
	addi	$r1, $r1, 17
	ldi	$r29, $r1, -16
	fldi	$f0, $r1, -14
	fadd	$f2, $f0, $f25
	addi	$r3, $r0, 0
	fldi	$f1, $r1, -1
	ldi	$r5, $r1, -12
	ldi	$r9, $r1, -7
	fsti	$f2, $r1, -15
	mov	$r4, $r9
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -17
	subi	$r1, $r1, 18
	jal	calc_dirvec.3024
	addi	$r1, $r1, 18
	ldi	$r29, $r1, -17
	addi	$r8, $r0, 1
	ldi	$r5, $r1, -12
	addi	$r3, $r5, 1
	addi	$r5, $r0, 5
	blt	$r3, $r5, ble_else.43714
	subi	$r5, $r3, 5
	j	ble_cont.43715
ble_else.43714:
	mov	$r5, $r3
ble_cont.43715:
	sti	$r5, $r1, -16
	itof	$f0, $r8
	fmul	$f8, $f0, $f30
	fsub	$f0, $f8, $f29
	addi	$r3, $r0, 0
	fldi	$f1, $r1, -1
	ldi	$r5, $r1, -16
	ldi	$r4, $r1, 0
	fsti	$f8, $r1, -17
	fmov	$f2, $f0
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -19
	subi	$r1, $r1, 20
	jal	calc_dirvec.3024
	addi	$r1, $r1, 20
	ldi	$r29, $r1, -19
	fldi	$f8, $r1, -17
	fadd	$f0, $f8, $f25
	addi	$r3, $r0, 0
	fldi	$f1, $r1, -1
	ldi	$r5, $r1, -16
	ldi	$r9, $r1, -7
	mov	$r4, $r9
	fmov	$f2, $f0
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -19
	subi	$r1, $r1, 20
	jal	calc_dirvec.3024
	addi	$r1, $r1, 20
	ldi	$r29, $r1, -19
	addi	$r8, $r0, 0
	ldi	$r5, $r1, -16
	addi	$r3, $r5, 1
	addi	$r5, $r0, 5
	blt	$r3, $r5, ble_else.43716
	subi	$r5, $r3, 5
	j	ble_cont.43717
ble_else.43716:
	mov	$r5, $r3
ble_cont.43717:
	fldi	$f1, $r1, -1
	ldi	$r4, $r1, 0
	mov	$r6, $r8
	sti	$r29, $r1, -19
	subi	$r1, $r1, 20
	jal	calc_dirvecs.3032
	addi	$r1, $r1, 20
	ldi	$r29, $r1, -19
	ldi	$r7, $r1, -3
	subi	$r8, $r7, 1
	ldi	$r6, $r1, -4
	addi	$r3, $r6, 2
	addi	$r6, $r0, 5
	blt	$r3, $r6, ble_else.43718
	subi	$r6, $r3, 5
	j	ble_cont.43719
ble_else.43718:
	mov	$r6, $r3
ble_cont.43719:
	ldi	$r4, $r1, 0
	addi	$r7, $r4, 4
	blt	$r8, $r0, bge_else.43720
	itof	$f0, $r8
	fmul	$f0, $f0, $f30
	fsub	$f1, $f0, $f29
	addi	$r3, $r0, 0
	fldi	$f7, $r1, -2
	sti	$r8, $r1, -18
	fsti	$f1, $r1, -19
	sti	$r6, $r1, -20
	sti	$r7, $r1, -21
	mov	$r4, $r7
	mov	$r5, $r6
	fmov	$f2, $f7
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -23
	subi	$r1, $r1, 24
	jal	calc_dirvec.3024
	addi	$r1, $r1, 24
	ldi	$r29, $r1, -23
	addi	$r3, $r0, 0
	ldi	$r7, $r1, -21
	addi	$r4, $r7, 2
	fldi	$f6, $r1, -6
	fldi	$f1, $r1, -19
	ldi	$r6, $r1, -20
	sti	$r4, $r1, -22
	mov	$r5, $r6
	fmov	$f2, $f6
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -24
	subi	$r1, $r1, 25
	jal	calc_dirvec.3024
	addi	$r1, $r1, 25
	ldi	$r29, $r1, -24
	ldi	$r6, $r1, -20
	addi	$r3, $r6, 1
	addi	$r5, $r0, 5
	blt	$r3, $r5, ble_else.43721
	subi	$r5, $r3, 5
	j	ble_cont.43722
ble_else.43721:
	mov	$r5, $r3
ble_cont.43722:
	addi	$r3, $r0, 0
	fldi	$f5, $r1, -9
	fldi	$f1, $r1, -19
	ldi	$r7, $r1, -21
	sti	$r5, $r1, -23
	mov	$r4, $r7
	fmov	$f2, $f5
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -25
	subi	$r1, $r1, 26
	jal	calc_dirvec.3024
	addi	$r1, $r1, 26
	ldi	$r29, $r1, -25
	addi	$r3, $r0, 0
	fldi	$f4, $r1, -11
	fldi	$f1, $r1, -19
	ldi	$r5, $r1, -23
	ldi	$r4, $r1, -22
	fmov	$f2, $f4
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -25
	subi	$r1, $r1, 26
	jal	calc_dirvec.3024
	addi	$r1, $r1, 26
	ldi	$r29, $r1, -25
	ldi	$r5, $r1, -23
	addi	$r3, $r5, 1
	addi	$r5, $r0, 5
	blt	$r3, $r5, ble_else.43723
	subi	$r5, $r3, 5
	j	ble_cont.43724
ble_else.43723:
	mov	$r5, $r3
ble_cont.43724:
	addi	$r3, $r0, 0
	fldi	$f3, $r1, -13
	fldi	$f1, $r1, -19
	ldi	$r7, $r1, -21
	sti	$r5, $r1, -24
	mov	$r4, $r7
	fmov	$f2, $f3
	fmov	$f4, $f16
	fmov	$f3, $f16
	sti	$r29, $r1, -26
	subi	$r1, $r1, 27
	jal	calc_dirvec.3024
	addi	$r1, $r1, 27
	ldi	$r29, $r1, -26
	addi	$r3, $r0, 0
	fldi	$f2, $r1, -15
	fldi	$f1, $r1, -19
	ldi	$r5, $r1, -24
	ldi	$r4, $r1, -22
	fmov	$f3, $f16
	fmov	$f4, $f16
	sti	$r29, $r1, -26
	subi	$r1, $r1, 27
	jal	calc_dirvec.3024
	addi	$r1, $r1, 27
	ldi	$r29, $r1, -26
	addi	$r4, $r0, 1
	ldi	$r5, $r1, -24
	addi	$r3, $r5, 1
	addi	$r5, $r0, 5
	blt	$r3, $r5, ble_else.43725
	subi	$r5, $r3, 5
	j	ble_cont.43726
ble_else.43725:
	mov	$r5, $r3
ble_cont.43726:
	fldi	$f1, $r1, -19
	ldi	$r7, $r1, -21
	mov	$r6, $r4
	mov	$r4, $r7
	sti	$r29, $r1, -26
	subi	$r1, $r1, 27
	jal	calc_dirvecs.3032
	addi	$r1, $r1, 27
	ldi	$r29, $r1, -26
	ldi	$r8, $r1, -18
	subi	$r5, $r8, 1
	ldi	$r6, $r1, -20
	addi	$r3, $r6, 2
	addi	$r6, $r0, 5
	blt	$r3, $r6, ble_else.43727
	subi	$r6, $r3, 5
	j	ble_cont.43728
ble_else.43727:
	mov	$r6, $r3
ble_cont.43728:
	ldi	$r7, $r1, -21
	addi	$r4, $r7, 4
	mov	$r7, $r5
	j	calc_dirvec_rows.3037
bge_else.43720:
	jr	$r29
bge_else.43709:
	jr	$r29

#---------------------------------------------------------------------
# args = [$r6, $r7]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
create_dirvec_elements.3043:
	blt	$r7, $r0, bge_else.43731
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r4, $r3
	ldi	$r3, $r0, 585
	sti	$r4, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	min_caml_create_array
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	mov	$r5, $r3
	mov	$r3, $r2
	addi	$r2, $r2, 2
	sti	$r5, $r3, 1
	ldi	$r4, $r1, 0
	sti	$r4, $r3, 0
	slli	$r4, $r7, 0
	str	$r3, $r6, $r4
	subi	$r7, $r7, 1
	blt	$r7, $r0, bge_else.43732
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	min_caml_create_float_array
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	mov	$r4, $r3
	ldi	$r3, $r0, 585
	sti	$r4, $r1, -1
	sti	$r29, $r1, -3
	subi	$r1, $r1, 4
	jal	min_caml_create_array
	addi	$r1, $r1, 4
	ldi	$r29, $r1, -3
	mov	$r5, $r3
	mov	$r3, $r2
	addi	$r2, $r2, 2
	sti	$r5, $r3, 1
	ldi	$r4, $r1, -1
	sti	$r4, $r3, 0
	slli	$r4, $r7, 0
	str	$r3, $r6, $r4
	subi	$r7, $r7, 1
	blt	$r7, $r0, bge_else.43733
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -3
	subi	$r1, $r1, 4
	jal	min_caml_create_float_array
	addi	$r1, $r1, 4
	ldi	$r29, $r1, -3
	mov	$r4, $r3
	ldi	$r3, $r0, 585
	sti	$r4, $r1, -2
	sti	$r29, $r1, -4
	subi	$r1, $r1, 5
	jal	min_caml_create_array
	addi	$r1, $r1, 5
	ldi	$r29, $r1, -4
	mov	$r5, $r3
	mov	$r3, $r2
	addi	$r2, $r2, 2
	sti	$r5, $r3, 1
	ldi	$r4, $r1, -2
	sti	$r4, $r3, 0
	slli	$r4, $r7, 0
	str	$r3, $r6, $r4
	subi	$r7, $r7, 1
	blt	$r7, $r0, bge_else.43734
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -4
	subi	$r1, $r1, 5
	jal	min_caml_create_float_array
	addi	$r1, $r1, 5
	ldi	$r29, $r1, -4
	mov	$r4, $r3
	ldi	$r3, $r0, 585
	sti	$r4, $r1, -3
	sti	$r29, $r1, -5
	subi	$r1, $r1, 6
	jal	min_caml_create_array
	addi	$r1, $r1, 6
	ldi	$r29, $r1, -5
	mov	$r5, $r3
	mov	$r3, $r2
	addi	$r2, $r2, 2
	sti	$r5, $r3, 1
	ldi	$r4, $r1, -3
	sti	$r4, $r3, 0
	slli	$r4, $r7, 0
	str	$r3, $r6, $r4
	subi	$r7, $r7, 1
	j	create_dirvec_elements.3043
bge_else.43734:
	jr	$r29
bge_else.43733:
	jr	$r29
bge_else.43732:
	jr	$r29
bge_else.43731:
	jr	$r29

#---------------------------------------------------------------------
# args = [$r8]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
create_dirvecs.3046:
	blt	$r8, $r0, bge_else.43739
	addi	$r6, $r0, 120
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	min_caml_create_float_array
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	mov	$r4, $r3
	ldi	$r3, $r0, 585
	sti	$r4, $r1, 0
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	min_caml_create_array
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	mov	$r5, $r3
	mov	$r3, $r2
	addi	$r2, $r2, 2
	sti	$r5, $r3, 1
	ldi	$r4, $r1, 0
	sti	$r4, $r3, 0
	mov	$r4, $r3
	mov	$r3, $r6
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	min_caml_create_array
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	slli	$r4, $r8, 0
	sti	$r3, $r4, 413
	slli	$r3, $r8, 0
	ldi	$r6, $r3, 413
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -2
	subi	$r1, $r1, 3
	jal	min_caml_create_float_array
	addi	$r1, $r1, 3
	ldi	$r29, $r1, -2
	mov	$r4, $r3
	ldi	$r3, $r0, 585
	sti	$r4, $r1, -1
	sti	$r29, $r1, -3
	subi	$r1, $r1, 4
	jal	min_caml_create_array
	addi	$r1, $r1, 4
	ldi	$r29, $r1, -3
	mov	$r5, $r3
	mov	$r3, $r2
	addi	$r2, $r2, 2
	sti	$r5, $r3, 1
	ldi	$r4, $r1, -1
	sti	$r4, $r3, 0
	sti	$r3, $r6, 118
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -3
	subi	$r1, $r1, 4
	jal	min_caml_create_float_array
	addi	$r1, $r1, 4
	ldi	$r29, $r1, -3
	mov	$r4, $r3
	ldi	$r3, $r0, 585
	sti	$r4, $r1, -2
	sti	$r29, $r1, -4
	subi	$r1, $r1, 5
	jal	min_caml_create_array
	addi	$r1, $r1, 5
	ldi	$r29, $r1, -4
	mov	$r5, $r3
	mov	$r3, $r2
	addi	$r2, $r2, 2
	sti	$r5, $r3, 1
	ldi	$r4, $r1, -2
	sti	$r4, $r3, 0
	sti	$r3, $r6, 117
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -4
	subi	$r1, $r1, 5
	jal	min_caml_create_float_array
	addi	$r1, $r1, 5
	ldi	$r29, $r1, -4
	mov	$r4, $r3
	ldi	$r3, $r0, 585
	sti	$r4, $r1, -3
	sti	$r29, $r1, -5
	subi	$r1, $r1, 6
	jal	min_caml_create_array
	addi	$r1, $r1, 6
	ldi	$r29, $r1, -5
	mov	$r5, $r3
	mov	$r3, $r2
	addi	$r2, $r2, 2
	sti	$r5, $r3, 1
	ldi	$r4, $r1, -3
	sti	$r4, $r3, 0
	sti	$r3, $r6, 116
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -5
	subi	$r1, $r1, 6
	jal	min_caml_create_float_array
	addi	$r1, $r1, 6
	ldi	$r29, $r1, -5
	mov	$r4, $r3
	ldi	$r3, $r0, 585
	sti	$r4, $r1, -4
	sti	$r29, $r1, -6
	subi	$r1, $r1, 7
	jal	min_caml_create_array
	addi	$r1, $r1, 7
	ldi	$r29, $r1, -6
	mov	$r5, $r3
	mov	$r3, $r2
	addi	$r2, $r2, 2
	sti	$r5, $r3, 1
	ldi	$r4, $r1, -4
	sti	$r4, $r3, 0
	sti	$r3, $r6, 115
	addi	$r7, $r0, 114
	sti	$r29, $r1, -6
	subi	$r1, $r1, 7
	jal	create_dirvec_elements.3043
	addi	$r1, $r1, 7
	ldi	$r29, $r1, -6
	subi	$r8, $r8, 1
	blt	$r8, $r0, bge_else.43740
	addi	$r6, $r0, 120
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -6
	subi	$r1, $r1, 7
	jal	min_caml_create_float_array
	addi	$r1, $r1, 7
	ldi	$r29, $r1, -6
	mov	$r4, $r3
	ldi	$r3, $r0, 585
	sti	$r4, $r1, -5
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	min_caml_create_array
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
	mov	$r5, $r3
	mov	$r3, $r2
	addi	$r2, $r2, 2
	sti	$r5, $r3, 1
	ldi	$r4, $r1, -5
	sti	$r4, $r3, 0
	mov	$r4, $r3
	mov	$r3, $r6
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	min_caml_create_array
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
	slli	$r4, $r8, 0
	sti	$r3, $r4, 413
	slli	$r3, $r8, 0
	ldi	$r6, $r3, 413
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -7
	subi	$r1, $r1, 8
	jal	min_caml_create_float_array
	addi	$r1, $r1, 8
	ldi	$r29, $r1, -7
	mov	$r4, $r3
	ldi	$r3, $r0, 585
	sti	$r4, $r1, -6
	sti	$r29, $r1, -8
	subi	$r1, $r1, 9
	jal	min_caml_create_array
	addi	$r1, $r1, 9
	ldi	$r29, $r1, -8
	mov	$r5, $r3
	mov	$r3, $r2
	addi	$r2, $r2, 2
	sti	$r5, $r3, 1
	ldi	$r4, $r1, -6
	sti	$r4, $r3, 0
	sti	$r3, $r6, 118
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -8
	subi	$r1, $r1, 9
	jal	min_caml_create_float_array
	addi	$r1, $r1, 9
	ldi	$r29, $r1, -8
	mov	$r4, $r3
	ldi	$r3, $r0, 585
	sti	$r4, $r1, -7
	sti	$r29, $r1, -9
	subi	$r1, $r1, 10
	jal	min_caml_create_array
	addi	$r1, $r1, 10
	ldi	$r29, $r1, -9
	mov	$r5, $r3
	mov	$r3, $r2
	addi	$r2, $r2, 2
	sti	$r5, $r3, 1
	ldi	$r4, $r1, -7
	sti	$r4, $r3, 0
	sti	$r3, $r6, 117
	addi	$r3, $r0, 3
	fmov	$f0, $f16
	sti	$r29, $r1, -9
	subi	$r1, $r1, 10
	jal	min_caml_create_float_array
	addi	$r1, $r1, 10
	ldi	$r29, $r1, -9
	mov	$r4, $r3
	ldi	$r3, $r0, 585
	sti	$r4, $r1, -8
	sti	$r29, $r1, -10
	subi	$r1, $r1, 11
	jal	min_caml_create_array
	addi	$r1, $r1, 11
	ldi	$r29, $r1, -10
	mov	$r5, $r3
	mov	$r3, $r2
	addi	$r2, $r2, 2
	sti	$r5, $r3, 1
	ldi	$r4, $r1, -8
	sti	$r4, $r3, 0
	sti	$r3, $r6, 116
	addi	$r7, $r0, 115
	sti	$r29, $r1, -10
	subi	$r1, $r1, 11
	jal	create_dirvec_elements.3043
	addi	$r1, $r1, 11
	ldi	$r29, $r1, -10
	subi	$r8, $r8, 1
	j	create_dirvecs.3046
bge_else.43740:
	jr	$r29
bge_else.43739:
	jr	$r29

#---------------------------------------------------------------------
# args = [$r12, $r13]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
init_dirvec_constants.3048:
	blt	$r13, $r0, bge_else.43743
	slli	$r3, $r13, 0
	ldr	$r8, $r12, $r3
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	subi	$r13, $r13, 1
	blt	$r13, $r0, bge_else.43744
	slli	$r3, $r13, 0
	ldr	$r8, $r12, $r3
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	subi	$r13, $r13, 1
	blt	$r13, $r0, bge_else.43745
	slli	$r3, $r13, 0
	ldr	$r8, $r12, $r3
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	subi	$r13, $r13, 1
	blt	$r13, $r0, bge_else.43746
	slli	$r3, $r13, 0
	ldr	$r8, $r12, $r3
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	subi	$r13, $r13, 1
	blt	$r13, $r0, bge_else.43747
	slli	$r3, $r13, 0
	ldr	$r8, $r12, $r3
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	subi	$r13, $r13, 1
	blt	$r13, $r0, bge_else.43748
	slli	$r3, $r13, 0
	ldr	$r8, $r12, $r3
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	subi	$r13, $r13, 1
	blt	$r13, $r0, bge_else.43749
	slli	$r3, $r13, 0
	ldr	$r8, $r12, $r3
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	subi	$r13, $r13, 1
	blt	$r13, $r0, bge_else.43750
	slli	$r3, $r13, 0
	ldr	$r8, $r12, $r3
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	subi	$r13, $r13, 1
	j	init_dirvec_constants.3048
bge_else.43750:
	jr	$r29
bge_else.43749:
	jr	$r29
bge_else.43748:
	jr	$r29
bge_else.43747:
	jr	$r29
bge_else.43746:
	jr	$r29
bge_else.43745:
	jr	$r29
bge_else.43744:
	jr	$r29
bge_else.43743:
	jr	$r29

#---------------------------------------------------------------------
# args = [$r14]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
init_vecset_constants.3051:
	blt	$r14, $r0, bge_else.43759
	slli	$r3, $r14, 0
	ldi	$r12, $r3, 413
	ldi	$r8, $r12, 119
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r8, $r12, 118
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r8, $r12, 117
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r8, $r12, 116
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r8, $r12, 115
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r8, $r12, 114
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r8, $r12, 113
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r8, $r12, 112
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	addi	$r13, $r0, 111
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	init_dirvec_constants.3048
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	subi	$r14, $r14, 1
	blt	$r14, $r0, bge_else.43760
	slli	$r3, $r14, 0
	ldi	$r12, $r3, 413
	ldi	$r8, $r12, 119
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r8, $r12, 118
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r8, $r12, 117
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r8, $r12, 116
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r8, $r12, 115
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r8, $r12, 114
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	ldi	$r8, $r12, 113
	ldi	$r3, $r0, 585
	subi	$r6, $r3, 1
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	iter_setup_dirvec_constants.2832
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	addi	$r13, $r0, 112
	sti	$r29, $r1, -1
	subi	$r1, $r1, 2
	jal	init_dirvec_constants.3048
	addi	$r1, $r1, 2
	ldi	$r29, $r1, -1
	subi	$r14, $r14, 1
	j	init_vecset_constants.3051
bge_else.43760:
	jr	$r29
bge_else.43759:
	jr	$r29
