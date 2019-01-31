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
	initial begin:B0
		integer i;
		for (i = 0; i < 128; i++)
			ram[i] = 64'h0001_0001_0001_0001; // NOP: addi x0, x0, 0
		// "li sp, 0x80000400" translates into the following opcodes:
		//   0010011b addiw sp,zero,1
		//   01f11113 slli  sp,sp,0x1f
		//   40010113 addi  sp,sp,1024
		// which should go into memory like this:
		ram[0] = 64'h01f1_1113_0010_011b;
		ram[1] = 64'h0001_0001_4001_0113;
	end
	always @(posedge R0_clk)
		if (R0_en) begin
			reg_R0_addr <= R0_addr;
			$display("## mem_rd: a=%h; d=%h",
				R0_addr[6:0], ram[R0_addr[6:0]]);
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
			$display("## mem_wr: a=%h d=%h [%b]",
				W0_addr[6:0], W0_data, W0_mask);
		end
	assign R0_data = ram[reg_R0_addr[6:0]];
endmodule

// totals 4KB (does NOT match 0x2000_0000 size in subsystem/Configs.scala)
// NOTE: size overridden and hardcoded to 4KB in
//       "trait CanHaveMasterAXI4MMIOPortModuleImp" in source file
//       rocket-chip/src/main/scala/subsystem/Ports.scala
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
	reg [ 8:0] reg_R0_addr;
	reg [63:0] ram [511:0];
	initial begin:B0
		integer i;
		for (i = 0; i < 512; i++)
			ram[i] = 64'h0010_0013_0010_0013; // load imediate 1
	end
	always @(posedge R0_clk)
		if (R0_en) begin
			reg_R0_addr <= R0_addr;
			$display("## mmio_rd: a=%h; d=%h",
				R0_addr, ram[R0_addr]);
		end
	always @(posedge W0_clk)
		if (W0_en) begin
			if (W0_mask[0]) ram[W0_addr][ 7: 0] <= W0_data[ 7: 0];
			if (W0_mask[1]) ram[W0_addr][15: 8] <= W0_data[15: 8];
			if (W0_mask[2]) ram[W0_addr][23:16] <= W0_data[23:16];
			if (W0_mask[3]) ram[W0_addr][31:24] <= W0_data[31:24];
			if (W0_mask[4]) ram[W0_addr][39:32] <= W0_data[39:32];
			if (W0_mask[5]) ram[W0_addr][47:40] <= W0_data[47:40];
			if (W0_mask[6]) ram[W0_addr][55:48] <= W0_data[55:48];
			if (W0_mask[7]) ram[W0_addr][63:56] <= W0_data[63:56];
			$display("## mmio_wr: a=%h d=%h [%b]",
				W0_addr, W0_data, W0_mask);
		end
	assign R0_data = ram[reg_R0_addr];
endmodule
