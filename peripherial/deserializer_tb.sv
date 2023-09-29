
module deserializer_tb;

	localparam FEATURE_BITS = 2;
	localparam ELEMENT_BITS = 8;
	localparam M = 4'b1001;
	localparam FEATURES = 4;

	logic								clk;
	logic								reset_n;
	logic								start;
	logic 	[ELEMENT_BITS-1:0]          serial_data_in;
	logic	[ELEMENT_BITS*FEATURES-1:0] parallel_data_out_1;
	logic	[ELEMENT_BITS*FEATURES-1:0] parallel_data_out_2;
	logic								done;
	

	deserializer uut(
		.clk(clk),
		.reset_n(reset_n),
		.start(start),
		.done(done),
		.serial_data_in(serial_data_in),
		.parallel_data_out_1(parallel_data_out_1),
		.parallel_data_out_2(parallel_data_out_2)
	);
	
	initial begin
		clk = 1'b1 ;
		reset_n = 1'b0 ;
		serial_data_in = 8'h00 ; 
		#10
		reset_n = 1'b1 ;
		start = 1'b1 ;
		#10
		start = 1'b0 ;
		serial_data_in = 8'h01 ; 
		#10
		serial_data_in = 8'h02 ; 
		#10
		serial_data_in = 8'h03 ; 
		#10
		serial_data_in = 8'h04 ; 
		#10
		serial_data_in = 8'h05 ; 
		#10
		serial_data_in = 8'h06 ; 
		#10
		serial_data_in = 8'h07 ; 
		#10
		serial_data_in = 8'h08 ; 
		#10
		serial_data_in = 8'h09 ; 
		#10
		serial_data_in = 8'h0a ; 
	end	
	
	always begin
		#5
		clk= ~clk;
	end


endmodule
