// a single proccessing element - PE
module synth_part (
	input	logic [3:0]	exp_diff,
	input	logic [7:0]	in_a,
	input	logic [7:0]	in_b,
			
	output	logic 		zero,
	output	logic 		sign_res,
	output	logic [3:0]	mant_res,
			
	output	logic [2:0]	exp_diff_norm,
	output	logic [1:0]	exp_diff_sign
);

logic			sign_a ; 
logic			sign_b ; 
logic			temp_sign ; 
logic	[3:0]	mant_a ; 
logic	[3:0]	mant_b ; 
logic	[5:0]	temp_mant_res ; 
logic			exp_diff_sig ; 
logic	[4:0]	mant_diff ; 
logic			mant_diff_sig ; 
logic	[3:0]	small_mant ; 
logic	[2:0]	shift_amount ; 
logic	[5:0]	shifted_mant ;
logic	[3:0]	big_mant ; 
logic			temp_sign_b ;
logic	[5:0]	twos_small_mant ;

assign sign_a = in_a[7] ; 
assign sign_b = in_b[7] ; 
assign mant_a = in_a[3:0] ; 
assign mant_b = in_b[3:0] ; 
assign exp_diff_sig = exp_diff[3] ; 
assign mant_diff = mant_a - mant_b ; 
assign mant_diff_sig = mant_diff[4] ; 

big_small mants (	.mant_a(mant_a),
					.mant_b(mant_b),
					.exp_diff(exp_diff),
					.exp_diff_sig(exp_diff_sig),
					.mant_diff_sig(mant_diff_sig),
					.big_mant(big_mant),
					.small_mant(small_mant)
				);

assign shift_amount = (exp_diff_sig) ? -(exp_diff[2:0]):exp_diff[2:0];
assign temp_sign = sign_b ; 
assign temp_sign_b = temp_sign ; 

right_shifter shift_mantissa (	.small_mant(small_mant),
								.shift_amount(shift_amount),
								.shifted_mant(shifted_mant)
							); 

twos_comp two_small_mant (	.sign_a(sign_a),
							.sign_b(sign_b),
							.shifted_mant(shifted_mant),
							.twos_small_mant(twos_small_mant)
						); 

assign temp_mant_res = {1'b1,big_mant} + twos_small_mant ; 

zero_detect zero_find (	.sign_a(sign_a),
						.sign_b(sign_b),
						.exp_diff(exp_diff),
						.mant_diff(mant_diff),
						.zero(zero)
					) ; 

normalize normal (	.in_mant(temp_mant_res),
					.out_mant(mant_res),
					.exp_diff_norm(exp_diff_norm),
					.exp_diff_sign(exp_diff_sign)
				) ;

final_sign sign_find (	.exp_diff_sig(exp_diff_sig),
						.mant_diff_sig(mant_diff_sig),
						.exp_diff(exp_diff),
						.sign_a(sign_a),
						.sign_b(temp_sign_b),
						.sign_res(sign_res)
					) ; 

endmodule