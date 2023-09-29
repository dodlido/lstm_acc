
// Address Generator from temp buff TB
// This module is a test bench for ag_w
module ag_w_tb;

	localparam FEATURE_BITS = 4;

	logic sys_clk;        					// systolic array clock
	logic reset_n;        					// reset_n 
	logic start ; 
	logic done ; 
	logic [(2 * FEATURE_BITS)-1:0] address;	// address from temp_buff
	logic [FEATURE_BITS-2:0] cs;				// chip select to W_i DPRs
	

	ag_w uut(
		.sys_clk(sys_clk),
		.reset_n(reset_n),
		.start(start),
		.done(done),
		.address(address),
		.cs(cs)
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
