
module add #(parameter ELEMENT_BITS = 8) (
		input logic		[ELEMENT_BITS-1:0]		data_in_a,
		input logic		[ELEMENT_BITS-1:0]		data_in_b,
		output logic	[ELEMENT_BITS-1:0]		data_out
);

always_comb begin
	data_out = data_in_a + data_in_b ; 
end

endmodule