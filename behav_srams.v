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
	reg [31:0] uart_ckdiv, uart_data;
	reg [7:0] reg_led;

	`ifndef SYNTHESIS
	always @(posedge R0_clk)
		if (R0_en)
			$display("## mmio_rd: a=%h (Not Supported!)", R0_addr);
	`endif // SYNTHESIS
	always @(posedge W0_clk)
		if (W0_en) begin
			if (W0_addr == 9'h000) begin // uart
				if (W0_mask[3:0] == 4'hF)
					uart_ckdiv <= W0_data[31: 0];
				if (W0_mask[7:4] == 4'hF)
					uart_data <= W0_data[63:32];
				`ifndef SYNTHESIS
				$display("## mmio_wr_uart: d=%h [%b]",
					W0_data, W0_mask);
				`endif // SYNTHESIS
			end
			if (W0_addr == 9'h001) begin
				if (W0_mask[0])
					reg_led <= W0_data[7:0];
				`ifndef SYNTHESIS
				$display("## mmio_wr_leds: d=%h [%b]",
					W0_data[7:0], W0_mask[0]);
				`endif // SYNTHESIS
			end
		end
	assign R0_data = 64'hFFFF_FFFF_FFFF_FFFF; // MMIO reads not supported!
endmodule
