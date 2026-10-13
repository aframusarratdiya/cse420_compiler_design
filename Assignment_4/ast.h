#ifndef AST_H
#define AST_H

#include <iostream>
#include <vector>
#include <string>
#include <fstream>
#include <map>

using namespace std;

class ASTNode {
public:
    virtual ~ASTNode() {}
    virtual string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp, int& temp_count, int& label_count) const = 0;
};



class ExprNode : public ASTNode {
protected:
    string node_type; 
public:
    ExprNode(string type) : node_type(type) {}
    virtual string get_type() const { return node_type; }
};



class VarNode : public ExprNode {
private:
    string name;
    ExprNode* index; 

public:
    VarNode(string name, string type, ExprNode* idx = nullptr)
        : ExprNode(type), name(name), index(idx) {}
    
    ~VarNode() { if(index) delete index; }
    
    bool has_index() const { return index != nullptr; }
    
    string generate_index_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                              int& temp_count, int& label_count) const {
        // Evaluate the index expression and return the name/temp holding its value
        if (index) {
            return index->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        return "";
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string temp = "t" + to_string(temp_count++);
        if (has_index()) {
            
            string idx_val = generate_index_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << temp << " = " << name << "[" << idx_val << "]" << endl;
        } else {
            
            outcode << temp << " = " << name << endl;
        }
        return temp;
    }
    
    string get_name() const { return name; }
};



class ConstNode : public ExprNode {
private:
    string value;

public:
    ConstNode(string val, string type) : ExprNode(type), value(val) {}
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        
        string temp = "t" + to_string(temp_count++);
        outcode << temp << " = " << value << endl;
        return temp;
    }
};



class BinaryOpNode : public ExprNode {
private:
    string op;
    ExprNode* left;
    ExprNode* right;

public:
    BinaryOpNode(string op, ExprNode* left, ExprNode* right, string result_type)
        : ExprNode(result_type), op(op), left(left), right(right) {}
    
    ~BinaryOpNode() {
        delete left;
        delete right;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string left_val = left ? left->generate_code(outcode, symbol_to_temp, temp_count, label_count) : "";
        string right_val = right ? right->generate_code(outcode, symbol_to_temp, temp_count, label_count) : "";
        string temp = "t" + to_string(temp_count++);
        outcode << temp << " = " << left_val << " " << op << " " << right_val << endl;
        return temp;
    }
};



class UnaryOpNode : public ExprNode {
private:
    string op;
    ExprNode* expr;

public:
    UnaryOpNode(string op, ExprNode* expr, string result_type)
        : ExprNode(result_type), op(op), expr(expr) {}
    
    ~UnaryOpNode() { delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string val = expr ? expr->generate_code(outcode, symbol_to_temp, temp_count, label_count) : "";
        string temp = "t" + to_string(temp_count++);
        outcode << temp << " = " << op << val << endl;
        return temp;
    }
};



class AssignNode : public ExprNode {
private:
    VarNode* lhs;
    ExprNode* rhs;

public:
    AssignNode(VarNode* lhs, ExprNode* rhs, string result_type)
        : ExprNode(result_type), lhs(lhs), rhs(rhs) {}
    
    ~AssignNode() {
        delete lhs;
        delete rhs;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string rhs_val = rhs ? rhs->generate_code(outcode, symbol_to_temp, temp_count, label_count) : "";

        if (lhs && lhs->has_index()) {
            
            string idx_val = lhs->generate_index_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << lhs->get_name() << "[" << idx_val << "] = " << rhs_val << endl;
        } else if (lhs) {
    
            outcode << lhs->get_name() << " = " << rhs_val << endl;
        }

        return rhs_val;
    }
};



class StmtNode : public ASTNode {
public:
    virtual string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                                int& temp_count, int& label_count) const = 0;
};



class ExprStmtNode : public StmtNode {
private:
    ExprNode* expr;

public:
    ExprStmtNode(ExprNode* e) : expr(e) {}
    ~ExprStmtNode() { if(expr) delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        
        if (expr) {
            expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        return "";
    }
};



class BlockNode : public StmtNode {
private:
    vector<StmtNode*> statements;

public:
    ~BlockNode() {
        for (auto stmt : statements) {
            delete stmt;
        }
    }
    
    void add_statement(StmtNode* stmt) {
        if (stmt) statements.push_back(stmt);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        for (auto stmt : statements) {
            if (stmt) {
                stmt->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            }
        }
        return "";
    }
};



class IfNode : public StmtNode {
private:
    ExprNode* condition;
    StmtNode* then_block;
    StmtNode* else_block; 

public:
    IfNode(ExprNode* cond, StmtNode* then_stmt, StmtNode* else_stmt = nullptr)
        : condition(cond), then_block(then_stmt), else_block(else_stmt) {}
    
    ~IfNode() {
        delete condition;
        delete then_block;
        if (else_block) delete else_block;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string cond_val = condition ? condition->generate_code(outcode, symbol_to_temp, temp_count, label_count) : "";

        string Ltrue = "L" + to_string(label_count++);

        if (else_block) {
            string Lelse = "L" + to_string(label_count++);
            string Lend = "L" + to_string(label_count++);

            outcode << "if " << cond_val << " goto " << Ltrue << endl;
            outcode << "goto " << Lelse << endl;
            outcode << Ltrue << ":" << endl;
            if (then_block) then_block->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << "goto " << Lend << endl;
            outcode << Lelse << ":" << endl;
            else_block->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << Lend << ":" << endl;
        } else {
            string Lend = "L" + to_string(label_count++);

            outcode << "if " << cond_val << " goto " << Ltrue << endl;
            outcode << "goto " << Lend << endl;
            outcode << Ltrue << ":" << endl;
            if (then_block) then_block->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << Lend << ":" << endl;
        }

        return "";
    }
};



class WhileNode : public StmtNode {
private:
    ExprNode* condition;
    StmtNode* body;

public:
    WhileNode(ExprNode* cond, StmtNode* body_stmt)
        : condition(cond), body(body_stmt) {}
    
    ~WhileNode() {
        delete condition;
        delete body;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string Lstart = "L" + to_string(label_count++);
        string Ltrue = "L" + to_string(label_count++);
        string Lend = "L" + to_string(label_count++);

        outcode << Lstart << ":" << endl;
        string cond_val = condition ? condition->generate_code(outcode, symbol_to_temp, temp_count, label_count) : "";
        outcode << "if " << cond_val << " goto " << Ltrue << endl;
        outcode << "goto " << Lend << endl;
        outcode << Ltrue << ":" << endl;
        if (body) body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        outcode << "goto " << Lstart << endl;
        outcode << Lend << ":" << endl;

        return "";
    }
};



class ForNode : public StmtNode {
private:
    ExprNode* init;
    ExprNode* condition;
    ExprNode* update;
    StmtNode* body;

public:
    ForNode(ExprNode* init_expr, ExprNode* cond_expr, ExprNode* update_expr, StmtNode* body_stmt)
        : init(init_expr), condition(cond_expr), update(update_expr), body(body_stmt) {}
    
    ~ForNode() {
        if (init) delete init;
        if (condition) delete condition;
        if (update) delete update;
        delete body;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        
        if (init) init->generate_code(outcode, symbol_to_temp, temp_count, label_count);

        string Lstart = "L" + to_string(label_count++);
        string Ltrue = "L" + to_string(label_count++);
        string Lend = "L" + to_string(label_count++);

        outcode << Lstart << ":" << endl;

        if (condition) {
            string cond_val = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << "if " << cond_val << " goto " << Ltrue << endl;
            outcode << "goto " << Lend << endl;
            outcode << Ltrue << ":" << endl;
        }

        if (body) body->generate_code(outcode, symbol_to_temp, temp_count, label_count);

        
        if (update) update->generate_code(outcode, symbol_to_temp, temp_count, label_count);

        outcode << "goto " << Lstart << endl;
        outcode << Lend << ":" << endl;

        return "";
    }
};



class ReturnNode : public StmtNode {
private:
    ExprNode* expr;

public:
    ReturnNode(ExprNode* e) : expr(e) {}
    ~ReturnNode() { if (expr) delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        if (expr) {
            string val = expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << "return " << val << endl;
        } else {
            outcode << "return" << endl;
        }
        return "";
    }
};



class DeclNode : public StmtNode {
private:
    string type;
    vector<pair<string, int>> vars; 

public:
    DeclNode(string t) : type(t) {}
    
    void add_var(string name, int array_size = 0) {
        vars.push_back(make_pair(name, array_size));
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        
        for (const auto& v : vars) {
            if (v.second > 0) {
                outcode << "// Declaration: " << type << " " << v.first << "[" << v.second << "]" << endl;
            } else {
                outcode << "// Declaration: " << type << " " << v.first << endl;
            }
        }
        return "";
    }
    
    string get_type() const { return type; }
    const vector<pair<string, int>>& get_vars() const { return vars; }
};

// Function declaration node

class FuncDeclNode : public ASTNode {
private:
    string return_type;
    string name;
    vector<pair<string, string>> params; 
    BlockNode* body;

public:
    FuncDeclNode(string ret_type, string n) : return_type(ret_type), name(n), body(nullptr) {}
    ~FuncDeclNode() { if (body) delete body; }
    
    void add_param(string type, string name) {
        params.push_back(make_pair(type, name));
    }
    
    void set_body(BlockNode* b) {
        body = b;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        outcode << "// Function: " << return_type << " " << name << "(";
        for (size_t i = 0; i < params.size(); i++) {
            outcode << params[i].first << " " << params[i].second;
            if (i != params.size() - 1) outcode << ", ";
        }
        outcode << ")" << endl;

        if (body) {
            body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }

        return "";
    }
};

// Helper class for function arguments

class ArgumentsNode : public ASTNode {
private:
    vector<ExprNode*> args;

public:
    ~ArgumentsNode() {
        
    }
    
    void add_argument(ExprNode* arg) {
        if (arg) args.push_back(arg);
    }
    
    ExprNode* get_argument(int index) const {
        if (index >= 0 && index < args.size()) {
            return args[index];
        }
        return nullptr;
    }
    
    size_t size() const {
        return args.size();
    }
    
    const vector<ExprNode*>& get_arguments() const {
        return args;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        
        return "";
    }
};

// Function call node

class FuncCallNode : public ExprNode {
private:
    string func_name;
    vector<ExprNode*> arguments;

public:
    FuncCallNode(string name, string result_type)
        : ExprNode(result_type), func_name(name) {}
    
    ~FuncCallNode() {
        for (auto arg : arguments) {
            delete arg;
        }
    }
    
    void add_argument(ExprNode* arg) {
        if (arg) arguments.push_back(arg);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // Evaluate each argument and immediately push it as a param,
        // interleaved in the order the arguments appear
        for (auto arg : arguments) {
            string av = arg->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << "param " << av << endl;
        }

        if (node_type == "void") {
            outcode << "call " << func_name << ", " << arguments.size() << endl;
            return "";
        } else {
            string temp = "t" + to_string(temp_count++);
            outcode << temp << " = call " << func_name << ", " << arguments.size() << endl;
            return temp;
        }
    }
};

// Program node (root of AST)

class ProgramNode : public ASTNode {
private:
    vector<ASTNode*> units;

public:
    ~ProgramNode() {
        for (auto unit : units) {
            delete unit;
        }
    }
    
    void add_unit(ASTNode* unit) {
        if (unit) units.push_back(unit);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        for (auto unit : units) {
            if (unit) {
                unit->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            }
        }
        return "";
    }
};

#endif // AST_H
