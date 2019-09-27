include(TargetBuild)

set(conanProfile "${CMAKE_BINARY_DIR}/conan_local.profile")
set(conanCompilerId NOT_DETECTED)
set(conanCompilerVersion NOT_DETECTED)
set(conanRemotes "${CMAKE_SOURCE_DIR}/conanremotes.txt")

if(${CMAKE_CXX_COMPILER_ID} MATCHES GNU)
    set(conanCompilerId gcc)
    string(REGEX MATCH "^([0-9]\\.[0-9]).*$" _ "${CMAKE_CXX_COMPILER_VERSION}")
    set(conanCompilerVersion ${CMAKE_MATCH_1})
    set(stat_flags "-static -static-libstdc++ -static-libgcc")
    list(APPEND CMAKE_EXE_LINKER_FLAGS ${stat_flags})
    list(APPEND CMAKE_STATIC_LINKER_FLAGS ${stat_flags})
    list(APPEND CMAKE_SHARED_LINKER_FLAGS ${stat_flags})
    list(APPEND CMAKE_MODULE_LINKER_FLAGS ${stat_flags})
else()
    message(FATAL_ERROR "Failed to obtain compiler information.")
endif()

function(formatOutput var out err)
    string(REGEX REPLACE "\n" "\n> -- " out "${out}")
    string(REGEX REPLACE "\n" "\n> -- " err "${err}")

    string(LENGTH "${out}" out_len)
    if(${out_len} GREATER 0)
        set(out "> OUTPUT:\n> -- ${out}\n")
    else()
        set(out ">\n")
    endif()

    string(LENGTH "${err}" err_len)
    if(${err_len} GREATER 0)
        set(err ">\n> ERROR:\n> -- ${err}\n")
    else()
        set(err "")
    endif()

    set(${var} "${out}${err}" PARENT_SCOPE)
endfunction()

function(execute)
    cmake_parse_arguments("" "NO_STATUS" "ERROR;STATUS" "COMMAND" "${ARGN}")
    execute_process(
        COMMAND ${_COMMAND}
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        RESULT_VARIABLE res
        OUTPUT_VARIABLE out
        ERROR_VARIABLE err)
    formatOutput(log "${out}" "${err}")
    if(NOT "${res}" EQUAL 0)
        message(FATAL_ERROR "${_ERROR}:\n${log}")
    elseif(NOT ${_NO_STATUS})
        message(STATUS "${_STATUS}:\n${log}")
    endif()
endfunction()

if(NOT EXISTS "${conanProfile}")
    set(commands
        "conan profile new \"${conanProfile}\" --detect"
        "conan profile update \"env.C=${CMAKE_C_COMPILER}\" \"${conanProfile}\""
        "conan profile update \"env.CXX=${CMAKE_CXX_COMPILER}\" \"${conanProfile}\""
        "conan profile update \"settings.compiler=${conanCompilerId}\" \"${conanProfile}\""
        "conan profile update \"settings.compiler.version=${conanCompilerVersion}\" \"${conanProfile}\""
        "conan profile update \"settings.compiler.libcxx=libstdc++11\" \"${conanProfile}\""
        "conan profile update \"settings.cppstd=17\" \"${conanProfile}\"")
    foreach(cmd IN LISTS commands)
        separate_arguments(cmd NATIVE_COMMAND ${cmd})
        execute(
            COMMAND ${cmd}
            ERROR "Unable to create local conan profile"
            NO_STATUS)
    endforeach()
endif()

if(EXISTS "${conanRemotes}")
    file(STRINGS "${conanRemotes}" remotes ENCODING UTF-8)
    foreach(remote IN LISTS remotes)
        string(REPLACE " " ";" remote "${remote}")
        list(GET remote 0 name)
        list(GET remote 1 url)
        list(GET remote 2 checkSsl)

        message(STATUS "conan remote add -f \"${name}\" \"${url}\" \"${checkSsl}\"")
        execute(
            COMMAND conan remote add -f "${name}" "${url}" "${checkSsl}"
            ERROR "Unable to add conan repository"
            NO_STATUS)
    endforeach()
endif()

execute(
    COMMAND conan install "${CMAKE_SOURCE_DIR}" -pr "${conanProfile}" --build outdated
    ERROR "Unable to setup conan packages"
    STATUS "Conan installation output")

include("${CMAKE_BINARY_DIR}/conanbuildinfo.cmake")
conan_basic_setup()
include(VsCode)

function(target_setup_conan target)
    cmake_parse_arguments("" "" "" "INCLUDES;COMP_DEFS;LIBRARIES;BIN_DIRS" "${ARGN}")
    cmake_parse_arguments("" "" "" "INTERFACE;PUBLIC;PRIVATE" "${_INCLUDES}")
    target_include_directories(${target}
        INTERFACE ${_INTERFACE}
        PUBLIC ${_PUBLIC}
        PRIVATE ${_PRIVATE})
    cmake_parse_arguments("" "" "" "INTERFACE;PUBLIC;PRIVATE" "${_COMP_DEFS}")
    target_compile_definitions(${target}
        INTERFACE ${_INTERFACE}
        PUBLIC ${_PUBLIC}
        PRIVATE ${_PRIVATE})
    cmake_parse_arguments("" "" "" "INTERFACE;PUBLIC;PRIVATE" "${_LIBRARIES}")
    target_link_libraries(${target}
        INTERFACE ${_INTERFACE}
        PUBLIC ${_PUBLIC}
        PRIVATE ${_PRIVATE})
    copyPostBuild(${target}
        GLOBS "*.dll"
        FILES "${_BIN_DIRS}")
endfunction()