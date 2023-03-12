#!/bin/bash

TOP=jtopl
DUMPSIGNALS=
EXTRA=
GYM_FILE=
GYM_ARG=
FAST=-DFASTDIV
VERI_EXTRA="-DSIMULATION"
WAV_FILE=
GATHER=gather.f
SKIPMAKE=FALSE
MACROS=

# Locate jtfiles.go
if which jtfiles > /dev/null; then
    JTFILES=jtfiles
elif [ -e $JTFRAME/bin/jtfiles.go ]; then
    JTFILES="go run $JTFRAME/bin/jtfiles.go"
else
    cat <<EOF
Cannot find jtfiles executable or source file. Clone
the JTFRAME repository (https://github.com/jotego/jtframe)
and set the environment variable JTFRAME to point to it.
Or run this script from within a JTOPL submodule in a
properly set up JTCORE repository
EOF
fi
JTFILES="$JTFILES -f sim -output gather"
$JTFILES -parse ../../hdl/jt26.yaml

function set_slow {
    FAST=
    EXTRA="$EXTRA -slow"    
}

#function eval_args {
    while [ $# -gt 0 ]; do
        case "$1" in
        "-w")
            echo "Signal dump enabled"
            DUMPSIGNALS="-trace";;
        "-w0")
            shift
            echo "Signal dump enabled from time $1"
            DUMPSIGNALS="-trace"
            EXTRA="$EXTRA -trace_start $1";;
        "-hex")
            echo "Hexadecimal dump enabled"
            FAST=
            EXTRA="$EXTRA -hex";;
        "-w1")
            echo "Signal dump enabled (only top level)"
            DUMPSIGNALS="-trace"
            VERI_EXTRA="$VERI_EXTRA --trace-depth 1";;
        "-f")
            shift
            if [ ! -e "$1" ]; then
                echo "Cannot open file " $1 " for GYM parsing"
                exit 1
            fi
            GYM_ARG="-gym"
            GYM_FILE="$1"
            if [[ "$WAV_FILE" == "" ]]; then
                WAV_FILE=$(basename "$GYM_FILE" .vgm).wav
            fi;;
        -opl2)
            # Ideally, I should use jtopl2.v instead of jtopl.v as the top level
            # but it gets messy to change the top level name in test.cpp
            MACROS="$MACROS -GOPL_TYPE=2 -DJTOPL2"
            $JTFILES -parse ../../hdl/jtopl2.yaml
            ;;
        -2413 | -opll )
            EXTRA="$EXTRA -2413"
            TOP="jt2413"
            $JTFILES -parse ../../hdl/jt2413.yaml
            ;;
        "-time" | "-t")
            shift
            EXTRA="$EXTRA -time $1";;
        "-o")
            shift
            WAV_FILE="$1";;
        "-noam" | "-noks" | "-nomul" | "-mute" | "-nodecode")
            EXTRA="$EXTRA $1"
            if [[ "$1" = -mute ]]; then
                shift
                EXTRA="$EXTRA $1"
            fi;;
        "-d")
            shift
            VERI_EXTRA="-D$1 $VERI_EXTRA";;
        "-runonly")
            echo Skipping Verilator and make steps
            SKIPMAKE=TRUE;;
        -h | -help | --help)
            cat << EOF
    -w           dump all signals to file test.fst
    -w1          dump top level signals to file test.fst
    -w0  t       dump all signals from time t
    -hex         hexadecimal sound dump
    -f           specify vgm file for parsing
    -time | -t   set simulation time
    -o           output wave file name
    -d           add Verilog macro
    -opl2        selects OPL2 chip
    -2413 | opll selects OP-LL chip (YM2413)
    -runonly     do not recompile
EOF
            exit 0;;
        *)
            echo go: unrecognized option $1
            exit 1
        esac
        shift
    done
#}

#eval_args $JT12_VERILATOR $*

if [[ "$GYM_FILE" = "" ]]; then
    echo "Specify the VGM/GYM/JTT file to parse using the argument -f file_name"
    exit 1
fi

echo EXTRA="$EXTRA"
echo GYM_FILE="$GYM_FILE"

if [[ $(expr "$GYM_FILE" : ".*\.vgz$") != 0 ]]; then
    echo Uncompressing vgz file...
    UNZIP_GYM=$(basename "$GYM_FILE" .vgz).vgm
    if [ -e /tmp ]; then
        UNZIP_GYM="/tmp/$UNZIP_GYM"
    fi
    WAV_FILE=$(basename "$UNZIP_GYM" .vgm).wav
    gunzip -S vgz "$GYM_FILE" --to-stdout > "$UNZIP_GYM"
else
    UNZIP_GYM=$GYM_FILE
fi

date

# Link files located in ../../cc
# Maybe I could just reference to files there, but it is not
# so obvious how to do it with Verilator Makefile so I just
# add them here
if [ ! -e WaveWritter.cpp ]; then
    ln -s ../../cc/WaveWritter.cpp
fi

if [ ! -e WaveWritter.hpp ]; then
    ln -s ../../cc/WaveWritter.hpp
fi

if [ $SKIPMAKE = FALSE ]; then
    if ! verilator --cc -f $GATHER --top-module $TOP --prefix Vjtopl \
        -I../../hdl --trace -DTEST_SUPPORT $MACROS -DSIMULATION \
        $VERI_EXTRA $FAST --exe test.cpp VGMParser.cpp WaveWritter.cpp; then
        exit $?
    fi

    if ! make -j -C obj_dir -f Vjtopl.mk Vjtopl; then
        exit $?
    fi
    echo Simulation start...
    echo obj_dir/Vjtopl $DUMPSIGNALS $EXTRA  $GYM_ARG "$UNZIP_GYM" -o "$WAV_FILE"
fi

if [[ $DUMPSIGNALS == "-trace" ]]; then
    if which vcd2fst; then
        # Verilator VCD output goes through standard output
        echo VCD to FST conversion running in parallel
        # filter out lines starting with INFO: because these come from $display commands in verilog and are
        # routed to standard output but are not part of the VCD file
        obj_dir/Vjtopl $DUMPSIGNALS $EXTRA $GYM_ARG "$UNZIP_GYM" -o "$WAV_FILE" |  grep -v "^INFO: " | vcd2fst -v - -f test.fst
    else
        if which simvisdbutil; then
            obj_dir/Vjtopl $DUMPSIGNALS $EXTRA $GYM_ARG "$UNZIP_GYM" -o "$WAV_FILE" | grep -v "^INFO: " > test.vcd
            echo VCD to SST2 conversion
            simvisdbutil test.vcd -output test -overwrite -shm && rm test.vcd
        else
            obj_dir/Vjtopl $DUMPSIGNALS $EXTRA $GYM_ARG "$UNZIP_GYM" -o "$WAV_FILE" > test.vcd
        fi
    fi
else
    obj_dir/Vjtopl $DUMPSIGNALS $EXTRA $GYM_ARG "$UNZIP_GYM" -o "$WAV_FILE"
fi
