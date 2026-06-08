#!/bin/bash
# Must be executed from within the source code directory.
gcc -Wall -Wextra -O2 -g $(pkg-config --cflags libsystemd) -o kfocus-fand ./kfocus-fand.c $(pkg-config --libs libsystemd)
