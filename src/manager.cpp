#include <manager.hpp>
#include <parser.hpp>

#include <iostream>

using namespace std;

CompileCommand::CompileCommand(const string& str) {
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

string CompileCommand::createFor(const string& src, const string& obj) const {
    if (parts.size() < 3) return "ERROR";
    if (src_first)
        return parts[0] + src + parts[1] + obj + parts[2];
    else
        return parts[0] + obj + parts[1] + src + parts[2];
}

bool Manager::openConfiguration(const std::string& filename) {
    // Yvalue yaml;
    // if (!processYamlFIle(filepath, yaml)) {
    //     cerr << "Error processing config file '" << filepath << "'. Cannot proceed.\n";
    //     return false;
    // }
    // if (yaml.type != YVType::root) {
    //     cerr << "Wrong configuration file.\n";
    //     return false;
    // }
    
    // Yroot& root = yaml.root;
    // Yvalue& version = root["version"];
    // Yvalue& namespace_ = root["namespace"];
    // Yvalue& compile_cmd = root["compileCommand"];
    // Yvalue& indices = root["indices"];

    // if (version.type != YVType::string) {
    //     cerr << "Config is missing or has wrong 'version' value.\n";
    //     return false;
    // }
    // if (namespace_.type != YVType::string) {
    //     cerr << "Config is missing or has wrong 'namespace' value.\n";
    //     return false;
    // }
    // if (compile_cmd.type != YVType::string) {
    //     cerr << "Config is missing or has wrong 'compileCommand' value.\n";
    //     return false;
    // }
    // if (indices.type != YVType::root) {
    //     cerr << "Config is missing or has wrong 'indices' value.\n";
    //     return false;
    // }

    // if (version.str != VERSION) {
    //     cerr << "Wrong configuration version. Cannot proceed.\n";
    //     return false;
    // }
    // CompileCommand compile;
    // try {
    //     compile = CompileCommand(compile_cmd.str);
    // } catch (exception e) {
    //     return false;
    // }

    // config.version = version.str;
    // config.namespace_ = namespace_.str;
    // config.compile_command = compile;
    // for (pair<const string, Yvalue>& pair: indices.root) {
    //     if (pair.second.type != YVType::string) {
    //         cerr << "Wrong resource value.\n";
    //         return false;
    //     }
    //     config.indices[pair.first] = pair.second.str;
    // }
    return false;
}
bool Manager::openResourceList(const std::string& filename) {
    return false;
}