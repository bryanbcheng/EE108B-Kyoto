//******************************************************************************
// EE108b MIPS verilog model
//
// IF.v
//
// Calculates the next PC and retrieves the instruction from memory
//
// verilog written by Daniel L. Rosenband, MIT 10/4/99
// modified by John Kim 3/26/03
// modified by Neil Achtman, 8/15/03
//
//******************************************************************************

module IF (
  // Outputs
  pc, instr,
  // Inputs
  clk, memclk, clken, rst, RsData, JumpBranch, JumpTarget, JumpReg
);

  input clk, memclk, clken;
  input rst;            // start from PC = 0

  input JumpBranch;     // branch offset should be next PC
  input JumpTarget;     // target addr should be next PC
  input JumpReg;        // register data should be next PC

  input [31:0] RsData;  // used for JR instruction
  
  output [31:0] instr;  // current instruction
  output [31:0] pc; // address of instruction

//******************************************************************************
// calculate the next PC
//******************************************************************************

  reg [31:0] pc_next;
  dffar #(32) pc_ff (.clk(clk), .r(rst), .en(clken), .d(pc_next), .q(pc));

  // MODIFY THE CODE BELOW SO THAT THE PROCESSOR HANDLES JUMPS AND BRANCHES CORRECTLY
  always @* begin
    pc_next = pc + 3'h4;
  end

//******************************************************************************
// instruction memory instantiation
//******************************************************************************

  irom instruction_memory(.addra(pc[10:2]), .clka(memclk), .douta(instr));

endmodule
