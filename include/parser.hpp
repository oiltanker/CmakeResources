#ifndef PARSER_HPP
#define PARSER_HPP

#include <string>
#include <map>
#include <vector>

#include <yaml-cpp/yaml.h>

typedef std::string Ykey;
struct Yvalue;
typedef std::map<std::string, Yvalue> Yroot;
enum class YVType { none, root, string, array };
struct Yvalue {
    YVType type;
    Yroot root;
    std::string str;
    std::vector<std::string> arr;

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
    Yvalue(const std::string& _str): type(YVType::string), str(_str) {};
    Yvalue(const char* _str): type(YVType::string), str(_str) {};
    Yvalue(const std::vector<std::string>& _arr): type(YVType::array), arr(_arr) {};

    ~Yvalue() {};
};

struct RTRes {
    std::string name;
    std::string binary_variable;
};
struct RTNode {
    std::string name;
    std::vector<RTRes> resources;
    std::vector<RTNode> categories;

    RTNode& operator[](const std::string& cat_name) {
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

#endif // PARSER_HPP