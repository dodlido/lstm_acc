
module ag_cyc #(parameter FEATURE_BITS = 4, parameter LIM = 4'b1001) ( 			
	input logic 						sys_clk,		// systolic array clock
	input logic 						reset_n, 		// reset_n 
	input logic 						start,			//start activity
	output logic 						done,			//signal module is done
	output logic 	[FEATURE_BITS-1:0]	address_read,	// address generated
	output logic 						enable_read,
	output logic 	[FEATURE_BITS-1:0]	address_write,
	output logic 						enable_write
);

//address_read register
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		address_read <= #1 {(FEATURE_BITS){1'b0}} ; 
	end
	else begin 
		if (start && !done)
			address_read <= #1 address_read + {{FEATURE_BITS-1{1'b0}},1'b1} ;
		else 
			address_read <= #1 {(FEATURE_BITS){1'b0}} ; 
	end
end

//address_write register
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		address_write <= #1 {(FEATURE_BITS){1'b0}} ; 
	end
	else begin 
		address_write <= #1 address_read ; 
	end
end

//done register
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		done <= #1 1'b0 ; 
	end
	else begin 
		if ( address_write == LIM )
			done <= #1 1'b1 ; 
		else 
			done <= #1 1'b0 ; 
	end
end

//enable read
always_comb begin
	if (address_read >= LIM )
		enable_read = 1'b0 ; 
	else if (start && !done)
		enable_read = 1'b1 ; 
	else
		enable_read = 1'b0 ; 
end

//enable write
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		enable_write <= #1 1'b0 ; 
	end
	else begin 
		enable_write <= #1 enable_read ;  
	end
end

endmodule