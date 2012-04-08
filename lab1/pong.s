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
  li    $a0, 0
  jal   write_byte
  li    $a0, 0
  jal   write_byte
  li    $a0, 0x4
  jal   write_byte
  li    $a0, 39
  jal   write_byte
  li    $a0, 29
  jal   write_byte
  li    $a0, 0x4
  jal   write_byte

# GAME CODE GOES HERE

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
  jr    $ra

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
