#ifndef MANAGER_HPP
#define MANAGER_HPP

#include <string>
#include <map>
#include <vector>

class ManageException: public std::exception {
public:
    ManageException(const char* message);
    const char* what () const throw ();
private:
    const char* message = nullptr;
};

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
};
struct ResourceIndex {
    std::string bundle_name;
    std::string c_name;
    std::string cxx_name;
    std::string filename;

    ResourceIndex(std::string bundle_name, std::string root, std::string filename);
};

class Manager {
    public:
        void openConfiguration(const std::string& filename);
        void openResourceList(const std::string& filename);

    private:
        Config config;
};

#endif // MANAGER_HPP
