/*
	This module is the top of the entire Systolic array
*/
module sys_top
// module parameters
#(	parameter 	FEATURE_BITS = 4,
	parameter 	ELEMENT_BITS = 8,
	parameter 	P = 3'b100,
	parameter 	M = 4'b1001,
	parameter	FEATURES = 3'b100,
	parameter 	GAMMA = 4'b0011) 
// module interface
(	input 	logic 							pe_clk, 				// slower than sys_clk, determined by mul latency  
	input 	logic							sys_clk,
	input 	logic 							reset_n,
	input	logic							start_load_weight,
	input	logic							start_load_hidden, 
	input	logic							start_load_input, 
	input	logic	[ELEMENT_BITS-1:0]		lc_data_in,
	input 	logic	[ELEMENT_BITS-1:0]		mmw_data, 
	input 	logic	[ELEMENT_BITS-1:0]		mmi_data, 
	input	logic	[FEATURE_BITS-1:0]		hidden_address,
	/*output 	logic	[2 * FEATURE_BITS-1:0]	mmw_address, 
	output 	logic	[FEATURE_BITS-1:0]		mmi_address, 
	output 	logic							mmw_oe, 
	output 	logic							mmi_oe, */
	output	logic	[ELEMENT_BITS-1:0]		lc_data_out,
	output  logic							done_load_weight, 
	output  logic							done_load_input ,
	output	logic							lc_oe_out/*, Outputs not used 
	output	logic	[FEATURE_BITS-1:0]		lc_address_out, 
	*/ 
);
// modes definition
logic		[2:0]			mode ; 
localparam 	INIT 		= 3'b000 ; 	// weights are not loaded yet, move to load weight if(load_weight)
localparam 	LOAD_WEIGHT = 3'b001 ; 	// loading weights, once per operation
localparam 	LOAD_INPUT 	= 3'b010 ; 	// load input from cell in and outside, happenes every single cycle
localparam 	OPERATE 	= 3'b011 ; 	// systolic array calculation
localparam 	LOAD_CELL	= 3'b100 ; 	// waiting for LSTM cell to finish
localparam 	IDLE 		= 3'b101 ; 	// waiting for LSTM cell to finish
// internal logics
logic	[FEATURE_BITS-2:0]		p_counter ; 
logic							start_operate ; 
logic							start_output ; 
logic							done_operate ;
logic							done_load_cell ; 
logic	[FEATURE_BITS-1:0]		load_cell_counter ; 
logic	[P*ELEMENT_BITS-1:0]	pw_data ; 
logic	[ELEMENT_BITS-1:0]		pi_data ; 
logic	[ELEMENT_BITS-1:0]		pol_data ; 
logic	[ELEMENT_BITS-1:0]		pof_data ; 
logic	[2*FEATURE_BITS-1:0]	done_counter ; 
// mode sequencing
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		mode <= #1 INIT ; 
	end
	else begin
		case(mode)
			INIT:
				mode <= #1 start_load_weight ? LOAD_WEIGHT : INIT ; 
			LOAD_WEIGHT:
				mode <= #1 done_load_weight ? IDLE : LOAD_WEIGHT ; 
			IDLE:
				mode <= #1 start_load_input ? LOAD_INPUT : IDLE ; 
			LOAD_INPUT:
				mode <= #1 done_load_input ? OPERATE : LOAD_INPUT ;
			OPERATE:
				mode <= #1 done_operate ? LOAD_CELL : OPERATE ;
			LOAD_CELL:
				mode <= #1 done_load_cell ? IDLE : LOAD_CELL ;
		endcase
	end
end
// start operate reg
always_ff @(posedge pe_clk or negedge reset_n) begin
	if(!reset_n) begin
		p_counter <= #1 {FEATURE_BITS-1{1'b0}} ; 
	end
	else begin
		if (mode==OPERATE && p_counter == P-1)
			p_counter <= #1 p_counter ; 
		else if (mode==OPERATE)
			p_counter <= #1 p_counter + {{FEATURE_BITS-2{1'b0}},1'b1} ; 
		else 
			p_counter <= #1 {FEATURE_BITS-1{1'b0}} ; 
	end
end
assign start_operate = (p_counter==P-1) ? 1'b1 : 1'b0 ; 
// start output reg
always_ff @(posedge pe_clk or negedge reset_n) begin
	if(!reset_n) begin
		start_output <= #1 1'b0 ; 
	end
	else begin
		start_output <= #1 start_operate ; 
	end
end
// done operate counter
always_ff @(posedge pe_clk or negedge reset_n) begin
	if(!reset_n) begin
		done_counter <= #1 {2*FEATURE_BITS{1'b0}} ; 
	end
	else begin
		if ( mode == IDLE ) 
			done_counter <= #1 {2*FEATURE_BITS{1'b0}} ; 
		else if ( done_counter == (M*GAMMA + P + 2'b10) )
			done_counter <= #1 {2*FEATURE_BITS{1'b0}} ; 
		else if ( mode == OPERATE )
			done_counter <= #1 done_counter + {{2*FEATURE_BITS-1{1'b0}},1'b1} ; 
		else
			done_counter <= #1 done_counter ; 
	end
end
// done operate reg
always_ff @(posedge pe_clk or negedge reset_n) begin
	if(!reset_n) begin
		done_operate <= #1 1'b0 ; 
	end
	else begin
		if (done_counter == (M*GAMMA + P + 2'b10))
			done_operate <= #1 1'b1 ; 
		else
			done_operate <= #1 1'b0 ; 
	end
end
// load cell counter
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		load_cell_counter <= #1 {FEATURE_BITS{1'b0}} ; 
	end
	else begin
		if ( mode != LOAD_CELL || load_cell_counter == M )
			load_cell_counter <= #1 {FEATURE_BITS{1'b0}} ; 
		else 
			load_cell_counter <= #1 load_cell_counter + {{FEATURE_BITS-1{1'b0}},1'b1} ; 
	end
end
// done load cell reg
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		done_load_cell <= #1 1'b0 ; 
	end
	else begin
		if ( load_cell_counter == M )
			done_load_cell <= #1 1'b1 ; 
		else 
			done_load_cell <= #1 1'b0 ; 
	end
end
// instantiation of weights
weight_top # (.FEATURE_BITS(FEATURE_BITS), .ELEMENT_BITS(ELEMENT_BITS), .P(P), .M(M), .GAMMA(GAMMA))
weight_top (
	.sys_clk(sys_clk),
	.pe_clk(pe_clk),
	.reset_n(reset_n),
	.load(start_load_weight),
	.start(start_operate),
	.main_mem_data(mmw_data),
	.load_done(done_load_weight),
	/*.main_mem_address(mmw_address),
	.main_mem_oe_out(mmw_oe),
	.main_mem_cs_out(mmw_oe), cs is NC*/
	.pe_data_in(pw_data)
);
// instantiation of input
input_top # (.FEATURE_BITS(FEATURE_BITS), .ELEMENT_BITS(ELEMENT_BITS), .P(P), .M(M), .GAMMA(GAMMA), .FEATURES(FEATURES))
input_top (
	.sys_clk(sys_clk),
	.pe_clk(pe_clk),
	.reset_n(reset_n),
	.hidden_address(hidden_address),
	.load_cell(start_load_hidden),
	.start_load_input(start_load_input),
	.cell_out_data_in(lc_data_in),
	.done_load_input(done_load_input),
	.main_mem_data_out(mmi_data),
	.pe_data_in(pi_data)
);
// instantiation of output
output_top # (.FEATURE_BITS(FEATURE_BITS), .ELEMENT_BITS(ELEMENT_BITS), .P(P), .M(M), .GAMMA(GAMMA), .FEATURES(FEATURES))
output_top (
	.sys_clk(sys_clk),
	.pe_clk(pe_clk),
	.reset_n(reset_n && mode != IDLE),
	.start(start_output),
	.last_pe_data(pol_data),
	.first_pe_data(pof_data),
	.start_load_cell(done_operate),
	.cell_in_buffer_data_in(lc_data_out),
	.oe_load_cell(lc_oe_out)/*, ports NC
	.address_write_load_cell(lc_address_out),
	*/
);
// instantiation of array
pe_array # (.ELEMENT_BITS(ELEMENT_BITS), .P(P)) 
pe_array (
	.sys_clk(sys_clk),
	.pe_clk(pe_clk),
	.reset_n(reset_n),
	.weight_data_in(pw_data),
	.input_data_in(pi_data),
	.output_data_in(pof_data),
	.output_data_out(pol_data)
);
endmodule