find_file(cresSources
    NAMES
        manager.cpp
        parser.cpp
    PATHS "${SOURCES_DIR}")
add_library(cres SHARED ${cresSources})
target_setup_conan(cres
    INCLUDES PUBLIC ${CONAN_INCLUDE_DIRS}
    COMP_DEFS PUBLIC ${CONAN_DEFINES}
    LIBRARIES PUBLIC ${CONAN_LIBS}
    BIN_DIRS PUBLIC ${CONAN_BIN_DIRS})
target_include_directories(cres PUBLIC "${INCLUDES_DIR}" ${CONAN_INCLUDE_DIRS})

find_file(cliSources
    NAMES
        main.cpp
    PATHS "${CMAKE_CURRENT_SOURCE_DIR}")
add_executable(cres-cli ${cliSources})
target_link_libraries(cres-cli PRIVATE cres)