
module mult_top (
	input	logic	[7:0]	in_a ,
	input	logic	[7:0]	in_b ,
	output 	logic	[7:0]	res  
);

localparam ZERO = 8'b00000000 ; 
localparam BIAS = 3'b011 ; 

logic		sign_a	; 
logic [2:0] exp_a	; 
logic [3:0] mant_a 	; 

logic		sign_b 	; 
logic [2:0] exp_b 	; 
logic [3:0] mant_b 	; 

logic		sign_res; 
logic [2:0] exp_res ; 
logic [3:0]	mant_res; 
logic [7:0] temp_res;

logic [3:0] exp_sum	 ;
logic [9:0] mant_prod;
logic [9:0] shifted_prod ; 
logic [3:0] adjusted_exp ; 
logic [2:0] denormalization ; 
logic [2:0] cap;

assign sign_a = in_a[7] ; 
assign exp_a = in_a[6:4] ;
assign mant_a = in_a[3:0] ;  

assign sign_b = in_b[7] ; 
assign exp_b = in_b[6:4] ;
assign mant_b = in_b[3:0] ;  

assign denormalization = ((exp_a==3'b000)||(exp_b==3'b000)) ? 3'b001 : 3'b000 ; 
assign exp_sum = {1'b0,exp_a} + {1'b0,exp_b} ; 
assign cap = (exp_sum>3'b111) ? 3'b111 : 3'b000 ; 

always_comb begin
	// both denormalized
	if ( (exp_a==3'b000) && (exp_b==3'b000) )
		mant_prod = {1'b0,mant_a}*{1'b0,mant_b} ; 
	// only a is denormalized
	else if (exp_a==3'b000)
		mant_prod = {1'b0,mant_a}*{1'b1,mant_b} ; 
	// only b is denormalized
	else if (exp_b==3'b000) 
		mant_prod = {1'b1,mant_a}*{1'b0,mant_b} ; 
	// neither denormalized
	else
		mant_prod = {1'b1,mant_a}*{1'b1,mant_b} ; 
end


//this block finds the shifting needed for mant_prod
always_comb begin
	//both A and B are denormalized
	if ( (exp_a==3'b000) && (exp_b==3'b000) ) begin
		shifted_prod = (mant_prod>>2) ; 
		adjusted_exp = exp_sum ; 
	end
	// neither is denormalized
	else begin
		if (mant_prod[9]) begin
			shifted_prod = (mant_prod>>1) ; 
			adjusted_exp = exp_sum + 3'b001 - BIAS + denormalization; 
		end
		else begin
			if (mant_prod[8]) begin 
				shifted_prod = mant_prod ; 
				adjusted_exp = exp_sum - BIAS ; 
			end
			else begin
				if (mant_prod[7]) begin
					shifted_prod = (mant_prod<<1) ; 
					adjusted_exp = exp_sum - 3'b001 - BIAS + denormalization; 
				end
				else begin
					if (mant_prod[6]) begin
						shifted_prod = (mant_prod<<2) ; 
						adjusted_exp = exp_sum - 3'b010 - BIAS+ denormalization; 
					end
					else begin
						if (mant_prod[5]) begin
							shifted_prod = (mant_prod<<3) ; 
							adjusted_exp = exp_sum - 3'b011 - BIAS+ denormalization; 
						end
						else begin
							if (mant_prod[4]) begin
								shifted_prod = (mant_prod<<4) ; 
								adjusted_exp = exp_sum - 3'b100 - BIAS+ denormalization; 
							end
							else begin
								if (mant_prod[3]) begin
									shifted_prod = (mant_prod<<5) ; 
									adjusted_exp = exp_sum - 3'b101 - BIAS+ denormalization; 
								end
								else begin
									if (mant_prod[2]) begin
										shifted_prod = (mant_prod<<6) ; 
										adjusted_exp = exp_sum - 3'b110 - BIAS+ denormalization;
									end
									else begin
										shifted_prod = (mant_prod<<7) ; 
										adjusted_exp = exp_sum - 3'b111 - BIAS+ denormalization;
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

assign sign_res = sign_a^sign_b ; 
assign exp_res = (adjusted_exp > 3'b111) ? cap : adjusted_exp ; 
assign mant_res = ((adjusted_exp > 3'b111)&&(exp_sum>3'b111)) ? 4'b0000 : shifted_prod[7:4] ; 

assign temp_res = {sign_res, exp_res, mant_res} ; 

assign res = ((in_a==ZERO)||(in_b==ZERO)) ? ZERO : temp_res ; 

endmodule