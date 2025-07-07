#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/IRBuilder.h>
#include <iostream>

int main() {
    // Создаем контекст и модуль
    llvm::LLVMContext Context;
    llvm::Module *Module = new llvm::Module("my_module", Context);

    // Определяем тип функции: int(int, int)
    llvm::FunctionType *FuncType = llvm::FunctionType::get(
        llvm::Type::getInt32Ty(Context),
        {llvm::Type::getInt32Ty(Context), llvm::Type::getInt32Ty(Context)},
        false
    );

    // Создаем функцию "add"
    llvm::Function *AddFunc = llvm::Function::Create(
        FuncType, llvm::Function::ExternalLinkage, "add", Module
    );

    // Добавляем аргументы
    llvm::Argument *A = AddFunc->arg_begin();
    A->setName("a");
    llvm::Argument *B = A + 1;
    B->setName("b");

    // Создаем базовый блок
    llvm::BasicBlock *BB = llvm::BasicBlock::Create(Context, "entry", AddFunc);
    llvm::IRBuilder<> Builder(BB);

    // Выполняем сложение
    llvm::Value *Sum = Builder.CreateAdd(A, B, "sum");
    Builder.CreateRet(Sum);

    // Выводим IR
    Module->print(llvm::outs(), nullptr);
    delete Module;
    return 0;
}
