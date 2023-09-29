
// Address Generator for sys_out DPR
// This module outputs a 3-bit address for the sys_out DPR read / write operations
// r is 1'b1 so the first add and latch of the arch are redundant and thus were not implemented

module ag_o_ex #(parameter FEATURE_BITS = 4, parameter P = 3'b100, parameter M = 4'b1001, parameter GAMMA = 4'b0011, parameter R = 4'b0001) ( 		//number of bits required to count the features
	input logic 						sys_clk,    // systolic array clock
	input logic 						reset_n,    // reset_n 
	input logic 						start,		//start activity
	output logic 						done,		//signal module is done
	output logic [2*FEATURE_BITS-1:0]	address_ex	//an expansion from FEATURE_BITS to 2*FEATURE_BITS
);

logic [FEATURE_BITS-1:0]  	address_in; 
logic [FEATURE_BITS-1:0]	m_it;
logic [FEATURE_BITS-1:0]	gamma_it;
logic [2*FEATURE_BITS-1:0]  expansion_factor;
logic [2*FEATURE_BITS-1:0]  latch_in;


ag_o #(.FEATURE_BITS(FEATURE_BITS),.P(P),.M(M),.GAMMA(GAMMA), .R(R)) ag_o
				(.sys_clk(sys_clk),
				.reset_n(reset_n),
				.start(start),
				.address(address_in));

//adder1 
always_comb begin
	 address_ex = (!done) ? address_in + expansion_factor : {2*FEATURE_BITS{1'b0}}; 
end

//adder2
always_comb begin
	 latch_in = (!done) ? M + expansion_factor : {2*FEATURE_BITS{1'b0}} ; 
end

//modulu m counter
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		m_it <= #1 {FEATURE_BITS{1'b0}} ;
	end
	else if ( m_it == M-1 ) begin
		m_it <= #1 {FEATURE_BITS{1'b0}} ;
	end
	else if(start && !done) begin
		m_it <= #1 m_it + {{(FEATURE_BITS-1){1'b0}},1'b1} ;
	end
	else begin
		m_it <= #1 m_it ; 
	end
end

//modulu gamma counter, enabled by modulu m counter
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		gamma_it <= #1 {(FEATURE_BITS){1'b0}} ;
	end
	else if ( ( gamma_it == GAMMA - 1 ) && ( m_it == M - 1 ) ) begin
		gamma_it <= #1 {(FEATURE_BITS){1'b0}} ;
	end
	else if ( m_it == M - 1 ) begin //count 
		gamma_it <= #1 gamma_it + {{(FEATURE_BITS-1){1'b0}},1'b1} ;
	end
	else begin //do not count
		gamma_it <= #1 gamma_it ;
	end
end

//adder register
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		expansion_factor <= #1 {(2*FEATURE_BITS){1'b0}} ;
	end
	// done counting to m-1 
	else if ( m_it == M - 1 ) begin
		expansion_factor <= #1 latch_in ;
	end
	// not done counting --> dont update this register
	else begin
		expansion_factor <= #1 expansion_factor ;
	end
end

//done register 
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		done <= #1 1'b0 ; 
	end
	else begin 
		if( ( gamma_it == GAMMA - 1 ) && ( m_it == M - 1 ) ) begin
			done <= #1 1'b1 ;
		end
		else begin
			done <= #1 done ;
		end
	end
end

endmodule

