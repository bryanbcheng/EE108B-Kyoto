module counter_ar(
	clk, 
	rst, 
	en, 
	count);
	
	parameter n=3;
  
 	input clk, rst, en;
 	output [n-1:0] count;

	wire [n-1:0] next_count, count;

	dffar #(n) count_reg(.clk(clk), .r(rst), .en(en), .d(next_count), .q(count));

	assign next_count = rst ? {n{1'b0}} : count + 1;
	
endmodule