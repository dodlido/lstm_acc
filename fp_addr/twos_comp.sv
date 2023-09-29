// a single proccessing element - PE
module twos_comp (
	input	logic			sign_a,
	input	logic			sign_b,
	input	logic	[5:0]	shifted_mant,
	
	output	logic	[5:0]	twos_small_mant
);

assign twos_small_mant = ((sign_a^sign_b)^(1'b0)) ? -(shifted_mant) : shifted_mant ; 

endmodule