# CMake generated Testfile for 
# Source directory: C:/Users/Oiltanker/Desktop/CmakeResources/tests
# Build directory: C:/Users/Oiltanker/Desktop/CmakeResources/build/tests
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(simple "C:/Program Files/CMake/bin/cmake.exe" "-D" "testsSrcDir=C:/Users/Oiltanker/Desktop/CmakeResources/tests" "-D" "testsBinDir=C:/Users/Oiltanker/Desktop/CmakeResources/build/_tests" "-D" "testName=simple" "-D" "cresScriptFile=C:/Users/Oiltanker/Desktop/CmakeResources/bin/CmakeResources.cmake" "-D" "CMAKE_GENERATOR=MinGW Makefiles" "-D" "CMAKE_CTEST_COMMAND=C:/Program Files/CMake/bin/ctest.exe" "-P" "./test.cmake")
set_tests_properties(simple PROPERTIES  DEPENDS "cresScript" WORKING_DIRECTORY "C:/Users/Oiltanker/Desktop/CmakeResources/tests" _BACKTRACE_TRIPLES "C:/Users/Oiltanker/Desktop/CmakeResources/tests/CMakeLists.txt;6;add_test;C:/Users/Oiltanker/Desktop/CmakeResources/tests/CMakeLists.txt;20;addProjectTest;C:/Users/Oiltanker/Desktop/CmakeResources/tests/CMakeLists.txt;0;")
