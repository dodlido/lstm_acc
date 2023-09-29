
//This module is a testbench for the weight top very large and complicated module
module input_top_tb;
	
	localparam FEATURE_BITS = 4 ;
	localparam ELEMENT_BITS = 8 ;
	localparam P 			= 4 ;
			
	logic 						sys_clk;       					
	logic 						reset_n;      					
	logic 						start;
	logic 						load_cell ; 
	logic [ELEMENT_BITS-1:0] 	cell_out_data_in ;	// data being read from previous output
	logic 						load_done ; 
	logic [FEATURE_BITS-1:0]	main_mem_address_in; 
	logic [ELEMENT_BITS-1:0]	main_mem_data_in;	
	logic 						main_mem_we_in;	
	logic [FEATURE_BITS-1:0]	main_mem_address_out; //address to read from main memory
	logic [ELEMENT_BITS-1:0]	main_mem_data_out;		
	logic						main_mem_oe_out ; 
	logic [ELEMENT_BITS-1:0]	pe_data_in;		// elements entering PEs
	logic						flag ; 
	

	input_top uut(
		.sys_clk(sys_clk),
		.reset_n(reset_n),
		.start(start),
		.load_cell(load_cell),
		.main_mem_data_out(main_mem_data_out),
		.cell_out_data_in(cell_out_data_in),
		.load_done(load_done),
		.pe_data_in(pe_data_in),
		.main_mem_address_out(main_mem_address_out),
		.main_mem_oe_out(main_mem_oe_out)
	);
	
	//impersonates main memory as a DPR, load it manually 
	dpr #(.FEATURE_BITS(FEATURE_BITS/2),.RAM_DEPTH(4)) main_mem_imp(
		.sys_clk(sys_clk),
		.reset_n(reset_n),
		.address_in(main_mem_address_in),
		.data_in(main_mem_data_in),
		.cs_in(main_mem_we_in),
		.we_in(main_mem_we_in),
		.address_out(main_mem_address_out),
		.oe_out(main_mem_oe_out),
		.cs_out(main_mem_oe_out),
		.data_out(main_mem_data_out)
	);
	
	initial begin
		sys_clk = 1'b1;
		reset_n = 1'b0;
		#10
		reset_n = 1'b1;
		#10
	//load main memory
		main_mem_we_in = 1'b1 ; 
		main_mem_address_in = 0 ; 
		main_mem_data_in = 5 ; 
		#10
		main_mem_address_in = 1 ; 
		main_mem_data_in = 6 ; 
		#10
		main_mem_address_in = 2 ; 
		main_mem_data_in = 7 ; 
		#10
		main_mem_address_in = 3 ; 
		main_mem_data_in = 8 ; 
		#10
		main_mem_we_in = 1'b0 ; 
	//done loading main mem
		#10
		load_cell = 1'b1 ;
		#20
		load_cell = 1'b0 ;
		for(int i = 1; i < 5 ; i++) begin
			cell_out_data_in = i ; 
			#10
			flag= ~flag;
		end
		flag= ~flag; 
		#400
		start = 1'b1 ; 
		#10
		start = 1'b0 ; 
	end	
	
	always begin
		#5
		sys_clk= ~sys_clk;
	end


endmodule
