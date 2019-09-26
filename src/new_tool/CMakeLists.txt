file(GLOB_RECURSE sources LIST_DIRECTORIES false
    "${CMAKE_CURRENT_LIST_DIR}/*.h"
    "${CMAKE_CURRENT_LIST_DIR}/*.c"
    "${CMAKE_CURRENT_LIST_DIR}/*.hpp"
    "${CMAKE_CURRENT_LIST_DIR}/*.cpp")

add_executable(cres "${sources}")
target_setup_conan(cres
    INCLUDES ${CONAN_INCLUDE_DIRS}
    COMP_DEFS ${CONAN_DEFINES}
    LIBRARIES ${CONAN_LIBS}
    BIN_DIRS ${CONAN_BIN_DIRS})
target_include_directories(cres PRIVATE "${CMAKE_CURRENT_LIST_DIR}/include")