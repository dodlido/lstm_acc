module output_top 
// module parameters
#(	parameter 	FEATURE_BITS = 4,
	parameter 	ELEMENT_BITS = 8,
	parameter 	P = 3'b100,
	parameter 	M = 4'b1001,
	parameter	FEATURES = 3'b100,
	parameter 	GAMMA = 4'b0011) 
// module interface
(	input logic 							pe_clk, 				// slower that sys_clk, determined by mul latency  
	input logic								sys_clk,
	input logic 							reset_n,
	input logic 							start,					// pulse, active high, start normal operation
	input logic  	[ELEMENT_BITS-1:0]		last_pe_data,			// data in from PE(P-1)
	input logic								start_load_cell,		// input from sys_top, indicates all data is rdy to load to LSTM cell
	output logic  	[ELEMENT_BITS-1:0]		first_pe_data,			// data out to PE(0)
	output logic 	[ELEMENT_BITS-1:0]		cell_in_buffer_data_in, // data to LSTM cell
	output logic	[FEATURE_BITS-1:0]		address_write_load_cell,// address to LSTM cell
	output logic							oe_load_cell			// enable write to LSTM cell
);
// modes definition
localparam IDLE = 2'b00 ; 		// do nothing, flush_n when begins
localparam OPERATE = 2'b01 ; 	// write to output dpr PE(P-1) data and read PE(0) data, clk is pe_clk
localparam LOAD_CELL = 2'b10 ; 	// output valid data to cell after calculation
// local parameters
localparam R = M-{P,1'b0} ; 
// internal logics
logic	[1:0]				mode ; 
logic						flush_n;				// pulse, active low, clears output dpr
logic	[FEATURE_BITS-1:0]	output_dpr_address_in ; 
logic						output_dpr_we ; 
logic	[FEATURE_BITS-1:0]	output_dpr_address_out ;
logic						output_dpr_oe ; 
logic	[ELEMENT_BITS-1:0]	output_dpr_data_out ;
logic						start_ag_pe_data_in ; 
logic						done_ag_pe_data_in ; 
logic						start_ag_pe_data_out ; 
logic						done_ag_pe_data_out ; 
logic	[FEATURE_BITS-1:0]	address_ag_pe_data_out ; 
logic						start_ag_load_cell ; 
logic						done_ag_load_cell ; 
logic	[FEATURE_BITS-1:0]	adress_read_load_cell ; 
logic						output_dpr_clk ; 
logic	[FEATURE_BITS-2:0]	p_it ; 
logic						we_load_cell ; 
// input buffer - instantiation of dpr 
dpr #(
	.FEATURE_BITS(FEATURE_BITS/2),
	.ELEMENT_BITS(ELEMENT_BITS),
	.RAM_DEPTH(M)
	) 
		output_dpr (
			.sys_clk(output_dpr_clk),
			.reset_n( reset_n && flush_n ),
			.address_in(output_dpr_address_in),
			.data_in(last_pe_data),
			.cs_in(output_dpr_we), 
			.we_in(output_dpr_we),
			.address_out(output_dpr_address_out),
			.oe_out(output_dpr_oe),
			.cs_out(output_dpr_oe),
			.data_out(output_dpr_data_out)
		);
// address genereation - write to output DPR
ag_o #(
	.FEATURE_BITS(FEATURE_BITS),
	.M(M),
	.GAMMA(GAMMA),
	.P(P),
	.R(R)
	)
		ag_pe_data_in (
			.sys_clk(pe_clk),
			.reset_n(reset_n && flush_n),
			.start(start_ag_pe_data_in),
			.done(done_ag_pe_data_in),
			.address(output_dpr_address_in)
		);
// address genereation - read from output DPR in OPERATE mode
ag_o #(
	.FEATURE_BITS(FEATURE_BITS),
	.M(M),
	.GAMMA(GAMMA),
	.P(P),
	.R(R)
	)
		ag_pe_data_out (
			.sys_clk(pe_clk),
			.reset_n(reset_n && flush_n),
			.start(start_ag_pe_data_out),
			.done(done_ag_pe_data_out),
			.address(address_ag_pe_data_out)
		);
// address genereation - read from output DPR in LOAD_CELL mode
ag_cyc #(
	.FEATURE_BITS(FEATURE_BITS),
	.LIM(M)
	)
		ag_load_cell (
		.sys_clk(sys_clk),
		.reset_n(reset_n && flush_n),
		.start(start_ag_load_cell),
		.done(done_ag_load_cell),
		.address_read(adress_read_load_cell),
		.enable_read(oe_load_cell),
		.address_write(address_write_load_cell),
		.enable_write(we_load_cell)
		);
// Mode Sequencing
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		mode <= #1 IDLE ; 
	end
	else begin
		if (mode == IDLE && start)
			mode <= #1 OPERATE ; 
		else if (start_load_cell) 
			mode <= #1 LOAD_CELL ; 
		else if (mode == LOAD_CELL && done_ag_load_cell )
			mode <= #1 IDLE ; 
		else 
			mode <= #1 mode ; 
	end
end
// Start address generation PE reads
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		start_ag_pe_data_out <= #1 1'b0 ; 
	end
	else begin
		if (mode == IDLE && start )
			start_ag_pe_data_out <= 1'b1 ; 
		else if ( mode == OPERATE && done_ag_pe_data_out )
			start_ag_pe_data_out <= #1 1'b0 ; 
		else 
			start_ag_pe_data_out <= #1 start_ag_pe_data_out ; 	
	end
end
// Start address generation PE writes, delayed by P pe_clk cycles 
always_ff @(posedge pe_clk or negedge reset_n) begin
	if(!reset_n) begin
		p_it <= #1 {FEATURE_BITS-2{1'b0}} ; 
	end
	else begin
		if ( mode != OPERATE )
			p_it <= #1 {FEATURE_BITS-2{1'b0}} ; 	
		else if ( p_it == P-1 )
			p_it <= #1 p_it ; 
		else 
			p_it <= #1 p_it + {{FEATURE_BITS-3{1'b0}},1'b1} ;
	end
end
always_ff @(posedge pe_clk or negedge reset_n) begin
	if(!reset_n) begin
		start_ag_pe_data_in <= #1 1'b0 ; 
	end
	else begin
		if (p_it==P-1)
			start_ag_pe_data_in <= #1 1'b1 ; 
		else 
			start_ag_pe_data_in <= #1 1'b0 ; 
	end
end
// Start address generation LSTM CELL reads
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		start_ag_load_cell <= #1 1'b0 ; 
	end
	else begin
		if (start_load_cell) 
			start_ag_load_cell <= #1 1'b1 ; 
		else 
			start_ag_load_cell <= #1 start_ag_load_cell ; 
	end
end
// flush_n register 
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		flush_n <= #1 1'b1 ; 
	end
	else begin
		if (mode == LOAD_CELL && done_ag_load_cell )
			flush_n <= #1 1'b0 ; 
		else if ( mode == IDLE && start )
			flush_n <= #1 1'b1 ; 
		else 
			flush_n <= #1 flush_n ; 
	end
end
// select output DPR interface depending on mode
always_comb begin
	if ( mode == OPERATE ) begin
		output_dpr_address_out = address_ag_pe_data_out ; 
		first_pe_data = output_dpr_data_out ; 
		cell_in_buffer_data_in = {ELEMENT_BITS{1'b0}} ; 
		output_dpr_clk = sys_clk ; 
	end
	else if ( mode == LOAD_CELL ) begin
		output_dpr_address_out = adress_read_load_cell; 
		cell_in_buffer_data_in = output_dpr_data_out ; 
		first_pe_data = {ELEMENT_BITS{1'b0}} ; 
		output_dpr_clk = sys_clk ; 
	end
	else begin
		output_dpr_address_out = {FEATURE_BITS{1'b0}} ; 
		cell_in_buffer_data_in =  {ELEMENT_BITS{1'b0}}; 
		first_pe_data =  {ELEMENT_BITS{1'b0}}; 
		output_dpr_clk = sys_clk ; 
	end
end
// write\read assigment of output DPR
always_comb begin
	if ( mode == OPERATE ) begin
		output_dpr_we = start_ag_pe_data_in ; 
		output_dpr_oe = start_ag_pe_data_out ; 
	end
	else if ( mode == LOAD_CELL ) begin
		output_dpr_we = 1'b0 ;
		output_dpr_oe = oe_load_cell ; 		
	end
	else begin
		output_dpr_we = 1'b0 ; 
		output_dpr_oe = 1'b0 ; 		
	end
end
endmodule