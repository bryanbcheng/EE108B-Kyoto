//******************************************************************************
// EE108b MIPS verilog model
//
// MIPStest.v
//
// testbench setup for MIPS.v
// This module will only be used in MODELSIM
//
//******************************************************************************

module MIPStest ( );

wire select;

reg MClk;
reg reset;

initial MClk = 0;

initial begin
  $dumpfile("MIPStest.lxt");
  $dumpvars(0, MIPStest);
  reset = 1;
  # 100;
  reset = 0;
  # 400;
  reset = 1;
  # 1000;
// This takes a looooong time to process...maybe about 10-15 minutes. Since our 
// implementation is cacheless, this takes almost 400,000 of these clock cycles...
  #11500; $stop; 
end

always #20 MClk = ~MClk;

MIPS mips (
	.clk			(MClk),
	.rst			(reset),
	.step		(1'b0),
	
	.display_mode	(1'b1),
	.run_mode		(1'b1)
	
	// Feel free to change these
);

endmodule
