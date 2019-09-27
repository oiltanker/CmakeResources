cmake_minimum_required(VERSION 3.15)
project(cres-tool VERSION 1.0.0)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/Modules")

include(ConanSetup)

set(INCLUDES_DIR "${CMAKE_CURRENT_SOURCE_DIR}/include")
set(SOURCES_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src")
add_subdirectory(src)