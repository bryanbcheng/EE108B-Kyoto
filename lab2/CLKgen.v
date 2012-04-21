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
  clk_in,
  step, 
  rst 
);
  input clk_in;		// 100 MHz
  input rst;
  input step;
  
  output memclk;		// 25 MHz
  output mipsclk;		// 12.5 MHz
  output wire step_pulse;            // single cycle (using mipsclk) pulse
  output clk_out;		// 50 MHz
  
  wire clk_out;
  reg [1:0] counter;
  
  //******************************************************************************
  // Clock divider
  //******************************************************************************
  // CLK = 100Mhz : main clock coming from the Xilinx board
  // The original XSA board ran at 50MHz, to preserve all other code, divide 100 MHz
  // by 2
  
  assign clk_out = counter[0];
  assign mem_clk = counter[1];
  
  always @(posedge clk_in) begin
    if (rst)
      counter = 0;
    else
      counter = counter + 1;
  end

//******************************************************************************
// Generate memory and processor clocks
//******************************************************************************
// CLK/2 = memclk (25Mhz) (inverted)
// Clk/4 = mipsclk (12.5MHz)

  dffar  dffr_div2 ( .clk(clk_in), .d(~memclk), .en(1'b1), .r(rst), .q(memclk));  
  dffar  dffr_div4 ( .clk(~memclk), .d(~mipsclk), .en(1'b1), .r(rst), .q(mipsclk));

//******************************************************************************
// generate one-cycle pulse for stepping through program
// pushbutton signal (step) is active-low
//******************************************************************************

  assign step_pulse = step;
  /*
  wire step_debounce;

  debouncer debounce (.clk(clk_out), .in(step), .out(step_debounce), .r(rst), .en(1'b1));
  one_pulse pulse (.clk(mipsclk), .in(step_debounce), .out(step_pulse));
  */

endmodule
