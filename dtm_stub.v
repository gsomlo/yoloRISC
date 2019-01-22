// Stub to satisfy TestHarness dependency:
module SimDTM(
	input clk,
	input reset,
	output        debug_req_valid,
	input         debug_req_ready,
	output [ 6:0] debug_req_bits_addr,
	output [ 1:0] debug_req_bits_op,
	output [31:0] debug_req_bits_data,
	input         debug_resp_valid,
	output        debug_resp_ready,
	input  [ 1:0] debug_resp_bits_resp,
	input  [31:0] debug_resp_bits_data,
	output [31:0] exit
);
	assign debug_req_valid     =  1'b0;
	assign debug_resp_ready    =  1'b0;
	assign exit                = 32'h0;
//	assign debug_req_bits_addr =  7'h0;
//	assign debug_req_bits_op   =  2'h0;
//	assign debug_req_bits_data = 32'h0;
endmodule // SimDTM
