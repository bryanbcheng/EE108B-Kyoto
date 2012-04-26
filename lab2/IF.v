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

  wire [31:0] branch_offset;
  `define jump_target 25:0

  assign branch_offset = {instr[15], 14'b0, instr[14:0], 2'b0};

  // MODIFY THE CODE BELOW SO THAT THE PROCESSOR HANDLES JUMPS AND BRANCHES CORRECTLY
  always @* begin
    if (JumpBranch == 1) begin
      // assume no overflow
      pc_next = pc + branch_offset;
    end else if (JumpTarget == 1) begin
      pc_next = {pc[31:28], instr[`jump_target], 2'b0};
    end else if (JumpReg == 1) begin
      pc_next = RsData;
    end else begin
      pc_next = pc + 3'h4;
    end
  end

//******************************************************************************
// instruction memory instantiation
//******************************************************************************

  irom instruction_memory(.addra(pc[10:2]), .clka(memclk), .douta(instr));

endmodule
