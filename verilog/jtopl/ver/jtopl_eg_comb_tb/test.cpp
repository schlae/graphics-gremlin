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
#include <fstream>
#include "Vtest.h"
#include "verilated_vcd_c.h"

using namespace std;

class Stim {
	ifstream file;
	int wait_count, line_cnt;
	void read_line();
public:
	// inputs
	int keyon_now, keyoff_now, state_in, eg_in, arate, drate, rate2, rrate, sl,
		keycode, eg_cnt, cnt_in, ksr, en_sus, sum_up_in,
		lfo_mod, amsen, ams, tl;
	// outputs
	int state_next, pg_rst, cnt_lsb, pure_eg_out, eg_out, sum_up_out;
	void reset();
	void apply(Vtest* dut);
	void get(Vtest* dut);
	void next(Vtest* dut);
	void open(const char *filename);
	bool done() { return file.eof() && wait_count==0; }
	Stim() { reset(); }
};

vluint64_t main_time = 0;	   // Current simulation time

double sc_time_stamp () {	   // Called by $time in Verilog
   return main_time;
}

int main(int argc, char *argv[]) {	

	Vtest* top = new Vtest;
	Stim stim;
	int err_code=0;
	VerilatedVcdC* vcd = new VerilatedVcdC;
	bool trace=true;

	for(int k=1; k<argc; k++ ) {
		// if( strcmp(argv[k],"-w")==0 ) { trace=true; continue; }
		if( strcmp(argv[k],"-f")==0 ) { stim.open(argv[++k]); continue; }
		cout << "ERROR: unknown argument " << argv[k] << '\n';
		err_code = 2;
		goto quit;
	}

	if( trace ) {
		Verilated::traceEverOn(true);
		top->trace(vcd,99);
		vcd->open("test.vcd");	
	}	

	// time 0 state:
	stim.apply(top); top->eval();
	if(trace) vcd->dump(main_time);

	try{
		do {
			stim.next(top);
			if(trace) vcd->dump(main_time);
		} while( !stim.done() );
	} catch( int ) {}
	quit:
	if(trace) vcd->close();	
	// VerilatedCov::write("logs/coverage.dat");
	delete vcd;
	delete top;
	return err_code;
}


void Stim::reset() {
	keyon_now=0, keyoff_now=0, state_in=0, eg_in=0x3ff, arate=0, drate=0, 
	rrate=0, sl=0, en_sus=0,
	keycode=0, eg_cnt=0, cnt_in=0, ksr=0,
	lfo_mod=0, amsen=0, ams=0, tl=0;
	sum_up_in = 0;
	wait_count=0;
}

void Stim::apply(Vtest* dut) {
	dut->keyon_now	= keyon_now;
	dut->keyoff_now	= keyoff_now;
	dut->state_in	= state_in;
	dut->sum_up_in  = sum_up_in;
	dut->eg_in		= eg_in;
	dut->arate		= arate;
	dut->drate		= drate;
	dut->rrate		= rrate;
	dut->sl			= sl;
	dut->en_sus		= en_sus;

	dut->keycode	= keycode;
	dut->eg_cnt		= eg_cnt;
	dut->cnt_in		= cnt_in;
	dut->ksr			= ksr;
	
	dut->lfo_mod	= lfo_mod;
	dut->amsen		= amsen;
	dut->ams		= ams;
	dut->tl			= tl;
}

void Stim::get(Vtest* dut) {
	state_next	= dut->state_next;
	pg_rst		= dut->pg_rst;
	cnt_lsb		= dut->cnt_lsb;
	pure_eg_out	= dut->pure_eg_out;
	eg_out		= dut->eg_out;
	sum_up_out  = dut->sum_up_out;
}

void Stim::next(Vtest* dut) {
	read_line();
	apply(dut);
	dut->eval();
	main_time+=20000; // zero period=20us = 4*18*1/3.6MHz
	get(dut);
	state_in  = state_next;
	eg_in     = pure_eg_out;
	cnt_in    = cnt_lsb;
	sum_up_in = sum_up_out;
	eg_cnt++;
	lfo_mod++;
	if( wait_count>0 ) wait_count--;
}

void Stim::open(const char *filename ) {
	line_cnt = 0;
	file.open(filename);
}

void remove_blanks( char*& str ) {
	while( *str!=0 && (*str==' ' || *str=='\t') ) str++;
}

void Stim::read_line() {
	while( !file.eof() && file.good() && wait_count==0) {
		char line[256]="";
		char *noblanks;
		do{
			file.getline(line,128);
			line_cnt++;
			//cout << line_cnt << '\n';
			noblanks = line;
			remove_blanks(noblanks);
		} while( (noblanks[0]=='#' || strlen(line)==0) && !file.eof()  );
		char cmd[256];
		int value;
		if( sscanf( noblanks, "%[a-z_12] = %x", cmd, &value ) != 2 ) {
			if( strcmp(cmd,"reset")==0	) { reset(); continue; }
			cout << "ERROR: Incomplete line " << line_cnt << "\n\t" << noblanks << '\n';
			throw 1;
		}
		while( true ) {
			if( strcmp(cmd,"keyon")==0 	) { keyon_now = value; break; }
			if( strcmp(cmd,"keyoff")==0	) { keyoff_now = value; break; }
			if( strcmp(cmd,"state")==0	) { state_in = value; break; }
			if( strcmp(cmd,"eg")==0		) { eg_in = value; break; }
			if( strcmp(cmd,"arate")==0	) { arate = value; break; }
			if( strcmp(cmd,"drate")==0	) { drate = value; break; }
			if( strcmp(cmd,"rrate")==0	) { rrate = value; break; }
			if( strcmp(cmd,"sl")==0		) { sl = value; break; }
			if( strcmp(cmd,"keycode")==0) { keycode = value; break; }
			if( strcmp(cmd,"eg_cnt")==0	) { eg_cnt = value; break; }
			if( strcmp(cmd,"cnt_in")==0	) { cnt_in = value; break; }
			if( strcmp(cmd,"ksr")==0		) { ksr = value; break; }
			if( strcmp(cmd,"lfo_mod")==0) { lfo_mod = value; break; }
			if( strcmp(cmd,"amsen")==0	) { amsen = value; break; }
			if( strcmp(cmd,"ams")==0	) { ams = value; break; }
			if( strcmp(cmd,"tl")==0		) { tl = value; break; }
			if( strcmp(cmd,"wait")==0	) { wait_count = value; break; }			
			cout << "ERROR: Unknown command '" << cmd << "'\n";
			throw 2;
		}
	}
}