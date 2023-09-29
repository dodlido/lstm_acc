/*
	This module is the top of all tops
*/
module top_deg_tb;

//localparameters
//localparam ELEMENT_BITSELEMENT_BITS   = 8    ; 

//mode definition
localparam IDLE     = 3'b000 ; 
localparam INIT_W1  = 3'b001 ; 
localparam INIT_W2  = 3'b010 ; 
localparam W_IN     = 3'b011 ;
localparam CALC     = 3'b100 ;
localparam R_OUT    = 3'b101 ;

logic							fpga_clk;				// clk from FPGA oscillator
logic							reset_n;				// system reset, active low
logic 							start; 					// wake system up, active high, pulse
logic	[2:0]					op_mode;				// system mode
//logic	[ELEMENT_BITS-1:0]		data_in;				// data to write\read
logic	[8-1:0]		data_in;				// data to write\read
//logic	[ELEMENT_BITS-1:0]		data_out;				// data to write\read
logic	[8-1:0]		data_out;				// data to write\read

top uut (
	.fpga_clk(fpga_clk),
	.reset_n(reset_n),
	.start(start),
	.op_mode(op_mode),
	.data_in(data_in),
	.data_out(data_out)
);

initial begin
	fpga_clk = 1'b1 ; 
	reset_n = 1'b0 ;
	start = 1'b0 ; 
	#10
	reset_n = 1'b1 ;
	#100
	start = 1'b1 ; 
end

always_ff @(posedge fpga_clk or negedge reset_n) begin
	if(!reset_n)
		//data_in <= #1 {ELEMENT_BITS{1'b0}} ; 
		data_in <= #1 {8{1'b0}};
	else begin
		case(op_mode)
			INIT_W1:
				data_in <= #1 8'h01 ; 
			INIT_W2:
				data_in <= #1 8'h02 ; 
			W_IN:
				data_in <= #1 8'h03 ; 
			default:
//				data_in <= #1 {ELEMENT_BITS{1'b0}} ; 
				data_in <= #1 {8{1'b0}};
		endcase
	end
end

always begin
	#5
	fpga_clk= ~fpga_clk;
end

endmodule