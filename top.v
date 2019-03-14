// top-level module
module chip_top(
	input        clkin,
	input        uart_rx,
	output       uart_tx,
	output [7:0] led,
);
	wire clock;

	pll_100_20 pll(
		.clki(clkin),
		.clko(clock),
		.locked(),
	);

	reg [6:0] reset_cnt = 0;
	wire reset = !(&reset_cnt);
	always @(posedge clock)
		reset_cnt <= reset_cnt + reset;

	wire [7:0] soc_led;

	TestHarness soc(
		.uart_rx(uart_rx),
		.uart_tx(uart_tx),
		.led(soc_led),
		.clock(clock),
		.reset(reset),
		.io_success() // ignored
	);

	assign led = ~soc_led;
endmodule // chip_top

module pll_100_20(
	input  clki,
	output clko,
	output locked,
);
	wire clkfb;
	(* ICP_CURRENT="6" *)
	(* LPF_RESISTOR="16" *)
	(* MFG_ENABLE_FILTEROPAMP="1" *)
	(* MFG_GMCREF_SEL="2" *)
	EHXPLLL #(
		.CLKI_DIV(5),
		.CLKFB_DIV(1),
		.CLKOP_DIV(30),
		.CLKOP_CPHASE(15),
		.FEEDBK_PATH("INT_OP"),
	) pll_i (
		.CLKI(clki),
		.CLKFB(clkfb),
		.PHASESEL1(1'b0),
		.PHASESEL0(1'b0),
		.PHASEDIR(1'b0),
		.PHASESTEP(1'b0),
		.STDBY(1'b0),
		.PLLWAKESYNC(1'b0),
		.RST(1'b0),
		.ENCLKOP(1'b0),
		.CLKOP(clko),
		.LOCK(locked),
		.CLKINTFB(clkfb),
	);
endmodule // pll_100_20
