module weight_top 
#(	parameter 	FEATURE_BITS = 4,
	parameter 	ELEMENT_BITS = 8,
	parameter 	P = 3'b100,
	parameter 	M = 4'b1001,
	parameter 	GAMMA = 4'b0011) 
	
(	input logic 							sys_clk, 
	input logic								pe_clk,
	input logic 							reset_n,
	input logic								load,
	input logic 							start,
	input logic  [ELEMENT_BITS-1:0]			main_mem_data,	// data being read from main memory
	output logic 							load_done,
	/*output logic [2 * FEATURE_BITS-1:0]		main_mem_address,
	output logic 							main_mem_oe_out,
	output logic 							main_mem_cs_out,*/
	output logic [P*ELEMENT_BITS-1:0]	 	pe_data_in		// elements entering PEs //was 2-dim
);

localparam TEMP_BUFF_DEPTH = {{FEATURE_BITS{1'b0}},M}*{{FEATURE_BITS{1'b0}},M} + {{{2*FEATURE_BITS-1}{1'b0}},1'b1}; 
//last address is reserved for 0 element to feed into weight DPRs extra slots

localparam WEIGHT_BUFF_DEPTH = {{FEATURE_BITS{1'b0}},M}*{{FEATURE_BITS{1'b0}},GAMMA} ;

localparam R = M-{P,1'b0} ; 

//internal logic declaration

//temp buff
logic [2*FEATURE_BITS-1:0] temp_buff_address_in ;
logic [2*FEATURE_BITS-1:0] temp_buff_address_out ;
logic temp_buff_cs_in ;
logic temp_buff_cs_out ;
logic temp_buff_we_in ;
logic temp_buff_oe_out ;

//weight DPRs
logic [2 * FEATURE_BITS-1:0] 		weight_dpr_address_in ;
logic [2 * FEATURE_BITS-1:0]		weight_dpr_address_out ;
logic [2*FEATURE_BITS*P-1:0]		weight_dpr_address_out_delayed ; //was 2-dim
logic [P-1:0] 						weight_dpr_cs_in ;
logic 								weight_dpr_cs_out ;
logic [P-1:0] 						weight_dpr_cs_out_delayed ;
logic [P-1:0] 						weight_dpr_we_in ;
logic								weight_dpr_oe_out ;
logic [P-1:0] 						weight_dpr_oe_out_delayed ;
logic [ELEMENT_BITS-1:0] 			weight_dpr_data_in ;
logic [P*ELEMENT_BITS-1:0] 			weight_dpr_data_out ;//was 2-dim
logic								weight_dpr_clk ; 

//address generation logics
logic [FEATURE_BITS-2:0] 			cs_decoder_in ; 
logic 								cs_decoder_enable ;
logic								ag_main_mem_start ; 
logic								ag_main_mem_done ; 
logic 								ag_temp_in_start ; 
logic								ag_temp_in_done ;
logic 								ag_w_start ; 
logic								ag_w_done ;
logic 								ag_o_ex_start ; 
logic								ag_o_ex_done ;
logic								ag_temp_out_start ; 
logic								ag_temp_out_done ; 

//temp_buff - instantiation of dpr 
dpr #(
	.FEATURE_BITS(FEATURE_BITS),
	.ELEMENT_BITS(ELEMENT_BITS),
	.RAM_DEPTH(TEMP_BUFF_DEPTH)
	) 
		temp_buff (
			.sys_clk(sys_clk),
			.reset_n(reset_n),
			.address_in(temp_buff_address_in),
			.data_in(main_mem_data),
			.cs_in(temp_buff_cs_in), 
			.we_in(temp_buff_we_in),
			.address_out(temp_buff_address_out),
			.oe_out(temp_buff_oe_out),
			.cs_out(temp_buff_cs_out),
			.data_out(weight_dpr_data_in)
			);

// generate P weight DPRs
genvar p_index ; 
generate
	for (p_index = 0; p_index < P; p_index++) begin
		//weights dpr
		dpr #(
			.FEATURE_BITS(FEATURE_BITS),
			.ELEMENT_BITS(ELEMENT_BITS),
			.RAM_DEPTH(WEIGHT_BUFF_DEPTH)
			) 
			weight_dpr (
				.sys_clk(weight_dpr_clk),
				.reset_n(reset_n),
				.address_in(weight_dpr_address_in),
				.data_in(weight_dpr_data_in),
				.cs_in(weight_dpr_cs_in[p_index]), 
				.we_in(weight_dpr_we_in[p_index]),
				.address_out(weight_dpr_address_out_delayed[2*FEATURE_BITS*(p_index+1)-1:2*FEATURE_BITS*p_index]),
				.oe_out(weight_dpr_oe_out_delayed[p_index]),
				.cs_out(weight_dpr_cs_out_delayed[p_index]),
				.data_out(weight_dpr_data_out[ELEMENT_BITS*(p_index+1)-1:ELEMENT_BITS*p_index])
			); 	
		//delay blocks
		if(!p_index) begin  //corner case of no delay
			no_delay_block #(
							.FEATURE_BITS(FEATURE_BITS)
							)
			no_delay (
				.address_in(weight_dpr_address_out),
				.enable_in(weight_dpr_oe_out),
				.cs_in(weight_dpr_cs_out),
				.address_out(weight_dpr_address_out_delayed[2 * FEATURE_BITS-1:0]),
				.enable_out(weight_dpr_oe_out_delayed[0]),
				.cs_out(weight_dpr_cs_out_delayed[0])
				);
		end
		else begin //rest of delay blocks
			delay_block #(
						.P_INDEX(p_index),
						.FEATURE_BITS(FEATURE_BITS)
						) 
			delay_block (
				.sys_clk(weight_dpr_clk),
				.reset_n(reset_n),
				.address_in(weight_dpr_address_out),
				.enable_in(weight_dpr_oe_out),
				.cs_in(weight_dpr_cs_out),
				.enable_out(weight_dpr_oe_out_delayed[p_index]),
				.cs_out(weight_dpr_cs_out_delayed[p_index]),
				.address_out(weight_dpr_address_out_delayed[2*FEATURE_BITS*(p_index+1)-1:2*FEATURE_BITS*p_index])
			);
		end
		//selectors
		selector #(
			.ELEMENT_BITS(ELEMENT_BITS)
			)
		output_selector(
			.sys_clk(weight_dpr_clk),
			.reset_n(reset_n),
			.data_in(weight_dpr_data_out[ELEMENT_BITS*(p_index+1)-1:ELEMENT_BITS*p_index]),
			.enable(weight_dpr_cs_out_delayed[p_index]),
			.data_out(pe_data_in[ELEMENT_BITS*(p_index+1)-1:ELEMENT_BITS*p_index])
		);
	end
endgenerate
				
//instantiate address generators
/*ag_h #(
	.FEATURE_BITS(FEATURE_BITS),
	.M(M)
	)
		ag_main_mem (
		.sys_clk(sys_clk),
		.reset_n(reset_n),
		.start(ag_main_mem_start),
		.done(ag_main_mem_done),
		.address(main_mem_address)
		);
*/		
ag_temp_in 	#(
		.FEATURE_BITS(FEATURE_BITS),
		.TEMP_BUFF_DEPTH(TEMP_BUFF_DEPTH),
		.M(M)
		)
		ag_temp_buff_in (
			.sys_clk(sys_clk),
			.reset_n(reset_n),
			.start(ag_temp_in_start),
			.done(ag_temp_in_done),
			.address(temp_buff_address_in)
		);
			
ag_w #(
		.FEATURE_BITS(FEATURE_BITS),
		.P(P),
		.M(M),
		.GAMMA(GAMMA)
		)
		ag_weight_dpr_in  (
			.sys_clk(sys_clk),
			.reset_n(reset_n),
			.start(ag_w_start),
			.done(ag_w_done),
			.address(weight_dpr_address_in),
			.cs(cs_decoder_in)
		);

ag_o_ex #(
		.FEATURE_BITS(FEATURE_BITS),
		.P(P),
		.M(M),
		.GAMMA(GAMMA),
		.R(R)
		) 
		ag_weight_dpr_out(
			.sys_clk(pe_clk),
			.reset_n(reset_n && start),
			.start(ag_o_ex_start),
			.done(ag_o_ex_done),
			.address_ex(weight_dpr_address_out)
		);

ag_h #( //was ag_temp_out
			.FEATURE_BITS(FEATURE_BITS),
			.M(M)
			) 
		ag_temp_out(
			.sys_clk(sys_clk),
			.reset_n(reset_n),
			.start(ag_temp_out_start),
			.done(ag_temp_out_done),
			.address(temp_buff_address_out)
		);

	
// chip select decoder (from temp buff to DPR)
always_comb begin
	weight_dpr_cs_in = (cs_decoder_enable) ? (1 << cs_decoder_in) : {P{1'b0}} ;
end
/*
//main mem read enable
always_comb begin
	//read from main memory
	if (ag_main_mem_start && !ag_main_mem_done) begin
		main_mem_oe_out = 1'b1 ;
		main_mem_cs_out = 1'b1 ;
	end
	//do not read
	else begin
		main_mem_oe_out = 1'b0 ;
		main_mem_cs_out = 1'b0 ;
	end
end
*/
//temp buff write/read enable
always_comb begin
	//read from main memory
	if (ag_temp_in_start && !ag_temp_in_done) begin
		temp_buff_we_in = 1'b1 ;
		temp_buff_cs_in = 1'b1 ;
		temp_buff_oe_out = 1'b0 ;
		temp_buff_cs_out = 1'b0 ;
	end
	//write to DPR_w
	else if (ag_temp_out_start && !ag_temp_out_done) begin
		temp_buff_we_in = 1'b0 ;
		temp_buff_cs_in = 1'b0 ;
		temp_buff_oe_out = 1'b1 ;
		temp_buff_cs_out = 1'b1 ;
	end
	else begin
		temp_buff_we_in = 1'b0 ;
		temp_buff_cs_in = 1'b0 ;
		temp_buff_oe_out = 1'b0 ;
		temp_buff_cs_out = 1'b0 ;
	end
end

//weight DPR write/read enable 
always_comb begin
//read from temp buff
	if (ag_w_start && !ag_w_done) begin
		weight_dpr_we_in = {P{1'b1}} ;
		cs_decoder_enable = 1'b1 ;
		weight_dpr_oe_out = 1'b0 ;
		weight_dpr_cs_out = 1'b0 ;
		weight_dpr_clk = sys_clk ; 
	end
	//write PEs
	else if (ag_o_ex_start && !ag_o_ex_done) begin
		weight_dpr_we_in = {P{1'b0}} ;
		cs_decoder_enable = 1'b0 ;
		weight_dpr_oe_out = 1'b1 ;
		weight_dpr_cs_out = 1'b1 ;
		weight_dpr_clk = pe_clk ; 
	end
	else begin
		weight_dpr_we_in = {P{1'b0}} ;
		cs_decoder_enable = 1'b0 ;
		weight_dpr_oe_out = 1'b0 ;
		weight_dpr_cs_out = 1'b0 ;
		weight_dpr_clk = pe_clk ; 
	end
end
// Start/Done sequencing 
	/*
	//ag_main_mem: main memory out address generation
	always_ff @(posedge sys_clk or negedge reset_n) begin
		if(!reset_n) begin
			ag_main_mem_start <= #1 1'b0 ; 
		end
		else if( load && !ag_main_mem_done ) begin
			ag_main_mem_start <= #1 1'b1 ;
		end
		else begin
			ag_main_mem_start <= #1 ag_main_mem_start ;
		end
	end
	*/
	//ag_temp_in: temp buff in address generation
	always_ff @(posedge sys_clk or negedge reset_n) begin
		if(!reset_n) begin
			ag_temp_in_start <= #1 1'b0 ; 
		end
		else if( load && !ag_temp_in_done ) begin
			ag_temp_in_start <= #1 1'b1 ;
		end
		else begin
			ag_temp_in_start <= #1 ag_temp_in_start ;
		end
	end
	//ag_temp_out: temp_buffer out address generation
	always_ff @(posedge sys_clk or negedge reset_n) begin
		if(!reset_n) begin
			ag_temp_out_start <= #1 1'b0 ; 
		end
		else if(ag_temp_in_done && !ag_temp_out_done) begin
			ag_temp_out_start <= #1 1'b1 ;
		end
		else begin
			ag_temp_out_start <= #1 1'b0 ;
		end
	end
	//ag_w: weight_DPRs in address generation
	always_ff @(posedge sys_clk or negedge reset_n) begin
		if(!reset_n) begin
			ag_w_start <= #1 1'b0 ; 
		end
		else if(ag_temp_out_start && !ag_temp_out_done) begin
			ag_w_start <= #1 1'b1 ;
		end
		else begin
			ag_w_start <= #1 1'b0 ;
		end
	end
	//ag_o: weight_DPRs out address generation
	always_ff @(posedge sys_clk or negedge reset_n) begin
		if(!reset_n) begin
			ag_o_ex_start <= #1 1'b0 ; 
		end
		else if(start && !ag_o_ex_done) begin
			ag_o_ex_start <= #1 1'b1 ;
		end
		else begin
			ag_o_ex_start <= #1 1'b0 ;
		end
	end

//load done register
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		load_done <= #1 1'b0 ; 
	end
	else if(ag_temp_out_done) begin
		load_done <= #1 1'b1 ;
	end
	else begin
		load_done <= #1 1'b0 ; 
	end
end

endmodule