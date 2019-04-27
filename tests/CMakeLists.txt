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
            -D "CMAKE_GENERATOR=${CMAKE_GENERATOR}"
            -D "CMAKE_CTEST_COMMAND=${CMAKE_CTEST_COMMAND}"
            -P "./test.cmake"
    )
endfunction()

addProjectTest(simple)
addProjectTest(heavy)
addProjectTest(various)
set_tests_properties(
    simple heavy various
    PROPERTIES
        DEPENDS cresScript
)