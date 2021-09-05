%{
	#include <stdio.h>
	#include "y.tab.h"

	//#define YY_USER_ACTION yylloc.first_line = yylloc.last_line = yylineno;

	extern void yyerror(const char *);  /* prints grammar violation message */

	static void comment(void);
%}

%option yylineno

D   		[0-9]
L   		[a-zA-Z_]
A   		[a-zA-Z_0-9]
WS  		[ \t\v\n\f]


%%
"/*"		{ comment(); }
"//"[^\n]*	{ /* Consume Comment */ }


int		{ return(INT); }
float		{ return(FLOAT); }
char		{ return(CHAR); }
void		{ return(VOID); }
main		{ return(MAIN); }

struct		{ return(STRUCT); }

"#"		{ return HASH; }
include		{ return INCLUDE; }
define		{ return DEFINE; }

"math.h"	{ return MATH; }
"stdio.h"	{ return STDIO; }
"stdlib.h"	{ return STDLIB; }
"string.h"	{ return STRING; }
"time.h"	{ return TIME; }

for		{ return(FOR); }
switch		{ return (SWITCH);}
case		{ return (CASE);}
break		{ return (BREAK);}
default		{ return (DEFAULT);}
continue	{ return (CONTINUE);}

{L}{A}*						{ strcpy(yylval.string,yytext); return IDENTIFIER;}
{L}{A}*\.{L}{A}*				{ strcpy(yylval.string,yytext); return IDENTIFIER;}
{D}+						{ strcpy(yylval.string,yytext); return INTEGER_LITERAL;}
{D}+\.{D}+					{ strcpy(yylval.string,yytext); return FLOAT_LITERAL;}
\"{A}+(".h"|".c")\"				{return HEADER_LITERAL;}
L?\"(\\.|[^\\"])*\"	{ return(STRING_LITERAL); }

	/* Assignment Operators */
"+="		{return(ADD_ASSIGN); }
"-="		{return(SUB_ASSIGN); }


	/* Relational Operators */
"++"		{return(INC_OP); }
"--"		{return(DEC_OP); }
"<="		{return(LE_OP); }
">="		{return(GE_OP); }
"=="		{return(EQ_OP); }
"!="		{return(NE_OP); }

	/* Basic Syntax */
";"		{return(';'); }
"{"	{return('{'); }
"}"	{return('}'); }
","		{return(','); }
":"		{return(':'); }
"="		{return('='); }
"("		{return('('); }
")"		{return(')'); }
("["|"<:")	{return('['); }
("]"|":>")	{return(']'); }
"."		{return('.'); }
"&"		{return('&'); }
"!"		{return('!'); }
"~"		{return('~'); }
"-"		{return('-'); }
"+"		{return('+'); }
"*"		{return('*'); }
"/"		{return('/'); }
"%"		{return('%'); }
"<"		{return('<'); }
">"		{return('>'); }
"^"		{return('^'); }
"|"		{return('|'); }
"?"		{return('?'); }


{WS}+		{ /* whitespace separates tokens */}
	
.		{ printf("No Match, Invalid Expression %s\n", yytext); }
%%

int yywrap(void)
{
	return 1;
}


static void comment(void)
{
    int c;

    while ((c = input()) != 0)
        if (c == '*')
        {
            while ((c = input()) == '*')
                ;

            if (c == '/')
                return;

            if (c == 0)
                break;
        }
    yyerror("unterminated comment");
}
