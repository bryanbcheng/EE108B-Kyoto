//******************************************************************************
// EE108b MIPS verilog model
//
// MIPStest.v
//
// testbench setup for MIPS.v
// This module will only be used in MODELSIM
//
//******************************************************************************

module MIPStest;

reg MClk;
reg reset;
initial MClk = 0;

initial begin
  $dumpfile("MIPStest.lxt");
  $dumpvars(0, MIPStest);
  reset = 1;
  # 100;
  reset = 0;
  # 100;
  reset = 1;
  
  #50000;
  $stop;
end

always #20 MClk = ~MClk;

MIPS mips (
  .clk(MClk),
  .rst(reset),
  .step(1'b0),
  .run_mode(1'b1)
);

endmodule
