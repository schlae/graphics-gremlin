#include "opll.h"
#include <iostream>
#include <iomanip>

using namespace std;

int main() {
    opll_t fm;
    OPLL_Reset(&fm, opll_type_ym2413);
    int last=0;
    for( int k=0; k<1'000'000; k++ ) {
        int32_t buffer[2];
        if( last != fm.lfo_am_out ) {
            cout << setw(10) << k << " " << setw(4) << fm.lfo_am_counter 
                << " " << (int)fm.lfo_am_car << " DIR=" << (int)fm.lfo_am_dir
                << " " << (int)fm.lfo_am_out << '\n';
            last = fm.lfo_am_out;             
        }
        OPLL_Clock( &fm, buffer);
    }
}

