#ifndef __FEATUREUSE_H
#define __FEATUREUSE_H

#include <cstring>
#include <iostream>

class FeatureUse {
	bool used;
	char _name[11];
	char _regmask, _enable_mask, _regbase;
	bool (*check_use)(char);
public:
	FeatureUse( const char *name, char regmask, char regbase, char enable_mask, 
		bool (*check)(char) );
	bool is_used() const { return used; }
	const char *name() const { return _name; }
	void check( char cmd, char val );
};

FeatureUse::FeatureUse( const char *name, char regmask, char regbase, 
		char enable_mask, bool (*check)(char) ) {
	strncpy( _name, name, 10 );
	_name[10] = 0;
	_regmask = regmask;
	_regbase = regbase;
	_enable_mask = enable_mask;
	used=false;
	check_use = check;
}

void FeatureUse::check( char cmd, char val ) {
	cmd &= _regmask;
	if( cmd == _regbase ) {
		val &= _enable_mask;
		used=(*check_use)(val);
	}
	// std::cout << std::hex << ((int)cmd&0xff) << " vs " << ((int)_regbase&0xff) << '\n';
}

#endif