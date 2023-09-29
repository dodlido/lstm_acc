module clk_div3(clk_in,reset_n, clk_out);
 
input clk_in;
input reset_n;
output clk_out;
 
logic [1:0] pos_count;
logic [1:0] neg_count;
 
always_ff @(posedge clk_in or negedge reset_n) begin
	if (!reset_n)
		pos_count <= 2'b00;
	else if (pos_count == 2'b10) 
		pos_count <= 2'b00;
	else 
		pos_count<= pos_count + 2'b01;
end
 
always_ff @(negedge clk_in or negedge reset_n) begin
	if (!reset_n)
		neg_count <= 2'b00;
	else if (neg_count == 2'b10) 
		neg_count <= 2'b00;
	else 
		neg_count<= neg_count + 2'b01;
end
 
assign clk_out = ((pos_count == 2'b10) | (neg_count == 2'b10));

endmodule