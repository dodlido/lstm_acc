module dmac #(MAIN_MEM_ADD_LEN = 11, FEATURES = 4, WEIGHTS = 64) (
	input  logic						fpga_clk,
	input  logic 						reset_n,
	input  logic 						direct, // direction of data transition: 0=main_mem to lstm, 1=lstm to main_mem
	input  logic						start,
	input  logic [MAIN_MEM_ADD_LEN-1:0]	main_mem_count,
	input  logic [MAIN_MEM_ADD_LEN-1:0]	main_mem_first_address,
	output logic [MAIN_MEM_ADD_LEN-1:0] main_mem_address_in_delayed,
	output logic [MAIN_MEM_ADD_LEN-1:0] main_mem_address_out,
	output logic 						main_mem_oe,
	output logic						main_mem_we_delayed
);

logic [MAIN_MEM_ADD_LEN-1:0] counter ;
logic						 main_mem_we ; 

//counter
always_ff @(posedge fpga_clk or negedge reset_n) begin
	if (!reset_n)
		counter <= #1 {MAIN_MEM_ADD_LEN{1'b0}} ; 
	else begin
		if(counter==(main_mem_count-{{MAIN_MEM_ADD_LEN-1{1'b0}},1'b1}))
			counter <= #1 {MAIN_MEM_ADD_LEN{1'b0}} ; 
		else if((main_mem_oe)||(main_mem_we))
			counter <= #1 counter + {{MAIN_MEM_ADD_LEN-1{1'b0}},1'b1} ; 
		else
			counter <= #1 {MAIN_MEM_ADD_LEN{1'b0}} ; 
	end
end

//we
assign main_mem_we = (((start)||(counter!={MAIN_MEM_ADD_LEN{1'b0}}))&&(direct)) ; 

//main_mem_address_out
assign main_mem_address_out = ((main_mem_oe)||(main_mem_we)) ? (main_mem_first_address + counter) :  {MAIN_MEM_ADD_LEN{1'b0}}; 

//oe
assign main_mem_oe = (((start)||(counter!={MAIN_MEM_ADD_LEN{1'b0}}))&&(!direct)) ; 

//main_mem_we_delayed
always_ff @(posedge fpga_clk or negedge reset_n) begin
	if (!reset_n)
		main_mem_we_delayed <= #1 1'b0 ; 
	else begin
		main_mem_we_delayed <= #1 main_mem_we ; 
	end
end

//main_mem_address_in_delayed
always_ff @(posedge fpga_clk or negedge reset_n) begin
	if (!reset_n)
		main_mem_address_in_delayed <= #1 {MAIN_MEM_ADD_LEN{1'b0}} ; 
	else begin
		main_mem_address_in_delayed <= #1 main_mem_address_out ; 
	end
end

endmodule
