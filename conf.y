%{
#include<string>
#include<iostream>
#include<memory>
#include<vector>
#include<fstream>
#include<sstream>
#include<string>
extern "C" int yylex();
extern "C" int yyparse();
extern "C" FILE *yyin;
 
void yyerror(const char *s);

std::string config;

class BaseDirective {
public:
	BaseDirective(const std::string& name, const std::vector<std::string>& params = std::vector<std::string>()) {
                SetName(name);
                SetParams(params);
	}

	BaseDirective(const std::string& name, const std::string param) {
	        std::vector<std::string> params;
                params.push_back(param);
                BaseDirective(name, params);
	}

	
	void SetName2(const std::string& name) {
		if(name.size() == _name.size())
			config.replace(_pos_name, name.size(), name);
		else if (name.size() < _name.size()) {
			config.erase(_pos_name, _name.size() - name.size());
			config.insert(_pos_name, name);
		} else if(name.size() > _name.size()) {
			config.erase(_pos_name, _name.size());
			config.insert(_pos_name, name);
		}
		_name = name;
	}

	void SetName(const std::string& name) {
		_name = name;
	}
	void SetParams(const std::vector<std::string>& params) {
		_params = params;
	}
	const std::string& GetName() const {
		return _name;
	}
	const std::vector<std::string>& GetParams() const {
		return _params;
	}

	virtual void Delete() {
	}

	BaseDirective& SetPosName(unsigned long pos) {
		_pos_name = pos;
		return *this;
	}

	BaseDirective& SetPosParams(unsigned long pos) {
		_pos_params = pos;
		return *this;
	}
	
	std::string _name;
	std::vector<std::string> _params;
	unsigned long _pos_name;
	unsigned long _pos_params;
};

class Directive : public BaseDirective {
public:
	Directive(const std::string& name, const std::vector<std::string>& params = std::vector<std::string>()) : BaseDirective(name, params), _pos_semicl(0) {}
	Directive(const std::string& name, const std::string& param) : BaseDirective(name, param), _pos_semicl(0) {}
	Directive& SetPosSemicl(unsigned long pos) {
		std::cout << "_pos_semicl " << _pos_semicl << std::endl;
		_pos_semicl = pos;
		return *this;
	}
	virtual void Delete() {}

	unsigned long _pos_semicl;
};

class Block : public BaseDirective {
public:
	Block() : BaseDirective("",""), _pos_ebrace(0), _pos_obrace(0), prev(NULL) {}

	Block(const std::string& name, const std::vector<std::string>& params = std::vector<std::string>()) : BaseDirective(name, params), _pos_ebrace(0), _pos_obrace(0), prev(NULL) {}

	Block& SetBlock2(const std::string& name, const std::vector<std::string>& params = std::vector<std::string>()) {
		Block *block = FindBlock(name, params);
		if (block) {
			std::cout << "block found\n" << std::endl;
			return *block;
		}
		
		size_t insert_pos = 0;	
                size_t last_direct_pos = std::string::npos;
                size_t last_block_pos = std::string::npos;

                if ( !directives.empty() ) {
                        last_direct_pos = directives.back()._pos_semicl;
                }
                if ( !blocks.empty() ) {
                        last_block_pos = blocks.back()._pos_ebrace;
                }
                size_t pos = std::min(last_direct_pos, last_block_pos);
		std::string insert_string = name + " {}\n";

		for(Block* iter = prev; iter; iter = iter->prev) {
			insert_string = "\t" + insert_string + "\t";
		}
		size_t last_tab = insert_string.rfind("\t", insert_string.size());
		if(last_tab != std::string::npos) {
			insert_string[last_tab] = 0;
			insert_string = insert_string.c_str();
		}

                if (pos == std::string::npos) {
                        insert_pos = _pos_ebrace;
                        if (config.find("\n", _pos_obrace, _pos_ebrace - _pos_obrace) != std::string::npos)
                                insert_string = '\n' + insert_string;
                } else {
                        insert_pos = config.find(pos, '\n');
                        if (insert_pos != std::string::npos) {
                                insert_pos++;
                        } else {
                                insert_string = '\n' + insert_string;
                                insert_pos = ++pos;
                        }
                }

		if(config.size() <= insert_pos)
			config.resize(insert_pos + 1);
		
		config.insert(insert_pos, insert_string);
		Block new_block(name, params);
		new_block._pos_obrace = config.find("{", insert_pos);
		new_block._pos_ebrace = config.find("}", insert_pos);
		new_block.SetPosName(++insert_pos);
		std::cout << "new_block._pos_obrace " << new_block._pos_obrace << std::endl; 
		std::cout << "new_block._pos_ebrace " << new_block._pos_ebrace << std::endl; 
		new_block.prev = this;
		blocks.push_back( new_block );
		return blocks.back();
	}

	Block& SetBlock(const std::string& name, const std::vector<std::string>& params = std::vector<std::string>()) {
		blocks.push_back( Block(name, params) );
		return blocks.back();
	}
	
	Directive& SetDirective2(const std::string& name, const std::string& param) {
		std::vector<std::string> params;
		params.push_back(param);
		Directive* direct = FindDirective(name, params);
		if (direct) return *direct;

		size_t insert_pos = 0;
                std::string insert_string = name + " " + param + ";\n";
		
		for(Block* iter = prev; iter; iter = iter->prev) {
			insert_string = "\t" + insert_string + "\t";
		}

		size_t last_tab = insert_string.rfind("\t", insert_string.size());
		if(last_tab != std::string::npos) {
			insert_string[last_tab] = 0;
			insert_string = insert_string.c_str();
		}

		size_t last_direct_pos = std::string::npos;
		size_t last_block_pos = std::string::npos;

                if ( !directives.empty() ) {
                        last_direct_pos = directives.back()._pos_semicl;
		}
		if ( !blocks.empty() ) {
			last_block_pos = blocks.back()._pos_ebrace;
		}
		size_t pos = std::min(last_direct_pos, last_block_pos);
		if (pos == std::string::npos) {
			insert_pos = _pos_ebrace;
			if (config.find("\n", _pos_obrace, _pos_ebrace - _pos_obrace) != std::string::npos)
				insert_string = '\n' + insert_string; 
		} else {
			insert_pos = config.find(pos, '\n');
                	if (insert_pos != std::string::npos) {
                        	insert_pos++;
                	} else {
                        	insert_string = '\n' + insert_string;
                        	insert_pos = ++pos;
                	}
		}
                if(config.size() <= insert_pos)
                        config.resize(insert_pos + 1);
                config.insert(insert_pos, insert_string);

		Directive new_direct(name, param);
		size_t pos_name = ++insert_pos;
		new_direct.SetPosName(pos_name);
		new_direct.SetPosSemicl( config.find(";", pos_name) );
		directives.push_back( new_direct );
                return directives.back();
	}

	Directive& SetDirective(const std::string& name, const std::string& param) {
		directives.push_back( Directive(name, param) );
                return directives.back();
	}

	Directive& SetDirective(const std::string& name, const std::vector<std::string>& params) {
		directives.push_back( Directive(name, params) );
		return directives.back();
	}

	Block* FindBlock(const std::string& name, const std::vector<std::string>& params) {
		for(auto block = blocks.begin(); block != blocks.end(); block++) {
			if (block->GetName() == name && block->GetParams() == params)
				return &*block;
		}
		return NULL;
	}
	Directive* FindDirective(const std::string& name, const std::vector<std::string>& params) {
		for(auto directive = directives.begin(); directive != directives.end(); directive++) {
			if (directive->GetName() == name && directive->GetParams() == params)
				return &*directive;
		}
		return NULL;
	}

	Block& SetPosEbrace(unsigned long pos) {
		_pos_ebrace = pos;
		std::cout << "SetPosEbrace " << _pos_ebrace << std::endl;
		return *this; 
	}

	Block* prev;
	virtual void Delete() {}
	
	unsigned long _pos_ebrace;
	unsigned long _pos_obrace;
	std::vector<Block> blocks;
	std::vector<Directive> directives;
};

class Nginx {
public:
	Nginx() {
		current = &main;
	}
	Block main;
	Block* current;
};
Nginx* nginx;

/*
std::vector<std::string> params;
params.push_back("\"${remote_addr}AAA\"");
params.push_back("$variant");
Config.SetBlock("http").SetBlock("split_clients", params).SetDirective("10%", "cdn1.");
Config.SetBlock("http").SetBlock("split_clients", params).SetDirective("50%", "cdn2.");
params.clear();
params.push_back("^");
params.push_back("http://${variant}<DOMAIN>$request_uri");
params.push_back("permanent");
Config.SetBlock("server").SetBlock("location", "/").SetBlock("if", "($host !~ ^(\w+\.<DOMAIN>$))").SetDirective("rewrite", params);
*/
%}
%union {
	struct _string {
		unsigned long pos;
		char* value;
	} string;
}
%token<string> WORD;
%token<string> EBRACE;
%token<string> OBRACE;
%token<string> SEMICOLON;
%token<string> QUOTE;
%%
config: 		sections_and_options
			;
sections_and_options:
			sections_and_options section_or_option 
			| section_or_option
			;
section_or_option:
			section
			| option
			;
section:
			WORD OBRACE 
				    { 
				      Block& block = nginx->current->SetBlock($1.value);
				      block.prev = nginx->current;
				      nginx->current = &block; 
				    } 
			sections_and_options EBRACE 
				   { 
				     std::cout << "Block name pos: " << $1.pos << std::endl;
				     std::cout << "Block ebrace pos: " << $5.pos << std::endl;
				     nginx->current->SetPosEbrace($5.pos).SetPosName($1.pos);
				     nginx->current->_pos_obrace = $2.pos;
				     nginx->current = nginx->current->prev;
				   }
			;
option:
			WORD WORD SEMICOLON { nginx->current->SetDirective($1.value, $2.value)
								.SetPosSemicl($3.pos).SetPosName($1.pos)
								.SetPosParams($2.pos); 
					    std::cout << "Directive semicolon pos: " << $3.pos << std::endl;
					    std::cout << "Directive name pos: " << $1.pos << std::endl;
					    std::cout << "Directive params pos: " << $2.pos << std::endl;
					    }
			;

%%
int main(int, char**) {
	Nginx ng;
	nginx = &ng;
	FILE *myfile = fopen("conf.file", "r");
	if (!myfile) {
		std::cout << "I can't open conf.file!" << std::endl;
		return -1;
	}
	yyin = myfile;
	do {
		yyparse();
	} while (!feof(yyin));
	std::ifstream ifs("./conf.file");
	std::stringstream stream;
	stream << ifs.rdbuf();
	config = stream.str();
	nginx->main.SetBlock2("nested").SetBlock2("nested2").SetBlock2("nested3").SetBlock2("nested4").SetDirective2("direct", "param");
	nginx->main.SetBlock2("nested").SetBlock2("nested2").SetBlock2("nested3").SetBlock2("nested4").SetDirective2("direct2", "param2");
	nginx->main.SetBlock2("nested").SetBlock2("nested2").SetBlock2("nested3").SetDirective2("direct2", "param2");
	std::cout <<  config << std::endl;
}

void yyerror(const char *s) {
	std::cout << "Parse error!  Message: " << s << std::endl;
	exit(-1);
}
