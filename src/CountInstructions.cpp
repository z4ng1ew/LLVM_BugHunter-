#include <llvm/Pass.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/Module.h>
#include <llvm/Support/raw_ostream.h>

using namespace llvm;

namespace {
    struct CountInstructions : public ModulePass {
        static char ID;
        CountInstructions() : ModulePass(ID) {}

        bool runOnModule(Module &M) override {
            unsigned totalInstructions = 0;
            
            for (Function &F : M) {
                // Пропускаем объявления функций
                if (F.isDeclaration()) continue;
                
                unsigned functionInstructions = 0;
                for (BasicBlock &BB : F) {
                    functionInstructions += BB.size();
                }
                
                errs() << "Function " << F.getName() << " has " 
                       << functionInstructions << " instructions.\n";
                totalInstructions += functionInstructions;
            }
            
            errs() << "Module " << M.getName() << " has " 
                   << totalInstructions << " total instructions.\n";
            return false;
        }
    };
}

char CountInstructions::ID = 0;
static RegisterPass<CountInstructions> X("countinsts", "Count Instructions Pass");
