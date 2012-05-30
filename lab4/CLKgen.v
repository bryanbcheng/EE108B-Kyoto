//******************************************************************************
// EE108b MIPS verilog model
//
// CLKgen.v
//
// Generates the different clocks and 
// the logic needed to single step through in hardware
//
// modified by Neil Achtman, 8/15/03
//
//******************************************************************************

module CLKgen (
	//Outputs
	memclk,
	mipsclk, 
	step_pulse,
	clk_out,

	//Inputs
	clk,
	step, 
	rst 
);


input	clk;			// 100 MHz
input	rst;
input	step;


output	mipsclk;		// 25 MHz
output	memclk;		// 50 MHz
output	step_pulse;	// single cycle (using mipsclk) pulse
output	clk_out;		// 50 MHz
reg		clk_out;

//******************************************************************************
// Clock divider
//******************************************************************************
// CLK = 100Mhz : main clock coming from the Xilinx board
// The original XSA board ran at 50MHz, to preserve all other code, divide 100 MHz
// by 2

always @(posedge clk)
	if (rst == 1'b0)
		clk_out <= clk_out + 1;
	else
		clk_out <= 1'b0;

// generate processor clock
wire		memclk;		// 50 MHz
dffar dffr_div2 ( .clk(clk_out), .en(1'b1), .d(~memclk), .r(rst), .q(memclk));
dffar  dffr_div4 ( .clk(memclk), .en(1'b1), .d(~mipsclk), .r(rst), .q(mipsclk));
//dffar dffr_div4 ( .clk(clk_out), .en(1'b1), .d(~mipsclk), .r(rst), .q(mipsclk));

// generate one-cycle pulse for stepping through program
// pushbutton signal (step) is active-low

assign step_pulse = step;

/*
wire		step_debounce;
debouncer debounce (.clk(clk), .in(step), .out(step_debounce), .r(rst), .en(1'b1));
one_pulse pulse (.clk(mipsclk), .in(step_debounce), .out(step_pulse));
*/

endmodule
