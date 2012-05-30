//******************************************************************************
// EE108b MIPS verilog model
//
// one_pulse.v
//
// Generate one-cycle pulse of an input
//
// written by Neil Achtman 8/15/03
//
//******************************************************************************

module one_pulse(clk, in, out);

	input clk, in;
	
	output out;

	reg [1:0] state;

	`define IDLE	2'b00
	`define PULSE	2'b01
	`define WAIT	2'b10

	always @(posedge clk) begin
		case (state)
			
			// wait for input

			`IDLE:	if (in)
						state[1:0] <= `PULSE;
					else
						state[1:0] <= `IDLE;
			
			// generate pulse for one cycle

			`PULSE:	state[1:0] <= `WAIT;

			// wait for input to go low

			`WAIT:	if (~in)
						state[1:0] <= `IDLE;
					else
						state[1:0] <= `WAIT;

			default:	state[1:0] <= `IDLE;

		endcase
	end

	assign out = state[0];	// output asserted only if in PULSE state

endmodule