
//This module is a testbench for the weight top very large and complicated module
module weight_top_tb;
	
	localparam FEATURE_BITS = 4 ;
	localparam ELEMENT_BITS = 8 ;
	localparam P 			= 4 ;
			
	logic 						sys_clk;      
	logic						pe_clk ; 
	logic 						reset_n;      					
	logic 						start;
	logic 						load ; 
	logic [ELEMENT_BITS-1:0] 	main_mem_data;	// data being read from main memory
	logic 						load_done ; 
	logic [P*ELEMENT_BITS-1:0]	pe_data_in;		// elements entering PEs
	logic [2*FEATURE_BITS-1:0]	main_mem_address;
	logic						main_mem_cs_out;
	logic						main_mem_oe_out;
	logic 						flag ; 

	weight_top uut(
		.sys_clk(sys_clk),
		.pe_clk(pe_clk),
		.reset_n(reset_n),
		.start(start),
		.load(load),
		.main_mem_data(main_mem_data),
		.load_done(load_done),
		.main_mem_address(main_mem_address),
		.main_mem_cs_out(main_mem_cs_out),
		.main_mem_oe_out(main_mem_oe_out),
		.pe_data_in(pe_data_in)
	);
	
	initial begin
		sys_clk = 1'b1;
		pe_clk = 1'b1;
		reset_n = 1'b0;
		#10
		reset_n = 1'b1;
		#10
		load = 1'b1 ;
		#5
		flag= ~flag;
		for(int i = 0; i < 9 ; i++) begin
			for (int k = 0; k < 9 ;k++ ) begin
				main_mem_data = 9*k + ((i+k)%9) ; 
				#10
				flag= ~flag;
			end
		end
		main_mem_data = 0 ; 
		#3000
		start = 1'b1 ; 
	end	
	
	always begin
		#5
		sys_clk= ~sys_clk;
	end
	
	always begin
		#25
		pe_clk= ~pe_clk;
	end

endmodule
