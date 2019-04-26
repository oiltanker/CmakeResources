cmake_minimum_required(VERSION 3.14)

project(simple VERSION 1.0.0)

include("${CMAKE_SOURCE_DIR}/CmakeResources.cmake")

add_executable(simple "${CMAKE_SOURCE_DIR}/src/main.cpp")
set_target_properties(simple PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/bin"
)
indexResources()
assignBundle(TARGET simple BUNDLE bundle)

# TODO: create custom cmake script, because fuck it
enable_testing()
ADD_TEST(
    NAME produceOutput
    COMMAND "${CMAKE_SOURCE_DIR}/bin/simple"
        "${CMAKE_SOURCE_DIR}/output.txt"
)
ADD_TEST(
    NAME outputCompare
    COMMAND "${CMAKE_COMMAND}" -E compare_files
        --ignore-eol
        "${CMAKE_SOURCE_DIR}/output.txt"
        "${CMAKE_SOURCE_DIR}/expectedOutput.txt"
)