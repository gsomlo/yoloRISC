#include <iostream>
#include "VTestHarness.h"

#define MAX_TIME 1000000

// Simulation time:
vluint64_t t_sim;

// provide method to be called by $time in Verilog:
double sc_time_stamp() { return t_sim; }

int main(int argc, char *argv[])
{
	// Initialize Verilator:
	Verilated::commandArgs(argc, argv);

	// Instantiate DUT:
	VTestHarness *dut = new VTestHarness;

	// Initial input signals:
	dut->clock = 0;
	dut->reset = 1;

	// Tick the clock for a few cycles (or until done):
	for (t_sim = 0; !Verilated::gotFinish() && t_sim < MAX_TIME; t_sim++) {
		if (t_sim > 100)       dut->reset = 0;
		if ((t_sim % 10) == 1) dut->clock = 1;
		if ((t_sim % 10) == 6) dut->clock = 0;

		dut->eval();

		if ((t_sim % 10000) == 0)
			std::cout << "### +1k cycles" << std::endl;
	}

	// Clean up:
	dut->final();
	delete dut;

	return 0;
}
