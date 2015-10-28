%{
#include <cstdio>
#include<string>
#define YY_DECL extern "C" int yylex()
#include "conf.tab.h"
unsigned long pos = 0;
struct _string {
                unsigned long pos;
                char* value;
        };
void set_val() {
	yylval.string.value = strdup(yytext); yylval.string.pos = pos; pos += strlen(yytext);
}
%}
%%
[a-zA-Z][a-zA-Z0-9]*    set_val(); return WORD;
\"                      set_val(); return QUOTE;
\{                      set_val(); return OBRACE;
\}                      set_val(); return EBRACE;
;                       set_val(); return SEMICOLON;
\n                      pos++;
.			pos++;
%%
