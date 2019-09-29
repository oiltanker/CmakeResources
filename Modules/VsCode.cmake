set(CCppProperties "${CMAKE_SOURCE_DIR}/.vscode/c_cpp_properties.json")

if(EXISTS "${CCppProperties}")
    file(STRINGS "${CCppProperties}" lines ENCODING UTF-8 NEWLINE_CONSUME)
    set(file_str ${lines})

    set(needed "")
    foreach(dir IN LISTS CONAN_INCLUDE_DIRS)
        string(FIND "${file_str}" "\"${dir}\"" pos)
        if(${pos} EQUAL -1)
            list(APPEND needed "${dir}")
        endif()
    endforeach()
    list(LENGTH needed neededCount)

    set(writeNeeded false)
    if(
        (${neededCount} GREATER 0) AND
        ("${file_str}" MATCHES "\"includePath\": \\[[^\n]*(\r?\n?[ \t]*)")
    )
        set(spacer ${CMAKE_MATCH_1})

        set(includes "")
        foreach(dir IN LISTS needed)
            string(APPEND includes "${spacer}\"${dir}\",")
        endforeach()

        string(REGEX REPLACE "(\"includePath\": \\[[^\n]*)" "\\1@includes@" file_str "${file_str}")
        string(CONFIGURE "${file_str}" file_str @ONLY)
        set(writeNeeded true)
    endif()

    if(
        ("${CMAKE_HOST_SYSTEM_NAME}" STREQUAL Windows) AND
        ("${CMAKE_C_COMPILER_ID}" STREQUAL GNU) AND
        ("${file_str}" MATCHES "\"intelliSenseMode\": \"([^\n]*)\"") AND
        (NOT "${CMAKE_MATCH_1}" STREQUAL "gcc-x64")
    )
        string(REGEX REPLACE "(\"intelliSenseMode\": \")[^\n]*(\")" "\\1gcc-x64\\2" file_str "${file_str}")
        set(writeNeeded true)
    endif()

    if(
        ("${file_str}" MATCHES "\"configurationProvider\": \"([^\n]*)\"") AND
        (NOT "${CMAKE_MATCH_1}" STREQUAL "vector-of-bool.cmake-tools")
    )
        string(REGEX REPLACE "(\"configurationProvider\": \")[^\n]*(\")" "\\1vector-of-bool.cmake-tools\\2" file_str "${file_str}")
        set(writeNeeded true)
    endif()

    if(${writeNeeded})
        file(WRITE "${CCppProperties}" "${file_str}")
    endif()
endif()