# CMake generated Testfile for 
# Source directory: C:/Users/Oiltanker/Desktop/CmakeResources/build/_tests/simple
# Build directory: C:/Users/Oiltanker/Desktop/CmakeResources/build/_tests/simple/build
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(produceOutput "C:/Users/Oiltanker/Desktop/CmakeResources/build/_tests/simple/bin/simple" "C:/Users/Oiltanker/Desktop/CmakeResources/build/_tests/simple/output.txt")
set_tests_properties(produceOutput PROPERTIES  _BACKTRACE_TRIPLES "C:/Users/Oiltanker/Desktop/CmakeResources/build/_tests/simple/CMakeLists.txt;16;ADD_TEST;C:/Users/Oiltanker/Desktop/CmakeResources/build/_tests/simple/CMakeLists.txt;0;")
add_test(outputCompare "C:/Program Files/CMake/bin/cmake.exe" "-E" "compare_files" "--ignore-eol" "C:/Users/Oiltanker/Desktop/CmakeResources/build/_tests/simple/output.txt" "C:/Users/Oiltanker/Desktop/CmakeResources/build/_tests/simple/expectedOutput.txt")
set_tests_properties(outputCompare PROPERTIES  _BACKTRACE_TRIPLES "C:/Users/Oiltanker/Desktop/CmakeResources/build/_tests/simple/CMakeLists.txt;21;ADD_TEST;C:/Users/Oiltanker/Desktop/CmakeResources/build/_tests/simple/CMakeLists.txt;0;")
