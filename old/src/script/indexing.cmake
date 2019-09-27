# Indexing functions
function(findAvailableResources)
    foreach(dir IN LISTS bundleDirs)
        decodePath(_dir "${bundleDir}" "${dir}")
        foreach(mask IN LISTS bundleMsks)
            string(PREPEND mask "${_dir}/")
            list(APPEND masks "${mask}")
        endforeach()
    endforeach()
    file(GLOB_RECURSE resources ${masks})

    list(APPEND bundleExls "ResourcesLists\\.txt")
    foreach(exclude IN LISTS bundleExls)
        list(FILTER resources EXCLUDE REGEX "${exclude}")
    endforeach()

    set(files "${resources}" PARENT_SCOPE)
endfunction()

function(getResName cxxName filepath)
    file(RELATIVE_PATH shortFilepath ${CMAKE_CURRENT_LIST_DIR} "${filepath}")

    string(REPLACE \\ / resName "${shortFilepath}")
    string(PREPEND resName R/)
    string(REGEX REPLACE "[^a-zA-Z0-9/]" _ resNameSimple "${resName}")
    string(REGEX REPLACE "/([0-9])" "/_\\1" resNameSimple "${resNameSimple}")

    set(${cxxName} ${resNameSimple} PARENT_SCOPE)
endfunction()

function(createResNames)
    foreach(file IN LISTS files)
        checkFilepath("${file}")
        get_filename_component(filename "${file}" NAME)
        checkFilename("${filename}")
        getResName(cxxName "${file}")
        list(APPEND cxxNames "${cxxName}")
    endforeach()
    set(cxxNames "${cxxNames}" PARENT_SCOPE)
endfunction()

function(processBundleFile)
    if(NOT EXISTS "${bundleDir}/${R_rcFileName}")
        message(FATAL_ERROR "Resource lists file for bundle '${bundle}' does not exist.")
        return()
    endif()

    file(STRINGS "${bundleDir}/${R_rcFileName}" bundleLists)

    set(bundleDirs "")
    set(bundleMsks "")
    set(bundleExls "")
    foreach(elem IN LISTS bundleLists)
        string(FIND "${elem}" "  " tab)
        if (NOT ${tab} EQUAL 0) # tag
            string(REGEX MATCH "^(.+)\\:$" _ "${elem}")
            set(key "${CMAKE_MATCH_1}")
            if("${key}" STREQUAL "directories")
                set(curList bundleDirs)
            elseif("${key}" STREQUAL "masks")
                set(curList bundleMsks)
            elseif("${key}" STREQUAL "excludes")
                set(curList bundleExls)
            else()
                message(FATAL_ERROR
                    "Unknown bundle parameter '${key}'\n\tFor bundle '${bundle}'"
                    "\n\tIn '${CMAKE_SOURCE_DIR}/${R_rcFileName}'.")
                return()
            endif()
        else() # values
            string(REGEX MATCH "^  (.+)$" _ "${elem}")
            set(val "${CMAKE_MATCH_1}")
            list(APPEND ${curList} "${val}")
        endif()
    endforeach()
    
    set(bundleDirs "${bundleDirs}" PARENT_SCOPE)
    set(bundleMsks "${bundleMsks}" PARENT_SCOPE)
    set(bundleExls "${bundleExls}" PARENT_SCOPE)
endfunction()

function(gerResVariables var binVar cxxName)
    string(FIND "${cxxName}" / pos REVERSE)
    math(EXPR pos "${pos} + 1")
    string(SUBSTRING "${cxxName}" ${pos} -1 _var)
    string(REPLACE / _ _binVar "${cxxName}")

    set(${var} ${_var} PARENT_SCOPE)
    set(${binVar} ${_binVar} PARENT_SCOPE)
endfunction()

function(updateCreateBundle)
    processBundleFile()
    findAvailableResources()
    createResNames()

    set(resourceDir "${R_bundleDir}/${bundle}")
    file(MAKE_DIRECTORY "${resourceDir}")
    file(MAKE_DIRECTORY "${resourceDir}/src")
    file(MAKE_DIRECTORY "${resourceDir}/include")
    file(MAKE_DIRECTORY "${R_compiledDir}/${bundle}")

    set(resourceConfFile "${resourceDir}/res.conf")
    set(resourceListFile "${resourceDir}/res.list")

    string(APPEND resList "resources:\n")
    set(outputs "")
    set(inputs "")
    list(LENGTH files resLen)
    math(EXPR resLen "${resLen} - 1")
    foreach(i RANGE 0 ${resLen})
        list(GET files ${i} file)
        list(GET cxxNames ${i} cxxName)
        string(APPEND INDICES "  ${cxxName}: ${file}\n")
        gerResVariables(var binVar "${cxxName}")
        string(APPEND resList "  ${cxxName}:\n    variable: ${var}\n    binaryVaraible: ${binVar}\n")
        list(APPEND outputs "${R_compiledDir}/${bundle}/${binVar}.obj")
        list(APPEND inputs "${file}")
    endforeach()
    
    file(READ "${R_bundleDir}/res_template.conf" conf)
    string(CONFIGURE "${conf}" conf @ONLY)

    set(anyChanges FALSE)
    if(EXISTS "${resourceConfFile}")
        file(READ "${resourceConfFile}" old)
        if(NOT "${old}" STREQUAL "${conf}")
            file(WRITE "${resourceConfFile}" "${conf}")
            set(anyChanges TRUE)
        endif()
    else()
        file(WRITE "${resourceConfFile}" "${conf}")
        set(anyChanges TRUE)
    endif()
    if(EXISTS "${resourceListFile}")
        file(READ "${resourceListFile}" old)
        if(NOT "${old}" STREQUAL "${resList}")
            file(WRITE "${resourceListFile}" "${resList}")
            set(anyChanges TRUE)
        endif()
    else()
        file(WRITE "${resourceListFile}" "${resList}")
        set(anyChanges TRUE)
    endif()

    if("${anyChanges}" OR (NOT EXISTS "${resourceDir}/include/resources.h"))
        message(STATUS "Generating includes for '${bundle}' bundle...")

        set(outLogFile "${resourceDir}/out.log")
        set(errLogFile "${resourceDir}/err.log")
        execute_process(
            COMMAND ${R_toolExe}
                gen lib
                -in "${resourceListFile}"
                -conf "${resourceConfFile}"
                -out-dir "${resourceDir}"
            WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
            OUTPUT_FILE "${outLogFile}"
            ERROR_FILE "${errLogFile}"
        )

        if(EXISTS "${errLogFile}")
            file(READ "${errLogFile}" errLog)
            if(NOT "${errLog}" STREQUAL "")
                message(FATAL_ERROR " Error generating includes:\n\n${errLog}")
                return()
            endif()
        endif()
        message(STATUS "Includes successfuly generated.")
        file(REMOVE "${outLogFile}" "${errLogFile}")
    endif()

    add_custom_command(
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT ${outputs}
        DEPENDS "${resourceConfFile}" "${resourceListFile}" ${inputs}
        COMMENT ""
        COMMAND ${CMAKE_COMMAND}
            -D "R_command=compile"
            -D "tool=${R_toolExe}"
            -D "bundle=${bundle}"
            -D "dir=${resourceDir}"
            -D "compiledDir=${R_compiledDir}/${bundle}"
            -P "${R_scriptFile}"
        VERBATIM
    )
    add_custom_target("R_${bundle}.compile" DEPENDS ${outputs})

    add_library("R_${bundle}" OBJECT 
        "${resourceDir}/include/resources.h"
        "${resourceDir}/src/resources.cpp")
    target_include_directories("R_${bundle}" PUBLIC "${resourceDir}/include")
    set_target_properties("R_${bundle}" PROPERTIES
        CXX_STANDARD 17
        CXX_STANDARD_REQUIRED YES
    )
    add_dependencies("R_${bundle}" "R_${bundle}.compile")
    foreach(output IN LISTS outputs)
        target_link_libraries("R_${bundle}" PRIVATE "${output}")
    endforeach()

    set_property(GLOBAL APPEND PROPERTY R_indexedBundles "${bundle}")
endfunction()

function(processMainLists)
    set(_bundles "")
    set(_bundleDirs "")
    set(_bundleDescs "")

    set(dirPresent FALSE)
    foreach(elem IN LISTS _mainLists)
        string(FIND "${elem}" "  " tab)
        if (NOT ${tab} EQUAL 0) # bundle name
            if ((NOT ${dirPresent}) AND (NOT "${bundleName}" STREQUAL ""))
                message(FATAL_ERROR "No direcoty specified for '${bundleName}' bundle.")
                return()
            else()
                list(APPEND _bundles "${bundleName}")
                list(APPEND _bundleDirs "${bundleDir}")
                list(APPEND _bundleDescs "${bundleDesc}")

                set(bundleName "")
                set(bundleDir "")
                set(bundleDesc "")
            endif()

            string(REGEX MATCH "^(.+)\\:$" _ "${elem}")
            set(bundleName "${CMAKE_MATCH_1}")
            if ("${bundleName}" STREQUAL "")
                message(FATAL_ERROR "Invalid bundle name syntax in: '${elem}'.")
                return()
            endif()
        else() #bundle parameters
            string(REGEX MATCH "^  (.+)\\: " _ "${elem}")
            set(key "${CMAKE_MATCH_1}")
            string(REGEX MATCH "\\: (.+)$" _ "${elem}")
            set(val "${CMAKE_MATCH_1}")

            if ("${key}" STREQUAL "")
                message(FATAL_ERROR "Invalid bundle parameter syntax in: '${elem}'.")
                return()
            elseif("${key}" STREQUAL "description")
                set(bundleDesc "${val}")
            elseif("${key}" STREQUAL "directory")
                set(dirPresent TRUE)
                checkFilepath("${val}")
                set(bundleDir "${val}")
                decodePath(bundleDir "${CMAKE_SOURCE_DIR}" "${bundleDir}")
            else()
                message(FATAL_ERROR "Unknown bundle parameter: '${key}'.")
                return()
            endif()
        endif()
    endforeach()

    list(APPEND _bundles "${bundleName}")
    list(APPEND _bundleDirs "${bundleDir}")
    list(APPEND _bundleDescs "${bundleDesc}")

    set(bundleName "")
    set(bundleDir "")
    set(bundleDesc "")

    set(_bundles "${_bundles}" PARENT_SCOPE)
    set(_bundleDirs "${_bundleDirs}" PARENT_SCOPE)
    set(_bundleDescs "${_bundleDescs}" PARENT_SCOPE)
endfunction()

function(indexResources)
    # Check if any work needed
    if (NOT EXISTS "${CMAKE_SOURCE_DIR}/${R_rcFileName}")
        message(WARNING "No 'ResourceLists.txt' file in project directory.")
        return()
    endif()

    # Obtain current state
    file(STRINGS "${CMAKE_SOURCE_DIR}/${R_rcFileName}" _mainLists)
    file(GLOB curBudles LIST_DIRECTORIES true RELATIVE "${R_bundleDir}" "${R_bundleDir}/*")

    # Process current state
    processMainLists()
    filterPaths(curBudles DIRECTORIES "${curBudles}")

    # Delete not needed bundles
    foreach(bundle IN LISTS curBudles)
        list(FIND _bundles "${bundle}" bundleFound)
        if (${bundleFound} EQUAL -1)
            file(REMOVE_RECURSE
                "${R_bundleDir}/${bundle}"
                "${R_compiledDir}/${bundle}")
            message(STATUS "Bundle '${bundle}' was removed as it is not longer needed.")
        endif()
    endforeach()

    # Create needed bundles
    file(READ "${R_bundleDir}/res_template.conf" _conf)
    list(LENGTH _bundles bundleCount)
    math(EXPR bundleCount "${bundleCount} - 1")
    foreach(i RANGE bundleCount)
        list(GET _bundles ${i} bundle)
        list(GET _bundleDirs ${i} bundleDir)
        list(GET _bundleDescs ${i} bundleDesc)
        updateCreateBundle()

        list(FIND curBudles "${bundle}" bundleFound)
        if (${bundleFound} EQUAL -1)
            message(STATUS "Bundle '${bundle}' created.")
        else()
            message(STATUS "Bundle '${bundle}' updated.")
        endif()
    endforeach()
endfunction()