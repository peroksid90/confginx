all:
	bison -d conf.y 
	flex conf.l 
	g++ conf.tab.c lex.yy.c --std=c++11 -lfl -ggdb
