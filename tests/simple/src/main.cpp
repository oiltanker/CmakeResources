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

    const Resource& r1 = R.bundle.f1.f1_1_txt;
    const Resource& r2 = R.bundle.f1.f1_2_txt;
    const Resource& r3 = R.bundle.f2.f21.f2_f21_1_txt;
    const Resource& r4 = R.bundle.f2.f22.f2_f22_1_txt;

    outFile << "RES: 'R.bundle.f1.f1_1_txt':\n";
    printAsString(outFile, r1);
    outFile << "RES: 'R.bundle.f1.f1_2_txt':\n";
    printAsString(outFile, r2);
    outFile << "RES: 'R.bundle.f2.f21.f2_f21_1_txt':\n";
    printAsString(outFile, r3);
    outFile << "RES: 'R.bundle.f2.f22.f2_f22_1_txt':\n";
    printAsString(outFile, r4);

    return 0;
}