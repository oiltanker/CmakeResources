# Variables
#     testsSrcDir    - direcory where tests are located
#     testsBinDir    - direcory where tests are run
#     testName       - name of the current test
#     cresScriptFile - CmakeResources script file
# 
# Cmake Variables
#     CMAKE_COMMAND
#     CMAKE_CTEST_COMMAND
#     CMAKE_GENERATOR
#     CMAKE_MAKE_PROGRAM
#     CMAKE_C_COMPILER
#     CMAKE_CXX_COMPILER

set(testDir "${testsBinDir}/${testName}")
if(EXISTS "${testDir}")
    file(REMOVE_RECURSE  "${testDir}")
endif()

file(COPY "${testsSrcDir}/${testName}" DESTINATION "${testsBinDir}")
file(COPY "${cresScriptFile}" DESTINATION "${testDir}")

# execute_process(
#     WORKING_DIRECTORY "${testDir}"
#     COMMAND "${CMAKE_COMMAND}"
#         -S "${testDir}"
#         -B "${testDir}/build"
#         -G "${CMAKE_GENERATOR}"
#         -D "CMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}"
#         -D "CMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
#         -D "CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
# )
execute_process(
    WORKING_DIRECTORY "${testDir}"
    COMMAND "${CMAKE_CTEST_COMMAND}"
        --build-and-test "${testDir}" "${testDir}/build"
        --build-generator "${CMAKE_GENERATOR}"
        -O "${testDir}/testOutput.txt"
        --build-options
            -D "CMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}"
            -D "CMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
            -D "CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
        --test-command "${CMAKE_CTEST_COMMAND}"
)

file(READ "${testDir}/testOutput.txt" testOutput)
if(NOT "${testOutput}" MATCHES "100\\% tests passed\\, 0 tests failed")
    message(FATAL_ERROR "Some tests have failed.")
else()
    message(STATUS "All tests have passed.")
endif()