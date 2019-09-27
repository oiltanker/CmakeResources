#ifndef MANAGER_HPP
#define MANAGER_HPP

#include <string>
#include <map>
#include <vector>

class CompileCommand {
public:
    CompileCommand() {}
    CompileCommand(const std::string& str);

    std::string createFor(const std::string& src, const std::string& obj) const;

private:
    bool src_first;
    std::vector<std::string> parts;
};

struct Config {
    std::string version;
    std::string namespace_;
    CompileCommand compile_command;
    std::map<std::string, std::string> indices;
};

class Manager {
    public:
        bool openConfiguration(const std::string& filename);
        bool openResourceList(const std::string& filename);

    private:
        Config config;
};

#endif // MANAGER_HPP
