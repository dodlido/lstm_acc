
// Address Generator for temp buff TB
// This module is a test bench for ag_h
module ag_temp_in_tb;

	localparam FEATURE_BITS = 4 ; 

	logic 							sys_clk;	// systolic array clock
	logic 							reset_n;    // reset_n 
	logic 							start ;
	logic							done ;
	logic [(2 * FEATURE_BITS)-1:0] 	address; 	//address to access
	

	ag_temp_in uut(
		.sys_clk(sys_clk),
		.reset_n(reset_n),
		.start(start),
		.done(done),
		.address(address)
	);
	
	initial begin
		sys_clk = 1'b1;
		reset_n = 1'b0;
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
