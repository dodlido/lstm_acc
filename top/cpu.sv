
module cpu #(MAIN_MEM_ADD_LEN = 11, FEATURES = 4, WEIGHTS = 64) (
	input  logic						fpga_clk,
	input  logic 						reset_n,
	input  logic [2:0]					op_mode,
	output logic 						direct, // direction of data transition: 0=main_mem to lstm, 1=lstm to main_mem
	output logic [MAIN_MEM_ADD_LEN-1:0]	main_mem_count,
	output logic [MAIN_MEM_ADD_LEN-1:0]	main_mem_first_address,
	output logic						start
);

//mode definition
localparam IDLE     = 3'b000 ; 
localparam INIT_W1  = 3'b001 ; 
localparam INIT_W2  = 3'b010 ; 
localparam W_IN     = 3'b011 ;
localparam CALC     = 3'b100 ;
localparam R_OUT    = 3'b101 ;

localparam CYCLES = 10 ; 
localparam WORD_SIZE = {{MAIN_MEM_ADD_LEN-4{1'b0}},4'b1000} ; 
localparam INPUT_SIZE = FEATURES*CYCLES ; 
localparam ZERO	= {MAIN_MEM_ADD_LEN{1'b0}} ; 
localparam IN_FIRST = ZERO ;
localparam W1_FIRST  = IN_FIRST + INPUT_SIZE ; 
localparam W2_FIRST  = W1_FIRST + WEIGHTS ; 
localparam OUT_FIRST = W2_FIRST + WEIGHTS ; 

logic [2:0] op_mode_delayed ;
logic [1:0] edge_det ; 
logic [3:0] cycle_count ; 

//detect mode change
always_ff @(posedge fpga_clk or negedge reset_n) begin
	if (!reset_n)
		op_mode_delayed <= #1 3'b000 ; 
	else 
		op_mode_delayed <= #1 op_mode ; 
end
assign edge_det[0] = ((op_mode[0])&&(!op_mode_delayed[0]));
assign edge_det[1] = ((op_mode[1])&&(!op_mode_delayed[1]));
assign start = ((edge_det[0])||(edge_det[1])) ; 

//cycle_count	
always_ff @(negedge op_mode[2] or negedge reset_n) begin
	if (!reset_n)
		cycle_count <= #1 3'b000 ; 
	else 
		cycle_count <= #1 cycle_count + 3'b001 ; 
end

//output assigment
always_comb begin
	case(op_mode)
		INIT_W1: begin
			direct = 1'b0 ; 
			main_mem_count = WEIGHTS;
			main_mem_first_address = W1_FIRST;
		end
		INIT_W2: begin
			direct = 1'b0 ; 
			main_mem_count = WEIGHTS;
			main_mem_first_address = W2_FIRST;
		end
		W_IN: begin
			direct = 1'b0 ; 
			main_mem_count = FEATURES ; 
			main_mem_first_address = IN_FIRST + cycle_count*FEATURES ; 
		end
		R_OUT: begin
			direct = 1'b1 ;
			main_mem_count = FEATURES ; 
			main_mem_first_address = OUT_FIRST + cycle_count*FEATURES ; 
		end
		default: begin
			direct = 1'b0 ; 
			main_mem_count = ZERO ; 
			main_mem_first_address = ZERO ; 
		end
	endcase
end

endmodule