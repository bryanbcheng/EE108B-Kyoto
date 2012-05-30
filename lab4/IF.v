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
  clk, memclk, clken, rst, RsData, JumpBranch, JumpTarget, JumpReg, dram_busy
);

  input 		clk, memclk;
  input		clken;
  input 		rst;			// start from PC = 0
  input 		JumpBranch;	// branch offset should be next PC
  input 		JumpTarget;	// target addr should be next PC
  input 		JumpReg;		// register data should be next PC
  input		dram_busy;	// DRAM is busy
  input [31:0]	RsData;		// used for JR instruction
  
  output [31:0]	instr;		// current instruction
  output [31:0]	pc;			// address of instruction
    


//******************************************************************************
// calculate the next PC
//******************************************************************************

  `define	immediate		15:0		// 16-bit immediate, branch or address disp
  `define	targetfield		25:0		// 26-bit jump target address
  
  wire [15:0] offset;					// offset for next instruction, used with branches
  wire [31:0] signExtendedOffset;		// 32-bit sign extended offset
  wire [25:0] target;					// used with J/JAL instructions
  
  assign offset = instr[`immediate];
  assign signExtendedOffset = {{14{offset[15]}}, offset[15:0], 2'b00};
  
  assign target = instr[`targetfield];

  reg [31:0] pc_next;
  wire [31:0] pc;			// program counter
  
  always @* begin
    if (JumpBranch)
      pc_next = pc + signExtendedOffset + 3'h4;
    else if (JumpTarget)
      pc_next = {pc[31:28], target, 2'b0};
    else if (JumpReg)
      pc_next = RsData;
    else
      pc_next = pc + 3'h4;
  end

  dffar #(32) pc_reg (.clk(clk), .r(rst), .en(clken), .d(pc_next), .q(pc));
   
  irom i_rom (.addr(pc[9:2]), .clk(memclk), .dout(instr));

endmodule
