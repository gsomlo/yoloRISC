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

// divide input clock 'clki' (100 MHz) by ten
module pll_100_10(
	input  clki,
	output clko,
);
	(* ICP_CURRENT="6" *)
	(* LPF_RESISTOR="16" *)
	(* MFG_ENABLE_FILTEROPAMP="1" *)
	(* MFG_GMCREF_SEL="2" *)
	EHXPLLL #(
        .PLLRST_ENA("DISABLED"),
        .INTFB_WAKE("DISABLED"),
        .STDBY_ENABLE("DISABLED"),
        .DPHASE_SOURCE("DISABLED"),
        .CLKOP_FPHASE(0),
        .CLKOP_CPHASE(64),
        .OUTDIVIDER_MUXA("DIVA"),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOP_DIV(65),
        .CLKFB_DIV(1),
        .CLKI_DIV(10),
        .FEEDBK_PATH("CLKOP")
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
