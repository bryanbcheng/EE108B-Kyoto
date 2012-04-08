#!/usr/bin/env python3.2

# Pong display code for Stanford EE 108B Lab 1

# Written by Chris Copeland (chrisnc@cs.stanford.edu)
# April 2, 2012

# Dependencies: Python 3.2 or later, and the appropriate version of Python tkinter

from tkinter import *
import sys

# make the main window and give it a title and size
root = Tk()
root.title('PONG')
ni = 40 # number of blocks in the x direction
nj = 30 # number of blocks in the y direction
f = 6 # width and height of the blocks in pixels
margin = 40
root.geometry(str(ni * f + margin) + "x" + str(nj * f + margin))

# make the canvas to draw the Pong game
pong_screen = Canvas(root)
pong_screen.pack(side=TOP)

blocks = {}
for i in range(1, ni + 1):
    for j in range(1, nj + 1):
        blocks[(i, j)] = pong_screen.create_rectangle(f * i, f * j, f * (i + 1), f * (j + 1), fill="#000000", width=0)

# skip over the first line of output that tells us we loaded the exception handler
sys.stdin.readline()

bytes_per_block = 3

# function to read a binary word from stdin and draw a rectangle on the canvas
# we read one word, then we reschedule this function to be run again immediately
# in the Tkinter main event loop
def read_and_draw_block():
    pixel_bytes = [ord(c) for c in sys.stdin.read(bytes_per_block)]
    if ord('E') in pixel_bytes:
        print("Received exit signal. Will not read any more bytes... (Close Tk window to exit.)")
        return
    if len(pixel_bytes) < bytes_per_block:
        print("Error reading " + str(bytes_per_block) + " bytes from stdin...")
        return
    i, j = pixel_bytes[0:2] 
    color_string = "#" + "".join(["ff" if pixel_bytes[2] & m else "00" for m in [4, 2, 1]])
    if 0 <= i < ni and 0 <= j < nj:
        print("Drawing block at (" + str(i) + ", " + str(j) + ") with color " + color_string)
        pong_screen.itemconfig(blocks[(i + 1, j + 1)], fill=color_string)
    else:
        print("Attempted to draw out of bounds... (" + str(i) + ", " + str(j) + ")")
    root.after(1, read_and_draw_block)

root.after(1, read_and_draw_block)
root.mainloop()
