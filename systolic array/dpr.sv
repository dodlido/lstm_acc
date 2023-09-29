
//implementation of a single DPR for weight matrix (there are P of those in top)
module dpr #(parameter FEATURE_BITS = 4, parameter ELEMENT_BITS = 8, parameter RAM_DEPTH = 27) ( 		// number of bits required to count the features
//TODO: calculate RAM_DEPTH somewhere else and use as input
	input logic sys_clk,        						// systolic array clock
	input logic reset_n,        						// reset_n 
	input logic [(2 * FEATURE_BITS)-1:0] address_in,	// address to dpr_w_i
	input logic [ELEMENT_BITS-1:0] data_in,				// 
	input logic cs_in,									// chip select to W_i DPRs
	input logic we_in,									// read\write enable
	input logic [(2 * FEATURE_BITS)-1:0] address_out,	// address from temp_buff
	input logic oe_out,									// output enable
	input logic cs_out,									// chip select out
	output logic [ELEMENT_BITS-1:0] data_out			// 
	
);

//define type regi the register
typedef bit [ELEMENT_BITS-1:0]	regi ;

//internal variables
regi [0:RAM_DEPTH-1] mem ; 

//memory write block
always_ff @(posedge sys_clk or negedge reset_n) begin
	mem <= #1 mem ; 
	if(!reset_n) begin
		mem <= #1 {(RAM_DEPTH*ELEMENT_BITS){1'b0}} ; 
	end
	else if ( cs_in && we_in ) begin
		mem[address_in] <= #1 data_in ; 
	end
end

//memory read block
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		data_out <= #1 {ELEMENT_BITS{1'b0}} ; 
	end
	else if ( oe_out && cs_out) begin
		data_out <= #1 mem[address_out] ;
	end
	else begin
		data_out <= #1 {ELEMENT_BITS{1'b0}} ; 
	end
end

endmodule