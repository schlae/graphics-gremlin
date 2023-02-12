#!/bin/bash

if ! verilator -f gather.f test.cpp --cc --exe --trace > s; then
	cat s; rm s
	exit $?
fi

if ! make -j -C obj_dir -f Vtest.mk Vtest > s; then
	cat s; rm s
	exit $?
fi

if ! obj_dir/Vtest $*; then
	exit $?
fi
# verilator_coverage logs/coverage.dat --annotate coverage
