// a single proccessing element - PE
module exp_part (
	input	logic	[2:0]	exp_a,
	input	logic	[2:0]	exp_b,
	input	logic	[2:0]	exp_diff_norm,
	input	logic	[1:0]	exp_diff_sign,
	
	output	logic	[3:0]	exp_diff,
	output	logic	[2:0]	exp_res
);

logic exp_diff_sig ; 
logic [2:0] temp_exp_res ; 

reg [2:0]	exp_res;

assign exp_diff = exp_a - exp_b ;
assign exp_diff_sig = exp_diff[3] ; 
assign temp_exp_res = exp_diff_sig ? exp_b : exp_a ; 

always@(exp_diff_norm or exp_diff_sign or temp_exp_res) begin
	if(exp_diff_sign[1])
		exp_res <= temp_exp_res - exp_diff_norm ; 
	else
		exp_res <= temp_exp_res + exp_diff_norm ; 
end

endmodule