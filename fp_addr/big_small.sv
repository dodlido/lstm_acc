// a single proccessing element - PE
module big_small (
	input	logic	[3:0]	mant_a,
	input	logic	[3:0]	mant_b,
	input	logic	[3:0]	exp_diff,
	input	logic			exp_diff_sig,
	input	logic			mant_diff_sig,
	
	output	logic	[3:0]	big_mant,
	output	logic	[3:0]	small_mant
);

always@(mant_a or mant_b or exp_diff or exp_diff_sig or mant_diff_sig ) begin
	if (exp_diff==4'b0000) begin
		big_mant <= mant_diff_sig ? mant_b : mant_a ; 
		small_mant <= mant_diff_sig ? mant_a : mant_b ; 
	end
	else begin
		big_mant <= exp_diff_sig ? mant_b : mant_a ; 
		small_mant <= exp_diff_sig ? mant_a : mant_b ;
	end
end

endmodule