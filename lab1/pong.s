# EE108B Lab 1

# This is the starter code for EE 108B Lab 1

# You must implement self-playing pong using the SPIM simulator and the
# provided Python script that serves as a display that will interact
# with your MIPS program via memory-mapped I/O.

# The display can draw squares of different colors on a 40x30 grid.
# To draw squares, use the following protocol:

# 1. Store a byte into the transmitter data register (memory address 0xffff000c)
#    representing the x-coordinate of the square to draw.

# 2. Put a byte into the transmitter data register
#    representing the y-coordinate of the square to draw.

# 3. Put a byte into the transmitter data register
#    representing the color to make the square.
#    The color format is 3-bit RGB, e.g., 0b010 is green, 0b011 is yellow.

# Once the console has read three bytes successfully, it will display the square
# according to the three parameters supplied by your program.
# You must wait for the transmitter control register's ready bit
# to be set before writing a byte to the transmitter data register.
# Please see the appendix of Patterson and Hennessy on SPIM for a thorough
# explanation of this mechanism.


# You may implement the following extensions for up to three points of extra credit (out of fifteen):
# 1. Paddles on every edge of the grid, all tracking the ball.
# 2. The paddles and ball move faster as the game progresses.
# 3. Implement "Breakout". You may interpret this liberally, but at a minimum it must involve some form
#    of destructible blocks whose states are stored in dynamic memory. Read SPIM documentation on syscalls
#    to learn how to do this.

.text
.globl main

main:
# we put some useful constants on the "stack"
# you may add more or change the existing ones
# other than the maximum x and y coordinates if you wish
  li    $t0, 40         # maximum x coordinate
  sw    $t0, 0($sp)
  li    $t0, 30         # maximum y coordinate
  sw    $t0, 4($sp)
  li    $t0, 0          # background color (black)
  sw    $t0, 8($sp)
  li    $t0, 0x02       # paddle color
  sw    $t0, 12($sp)
  li    $t0, 0x04       # ball color
  sw    $t0, 16($sp)
  li    $t0, 1          # ball height & width, paddle width
  sw    $t0, 20($sp)
  li    $t0, 6          # paddle height
  sw    $t0, 24($sp)

# this is an example of proper use of the display protocol
# we have provided a correctly implemented "write_byte" function below
#  li    $a0, 0
#  jal   write_byte
#  li    $a0, 0
#  jal   write_byte
#  li    $a0, 0x4
#  jal   write_byte
#  li    $a0, 39
#  jal   write_byte
#  li    $a0, 29
#  jal   write_byte
#  li    $a0, 0x4
#  jal   write_byte

# GAME CODE GOES HERE

# draw background color
  li	$s0, 0	 	# x coordinate
  li	$s1, 0		# y coordinate
  lw    $s2, 0($sp)     # max x coordinate
  lw    $s3, 4($sp)     # max y coordinate
  lw	$a1, 8($sp)	# background color
#  jal	draw
	
# draw default ball and paddle	
  srl	$s0, $s2, 1
  srl	$s1, $s3, 1
  lw	$s2, 20($sp)
  lw	$s3, 20($sp)
  lw	$a1, 16($sp)
  jal	draw
  move	$s4, $s0
  move	$s5, $s1
#paddle	
  li	$s0, 0
  addi	$s1, $s1, -3
  lw	$s3, 24($sp)
  lw	$a1, 12($sp)
  jal	draw

# start game loop
# s4, s5 position of ball
# s6, s7 velocity of ball
# s5, s6 game screen size
gamebegin:	
  li	$s6, -1
  li	$s7, -1

game:	
checkx:
  blez	$s4, end_the_game
  li	$t0, 1
  beq	$s4, $t0, flipx
  lw	$t0, 0($sp)
  addi	$t0, $t0, -1
  beq	$s4, $t0, flipx
checky:	
  blez	$s5, flipy
  lw	$t0, 4($sp)
  addi	$t0, $t0, -1
  beq	$s5, $t0, flipy	

erase:	
# erase ball
  move  $s0, $s4
  move  $s1, $s5
  lw    $s2, 20($sp)
  lw    $s3, 20($sp)
  lw    $a1, 8($sp)
  jal   draw
# erase paddle
  li    $s0, 0
  addi  $s1, $s1, -3
  bgez  $s1, erasepaddlejump1
  li    $s1, 0
erasepaddlejump1:
  lw    $s3, 24($sp)
  add   $t0, $s3, $s1
  lw    $t1, 4($sp)
  bleu  $t0, $t1, erasepaddlejump2
  sub   $s1, $t1, $s3
erasepaddlejump2:
  jal   draw
	
redraw:
  add	$s4, $s4, $s6
  add	$s5, $s5, $s7
#redraw ball
  move  $s0, $s4
  move	$s1, $s5
  lw    $s2, 20($sp)
  lw    $s3, 20($sp)
  lw    $a1, 16($sp)
  jal   draw
#redraw paddle
  li	$s0, 0
  addi  $s1, $s1, -3
  bgez 	$s1, redrawpaddlejump1
  li	$s1, 0
redrawpaddlejump1:	
  lw    $s3, 24($sp)
  add   $t0, $s3, $s1
  lw	$t1, 4($sp)
  bleu	$t0, $t1, redrawpaddlejump2
  sub   $s1, $t1, $s3
redrawpaddlejump2:	
  lw    $a1, 12($sp)
  jal   draw
	
  j	game
	
# some things you need to do:
# draw on top of the old ball and paddle to erase them
# determine the new positions of the ball and paddle
# draw the ball and paddle again

# before entering this loop, you should draw the background color
# over the entire grid

# this will exit SPIM and stop the display from asking for more output
# the implementation is below
  j     end_the_game

 

# write useful standalone functions here

# functions can call other functions, but make sure to use consistent calling conventions
# and to restore return addresses properly

# function: write_byte
# write the byte in $a0 to the transmitter data register after polling the ready bit
# of the transmitter control register
# the transmitter control register is at address 0xffff0008
# the transmitter data register is at address 0xffff000c
# the "la" pseudoinstruction is very convenient for loading these

write_byte:
# IMPLEMENT THIS FIRST
  la	$t0, 0xffff0008
  lw	$t0, 0($t0)
  andi	$t1, $t0, 1
  blez	$t1, write_byte
  sb	$a0, 0xffff000c
  jr    $ra

# function: draw
# x start stored in s0
# y start stored in s1
# x width stored in s2
# y width stored in s3
# color stored in a1
draw:
  move	$t2, $ra
  li    $t3, 0
  li    $t4, 0
loop:
  add	$a0, $t3, $s0
  jal	write_byte
  add	$a0, $t4, $s1
  jal	write_byte
  move	$a0, $a1
  jal	write_byte
  addi	$t3, $t3, 1
  bne	$t3, $s2, loop
  li	$t3, 0
  addi	$t4, $t4, 1
  bne	$t4, $s3, loop
  jr	$t2


# function: flipx
flipx:	
  neg	$s6, $s6
  j	checky
	
# function: flipy
flipy:
  neg	$s7, $s7
  j	erase
	
# function: print_int
# displays the contents of $a0 as an integer on stdout
# note that it will only work if you run pong without the display, which consumes stdout
# very useful for debugging
print_int:
  li    $v0, 1
  syscall

# function: end_the_game
# send the exit signal to the display and make an exit syscall in SPIM
# this stops the Python tkinter display and SPIM safely
# also be advised that this uses write_byte, so it won't work until you implement it
end_the_game:
  li    $a0, 69 # 69 is 'E'
  jal   write_byte
  li    $v0, 10
  syscall
