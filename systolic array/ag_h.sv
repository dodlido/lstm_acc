

module ag_h #(parameter FEATURE_BITS = 4, parameter M = 4'b1001) ( 			// number of bits required to count the features
	input logic 							sys_clk,	// systolic array clock
	input logic 							reset_n, 	// reset_n 
	input logic 							start,		//start activity
	output logic 							done,		//signal module is done
	output logic [(2 * FEATURE_BITS)-1:0] 	address		// address to temp_buff
);

logic [FEATURE_BITS-1:0] i_it ;						//iterator up to m-1
logic [FEATURE_BITS-1:0] k_it ;						//iterator up to m-1
logic [FEATURE_BITS:0] adder3_in_a ;				//
logic [(2 * FEATURE_BITS)-1:0] adder3_in_b ;
logic [(2 * FEATURE_BITS)-1:0] l1_in ;


//adder1
always_comb begin
	l1_in = M + adder3_in_b ;
end

//adder2
always_comb begin
	adder3_in_a = ( {1'b1,i_it} + {1'b1,k_it} ) % M ;
end

//adder3
always_comb begin
	address = {{(FEATURE_BITS-1){1'b0}},adder3_in_a} + adder3_in_b ;
end

//L1 register
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		adder3_in_b <= #1 {2*FEATURE_BITS{1'b0}} ;
	end
	//Etay added this alone so mistakes are bound to be made
	else if ( k_it == M - 1 ) begin
		adder3_in_b <= #1 {2*FEATURE_BITS{1'b0}} ;
	end
	//end of Etay shananigans
	else if (start && !done) begin
		adder3_in_b <= #1 l1_in ;
	end
	else begin
		adder3_in_b <= #1 adder3_in_b ;
	end
end

//k_it register
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		k_it <= #1 {(FEATURE_BITS-1){1'b0}} ; 
	end
	else begin 
		if( k_it == M - 1 )begin
			k_it <= #1 {(FEATURE_BITS-1){1'b0}} ; 
		end
		else if( start && !done) begin
			k_it <= #1 k_it + {{(FEATURE_BITS-1){1'b0}},1'b1} ; 
		end
		else begin
			k_it <= #1 k_it ; 
		end
	end
end

//i_it register 
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		i_it <= #1 {FEATURE_BITS{1'b0}} ; 
	end
	else begin 
		if( ( i_it == M - 1 ) && ( k_it == M - 1 ) ) begin
			i_it <= #1 {FEATURE_BITS{1'b0}} ; 
		end
		else if ( k_it == M - 1 ) begin
			i_it <= #1 i_it + {{(FEATURE_BITS-1){1'b0}},1'b1} ; 
		end
		else begin
			i_it <= #1 i_it ; 
		end
	end
end

//done register 
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		done <= #1 1'b0 ; 
	end
	else begin 
		if( ( i_it == M - 1 ) && ( k_it == M - 1 ) ) begin
			done <= #1 1'b1 ;
		end
		else begin
			done <= #1 done ;
		end
	end
end

endmodule