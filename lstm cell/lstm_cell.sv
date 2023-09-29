module lstm_cell #( parameter ELEMENT_BITS = 8,
	parameter FEATURES = 4,
	parameter FEATURE_BITS = 3,
	parameter M = 4'b1001) 
(
input logic									cell_clk,
input logic									sys_clk,
input logic									reset_n,
input logic 								done_w1,
input logic 								done_w2,
input logic [FEATURES*ELEMENT_BITS-1:0] 	wi_xt , 
input logic [FEATURES*ELEMENT_BITS-1:0] 	wf_xt , 
input logic [FEATURES*ELEMENT_BITS-1:0] 	wg_xt , 
input logic [FEATURES*ELEMENT_BITS-1:0] 	wo_xt ,
input logic									read_output , //active when op_mode is R_OUT

output logic [ELEMENT_BITS-1:0]				h_curr_ser,
output logic [FEATURE_BITS-1:0]				hidden_address, // address to input buffer
output logic								done_wr,
output logic								done_re
);

//stages definition and sequencing
localparam IDLE = 2'b00 ; 
localparam S1   = 2'b01 ; 
localparam S2   = 2'b10 ; 
localparam S3   = 2'b11 ; 

//Change this to choose adder and multiplier OP mode: 0-FP, 1-Decimal
localparam DECI = 1'b0 ; 

logic 	[1:0] 						stage ; 
logic	[FEATURE_BITS-1:0]			output_buff_add_in ; 
logic	[FEATURE_BITS-1:0]			output_buff_add_out ; 
logic	[ELEMENT_BITS-1:0]			h_out_ser ;  
logic 	[FEATURES*ELEMENT_BITS-1:0] cell_state ; 
logic	[FEATURES*ELEMENT_BITS-1:0] h_out ; 
//generating #FEATURES tanhs, sigmoids, adders and multipliers
logic [FEATURES*ELEMENT_BITS-1:0] sig_in ; 
logic [FEATURES*ELEMENT_BITS-1:0] sig_out ; 
logic [FEATURES*ELEMENT_BITS-1:0] tanh_in ; 
logic [FEATURES*ELEMENT_BITS-1:0] tanh_out ; 
logic [FEATURES*ELEMENT_BITS-1:0] mul_in_a ; 
logic [FEATURES*ELEMENT_BITS-1:0] mul_in_b ; 
logic [FEATURES*ELEMENT_BITS-1:0] mul_out ; 
logic [FEATURES*ELEMENT_BITS-1:0] add_in_a ; 
logic [FEATURES*ELEMENT_BITS-1:0] add_in_b ; 
logic [FEATURES*ELEMENT_BITS-1:0] add_out ; 
//internal gate outputs 
logic [FEATURES*ELEMENT_BITS-1:0] input_gate ; 
logic [FEATURES*ELEMENT_BITS-1:0] forget_gate ; 

logic	[1:0]			   					   start_ser ; 
logic	[2:0] 			   					   start_write ; 
logic	[FEATURE_BITS-1:0] 					   address_lim ; 
logic					   					   done_ser ; 
logic	[FEATURES-1:0]	   					   addr_zero ; 

always_ff @(posedge cell_clk or negedge reset_n) begin
if (!reset_n)
stage <= #1 IDLE ; 
else begin 
case (stage)
IDLE:
stage <= #1 !(done_w1&&done_w2) ? IDLE : S1 ;
S3:
stage <= #1 IDLE ; 
default:
stage <= #1 stage + 2'b01 ; 
endcase
end
end

genvar feature_num ; 
generate
for (feature_num = 0 ; feature_num<FEATURES ; feature_num++) begin
//sigmoids
sigmoid #(.ELEMENT_BITS(ELEMENT_BITS))
sigmoid (.data_in(sig_in[(ELEMENT_BITS*(feature_num+1)-1):ELEMENT_BITS*feature_num]),
 .data_out(sig_out[(ELEMENT_BITS*(feature_num+1)-1):ELEMENT_BITS*feature_num])
);
//tanhs
tanh #(.ELEMENT_BITS(ELEMENT_BITS))
tanh 	(.data_in(tanh_in[(ELEMENT_BITS*(feature_num+1)-1):ELEMENT_BITS*feature_num]),
 .data_out(tanh_out[(ELEMENT_BITS*(feature_num+1)-1):ELEMENT_BITS*feature_num])
);
//multipliers
mult_top lstm_mul (	.in_a(mul_in_a[(ELEMENT_BITS*(feature_num+1)-1):ELEMENT_BITS*feature_num]),
			.in_b(mul_in_b[(ELEMENT_BITS*(feature_num+1)-1):ELEMENT_BITS*feature_num]),
			.mode(DECI),
			.res(mul_out[(ELEMENT_BITS*(feature_num+1)-1):ELEMENT_BITS*feature_num])
			) ; 
//adders
addr_top lstm_addr (.in_a(add_in_a[(ELEMENT_BITS*(feature_num+1)-1):ELEMENT_BITS*feature_num]),
			.in_b(add_in_b[(ELEMENT_BITS*(feature_num+1)-1):ELEMENT_BITS*feature_num]),
			.mode(DECI),
			.res(add_out[(ELEMENT_BITS*(feature_num+1)-1):ELEMENT_BITS*feature_num])
			) ; 
end
endgenerate

//input gate register
always_ff @(posedge cell_clk or negedge reset_n) begin
if (!reset_n)
input_gate <= #1 {FEATURES*ELEMENT_BITS{1'b0}} ; 
else begin 
if (stage == S1) 	
input_gate <= #1 mul_out ; 
else 							
input_gate <= #1 input_gate ; 
end
end
//forget gate register
always_ff @(posedge cell_clk or negedge reset_n) begin
if (!reset_n)
forget_gate <= #1 {FEATURES*ELEMENT_BITS{1'b0}} ; 
else begin 
if (stage == S2) 	
forget_gate <= #1 add_out ; 
else 							
forget_gate <= #1 forget_gate ; 
end
end

//ht register
always_ff @(posedge cell_clk or negedge reset_n) begin
if (!reset_n)
h_out <= #1 {FEATURES*ELEMENT_BITS{1'b0}} ; 
else begin 
if (stage == S3) 	
h_out <= #1 mul_out ; 
else 							
h_out <= #1 h_out ; 
end
end

//cell_state register
always_ff @(posedge cell_clk or negedge reset_n) begin
if (!reset_n)
cell_state <= #1 {FEATURES*ELEMENT_BITS{1'b0}} ; 
else begin 
if (stage == S3) 	
cell_state <= #1 forget_gate ; 
else 							
cell_state <= #1 cell_state ; 
end
end

assign	address_lim = (M>>1)-{{FEATURE_BITS-2{1'b0}},2'b10} ; 

//catch negedge of stage[1] (which is transition from S3 to IDLE)
always_ff @(posedge sys_clk or negedge reset_n) begin
if (!reset_n)
start_ser[0] <= #1 1'b0 ; 
else begin
start_ser[0] <= stage[1] ; 
end
end
assign start_ser[1] = (start_ser[0])&&(!stage[1]) ; 

//start_write
always_ff @(posedge sys_clk or negedge reset_n) begin
if (!reset_n)
start_write[0] <= #1 1'b0 ; 
else begin 
start_write[0] <= #1 start_ser[1] ;
end
end
always_ff @(posedge sys_clk or negedge reset_n) begin
if (!reset_n)
start_write[1] <= #1 1'b0 ; 
else begin 
start_write[1] <= #1 start_write[0] ;
end
end
assign start_write[2] = ((start_write[1])||(output_buff_add_in!={FEATURE_BITS{1'b0}})) ; 

//output_buff_add_in
always_ff @(posedge sys_clk or negedge reset_n) begin
if (!reset_n)
output_buff_add_in <= #1 {FEATURE_BITS{1'b0}} ; 
else begin 
if (done_wr)
output_buff_add_in <= #1 {FEATURE_BITS{1'b0}} ; 
else if (start_write[2])
output_buff_add_in <= #1 output_buff_add_in + 1'b1;
else
output_buff_add_in <= #1 {FEATURE_BITS{1'b0}} ; 
end
end

//output_buff_add_out
always_ff @(posedge sys_clk or negedge reset_n) begin
if (!reset_n)
output_buff_add_out <= #1 {FEATURE_BITS{1'b0}} ; 
else begin 
if(done_re)
output_buff_add_out <= #1 {FEATURE_BITS{1'b0}} ; 
else if (read_output)
output_buff_add_out <= #1 output_buff_add_out + 1'b1 ; 
else
output_buff_add_out <= #1 {FEATURE_BITS{1'b0}} ; 
end
end

//hidden layer address (to input buffer)
always_ff @(posedge sys_clk or negedge reset_n) begin
if (!reset_n)
hidden_address <= #1 {FEATURE_BITS{1'b0}} ; 
else begin 
hidden_address <= #1 output_buff_add_out + FEATURES[FEATURE_BITS-1:0] ; 
end
end

//done_write
always_ff @(posedge sys_clk or negedge reset_n) begin
if (!reset_n)
done_wr <= #1 1'b0 ; 
else begin 
if (output_buff_add_in==address_lim)
done_wr <= #1 1'b1 ; 
else
done_wr <= #1 1'b0 ; 
end
end

//done_read
always_ff @(posedge sys_clk or negedge reset_n) begin
if (!reset_n)
done_re <= #1 1'b0 ; 
else begin 
if (output_buff_add_out==address_lim+1'b1)
done_re <= #1 1'b1 ; 
else
done_re <= #1 1'b0 ; 
end
end

serializer #(
.ELEMENT_BITS(ELEMENT_BITS),
.FEATURES(FEATURES),
.FEATURE_BITS(FEATURE_BITS),
.M(M)
)
ser_cell (
.clk(sys_clk),
.start(start_ser[1]),
.reset_n(reset_n),
.serial_data_out(h_out_ser),
.parallel_data_in(h_out),
.done(done_ser)
);

dpr #(
.FEATURE_BITS(FEATURE_BITS),
.ELEMENT_BITS(ELEMENT_BITS),
.RAM_DEPTH(M)
) 
output_buff (
.sys_clk(sys_clk),
.reset_n(reset_n),
.address_in(output_buff_add_in),
.data_in(h_out_ser),
.cs_in(start_write[2]), 
.we_in(start_write[2]),
.address_out(output_buff_add_out),
.oe_out((read_output)&&(!done_re)),
.cs_out((read_output)&&(!done_re)),
.data_out(h_curr_ser)
);


//modules interafaces as a func of stage
always_comb begin
if ( stage == S1 ) begin
sig_in = wi_xt;
tanh_in = wg_xt;
mul_in_a = sig_out;
mul_in_b = tanh_out;
add_in_a = {FEATURES*ELEMENT_BITS{1'b0}};
add_in_b = {FEATURES*ELEMENT_BITS{1'b0}};
end
else if ( stage == S2 ) begin
sig_in = wf_xt;
tanh_in = {FEATURES*ELEMENT_BITS{1'b0}};
mul_in_a = sig_out;
mul_in_b = cell_state;
add_in_a = input_gate;
add_in_b = mul_out;
end
else if ( stage == S3 ) begin 
sig_in = wo_xt;
tanh_in = forget_gate;
mul_in_a = tanh_out;
mul_in_b = sig_out;
add_in_a = {FEATURES*ELEMENT_BITS{1'b0}};
add_in_b = {FEATURES*ELEMENT_BITS{1'b0}};
end 
else begin
sig_in = {FEATURES*ELEMENT_BITS{1'b0}};
tanh_in = {FEATURES*ELEMENT_BITS{1'b0}};
mul_in_a = {FEATURES*ELEMENT_BITS{1'b0}};
mul_in_b = {FEATURES*ELEMENT_BITS{1'b0}};
add_in_a = {FEATURES*ELEMENT_BITS{1'b0}};
add_in_b = {FEATURES*ELEMENT_BITS{1'b0}};
end
end

endmodule