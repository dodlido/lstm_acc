module input_top 
#(	parameter 	FEATURE_BITS = 4,
	parameter 	ELEMENT_BITS = 8,
	parameter 	P = 3'b100,
	parameter 	M = 4'b1001,
	parameter	FEATURES = 3'b100,
	parameter 	GAMMA = 4'b0011
	) 
	
(	input logic 							sys_clk,   
	input logic								pe_clk,
	input logic 							reset_n,
	input logic								load_cell,
	input logic								start_load_input, 
	input logic  [ELEMENT_BITS-1:0]			cell_out_data_in,	// data being read from previous iteration
	input logic	 [FEATURE_BITS-1:0]			hidden_address,
	input logic  [ELEMENT_BITS-1:0]			main_mem_data_out,	// data being read from main memory
	/*output logic [FEATURE_BITS-1:0]			main_mem_address_out, //address to read from main memory
	output logic 							main_mem_oe_out, //address to read from main memory*/
	output logic							done_load_input,
	output logic [ELEMENT_BITS-1:0]	 		pe_data_in	// elements entering PEs 
);

localparam IDLE = 2'b00 ; 
localparam LOAD_CELL = 2'b01 ; 
localparam LOAD_INPUT = 2'b10 ; 
localparam OPERATE = 2'b11 ; 

//internal logics 
logic [2:0]					mode ; 
logic						operate_ag_done ; 
logic						operate_done ; 
logic [FEATURE_BITS-1:0]	load_input_address ; 
logic [FEATURE_BITS-1:0]	address_lim ; 

//input buffer - internal logics
logic [FEATURE_BITS-1:0] 	input_buff_address_out ;
logic [FEATURE_BITS-1:0] 	input_buff_address_in ;
logic 						input_buff_we_in ;
logic 						input_buff_oe_out ;
logic [ELEMENT_BITS-1:0]	input_buff_data_in ; 
logic						input_buff_clk ; 

//input buffer - instantiation of dpr 
dpr #(
	.FEATURE_BITS(FEATURE_BITS/2),
	.ELEMENT_BITS(ELEMENT_BITS),
	.RAM_DEPTH(M)
	) 
		input_buff (
			.sys_clk(input_buff_clk),
			.reset_n(reset_n),
			.address_in(input_buff_address_in),
			.data_in(input_buff_data_in),
			.cs_in(input_buff_we_in), 
			.we_in(input_buff_we_in),
			.address_out(input_buff_address_out),
			.oe_out(input_buff_oe_out),
			.cs_out(input_buff_oe_out),
			.data_out(pe_data_in)
			);

//input buffer out
ag_o #(
	.FEATURE_BITS(FEATURE_BITS),
	.P(P),
	.M(M),
	.GAMMA(GAMMA),
	.R(4'b0000)
	)
		operate_ag (
		.sys_clk(pe_clk),
		.reset_n(reset_n && (mode!=IDLE)),
		.start(input_buff_oe_out),
		.done(operate_ag_done),
		.address(input_buff_address_out)
		); 

assign	address_lim = (M>>1)-{{FEATURE_BITS-2{1'b0}},2'b10} ; 

// done_load_input
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) 
		done_load_input <= #1 1'b0 ; 
	else begin
		if (load_input_address==address_lim)
			done_load_input <= #1 1'b1 ; 
		else
			done_load_input <= #1 1'b0 ; 
	end
end

// load_input_address
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) 
		load_input_address <= #1 {FEATURE_BITS{1'b0}} ; 
	else begin
		if(done_load_input)
			load_input_address <= #1 {FEATURE_BITS{1'b0}} ; 
		else if (mode==LOAD_INPUT)
			load_input_address <= #1 load_input_address + {{FEATURE_BITS-1{1'b0}},1'b1} ; 
		else
			load_input_address <= #1 {FEATURE_BITS{1'b0}} ; 
	end
end

//operate_done reg
always_ff @(posedge pe_clk or negedge reset_n) begin
	if(!reset_n) begin
		operate_done <= #1 1'b0 ; 
	end
	else begin
		operate_done <= #1 operate_ag_done ; 
	end
end

//indicate that input top has finished loading and ready to start opertation
always_comb begin 
	if (mode==LOAD_CELL) begin
		input_buff_data_in = cell_out_data_in ; 
		input_buff_address_in = hidden_address ;
		input_buff_we_in = 1'b1 ; 
		input_buff_oe_out = 1'b0 ; 
		input_buff_clk = sys_clk ; 
	end
	else if (mode==LOAD_INPUT) begin
		input_buff_data_in = main_mem_data_out ; 
		input_buff_address_in =  load_input_address;
		input_buff_we_in = 1'b1 ; 
		input_buff_oe_out = 1'b0 ; 
		input_buff_clk = sys_clk ; 
	end
	else if (mode==OPERATE) begin
		input_buff_data_in = {ELEMENT_BITS{1'b0}} ; 
		input_buff_address_in = {FEATURE_BITS{1'b0}} ;
		input_buff_we_in = 1'b0 ; 
		input_buff_oe_out = !operate_done ? 1'b1 : 1'b0 ; 
		input_buff_clk = pe_clk ; 
	end
	else begin
		input_buff_data_in = {ELEMENT_BITS{1'b0}} ;  
		input_buff_address_in = {FEATURE_BITS{1'b0}};
		input_buff_we_in = 1'b0 ; 
		input_buff_oe_out = 1'b0 ; 
		input_buff_clk = sys_clk ; 
	end
end

// Mode sequencing 
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		mode <= #1 IDLE ; 
	end
	else begin
		case (mode)
			IDLE:
				if(load_cell)
					mode <= #1 LOAD_CELL ; 
				else if (start_load_input)
					mode <= #1 LOAD_INPUT ; 
				else 
					mode <= #1 IDLE ; 
			LOAD_CELL:
				mode <= #1 start_load_input ? LOAD_INPUT : LOAD_CELL ; 
			LOAD_INPUT:
				mode <= #1 done_load_input ? OPERATE : LOAD_INPUT ; 
			OPERATE:
				mode <= #1 operate_done ? IDLE : OPERATE ; 
		endcase 
	end
end

endmodule