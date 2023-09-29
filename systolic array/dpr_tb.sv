
// DPR_Wi TB

module dpr_tb;

	localparam FEATURE_BITS = 4 ;
	localparam ELEMENT_BITS = 8 ;
	localparam RAM_DEPTH = 27 ;

	logic sys_clk;        						// systolic array clock
	logic reset_n;        						// reset_n 
	logic [FEATURE_BITS-1:0]	m; 					// number of features (+1 if even)
	logic [FEATURE_BITS-1:0]	gamma;				// number of features (+1 if even)
	logic [(2 * FEATURE_BITS)-1:0] address_in;	// address to dpr_w_i
	logic [ELEMENT_BITS-1:0] data_in;				// 
	logic cs_in;									// chip select to W_i DPRs
	logic we_in;									// read\write enable
	logic [(2 * FEATURE_BITS)-1:0] address_out;	// address from temp_buff
	logic oe_out;
	logic cs_out;
	logic [ELEMENT_BITS-1:0] data_out;			//
	

	dpr_w_i uut(
		.sys_clk(sys_clk),
		.reset_n(reset_n),
		.m(m),
		.gamma(gamma),
		.address_in(address_in),
		.data_in(data_in),
		.cs_in(cs_in),
		.we_in(we_in),
		.address_out(address_out),
		.oe_out(oe_out),
		.cs_out(cs_out),
		.data_out(data_out)
		
	);
	
	initial begin
		sys_clk = 1'b1;
		reset_n = 1'b0;
		m = {{(FEATURE_BITS-4){1'b0}},4'b1001} ; 
		gamma = {{(FEATURE_BITS-2){1'b0}},2'b11} ;
		cs_in = 1'b1 ;
		we_in = 1'b1 ;
		oe_out = 1'b0 ;
		cs_out = 1'b0 ;
		#10
		reset_n = 1'b1 ;
		#10
		
		//insert test data values into RAM
		for (int i = 0; i < RAM_DEPTH; i++) begin
			#10
			address_in = i ;
			data_in = $urandom();
		end
		
		#30
		cs_in = 1'b0 ;
		we_in = 1'b0 ;
		oe_out = 1'b1 ;
		cs_out = 1'b1 ;
		
		//read values from RAM
		for (int i = 0; i < RAM_DEPTH; i++) begin
			#10
			address_out = i ;
		end
	end	
	
	always begin
		#5
		sys_clk= ~sys_clk;
	end


endmodule
