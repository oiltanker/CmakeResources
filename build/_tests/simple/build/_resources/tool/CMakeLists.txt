# Variables:
#     CMAKE_MAJOR_VERSION - cmake executable major version
#     CMAKE_MINOR_VERSION - cmake executable minor version
#     R_version           - CmakeResources version
#     R_toolDir           - resources tool directory
#     R_toolSrc           - resources tool source code file
#     R_toolTarget        - resources tool cmake target name

cmake_minimum_required (VERSION 3.14)

project (R_toolProject VERSION 1.0.0)

add_executable(resbld "C:/Users/Oiltanker/Desktop/CmakeResources/build/_tests/simple/build/_resources/tool/src/resbld.cpp")
set_target_properties(resbld PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "C:/Users/Oiltanker/Desktop/CmakeResources/build/_tests/simple/build/_resources/tool/bin"
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED TRUE
)
