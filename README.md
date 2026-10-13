CSE420: Compiler Design

Lab assignments for CSE420 (Compiler Design) at BRAC University. Together they build the front end of a compiler for a subset of C, using Flex (lexer) and Bison (parser).

Assignments
Assignment 1: Lexical and Syntax Analyzer. Tokenizes C source code (keywords, identifiers, constants, operators, punctuators) and parses it with a Bison grammar. Logs every token and every matched grammar rule along with the source segment, plus the final line count.

Assignment 2: Symbol Table. Symbol table with nested scope handling (symbol_info.h, scope_table.h, symbol_table.h), integrated into the Bison/Flex parser.

Assignment 3: Semantic Analyzer. Semantic checks on top of the symbol table, including type checking in expressions and assignments, array index type checks, function argument checks, and modulus/division-by-zero detection.

Assignment 4: Intermediate Code Generation. Builds an Abstract Syntax Tree during parsing, then traverses it to generate three-address code (arithmetic, logical and relational operations, arrays, if/while/for, function calls and returns).
Tools

Flex, Bison, C/C++, GCC (MinGW on Windows)

Build and run

Each assignment folder has a script.sh that generates the lexer and parser and compiles them. Run it inside that folder, then run the executable with the provided input file (input.txt for Assignment 1, input.c for Assignment 4).

Output files (log.txt, error.txt, code.txt) are generated on run and are not committed.
