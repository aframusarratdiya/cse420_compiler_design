%{

#include "symbol_table.h"

#define YYSTYPE symbol_info*
#include <cstdlib>

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

// create your symbol table here.
symbol_table *sym_table = new symbol_table(10);

int lines = 1;

ofstream outlog;
ofstream outerror;

// you may declare other necessary variables here to store necessary info
string current_var_type = "";
vector<string> current_param_types;
bool skip_scope_for_next_compound = false;

// ---------------- Semantic Analysis bookkeeping ----------------
int error_count = 0;
int warning_count = 0;

// Writes an ERROR message to both the log file and the error file,
// following the "Line# : message" style already used for redeclaration
// errors in this grammar, and bumps the running error counter.
void semantic_error(const string &msg)
{
	error_count++;
	outlog  << "Error at line " << lines << ": " << msg << endl << endl;
	outerror<< "Error at line " << lines << ": " << msg << endl;
}

// Writes a WARNING message (non-fatal, e.g. implicit narrowing conversion)
void semantic_warning(const string &msg)
{
	warning_count++;
	outlog  << "Warning at line " << lines << ": " << msg << endl << endl;
	outerror<< "Warning at line " << lines << ": " << msg << endl;
}

// Returns true if the given textual representation is a literal zero
// (used for division / modulus by zero detection)
bool is_literal_zero(const string &s)
{
	if (s.empty()) return false;
	for (char c : s) if (c != '0' && c != '.') return false;
	return true;
}

void yyerror(char *s)
{
	outlog<<"At line "<<lines<<" "<<s<<endl<<endl;

    // you may need to reinitialize variables if you find an error
}

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		outlog<<"At line no: "<<lines<<" start : program "<<endl<<endl;
		outlog<<"Symbol Table"<<endl<<endl;
		
		// Print your whole symbol table here
		sym_table->print_all_scopes(outlog);
	}
	;

program : program unit
	{
		outlog<<"At line no: "<<lines<<" program : program unit "<<endl<<endl;
		outlog<<$1->getname()+"\n"+$2->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname()+"\n"+$2->getname(),"program");
	}
	| unit
	{
		outlog<<"At line no: "<<lines<<" program : unit "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"program");
	}
	;

unit : variable_decl
	 {
		outlog<<"At line no: "<<lines<<" unit : variable_decl "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"unit");
	 }
     | func_definition
     {
		outlog<<"At line no: "<<lines<<" unit : func_definition "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"unit");
	 }
     ;

func_definition : type_specifier ID LPAREN
		{
			symbol_info *func_sym = new symbol_info($2->getname(), "ID");
			func_sym->set_symbol_kind(KIND_FUNCTION);
			func_sym->set_data_type($1->getname());
			if (!sym_table->insert(func_sym))
			{
				semantic_error("Multiple declaration of function \""+$2->getname()+"\"");
				delete func_sym;
			}

			current_param_types.clear();
			int new_id = sym_table->enter_scope();
			outlog<<"New ScopeTable with id "<<new_id<<" created"<<endl<<endl;
			skip_scope_for_next_compound = true;
		}
		param_list RPAREN
		{
			
			symbol_info *func_sym_lookup = sym_table->lookup($2->getname());
			if (func_sym_lookup != NULL)
				func_sym_lookup->set_param_types(current_param_types);
		}
		compound_statement
		{	
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN param_list RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<"("+$5->getname()+")\n"<<$8->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+"("+$5->getname()+")\n"+$8->getname(),"func_def");	
			
		}
		| type_specifier ID LPAREN
		{
			symbol_info *func_sym = new symbol_info($2->getname(), "ID");
			func_sym->set_symbol_kind(KIND_FUNCTION);
			func_sym->set_data_type($1->getname());
		
			if (!sym_table->insert(func_sym))
			{
				semantic_error("Multiple declaration of function \""+$2->getname()+"\"");
				delete func_sym;
			}

			current_param_types.clear();
			int new_id = sym_table->enter_scope();
			outlog<<"New ScopeTable with id "<<new_id<<" created"<<endl<<endl;
			skip_scope_for_next_compound = true;

			symbol_info *func_sym_lookup2 = sym_table->lookup($2->getname());
			if (func_sym_lookup2 != NULL)
				func_sym_lookup2->set_param_types(current_param_types); // no params
		}
		RPAREN compound_statement
		{
			
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<"()\n"<<$6->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+"()\n"+$6->getname(),"func_def");	
			

		}
 		;

param_list : param_list COMMA type_specifier ID
		{
			outlog<<"At line no: "<<lines<<" param_list : param_list COMMA type_specifier ID "<<endl<<endl;
			outlog<<$1->getname()<<","<<$3->getname()<<" "<<$4->getname()<<endl<<endl;
					
			$$ = new symbol_info($1->getname()+","+$3->getname()+" "+$4->getname(),"param_list");
			
			symbol_info *param_sym = new symbol_info($4->getname(), "ID");
			param_sym->set_symbol_kind(KIND_VARIABLE);
			param_sym->set_data_type($3->getname());
			if (!sym_table->insert(param_sym))
			{
				semantic_error("Multiple declaration of parameter \""+$4->getname()+"\"");
				delete param_sym;
			}
			current_param_types.push_back($3->getname());
		}
		| param_list COMMA type_specifier
		{
			outlog<<"At line no: "<<lines<<" param_list : param_list COMMA type_specifier "<<endl<<endl;
			outlog<<$1->getname()<<","<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+","+$3->getname(),"param_list");
			
			current_param_types.push_back($3->getname());
		}
 		| type_specifier ID
 		{
			outlog<<"At line no: "<<lines<<" param_list : type_specifier ID "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname(),"param_list");
			
			symbol_info *param_sym = new symbol_info($2->getname(), "ID");
			param_sym->set_symbol_kind(KIND_VARIABLE);
			param_sym->set_data_type($1->getname());
			if (!sym_table->insert(param_sym))
			{
				semantic_error("Multiple declaration of parameter \""+$2->getname()+"\"");
				delete param_sym;
			}
			current_param_types.push_back($1->getname());
		}
		| type_specifier
		{
			outlog<<"At line no: "<<lines<<" param_list : type_specifier "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"param_list");
			
			current_param_types.push_back($1->getname());
		}
 		;

compound_statement : LCURL
			{
				if (skip_scope_for_next_compound)
				{
					skip_scope_for_next_compound = false;
				}
				else
				{
					int new_id = sym_table->enter_scope();
					outlog<<"New ScopeTable with id "<<new_id<<" created"<<endl<<endl;
				}
			}
			statements RCURL
			{ 
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL statements RCURL "<<endl<<endl;
				outlog<<"{\n"+$3->getname()+"\n}"<<endl<<endl;
				
				$$ = new symbol_info("{\n"+$3->getname()+"\n}","comp_stmnt");
				
				outlog<<"Symbol Table before exiting scope:"<<endl<<endl;
				sym_table->print_all_scopes(outlog);
				int removed_id = sym_table->exit_scope();
				outlog<<"ScopeTable # "<<removed_id<<" removed"<<endl<<endl;
 		    }
 		    | LCURL
 		    {
				if (skip_scope_for_next_compound)
				{
					skip_scope_for_next_compound = false;
				}
				else
				{
					int new_id = sym_table->enter_scope();
					outlog<<"New ScopeTable with id "<<new_id<<" created"<<endl<<endl;
				}
 		    }
 		    RCURL
 		    { 
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL RCURL "<<endl<<endl;
				outlog<<"{\n}"<<endl<<endl;
				
				$$ = new symbol_info("{\n}","comp_stmnt");
				
				outlog<<"Symbol Table before exiting scope:"<<endl<<endl;
				sym_table->print_all_scopes(outlog);
				int removed_id = sym_table->exit_scope();
				outlog<<"ScopeTable # "<<removed_id<<" removed"<<endl<<endl;
 		    }
 		    ;
 		    
variable_decl : type_specifier declaration_list SEMICOLON
		 {
			outlog<<"At line no: "<<lines<<" variable_decl : type_specifier declaration_list SEMICOLON "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<";"<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+";","var_dec");
			
		 }
 		 ;

type_specifier : INT
		{
			outlog<<"At line no: "<<lines<<" type_specifier : INT "<<endl<<endl;
			outlog<<"int"<<endl<<endl;
			
			$$ = new symbol_info("int","type");
			current_var_type = "int";
	    }
 		| FLOAT
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : FLOAT "<<endl<<endl;
			outlog<<"float"<<endl<<endl;
			
			$$ = new symbol_info("float","type");
			current_var_type = "float";
	    }
 		| VOID
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : VOID "<<endl<<endl;
			outlog<<"void"<<endl<<endl;
			
			$$ = new symbol_info("void","type");
			current_var_type = "void";
	    }
		| CHAR
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : CHAR "<<endl<<endl;
			outlog<<"char"<<endl<<endl;
			
			$$ = new symbol_info("char","type");
			current_var_type = "char";
	    }
 		;

declaration_list : declaration_list COMMA ID
		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID "<<endl<<endl;
 		  	outlog<<$1->getname()+","<<$3->getname()<<endl<<endl;

			$$ = new symbol_info($1->getname()+","+$3->getname(),"decl_list");

			if (current_var_type == "void")
			{
				semantic_error("Variable \""+$3->getname()+"\" declared void, which is not allowed");
			}
			else
			{
				symbol_info *var_sym = new symbol_info($3->getname(), "ID");
				var_sym->set_symbol_kind(KIND_VARIABLE);
				var_sym->set_data_type(current_var_type);
				if (!sym_table->insert(var_sym))
				{
					semantic_error("Multiple declaration of \""+$3->getname()+"\"");
					delete var_sym;
				}
			}
 		  }
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD //array after some declaration
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
 		  	outlog<<$1->getname()+","<<$3->getname()<<"["<<$5->getname()<<"]"<<endl<<endl;

			$$ = new symbol_info($1->getname()+","+$3->getname()+"["+$5->getname()+"]","decl_list");

			if (current_var_type == "void")
			{
				semantic_error("Array \""+$3->getname()+"\" declared void, which is not allowed");
			}
			else
			{
				symbol_info *arr_sym = new symbol_info($3->getname(), "ID");
				arr_sym->set_symbol_kind(KIND_ARRAY);
				arr_sym->set_data_type(current_var_type);
				arr_sym->set_array_size(atoi($5->getname().c_str()));
				if (!sym_table->insert(arr_sym))
				{
					semantic_error("Multiple declaration of \""+$3->getname()+"\"");
					delete arr_sym;
				}
			}
 		  }
 		  |ID
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;

			$$ = new symbol_info($1->getname(),"decl_list");

			if (current_var_type == "void")
			{
				semantic_error("Variable \""+$1->getname()+"\" declared void, which is not allowed");
			}
			else
			{
				symbol_info *var_sym = new symbol_info($1->getname(), "ID");
				var_sym->set_symbol_kind(KIND_VARIABLE);
				var_sym->set_data_type(current_var_type);
				if (!sym_table->insert(var_sym))
				{
					semantic_error("Multiple declaration of \""+$1->getname()+"\"");
					delete var_sym;
				}
			}
 		  }
 		  | ID LTHIRD CONST_INT RTHIRD //array
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
			outlog<<$1->getname()<<"["<<$3->getname()<<"]"<<endl<<endl;

			$$ = new symbol_info($1->getname()+"["+$3->getname()+"]","decl_list");

			if (current_var_type == "void")
			{
				semantic_error("Array \""+$1->getname()+"\" declared void, which is not allowed");
			}
			else
			{
				symbol_info *arr_sym = new symbol_info($1->getname(), "ID");
				arr_sym->set_symbol_kind(KIND_ARRAY);
				arr_sym->set_data_type(current_var_type);
				arr_sym->set_array_size(atoi($3->getname().c_str()));
				if (!sym_table->insert(arr_sym))
				{
					semantic_error("Multiple declaration of \""+$1->getname()+"\"");
					delete arr_sym;
				}
			}
 		  }
 		  ;
 		  

statements : statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnts");
	   }
	   | statements statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statements statement "<<endl<<endl;
			outlog<<$1->getname()<<"\n"<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+"\n"+$2->getname(),"stmnts");
	   }
	   ;
	   
statement : variable_decl
	  {
	    	outlog<<"At line no: "<<lines<<" statement : variable_decl "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
	  }
	  | func_definition
	  {
	  		outlog<<"At line no: "<<lines<<" statement : func_definition "<<endl<<endl;
            outlog<<$1->getname()<<endl<<endl;

            $$ = new symbol_info($1->getname(),"stmnt");
	  		
	  }
	  | expression_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : expression_statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
	  }
	  | compound_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl<<endl;
			outlog<<"for("<<$3->getname()<<$4->getname()<<$5->getname()<<")\n"<<$7->getname()<<endl<<endl;
			
			$$ = new symbol_info("for("+$3->getname()+$4->getname()+$5->getname()+")\n"+$7->getname(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"if("<<$3->getname()<<")\n"<<$5->getname()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->getname()+")\n"+$5->getname(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement ELSE statement "<<endl<<endl;
			outlog<<"if("<<$3->getname()<<")\n"<<$5->getname()<<"\nelse\n"<<$7->getname()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->getname()+")\n"+$5->getname()+"\nelse\n"+$7->getname(),"stmnt");
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : WHILE LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"while("<<$3->getname()<<")\n"<<$5->getname()<<endl<<endl;
			
			$$ = new symbol_info("while("+$3->getname()+")\n"+$5->getname(),"stmnt");
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : PRINTLN LPAREN ID RPAREN SEMICOLON "<<endl<<endl;
			outlog<<"printf("<<$3->getname()<<");"<<endl<<endl; 

			if (sym_table->lookup($3->getname()) == NULL)
			{
				semantic_error("Undeclared variable \""+$3->getname()+"\"");
			}
			
			$$ = new symbol_info("printf("+$3->getname()+");","stmnt");
	  }
	  | RETURN expression SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : RETURN expression SEMICOLON "<<endl<<endl;
			outlog<<"return "<<$2->getname()<<";"<<endl<<endl;
			
			$$ = new symbol_info("return "+$2->getname()+";","stmnt");
	  }
	  ;
	  
expression_statement : SEMICOLON
			{
				outlog<<"At line no: "<<lines<<" expression_statement : SEMICOLON "<<endl<<endl;
				outlog<<";"<<endl<<endl;
				
				$$ = new symbol_info(";","expr_stmt");
	        }			
			| expression SEMICOLON 
			{
				outlog<<"At line no: "<<lines<<" expression_statement : expression SEMICOLON "<<endl<<endl;
				outlog<<$1->getname()<<";"<<endl<<endl;
				
				$$ = new symbol_info($1->getname()+";","expr_stmt");
				$$->set_value_type($1->get_value_type());
	        }
			;
	  
variable : ID 	
      {
	    outlog<<"At line no: "<<lines<<" variable : ID "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"varbl");

		symbol_info *found = sym_table->lookup($1->getname());
		if (found == NULL)
		{
			semantic_error("Undeclared variable \""+$1->getname()+"\"");
			$$->set_value_type("error");
		}
		else if (found->get_symbol_kind() == KIND_FUNCTION)
		{
			semantic_error("\""+$1->getname()+"\" is a function, cannot be used as a variable");
			$$->set_value_type("error");
		}
		else if (found->get_symbol_kind() == KIND_ARRAY)
		{
			semantic_error("Mismatching type, array \""+$1->getname()+"\" used without index");
			$$->set_value_type("error");
		}
		else
		{
			$$->set_value_type(found->get_data_type());
		}
		
	 }	
	 | ID LTHIRD expression RTHIRD 
	 {
	 	outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
		outlog<<$1->getname()<<"["<<$3->getname()<<"]"<<endl<<endl;
		
		$$ = new symbol_info($1->getname()+"["+$3->getname()+"]","varbl");

		symbol_info *found = sym_table->lookup($1->getname());
		if (found == NULL)
		{
			semantic_error("Undeclared variable \""+$1->getname()+"\"");
			$$->set_value_type("error");
		}
		else if (found->get_symbol_kind() != KIND_ARRAY)
		{
			semantic_error("Mismatching type, \""+$1->getname()+"\" is not an array, cannot be indexed");
			$$->set_value_type("error");
		}
		else
		{
			if ($3->get_value_type() == "float")
			{
				semantic_error("Non-integer (\"" + $3->getname() + "\") used as index of array \""+$1->getname()+"\"");
			}
			$$->set_value_type(found->get_data_type());
		}
	 }
	 ;
	 
expression : logic_expression
	   {
	    	outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"expr");
			$$->set_value_type($1->get_value_type());
	   }
	   | variable ASSIGNOP logic_expression 	
	   {
	    	outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
			outlog<<$1->getname()<<"="<<$3->getname()<<endl<<endl;

			$$ = new symbol_info($1->getname()+"="+$3->getname(),"expr");

			string var_type = $1->get_value_type();
			string rhs_type = $3->get_value_type();

			if (var_type != "error" && rhs_type != "error")
			{
				if (rhs_type == "void")
				{
					semantic_error("Void function used in expression / assigned to variable \""+$1->getname()+"\"");
				}
				else if (var_type == "void")
				{
					semantic_error("Cannot assign to void type variable \""+$1->getname()+"\"");
				}
				else if (var_type == "int" && rhs_type == "float")
				{
					semantic_warning("Type Mismatch, conflicting types, assigning FLOAT to INT variable \""+$1->getname()+"\"");
				}
				else if (var_type != rhs_type && !(var_type == "float" && rhs_type == "int"))
				{
					semantic_error("Type Mismatch, cannot assign type \""+rhs_type+"\" to type \""+var_type+"\" variable \""+$1->getname()+"\"");
				}
			}

			$$->set_value_type(var_type == "error" ? rhs_type : var_type);
	   }
	   ;
			
logic_expression : rel_expression
	     {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"lgc_expr");
			$$->set_value_type($1->get_value_type());
	     }	
		 | rel_expression LOGICOP rel_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"lgc_expr");

			if ($1->get_value_type() == "void" || $3->get_value_type() == "void")
			{
				semantic_error("Void function used in expression");
			}
			// Result of a LOGICOP operation should always be int
			$$->set_value_type("int");
	     }	
		 ;
			
rel_expression	: simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"rel_expr");
			$$->set_value_type($1->get_value_type());
	    }
		| simple_expression RELOP simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"rel_expr");

			if ($1->get_value_type() == "void" || $3->get_value_type() == "void")
			{
				semantic_error("Void function used in expression");
			}
			// Result of a RELOP operation should always be int
			$$->set_value_type("int");
	    }
		;
				
simple_expression : term
          {
	    	outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"simp_expr");
			$$->set_value_type($1->get_value_type());
			
	      }
		  | simple_expression ADDOP term 
		  {
	    	outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"simp_expr");

			string t1 = $1->get_value_type();
			string t2 = $3->get_value_type();

			if (t1 == "void" || t2 == "void")
			{
				semantic_error("Void function used in expression");
				$$->set_value_type("error");
			}
			else if (t1 == "error" || t2 == "error")
			{
				$$->set_value_type("error");
			}
			else
			{
				$$->set_value_type((t1 == "float" || t2 == "float") ? "float" : "int");
			}
	      }
		  ;
					
term :	unary_expression //term can be void because of un_expr->factor
     {
	    	outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"term");
			$$->set_value_type($1->get_value_type());
			
	 }
     |  term MULOP unary_expression
     {
	    	outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"term");

			string t1 = $1->get_value_type();
			string t2 = $3->get_value_type();
			string op = $2->getname();

			if (t1 == "void" || t2 == "void")
			{
				semantic_error("Void function used in expression");
				$$->set_value_type("error");
			}
			else if (t1 == "error" || t2 == "error")
			{
				$$->set_value_type("error");
			}
			else if (op == "%")
			{
				if (t1 != "int" || t2 != "int")
				{
					semantic_error("Non-integer operand on modulus operator");
				}
				else if (is_literal_zero($3->getname()))
				{
					semantic_error("Modulus by zero");
				}
				$$->set_value_type("int");
			}
			else if (op == "/")
			{
				if (is_literal_zero($3->getname()))
				{
					semantic_error("Division by zero");
				}
				$$->set_value_type((t1 == "float" || t2 == "float") ? "float" : "int");
			}
			else // '*'
			{
				$$->set_value_type((t1 == "float" || t2 == "float") ? "float" : "int");
			}
			
	 }
     ;

unary_expression : ADDOP unary_expression  
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname(),"un_expr");

			if ($2->get_value_type() == "void")
			{
				semantic_error("Void function used in expression");
				$$->set_value_type("error");
			}
			else
			{
				$$->set_value_type($2->get_value_type());
			}
	     }
		 | NOT unary_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
			outlog<<"!"<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info("!"+$2->getname(),"un_expr");

			if ($2->get_value_type() == "void")
			{
				semantic_error("Void function used in expression");
			}
			$$->set_value_type("int");
	     }
		 | factor_info  
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : factor_info  "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"un_expr");
			$$->set_value_type($1->get_value_type());
	     }
		 ;
factor_info : factor	{
	    outlog<<"At line no: "<<lines<<" factor_info : factor "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr_info");
		$$->set_value_type($1->get_value_type());
	}	
factor	: variable
    {
	    outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr");
		$$->set_value_type($1->get_value_type());
	}
	| ID LPAREN argument_list RPAREN
	{
	    outlog<<"At line no: "<<lines<<" factor : ID LPAREN argument_list RPAREN "<<endl<<endl;
		outlog<<$1->getname()<<"("<<$3->getname()<<")"<<endl<<endl;

		$$ = new symbol_info($1->getname()+"("+$3->getname()+")","fctr");

		symbol_info *found = sym_table->lookup($1->getname());
		if (found == NULL)
		{
			semantic_error("Undeclared function \""+$1->getname()+"\"");
			$$->set_value_type("error");
		}
		else if (found->get_symbol_kind() != KIND_FUNCTION)
		{
			semantic_error("\""+$1->getname()+"\" is not a function, cannot be called");
			$$->set_value_type("error");
		}
		else
		{
			vector<string> declared = found->get_param_types();
			vector<string> actual = $3->get_param_types();

			if (declared.size() != actual.size())
			{
				semantic_error("Total number of arguments mismatch in function \""+$1->getname()+"\"");
			}
			else
			{
				for (size_t i = 0; i < declared.size(); i++)
				{
					if (actual[i] == "error") continue;
					if (declared[i] == actual[i]) continue;
					if (declared[i] == "float" && actual[i] == "int") continue; // implicit widening ok

					if (declared[i] == "int" && actual[i] == "float")
					{
						semantic_warning("Type Mismatch, argument "+to_string(i+1)+" of function \""+$1->getname()+"\": passing FLOAT where INT expected (implicit conversion)");
					}
					else
					{
						semantic_error("Type Mismatch, argument "+to_string(i+1)+" of function \""+$1->getname()+"\": expected \""+declared[i]+"\" but got \""+actual[i]+"\"");
					}
					break; // one error message per faulty call is enough
				}
			}

			$$->set_value_type(found->get_data_type());
		}
	}
	| LPAREN expression RPAREN
	{
	   	outlog<<"At line no: "<<lines<<" factor : LPAREN expression RPAREN "<<endl<<endl;
		outlog<<"("<<$2->getname()<<")"<<endl<<endl;
		
		$$ = new symbol_info("("+$2->getname()+")","fctr");
		$$->set_value_type($2->get_value_type());
	}
	| CONST_INT 
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_INT "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr");
		$$->set_value_type("int");
	}
	| CONST_FLOAT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr");
		$$->set_value_type("float");
	}
	| variable INCOP 
	{
	    outlog<<"At line no: "<<lines<<" factor : variable INCOP "<<endl<<endl;
		outlog<<$1->getname()<<"++"<<endl<<endl;
			
		$$ = new symbol_info($1->getname()+"++","fctr");
		$$->set_value_type($1->get_value_type());
	}
	| variable DECOP
	{
	    outlog<<"At line no: "<<lines<<" factor : variable DECOP "<<endl<<endl;
		outlog<<$1->getname()<<"--"<<endl<<endl;
			
		$$ = new symbol_info($1->getname()+"--","fctr");
		$$->set_value_type($1->get_value_type());
	}
	;
	
argument_list : arguments
			  {
					outlog<<"At line no: "<<lines<<" argument_list : arguments "<<endl<<endl;
					outlog<<$1->getname()<<endl<<endl;
						
					$$ = new symbol_info($1->getname(),"arg_list");
					$$->set_param_types($1->get_param_types());
			  }
			  |
			  {
					outlog<<"At line no: "<<lines<<" argument_list :  "<<endl<<endl;
					outlog<<""<<endl<<endl;
						
					$$ = new symbol_info("","arg_list");
					$$->set_param_types(vector<string>());
			  }
			  ;
	
arguments : arguments COMMA logic_expression
		  {
				outlog<<"At line no: "<<lines<<" arguments : arguments COMMA logic_expression "<<endl<<endl;
				outlog<<$1->getname()<<","<<$3->getname()<<endl<<endl;
						
				$$ = new symbol_info($1->getname()+","+$3->getname(),"arg");

				vector<string> types = $1->get_param_types();
				types.push_back($3->get_value_type());
				$$->set_param_types(types);
		  }
	      | logic_expression
	      {
				outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
				outlog<<$1->getname()<<endl<<endl;
						
				$$ = new symbol_info($1->getname(),"arg");

				vector<string> types;
				types.push_back($1->get_value_type());
				$$->set_param_types(types);
		  }
	      ;
 

%%

int main(int argc, char *argv[])
{
	if(argc != 2) 
	{
		cout<<"Please input file name"<<endl;
		return 0;
	}
	yyin = fopen(argv[1], "r");
	outlog.open("22201157_log.txt", ios::trunc);
	outerror.open("22201157_error.txt", ios::trunc);
	
	if(yyin == NULL)
	{
		cout<<"Couldn't open file"<<endl;
		return 0;
	}
	// Enter the global or the first scope here
	int global_id = sym_table->enter_scope();
	outlog<<"New ScopeTable with id "<<global_id<<" created"<<endl<<endl;

	yyparse();
	
	outlog<<endl<<"Total lines: "<<lines<<endl;
	outlog<<"Total errors: "<<error_count<<endl;
	outlog<<"Total warnings: "<<warning_count<<endl;

	outerror<<endl<<"Total errors: "<<error_count<<endl;
	outerror<<"Total warnings: "<<warning_count<<endl;
	
	outlog.close();
	outerror.close();
	
	fclose(yyin);
	
	return 0;
}
