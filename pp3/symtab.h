#ifndef _H_symtab
#define _H_symtab

#include "hashtable.h"
#include "ast_decl.h"

class SymTab
{
    protected:
      Hashtable<Decl*> *tab;
    public:
      SymTab() { tab = new Hashtable<Decl*>(); }
      Decl* Find(const char *ident) { return tab->Lookup(ident); }
      void Add(const char *ident, Decl *decl) { tab->Enter(ident, decl, true); }
};

#endif
