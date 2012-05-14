//******************************************************************************
// EE108b MIPS verilog model
//
// ff.v
//
// contains flop-flop definitions to be used in the design
//
// from EE183 library
//
//******************************************************************************

// dff: D flip-flop
// Parametrized width; default of 1
module dff(d, clk, q);
  parameter WIDTH = 1;
  input clk;
  input [WIDTH-1:0] d;
  output reg [WIDTH-1:0] q;
  
  always @ (posedge clk) 
    q <= d;

endmodule

// dffr: D flip-flop with active high synchronous reset
// Parametrized width; default of 1
module dffr(d, r, clk, q);
  parameter WIDTH = 1;
  input r, clk;
  input [WIDTH-1:0] d;
  output reg [WIDTH-1:0] q;

  always @ (posedge clk) 
    if (r) 
      q <= {WIDTH{1'b0}};
    else
      q <= d;

endmodule


// dffre: D flip-flop with active high enable and reset
// Parametrized width; default of 1
module dffre (d, en, r, clk, q);
  parameter WIDTH = 1;
  input en, r, clk;
  input [WIDTH-1:0] d;
  output reg [WIDTH-1:0] q;

  always @ (posedge clk)
    if (r)
      q <= {WIDTH{1'b0}};
    else if (en)
      q <= d;
    else
      q <= q;

endmodule


// dffar: D flip-flop with active high asynchronous reset
// Parametrized width; default of 1
module dffar (d, en, r, clk, q);
  parameter WIDTH = 1;
  input en, r, clk;
  input [WIDTH-1:0] d;
  output reg [WIDTH-1:0] q;

  always @ (posedge clk or posedge r)
    if (r)
      q <= {WIDTH{1'b0}};
    else if (en)
      q <= d;
    else
      q <= q;

endmodule


