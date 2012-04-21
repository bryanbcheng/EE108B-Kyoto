//******************************************************************************
// EE108b MIPS verilog model
//
// MIPStest.v
//
// testbench setup for MIPS.v
//
//******************************************************************************

module MIPStest ();

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
    # 400;

    #100000; $stop;
  end

  always #20 MClk = ~MClk;

  MIPS mips (
    .clk(MClk),
    .rst(reset),
    .step(1'b0),
    .display_mode(1'b1),
    .run_mode(1'b1)
  );

endmodule
