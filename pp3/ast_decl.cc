/* File: ast_decl.cc
 * -----------------
 * Implementation of Decl node classes.
 */
#include "ast_decl.h"
#include "ast_type.h"
#include "ast_stmt.h"
#include "scope.h"


Decl::Decl(Identifier *n) : Node(*n->GetLocation()) {
    Assert(n != NULL);
    (id=n)->SetParent(this);
}


VarDecl::VarDecl(Identifier *n, Type *t) : Decl(n) {
    Assert(n != NULL && t != NULL);
    (type=t)->SetParent(this);
}

void VarDecl::PrintChildren(int indentLevel) {
   type->Print(indentLevel+1);
   id->Print(indentLevel+1);
}

void VarDecl::BuildDecls() {
    Scope *s = GetScope();
    s->AddSym(GetName(), this);
}

ClassDecl::ClassDecl(Identifier *n, NamedType *ex, List<NamedType*> *imp, List<Decl*> *m) : Decl(n) {
    // extends can be NULL, impl & mem may be empty lists but cannot be NULL
    Assert(n != NULL && imp != NULL && m != NULL);
    extends = ex;
    if (extends) extends->SetParent(this);
    (implements=imp)->SetParentAll(this);
    (members=m)->SetParentAll(this);
}

void ClassDecl::PrintChildren(int indentLevel) {
    id->Print(indentLevel+1);
    if (extends) extends->Print(indentLevel+1, "(extends) ");
    implements->PrintAll(indentLevel+1, "(implements) ");
    members->PrintAll(indentLevel+1);
}

void ClassDecl::BuildDecls() {
    Scope *curScope = GetScope();
    curScope->AddSym(GetName(), this);
    Scope *newScope = new Scope(curScope);
    newScope->SetDecl(this);
    for (int i = 0; i < members->NumElements(); i++) {
        Decl *d = members->Nth(i);
        d->SetScope(newScope);
        d->BuildDecls();
    }
}

InterfaceDecl::InterfaceDecl(Identifier *n, List<Decl*> *m) : Decl(n) {
    Assert(n != NULL && m != NULL);
    (members=m)->SetParentAll(this);
}

void InterfaceDecl::PrintChildren(int indentLevel) {
    id->Print(indentLevel+1);
    members->PrintAll(indentLevel+1);
}

void InterfaceDecl::BuildDecls() {
    Scope *curScope = GetScope();
    curScope->AddSym(GetName(), this);
    Scope *newScope = new Scope(curScope);
    newScope->SetDecl(this);
    for (int i = 0; i < members->NumElements(); i++) {
        Decl *d = members->Nth(i);
        d->SetScope(newScope);
        d->BuildDecls();
    }
}

FnDecl::FnDecl(Identifier *n, Type *r, List<VarDecl*> *d) : Decl(n) {
    Assert(n != NULL && r!= NULL && d != NULL);
    (returnType=r)->SetParent(this);
    (formals=d)->SetParentAll(this);
    body = NULL;
}

void FnDecl::SetFunctionBody(Stmt *b) {
    (body=b)->SetParent(this);
}

void FnDecl::PrintChildren(int indentLevel) {
    returnType->Print(indentLevel+1, "(return type) ");
    id->Print(indentLevel+1);
    formals->PrintAll(indentLevel+1, "(formals) ");
    if (body) body->Print(indentLevel+1, "(body) ");
}

void FnDecl::BuildDecls() {
    Scope *curScope = GetScope();
    curScope->AddSym(GetName(), this);
    Scope *newScope = new Scope(curScope);
    newScope->SetDecl(this);
    for (int i = 0; i < formals->NumElements(); i++) {
        VarDecl *var = formals->Nth(i);
        var->SetScope(newScope);
    }
    body->SetScope(newScope);
    body->BuildDecls();
}
