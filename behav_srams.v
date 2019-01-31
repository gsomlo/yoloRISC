// - specified at 256MB (too large to synthesize);
// - we implement 1K (half for .text, half for stack):
module mem_ext(
	input         W0_clk,
	input  [24:0] W0_addr,
	input         W0_en,
	input  [63:0] W0_data,
	input  [ 7:0] W0_mask,
	input         R0_clk,
	input  [24:0] R0_addr,
	input         R0_en,
	output [63:0] R0_data
);
	reg [24:0] reg_R0_addr;
//	reg [63:0] ram [33554431:0];
	reg [63:0] ram [127:0];

	initial $readmemh("firmware.hex", ram);

	always @(posedge R0_clk)
		if (R0_en) begin
			reg_R0_addr <= R0_addr;
			`ifndef SYNTHESIS
			$display("## mem_rd: a=%h; d=%h",
				R0_addr[6:0], ram[R0_addr[6:0]]);
			`endif // SYNTHESIS
		end
	always @(posedge W0_clk)
		if (W0_en) begin
			if (W0_mask[0])
				ram[W0_addr[6:0]][ 7: 0] <= W0_data[ 7: 0];
			if (W0_mask[1])
				ram[W0_addr[6:0]][15: 8] <= W0_data[15: 8];
			if (W0_mask[2])
				ram[W0_addr[6:0]][23:16] <= W0_data[23:16];
			if (W0_mask[3])
				ram[W0_addr[6:0]][31:24] <= W0_data[31:24];
			if (W0_mask[4])
				ram[W0_addr[6:0]][39:32] <= W0_data[39:32];
			if (W0_mask[5])
				ram[W0_addr[6:0]][47:40] <= W0_data[47:40];
			if (W0_mask[6])
				ram[W0_addr[6:0]][55:48] <= W0_data[55:48];
			if (W0_mask[7])
				ram[W0_addr[6:0]][63:56] <= W0_data[63:56];
			`ifndef SYNTHESIS
			$display("## mem_wr: a=%h d=%h [%b]",
				W0_addr[6:0], W0_data, W0_mask);
			`endif // SYNTHESIS
		end
	assign R0_data = ram[reg_R0_addr[6:0]];
endmodule

// totals 4KB (does NOT match 0x2000_0000 size in subsystem/Configs.scala)
// NOTE: size overridden and hardcoded to 4KB in
//       "trait CanHaveMasterAXI4MMIOPortModuleImp" in source file
//       rocket-chip/src/main/scala/subsystem/Ports.scala
// NOTE1: we remove the "RAM" registers altogether, and just forward
//        data to/from the "hardware".
module mem_0_ext(
	input         reset,
	input         uart_rx,
	output        uart_tx,
	output [ 7:0] led,

	input         W0_clk,
	input  [ 8:0] W0_addr,
	input         W0_en,
	input  [63:0] W0_data,
	input  [ 7:0] W0_mask,
	input         R0_clk,
	input  [ 8:0] R0_addr,
	input         R0_en,
	output [63:0] R0_data
);
	reg [8:0] reg_R0_addr;
	reg [7:0] reg_led;

	wire        uart_dat_we, uart_dat_wait;
	wire [ 3:0] uart_div_we;
	wire [31:0] uart_dat_do, uart_div_do;

	assign uart_dat_we = (W0_en && W0_addr == 9'h0 && W0_mask[7:4] != 4'h0);
	assign uart_div_we = (W0_en && W0_addr == 9'h0) ? W0_mask[3:0] : 4'h0;

	simpleuart uart (
		.clk(W0_clk), // both W0_clk and R0_clk driven by global clock
		.resetn(~reset),

		.ser_rx(uart_rx),
		.ser_tx(uart_tx),

		.reg_div_we(uart_div_we),
		.reg_div_di(W0_data[31: 0]),
		.reg_div_do(uart_div_do),

		.reg_dat_we(uart_dat_we),
		.reg_dat_re(R0_en),
		.reg_dat_di(W0_data[63:32]), // only LSB actually used
		.reg_dat_do(uart_dat_do),
		.reg_dat_wait(uart_dat_wait)
	);

	always @(posedge R0_clk)
		if (R0_en)
			reg_R0_addr <= R0_addr;
	always @(posedge W0_clk)
		if (W0_en && W0_addr == 9'h1 && W0_mask[0])
			reg_led <= W0_data[7:0];
	`ifndef SYNTHESIS
	always @(posedge W0_clk)
		// NOTE: With the way mem_0_ext is generated, there is
		// no simple way to forward the UART's back-pressure
		// 'wait' signal up the module hierarchy. We'd either
		// have to connect the UART somewhere higher up said
		// hierarchy, or implement a buffering mechanism that
		// would keep retrying the data write until the UART's
		// 'wait' signal is de-asserted.
		if (uart_dat_we && uart_dat_wait)
			$display("## WARNING: dropping UART data write!");
	`endif // SYNTHESIS

	assign R0_data = (reg_R0_addr == 9'h0) ? {uart_dat_do, uart_div_do} :
			(reg_R0_addr == 9'h1) ? {56'h0, reg_led} : 64'h0;
	assign led = reg_led;
endmodule
