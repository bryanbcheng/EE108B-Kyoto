//******************************************************************************
// EE108b MIPS verilog model
//
// MIPS.v
//
// Top-level module for MIPS processor implementation.
//
// verilog written by Daniel L. Rosenband, MIT 10/4/99
// modified by John Kim, 3/26/03
// modified by Neil Achtman, 8/15/03
//
//******************************************************************************

module MIPS (
  clk, rst, display_mode, run_mode, step
);

  input clk;                      // 100 MHz --> might have to reduce to 50 if doesn't work
  input rst;                      // active low reset

  // Mode control
  input display_mode;             // toggle between debug and run
  input run_mode;                 // whether to step through 1 instruction at a time
  input step;                     // step through 1 instruction

  // Clock signals
  wire mipsclk;                   // clock for processor (12.5 MHz)
  wire memclk;                    // clock for memory (25 MHz, inverted)
  wire step_pulse;                // one cycle pulse from step button

  // IF input
  wire JumpBranch;                // use the branch offset for next pc
  wire JumpTarget;                // use the target field for next pc
  wire JumpReg;                   // use data in Rs for next pc
  
  // IF output
  wire [31:0] instr;              // current instruction
  wire [31:0] pc;                 // current pc

  // Regfile input
  wire [31:0] RegWriteData;       // data to be written to register file
  wire [4:0]  RegWriteAddr;       // address of register to be written to
  wire RegWriteEn;                // whether to write to a register
  
  // Regfile output
  wire [31:0] RsData;
  wire [31:0] RtData;

  // ALU input
  wire [31:0] ALUOpX, ALUOpY;     // ALU operands
  wire [3:0] ALUOp;               // ALU operation to perform
  
  // ALU output
  wire ALUZero, ALUNeg;           // whether ALU result is 0 or negative
  wire [31:0] ALUResult;          // ALU result

  // Data memory interface
  wire [31:0] DMemAddr;           // address to access in memory
  wire DMemWE;                    // whether to write to memory
  wire VgaWE;                     // whether to write to VGA interface
  wire [31:0] SegaData = 32'b0;   // data from Sega gamepad
  wire clk_50mhz;

//******************************************************************************
// Instruction Fetch unit
//******************************************************************************

  IF IF (
    // Outputs
    .pc(pc),        
    .instr(instr),
    // Inputs
    .clk(mipsclk),
    .memclk(memclk),
    .clken(run_mode | step_pulse),
    .rst(~rst),
    .JumpBranch(JumpBranch), 
    .JumpTarget(JumpTarget),
    .JumpReg(JumpReg),
    .RsData(RsData)
  );

//******************************************************************************
// Instruction Decode unit
//******************************************************************************
  Decode Decode(
    // Outputs
    .JumpBranch(JumpBranch), 
    .JumpTarget(JumpTarget),
    .JumpReg(JumpReg),
    .ALUOp(ALUOp),
    .ALUOpX(ALUOpX),
    .ALUOpY(ALUOpY),
    .MemToReg(MemToReg),
    .MemWrite(MemWrite),
    .RegWriteAddr(RegWriteAddr),
    .RegWriteEn(RegWriteEn),
    // Inputs
    .instr(instr),
    .pc(pc),
    .RsData(RsData),
    .RtData(RtData),
    .ALUZero(ALUZero),
    .ALUNeg(ALUNeg)
  );

//******************************************************************************
// Register File
//******************************************************************************

  `define rs 25:21 // 5-bit source register specifier
  `define rt 20:16 // 5-bit source/dest register specifier

  RegFile RegFile (
    // Outputs
    .RsData(RsData),
    .RtData(RtData),
    // Inputs
    .clk(mipsclk),
    .clken(run_mode || step_pulse),
    .RegWriteData(RegWriteData),
    .RegWriteAddr(RegWriteAddr),
    .RegWriteEn(RegWriteEn),
    .RsAddr(instr[`rs]),
    .RtAddr(instr[`rt])
  );

//******************************************************************************
// ALU (Execution Unit)
//******************************************************************************

  ALU ALU (
    // Outputs
    .ALUResult(ALUResult),
    .ALUZero(ALUZero),
    .ALUNeg(ALUNeg),
    // Inputs
    .ALUOp(ALUOp),
    .ALUOpX(ALUOpX),
    .ALUOpY(ALUOpY)
  );

//******************************************************************************
// Interface with Data Memory
//******************************************************************************

  MemStage MemStage (
    // Outputs
    .VgaWE(VgaWE),
    .RegWriteData(RegWriteData),
    // Inputs			
    .clk(memclk),
    .MemToReg(MemToReg),
    .MemWrite(MemWrite),
    .ALUResult(ALUResult),
    .RtData(RtData),
    .SegaData(SegaData)
  );

//******************************************************************************
// Clock generator
//******************************************************************************

  // CLK = 50Mhz : main clock coming from the XSA board
  // CLK/2 = memclk (25Mhz) (inverted)
  // Clk/4 = mipsclk (12.5MHz)

  CLKgen  CLKgen (
    // Outputs
    .mipsclk(mipsclk),
    .memclk(memclk),
    .step_pulse(step_pulse),
    .clk_out (clk_50mhz),
    // Inputs
    .clk_in(clk),
    .rst(~rst),
    .step(~step)
  );

endmodule
