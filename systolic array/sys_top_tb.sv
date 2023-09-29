/*
	This module is the test-bench of the top of the entire Systolic array
*/
module sys_top_tb;
// module parameters
	localparam 	FEATURE_BITS = 4;
	localparam 	ELEMENT_BITS = 8;
	localparam 	P = 3'b100;
	localparam 	M = 4'b1001;
	localparam	FEATURES = 3'b100;
	localparam 	GAMMA = 4'b0011;
// module interface
	logic 							pe_clk; 				
	logic							sys_clk;
	logic 							reset_n;
	logic							start_load_weight;
	logic							start_load_input ; 
	logic	[ELEMENT_BITS-1:0]		lc_data_in;
	logic	[ELEMENT_BITS-1:0]		mmw_data; 
	logic	[ELEMENT_BITS-1:0]		mmi_data; 
	logic	[2 * FEATURE_BITS-1:0]	mmw_address; 
	logic	[FEATURE_BITS-1:0]		mmi_address;
	logic							mmw_oe; 
	logic							mmi_oe;
	logic	[ELEMENT_BITS-1:0]		lc_data_out;
	logic	[FEATURE_BITS-1:0]		lc_address_out;
	logic							lc_oe_out;
	logic							flag ; 
	logic							if_we ; 
	logic	[ELEMENT_BITS-1:0]		if_data ; 
	logic	[FEATURE_BITS-1:0]		if_add ;
	logic							wf_we ; 
	logic	[ELEMENT_BITS-1:0]		wf_data ; 
	logic	[2*FEATURE_BITS-1:0]	wf_add ; 	
// sys_top instance
	sys_top uut (
		.pe_clk(pe_clk),
		.sys_clk(sys_clk),
		.reset_n(reset_n),
		.start_load_weight(start_load_weight),
		.start_load_input(start_load_input),
		.lc_data_in(lc_data_in),
		.mmw_data(mmw_data),
		.mmi_data(mmi_data),
		.mmw_address(mmw_address),
		.mmi_address(mmi_address),
		.mmw_oe(mmw_oe),
		.mmi_oe(mmi_oe),
		.lc_data_out(lc_data_out),
		.lc_address_out(lc_address_out),
		.lc_oe_out(lc_oe_out)
	);
//main memory input instance
	dpr #(.FEATURE_BITS(FEATURE_BITS/2),.RAM_DEPTH(4)) main_mem_in(
		.sys_clk(sys_clk),
		.reset_n(reset_n),
		.address_in(if_add),
		.data_in(if_data),
		.cs_in(if_we),
		.we_in(if_we),
		.address_out(mmi_address),
		.oe_out(mmi_oe),
		.cs_out(mmi_oe),
		.data_out(mmi_data)
	);
//main memory weights instance
	dpr #(.FEATURE_BITS(FEATURE_BITS),.RAM_DEPTH(81)) main_mem_weights(
		.sys_clk(sys_clk),
		.reset_n(reset_n),
		.address_in(wf_add),
		.data_in(wf_data),
		.cs_in(wf_we),
		.we_in(wf_we),
		.address_out(mmw_address),
		.oe_out(mmw_oe),
		.cs_out(mmw_oe),
		.data_out(mmw_data)
	);
// tb
	initial begin
		sys_clk = 1'b1;
		pe_clk = 1'b1;
		reset_n = 1'b0;
		start_load_input = 1'b0 ; 
		start_load_weight = 1'b0 ; 
		wf_we = 1'b0 ; 
		if_we = 1'b0 ; 
		lc_data_in = {{7{1'b0}},1'b1} ; 
		#10
		reset_n = 1'b1;
		//fill weight main mem
		wf_we = 1'b1 ; 
		for (int i=0 ; i<81 ; i++ ) begin
			if(i < 20 )
				wf_data = 1 ;
			else if(i < 40)
				wf_data = 2 ;
			else if(i < 60)
				wf_data = 3 ;
			else
				wf_data = 4 ;
			wf_add = i ; 
			#10
			flag = 1'b0 ; 
		end
		wf_we = 1'b0 ; 
		//fill input main mem 
		if_we = 1'b1 ; 
		for (int i=2 ; i<6 ; i++ ) begin
			if_add = i - 2; 
			if_data = i ; 
			#10
			flag = 1'b0 ; 
		end
		if_we = 1'b0 ; 
		#10
		start_load_weight = 1'b1 ; 
		#10
		start_load_weight = 1'b0 ; 
		#2000
		start_load_input = 1'b1 ; 
		#10
		start_load_input = 1'b0 ; 
		#200
		//fill input main mem , second it
		if_we = 1'b1 ; 
		for (int i=2 ; i<6 ; i++ ) begin
			if_add = i - 2; 
			if_data = 10 - i ; 
			#10
			flag = 1'b0 ; 
		end
		if_we = 1'b0 ; 
		#2000
		start_load_input = 1'b1 ; 
		#10
		start_load_input = 1'b0 ; 
	end
// sys_clk
	always begin
		#5
		sys_clk= ~sys_clk;
	end
// pe_clk
	always begin
		#25
		pe_clk= ~pe_clk;
	end
endmodule