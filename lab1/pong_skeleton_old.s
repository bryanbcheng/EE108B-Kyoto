# This is the skeleton file distributed with the old version of the assignment.
# It uses a different memory-mapped I/O protocol, but you can read it
# and get some ideas for how to implement your version of Pong

# pong.s

# Memory-mapped instructions
# --------------------------
# sw $s0, 0xff	-> store data in $s0 to VGA interface
# color in bits 18...16
# x in bits 13...8 (0 <= x < 40)
# y in bits 5...0 (0 <= y < 30)
#
# lw $s0, 0xfd	-> load data from Sega controller into $s0
# bits 4...0 = (b/c, right, left, down, up)

###############
#
# With the exception of the memory mapped I/O devices,
# you should offset all memory accesses with $sp for 
# correct functioning in xspim.
#
# main function
# keep looping through, checking for user input and moving the
# ball around the screen until the game ends
###############

main:
	
	# initialize constants (feel free to change these)
	# remember that you cannot use the lower addresses in xspim (read the lab handout for explanation).
	addi	$t0, $0, 39			# maximum x coordinate
	sw	$t0, 0($sp)
	addi	$t0, $0, 29			# maximum y coordinate
	sw	$t0, 4($sp)
	add	$t0, $0, $0			# background color (black)
	sw	$t0, 8($sp)
	addi	$t0, $0, 0x02			# paddle color
	sw	$t0, 12($sp)
	addi	$t0, $0, 0x04			# ball color
	sw	$t0, 16($sp)
	addi	$t0, $0, 1			# ball height/width, paddle/width
	sw	$t0, 20($sp)
	addi	$t0, $0, 6			# paddle height
	sw	$t0, 24($sp)
	
	#initial ball state
	addi $t0, $0, 20		#initial ball x
	sw $t0, 28($sp)
	addi $t0, $0, 15		#initial ball y
	sw $t0, 32($sp)
	
	#initial paddle state
	addi $t0, $0, 0			#initial paddle x
	sw $t0, 36($sp)	
	addi $t0, $0, 12		#initial paddle y
	sw $t0, 40($sp)
	
	#initialize ball state
	lw $s0, 28($sp)
	lw $s1, 32($sp)



game_loop:
		
	# cover up old ball/paddle by coloring them with background color
	


	# get user input and move paddle


	
	# move the ball vertically and horizontally	


	
	# if the ball is at the left edge, determine if it
	# collided with the paddle, ending the game if it didn't



	# draw the ball and paddle in their new positions
	lw $a0, 16($sp)
	add $a1, $0, $s0
	add $a2, $0, $s1
	jal color_ball


	# stall for a while so the paddle and ball don't move too quickly.
	# change this code if you want to vary the game speed.
	
	lui		$a0, 0x4
	ori		$a0, $a0, 0xffff	# stall for 0x4ffff
	jal		stall
	
	j game_loop
	
	# game over: keep looping until the restart button is pressed,
	# then start a new game
	
###############
# function: stall
# arguments:
#   $a0: number of cycles (x3) to stall for
###############

stall:
	add		$t0, $0, $0
stall_loop:
	beq		$t0, $a0, end_stall
	addi		$t0, $t0, 1
	j		stall_loop
end_stall:
	jr		$ra
	
###############
# function: color_ball
# arguments:
#   $a0: color of the ball
#   $a1: x coordinate of lower left corner of ball
#   $a2: y coordinate of lower left corner of ball
###############

color_ball:
	add $t0, $0, $a0
	sll   $t0, $t0, 8
	add $t0, $t0, $a1
	sll $t0, $t0, 8
	add $t0, $t0, $a2
	sw $t0, 0xFF($0)
	


###############
# function: color_paddle
# arguments:
#   $a0: color of the paddle
#   $a1: y coordinate of bottom of paddle
###############

color_paddle:


###############
# function: color_region
# arguments:
#   $a0: color of region
#   $a1: coordinate of lower left corner of region
#        x in bits 13...8, y in bits 5...0
#   $a2: coordinate of upper right corner of region
#        x in bits 13...8, y in bits 5...0
###############

color_region:
