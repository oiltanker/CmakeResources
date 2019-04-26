# Variables
#     outFile - file where write script contents to

# Functions
function(appendFile inFile)
    file(READ "${inFile}" tmp)
    file(APPEND "${outFile}" "${tmp}\n")
endfunction()

function(appendString str)
    file(APPEND "${outFile}" "${str}\n")
endfunction()

function(appendFileAsVar inFile varName)
    file(READ "${inFile}" tmp)
    set(var "set(\"${varName}\" [==[${tmp}\n]==])")
    file(APPEND "${outFile}" "${var}\n")
endfunction()

# Build script
file(WRITE "${outFile}" "")

appendFile("./script/info.cmake")

appendString("\n# Misc")
appendFile("./script/misc.cmake")

appendString("\n# Commands")
appendFile("./commands/commands.cmake")
appendFile("./commands/compile.cmake")

appendString("\n# Configuration")
appendFileAsVar("./tool/main.cpp" R_toolSource)
appendFileAsVar("./tool/CMakeLists.txt" R_toolCmake)
appendFileAsVar("./tool/cmds.txt" R_toolProjectCmds)
appendFileAsVar("./tool/res.conf" R_confTemplate)
appendFile("./script/config.cmake")

appendString("\n# Indexing")
appendFile("./script/indexing.cmake")
appendString("\n# Bundle")
appendFile("./script/bundle.cmake")

message(STATUS "Srcipt compilation complete.")