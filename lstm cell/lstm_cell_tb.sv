
// Address Generator for sys_out DPR TB
// This module is a test bench for ag_o 
module lstm_cell_tb;

	localparam FEATURES = 4;
	localparam ELEMENT_BITS = 8;

	logic										cell_clk;
	logic										sys_clk ; 
	logic										reset_n;
	logic 										done_w1;
	logic 										done_w2;
	logic  [FEATURES*ELEMENT_BITS-1:0]			wi_xt;
	logic  [FEATURES*ELEMENT_BITS-1:0]			wg_xt;
	logic  [FEATURES*ELEMENT_BITS-1:0]			wf_xt;
	logic  [FEATURES*ELEMENT_BITS-1:0]			wo_xt;
	logic										read_output ; 
	
	logic [ELEMENT_BITS-1:0]					h_curr_ser;
	logic										done_wr ; 
	

	lstm_cell uut(
		.cell_clk(cell_clk),
		.sys_clk(sys_clk),
		.reset_n(reset_n),
		.done_w1(done_w1),
		.done_w2(done_w2),
		.wi_xt(wi_xt),
		.wg_xt(wg_xt),
		.wf_xt(wf_xt),
		.wo_xt(wo_xt),
		.read_output(read_output),
		.h_curr_ser(h_curr_ser),
		.done_wr(done_wr)
	);
	
	initial begin
		cell_clk = 1'b1;
		sys_clk = 1'b1;
		reset_n = 1'b0 ;
		done_w1 = 1'b0 ; 
		done_w2 = 1'b0 ; 
		read_output = 1'b0 ; 
		wi_xt = 32'h0f18a7b7 ; 
		wg_xt = 32'h1c5e83eb ; 
		wf_xt = 32'h404c102b ;
		wo_xt = 32'h9aaeefc1 ;
		#90
		reset_n = 1'b1 ; 
		done_w1 = 1'b1 ;  
		#60
		done_w2 = 1'b1 ; 
		#50
		done_w1 = 1'b0 ; 
		#400
		read_output = 1'b1 ; 
		#40
		read_output = 1'b0 ; 
	end	
	
	
	always begin
		#30
		cell_clk= ~cell_clk;
	end

	always begin
		#5
		sys_clk= ~sys_clk;
	end

endmodule
