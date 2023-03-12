#!/bin/bash

if ! verilator -f sweep.f sweep.cpp --cc --exe --trace --timescale 1ns/1ns > s; then
	cat s; rm s
	exit $?
fi

if ! make -j -C obj_dir -f Vsweep.mk Vsweep > s; then
	cat s; rm s
	exit $?
fi

if ! obj_dir/Vsweep $*; then
	exit $?
fi
# verilator_coverage logs/coverage.dat --annotate coverage
