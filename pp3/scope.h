#ifndef _H_scope
#define _H_scope

#include "ast_decl.h"
#include "symtab.h"

class Scope
{
  protected:
    Scope *parent;
    Decl *decl;
    SymTab *symtab;
  public:
    Scope(Scope *p = NULL) {
        parent = p;
        symtab = new SymTab();
    }
    bool IsGlobal() { return parent == NULL; }
    void SetDecl(Decl *d) { decl = d; }
    Decl* GetDecl() { return decl; }
    static Scope *globalScope;
    Decl* FindSym(const char *name);
    void AddSym(const char *name, Decl *d) { symtab->Add(name, d); }
};

#endif
