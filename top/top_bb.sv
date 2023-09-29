/*
	This module is the top of all tops
*/
module top_bb ; 

//localparameters
localparam ELEMENT_BITS   = 8    ; 
localparam WEIGHTS = 64 ; 
localparam FEATURES = 4 ; 
localparam MAIN_MEM_DEPTH = 2048 ; 
localparam MAIN_MEM_ADD_LEN = 11 ; 
localparam CYCLES = 10 ; 
localparam WORD_SIZE = {{MAIN_MEM_ADD_LEN-4{1'b0}},4'b1000} ; 
localparam INPUT_SIZE = FEATURES*CYCLES ; 
localparam ZERO	= {MAIN_MEM_ADD_LEN{1'b0}} ; 
localparam IN_FIRST = ZERO ;
localparam W1_FIRST  = IN_FIRST + INPUT_SIZE ; 
localparam W2_FIRST  = W1_FIRST + WEIGHTS ; 
localparam OUT_FIRST = W2_FIRST + WEIGHTS ;

logic							fpga_clk;				// clk from FPGA oscillator
logic							reset_n;				// system reset, active low
logic 							start; 					// wake system up, active high, pulse
logic 							start_trans; 			// start data transaction, cpu outputs, dmac input
logic	[2:0]					op_mode;				// system mode
logic	[ELEMENT_BITS-1:0]		data_in;				// data to write to main_mem
logic	[ELEMENT_BITS-1:0]		data_out;				// data to read from main_mem
logic							direct;					// direction of data transition: 0=main_mem to lstm, 1=lstm to main_mem
logic	[MAIN_MEM_ADD_LEN-1:0]	main_mem_first_address;	// address of first word to read from \ write to
logic	[MAIN_MEM_ADD_LEN-1:0]	main_mem_count;			// number of consecutive words to read from \ write to 
logic	[MAIN_MEM_ADD_LEN-1:0]	main_mem_address_in;		// dmac generates to main_mem
logic	[MAIN_MEM_ADD_LEN-1:0]	main_mem_address_out;		// dmac generates to main_mem
logic							main_mem_oe ; 
logic							main_mem_we ; 
logic							manual_load_we ; 
logic	[ELEMENT_BITS-1:0]		manual_load_data ; 
logic	[MAIN_MEM_ADD_LEN-1:0]	manual_load_address ; 
logic							dpr_we ; 
logic	[ELEMENT_BITS-1:0]		dpr_data_in ; 
logic	[MAIN_MEM_ADD_LEN-1:0]	dpr_address_in ; 


top uut (
	.fpga_clk(fpga_clk),
	.reset_n(reset_n),
	.start(start),
	.op_mode(op_mode),
	.data_in(data_out),
	.data_out(data_in)
);

cpu cpu (
	.fpga_clk(fpga_clk),
	.reset_n(reset_n),
	.op_mode(op_mode),
	.start(start_trans),
	.direct(direct),
	.main_mem_count(main_mem_count),
	.main_mem_first_address(main_mem_first_address)
);

dmac dmac (
	.fpga_clk(fpga_clk),
	.reset_n(reset_n),
	.direct(direct),
	.start(start_trans),
	.main_mem_count(main_mem_count),
	.main_mem_first_address(main_mem_first_address),
	.main_mem_address_in_delayed(main_mem_address_in),
	.main_mem_address_out(main_mem_address_out),
	.main_mem_we_delayed(main_mem_we),
	.main_mem_oe(main_mem_oe)
);

dpr #(
	.FEATURE_BITS(6),
	.ELEMENT_BITS(ELEMENT_BITS),
	.RAM_DEPTH(MAIN_MEM_DEPTH)
) 
main_mem (
	.sys_clk(fpga_clk),
	.reset_n(reset_n),
	.address_in(dpr_address_in),
	.data_in(dpr_data_in),
	.cs_in(dpr_we), 
	.we_in(dpr_we),
	.address_out(main_mem_address_out),
	.oe_out(main_mem_oe),
	.cs_out(main_mem_oe),
	.data_out(data_out)
);

always_comb begin
	dpr_we = start ? main_mem_we : manual_load_we ; 
	dpr_data_in = start ? data_in : manual_load_data ; 
	dpr_address_in = start ? main_mem_address_in : manual_load_address ; 
end

initial begin
	fpga_clk = 1'b1 ; 
	reset_n = 1'b0 ;
	start = 1'b0 ; 
	#10
	//load main_mem manually
	reset_n = 1'b1 ;
	manual_load_we = 1'b1 ; 
		//write W1
		for (int i=0; i<WEIGHTS; i++) begin
			#10
			manual_load_address = W1_FIRST + i ; 
			if(i<20)
				manual_load_data = 8'b00000100 ; 
			else if (i<40)
				manual_load_data = 8'b00000011 ; 
			else
				manual_load_data = 8'b00000010 ; 
		end
		//write W2
		for (int i=0; i<WEIGHTS; i++) begin
			#10
			manual_load_address = W2_FIRST + i ; 
			if(i<20)
				manual_load_data = 8'b00000100 ;  
			else if (i<40)
				manual_load_data = 8'b00000011 ; 
			else
				manual_load_data = 8'b00000010 ; 
		end
		#10
		//write Inputs
		manual_load_address = IN_FIRST ; 
		manual_load_data = 8'b00000001 ;  
		#10
		manual_load_address = IN_FIRST + 1; 
		manual_load_data = 8'b00000010 ;  
		#10
		manual_load_address = IN_FIRST + 2 ; 
		manual_load_data = 8'b00000011 ;  
		#10
		manual_load_address = IN_FIRST + 3 ; 
		manual_load_data = 8'b00000100 ;   
		#10
		manual_load_address = IN_FIRST + 4 ; 
		manual_load_data = 8'b00000101 ;    
		#10
		manual_load_address = IN_FIRST + 5 ; 
		manual_load_data = 8'b00000110 ;    
		#10
		manual_load_address = IN_FIRST + 6 ; 
		manual_load_data = 8'b00000111 ;    
		#10
		manual_load_address = IN_FIRST + 7 ; 
		manual_load_data = 8'b00001000 ;    
		#10
		manual_load_address = IN_FIRST + 8 ; 
		manual_load_data = 8'b00000111 ;    
		#10
		manual_load_address = IN_FIRST + 9 ; 
		manual_load_data = 8'b00000110 ;    
		#10
		manual_load_address = IN_FIRST + 10 ; 
		manual_load_data = 8'b00000101 ;  
		#10
		manual_load_address = IN_FIRST + 11 ; 
		manual_load_data = 8'b00000100 ;  
		#10
		manual_load_address = IN_FIRST + 12 ; 
		manual_load_data = 8'b00000011 ;  
		#10
		manual_load_address = IN_FIRST + 13 ; 
		manual_load_data = 8'b00000010 ;  
		#10
		manual_load_address = IN_FIRST + 14 ; 
		manual_load_data = 8'b00000001 ;  
		#10
		manual_load_address = IN_FIRST + 15 ; 
		manual_load_data = 8'b00001000 ;  
		#10
		manual_load_address = 0 ; 
		manual_load_data = 0 ; 
	manual_load_we = 1'b0 ; 
	#500
	start = 1'b1 ; 
end

always begin
	#5
	fpga_clk= ~fpga_clk;
end

endmodule