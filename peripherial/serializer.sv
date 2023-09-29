module serializer #(ELEMENT_BITS = 8, FEATURES = 4, FEATURE_BITS = 3, M=4'b1001) (
	input logic								clk,
	input logic								start,
	input logic								reset_n,
	input  logic	[FEATURES*ELEMENT_BITS-1:0] parallel_data_in,
	output logic	[ELEMENT_BITS-1:0]			serial_data_out,
	output logic								done
);

localparam ONE  = {{FEATURE_BITS-1{1'b0}},1'b1};
localparam ZERO = {FEATURE_BITS{1'b0}};

logic [FEATURE_BITS-1:0] count ; 
logic write_mode ; 
logic [FEATURE_BITS-1:0]	count_lim ; 
logic [2*FEATURE_BITS-1:0]	index_first ;

assign index_first = ((count)<<FEATURE_BITS) ; 
assign count_lim = (M>>1) - ONE ;  

//count
always_ff @(posedge clk or negedge reset_n) begin
	if (!reset_n)
		count <= #1 ZERO ; 
	else begin 
		if ( count == count_lim )
			count <= #1 ZERO ; 
		else if (write_mode)
			count <= #1 count + ONE ; 
		else
			count <= #1 ZERO ; 
	end
end

//write mode
always_ff @(posedge clk or negedge reset_n) begin
	if (!reset_n)
		write_mode <= #1 1'b0 ; 
	else begin
		if(!write_mode&&start)
			write_mode <= #1 1'b1 ; 
		else if ( (count == count_lim) && (write_mode) )
			write_mode <= #1 1'b0 ; 
		else
			write_mode <= #1 write_mode ; 
	end
end

//done reg
always_ff @(posedge clk or negedge reset_n) begin
	if (!reset_n)
		done <= #1 1'b0 ; 
	else begin 
		if ( (count == count_lim) && (write_mode) )
			done <= #1 1'b1 ; 
		else 
			done <= #1 done ; 
	end
end

//serial_data_out
always_ff @(posedge clk or negedge reset_n) begin
	if (!reset_n)
		serial_data_out <= #1 {ELEMENT_BITS{1'b0}} ;  
	else begin
		if(write_mode)
			serial_data_out <= #1 parallel_data_in[index_first +: ELEMENT_BITS] ; 
		else 
			serial_data_out <= #1 serial_data_out ; 
	end
end

endmodule

