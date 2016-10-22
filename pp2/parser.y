/* File: parser.y
 * --------------
 * Bison input file to generate the parser for the compiler.
 *
 * pp2: your job is to write a parser that will construct the parse tree
 *      and if no parse errors were found, print it. The parser should
 *      accept the language as described in specification, and as augmented
 *      in the pp2 handout.
 */

%{

/* Just like lex, the text within this first region delimited by %{ and %}
 * is assumed to be C/C++ code and will be copied verbatim to the y.tab.c
 * file ahead of the definitions of the yyparse() function. Add other header
 * file inclusions or C++ variable declarations/prototypes that are needed
 * by your code here.
 */
#include "scanner.h" // for yylex
#include "parser.h"
#include "errors.h"

void yyerror(const char *msg); // standard error-handling routine

%}

/* The section before the first %% is the Definitions section of the yacc
 * input file. Here is where you declare tokens and types, add precedence
 * and associativity options, and so on.
 */

/* yylval
 * ------
 * Here we define the type of the yylval global variable that is used by
 * the scanner to store attribute information about the token just scanned
 * and thus communicate that information to the parser.
 *
 * pp2: You will need to add new fields to this union as you add different
 *      attributes to your non-terminal symbols.
 */
%union {
    int integerConstant;
    bool boolConstant;
    char *stringConstant;
    double doubleConstant;
    char *identifier;
    Decl *decl;
    List<Decl*> *declList;
    VarDecl *varDecl;
    List<VarDecl*> *varDeclList;
    Type *type;
    Stmt *stmt;
    StmtBlock *stmtBlock;
    List<Stmt*> *stmtList;
    NamedType *namedType;
    List<NamedType*> *namedTypeList;
    Expr *expr;
    List<Expr*> *exprList;
}


/* Tokens
 * ------
 * Here we tell yacc about all the token types that we are using.
 * Bison will assign unique numbers to these and export the #define
 * in the generated y.tab.h header file.
 */
%token   T_Void T_Bool T_Int T_Double T_String T_Class
%token   T_LessEqual T_GreaterEqual T_Equal T_NotEqual T_Dims
%token   T_And T_Or T_Null T_Extends T_This T_Interface T_Implements
%token   T_While T_For T_If T_Else T_Return T_Break
%token   T_New T_NewArray T_Print T_ReadInteger T_ReadLine

%token   <identifier> T_Identifier
%token   <stringConstant> T_StringConstant
%token   <integerConstant> T_IntConstant
%token   <doubleConstant> T_DoubleConstant
%token   <boolConstant> T_BoolConstant


/* Non-terminal types
 * ------------------
 * In order for yacc to assign/access the correct field of $$, $1, we
 * must declare which field is appropriate for the non-terminal.
 * As an example, this first type declaration establishes that the DeclList
 * non-terminal uses the field named "declList" in the yylval union. This
 * means that when we are setting $$ for a reduction for DeclList or reading
 * $n which corresponds to a DeclList nonterminal we are accessing the field
 * of the union named "declList" which is of type List<Decl*>.
 * pp2: You'll need to add many of these of your own.
 */
%type <declList>  DeclList Fields Prototypes
%type <varDeclList>  Formals VariableDecls
%type <decl>      Decl Field
%type <varDecl>   Variable VariableDecl
%type <decl>      FunctionDecl ClassDecl InterfaceDecl Prototype
%type <type>      Type
%type <stmt>      Stmt IfStmt ElseStmt WhileStmt ForStmt ReturnStmt PrintStmt BreakStmt
%type <stmtList>  Stmts
%type <stmtBlock> StmtBlock StmtBlockNonEmpty
%type <namedType> ExtendsClass
%type <namedTypeList> ImplementsInterface
%type <expr> Expr LValue Constant Call
%type <exprList> Args Actuals

%left '<' '>' '=' "!=" "<=" ">="
%left '+' '-'
%left '*' '/'

%%
/* Rules
 * -----
 * All productions and actions should be placed between the start and stop
 * %% markers which delimit the Rules section.

 */
Program   :    DeclList            {
                                      /* pp2: The @1 is needed to convince
                                       * yacc to set up yylloc. You can remove
                                       * it once you have other uses of @n*/
                                      Program *program = new Program($1);
                                      // if no errors, advance to next phase
                                      if (ReportError::NumErrors() == 0)
                                          program->Print(0);
                                    }
          ;

DeclList  :    DeclList Decl        { ($$=$1)->Append($2); }
          |    Decl                 { ($$ = new List<Decl*>)->Append($1); }
          ;

Decl      :    VariableDecl { $$ = $1; }
          |    FunctionDecl { $$ = $1; }
          |    ClassDecl { $$ = $1; }
          |    InterfaceDecl { $$ = $1; }
          ;

VariableDecl   : Variable ';' { $$ = $1; }
               ;

Variable : Type T_Identifier { $$ = new VarDecl(new Identifier(@2, $2), $1); }
         ;

Type     : T_Int { $$ = Type::intType; }
         | T_Double { $$ = Type::doubleType; }
         | T_Bool { $$ = Type::boolType; }
         | T_String { $$ = Type::stringType; }
         | T_Identifier { $$ = new NamedType(new Identifier(@1, $1)); }
         | Type T_Dims { $$ = new ArrayType(@1, $1); }
         ;

FunctionDecl  : Type T_Identifier '(' Formals ')' StmtBlockNonEmpty { FnDecl *decl = new FnDecl(new Identifier(@2, $2), $1, $4); decl->SetFunctionBody($6); $$ = decl; }
              | T_Void T_Identifier '(' Formals ')' StmtBlockNonEmpty { FnDecl *decl = new FnDecl(new Identifier(@2, $2), Type::voidType, $4); decl->SetFunctionBody($6); $$ = decl; }
              ;

Formals   : Variable { ($$ = new List<VarDecl*>)->Append($1); }
          | Formals Variable { $$->Append($2); }
          | /* empty */ { $$ = new List<VarDecl*>(); }
          ;

ClassDecl : T_Class T_Identifier ExtendsClass '{' Fields '}' { $$ = new ClassDecl(new Identifier(@2, $2), $3, new List<NamedType*>(), $5); }
          | T_Class T_Identifier ExtendsClass ImplementsInterface '{' Fields '}' {}
          ;

ExtendsClass : T_Extends T_Identifier { $$ = new NamedType(new Identifier(@2, $2)); }
             | /* empty */ { $$ = NULL; }
             ;

ImplementsInterface : T_Implements T_Identifier { ($$ = new List<NamedType*>())->Append(new NamedType(new Identifier(@2, $2))); }
                    | ImplementsInterface ',' T_Implements T_Identifier { $$->Append(new NamedType(new Identifier(@4, $4))); }
                    ;

Fields : Field { ($$ = new List<Decl*>)->Append($1); }
       | Fields Field { ($$=$1)->Append($2); }
       | /* empty */ { $$ = new List<Decl*>(); }
       ;

Field : VariableDecl { $$ = static_cast<Decl*>($1); }
      | FunctionDecl { $$ = static_cast<Decl*>($1); }
      ;

InterfaceDecl : T_Interface T_Identifier '{' Prototypes '}' { $$ = new InterfaceDecl(new Identifier(@2, $2), $4); }
              ;

Prototypes : Prototype { ($$ = new List<Decl*>)->Append($1); }
           | Prototypes Prototype { $$->Append($2); }
           | /* empty */ { $$ = new List<Decl*>(); }
           ;

Prototype : Type T_Identifier '(' Formals ')' ';' { $$ = new FnDecl(new Identifier(@2, $2), $1, $4); }
          | T_Void T_Identifier '(' Formals ')' ';' { $$ = new FnDecl(new Identifier(@2, $2), Type::voidType, $4); }
          ;

StmtBlock : VariableDecls Stmts { $$ = new StmtBlock($1, $2); }
          | Stmts { $$ = new StmtBlock(new List<VarDecl*>(), $1); }
          | /* empty */ { $$ = new StmtBlock(new List<VarDecl*>(), new List<Stmt*>()); }
          ;

StmtBlockNonEmpty : '{' VariableDecls Stmts '}' { $$ = new StmtBlock($2, $3); }
                  | '{' Stmts '}' { $$ = new StmtBlock(new List<VarDecl*>(), $2); }
                  ;

VariableDecls : VariableDecl { ($$ = new List<VarDecl*>())->Append($1); }
              | VariableDecls VariableDecl { ($$=$1)->Append($2); }
              ;

Stmts : Stmt { ($$ = new List<Stmt*>)->Append($1); }
      | Stmts Stmt { ($$=$1)->Append($2); }
      ;

Stmt : ';' { $$ = NULL; }
     | Expr ';' { $$ = static_cast<Stmt*>($1); }
     | IfStmt { $$ = $1; }
     | WhileStmt { $$ = $1; }
     | ForStmt { $$ = $1; }
     | BreakStmt { $$ = $1; }
     | ReturnStmt { $$ = $1; }
     | PrintStmt { $$ = $1; }
     | StmtBlockNonEmpty { $$ = $1; }
     ;

IfStmt : T_If '(' Expr ')' Stmt ElseStmt { $$ = new IfStmt($3, $5, $6); }
       ;

ElseStmt : T_Else Stmt { $$ = $2; }
         | /* empty */ { $$ = NULL; }
         ;

WhileStmt : T_While '(' Expr ')' Stmt { $$ = new WhileStmt($3, $5); }
          ;

ForStmt : T_For '(' Expr ';' Expr ';' Expr ')' Stmt { $$ = new ForStmt($3, $5, $7, $9); }
        ;

ReturnStmt : T_Return Expr ';' { $$ = new ReturnStmt(@1, $2); }
           | T_Return ';' { $$ = new ReturnStmt(@1, NULL); }
           ;

BreakStmt : T_Break ';' { $$ = new BreakStmt(@1); }
          ;

PrintStmt : T_Print '(' Args ')' ';' { $$ = new PrintStmt($3); }
          ;

Args : Expr { ($$ = new List<Expr*>())->Append($1); }
     | Args ',' Expr { ($$=$1)->Append($3); }
     ;

Expr : LValue '=' Expr { $$ = new AssignExpr($1, new Operator(@2, "="), $3); }
     | Constant { $$ = $1; }
     | LValue { $$ = $1; }
     | T_This { $$ = new This(@1); }
     | Call { $$ = $1; }
     | '(' Expr ')' { $$ = $2; }
     | Expr '+' Expr { $$ = new ArithmeticExpr($1, new Operator(@2, "+"), $3); }
     | Expr '-' Expr { $$ = new ArithmeticExpr($1, new Operator(@2, "-"), $3); }
     | Expr '*' Expr { $$ = new ArithmeticExpr($1, new Operator(@2, "*"), $3); }
     | Expr '/' Expr { $$ = new ArithmeticExpr($1, new Operator(@2, "/"), $3); }
     | Expr '%' Expr { $$ = new ArithmeticExpr($1, new Operator(@2, "%"), $3); }
     | '-' Expr { $$ = new ArithmeticExpr(new Operator(@1, "-"), $2); }
     | Expr '<' Expr { $$ = new RelationalExpr($1, new Operator(@2, "<"), $3); }
     | Expr T_LessEqual Expr { $$ = new RelationalExpr($1, new Operator(@2, "<="), $3); }
     | Expr '>' Expr { $$ = new RelationalExpr($1, new Operator(@2, ">"), $3); }
     | Expr T_GreaterEqual Expr { $$ = new RelationalExpr($1, new Operator(@2, ">="), $3); }
     | Expr T_Equal Expr { $$ = new LogicalExpr($1, new Operator(@2, "=="), $3); }
     | Expr T_NotEqual Expr { $$ = new LogicalExpr($1, new Operator(@2, "!="), $3); }
     | Expr T_And Expr { $$ = new LogicalExpr($1, new Operator(@2, "&&"), $3); }
     | Expr T_Or Expr { $$ = new LogicalExpr($1, new Operator(@2, "||"), $3); }
     | '!' Expr { $$ = new LogicalExpr(new Operator(@1, "!"), $2); }
     | T_ReadInteger '(' ')' { $$ = new ReadIntegerExpr(@1); }
     | T_ReadLine '(' ')' { $$ = new ReadLineExpr(@1); }
     | T_New T_Identifier { $$ = new NewExpr(@1, new NamedType(new Identifier(@2, $2))); }
     | T_NewArray '(' Expr ',' Type ')' { $$ = new NewArrayExpr(@1, $3, $5); }
     ;

LValue : T_Identifier { $$ = new FieldAccess(NULL, new Identifier(@1, $1)); }
       | Expr '.' T_Identifier { $$ = new FieldAccess($1, new Identifier(@3, $3)); }
       | Expr '[' Expr ']' { $$ = new ArrayAccess(@1, $1, $3); }
       ;

Call : T_Identifier '(' Actuals ')' { $$ = new Call(@1, NULL, new Identifier(@1, $1), $3); }
     | Expr '.' T_Identifier '(' Actuals ')' { $$ = new Call(@1, $1, new Identifier(@3, $3), $5); }
     ;

Actuals : Expr { ($$ = new List<Expr*>())->Append($1); }
        | Actuals Expr { ($$=$1)->Append($2); }
        | /* empty */ { $$ = new List<Expr*>(); }
        ;

Constant : T_IntConstant { $$ = new IntConstant(@1, $1); }
         | T_DoubleConstant { $$ = new DoubleConstant(@1, $1); }
         | T_BoolConstant { $$ = new BoolConstant(@1, $1); }
         | T_StringConstant { $$ = new StringConstant(@1, $1); }
         | T_Null { $$ = new NullConstant(@1); }
         ;

%%

/* The closing %% above marks the end of the Rules section and the beginning
 * of the User Subroutines section. All text from here to the end of the
 * file is copied verbatim to the end of the generated y.tab.c file.
 * This section is where you put definitions of helper functions.
 */

/* Function: InitParser
 * --------------------
 * This function will be called before any calls to yyparse().  It is designed
 * to give you an opportunity to do anything that must be done to initialize
 * the parser (set global variables, configure starting state, etc.). One
 * thing it already does for you is assign the value of the global variable
 * yydebug that controls whether yacc prints debugging information about
 * parser actions (shift/reduce) and contents of state stack during parser.
 * If set to false, no information is printed. Setting it to true will give
 * you a running trail that might be helpful when debugging your parser.
 * Please be sure the variable is set to false when submitting your final
 * version.
 */
void InitParser()
{
   PrintDebug("parser", "Initializing parser");
   yydebug = false;
}
