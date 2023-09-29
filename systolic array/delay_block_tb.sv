
module delay_block_tb;

	localparam FEATURE_BITS = 4 ;
	localparam P_INDEX = 3;
	
	logic 							sys_clk; 
	logic 							reset_n; 
	//logic [FEATURE_BITS-2:0]		p_index;
	logic [(2*FEATURE_BITS)-1:0]	address_in;
	logic							enable_in;
	logic							cs_in;
	logic							enable_out;
	logic							cs_out;
	logic [(2*FEATURE_BITS)-1:0]	address_out;
	

	delay_block #(.FEATURE_BITS(FEATURE_BITS), .P_INDEX(P_INDEX)) uut (
		.sys_clk(sys_clk),
		.reset_n(reset_n),		
		//.p_index(p_index),
		.address_in(address_in),
		.enable_in(enable_in),
		.cs_in(cs_in),
		.enable_out(enable_out),
		.cs_out(cs_out),
		.address_out(address_out)
	);
	
	initial begin
		sys_clk = 1'b1;
		reset_n = 1'b0;
		address_in = {(2 * FEATURE_BITS){1'b0}} ; 
		cs_in = 1'b0 ; 
		//p_index = 2'b11 ; 
		enable_in = 1'b0 ; 
		cs_in = 1'b0 ; 
		#10
		reset_n = 1'b1 ; 
		#10
		address_in = {{(2 * FEATURE_BITS - 4){1'b0}},4'b0000} ; 
		#10
		address_in = {{(2 * FEATURE_BITS - 4){1'b0}},4'b0001} ; 
		#10
		address_in = {{(2 * FEATURE_BITS - 4){1'b0}},4'b0010} ; 
		#10
		address_in = {{(2 * FEATURE_BITS - 4){1'b0}},4'b0011} ; 
		#10
		address_in = {{(2 * FEATURE_BITS - 4){1'b0}},4'b0100} ; 
		#10
		address_in = {{(2 * FEATURE_BITS - 4){1'b0}},4'b0101} ; 
		#10
		address_in = {{(2 * FEATURE_BITS - 4){1'b0}},4'b0110} ; 
		#10
		address_in = {{(2 * FEATURE_BITS - 4){1'b0}},4'b0111} ; 
		#10
		address_in = {{(2 * FEATURE_BITS - 4){1'b0}},4'b1000} ; 
		#10
		address_in = {{(2 * FEATURE_BITS - 4){1'b0}},4'b1001} ; 
	end	
	
	always begin
		#5
		sys_clk= ~sys_clk;
	end


endmodule
