// Version @R_version@
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
#include <mutex>

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
            case YVType::none:
                return *this;
            default:
                throw "Unknown YVType.";
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

bool tryRemove(const char* filepath) {
    bool result = false;
    for(int i = 0; (i < 3) && !result; i++) {
        result = remove(filepath) == 0;
        if(!result) {
            ifstream is(filepath);
            result = !is.good();
            is.close();
        }
    }
    return result;
}
mutex removeLock;
bool removeInThread(const char* filepath) {
    removeLock.lock();
    bool result = tryRemove(filepath);
    removeLock.unlock();
    return result;
}

mutex systemLock;
int systemInThread(const char* cmd) {
    systemLock.lock();
    int result = system(cmd);
    systemLock.unlock();
    return result;
}

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
    if (systemInThread(command.c_str()) != 0) {
        cerr << "Error while compiling resource:\n    CMD: " << command << ".\n";
        err = true;
    }
    if (!removeInThread(task.source.c_str())) {
        cerr << "Error removing resource source '" << task.source << "'.\n";
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
            tryRemove(tasks[i].object.c_str());
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
                source_file << ",\n";
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
                if (!tryRemove(file.c_str())) err = true;
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