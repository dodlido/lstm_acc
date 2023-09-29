
//This module is a testbench for the weight top very large and complicated module
module output_top_tb;
	
	localparam FEATURE_BITS = 4 ;
	localparam ELEMENT_BITS = 8 ;
	localparam P 			= 3'b100 ;
	localparam M 			= 4'b1001 ;
			
	logic 							pe_clk; 				// slower that sys_clk, determined by mul latency  
	logic							sys_clk;
	logic 							reset_n;
	logic 							start;					// pulse, active high, start normal operation
	logic  	[ELEMENT_BITS-1:0]		last_pe_data;			// data in from PE(P-1)
	logic  	[ELEMENT_BITS-1:0]		first_pe_data;			// data out to PE(0)
	logic 	[ELEMENT_BITS-1:0]		cell_in_buffer_data_in; // data to LSTM cell
	logic	[FEATURE_BITS-1:0]		address_write_load_cell;// address to LSTM cell
	logic							we_load_cell;			// enable write to LSTM cell
	logic							flag ; 

	output_top uut(
		.pe_clk(pe_clk),
		.sys_clk(sys_clk),
		.reset_n(reset_n),
		.start(start),
		.last_pe_data(last_pe_data),
		.first_pe_data(first_pe_data),
		.cell_in_buffer_data_in(cell_in_buffer_data_in),
		.address_write_load_cell(address_write_load_cell),
		.we_load_cell(we_load_cell)
	);
	
	//impersonates CELL in DPR, loading this as output
	dpr #(.FEATURE_BITS(FEATURE_BITS/2),.RAM_DEPTH(M)) cell_dpr(
		.sys_clk(sys_clk),
		.reset_n(reset_n),
		.address_in(address_write_load_cell),
		.data_in(cell_in_buffer_data_in),
		.cs_in(we_load_cell),
		.we_in(we_load_cell),
		.address_out({FEATURE_BITS{1'b0}}),
		.oe_out(1'b0),
		.cs_out(1'b0)
	);
	
	initial begin
		sys_clk = 1'b1;
		pe_clk = 1'b1 ; 
		reset_n = 1'b0;
		last_pe_data = {ELEMENT_BITS{1'b0}} ;
		#10
		reset_n = 1'b1;
		#10
		start = 1'b1 ; 
		#10
		start = 1'b0 ; 
		for (int i = 1 ; i < 28 ; i++ ) begin
			last_pe_data = i ; 
			#50
			flag = ~flag ; 
		end	
		flag = ~flag ; 
		#450
		start = 1'b1 ; 
		#10 
		start = 1'b0 ; 
		for (int i = 1 ; i < 28 ; i++ ) begin
			last_pe_data = i ; 
			#50
			flag = ~flag ; 
		end	
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
