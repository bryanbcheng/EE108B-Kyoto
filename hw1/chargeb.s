# EE108B HW 1 Problem 2b

.text
.globl main

main:
	jal	change
	j	end
	
# amount stored in $a0
	# space stored in $a1
change:
	li	$t0, 0		# space[0] = 0
	sw	$t0, $t0($a1)
	li	$t0, 1		# space[1] = 1
	sll	$t1, $t0, 2
	sw	$t0, $t1,($a1)
	li	$t0, 2		# space[2] = 2
	sll	$t1, $t0, 2
	sw	$t0, $t1,($a1)
	li	$t0, 3		# space[3] = 3
	sll	$t1, $t0, 2
	sw	$t0, $t1,($a1)
	li	$t0, 4		# space[4] = 1
	sll	$t1, $t0, 2
	li	$t2, 1
	sw	$t2, $t1,($a1)
	li	$t0, 5		# space[5] = 2
	sll	$t1, $t0, 2
	li	$t2, 2
	sw	$t2, $t1,($a1)
	li	$t0, 6		# space[6] = 3
	sll	$t1, $t0, 2
	li	$t2, 3
	sw	$t2, $t1,($a1)

	# for loop
loop:
	addi	$t0, $t0, 1	# i++

aspace:
	addi	$t1, $t0, -1
	sll	$t2, $t1, 2
	lw	$s0, $t2($a1)	# a = space[i - 1]

bspace:
	addi	$t1, $t0, -4
	sll	$t2, $t1, 2
	lw	$s1, $t2($a1)	# b = space[i - 4]
	slt	$t3, $s1, $s0
	blez	$t3, cspace
	move	$s0, $s1

cspace:
	addi	$t1, $t0, -7
	sll	$t2, $t1, 2
	lw	$s1, $t2($a1)	# c = space[i - 7]
	slt	$t3, $s1, $s0
	blez	$t3, set
	move	$s0, $s1

set:
	sll	$t2, $t0, 2
	addi	$s0, $s0, 1
	sw	$s0, $t2($a1)	# space[i] = min(a,b,c) + 1

	beq	$t0, $a0, loop

	sll	$t0, $a0, 2
	lw	$v0, $t0($a1)
	
end:	
	syscall
