# Variables:
#     tool        - R_toolExe
#     bundle      - bundle name
#     dir         - bundle directory inside bundles
#     compiledDir - bundle directory inside cache/compiled

function(parseResConfFile)
    file(STRINGS "${resConfFile}" resConf)

    set(rootTagFound FALSE)
    set(confResources "")
    set(confFiles "")

    foreach(elem IN LISTS resConf)
        string(REGEX MATCH "^ +" tab "${elem}")
        string(LENGTH "${tab}" tabLen)

        if(${tabLen} EQUAL 0) # root tag
            string(REGEX MATCH "^ *(.+)\\:$" _ "${elem}")
            set(key "${CMAKE_MATCH_1}")

            if("${key}" STREQUAL "indices")
                set(rootTagFound TRUE)
            elseif(${rootTagFound})
                break()
            endif()
        elseif((${tabLen} EQUAL 2) AND ${rootTagFound}) # index entry
            string(REGEX MATCH "^ *(.+)\\: (.+)$" _ "${elem}")
            set(key "${CMAKE_MATCH_1}")
            set(val "${CMAKE_MATCH_2}")

            list(APPEND confResources "${key}")
            list(APPEND confFiles "${val}")
        elseif(${rootTagFound})
            message(FATAL_ERROR "Indices should only contain indexe entries.")
            return()
        endif()
    endforeach()

    set(confResources "${confResources}" PARENT_SCOPE)
    set(confFiles "${confFiles}" PARENT_SCOPE)
endfunction()

function(parseResListFile)
    file(STRINGS "${resListFile}" resList)

    set(rootTagFound FALSE)
    set(resResources "")
    set(resVariables "")
    set(resBinVariables "")

    foreach(elem IN LISTS resList)
        string(REGEX MATCH "^ +" tab "${elem}")
        string(LENGTH "${tab}" tabLen)

        if(${tabLen} EQUAL 0) # root tag
            string(REGEX MATCH "^ *(.+)\\:$" _ "${elem}")
            set(key "${CMAKE_MATCH_1}")

            if("${key}" STREQUAL "resources")
                set(rootTagFound TRUE)
                set(resource "")
                set(variable "")
                set(binVariable "")
            else()
                message(FATAL_ERROR "Resources list file should only contain 'resources' root tag.\nIn: '${elem}'")
                return()
            endif()
        else() # everything else
            if(NOT ${rootTagFound})
                message(FATAL_ERROR "No 'resources' tag specified.")
                return()
            endif()

            if(${tabLen} EQUAL 2) # resource name
                if(NOT "${resource}" STREQUAL "")
                    if(("${variable}" STREQUAL "") OR ("${binVariable}" STREQUAL ""))
                        message(FATAL_ERROR
                            "Both variable and binaryVariable shold be specified for a resource.")
                        return()
                    endif()

                    list(APPEND resResources "${resource}")
                    list(APPEND resVariables "${variable}")
                    list(APPEND resBinVariables "${binVariable}")
                endif()

                string(REGEX MATCH "^ *(.+)\\:$" _ "${elem}")
                set(key "${CMAKE_MATCH_1}")
                set(resource "${key}")
            elseif(${tabLen} EQUAL 4) # resource variables
                if("${resource}" STREQUAL "")
                    message(FATAL_ERROR "Resource variables can only be defined for resources.")
                    return()
                endif()

                string(REGEX MATCH "^ *(.+)\\: (.+)$" _ "${elem}")
                set(key "${CMAKE_MATCH_1}")
                set(val "${CMAKE_MATCH_2}")

                if ("${key}" STREQUAL "variable")
                    set(variable "${val}")
                elseif ("${key}" STREQUAL "binaryVaraible")
                    set(binVariable "${val}")
                else()
                    message(FATAL_ERROR "Unknow resource parameter '${key}'.")
                    return()
                endif()
            else() # unknown case
                message(FATAL_ERROR "Unknow error while processing resource list.")
                return()
            endif()
        endif()
    endforeach()
    list(APPEND resResources "${resource}")
    list(APPEND resVariables "${variable}")
    list(APPEND resBinVariables "${binVariable}")
    
    set(resResources "${resResources}" PARENT_SCOPE)
    set(resVariables "${resVariables}" PARENT_SCOPE)
    set(resBinVariables "${resBinVariables}" PARENT_SCOPE)
endfunction()

function(parseCompiledListFile)
    if(NOT EXISTS "${compiledListFile}")
        file(TOUCH "${compiledListFile}")
    endif()
    file(STRINGS "${compiledListFile}" compiledList)

    set(compResources "")
    set(compTimestemps "")
    set(compFiles "")

    foreach(elem IN LISTS compiledList)
        string(REPLACE | ";" elem "${elem}")
        list(GET elem 0 resource)
        list(GET elem 1 timestemp)
        list(GET elem 2 file)

        list(APPEND compResources "${resource}")
        list(APPEND compTimestemps "${timestemp}")
        list(APPEND compFiles "${file}")
    endforeach()
    
    set(compResources "${compResources}" PARENT_SCOPE)
    set(compTimestemps "${compTimestemps}" PARENT_SCOPE)
    set(compFiles "${compFiles}" PARENT_SCOPE)
endfunction()

function(writeCompiledFile)
    set(compiledList "")

    list(LENGTH compResources compLen)
    math(EXPR compLen "${compLen} - 1")
    if(NOT ${compLen} EQUAL -1)
        foreach(i RANGE ${compLen})
            list(GET compResources ${i} resource)
            list(GET compTimestemps ${i} timestemp)
            list(GET compFiles ${i} file)

            string(APPEND compiledList "${resource}|${timestemp}|${file}\n")
        endforeach()
    endif()

    file(WRITE "${compiledListFile}" "${compiledList}")
endfunction()

if("${R_command}" STREQUAL "compile")
    set(resConfFile "${dir}/res.conf")
    parseResConfFile()

    set(resListFile "${dir}/res.list")
    parseResListFile()

    set(compiledListFile "${compiledDir}/compiled.list")
    parseCompiledListFile()

    list(LENGTH confResources crLen)
    list(LENGTH resResources rrLen)
    set(notSame FALSE)
    foreach(confRes IN LISTS confResources)
        list(FIND resResources "${confRes}" pos)
        if(${pos} EQUAL -1)
            set(notSame TRUE)
            break()
        endif()
    endforeach()
    if((NOT ${crLen} EQUAL ${rrLen}) OR ${notSame})
        message(FATAL_ERROR "Resource configuration and list files must have same resources.")
        return()
    endif()
    
    list(LENGTH compResources crLen)
    math(EXPR crLen "${crLen} - 1")
    if(NOT ${crLen} EQUAL -1)
        set(cpRFiltered "")
        set(cpTFiltered "")
        set(cpFFiltered "")

        foreach(i RANGE ${crLen})
            list(GET compResources ${i} compRes)
            list(GET compTimestemps ${i} compTime)
            list(GET compFiles ${i} compFile)

            list(FIND confResources "${compRes}" pos)
            if(NOT ${pos} EQUAL -1)
                list(GET confFiles ${pos} confFile)
                getFileTimestemp(timestemp "${confFile}")
                if(
                    (NOT ${timestemp} EQUAL ${compTime}) OR
                    (NOT EXISTS "${compFile}")
                )
                    file(REMOVE "${compFile}")
                else()
                    list(APPEND cpRFiltered "${compRes}")
                    list(APPEND cpTFiltered "${compTime}")
                    list(APPEND cpFFiltered "${compFile}")
                endif()
            else()
                file(REMOVE "${compFile}")
            endif()
        endforeach()

        set(compResources "${cpRFiltered}")
        set(compTimestemps "${cpTFiltered}")
        set(compFiles "${cpFFiltered}")       
    endif()

    set(newResListFile "${compiledDir}/res.list")
    set(newResList "resources:\n")
    set(compilationCount 0)
    list(LENGTH confResources crLen)
    math(EXPR crLen "${crLen} - 1")
    if(NOT ${crLen} EQUAL -1)
        foreach(confPos RANGE ${crLen})
            list(GET confResources ${confPos} confRes)
            list(GET confFiles ${confPos} confFile)

            list(FIND compResources "${confRes}" compPos)
            if(${compPos} EQUAL -1)
                math(EXPR compilationCount "${compilationCount} + 1")

                list(FIND resResources "${confRes}" resPos)
                list(GET resVariables ${resPos} resVar)
                list(GET resBinVariables ${resPos} resBinVar)

                getFileTimestemp(timestemp "${confFile}")

                list(APPEND compResources "${confRes}")
                list(APPEND compTimestemps "${timestemp}")
                list(APPEND compFiles "${compiledDir}/${resBinVar}.obj")
                string(APPEND newResList "  ${confRes}:\n")
                string(APPEND newResList "    variable: ${resVar}\n")
                string(APPEND newResList "    binaryVaraible: ${resBinVar}\n")
            endif()
        endforeach()

        if(${compilationCount} GREATER 0)
            message(STATUS "Compiling '${bundle}' bundle resources...")
            writeCompiledFile()
            file(WRITE "${newResListFile}" "${newResList}")
            execute_process(
                COMMAND ${tool}
                    gen obj
                    -in "${newResListFile}"
                    -conf "${resConfFile}"
                    -out-dir "${compiledDir}"
                WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
            )
            file(REMOVE "${newResListFile}")
            message(STATUS "'${bundle}' bundle resources compiled.")
        endif()
    endif()

    return()
endif()