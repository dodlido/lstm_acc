// generation of PE array
module pe_array #(parameter ELEMENT_BITS = 8, parameter P = 3'b100) (
	input logic								pe_clk,			//times data movement across the PE array
	input logic 							sys_clk,		//a faster clock, used for multiplying 
	input logic 							reset_n,        
	input logic 	[P*ELEMENT_BITS-1:0]	weight_data_in,
	input logic 	[ELEMENT_BITS-1:0]	 	input_data_in,		
	input logic 	[ELEMENT_BITS-1:0]		output_data_in,
	output logic	[ELEMENT_BITS-1:0]		output_data_out
);
//internal logics
logic [(P-1)*ELEMENT_BITS-1:0] array_input_last_pe ; 
logic [(P-1)*ELEMENT_BITS-1:0] array_input_next_pe ; 
//generation of array
genvar p_index ; 
for (p_index = 0; p_index < P; p_index++ ) begin
	//generation of first PE
	if(p_index==0) begin
		pe #(.ELEMENT_BITS(ELEMENT_BITS), .P(P)) pe (
				.pe_clk(pe_clk),
				.sys_clk(sys_clk),
				.reset_n(reset_n),
				.input_weight(weight_data_in[ELEMENT_BITS-1:0]),
				.input_last_pe(output_data_in),
				.input_next_pe(array_input_next_pe[ELEMENT_BITS-1:0]),
				//.output_last_pe(), NC - not used
				.output_next_pe(array_input_last_pe[ELEMENT_BITS-1:0])
		);
	end
	//generation of last PE
	else if(p_index==P-1) begin
		pe #(.ELEMENT_BITS(ELEMENT_BITS), .P(P)) pe (
				.pe_clk(pe_clk),
				.sys_clk(sys_clk),
				.reset_n(reset_n),
				.input_weight(weight_data_in[P*ELEMENT_BITS-1:(P-1)*ELEMENT_BITS]),
				.input_last_pe(array_input_last_pe[(P-1)*ELEMENT_BITS-1:(P-2)*ELEMENT_BITS]),
				.input_next_pe(input_data_in),
				.output_last_pe(array_input_next_pe[(P-1)*ELEMENT_BITS-1:(P-2)*ELEMENT_BITS]),
				.output_next_pe(output_data_out)
		);
	end
	//generation of all the middle PEs
	else begin
		pe #(.ELEMENT_BITS(ELEMENT_BITS), .P(P)) pe (
				.pe_clk(pe_clk),
				.sys_clk(sys_clk),
				.reset_n(reset_n),
				.input_weight(weight_data_in[ELEMENT_BITS*(p_index+1)-1:ELEMENT_BITS*p_index]),
				.input_last_pe(array_input_last_pe[ELEMENT_BITS*(p_index)-1:ELEMENT_BITS*(p_index-1)]),
				.input_next_pe(array_input_next_pe[ELEMENT_BITS*(p_index+1)-1:ELEMENT_BITS*p_index]),
				.output_last_pe(array_input_next_pe[ELEMENT_BITS*(p_index)-1:ELEMENT_BITS*(p_index-1)]),
				.output_next_pe(array_input_last_pe[ELEMENT_BITS*(p_index+1)-1:ELEMENT_BITS*p_index])
		);
	end
end
endmodule

