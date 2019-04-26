# Resources manager (version 1.0.0)
#
# Usage:
#    TODO: write about usage.
# 
# TODO:
#     Consider supporting multiple bundles
set(R_version 1.0.0)

# Misc
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

# Commands
if(NOT "${R_command}" STREQUAL "")
    cmake_policy(SET CMP0054 NEW)
    cmake_policy(SET CMP0012 NEW)
endif()
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

# Configuration
set("R_toolSource" [==[// Version @R_version@
/*
 * This is a resource builder tool source file
 * Do not change as it is used to generate resources for other targets
 * If you change the source it will affect your project resources
 * 
 * Variables:
 *     R_version - CmakeResources version
 */
#define VERSION "@R_version@"

#include <vector>
#include <map>
#include <fstream>
#include <string>
#include <cmath>
#include <stack>
#include <cstdlib>
#include <thread>
#include <algorithm>

#include <iostream>
#include <cstdio>

#define BUF_SIZE 1048576
#define COLLS 16

using namespace std;

string generated_warning = R"(/*
 * This is a resource builder source file
 * Do not change as it is used to generate resources for other targets
 * If you change the source it will affect your project resources
 */
)";

enum class TaskType { none, remove, gen_obj, gen_include };
struct Task {
    TaskType type;

    string in_file;

    string out_file;
    string out_dir;

    string config_file;
    vector<string> remove_files;
};

class CompileCommand {
public:
    string createFor(const string& src, const string& obj) const {
        if (parts.size() < 3) return "ERROR";
        if (src_first)
            return parts[0] + src + parts[1] + obj + parts[2];
        else
            return parts[0] + obj + parts[1] + src + parts[2];
    }

    CompileCommand() {}
    CompileCommand(const string& str) {
        size_t src = str.find("<SRC>");
        size_t obj = str.find("<OBJ>");

        if (src == string::npos || obj == string::npos) {
            cerr << "Compile command misformed.\n";
            throw;
        }

        if (src < obj) {
            parts.push_back(str.substr(0, src));
            parts.push_back(str.substr(src + 5, obj - (src + 5)));
            parts.push_back(str.substr(obj + 5));
            src_first = true;
        } else {
            parts.push_back(str.substr(0, obj));
            parts.push_back(str.substr(obj + 5, src - (obj + 5)));
            parts.push_back(str.substr(src + 5));
            src_first = false;
        }
    }
private:
    bool src_first;
    vector<string> parts;
};

struct Config {
    string version;
    string namespace_;
    CompileCommand compile_command;
    map<string, string> indices;
};

struct ObjTask {
    string name;
    string file;
    string source;
    string object;
    string variable;
    string binary_variable;
};

enum class LineType { key, value, key_value, comment, empty };
struct Line {
    LineType type;
    int offset;
    vector<string> composition;
};

typedef string Ykey;
struct Yvalue;
typedef map<string, Yvalue> Yroot;
enum class YVType { none, root, string, array };
struct Yvalue {
    YVType type;
    Yroot root;
    string str;
    vector<string> arr;

    Yvalue& operator= (const Yvalue& val) {
        type = val.type;
        switch (type)
        {
            case YVType::root:
                root = val.root;
                return *this;
            case YVType::string:
                str = val.str;
                return *this;
            case YVType::array:
                arr = val.arr;
                return *this;
        }
    }

    Yvalue(): type(YVType::none) {};
    Yvalue(const Yroot& _root): type(YVType::root), root(_root) {};
    Yvalue(const string& _str): type(YVType::string), str(_str) {};
    Yvalue(const char* _str): type(YVType::string), str(_str) {};
    Yvalue(const vector<string>& _arr): type(YVType::array), arr(_arr) {};

    ~Yvalue() {};
};

struct RTRes {
    string name;
    string binary_variable;
};
struct RTNode {
    string name;
    vector<RTRes> resources;
    vector<RTNode> categories;

    RTNode& operator[](const string& cat_name) {
        for (auto iter = categories.begin(); iter != categories.end(); iter++) {
            if (iter->name == cat_name) return *iter;
            else if (iter->name > cat_name)
                return *categories.insert(iter, { cat_name });
        }
        categories.push_back({ cat_name });
        return categories.back();
    }
    void operator()(const RTRes& res) {
        for (auto iter = resources.begin(); iter != resources.end(); iter++) {
            if (iter->name > res.name) {
                resources.insert(iter, res);
                return;
            }
        }
        resources.push_back(res);
    }
};

bool processTask(const int argc, char** argv, Task& task) {
    if (argc < 2) {
        task.type = TaskType::none;
        return true;
    }

    string arg0 = argv[1];
    if (arg0 == "rm") {
        task.type = TaskType::remove;

        for (int i = 2; i < argc; i++) {
            string arg = argv[i];
            if (arg[0] == '-') {
                cerr << "Remove command takes no arguments apart from files.";
                return false;
            }
            task.remove_files.push_back(arg);
        }
    } else if (arg0 == "gen") {
        string arg1 = argv[2];
        if(arg1 == "obj") {
            task.type = TaskType::gen_obj;
            for (int i = 3; i < argc; i++) {
                string arg = argv[i];
                if (arg == "-in") {
                    i++;
                    task.in_file = argv[i];
                } else if (arg == "-out-dir") {
                    i++;
                    task.out_dir = argv[i];
                } else if (arg == "-conf") {
                    i++;
                    task.config_file = argv[i];
                } else {
                    cerr << "Wrong argument '" << arg << "'.";
                    return false;
                }
            }
        } else if(arg1 == "lib") {
            task.type = TaskType::gen_include;
            for (int i = 3; i < argc; i++) {
                string arg = argv[i];
                if (arg == "-in") {
                    i++;
                    task.in_file = argv[i];
                } else if (arg == "-out-dir") {
                    i++;
                    task.out_dir = argv[i];
                } else if (arg == "-conf") {
                    i++;
                    task.config_file = argv[i];
                } else {
                    cerr << "Wrong argument '" << arg << "'.";
                    return false;
                }
            }
        } else {
            cerr << "Unkown generation command '" << arg1 << "'.";
            return false;
        }
    } else {
        cerr << "Unkown command '" << arg0 << "'.";
        return false;
    }

    return true;
}

string cat(const Line& line) {
    if (line.composition.size() == 0) {
        return "";
    } else if (line.composition.size() == 1) {
        return line.composition[0];
    } else if (line.composition.size() == 2) {
        return line.composition[0] + ": " + line.composition[1];
    } else {
        return "Unkonw line format.\n";
    }
}
bool processValue(const string& value, string& result) {
    result = value;
    const size_t str_size = value.length();
    if (
        (result[0] == result[str_size - 1]) &&
        (result[0] == '\'' || result[0] == '"')
    )  result = result.substr(1, str_size - 2);
    return true;
}
bool parseLine(const int line_number, const string& str, Line& line) {
    // Count offset
    size_t i;
    for(i = 0; i < str.length() && str[i] == ' '; i++);
    line.offset = i / 2;
    // Crop and determine if line is a comment line
    if (i == str.length()) {
        line.type = LineType::empty;
        return true;
    } else if (str[i] == '#') {
        line.type = LineType::comment;
        return true;
    }
    string payload = str.substr(i);
    // Find comment and devider
    bool in_quotes = false;
    size_t devider = string::npos;
    char quote_type;
    for (i = 0; i < payload.length(); i++) {
        if (payload[i] == '\'' && (i == 0 || payload[i - 1] != '\\')) {
            if (in_quotes && quote_type == '\'')
                in_quotes ^= true;
            else {
                in_quotes ^= true;
                quote_type = '\'';
            }
        } else if (payload[i] == '"' && (i == 0 || payload[i - 1] != '\\')) {
            if (in_quotes && quote_type == '"')
                in_quotes ^= true;
            else {
                in_quotes ^= true;
                quote_type = '"';
            }
        } else if (!in_quotes && payload[i] == '#' && (i == 0 || payload[i - 1] == ' ')) break;
        else if (!in_quotes && payload[i] == ':') {
            if ((i == payload.length() - 1) || (payload[i + 1] == ' ')) {
                if (devider != string::npos) {
                    cerr << "Duplicate key at " << line_number << ":\n\t" << str << "\n";
                    return false;
                }
                devider = i;
            }
        }
    }
    if (in_quotes) {
        cerr << "Unclosed parentheses at " << line_number << ":\n\t" << str << "\n";
        return false;
    }
    payload = payload.substr(0, i);
    // Remove spaces on back
    for(i = payload.length() - 1; i >= 0  && str[i] == ' '; i--);
    if (i != payload.length() - 1) payload = payload.substr(0, i + 1);
    // Check line type
    if (devider == string::npos) {
        line.type = LineType::value;
        string result;
        if (!processValue(payload, result)) {
            cerr << "Invalid value at " << line_number << ":\n\t" << str << "\n";
            return false;
        }
        line.composition.push_back(result);
    } else {
        string key = payload.substr(0, devider);
        if (key.empty()) {
            cerr << "Key cannot be empty at " << line_number << ":\n\t" << str << "\n";
            return false;
        } else
            line.composition.push_back(key);
        if (devider == payload.length() - 1) {
            line.type = LineType::key;      
        } else {
            line.type = LineType::key_value;
            string result;
            if (!processValue(payload.substr(devider + 2), result)) {
                cerr << "Invalid value at " << line_number << ":\n\t" << str << "\n";
                return false;
            }
            line.composition.push_back(result);
        }
    }
    return true;
}
void printYaml(const Yvalue& root, const int offset = 0) {
    for(const pair<const string, Yvalue>& elem: root.root) {
        for(int i = 0; i < offset; i++) cout << "    ";
        cout << elem.first << ": ";
        if (elem.second.type == YVType::none) {
            cout << "\n";
        } else if (elem.second.type == YVType::string) {
            cout << elem.second.str << "\n";
        } else if (elem.second.type == YVType::array) {
            for(const string& str: elem.second.arr) {
                cout << "\n";
                for(int i = 0; i < offset; i++) cout << "    ";
                cout << "    " << str;
            }
            cout << "\n";
        } else if (elem.second.type == YVType::root) {
            cout << "\n";
            printYaml(elem.second.root, offset + 1);
        } 
    }
}
enum class YPState { none, root, value, array };
bool processYamlFIle(const string& filepath, Yvalue& yaml) {
    ifstream file(filepath);
    vector<string> strings;
    for (string line; getline(file, line); strings.push_back(line));
    file.close();
    
    vector<Line> lines;
    for (int i = 0; i < strings.size(); i++) {
        Line line;
        if (!parseLine(i, strings[i], line)) return false;
        else lines.push_back(line);
    }
    strings.clear();

    Ykey key;
    bool same_string = false;
    int offset = 0;

    YPState state = YPState::none;
    stack<Yvalue*> roots;
    roots.push(&yaml);

    for (int i = 0; i < lines.size(); i++) {
        const Line& line = lines[i];
        Yvalue& root = *roots.top();
        if(line.type == LineType::comment || line.type == LineType::empty) continue;

        switch (state) {
            case YPState::none: {
                if (line.type == LineType::key || line.type == LineType::key_value) {
                    root.type = YVType::root;
                    state = YPState::root;
                    i--;
                } else {
                    cerr << "Non key-value yaml root not supported.\n";
                    return false;
                }
                break;
            } case YPState::root: {
                if (line.offset < offset) {
                    i--;
                    for (; line.offset < offset; offset--, roots.pop());
                    continue;
                } else if (line.offset > offset) {
                    cerr << "Invalid line " << i << ":\n\t" << cat(line) << "'.\n";
                    return false;
                }

                key = line.composition[0];
                if (line.type == LineType::key_value) {
                    i--;
                    same_string = true;
                } else if (line.type == LineType::key) {
                    if (i == lines.size() - 1) {
                        root.root[key] = Yvalue();
                    }
                    offset++;
                    same_string = false;
                } else {
                    cerr << "Unknown Yaml line error.\n";
                    return false;
                }  
                state = YPState::value;
                break;
            } case YPState::value: {
                if (same_string) {
                    root.root[key] = Yvalue(line.composition[1]);
                    state = YPState::root;
                } else {
                    if (line.offset < offset) {
                        offset--;
                        for (; line.offset < offset; offset--, roots.pop());
                        state = YPState::root;
                        root.root[key] = Yvalue();
                        continue;
                    } else if (line.offset > offset) {
                        cerr << "Invalid line " << i << ":\n\t" << cat(line) << "'.\n";
                        return false;
                    }
                    if (line.type == LineType::value) {
                        i--;
                        state = YPState::array;
                    } else if (line.type == LineType::key || line.type == LineType::key_value) {
                        i--;
                        state = YPState::root;
                        Yvalue& newVal = root.root[key] = Yvalue(Yroot());
                        roots.push(&newVal);
                    } else {
                        cerr << "Invalid string " << i << ":\n\t" << cat(line) << "'.\n";
                        return false;
                    }
                }
                break;
            } case YPState::array: {
                vector<string> strings;
                for(; i < lines.size(); i++) {
                    const Line& line = lines[i];
                    if (line.offset < offset) {
                        i--;
                        for (; line.offset < offset; offset--, roots.pop());
                        root.root[key] = Yvalue(strings);
                        continue;
                    } else if (line.offset > offset) {
                        cerr << "Invalid line " << i << ":\n\t" << cat(line) << "'.\n";
                        return false;
                    }
                    if (line.type == LineType::value)
                        strings.push_back(line.composition[0]);
                    else {
                        cerr << "Array only accepts values at " << i << ":\n\t" << cat(line) << ".'\n";
                        return false;
                    }
                }
                root.root[key] = Yvalue(strings);
                break;
            } default:
                cerr << "Unkown parser state.\n";
                return false;
        }
    }

    return true;
}

bool processConfig(const string& filepath, Config& config) {
    Yvalue yaml;
    if (!processYamlFIle(filepath, yaml)) {
        cerr << "Error processing config file '" << filepath << "'. Cannot proceed.\n";
        return false;
    }
    if (yaml.type != YVType::root) {
        cerr << "Wrong configuration file.\n";
        return false;
    }
    
    Yroot& root = yaml.root;
    Yvalue& version = root["version"];
    Yvalue& namespace_ = root["namespace"];
    Yvalue& compile_cmd = root["compileCommand"];
    Yvalue& indices = root["indices"];

    if (version.type != YVType::string) {
        cerr << "Config is missing or has wrong 'version' value.\n";
        return false;
    }
    if (namespace_.type != YVType::string) {
        cerr << "Config is missing or has wrong 'namespace' value.\n";
        return false;
    }
    if (compile_cmd.type != YVType::string) {
        cerr << "Config is missing or has wrong 'compileCommand' value.\n";
        return false;
    }
    if (indices.type != YVType::root) {
        cerr << "Config is missing or has wrong 'indices' value.\n";
        return false;
    }

    if (version.str != VERSION) {
        cerr << "Wrong configuration version. Cannot proceed.\n";
        return false;
    }
    CompileCommand compile;
    try {
        compile = CompileCommand(compile_cmd.str);
    } catch (exception e) {
        return false;
    }

    config.version = version.str;
    config.namespace_ = namespace_.str;
    config.compile_command = compile;
    for (pair<const string, Yvalue>& pair: indices.root) {
        if (pair.second.type != YVType::string) {
            cerr << "Wrong resource value.\n";
            return false;
        }
        config.indices[pair.first] = pair.second.str;
    }

    return true;
}

bool loadResources(const Task& task, Yvalue& resources) {
    string filepath = task.in_file;
    Yvalue yaml;
    if (!processYamlFIle(filepath, yaml)) {
        cerr << "Error processing resources file '" << filepath << "'. Cannot proceed.\n";
        return false;
    }
    if (yaml.type != YVType::root) {
        cerr << "Wrong resource file.\n";
        return false;
    }

    Yroot& root = yaml.root;
    resources = root["resources"];
    if (resources.type != YVType::root && resources.type != YVType::none) {
        cerr << "Resources file is missing or has wrong 'resources' value.\n";
        return false;
    }
    return true;
}
bool processResources(const Config& config, const Task& task, vector<ObjTask>& tasks) {
    Yvalue resources;
    if (!loadResources(task, resources)) return false;
    if (resources.type == YVType::none) return true;
    for (pair<const string, Yvalue>& pair: resources.root) {
        if (
            pair.second.type != YVType::root ||
            (pair.second.root["variable"].type != YVType::string) ||
            (pair.second.root["binaryVaraible"].type != YVType::string)
        ) {
            cerr << "Wrong resource value.\n";
            return false;
        }
        string var = pair.second.root["variable"].str,
        binary_var = pair.second.root["binaryVaraible"].str;
        tasks.push_back({
            pair.first,
            config.indices.at(pair.first),
            task.out_dir + "/" + binary_var + ".cpp",
            task.out_dir + "/" + binary_var + ".obj",
            var,
            binary_var
        });
    }
    return true;
}

void generateResource(bool* result, const string& command, const string& namespace_, const ObjTask& task) {
    cout << "Generating '" << task.file << "' ...\n";

    ifstream in;
    ofstream out;
    in.open(task.file, ios::binary | ios::in);
    out.open(task.source, ios::out | ios::trunc);

    if (!in.is_open()) {
        cout << "Was unable to open resouce file.\n";
        *result = false; return;
    }
    else if (!out.is_open()) {
        cout << "Was unable to create intermediate source file.\n";
        *result = false; return;
    }
    in.seekg(0, ios::end);  
    size_t file_len = in.tellg(); 
    in.seekg(0, ios::beg);

    string tab = "    ";
    out << "namespace " << namespace_ << " {\n"
        << tab << "// Binary resource variables\n" << tab
        << "extern const unsigned long long _binary_" << task.binary_variable << "_size_"
        << " = " << file_len << ";\n" << tab
        << "extern const unsigned char _binary_" << task.binary_variable << "_begin_[]"
        << " = {\n";
    tab += "    ";

    string line = tab;
    size_t cur_col = 0;
    for (size_t i = 0; i < file_len; ) {
        const size_t part_size = file_len - i > BUF_SIZE ? BUF_SIZE : file_len - i;
        unsigned char part[part_size];
        in.read((char*)part, part_size);

        for (size_t j = 0; j < part_size; j++) {
            char hex_buf[5];
            sprintf(hex_buf,
                "0x%02x\0",
                part[j]
            );

            line += string(hex_buf) + ", ";
            cur_col++;

            if (cur_col == COLLS) {
                if (i + j >= file_len) {
                    line = line.substr(0, line.size() - 2);
                    out << line << "\n";
                } else
                    out << line << "\n";

                cur_col = 0;
                line = tab;
            }
        }
        i += part_size;
    }
    if (line != tab) {
        line = line.substr(0, line.size() - 2);
        out << line << "\n";
    }
    tab = tab.substr(0, tab.length() - 4);
    out << tab << "};\n"
        << "}\n\n";

    in.close(); out.close();

    bool err = false;
    if (system(command.c_str()) != 0) {
        cerr << "Error while compiling resource.\n";
        err = true;
    }
    if (remove(task.source.c_str()) != 0) {
        cerr << "Error removing resource source.\n";
        err = true;
    }
    *result = !err; return;
}
bool executeTasks(const Config& config, const vector<ObjTask>& tasks) {
    if (system(NULL) == 0) {
        cerr << "Connand processor is not available. Aborting.\n";
        return false;
    }
    vector<thread> threads;
    vector<bool*> results;
    for(const ObjTask& task: tasks) {
        string command = config.compile_command.createFor(task.source, task.object);
        results.push_back(new bool(true));
        threads.push_back(thread(generateResource, results.back(), command, config.namespace_, task));
    }
    for (thread& task_thread: threads) task_thread.join();
    bool result = true;
    for (size_t i = 0 ; i < results.size(); i++) {
        if(!*results[i]) {
            cout << "Generation of " << tasks[i].file << " failed.\n";
            remove(tasks[i].object.c_str());
            result = false;
        }
    }
    for (bool*& res_var: results) delete res_var;
    return result;
}

vector<string> spitName(const string& res_name) {
    vector<string> result;
    for(
        size_t find = res_name.find('/'), last_find = 0;
        find != string::npos;
        last_find = find + 1, find = res_name.find('/', last_find)
    ) result.push_back(res_name.substr(last_find, find - last_find));
    if (result.size() > 0) result.erase(result.begin());
    return result;
}
bool buildResourceTree(
    const vector<string>& names, const vector<string>& vars,
    const vector<string>& bin_vars, RTNode& root
) {
    if (names.size() > 0) {
        root.name = names[0].substr(0, names[0].find('/'));
        if (root.name.empty()) {
            cerr << "Root name cannot be empty.\n";
            return false;
        }
    }
    for(int i = 0; i < names.size(); i++) {
        if (names[i].find(root.name) != 0) {
            cerr << "All resources musk have same root.\n";
            return false;
        }
        vector<string> parts = spitName(names[i]);
        if (parts.size() == 0) {
            cerr << "Resource name must contain root category.\n";
            return false;
        }
        RTNode* cat = &root;
        for (const string& part: parts) cat = &(*cat)[part];
        if (vars[i].empty()) {
            cerr << "Reource name cannot be empty.\n";
            return false;
        }
        (*cat)({ vars[i], bin_vars[i] });
    }
    return true;
}
bool generateLibrarySource(const Task& task, const Config& config, const vector<ObjTask>& tasks) {
    cout << "Generating include...\n";
    vector<string> names, bin_vars, vars;
    for (const ObjTask& task: tasks) {
        names.push_back(task.name);
        vars.push_back(task.variable);
        bin_vars.push_back(task.binary_variable);
    }
    RTNode root;
    if (!buildResourceTree(names, vars, bin_vars, root)) return  false;

    ofstream include_file, source_file;
    include_file.open(task.out_dir + "/include/resources.h");
    source_file.open(task.out_dir + "/src/resources.cpp");
    if (!include_file.is_open()) {
        cerr << "Could not create resources header file.\n";
        return false;
    } else if (!source_file.is_open()) {
        cerr << "Could not create resources source file.\n";
        return false;
    }

    string inc_tab = "    ", src_tab = "    ";
    include_file << "//Version " << VERSION << "\n"
        << generated_warning << "\n"
        << "#ifndef _RESOURCES_H\n#define _RESOURCES_H\n\n"
        << "namespace " << config.namespace_ << " {\n"
        << inc_tab << "struct Resource {\n"
        << inc_tab << "    const void* begin;\n"
        << inc_tab << "    const unsigned long long size;\n\n"
        << inc_tab << "    Resource(const void* begin, const unsigned long long size);\n"
        << inc_tab << "};\n\n";
    
    source_file << "//Version " << VERSION << "\n"
        << generated_warning << "\n"
        << "#include \"resources.h\"\n\n"
        << "namespace " << config.namespace_ << " {\n"
        << src_tab << "Resource::Resource(const void* _begin, const unsigned long long _size):\n"
        << src_tab << "    begin(_begin), size(_size)\n"
        << src_tab << "{ };\n\n";
    source_file << src_tab << "// Binary resource variables\n";
    for (const string& str: bin_vars) {
        source_file << src_tab << "extern const unsigned long long _binary_" << str << "_size_;\n"
             << src_tab << "extern const unsigned char _binary_" << str << "_begin_[];\n\n";
    }

    vector<const RTNode*> cats; cats.push_back(&root);
    stack<int> res_ptr; res_ptr.push(-1);
    while(cats.size() > 0) {
        if (res_ptr.top() == -1) {
            include_file << inc_tab << "struct ";
            source_file << src_tab;
            if (cats.size() == 1) {
                include_file << "_ResourcesStructure";
                source_file << "const _ResourcesStructure " << cats.back()->name << " = ";
            }
            include_file << "{\n";
            source_file << "{\n";
            inc_tab += "    ";
            src_tab += "    ";
            for(const RTRes& res: cats.back()->resources) {
                include_file << inc_tab << "Resource " << res.name << ";\n";
                source_file << src_tab << "Resource("
                    << "&_binary_" << res.binary_variable << "_begin_, "
                    << "_binary_" << res.binary_variable << "_size_)";
                if (&res != &cats.back()->resources.back()) source_file << ",\n";
                else source_file << "\n";
            }
            res_ptr.top() = 0;
        } else if (res_ptr.top() == cats.back()->categories.size()) {
            inc_tab = inc_tab.substr(0, inc_tab.length() - 4);
            src_tab = src_tab.substr(0, src_tab.length() - 4);
            include_file << inc_tab << "} ";
            source_file << src_tab << "}";
            if (cats.size() == 1) {
                include_file << "extern const ";
                source_file << ";\n";
            } else {
                source_file << ",\n";
            }
            include_file << cats.back()->name << ";\n";
            res_ptr.pop();
            cats.pop_back();
        } else {
            cats.push_back(&cats.back()->categories[res_ptr.top()]);
            res_ptr.top() += 1;
            res_ptr.push(-1);
        }
    }
    include_file << "}\n\n#endif // _RESOURCES_H\n";
    source_file << "}\n";
    include_file.close(); source_file.close();

    return true;
}

int main(int argc, char** argv) {
    Task task;
    if (!processTask(argc, argv, task)) {
        return 1;
    }
    
    int result = 0;
    switch (task.type) {
        case TaskType::none:
            result = 0;
            break;
        case TaskType::remove: {
            bool err = false;
            for (string file: task.remove_files) {
                if (remove(file.c_str()) != 0)
                    err = true;
            }
            if (err) {
                cerr << "Was unable to delete all files.";
                result = 1;
            } else
                result = 0;
            break;
        } case TaskType::gen_obj: {
            Config config;
            vector<ObjTask> tasks;
            if (
                !processConfig(task.config_file, config) ||
                !processResources(config, task, tasks) ||
                !executeTasks(config, tasks)
            ) {
                result = 1;
            } else
                result = 0;
            break;
        } case TaskType::gen_include: {
            Config config;
            vector<ObjTask> tasks;
            if (
                !processConfig(task.config_file, config) ||
                !processResources(config, task, tasks) ||
                !generateLibrarySource(task, config, tasks)
            ) {
                result = 1;
            } else
                result = 0;
            break;
        }  default:
            break;
    }

    return result;
}
]==])
set("R_toolCmake" [==[# Variables:
#     CMAKE_MAJOR_VERSION - cmake executable major version
#     CMAKE_MINOR_VERSION - cmake executable minor version
#     R_version           - CmakeResources version
#     R_toolDir           - resources tool directory
#     R_toolSrc           - resources tool source code file
#     R_toolTarget        - resources tool cmake target name

cmake_minimum_required (VERSION @CMAKE_MAJOR_VERSION@.@CMAKE_MINOR_VERSION@)

project (R_toolProject VERSION @R_version@)

add_executable(@R_toolTarget@ "@R_toolSrc@")
set_target_properties(@R_toolTarget@ PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "@R_toolDir@/bin"
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED TRUE
)
]==])
set("R_toolProjectCmds" [==[commands:
  configure:
    @CMAKE_COMMAND@ .
        -G "@CMAKE_GENERATOR@"
        -D "CMAKE_C_COMPILER=@CMAKE_C_COMPILER@"
        -D "CMAKE_CXX_COMPILER=@CMAKE_CXX_COMPILER@"
        -B "@R_toolDir@/build"
  build:
    @CMAKE_COMMAND@
        --build "@R_toolDir@/build"
        --config Release
]==])
set("R_confTemplate" [==[version: @R_version@
namespace: @namespace@
compileCommand: @resCompileCmd@
indices:
]==])
# Variables:
#     R_toolSource      - resources tool source code file contents
#     R_toolCmake       - resources tool CMakeLists.txt file contents
#     R_toolProjectCmds - resources tool cmake project commands
#     R_confTemplate    - template bundle configuration

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

if(NOT "${R_versionCheck}" STREQUAL "${R_version}")
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
            message(SATUS "Tool configuration error:\n\n${confErr}")
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
    else()
        message(FATAL_ERROR "Tool creation failed.")
    endif()
endif()

# Indexing
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

    list(APPEND bundleExls "CMakeLists\\.txt;ResourcesLists\\.txt")
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

    if(${anyChanges} OR (NOT EXISTS "${resourceDir}/include/resources.h"))
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

# Bundle
function(assignBundle)
    cmake_parse_arguments("" "" "TARGET;BUNDLE" "" "${ARGN}")
    
    get_property(bundles GLOBAL PROPERTY R_indexedBundles)
    list(FIND bundles "${_BUNDLE}" pos)
    if(${pos} EQUAL -1)
        message(FATAL_ERROR "Bundle '${_BUNDLE}' does not exist.")
        return()
    endif()

    get_property(targetBundle TARGET "${_TARGET}" PROPERTY R_bundle)
    if(NOT "${targetBundle}" STREQUAL "")
        message(FATAL_ERROR "Target '${_TARGET}' is already assigned a bundle ('${targetBundle}').")
        return()
    else()
        set_property(TARGET "${_TARGET}" PROPERTY R_bundle "${_BUNDLE}")
    endif()
    
    target_link_libraries("${_TARGET}" "R_${_BUNDLE}")
endfunction()

