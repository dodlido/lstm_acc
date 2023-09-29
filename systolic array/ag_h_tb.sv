
// Address Generator for temp buff TB
// This module is a test bench for ag_h
module ag_h_tb;

	localparam FEATURE_BITS = 4;
	localparam M = 9;

	logic sys_clk;        						// systolic array clock
	logic reset_n;        						// reset_n 
	//logic [FEATURE_BITS-1:0]	m;     			// m is a constant 4'b1001, stored in a register
	logic 						start ;
	logic						done ;
	logic [(2 * FEATURE_BITS)-1:0] 	address; 	//address to access
	

	ag_h uut(
		.sys_clk(sys_clk),
		.reset_n(reset_n),
		//.m(m),
		.start(start),
		.done(done),
		.address(address)
	);
	
	initial begin
		sys_clk = 1'b1;
		reset_n = 1'b0;
		//m = {{(FEATURE_BITS-4){0}},4'b1001} ; 
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
