set(testsSrcDir "${CMAKE_SOURCE_DIR}/tests")
set(testsBinDir "${CMAKE_BINARY_DIR}/_tests")
file(MAKE_DIRECTORY "${testsBinDir}")

function(addProjectTest projetName)
    add_test(
        NAME "${projetName}"
        WORKING_DIRECTORY "${testsSrcDir}"
        COMMAND "${CMAKE_COMMAND}"
            -D "testsSrcDir=${testsSrcDir}"
            -D "testsBinDir=${testsBinDir}"
            -D "testName=${projetName}"
            -D "cresScriptFile=${cresScriptFile}"

            -D "CMAKE_COMMAND=${CMAKE_COMMAND}"
            -D "CMAKE_CTEST_COMMAND=${CMAKE_CTEST_COMMAND}"
            -D "CMAKE_GENERATOR=${CMAKE_GENERATOR}"
            -D "CMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}"
            -D "CMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
            -D "CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}"

            -P "./test.cmake"
    )
    set_tests_properties( "${projetName}" PROPERTIES
        DEPENDS cresScript
    )
endfunction()

addProjectTest(simple)
addProjectTest(heavy)
addProjectTest(various)