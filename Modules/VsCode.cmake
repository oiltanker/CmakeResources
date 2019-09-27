set(CCppProperties "${CMAKE_SOURCE_DIR}/.vscode/c_cpp_properties.json")

if(EXISTS "${CCppProperties}")
    file(STRINGS "${CCppProperties}" lines ENCODING UTF-8 NEWLINE_CONSUME)

    set(needed "")
    foreach(dir IN LISTS CONAN_INCLUDE_DIRS)
        string(FIND "${file_str}" "${dir}" pos)
        if(${pos} GREATER -1)
            list(APPEND needed "${dir}")
        endif()
    endforeach()
    list(LENGTH needed neededCount)

    set(file_str ${lines})
    if(
        (${neededCount} GREATER 0) AND
        ("${file_str}" MATCHES "\"includePath\": \\[[^\n]*(\r?\n?[ \t]*)")
    )
        set(spacer ${CMAKE_MATCH_1})

        set(includes "")
        foreach(dir IN LISTS needed)
            string(APPEND includes "${spacer}\"${dir}\",")
        endforeach()

        string(REGEX REPLACE "(\"includePath\": \\[[^\n]*)" "\\1@includes@" new_str "${file_str}")
        string(CONFIGURE "${new_str}" new_str @ONLY)
        message(STATUS "${new_str}")
        # file(WRITE "${CCppProperties}" "${new_str}")
    endif()
endif()