# Variables:
#     CMAKE_MAJOR_VERSION - cmake executable major version
#     CMAKE_MINOR_VERSION - cmake executable minor version
#     R_version           - CmakeResources version
#     R_toolDir           - resources tool directory
#     R_toolSrc           - resources tool source code file
#     R_toolTarget        - resources tool cmake target name

cmake_minimum_required (VERSION @CMAKE_MAJOR_VERSION@.@CMAKE_MINOR_VERSION@)

project (R_toolProject VERSION @R_version@)

add_executable(@R_toolTarget@ "@R_toolSrc@")
set_target_properties(@R_toolTarget@ PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "@R_toolDir@/bin"
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED TRUE
)