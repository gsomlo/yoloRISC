// top-level module
module chip_top(
	input        clkin,
	input        uart_rx,
	output       uart_tx,
	output [7:0] led,
);
	wire clock;

	pll_100_10 pll(
		.clki(clkin),
		.clko(clock)
	);

	reg [6:0] reset_cnt = 0;
	wire reset = !(&reset_cnt);
	always @(posedge clock)
		reset_cnt <= reset_cnt + reset;

	TestHarness soc(
		.uart_rx(uart_rx),
		.uart_tx(uart_tx),
		.led(~led),
		.clock(clock),
		.reset(reset),
		.io_success() // ignored
	);
endmodule // chip_top

// divide input clock 'clki' (100 MHz) by ten
module pll_100_10(
	input  clki,
	output clko,
);
	(* ICP_CURRENT="12" *)
	(* LPF_RESISTOR="8" *)
	(* MFG_ENABLE_FILTEROPAMP="1" *)
	(* MFG_GMCREF_SEL="2" *)
	EHXPLLL #(
		.CLKI_DIV(10),
		.CLKOP_DIV(12),
		.CLKOP_CPHASE(11),
	) pll_i (
		.CLKI(clki),
		.CLKFB(clko),
		.PHASESEL1(1'b0),
		.PHASESEL0(1'b0),
		.PHASEDIR(1'b0),
		.PHASESTEP(1'b0),
		.STDBY(1'b0),
		.PLLWAKESYNC(1'b0),
		.RST(1'b0),
		.ENCLKOP(1'b0),
		.CLKOP(clko),
	);
endmodule // pll_100_10
