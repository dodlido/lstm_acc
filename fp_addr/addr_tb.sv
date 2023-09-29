// a single proccessing element - PE
module addr_tb;

logic	[7:0]	in_a ;
logic	[7:0]	in_b ;
logic	[7:0]	res  ;
logic			zero ;

addr_top uut (.in_a(in_a),.in_b(in_b),.res(res),.zero(zero)) ; 

initial begin
	in_a = 8'b00010101 ; //0.328125
	in_b = 8'b00001010 ; //0.15625
	//res should be (0-001-1111)2 = (0.484375)10
	#100
	in_a = 8'b00011111 ; //0.484375
	in_b = 8'b00001010 ; //0.15625
	//res should be (0-010-0100)2 = (0.625)10
	#100
	in_a = 8'b00011111 ; //0.484375
	in_b = 8'b00100100 ; //0.625
	//res should be (0-011-0001)2 = (1.0625)10
	#100
	in_a = 8'b10011111 ; //-0.484375
	in_b = 8'b00100100 ; //0.625
	//res should be (0-000-1001)2 = (0.140625)10
	#100
	in_a = 8'b00011111 ; //0.484375
	in_b = 8'b10100100 ; //-0.625
	//res should be (1-000-1001)2 = (-0.140625)10
	#100
	in_a = 8'b00011111 ; //0.484375
	in_b = 8'b10011111 ; //-0.484375
	//res should be (0-000-0000)2 = (0)10
	#100
	in_a = 8'b00100100 ; //0.625
	in_b = 8'b10100100 ; //-0.625
	//res should be (0-000-0000)2 = (0)10
	#100
	in_a = 8'b00000000 ; //0
	in_b = 8'b00000000 ; //0
	//res should be (0-000-0000)2 = (0)10
end

endmodule