#ifndef ENCRYPTION_ENCRPYT_H
#define ENCRYPTION_ENCRPYT_H

#include "utils.hpp"

#include <iostream>
#include <map>
#include <vector>
#include <set>
#include <string>

class Encryptor {
	public:
		Encryptor();
		std::map<char, std::set<uint32_t>*> generateKeys();
		std::string encrypt(std::string&);
		void printKeyMap() const;

	private:
		RNG rng;
		std::map<char, std::set<uint32_t>*> keyMap;
};

#endif
