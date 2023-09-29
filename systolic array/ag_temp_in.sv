

module ag_temp_in #(parameter FEATURE_BITS = 4, parameter TEMP_BUFF_DEPTH = 82, parameter M = 4'b1001) ( 			// number of bits required to count the features
	input logic 							sys_clk,	// systolic array clock
	input logic 							reset_n, 	// reset_n 
	input logic 							start,		//start activity
	output logic 							done,		//signal module is done
	output logic [(2 * FEATURE_BITS)-1:0] 	address		// address to temp_buff
);

logic [FEATURE_BITS-1:0] counter ; 
logic [FEATURE_BITS-1:0] lim ; 
logic offset ; 

//counter limit
assign lim = M-{{FEATURE_BITS-2{1'b0}},2'b10} ; 

//counter (offest calculation)
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		counter <= #1 {FEATURE_BITS{1'b0}} ;
	end
	else begin
		if ( done ) begin
			counter <= #1 {FEATURE_BITS{1'b0}} ;
		end
		else if (counter == lim) begin
			counter <= #1 {FEATURE_BITS{1'b0}} ;
		end
		else if ( start && !done) begin
			counter <= #1 counter + {{FEATURE_BITS-1{1'b0}},1'b1} ; 
		end
		else begin
			counter <= #1 {FEATURE_BITS{1'b0}} ; 
		end
	end
end

//offset (zero padding)
assign offset = (counter == lim ) ? 1'b1 : 1'b0 ; 

//address register
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		address <= #1 {2*FEATURE_BITS{1'b0}} ;
	end
	else begin
		if ( done ) begin
			address <= #1 {2*FEATURE_BITS{1'b0}} ;
		end
		else if ( start && !done) begin
			address <= #1 address + {{2*FEATURE_BITS-1{1'b0}},1'b1} + {{2*FEATURE_BITS-1{1'b0}},offset};
		end
		else begin
			address <= #1 address ; 
		end
	end
end

//done register
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		done <= #1 1'b0 ; 
	end
	else begin 
		if(  address >= (TEMP_BUFF_DEPTH - M - 3) )begin
			done <= #1 1'b1 ; 
		end
		else begin
			done <= #1 done ; 
		end
	end
end

endmodule