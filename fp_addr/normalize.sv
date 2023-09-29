// a single proccessing element - PE
module normalize (
	input	logic	[5:0]	in_mant,
	
	output	logic	[3:0]	out_mant,
	output	logic	[1:0]	exp_diff_sign,
	output	logic	[2:0]	exp_diff_norm
);

always@(in_mant) begin
	if(in_mant[5]) begin
		out_mant <= in_mant[4:1] ; 
		exp_diff_norm <= 3'b001 ; 
		exp_diff_sign <= 2'b01 ;
	end
	else if (in_mant[4]) begin
		out_mant <= in_mant[3:0] ; 
		exp_diff_norm <= 3'b000 ; 
		exp_diff_sign <= 2'b01 ;
	end
	else if (in_mant[3]) begin
		out_mant <= {in_mant[2:0],1'b0} ; 
		exp_diff_norm <= 3'b001 ; 
		exp_diff_sign <= 2'b10 ;
	end
	else if (in_mant[2]) begin
		out_mant <= {in_mant[1:0],2'b00} ; 
		exp_diff_norm <= 3'b010 ; 
		exp_diff_sign <= 2'b10 ;
	end
	else if (in_mant[1]) begin
		out_mant <= {in_mant[0],3'b000} ; 
		exp_diff_norm <= 3'b011 ; 
		exp_diff_sign <= 2'b10 ;
	end
	else if (in_mant[0]) begin
		out_mant <= 4'b0000 ; 
		exp_diff_norm <= 3'b100 ; 
		exp_diff_sign <= 2'b10 ;
	end
	else begin
		out_mant <= in_mant ; 
		exp_diff_norm <= 3'b001 ; 
		exp_diff_sign <= 2'b01 ;
	end
end

endmodule