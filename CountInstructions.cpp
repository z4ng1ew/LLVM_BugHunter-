#include <llvm/Pass.h>
#include <llvm/IR/Function.h>
#include <llvm/Support/raw_ostream.h>

using namespace llvm;

namespace {
    struct CountInstructions : public FunctionPass {
        static char ID;
        CountInstructions() : FunctionPass(ID) {}

        bool runOnFunction(Function &F) override {
            unsigned InstCount = 0;
            for (auto &BB : F) {
                InstCount += BB.size();
            }
            errs() << "Function " << F.getName() << " has " << InstCount << " instructions.\n";
            return false;
        }
    };
}

char CountInstructions::ID = 0;
static RegisterPass<CountInstructions> X("countinsts", "Count Instructions Pass");

