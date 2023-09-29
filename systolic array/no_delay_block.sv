

module no_delay_block #(parameter FEATURE_BITS = 4) ( 		
		input logic	[(2*FEATURE_BITS)-1:0]	address_in,
		input logic							enable_in,
		input logic							cs_in,
		output logic						enable_out,
		output logic						cs_out,
		output logic [(2*FEATURE_BITS)-1:0]	address_out
);

assign address_out = address_in ; 
assign cs_out = cs_in ; 
assign enable_out = enable_in ; 

endmodule