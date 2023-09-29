// a single proccessing element - PE
module pe #(parameter ELEMENT_BITS = 8, parameter P = 3'b100) (
	input logic							pe_clk,			//times data movement across the PE array
	input logic 						sys_clk,		//a faster clock, used for multiplying 
	input logic 						reset_n,        
	input logic		[ELEMENT_BITS-1:0]	input_weight,
	input logic		[ELEMENT_BITS-1:0]	input_last_pe,
	input logic		[ELEMENT_BITS-1:0]	input_next_pe,
	output logic	[ELEMENT_BITS-1:0]	output_last_pe,
	output logic	[ELEMENT_BITS-1:0]	output_next_pe
);
//Change this to choose adder and multiplier OP mode: 0-FP, 1-Decimal
localparam DECI = 1'b1 ; 

// internal logic decleration

logic [ELEMENT_BITS-1:0] mul_out;
logic [ELEMENT_BITS-1:0] adder_out;
logic [7:0]			     mult_status ;

mult_top pe_mult (.in_a(input_weight),.in_b(input_next_pe),.mode(DECI),.res(mul_out)) ; 
addr_top pe_addr (.in_a(mul_out),.in_b(input_last_pe),.mode(DECI),.res(adder_out)) ; 

// output_last_pe register
always_ff @(posedge pe_clk or negedge reset_n) begin
	if(!reset_n) begin
		output_last_pe <= #1 {ELEMENT_BITS{1'b0}} ; 
	end
	else begin 
		output_last_pe <= #1 input_next_pe ; 
	end
end
// output_next_pe register
always_ff @(posedge pe_clk or negedge reset_n) begin
	if(!reset_n) begin
		output_next_pe <= #1 {ELEMENT_BITS{1'b0}} ; 
	end
	else begin 
		output_next_pe <= #1 adder_out ; 
	end
end
endmodule

