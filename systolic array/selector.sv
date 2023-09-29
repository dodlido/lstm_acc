
//data out is 0 if enable is 0, otherwise it is data in
//used in weights top to feed in 0 elements to PEs

module selector #(parameter ELEMENT_BITS = 8) ( 			
	input logic 					enable,
	input logic  [ELEMENT_BITS-1:0]	data_in,
	output logic [ELEMENT_BITS-1:0]	data_out
);

logic enable_delayed ; 

assign data_out = (enable_delayed) ? data_in : {ELEMENT_BITS{1'b0}} ; 

always_ff @(posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		enable_delayed <= #1 1'b0 ; 
	end
	else begin 
		enable_delayed <= #1 enable ; 
	end
end


endmodule