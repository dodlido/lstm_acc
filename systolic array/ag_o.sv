
// Address Generator for sys_out DPR
// This module outputs a 3-bit address for the sys_out DPR read / write operations
// r is 1'b1 so the first add and latch of the arch are redundant and thus were not implemented

module ag_o #(parameter FEATURE_BITS = 4, parameter P = 3'b100, parameter M = 4'b1001, parameter GAMMA = 4'b0011, parameter R = 4'b0001) ( 		//number of bits required to count the features
	input logic 					sys_clk,		// systolic array clock
	input logic 					reset_n,		// reset_n 
	input logic 					start,			//start activity
	output logic					done,
	output logic [FEATURE_BITS-1:0] address 		// Valid addresses are 0,1,2,3,4
);

logic [FEATURE_BITS-1:0] 			gamma_it ;	    // gamma_it is a counter: 0,1,2...gamma-1
logic [FEATURE_BITS-1:0] 			m_it;       	// m_it is a counter: 0,1,2...m-1
logic [(2 * FEATURE_BITS)-1:0]		adder2_in ;		// input of both adder2 and adder1
logic [2 * FEATURE_BITS:0] 			barrel_in ; 	// the result of gamma_it + m_it
logic [FEATURE_BITS-1:0] 			adder3_in_b ; 	// the result of the module's mux
logic [FEATURE_BITS-1:0] 			mux_in ; 		// input to module's mux 
logic [2 * FEATURE_BITS:0] 			modulu_in ;		// address before modulu 9 operation

//adder2
always_comb begin
	barrel_in = {{(FEATURE_BITS){1'b0}},adder2_in} + m_it ; 
end

//mux in calculator
always_comb begin
//calculate mux_in = [(m-1)/2]+1
	mux_in = M - {{(FEATURE_BITS-1){1'b0}},1'b1} ; 
	mux_in = mux_in >> 1 ;
	mux_in = mux_in + {{(FEATURE_BITS-1){1'b0}},1'b1} ; 
end

//mux
always_comb begin	
//if LSB of g_it+m_it then adder3_in_b = mux_in. otherwise 0.
	adder3_in_b = (barrel_in[0]) ? mux_in : {FEATURE_BITS{1'b0}} ;
end

//adder3 
always_comb begin	
	modulu_in = {{(FEATURE_BITS+1){1'b0}},adder3_in_b} + {1'b0,barrel_in[2 * FEATURE_BITS:1]} ;
	address = modulu_in % M ;
end

//adder2 register
always_ff @(posedge sys_clk or negedge reset_n) begin
	if (!reset_n) begin
		adder2_in <= #1 {(2 * FEATURE_BITS){1'b0}} ;
	end
	else if( ( gamma_it == GAMMA - 1 ) && ( m_it == M - 1 ) ) begin
		adder2_in <= #1 {(2 * FEATURE_BITS){1'b0}} ;
	end
	else if ( m_it == M - 1 ) begin
		adder2_in <= #1 adder2_in + {{(FEATURE_BITS){1'b0}},R};
	end
	else begin
		adder2_in <= #1 adder2_in;
	end
end

//m_it register
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		m_it <= #1 {(FEATURE_BITS-1){1'b0}} ; 
	end
	else begin 
		if( ( gamma_it == GAMMA ) || ( m_it == M - 1 ) ) begin
			m_it <= #1 {(FEATURE_BITS-1){1'b0}} ; 
		end
		else if (start) begin
			m_it <= #1 m_it + {{(FEATURE_BITS-1){1'b0}},1'b1} ; 
		end
		else begin
			m_it <= #1 m_it ;
		end
	end
end

//gamma_it register 
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		gamma_it <= #1 {FEATURE_BITS{1'b0}} ; 
	end
	else begin 
		if( ( gamma_it == GAMMA-1 ) && ( m_it == M-1 ) ) begin
			gamma_it <= #1 {FEATURE_BITS{1'b0}} ; 
		end
		else if ( m_it == M-1 ) begin
			gamma_it <= #1 gamma_it + {{(FEATURE_BITS-1){1'b0}},1'b1} ; 
		end
		else begin
			gamma_it <= #1 gamma_it ; 
		end
	end
end

//done register 
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		done <= #1 1'b0 ; 
	end
	else begin 
		if( ( gamma_it == GAMMA-1 ) && ( m_it == M-1 ) ) begin
			done <= #1 1'b1 ; 
		end
		else begin
			done <= #1 done ; 
		end
	end
end

endmodule

