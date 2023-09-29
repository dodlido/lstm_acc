
// Address Generator for sys_out DPR
// This module outputs a 3-bit address for the sys_out DPR read / write operations
// r is 1'b1 so the first add and latch of the arch are redundant and thus were not implemented

module ag_temp_out #(parameter FEATURE_BITS = 4, parameter P = 3'b100, parameter TEMP_BUFF_DEPTH = 82, parameter WEIGHT_BUFF_DEPTH = 27) ( 		//number of bits required to address the features
	input logic 						sys_clk,		// systolic array clock
	input logic 						reset_n,        // reset_n 
	input logic 						start,			//start activity
	output logic [2*FEATURE_BITS-1:0]   address, 		//
	output logic 						done			//1 when done
);

localparam 								DIFF = WEIGHT_BUFF_DEPTH * P ; 

logic [2*FEATURE_BITS-1:0] 				count ; 

//address register
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		address <= #1 {2*FEATURE_BITS{1'b0}} ; 
	end
	else begin 
		if ( address < TEMP_BUFF_DEPTH - 1 && start && !done) begin
			address <= #1 address + {{(2*FEATURE_BITS-1){1'b0}},1'b1} ; 
		end
		else if (done) begin
			address <= #1 {2*FEATURE_BITS{1'b0}} ; 
		end
		else begin
			address <= #1 address ; 
		end
	end
end

//count register
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		count <= #1 {2*FEATURE_BITS{1'b0}} ; 
	end
	else begin 
		if ( count < DIFF && start && !done) begin
			count <= #1 count + {{(2*FEATURE_BITS-1){1'b0}},1'b1} ; 
		end
		else if (done) begin
			count <= #1 {2*FEATURE_BITS{1'b0}} ; 
		end
		else begin
			count <= #1 count ; 
		end
	end
end

//done register
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		done <= #1 1'b0 ; 
	end
	else begin 
		if (count == DIFF) begin
			done <= #1 1'b1 ; 
		end
		else begin
			done <= #1 done ; 
		end
	end
end

endmodule

