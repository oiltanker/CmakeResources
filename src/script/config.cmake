# Variables:
#     R_toolSource      - resources tool source code file contents
#     R_toolCmake       - resources tool CMakeLists.txt file contents
#     R_toolProjectCmds - resources tool cmake project commands
#     R_confTemplate    - template bundle configuration

# Uncomment if developing tool source
# set(R_toolRecompile FALSE CACHE INTERNAL "Flag specifying if tool must be recompiled." FORCE)

# Configuration functions
set(R_scriptFile "${CMAKE_CURRENT_LIST_FILE}")

function(createConfigurationTemplate)
    string(REPLACE "<CMAKE_CXX_COMPILER>" "${CMAKE_CXX_COMPILER}"
        resCompileCmd "${CMAKE_CXX_COMPILE_OBJECT}")
    string(REPLACE "<DEFINES>" ""
        resCompileCmd "${resCompileCmd}")
    string(REPLACE "<INCLUDES>" ""
        resCompileCmd "${resCompileCmd}")
    string(REPLACE "<FLAGS>" "${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_RELEASE}"
        resCompileCmd "${resCompileCmd}")
    string(REPLACE "<OBJECT>" "<OBJ>"
        resCompileCmd "${resCompileCmd}")
    string(REPLACE "<SOURCE>" "<SRC>"
        resCompileCmd "${resCompileCmd}")
    
    set(namespace rc)

    string(CONFIGURE "${R_confTemplate}" template @ONLY)
    string(APPEND template "@INDICES@")
    file(WRITE "${R_bundleDir}/res_template.conf" "${template}")
endfunction()

if((NOT "${R_versionCheck}" STREQUAL "${R_version}") OR "${R_toolRecompile}")
    set(R_versionCheck ${R_version} CACHE INTERNAL "Resources version check" FORCE)
    set(R_rootDir "${CMAKE_BINARY_DIR}/_resources"
        CACHE INTERNAL "Resources root directory" FORCE)
    file(REMOVE_RECURSE "${R_rootDir}")
    file(MAKE_DIRECTORY "${R_rootDir}")

    set(R_rcFileName "ResourcesLists.txt"
        CACHE INTERNAL "Resource lists filename" FORCE)

    set(R_toolDir "${R_rootDir}/tool"
        CACHE INTERNAL "Resources tool directory" FORCE)
    set(R_toolSrc "${R_toolDir}/src/resbld.cpp"
        CACHE INTERNAL "Resources tool source code file" FORCE)
    set(R_toolExe "${R_toolDir}/bin/resbld"
        CACHE INTERNAL "Resources tool executable" FORCE)
    set(R_toolTarget "resbld"
        CACHE INTERNAL "Resources tool target" FORCE)
    file(MAKE_DIRECTORY "${R_toolDir}")
    file(MAKE_DIRECTORY "${R_toolDir}/src")
    file(MAKE_DIRECTORY "${R_toolDir}/bin")

    set(R_bundleDir "${R_rootDir}/bundle"
        CACHE INTERNAL "Resource bundles directory" FORCE)
    set(R_cacheDir "${R_rootDir}/cache"
        CACHE INTERNAL "Resource cache directory" FORCE)
    set(R_compiledDir "${R_cacheDir}/compiled"
        CACHE INTERNAL "Compiled resources directory" FORCE)
    file(MAKE_DIRECTORY "${R_bundleDir}")
    file(MAKE_DIRECTORY "${R_cacheDir}")
    file(MAKE_DIRECTORY "${R_compiledDir}")

    createConfigurationTemplate()
    
    # Tool source code
    string(CONFIGURE "${R_toolSource}" toolSource @ONLY)
    file(WRITE "${R_toolSrc}" "${toolSource}")

    #CMAKE_VERSION
    string(CONFIGURE "${R_toolCmake}" toolCmake @ONLY)
    file(WRITE "${R_toolDir}/CMakeLists.txt" "${toolCmake}")

    # Building tool
    set(confLogFile "${R_toolDir}/config.log")
    set(confErrFile "${R_toolDir}/configError.log")
    set(bldLogFile "${R_toolDir}/build.log")
    set(bldErrFile "${R_toolDir}/buildError.log")

    string(CONFIGURE "${R_toolProjectCmds}" commands @ONLY)
    file(WRITE "${R_toolDir}/commands.txt" "${commands}")

    message(STATUS "Configuring resource tool...")
    execute_process(
        COMMAND ${CMAKE_COMMAND} .
            -G "${CMAKE_GENERATOR}"
            -D "CMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}"
            -D "CMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
            -D "CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
            -B "${R_toolDir}/build"
        WORKING_DIRECTORY "${R_toolDir}"
        OUTPUT_FILE "${confLogFile}"
        ERROR_FILE "${confErrFile}"
    )
    message(STATUS "Building resource tool...")
    execute_process(
        COMMAND ${CMAKE_COMMAND}
            --build "${R_toolDir}/build"
            --config Release
        WORKING_DIRECTORY "${R_toolDir}"
        OUTPUT_FILE "${bldLogFile}"
        ERROR_FILE "${bldErrFile}"
    )

    set(errorOccured FALSE)
    if(EXISTS "${confErrFile}")
        file(READ "${confErrFile}" confErr)
        if(NOT "${confErr}" STREQUAL "")
            set(errorOccured TRUE)
            message(STATUS "Tool configuration error:\n\n${confErr}")
        endif()
    endif()
    if(EXISTS "${bldErrFile}")
        file(READ "${bldErrFile}" bldErr)
        if(NOT "${bldErr}" STREQUAL "")
            set(errorOccured TRUE)
            message(STATUS "Tool build error:\n\n${bldErr}")
        endif()
    endif()

    if(NOT ${errorOccured})
        file(REMOVE "${confErrFile}")
        file(REMOVE "${bldErrFile}")
        message(STATUS "Tool creation successful.")
        set(R_toolRecompile FALSE CACHE INTERNAL "Flag specifying if tool must be recompiled." FORCE)
    else()
        message(FATAL_ERROR "Tool creation failed.")
        set(R_toolRecompile TRUE CACHE INTERNAL "Flag specifying if tool must be recompiled." FORCE)
    endif()
endif()