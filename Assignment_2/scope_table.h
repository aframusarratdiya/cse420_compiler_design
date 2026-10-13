#include "symbol_info.h"

class scope_table
{
private:
    int bucket_count;
    int unique_id;
    scope_table *parent_scope = NULL;
    vector<list<symbol_info *>> table;

    int hash_function(string name)
    {
        unsigned long long hash_val = 0;
        int prime = 37;
        for (size_t i = 0; i < name.length(); i++)
        {
            hash_val = hash_val * prime + (unsigned char)name[i];
        }
        return (int)(hash_val % (unsigned long long)bucket_count);
    }

public:
    scope_table()
    {
        bucket_count = 10;
        unique_id = 0;
        parent_scope = NULL;
        table.resize(bucket_count);
    }

    scope_table(int bucket_count, int unique_id, scope_table *parent_scope)
    {
        this->bucket_count = bucket_count;
        this->unique_id = unique_id;
        this->parent_scope = parent_scope;
        table.resize(bucket_count);
    }

    scope_table *get_parent_scope()
    {
        return parent_scope;
    }

    int get_unique_id()
    {
        return unique_id;
    }

    symbol_info *lookup_in_scope(symbol_info *symbol)
    {
        int idx = hash_function(symbol->getname());
        for (list<symbol_info *>::iterator it = table[idx].begin(); it != table[idx].end(); it++)
        {
            if ((*it)->getname() == symbol->getname())
                return *it;
        }
        return NULL;
    }

    symbol_info *lookup_in_scope(string name)
    {
        int idx = hash_function(name);
        for (list<symbol_info *>::iterator it = table[idx].begin(); it != table[idx].end(); it++)
        {
            if ((*it)->getname() == name)
                return *it;
        }
        return NULL;
    }

    bool insert_in_scope(symbol_info *symbol)
    {
        if (lookup_in_scope(symbol->getname()) != NULL)
            return false; // already present in this scope

        int idx = hash_function(symbol->getname());
        table[idx].push_back(symbol);
        return true;
    }

    bool delete_from_scope(symbol_info *symbol)
    {
        int idx = hash_function(symbol->getname());
        for (list<symbol_info *>::iterator it = table[idx].begin(); it != table[idx].end(); it++)
        {
            if ((*it)->getname() == symbol->getname())
            {
                delete (*it);
                table[idx].erase(it);
                return true;
            }
        }
        return false;
    }

    void print_scope_table(ofstream &outlog)
    {
        outlog << "ScopeTable # " << unique_id << endl;
        for (int i = 0; i < bucket_count; i++)
        {
            if (table[i].empty())
                continue;
            outlog << i << " --> ";
            bool first = true;
            for (list<symbol_info *>::iterator it = table[i].begin(); it != table[i].end(); it++)
            {
                if (!first) outlog << " ";
                outlog << (*it)->get_details_string();
                first = false;
            }
            outlog << endl;
        }
    }

    ~scope_table()
    {
        for (int i = 0; i < bucket_count; i++)
        {
            for (list<symbol_info *>::iterator it = table[i].begin(); it != table[i].end(); it++)
            {
                delete (*it);
            }
            table[i].clear();
        }
    }
};


