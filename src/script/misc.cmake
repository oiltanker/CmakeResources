function(getFileTimestemp var file)
    file(TIMESTAMP "${file}" result %s UTC) # file/directory modification timestemp in global time
    set(${var} ${result} PARENT_SCOPE)
endfunction()

function(decodePath var curDir path)
	string(REPLACE \\ / path "${path}")
    string(REPLACE \\ / curDir "${curDir}")
    
	string(FIND "${path}" ./ relCur1)
    string(FIND "${path}" ../ relPar1)
    string(FIND "${path}" . relCur2)
	string(FIND "${path}" .. relPar2)
	if(
        (${relCur1} EQUAL 0) OR
        (${relPar1} EQUAL 0) OR
        (${relCur2} EQUAL 0) OR
        (${relPar2} EQUAL 0)
    )
		SET(path "${curDir}/${path}")
    endif()
    
	string(FIND "${curDir}" / firstEnd)
	string(SUBSTRING "${curDir}" 0 ${firstEnd} first)
	file(RELATIVE_PATH path "${first}/" "${path}")
	set("${var}" "${first}/${path}" PARENT_SCOPE)
endfunction()

function(checkFilepath filepath)
    if("${filepath}" MATCHES "[|?*<\">;]")
        message(FATAL_ERROR
            "Filepath '${filepath}' in not valid."
            "\n\t- Filepath should not contain | ? * < \" > ; symbols"
        )
    endif()
endfunction()

function(checkFilename filename)
    if(${filename} MATCHES "[|\\?*<\":>/;]")
        message(FATAL_ERROR
            "Filename '${filename}' in not valid."
            "\n\t- Filename should not contain | \\ ? * < \" : > / ; symbols"
        )
    endif()
endfunction()

function(filterPaths var type oldPaths)
    set(newPaths "")

    if ("${type}" STREQUAL "DIRECTORIES")
        foreach(path IN LISTS oldPaths)
            if (IS_DIRECTORY "${path}")
                list(APPEND newPaths "${path}")
            endif()
        endforeach()
    elseif ("${type}" STREQUAL "FILES")
        foreach(path IN LISTS oldPaths)
            if (NOT IS_DIRECTORY "${path}")
                list(APPEND newPaths "${path}")
            endif()
        endforeach()
    else()
        message(FATAL_ERROR "Wrong path type for path filtering.")
        return()
    endif()

    set("${var}" "${newPaths}" PARENT_SCOPE)
endfunction()