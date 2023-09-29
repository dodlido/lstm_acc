
// Address Generator for sys_out DPR TB
// This module is a test bench for ag_o 
module ag_o_tb;

	localparam FEATURE_BITS = 4;

	logic sys_clk;        					// systolic array clock
	logic reset_n;        					// reset_n 
	logic start ;
	logic [FEATURE_BITS-1:0] 	address; 
	

	ag_o uut(
		.sys_clk(sys_clk),
		.reset_n(reset_n),
		.start(start),
		.address(address)
	);
	
	initial begin
		sys_clk = 1'b1;
		reset_n = 1'b0;
		#10
		reset_n = 1'b1 ; 
		start = 1'b1 ; 
	end	
	
	always begin
		#5
		sys_clk= ~sys_clk;
	end


endmodule
