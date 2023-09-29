/*
	This module is the top of all tops
*/
module top
// module parameters
#(	parameter 	ELEMENT_BITS = 8,
	parameter 	P = 3'b100,
	parameter	FEATURES = 3'b100,
	parameter 	GAMMA = 4'b0011
)
//local parameters 
localparam M = {FEATURES,1'b1} ; 

//interface
(
	input  logic							fpga_clk,			// clk from FPGA oscillator
	input  logic							reset_n,			// system reset, active low
	input  logic 							start, 				// wake system up, active high, pulse
	input  logic	[ELEMENT_BITS-1:0]		data_in,	
	output logic	[2:0]					op_mode,			// system mode
	output logic	[ELEMENT_BITS-1:0]		data_out	
);

//mode definition
localparam IDLE     = 3'b000 ; 
localparam INIT_W1  = 3'b001 ; 
localparam INIT_W2  = 3'b010 ; 
localparam W_IN     = 3'b011 ;
localparam CALC     = 3'b100 ;
localparam R_OUT    = 3'b101 ;

//parameters
localparam ZERO_2FEAT = {2*FEATURES{1'b0}} ; 
localparam ZERO_FEAT = {FEATURES{1'b0}} ; 
localparam ZERO_ELE = {ELEMENT_BITS{1'b0}} ; 

//clks
logic	sys_clk ; 
logic	pe_clk	;
logic	cell_clk ; 

//bottom hierarchy done\start signals
logic									r_out_done ; 	//output serializer done signal
logic									w1_init_done ; 
logic									w2_init_done ; 
logic									w_in_done ; 
logic									w1_des_start ; 
logic									w2_des_start ;
logic									calc_done ; 
//logic	[2:0]							op_mode_delayed;	// system mode, delayed by 1 clk cycle 

//bottom hierarchy data 
logic [ELEMENT_BITS - 1:0] 				h_curr_ser ; 
logic [FEATURE_BITS - 1:0]				hidden_address ; 

logic [2*FEATURES*ELEMENT_BITS - 1:0] 	w1_des ;  
logic [2*FEATURES*ELEMENT_BITS - 1:0] 	w2_des ;  
logic [ELEMENT_BITS - 1:0] 				w1_ser ;  
logic [ELEMENT_BITS - 1:0]				w2_ser ; 

//mode sequencing
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) 
		op_mode <= #1 IDLE ; 
	else begin
		case(op_mode)
			IDLE:
				op_mode <= #1 start 		? INIT_W1 : IDLE ; 
			INIT_W1:
				op_mode <= #1 w1_init_done 	? INIT_W2 : INIT_W1 ; 
			INIT_W2:
				op_mode <= #1 w2_init_done 	? W_IN	  : INIT_W2 ; 
			W_IN:
				op_mode <= #1 w_in_done		? CALC    : W_IN ; 
			CALC:
				op_mode <= #1 calc_done		? R_OUT   : CALC ; 
			R_OUT:
				op_mode <= #1 r_out_done	? W_IN    : R_OUT ; 
		endcase
	end
end/*
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) 
		op_mode_delayed <= #1 IDLE ; 
	else 
		op_mode_delayed <= #1 op_mode ; 
end*/

clk_gen clk_gen (
		.fpga_clk(fpga_clk), 	// clk from FPGA oscillator
		.reset_n(reset_n),      
		.sys_clk(sys_clk),		// system clock, same as fpga_clk
		.pe_clk(pe_clk),	    // proccessing element clock, slow enough to fit a single * op
		.cell_clk(cell_clk)		// lstm cell clock, slowest, slower by 2 in comparison to pe_clk
		);

sys_top #(
			.FEATURE_BITS(FEATURES),
			.ELEMENT_BITS(ELEMENT_BITS),
			.P(P),
			.GAMMA(GAMMA),
			.M(M)
		)
		wi_wg_arr
		(
			.pe_clk(pe_clk),
			.sys_clk(sys_clk),
			.reset_n(reset_n),
			.start_load_weight(op_mode==INIT_W1),
			.start_load_hidden(op_mode==R_OUT),
			.start_load_input(op_mode==W_IN),
			.done_load_weight(w1_init_done),
			.done_load_input(w_in_done),
			.lc_data_in(h_curr_ser),
			.mmw_data(data_in),
			.mmi_data(data_in),
			.lc_data_out(w1_ser),
			.hidden_address(hidden_address),
			.lc_oe_out(w1_des_start)
);

deserializer #(
	.ELEMENT_BITS(ELEMENT_BITS),
	.FEATURES(FEATURES),
	.FEATURE_BITS(FEATURES),
	.M(M)
	)
des_wi_wg (
	.clk(sys_clk),
	.reset_n((reset_n)&&(op_mode==CALC)),
	.start(w1_des_start),
	.serial_data_in(w1_ser),
	.parallel_data_out_1(w1_des[FEATURES*ELEMENT_BITS-1:0]),
	.parallel_data_out_2(w1_des[2*FEATURES*ELEMENT_BITS-1:FEATURES*ELEMENT_BITS]),
	.done(w1_des_done)
	);

sys_top #(
			.FEATURE_BITS(FEATURES),
			.ELEMENT_BITS(ELEMENT_BITS),
			.P(P),
			.GAMMA(GAMMA),
			.M(M)
		)   
		wf_wo_arr
		(
			.pe_clk(pe_clk),
			.sys_clk(sys_clk),
			.reset_n(reset_n),
			.start_load_weight(op_mode==INIT_W2),
			.start_load_hidden(op_mode==R_OUT),
			.start_load_input(op_mode==W_IN),
			.done_load_weight(w2_init_done),
			.lc_data_in(h_curr_ser),
			.mmw_data(data_in),
			.mmi_data(data_in),
			.lc_data_out(w2_ser),
			.hidden_address(hidden_address),
			.lc_oe_out(w2_des_start)
);

deserializer #(
	.ELEMENT_BITS(ELEMENT_BITS),
	.FEATURES(FEATURES),
	.FEATURE_BITS(FEATURES),
	.M(M)
	)
des_wf_wo (
	.clk(sys_clk),
	.reset_n((reset_n)&&(op_mode==CALC)),
	.start(w2_des_start),
	.serial_data_in(w2_ser),
	.parallel_data_out_1(w2_des[FEATURES*ELEMENT_BITS-1:0]),
	.parallel_data_out_2(w2_des[2*FEATURES*ELEMENT_BITS-1:FEATURES*ELEMENT_BITS]),
	.done(w2_des_done)
	);

lstm_cell #(.ELEMENT_BITS(ELEMENT_BITS),
			.FEATURES(FEATURES)
			)
			lstm_cell (
				.sys_clk(sys_clk),
				.cell_clk(cell_clk),
				.reset_n(reset_n),
				.done_w1(w1_des_done),
				.done_w2(w2_des_done),
				.wi_xt(w1_des[FEATURES*ELEMENT_BITS-1:0]),
				.wf_xt(w2_des[FEATURES*ELEMENT_BITS-1:0]),
				.wg_xt(w1_des[2*FEATURES*ELEMENT_BITS-1:FEATURES*ELEMENT_BITS]),
				.wo_xt(w2_des[2*FEATURES*ELEMENT_BITS-1:FEATURES*ELEMENT_BITS]),
				.read_output(op_mode==R_OUT),
				.h_curr_ser(h_curr_ser),
				.hidden_address(hidden_address),
				.done_wr(calc_done),
				.done_re(r_out_done)
);

// output
assign data_out = h_curr_ser ; 

endmodule