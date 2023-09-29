// a single proccessing element - PE
module final_sign (
	input	logic			exp_diff_sig,
	input	logic			mant_diff_sig,
	input	logic	[3:0]	exp_diff,
	input	logic			sign_a,
	input	logic			sign_b,
	output	logic			sign_res
);

always@(exp_diff_sig or mant_diff_sig or exp_diff or sign_a or sign_b ) begin
	if(exp_diff_sig)
		sign_res <= sign_b ; 
	else begin
		if (exp_diff==4'b0000) begin
			if(mant_diff_sig)
				sign_res <= sign_b ; 
			else
				sign_res <= sign_a ; 
		end
		else
			sign_res <= sign_a ; 
	end
end

endmodule