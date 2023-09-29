
module clk_gen (
	input  logic	fpga_clk,	// clk from FPGA oscillator
	input  logic	reset_n,
	output logic	sys_clk,	// system clock, same as fpga_clk
	output logic 	pe_clk, 	// proccessing element clock, slow enough to fit a single * op
	output logic	cell_clk	// lstm cell clock, slowest, slower by 2 in comparison to pe_clk
);

logic div_2 ; 
logic div_4 ; 
logic div_3 ;

assign sys_clk = fpga_clk ; 

//Divide system clock frequency by 2
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n)
		div_2 <= #1 1'b0 ; 
	else
		div_2 <= #1 ~div_2 ; 
end

//Divide system clock frequency by 4
always_ff @(posedge div_2 or negedge reset_n) begin
	if(!reset_n)
		div_4 <= #1 1'b0 ; 
	else
		div_4 <= #1 ~div_4 ; 
end

//Create pe_clk, f(pe_clk)=f(sys_clk)/8
always_ff @(posedge div_4 or negedge reset_n) begin
	if(!reset_n)
		pe_clk <= #1 1'b0 ; 
	else
		pe_clk <= #1 ~pe_clk ; 
end

//Divide system clock frequency by 3
clk_div3 div3 (
	.reset_n(reset_n),
	.clk_in(sys_clk),
	.clk_out(div_3)
);

//Create cell_clk, f(cell_clk)=f(sys_clk)/9
clk_div3 cell_clk_gen (
	.reset_n(reset_n),
	.clk_in(div_3),
	.clk_out(cell_clk)
);

endmodule