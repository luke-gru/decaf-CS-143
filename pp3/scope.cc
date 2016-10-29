#include "scope.h"

Scope *Scope::globalScope = new Scope(NULL);

Decl* Scope::FindSym(const char *name) {
    Scope *curScope = this;
    while (curScope != NULL) {
        Decl* decl = curScope->FindSym(name);
        if (decl) {
            return decl;
        } else {
            curScope = curScope->parent;
        }
    }
    return NULL;
}
