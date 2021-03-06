/* File:  scanner.l
 * ----------------
 * Lex input file to generate the scanner for the compiler.
 */

%{

/* The text within this first region delimited by %{ and %} is assumed to
 * be C/C++ code and will be copied verbatim to the lex.yy.c file ahead
 * of the definitions of the yylex() function. Add other header file inclusions
 * or C++ variable declarations/prototypes that are needed by your code here.
 */

#include <string.h>
#include <stdlib.h>
#include <vector>
#include "scanner.h"
#include "utility.h" // for PrintDebug()
#include "errors.h"
using namespace std;

/* Global variable: yylval
 * -----------------------
 * This global variable is how we get attribute information about the token
 * just scanned to the client. The scanner sets the global variable
 * appropriately and since it's global the client can just read it.  In the
 * future, this variable will be declared for us in the y.tab.c file
 * produced by Yacc, but for now, we declare it manually.
 */
YYSTYPE yylval;  // manually declared for pp1, later Yacc provides

/* Global variable: yylloc
 * -----------------------
 * This global variable is how we get position information about the token
 * just scanned to the client. (Operates similarly to yylval above)
 */
struct yyltype yylloc; // manually declared for pp1, later Yacc provides

static int curLineNum, curColNum;
vector<const char*> savedLines;

/* Macro: YY_USER_ACTION
 * ---------------------
 * This flex built-in macro can be defined to provide an action which is
 * always executed prior to any matched rule's action. Basically, it is
 * a way of having a piece of code common to all actions factored out to
 * this routine. We already defined it for you and left the empty
 * function DoBeforeEachAction ready for your use as needed. It will
 * be called once for each pattern scanned from the file, before
 * executing its action.
 */
static void DoBeforeEachAction();
#define YY_USER_ACTION DoBeforeEachAction();

#define TAB_SIZE 8

%}

 /* The section before the first %% is the Definitions section of the lex
  * input file. Here is where you set options for the scanner, define lex
  * states, and can set up definitions to give names to regular expressions
  * as a simple substitution mechanism that allows for more readable
  * entries in the Rules section later.
  */

%s N
%x COPY COMM
%option stack

DIGIT [0-9]
ID    [a-z][a-z0-9]*
IDENT [a-zA-Z][a-zA-Z0-9_]*
BOOL true|false
INT_DEC [0-9]+
INT_HEX 0[xX][0-9a-fA-F]+
DOUBLE [0-9]+\.[0-9]*([eE][+-]?[0-9]+)?
OP [-+/*%=.,;!<>()[\]{}]
BEG_STR (\"[^"\n]*)
STRING ({BEG_STR}\")
BEG_COMMENT ("/*")
END_COMMENT ("*/")
SINGLE_COMMENT ("//"[^\n]*)

%%             /* BEGIN RULES SECTION */
 /* All patterns and actions should be placed between the start and stop
  * %% markers which delimit the Rules section.
  */

<COPY>.*  {
            savedLines.push_back(strdup(yytext));
            curColNum = 1;
            yy_pop_state();
            yyless(0);
          }
<COPY><<EOF>> { yy_pop_state(); }
<*>\n       {
              curLineNum++;
              curColNum = 1;
              if (YYSTATE == COPY) {
                savedLines.push_back("");
              } else {
                yy_push_state(COPY);
              }
            }
[ ]+                     { /* ignore all spaces */  }
<*>[\t\r]                { curColNum += TAB_SIZE - curColNum % TAB_SIZE + 1; }

 /* comments */
{BEG_COMMENT} { BEGIN(COMM); }
<COMM>{END_COMMENT} { BEGIN(N); }
<COMM><<EOF>> { ReportError::UntermComment(); return 0; }
<COMM>. { /* ignore */ }
{SINGLE_COMMENT} { /* skip to the end of the line */ }

 /* keywords */

void { return T_Void; }
int  { return T_Int; }
double  { return T_Double; }
bool  { return T_Bool; }
string { return T_String; }
class { return T_Class; }
interface { return T_Interface; }
null { return T_Null; }
this { return T_This; }
extends { return T_Extends; }
implements { return T_Implements; }
for { return T_For; }
while { return T_While; }
if { return T_If; }
else { return T_Else; }
return { return T_Return; }
break { return T_Break; }
new { return T_New; }
NewArray { return T_NewArray; }
Print { return T_Print; }
ReadInteger { return T_ReadInteger; }
ReadLine { return T_ReadLine; }
"[]"     { return T_Dims; }
"=="      { return T_Equal; }
"!="     { return T_NotEqual; }
"<="     { return T_LessEqual; }
">="     { return T_GreaterEqual; }
"&&"     { return T_And; }
"||"     { return T_Or; }

{DOUBLE} { yylval.doubleConstant = strtod(yytext, NULL); return T_DoubleConstant; }
{INT_HEX} { yylval.integerConstant = htoi(yytext); return T_IntConstant; }
{INT_DEC} { yylval.integerConstant = atoi(yytext); return T_IntConstant; }
{BOOL} { yylval.boolConstant = strcmp(yytext, "true") == 0 ? true : false; return T_BoolConstant; }
{OP}   { return *yytext; }
{IDENT} {
  if (strlen(yytext) > MaxIdentLen) {
    ReportError::LongIdentifier(&yylloc, yytext);
  }
  yylval.identifier = strndup(yytext, MaxIdentLen); return T_Identifier;
}
{STRING} { yylval.stringConstant = strdup(yytext); return T_StringConstant; }
{BEG_STR} { ReportError::UntermString(&yylloc, yytext); }

 /* default rule (error) */
. { ReportError::UnrecogChar(&yylloc, *yytext); }


%%
/* The closing %% above marks the end of the Rules section and the beginning
 * of the User Subroutines section. All text from here to the end of the
 * file is copied verbatim to the end of the generated lex.yy.c file.
 * This section is where you put definitions of helper functions.
 */


/* Function: InitScanner
 * ---------------------
 * This function will be called before any calls to yylex().  It is designed
 * to give you an opportunity to do anything that must be done to initialize
 * the scanner (set global variables, configure starting state, etc.). One
 * thing it already does for you is assign the value of the global variable
 * yy_flex_debug that controls whether flex prints debugging information
 * about each token and what rule was matched. If set to false, no information
 * is printed. Setting it to true will give you a running trail that might
 * be helpful when debugging your scanner. Please be sure the variable is
 * set to false when submitting your final version.
 */
void InitScanner()
{
    PrintDebug("lex", "Initializing scanner");
    yy_flex_debug = false;
    BEGIN(N);
    yy_push_state(COPY);
    curLineNum = 1;
    curColNum = 1;
}


/* Function: DoBeforeEachAction()
 * ------------------------------
 * This function is installed as the YY_USER_ACTION. This is a place
 * to group code common to all actions.
 */
static void DoBeforeEachAction()
{
  yylloc.first_line = curLineNum;
  yylloc.first_column = curColNum;
  yylloc.last_column = curColNum + yyleng - 1;
  curColNum += yyleng;
}
