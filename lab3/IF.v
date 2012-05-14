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
// modified by Nicolas Kokkalis, Stanford 2/22/05
//
//******************************************************************************

module IF (
  // Outputs
  pc_out, instr_out,
  // Inputs
  clk, mipsclk, rst, en, pc_in, instr_in, RsData, JumpBranch, JumpTarget, JumpReg
);

  input clk;
  input rst;             // start from PC = 0
  input en;
  
  input mipsclk;
  
  input [31:0] pc_in, instr_in;
  
  input JumpBranch;      // branch offset should be next PC
  input JumpTarget;      // target addr should be next PC
  input JumpReg;         // register data should be next PC
  
  input [31:0] RsData;   // used for JR instruction
  
  output wire [31:0] pc_out; // address of instruction
  output [31:0] instr_out;

//******************************************************************************
// calculate the next PC
//******************************************************************************

  wire [31:0] signExtendedWordOffset = {{14{instr_in[15]}}, instr_in[15:0], 2'b0};
  wire [25:0] target = instr_in[25:0];

  reg [31:0] pc_next;
  dffar #(32) pc_ff (.clk(mipsclk), .r(rst), .en(en), .d(pc_next), .q(pc_out));

  always @* begin
    if (JumpBranch)
      pc_next = pc_in + 3'h4 + signExtendedWordOffset;
    else if (JumpTarget)
      pc_next = {pc_in[31:28], target, 2'b0};
    else if (JumpReg)
      pc_next = RsData;
    else
      pc_next = pc_out + 3'h4;
  end

//******************************************************************************
// instruction memory instantiation
//******************************************************************************

  irom instruction_memory(.addra(pc_out[10:2]), .clka(clk), .douta(instr_out));

endmodule
