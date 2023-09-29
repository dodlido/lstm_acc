// a single proccessing element - PE
module zero_detect (
	input	logic			sign_a,
	input	logic			sign_b,
	input	logic	[3:0]	exp_diff,
	input	logic	[4:0]	mant_diff,
	output	logic			zero
);

always@(sign_a or sign_b or exp_diff or mant_diff) begin
	if((sign_a!=sign_b)&&(exp_diff==4'b0000)&&(mant_diff==5'b00000))
		zero <= 1'b1 ; 
	else
		zero <= 1'b0 ; 
end

endmodule