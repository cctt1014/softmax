// DESCRIPTION: Verilator: Verilog example module
//
// This file ONLY is placed under the Creative Commons Public Domain, for
// any use, without warranty, 2017 by Wilson Snyder.
// SPDX-License-Identifier: CC0-1.0
//======================================================================

// For std::unique_ptr
#include <memory>
#include <verilated_vcd_c.h>

// Include common routines
#include <verilated.h>

// Include model header, generated from Verilating "top.v"
#include "Vsoftmax.h"

// Legacy function required only so linking works on Cygwin and MSVC++
double sc_time_stamp() { return 0; }

int main(int argc, char** argv) {
    // Create logs/ directory in case we have traces to put under it
    Verilated::mkdir("logs");

    // Construct a VerilatedContext to hold simulation time, etc.
    // Multiple modules (made later below with Vtop) may share the same
    // context to share time, or modules may have different contexts if
    // they should be independent from each other.

    // Using unique_ptr is similar to
    // "VerilatedContext* contextp = new VerilatedContext" then deleting at end.
    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
    // Do not instead make Vtop as a file-scope static variable, as the
    // "C++ static initialization order fiasco" may cause a crash

    // Set debug level, 0 is off, 9 is highest presently used
    // May be overridden by commandArgs argument parsing
    contextp->debug(0);

    // Randomization reset policy
    // May be overridden by commandArgs argument parsing
    contextp->randReset(2);

    // Verilator must compute traced signals
    contextp->traceEverOn(true);
    VerilatedVcdC	*m_trace;
    m_trace = new VerilatedVcdC;

    // Pass arguments so Verilated code can see them, e.g. $value$plusargs
    // This needs to be called before you create any model
    contextp->commandArgs(argc, argv);

    // Construct the Verilated model, from Vtop.h generated from Verilating "top.v".
    // Using unique_ptr is similar to "Vtop* top = new Vtop" then deleting at end.
    // "TOP" will be the hierarchical name of the module.
    const std::unique_ptr<Vsoftmax> top{new Vsoftmax{contextp.get(), "softmax"}};

    top->trace(m_trace, 99);
    m_trace->open("sim_softmax.vcd");

    // Set Vtop's input signals
    top->Reset = 0;
    top->Clock = 0;
    top->Start = 0;
    top->Datain = 0;
    top->N = 3;

    // Simulate until $finish
    while (contextp->time() < 100) {
        // Historical note, before Verilator 4.200 Verilated::gotFinish()
        // was used above in place of contextp->gotFinish().
        // Most of the contextp-> calls can use Verilated:: calls instead;
        // the Verilated:: versions just assume there's a single context
        // being used (per thread).  It's faster and clearer to use the
        // newer contextp-> versions.

        contextp->timeInc(1);  // 1 timeprecision period passes...
        // Historical note, before Verilator 4.200 a sc_time_stamp()
        // function was required instead of using timeInc.  Once timeInc()
        // is called (with non-zero), the Verilated libraries assume the
        // new API, and sc_time_stamp() will no longer work.

        // Toggle a fast (time/2 period) clock
        top->Clock = !top->Clock;

        // Toggle control signals on an edge that doesn't correspond
        // to where the controls are sampled; in this example we do
        // this only on a negedge of Clock, because we know
        // reset is not sampled there.
        if (!top->Clock) {
            if (contextp->time() > 1 && contextp->time() < 10) {
                top->Reset = 1;  // Assert reset
            } else {
                top->Reset = 0;  // Deassert reset
                
            }

            if (contextp->time() == 10) {
                top->Start = 1;  // Assert start
                top->Datain = 0x3f800000;
            } else if (contextp->time() == 15) {
                top->Datain = 0x3f800000;
            } else if (contextp->time() == 20) {
                top->Datain = 0x3f800000;
            } else if (contextp->time() == 30) {
                top->Start = 0;  // Assert start
            }
        }
        // Evaluate model
        // (If you have multiple models being simulated in the same
        // timestep then instead of eval(), call eval_step() on each, then
        // eval_end_step() on each. See the manual.)
        top->eval();
        m_trace->dump(contextp->time());

        // Read outputs
        // VL_PRINTF("[%" PRId64 "] Clock=%x rstl=%x iquad=%" PRIx64 " -> oquad=%" PRIx64
        //           " owide=%x_%08x_%08x\n",
        //           contextp->time(), top->Clock, top->Reset, top->in_quad, top->out_quad,
        //           top->out_wide[2], top->out_wide[1], top->out_wide[0]);
    }
    m_trace->close();

    // Final model cleanup
    top->final();



    // Final simulation summary
    // contextp->statsPrintSummary();

    // Return good completion status
    // Don't use exit() or destructor won't get called
    return 0;
}