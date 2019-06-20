cmake_minimum_required(VERSION 3.14)

project(cmake_resources VERSION 1.0.0)

set(cresScriptFile "${CMAKE_SOURCE_DIR}/bin/CmakeResources.cmake")
file(GLOB_RECURSE files "${CMAKE_SOURCE_DIR}/src/*")
add_custom_command(
    OUTPUT "${cresScriptFile}"
    DEPENDS "${files}"
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/src"
    COMMENT "Building CmakeResources script..."
    COMMAND ${CMAKE_COMMAND}
        -D "outFile=${cresScriptFile}"
        -P "${CMAKE_SOURCE_DIR}/src/buildScript.cmake"
    VERBATIM
)
add_custom_target(cresScript ALL DEPENDS "${cresScriptFile}")

enable_testing()
add_subdirectory(tests)