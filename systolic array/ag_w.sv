
//outputs address to read from temp_buff and Chip select signal for each W_i DPRs
module ag_w #(parameter FEATURE_BITS = 4, parameter P = 3'b100, parameter M = 4'b1001, parameter GAMMA = 4'b0011) ( 		// number of bits required to count the features
	input logic 							sys_clk,	// systolic array clock
	input logic 							reset_n,    // reset_n 
	input logic 							start,		//start activity
	output logic 							done,		//signal module is done
	output logic [(2 * FEATURE_BITS)-1:0] 	address,	// address from temp_buff
	output logic [FEATURE_BITS-2:0] 		cs			// chip select to W_i DPRs
);

logic [FEATURE_BITS-1:0] m_it ;						//iterator up to m-1
logic [FEATURE_BITS-1:0] gamma_it ;					//iterator up to gamma-1
logic [FEATURE_BITS-2:0] p_it ;						//iterator up to p-1
logic [(2 * FEATURE_BITS)-1:0] l1_in ; 
logic [(2 * FEATURE_BITS)-1:0] adder2_in_a ; 

//Chip Select
always_comb begin
	cs = p_it ; 
end

//adder1
always_comb begin
	l1_in = (!done) ? {{FEATURE_BITS{1'b0}},M} + adder2_in_a : {2*FEATURE_BITS{1'b0}} ; 
end

//adder2
always_comb begin
	address = (!done) ? {{FEATURE_BITS{1'b0}},m_it} + adder2_in_a : {2*FEATURE_BITS{1'b0}} ; 
end

//modulu m counter
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		m_it <= #1 {FEATURE_BITS{1'b0}} ;
	end
	else if ( m_it == M - {{(FEATURE_BITS-1){1'b0}},1'b1} ) begin
		m_it <= #1 {FEATURE_BITS{1'b0}} ;
	end
	else if(start && !done) begin
		m_it <= #1 m_it + {{(FEATURE_BITS-1){1'b0}},1'b1} ;
	end
	else begin
		m_it <= #1 m_it ; 
	end
end

//modulu p counter, enabled by modulu m counter
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		p_it <= #1 {(FEATURE_BITS-1){1'b0}} ;
	end
	else if ( ( p_it == P - {{(FEATURE_BITS-2){1'b0}},1'b1} ) && ( m_it == M - {{(FEATURE_BITS-1){1'b0}},1'b1} ) ) begin
		p_it <= #1 {(FEATURE_BITS-1){1'b0}} ;
	end
	else if ( m_it == M - {{(FEATURE_BITS-1){1'b0}},1'b1} ) begin //count 
		p_it <= #1 p_it + {{(FEATURE_BITS-2){1'b0}},1'b1} ;
	end
	else begin //do not count
		p_it <= #1 p_it ;
	end
end

//modulu gamma counter, enabled by modulu p counter
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		gamma_it <= #1 {(FEATURE_BITS){1'b0}} ;
	end
	else if ( ( gamma_it == GAMMA - {{(FEATURE_BITS-1){1'b0}},1'b1} ) && ( p_it == P - {{(FEATURE_BITS-2){1'b0}},1'b1} ) && ( m_it == M - {{(FEATURE_BITS-1){1'b0}},1'b1} ) ) begin
		gamma_it <= #1 {(FEATURE_BITS){1'b0}} ;
	end
	else if ( ( p_it == P - {{(FEATURE_BITS-2){1'b0}},1'b1} ) && ( m_it == M - {{(FEATURE_BITS-1){1'b0}},1'b1} ) ) begin //count 
		gamma_it <= #1 gamma_it + {{(FEATURE_BITS-1){1'b0}},1'b1} ;
	end
	else begin //do not count
		gamma_it <= #1 gamma_it ;
	end
end

//adder2_in_a register
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		adder2_in_a <= #1 {(2*FEATURE_BITS){1'b0}} ;
	end
	// done counting to gamma-1, p-1, m-1 --> reset this register
	else if ( ( p_it == P - {{(FEATURE_BITS-2){1'b0}},1'b1} ) && ( m_it == M - {{(FEATURE_BITS-1){1'b0}},1'b1} ) && ( gamma_it == GAMMA - {{(FEATURE_BITS-1){1'b0}},1'b1} ) ) begin
		adder2_in_a <= #1 {2*FEATURE_BITS{1'b0}} ;
	end
	// done counting to p-1, m-1 but not gamma-1 --> sample addder1 out
	else if ( ( p_it == P - {{(FEATURE_BITS-2){1'b0}},1'b1} ) && ( m_it == M - {{(FEATURE_BITS-1){1'b0}},1'b1} ) ) begin
		adder2_in_a <= #1 l1_in ;
	end
	// not done counting --> dont update this register
	else begin
		adder2_in_a <= #1 adder2_in_a ;
	end
end

//done register 
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		done <= #1 1'b0 ; 
	end
	else begin 
		if( ( gamma_it == GAMMA - {{(FEATURE_BITS-1){1'b0}},1'b1} ) && ( p_it == P - {{(FEATURE_BITS-2){1'b0}},1'b1} ) && ( m_it == M - {{(FEATURE_BITS-1){1'b0}},1'b1} ) ) begin
			done <= #1 1'b1 ;
		end
		else begin
			done <= #1 done ;
		end
	end
end

endmodule