
module serializer_tb;

	localparam FEATURE_BITS = 2;
	localparam ELEMENT_BITS = 8;
	localparam M = 4'b1001;
	localparam FEATURES = 4;

	logic								clk;
	logic								reset_n;
	logic								start;
	logic 	[ELEMENT_BITS-1:0]          serial_data_out;
	logic	[ELEMENT_BITS*FEATURES-1:0] parallel_data_in;
	logic								done;
	

	serializer uut(
		.clk(clk),
		.reset_n(reset_n),
		.start(start),
		.done(done),
		.serial_data_out(serial_data_out),
		.parallel_data_in(parallel_data_in)
	);
	
	initial begin
		clk = 1'b1 ;
		reset_n = 1'b0 ;
		parallel_data_in = 32'h00000000 ; 
		#10
		reset_n = 1'b1 ;
		start = 1'b1 ;
		#10
		start = 1'b0 ;
		parallel_data_in = 32'h04030201 ; 
	end	
	
	always begin
		#5
		clk= ~clk;
	end


endmodule
