//******************************************************************************
// EE108b MIPS verilog model
//
// Sega_ctl.v
//
// Converts input from the Sega gamepad into a 32-bit word
//
// If you want to change the interface, talk to the TAs before modifying this file
//
// written by Neil Achtman, 8/15/03
//
//******************************************************************************

module Sega_ctl (clk, up, down, left, right, a_b, c_start, select, move);

	input		clk;		// 50 MHz
	
	input		up, down, left, right, a_b, c_start;

	output [31:0]	move;
	reg [31:0]	move;

	output		select;

	assign select = 1;

	// assign inputs to data word, converting from active low to active high
	
	always @(posedge clk) begin
		move[31:0] <= {27'b0, ~a_b | ~c_start, ~right, ~left, ~down, ~up};
	end

endmodule
