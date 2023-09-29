
//This module is a testbench for the weight top very large and complicated module
module pe_array_tb;
	
	localparam ELEMENT_BITS = 8 ;
	localparam P 			= 4 ;
			
	logic							pe_clk;			//times data movement across the PE array
	logic 							sys_clk;		//a faster clock, used for multiplying 
	logic 							reset_n;        
	logic 	[P*ELEMENT_BITS-1:0]	weight_data_in;
	logic 	[ELEMENT_BITS-1:0]	 	input_data_in;		
	logic 	[ELEMENT_BITS-1:0]		output_data_in;
	logic	[ELEMENT_BITS-1:0]		output_data_out;
	logic							flag ; 
	

	pe_array uut(
		.sys_clk(sys_clk),
		.pe_clk(pe_clk),
		.reset_n(reset_n),
		.weight_data_in(weight_data_in),
		.input_data_in(input_data_in),
		.output_data_in(output_data_in),
		.output_data_out(output_data_out)
	);
		
	initial begin
		sys_clk = 1'b1;
		pe_clk = 1'b1 ; 
		reset_n = 1'b0;
		weight_data_in[31:0] = {32{1'b0}} ; 
		input_data_in[7:0] = {8{1'b0}} ; 
		output_data_in[7:0] = {8{1'b0}} ; 
		#10
		reset_n = 1'b1;
		for ( int i = 0 ; i < 30 ; i++ ) begin
			weight_data_in[7:0] = i ; 
			input_data_in[7:0] = (i+30) ; 
			output_data_in[7:0] = (i+60) ; 
			#50
			flag = 1'b0 ; 
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