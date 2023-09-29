module deserializer #(ELEMENT_BITS = 8, FEATURES = 4, FEATURE_BITS = 4, M = 4'b1001) (
	input  logic							 clk,
	input  logic							 reset_n,
	input  logic							 start,
	input  logic [ELEMENT_BITS-1:0]          serial_data_in,
	output logic [ELEMENT_BITS*FEATURES-1:0] parallel_data_out_1,
	output logic [ELEMENT_BITS*FEATURES-1:0] parallel_data_out_2,
	output logic		                     done
);

localparam RDY = 2'b00;
localparam W1  = 2'b01;
localparam W2  = 2'b10;
localparam ONE  = {{FEATURE_BITS-1{1'b0}},1'b1};
localparam ZERO = {FEATURE_BITS{1'b0}};

logic [FEATURE_BITS-1:0]	count ; 
logic [1:0]				 	write_mode ; 
logic [2*FEATURE_BITS-1:0]	index_first ; 
logic [FEATURE_BITS-1:0]	count_lim ; 

assign count_lim = (M>>1) - ONE ;  
assign index_first = ((count)<<(FEATURE_BITS-1)) ; 

//count
always_ff @(posedge clk or negedge reset_n) begin
	if (!reset_n)
		count <= #1 ZERO ; 
	else begin 
		if ( count == count_lim )
			count <= #1 ZERO ; 
		else if (write_mode!=RDY)
			count <= #1 count + ONE ; 
		else
			count <= #1 ZERO ; 
	end
end

//write mode
always_ff @(posedge clk or negedge reset_n) begin
	if (!reset_n)
		write_mode <= #1 RDY ; 
	else begin
		if(write_mode==RDY&&start)
			write_mode <= #1 W1 ; 
		else if ( ( count == count_lim ) && ( write_mode == W2 ) )
			write_mode <= #1 RDY ; 
		else if ( count == count_lim )
			write_mode <= #1 write_mode + 2'b01 ; 
		else
			write_mode <= #1 write_mode ; 
	end
end

//done reg
always_ff @(posedge clk or negedge reset_n) begin
	if (!reset_n)
		done <= #1 1'b0 ; 
	else begin 
		if ( (write_mode==W2)&& ( count == count_lim ) )
			done <= #1 1'b1 ; 
		else 
			done <= #1 done ; 
	end
end


//parallel_data_out_1
always_ff @(posedge clk or negedge reset_n) begin
	if (!reset_n)
		parallel_data_out_1 <= #1 {FEATURES*ELEMENT_BITS{1'b0}} ;  
	else begin
		if(write_mode==W1)
			parallel_data_out_1[index_first +: ELEMENT_BITS] <= #1 serial_data_in ; 
		else 
			parallel_data_out_1 <= #1 parallel_data_out_1 ; 
	end
end

//parallel_data_out_2
always_ff @(posedge clk or negedge reset_n) begin
	if (!reset_n)
		parallel_data_out_2 <= #1 {FEATURES*ELEMENT_BITS{1'b0}} ;  
	else begin
		if(write_mode==W2)
			parallel_data_out_2[index_first +: ELEMENT_BITS] <= #1 serial_data_in ; 
		else 
			parallel_data_out_2 <= #1 parallel_data_out_2 ; 
	end
end

endmodule

