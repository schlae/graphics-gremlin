/*

	This file runs a simulation on the purely combinational logic of the envelope generator.
	The simulation is controlled via text files

	The text file is a sequence of write commands that will configure the inputs to the logic
	then a wait command will kick the simulation for a given number of clocks

	The LFO is always running. The simulations show that SSG is well implemented and that
	the circuit behaves within bounds for extreme cases

	The core logic of the ASDR envelope is simulated on separate test bench eg2.

	Arguments:
		-w write VCD	(always enabled, uncomment to evaluate this argument)
		-o path-to-test-file

*/

#include <cstring>
#include <iostream>
#include <iomanip>
#include <fstream>
#include "Vsweep.h"
#include "verilated_vcd_c.h"

using namespace std;


vluint64_t main_time = 0;	   // Current simulation time
const vluint64_t HALFPERIOD=133; // 3.57MHz (133ns * 2)
Vsweep top;
VerilatedVcdC* vcd;
bool keep = true;

void clock(int n) {
	while( n-->0 ) {
		top.eval();
		if(keep) vcd->dump(main_time);

		main_time += HALFPERIOD;
		top.clk=1;
		top.eval();
		if(keep) vcd->dump(main_time);

		main_time += HALFPERIOD;
		top.clk=0;
	}
}

double sc_time_stamp () {	   // Called by $time in Verilog
   return main_time;
}

void reset() {
	top.rst = 1;
	top.keyon_I = 0;
	clock(18*2);
	top.rst = 0;
}

void attack_sweep() {
	// YM2413
	// float atime[] = { 0.1, 1738,863,432,216,108,54,27,13.52,6.76,3.38,1.69,0.84,0.5,0.28,0.1 };
	// YM3812
	float atime[] = { 0.1, 2826, 1413, 706, 353, 176, 88, 44, 22, 11, 5.52, 2.76, 1.40, 0.7, 0.38,0.1 };

	top.ksr_II=1;
	for( top.arate_I=3; top.arate_I<15; top.arate_I++ )
	for( top.block_I=0; top.block_I<4; top.block_I++ )
	{
		reset();
		top.keyon_I = 1;
		vluint64_t t0=main_time;
		int limit=1'000'000;
		if( top.arate_I!=0) {
			while( (int)top.eg_V!=0 && --limit ) {
				clock( 10 );
			}
		}
		if( limit==0 ) {
			cout << "ARATE " << hex << (int)top.arate_I << dec << " timeout " << "(" << (int) top.eg_V << ")\n";
			if( top.arate_I>5 ) break; // do not continue
		}
		if( (int)top.eg_V==0 ) {
			float delta=(float)main_time-t0;
			delta /= 1e6;
			float err = (delta-atime[top.arate_I])/atime[top.arate_I]*100.0;
			printf("ARATE %X (block %d) %6.2f ms (%4.1f %%)\n",
				top.arate_I, top.block_I, delta, err );
		}
	}
}

void decay_sweep() {
	// YM3812
	float atime[] = { 0.1, 39280,19640,9820,4910,2455,1227,613.7,306.8,153.44,76.72,38.36,19.20,9.60,4.80,2.40 };

	top.arate_I=15;
	top.sl_I=15;
	for( top.drate_I= keep ? 5 : 1; top.drate_I<16; top.drate_I++ ) {
		reset();
		top.keyon_I = 1;
		clock( 100 );
		vluint64_t t0=main_time;
		int limit=1'000'000;
		if( top.drate_I!=0) {
			while( (int)top.eg_V<0x3e0 && --limit ) {
				clock( 10 );
			}
		}
		if( limit==0 ) {
			cout << "DRATE " << hex << (int)top.drate_I << dec << " timeout " << "(" << (int) top.eg_V << ")\n";
			if( top.drate_I>5 ) break; // do not continue
		}
		if( (int)top.eg_V>=0x3e0 ) {
			float delta=(float)main_time-t0;
			delta /= 1e6;
			float err = (delta-atime[top.drate_I])/atime[top.drate_I]*100.0;
			printf("DRATE %X (block %d) %6.2f ms (%4.1f %%)\n",
				top.drate_I, top.block_I, delta, err );
		} else {
			printf("End not reached\n");
		}
	}
}

int main(int argc, char *argv[]) {
	int err_code=0;
	vcd = new VerilatedVcdC;
	bool trace=true;

	if( trace ) {
		Verilated::traceEverOn(true);
		top.trace(vcd,99);
		vcd->open("test.vcd");
	}

	//attack_sweep();
	decay_sweep();

	if(trace) vcd->close();
	// VerilatedCov::write("logs/coverage.dat");
	delete vcd;
	return err_code;
}


void remove_blanks( char*& str ) {
	while( *str!=0 && (*str==' ' || *str=='\t') ) str++;
}