# EE108B HW 1 Problem 2

.text
.globl main

main:
	jal	change
	j	end
	
change:	 # base case
	li	$t0, 7
	beq	$a0, $t0, base1
	li	$t0, 4
	beq	$a0, $t0, base1
	blt	$a0, $t0, base2
	li	$t0, 7
	blt	$a0, $t0, base3
	j	recurse

base1:
	li	$v0, 1
	jr	$ra

base2:
	move	$v0, $a0
	jr	$ra

base3:
	addi	$v0, $a0, -3
	jr	$ra

recurse:
	sub	$sp, $sp, 12	# store 3 registers to stack
	sw	$ra, 0($sp)	# $ra in 1st reg
	sw	$a0, 4($sp)	# $a0 in 2nd reg

achange:
	# a = change (amount - 1)
	sub	$a0, $a0, 1	# amount - 1
	jal	change
	sw	$v0, 8($sp)	# $v0 in 3rd reg

bchange:
	# b = change (amount - 4)
	lw	$a0, 4($sp)	# get orig value
	sub	$a0, $a0, 4	# amount - 4
	jal	change
	lw	$t0, 8($sp)	# get 1st recursive result
	slt	$t1, $v0, $t0
	blez	$t1, cchange
	sw	$v0, 8($sp)

cchange:
	# c = change (amount - 7)
	lw	$a0, 4($sp)	# get orig value
	sub	$a0, $a0, 7	# amount - 7
	jal	change
	lw	$t0, 8($sp)	# get 1st/2nd recursive result
	slt	$t1, $v0, $t0
	blez	$t1, finish
	sw	$v0, 8($sp)

finish:
	# t0 holds min of a, b, and c
	# fix stack and return result
	addi	$v0, $t0, 1
	lw	$ra, 0($sp)
	addi	$sp, $sp, 12
	jr	$ra
	
end:	
	#syscall
