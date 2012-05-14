# EE108B HW 1 Problem 2c

.text
.globl main

main:
	jal	change
	j	end
	
change:
	li	$t0, 7
	div	$a0, $t0	# amount / 7 & amount % 7
	mflo	$t1		# amount / 7
	li	$t0, 4
	mfhi	$t2		# amount % 7
	srl	$t3, $t2, 2	# remainder / 4
	add	$t1, $t1, $t3
	andi	$t3, $t2, 4	# remainder % 4
	add	$v0, $t1, $t3
	
end:	
	syscall
