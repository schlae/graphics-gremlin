#ifndef __WAVEWRITTER_H
#define __WAVEWRITTER_H

#include <fstream>
#include <string>

class WaveWritter {
    std::ofstream fsnd, fhex;
    std::string name;
    bool dump_hex;
    void Constructor(const char *filename, int sample_rate, bool hex );
public:
    WaveWritter(const char *filename, int sample_rate, bool hex ) {
        Constructor( filename, sample_rate, hex );
    }
    WaveWritter(const std::string &filename, int sample_rate, bool hex ) {
        Constructor( filename.c_str(), sample_rate, hex );
    }
    void write( int16_t *lr );
    ~WaveWritter();
};

#endif