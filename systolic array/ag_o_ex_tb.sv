
// Address Generator for sys_out DPR TB
// This module is a test bench for ag_o 
module ag_o_ex_tb;

	localparam FEATURE_BITS = 4;
	localparam M = 4'b1001 ; 
	localparam GAMMA = 4'b0011 ; 
	localparam P = 3'b100 ; 

	logic sys_clk;        					// systolic array clock
	logic reset_n;        					// reset_n 
	logic [2*FEATURE_BITS-1:0] 	address; 
	logic 						start;
	logic 						done;
	

	ag_o_ex uut(
		.sys_clk(sys_clk),
		.reset_n(reset_n),
		.address_ex(address),
		.start(start),
		.done(done)
	);
	
	initial begin
		sys_clk = 1'b1;
		reset_n = 1'b0;
		start = 1'b0 ;
		#10
		reset_n = 1'b1 ; 
		#10
		start = 1'b1 ;
	end	
	
	always begin
		#5
		sys_clk= ~sys_clk;
	end


endmodule
