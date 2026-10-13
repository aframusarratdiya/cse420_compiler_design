#include<bits/stdc++.h>
using namespace std;

enum SymbolKind
{
    KIND_UNDEFINED,
    KIND_VARIABLE,
    KIND_ARRAY,
    KIND_FUNCTION
};

class symbol_info
{
private:
    string name;
    string type;

    // Write necessary attributes to store what type of symbol it is (variable/array/function)
    // Write necessary attributes to store the type/return type of the symbol (int/float/void/...)
    // Write necessary attributes to store the parameters of a function
    // Write necessary attributes to store the array size if the symbol is an array
    SymbolKind symbol_kind = KIND_UNDEFINED;
    string data_type = "";
    int array_size = 0;
    vector<string> param_types;

    // ---- Added for Semantic Analysis (Lab 3) ----
    // Carries the *computed semantic value type* (int/float/void/error) of an
    // expression-producing AST node (factor, term, expression, etc.)
    // "error" is used as a sentinel so that we don't cascade extra error
    // messages once something has already been reported as wrong.
    string value_type = "int";

public:
    symbol_info(string name, string type)
    {
        this->name = name;
        this->type = type;
    }
    string get_name()
    {
        return name;
    }
    string get_type()
    {
        return type;
    }
    void set_name(string name)
    {
        this->name = name;
    }
    void set_type(string type)
    {
        this->type = type;
    }
    // Write necessary functions to set and get the attributes
    void set_symbol_kind(SymbolKind k) { symbol_kind = k; }
    SymbolKind get_symbol_kind() { return symbol_kind; }

    void set_data_type(string dt) { data_type = dt; }
    string get_data_type() { return data_type; }

    void set_array_size(int size) { array_size = size; }
    int get_array_size() { return array_size; }

    void set_param_types(vector<string> types) { param_types = types; }
    vector<string> get_param_types() { return param_types; }

    // ---- Added for Semantic Analysis (Lab 3) ----
    void set_value_type(string vt) { value_type = vt; }
    string get_value_type() { return value_type; }

    string get_details_string()
    {
        string s;
        if (symbol_kind == KIND_FUNCTION)
        {
            s = "< " + name + " : FUNCTION, Return Type : " + data_type + " , Parameters : (";
            for (size_t i = 0; i < param_types.size(); i++)
            {
               s += param_types[i];
               if (i + 1 < param_types.size()) s += ", ";
            }
            s += ") >";
          }
        else if (symbol_kind == KIND_ARRAY)
     {
            s = "< " + name + " : ARRAY, Type : " + data_type + " , Size : " + to_string(array_size) + " >";
     }
        else if (symbol_kind == KIND_VARIABLE)
        {
            s = "< " + name + " : VARIABLE, Type : " + data_type + " >";
         }
        else
        {
            s = "< " + name + " : " + type + " >";
         }
        return s;
    }
    string getname() { return get_name(); }
    string gettype() { return get_type(); }

    ~symbol_info()
    {
        // Write necessary code to deallocate memory, if necessary
    }
};
