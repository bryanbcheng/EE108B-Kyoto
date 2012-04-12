#!/usr/bin/env sh

spim -mapped_io -st 1024 -file pong.s | ./pong_display.py
