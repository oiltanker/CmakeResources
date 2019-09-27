cmake_minimum_required(VERSION 3.14)

project(various VERSION 1.0.0)

include("${CMAKE_SOURCE_DIR}/CmakeResources.cmake")

add_executable(various "${CMAKE_SOURCE_DIR}/src/main.cpp")
set_target_properties(various PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/bin"
)
indexResources()
assignBundle(TARGET various BUNDLE bundle)

enable_testing()
ADD_TEST(
    NAME produceOutput
    COMMAND "${CMAKE_SOURCE_DIR}/bin/various"
        "${CMAKE_SOURCE_DIR}/output.txt"
)
ADD_TEST(
    NAME outputCompare
    COMMAND "${CMAKE_COMMAND}" -E compare_files
        --ignore-eol
        "${CMAKE_SOURCE_DIR}/output.txt"
        "${CMAKE_SOURCE_DIR}/expectedOutput.txt"
)