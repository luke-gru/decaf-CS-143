/* File: ast_stmt.cc
 * -----------------
 * Implementation of statement node classes.
 */
#include "ast_stmt.h"
#include "ast_type.h"
#include "ast_decl.h"
#include "ast_expr.h"
#include "scope.h"


Program::Program(List<Decl*> *d) {
    Assert(d != NULL);
    (decls=d)->SetParentAll(this);
}

void Program::PrintChildren(int indentLevel) {
    decls->PrintAll(indentLevel+1);
    printf("\n");
}

void Program::BuildDecls() {
    SetScope(Scope::globalScope);
    for (int i = 0; i < decls->NumElements(); i++) {
        Decl *d = decls->Nth(i);
        d->BuildDecls();
    }
}

void Program::TypeCheck() {
    // TODO
}

StmtBlock::StmtBlock(List<VarDecl*> *d, List<Stmt*> *s) {
    Assert(d != NULL && s != NULL);
    (decls=d)->SetParentAll(this);
    (stmts=s)->SetParentAll(this);
}

void StmtBlock::PrintChildren(int indentLevel) {
    decls->PrintAll(indentLevel+1);
    stmts->PrintAll(indentLevel+1);
}

void StmtBlock::BuildDecls() {
    Scope *curScope = GetScope();
    Scope *blockScope = new Scope(curScope);
    for (int i = 0; i < decls->NumElements(); i++) {
        VarDecl *var = decls->Nth(i);
        var->SetScope(blockScope);
        var->BuildDecls();
    }
    for (int i = 0; i < stmts->NumElements(); i++) {
        Stmt *stmt = stmts->Nth(i);
        stmt->SetScope(blockScope);
        stmt->BuildDecls();
    }
}

ConditionalStmt::ConditionalStmt(Expr *t, Stmt *b) {
    Assert(t != NULL && b != NULL);
    (test=t)->SetParent(this);
    (body=b)->SetParent(this);
}

void ConditionalStmt::BuildDecls() {
    test->BuildDecls();
    body->BuildDecls();
}

ForStmt::ForStmt(Expr *i, Expr *t, Expr *s, Stmt *b): LoopStmt(t, b) {
    Assert(i != NULL && t != NULL && s != NULL && b != NULL);
    (init=i)->SetParent(this);
    (step=s)->SetParent(this);
}

void ForStmt::PrintChildren(int indentLevel) {
    init->Print(indentLevel+1, "(init) ");
    test->Print(indentLevel+1, "(test) ");
    step->Print(indentLevel+1, "(step) ");
    body->Print(indentLevel+1, "(body) ");
}

void ForStmt::BuildDecls() {
    Scope *curScope = GetScope();
    Scope *forStepScope = new Scope(curScope);
    init->SetScope(forStepScope);
    init->BuildDecls();
    test->SetScope(forStepScope);
    test->BuildDecls();
    step->SetScope(forStepScope);
    step->BuildDecls();
    body->BuildDecls();
}

void WhileStmt::PrintChildren(int indentLevel) {
    test->Print(indentLevel+1, "(test) ");
    body->Print(indentLevel+1, "(body) ");
}

IfStmt::IfStmt(Expr *t, Stmt *tb, Stmt *eb): ConditionalStmt(t, tb) {
    Assert(t != NULL && tb != NULL); // else can be NULL
    elseBody = eb;
    if (elseBody) elseBody->SetParent(this);
}

void IfStmt::PrintChildren(int indentLevel) {
    test->Print(indentLevel+1, "(test) ");
    body->Print(indentLevel+1, "(then) ");
    if (elseBody) elseBody->Print(indentLevel+1, "(else) ");
}

void IfStmt::BuildDecls() {
    ConditionalStmt::BuildDecls();
    elseBody->BuildDecls();
}

SwitchStmt::SwitchStmt(Expr *t, List<SwitchCase*> *c, SwitchCase *defaultC) {
    (test=t)->SetParent(this);
    (cases=c)->SetParentAll(this);
    defaultCase = defaultC;
    if (defaultCase) {
        defaultCase->SetParent(this);
    }
}

void SwitchStmt::PrintChildren(int indentLevel) {
    test->Print(indentLevel+1);
    cases->PrintAll(indentLevel+1);
    if (defaultCase) {
        defaultCase->Print(indentLevel+1);
    }
}

SwitchCase::SwitchCase(IntConstant *c, List<Stmt*> *stmtsList, bool isDefaultCase) {
    (test=c)->SetParent(this);
    (stmts=stmtsList)->SetParentAll(this);
    isDefault = isDefaultCase;
}

void SwitchCase::PrintChildren(int indentLevel) {
    if (!isDefault) {
        test->Print(indentLevel+1);
    }
    stmts->PrintAll(indentLevel+1);
}

void SwitchCase::BuildDecls() {
    test->BuildDecls();
    for (int i = 0; i < stmts->NumElements(); i++) {
        Stmt *stmt = stmts->Nth(i);
        stmt->BuildDecls();
    }
}

void SwitchStmt::BuildDecls() {
    test->BuildDecls();
    for (int i = 0; i < cases->NumElements(); i++) {
        SwitchCase *c = cases->Nth(i);
        c->BuildDecls();
    }
    if (defaultCase) {
        defaultCase->BuildDecls();
    }
}

ReturnStmt::ReturnStmt(yyltype loc, Expr *e) : Stmt(loc) {
    Assert(e != NULL);
    (expr=e)->SetParent(this);
}

void ReturnStmt::PrintChildren(int indentLevel) {
    expr->Print(indentLevel+1);
}

void ReturnStmt::BuildDecls() {
    expr->BuildDecls();
}

PrintStmt::PrintStmt(List<Expr*> *a) {
    Assert(a != NULL);
    (args=a)->SetParentAll(this);
}

void PrintStmt::PrintChildren(int indentLevel) {
    args->PrintAll(indentLevel+1, "(args) ");
}

void PrintStmt::BuildDecls() {
    for (int i = 0; i < args->NumElements(); i++) {
        Expr *arg = args->Nth(i);
        arg->BuildDecls();
    }
}
