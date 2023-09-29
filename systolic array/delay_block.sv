

module delay_block #(parameter FEATURE_BITS = 4, parameter P_INDEX = 1) ( 		
		input logic 						sys_clk, 
		input logic 						reset_n, 
		input logic	[(2*FEATURE_BITS)-1:0]	address_in,
		input logic							enable_in,
		input logic							cs_in,
		output logic						enable_out,
		output logic						cs_out,
		output logic [(2*FEATURE_BITS)-1:0]	address_out
);

logic [P_INDEX-1:0] cs_mem ; 
logic [P_INDEX-1:0] enable_mem ; 
logic [P_INDEX-1:0][(2*FEATURE_BITS)-1:0] address_mem ; 
logic [FEATURE_BITS-2:0] p_counter ; 

//modulu p counter
always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		p_counter <= #1 {FEATURE_BITS-1{1'b0}} ; 
	end
	else if (p_counter == P_INDEX - 1 ) begin
		p_counter <= #1 {FEATURE_BITS-1{1'b0}} ; 
	end
	else begin
		p_counter <= #1 p_counter + {{FEATURE_BITS-2{1'b0}},1'b1} ; 
	end
end

//cs_mem 
always_ff @(posedge sys_clk or negedge reset_n) begin
	cs_mem <= #1 cs_mem ; 
	if(!reset_n) begin
		cs_mem <= #1 {P_INDEX{1'b0}} ; 
	end
	else begin
		cs_mem[p_counter] <= #1 cs_in ; 
	end
end

//cs_out 
always_ff @(negedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		cs_out <= #1 1'b0 ; 
	end
	else begin
		cs_out <= #1 cs_mem[p_counter] ;
	end
end

//enable_mem 
always_ff @(posedge sys_clk or negedge reset_n) begin
	enable_mem <= #1 enable_mem ; 
	if(!reset_n) begin
		enable_mem <= #1 {P_INDEX{1'b0}} ; 
	end
	else begin
		enable_mem[p_counter] <= #1 enable_in ; 
	end
end

//enable_out 
always_ff @(negedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		enable_out <= #1 1'b0 ; 
	end
	else begin
		enable_out <= #1 enable_mem[p_counter] ;
	end
end

//address_mem 
always_ff @(posedge sys_clk or negedge reset_n) begin
	address_mem <= #1 address_mem ; 
	if(!reset_n) begin
		address_mem <= #1 {(2*FEATURE_BITS*P_INDEX){1'b0}} ; 
	end
	else begin
		address_mem[p_counter][(2*FEATURE_BITS)-1:0] <= #1 address_in ; 
	end
end

//address_out 
always_ff @(negedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		address_out <= #1 {(2*FEATURE_BITS*P_INDEX){1'b0}} ; 
	end
	else begin
		address_out <= #1 address_mem[p_counter][(2*FEATURE_BITS)-1:0] ;
	end
end

endmodule