# Variables
#     testsSrcDir    - direcory where tests are located
#     testsBinDir    - direcory where tests are run
#     testName       - name of the current test
#     cresScriptFile - CmakeResources script file
# 
# Cmake Variables
#     CMAKE_GENERATOR
#     CMAKE_CTEST_COMMAND

set(testDir "${testsBinDir}/${testName}")
if(EXISTS "${testDir}")
    file(REMOVE_RECURSE  "${testDir}")
endif()

file(COPY "${testsSrcDir}/${testName}" DESTINATION "${testsBinDir}")
file(COPY "${cresScriptFile}" DESTINATION "${testDir}")

execute_process(
    WORKING_DIRECTORY "${testDir}"
    COMMAND "${CMAKE_CTEST_COMMAND}"
        --build-and-test "${testDir}" "${testDir}/build"
        --build-generator "${CMAKE_GENERATOR}"
        --test-command "${CMAKE_CTEST_COMMAND}"
        -O "${testDir}/testOutput.txt"
)

file(READ "${testDir}/testOutput.txt" testOutput)
if(NOT "${testOutput}" MATCHES "100\\% tests passed\\, 0 tests failed")
    message(FATAL_ERROR "Some tests have failed.")
else()
    message(STATUS "All tests have passed.")
endif()