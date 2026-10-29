#include "verilated.h"
#include "Vtb_rv32i_core.h"
#if VM_COVERAGE
#include "verilated_cov.h"
#endif

int main(int argc, char** argv, char**) {
    Verilated::debug(0);
    const std::unique_ptr<VerilatedContext> contextp{new 
VerilatedContext};
    contextp->traceEverOn(true);
    contextp->commandArgs(argc, argv);

    const std::unique_ptr<Vtb_rv32i_core> topp{new 
Vtb_rv32i_core{contextp.get()}};

    while (!contextp->gotFinish()) {
        topp->eval();
        if (!topp->eventsPending()) break;
        contextp->time(topp->nextTimeSlot());
    }

    topp->final();

#if VM_COVERAGE
    contextp->coveragep()->write("coverage.dat");
#endif
    return 0;
}
