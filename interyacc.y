%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#define LIMIT 1024
//	extern int lineno = 0;
	void yyerror(const char*);
	int yylex();
	int temp_no = 0;
	int label = 0;
	FILE *outfile;
	void arithmetic_gen(char op[5]);
	void display_stack();
	void push(char *);
	char *pop();
	void label_push(int);
	char *label_pop();
	char sw_var[10];
	int next = 0;
	typedef struct Stack {
		char *items[LIMIT];
		int top;
	}Stack;
	Stack stack;
	Stack label_stack;
	
%}
%union
{
	char string[128];
}
%token HASH INCLUDE DEFINE STDIO STDLIB MATH STRING TIME
%token	IDENTIFIER INTEGER_LITERAL STRING_LITERAL HEADER_LITERAL FLOAT_LITERAL
%token	INC_OP DEC_OP LE_OP GE_OP EQ_OP NE_OP
%token	ADD_ASSIGN SUB_ASSIGN
%token	CHAR INT FLOAT VOID MAIN
%token	STRUCT BREAK DEFAULT CONTINUE CASE SWITCH
%token	FOR 
%type <string> IDENTIFIER INTEGER_LITERAL STRING_LITERAL HEADER_LITERAL FLOAT_LITERAL
%type <string> primary_expression postfix_expression unary_expression multiplicative_expression
%type <string> additive_expression relational_expression equality_expression conditional_expression assignment_expression
%type <string> expression constant_expression declaration init_declarator_list init_declarator type_specifier
%type <string> statement compound_statement block_item_list block_item expression_statement iteration_statement translation_unit external_declaration selection_statement case_statement_list case_statement break_statement default_line 


%start translation_unit
%%
headers
	: HASH INCLUDE HEADER_LITERAL 
	| HASH INCLUDE '<' libraries '>'
	;
libraries
	: STDIO
	| STDLIB
	| MATH
	| STRING
	| TIME
	;
primary_expression
	: IDENTIFIER	{push($1); strcpy($$, $1);}
	| INTEGER_LITERAL {push($1); strcpy($$, $1);}
	| FLOAT_LITERAL {push($1); strcpy($$, $1);}
	| STRING_LITERAL {push($1); strcpy($$, $1);}	
	| '(' expression ')' {strcpy($$, $2);}
	;
postfix_expression
	: primary_expression	{strcpy($$, $1);}
	| postfix_expression '(' ')'
	| postfix_expression '.' IDENTIFIER
	| postfix_expression INC_OP {push($1); push("1"); arithmetic_gen("+"); fprintf(outfile, "%s = %s\n", pop(), pop());}
	| postfix_expression DEC_OP {push($1); push("1"); arithmetic_gen("-"); fprintf(outfile, "%s = %s\n", pop(), pop());}
	| INC_OP primary_expression {push($2); push("1"); arithmetic_gen("+"); fprintf(outfile, "%s = %s\n", pop(), pop());}
	| DEC_OP primary_expression {push($2); push("1"); arithmetic_gen("-"); fprintf(outfile, "%s = %s\n", pop(), pop());}
	;
unary_expression
	: postfix_expression 	{strcpy($$, $1);}
	| '+' unary_expression {char temp[5]; strcpy(temp, pop()); push("0"); push(temp); arithmetic_gen("+");}
	| '-' unary_expression {char temp[5]; strcpy(temp, pop()); push("0"); push(temp); arithmetic_gen("-");}
	;
multiplicative_expression
	: unary_expression
	| multiplicative_expression '*' unary_expression {arithmetic_gen("*");}
	| multiplicative_expression '/' unary_expression {arithmetic_gen("/");}
	| multiplicative_expression '%' unary_expression {arithmetic_gen("%");}
	;
additive_expression
	: multiplicative_expression
	| additive_expression '+' multiplicative_expression {arithmetic_gen("+");}
	| additive_expression '-' multiplicative_expression {arithmetic_gen("-");}
	;
relational_expression
	: additive_expression
	| relational_expression '<' additive_expression {arithmetic_gen("<");}
	| relational_expression '>' additive_expression {arithmetic_gen(">");}
	| relational_expression LE_OP additive_expression {arithmetic_gen("<=");}
	| relational_expression GE_OP additive_expression {arithmetic_gen(">=");}
	;
equality_expression
	: relational_expression 
	| equality_expression EQ_OP relational_expression {arithmetic_gen("==");}
	| equality_expression NE_OP relational_expression {arithmetic_gen("!=");}
	;
conditional_expression
	: equality_expression 
	| equality_expression {fprintf(outfile, "ifFalse %s goto L%d\n", pop(), ++label); char temp[5]; sprintf(temp, "t%d", temp_no++); push(temp);} '?' expression {gen_true_code();} ':' conditional_expression {gen_false_code();}
	;
assignment_expression
	: conditional_expression
	| unary_expression '=' assignment_expression  {fprintf(outfile, "%s = %s\n", pop(), pop());}
	| unary_expression ADD_ASSIGN assignment_expression  {arithmetic_gen("+"); fprintf(outfile, "%s = %s\n", $1, pop());}
	| unary_expression SUB_ASSIGN assignment_expression  {arithmetic_gen("-"); fprintf(outfile, "%s = %s\n", $1, pop());}
	;
expression
	: assignment_expression 
	| expression ',' assignment_expression
	;
constant_expression
	: conditional_expression
	;
declaration
	: type_specifier ';'
	| type_specifier init_declarator_list ';'
	;
init_declarator_list
	: init_declarator
	| init_declarator_list ',' init_declarator
	;
init_declarator
	: IDENTIFIER {push($1);} '=' assignment_expression {strcpy($$, $1);fprintf(outfile, "%s = %s\n", $1, pop());}
	| IDENTIFIER {push($1); strcpy($$, $1);}
	;
type_specifier
	: VOID
	| CHAR
	| INT
	| FLOAT
	;
statement
	: compound_statement
	| expression_statement
	| iteration_statement
	| selection_statement
	;
compound_statement
	:'{' block_item_list '}'
	;
block_item_list
	: block_item
	| block_item_list block_item
	;
block_item
	: declaration
	| statement
	;
expression_statement
	: ';'
	| expression ';'
	;
iteration_statement 		
	: FOR '(' expression_statement {fprintf(outfile, "L%d :\n", ++label);} expression_statement {fprintf(outfile, "ifFalse %s goto L%d\ngoto L%d\nL%d : \n", pop(), label+3, label+1, label+2); label_push(label+2); label_push(label+3); label_push(label+1); label_push(label);} expression {fprintf(outfile, "goto %s\n", label_pop()); label += 3;}')' {fprintf(outfile, "%s :\n", label_pop());} statement {fprintf(outfile, "goto %s\n%s : \n", label_pop(), label_pop());}
	;
translation_unit
	: external_declaration
	| translation_unit external_declaration
	;

selection_statement	
	: SWITCH '(' expression {strcpy(sw_var, pop());next++;}')' '{' case_statement_list '}'{fprintf(outfile, "next%d :\n",next);}
	;
case_statement_list
	: case_statement 
	| case_statement break_statement case_statement_list
	| case_statement case_statement_list 
	| default_line
	| break_statement
	;
case_statement
	: CASE constant_expression
{fprintf(outfile, "L%d :\n", ++label);push(sw_var);arithmetic_gen("==");fprintf(outfile, "ifFalse %s goto L%d\n",pop(),label+5);}':' block_item_list
	;
	
break_statement
	: BREAK ';' {fprintf(outfile, "goto next%d\n",next);}
	;
default_line
	: DEFAULT ':' {fprintf(outfile, "L%d :\n",++label);} block_item_list 
	;
external_declaration
	: INT MAIN '(' ')' compound_statement
	| declaration
	| headers 	
	;
%%
void yyerror(const char *str)
{
	fflush(stdout);
	fprintf(stderr, "%s at line\n", str);
}
int main(){
	stack.top = -1;
	push("$");
	outfile = fopen("output_file.txt", "w");
	if (yyparse() != 0)
	{
		printf("Parse failed\n");
		exit(0);
	}
	printf("success\n");
	int i = 0;
	fclose(outfile);
	system("cat output_file.txt");
	return 0;
}
void push(char *str)
{
	stack.items[++stack.top] = (char*)malloc(LIMIT);
	strcpy(stack.items[stack.top], str);
}
char *pop()
{
	if (stack.top <= -1) {
		printf("\nError in evaluating expression\n");
		exit(0);
	}
	char *str = (char*)malloc(LIMIT);
	strcpy(str, stack.items[stack.top--]);
	free(stack.items[stack.top+1]);
	return str;
}
char *top(int off)
{
	return stack.items[stack.top-off];
}
void arithmetic_gen(char op[5])
{
	char temp[5];
	sprintf(temp,"t%d",temp_no++);
  	fprintf(outfile,"%s = %s %s %s\n",temp,top(1),op,top(0));
	pop(); pop(); push(temp);
}
void display_stack()
{
	int i;
	for(i=0; i<=stack.top; i++)
		printf("%s ", stack.items[i]);
		printf("\n");
}
void gen_true_code()
{
	if (stack.top > -1)
	{
		fprintf(outfile, "%s = %s\ngoto L%d\n", top(0), pop(), label+1);
		label_push(label+1);
		fprintf(outfile, "L%d :\n", label);
		label_push(label+1);
	}
	else
		fprintf(outfile, "%s\ngoto L%d\n", pop(), ++label);
}
void gen_false_code()
{
	if (stack.top > -1)
	{
		fprintf(outfile, "%s = %s\ngoto %s\n", top(0), pop(), label_pop());
		fprintf(outfile, "%s :\n", label_pop());
		label++;
	}
	else
		fprintf(outfile, "%s\ngoto L%d\n", pop(), label-1);
}
void label_push(int label)
{
	char temp[5];
	sprintf(temp, "L%d", label);
	label_stack.items[++label_stack.top] = malloc(LIMIT);
	strcpy(label_stack.items[label_stack.top], temp);
	
}
char *label_pop()
{
	if (label_stack.top <= -1) {
		printf("\nError in evaluating expression\n");
		exit(0);
	}
	char *str = (char*)malloc(LIMIT);
	strcpy(str, label_stack.items[label_stack.top--]);
	free(label_stack.items[label_stack.top+1]);
	return str;
}
