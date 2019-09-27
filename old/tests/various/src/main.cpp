#include "resources.h"

#include <iostream>
#include <string>
#include <fstream>

using namespace std;
using namespace rc;

void printAsString(ofstream& outFile, const Resource& rc) {
    char buf[1025];
    size_t curPos = 0;
    for (size_t i = 0; i < rc.size; i++) {
        for (curPos = 0; (curPos < 1024) && (i < rc.size); curPos++, i++) {
            buf[curPos] = ((const char*)rc.begin)[i];
        }
        buf[curPos] = '\0';
        outFile << buf;
    }
    outFile << "\n";
}

int main(int argc, char** argv) {
    ofstream outFile;
    if (argc >= 2) {
        outFile.open(argv[1]);
    } else {
        cerr << "No output file specified.\n";
        return 1;
    }

    const Resource& r01 = R.bundle.f1._01_txt;
    const Resource& r02 = R.bundle.f1._02_txt;
    const Resource& r03 = R.bundle.f1._03_txt;
    const Resource& r04 = R.bundle.f1._04_txt;
    const Resource& r05 = R.bundle.f2._05_txt;
    const Resource& r06 = R.bundle.f2._06_txt;
    const Resource& r07 = R.bundle.f2.f21._07_txt;
    const Resource& r08 = R.bundle.f2.f21._08_txt;
    const Resource& r09 = R.bundle.f2.f22._09_txt;
    const Resource& r10 = R.bundle.f2.f22._10_txt;

    outFile << "RES: 'R.bundle.f1._01_txt':\n";
    printAsString(outFile, r01);
    outFile << "RES: 'R.bundle.f1._02_txt':\n";
    printAsString(outFile, r02);
    outFile << "RES: 'R.bundle.f1._03_txt':\n";
    printAsString(outFile, r03);
    outFile << "RES: 'R.bundle.f1._04_txt':\n";
    printAsString(outFile, r04);
    outFile << "RES: 'R.bundle.f2._05_txt':\n";
    printAsString(outFile, r05);
    outFile << "RES: 'R.bundle.f2._06_txt':\n";
    printAsString(outFile, r06);
    outFile << "RES: 'R.bundle.f2.f21._07_txt':\n";
    printAsString(outFile, r07);
    outFile << "RES: 'R.bundle.f2.f21._08_txt':\n";
    printAsString(outFile, r08);
    outFile << "RES: 'R.bundle.f2.f22._09_txt':\n";
    printAsString(outFile, r09);
    outFile << "RES: 'R.bundle.f2.f22._10_txt':\n";
    printAsString(outFile, r10);

    return 0;
}