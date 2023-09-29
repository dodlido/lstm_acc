
module addr_top (
	input	logic	[7:0]	in_a ,
	input	logic	[7:0]	in_b ,
	input	logic			mode , 
	output 	logic	[7:0]	res  
);

localparam ZERO = 8'b00000000 ; 

logic [2:0] exp_a ; 
logic [2:0] exp_b ; 
logic [2:0] exp_res ; 
logic		sign_res ; 
logic [3:0]	mant_res ; 

logic [2:0]	exp_diff_norm ; 
logic [1:0]	exp_diff_sign ; 
logic [3:0]	exp_diff ; 
logic [7:0] res_n_zero ; 
logic		is_zero ; 
logic			zero ; 

assign exp_a = in_a[6:4] ; 
assign exp_b = in_b[6:4] ; 
assign res_n_zero = (mode) ? (in_a + in_b) : {sign_res,exp_res,mant_res} ; 
assign is_zero = ((zero)||((in_a==ZERO)&&(in_b==ZERO))) ; 
assign res = (is_zero) ? ZERO : res_n_zero ; 

synth_part 	get_mant (	.in_a(in_a),
						.in_b(in_b),
						.zero(zero),
						.exp_diff_norm(exp_diff_norm),
						.exp_diff_sign(exp_diff_sign),
						.exp_diff(exp_diff),
						.sign_res(sign_res),
						.mant_res(mant_res) 
						); 

exp_part 	get_exp	 (	.exp_a(exp_a),
						.exp_b(exp_b),
						.exp_diff_norm(exp_diff_norm),
						.exp_diff_sign(exp_diff_sign),
						.exp_diff(exp_diff),
						.exp_res(exp_res)
						); 

endmodule