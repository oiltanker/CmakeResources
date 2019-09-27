#include "resources.h"

#include <iostream>
#include <fstream>
#include <algorithm>
#include <functional>
#include <string>

using namespace std;
using namespace rc;

void printAsHash(ofstream& outFile, const Resource& rc) {
    hash<string> str_hash;
    for (size_t i = 0; i < rc.size;) {
        size_t step = min(rc.size - i, 10240ULL);
        string str(((char*)rc.begin)[i], step);
        outFile << str_hash(str) << "\n";
        i += step;
    }
}

int main(int argc, char** argv) {
    ofstream outFile;
    if (argc >= 2) {
        outFile.open(argv[1]);
    } else {
        cerr << "No output file specified.\n";
        return 1;
    }

    const Resource& r1 = R.bundle._1and2._1_txt;
    const Resource& r2 = R.bundle._1and2._2_txt;
    const Resource& r3 = R.bundle._3and4._3_txt;
    const Resource& r4 = R.bundle._3and4._4._4_txt;

    outFile << "RES: 'R.bundle._1and2._1_txt':\n";
    printAsHash(outFile, r1);
    outFile << "RES: 'R.bundle._1and2._2_txt':\n";
    printAsHash(outFile, r2);
    outFile << "RES: 'R.bundle._3and4._3_txt':\n";
    printAsHash(outFile, r3);
    outFile << "RES: 'R.bundle._3and4._4._4_txt':\n";
    printAsHash(outFile, r4);

    return 0;
}