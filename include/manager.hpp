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

struct ManageException : public exception {
    const char* message = nullptr;
    ManageException(const char* message) {
        this->message = message;
    }

    const char* what () const throw () {
        return message;
    }
};

class Manager {
    public:
        void openConfiguration(const std::string& filename);
        void openResourceList(const std::string& filename);

    private:
        Config config;
};

#endif // MANAGER_HPP
