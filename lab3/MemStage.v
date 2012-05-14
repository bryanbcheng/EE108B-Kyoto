//******************************************************************************
// EE108b MIPS verilog model
//
// MemStage.v
//
// Stores/loads data to/from memory, and determines what data should be
// written back to the register
//
// verilog written by Daniel L. Rosenband, MIT 10/4/99
// modified by John Kim, 3/26/03
// modified by Neil Achtman, 8/15/03
// modified by T.J. Hsiang, Stanford 2/21/05
// modified by Nicolas Kokkalis, Stanford 2/21/05
//
//******************************************************************************

module MemStage (
  // Outputs
  VgaWE, RegWriteData, 
  
  // Inputs
  clk, MemToReg, MemWrite, ALUResult, MemWriteData, SegaData
);

  input clk;
  
  input MemToReg;			// register writeback data: 0 for memory load result,										// 1 for ALU result
  input MemWrite;			// store operation: enable writing to memory
  
  input [31:0] ALUResult;		// output of ALU, memory address for load/store ops
  input [31:0] MemWriteData;		// data for store instructions
  input [31:0] SegaData;			// data from Sega gamepad
  
  output VgaWE;			// store data to VGA instead of data memory
  output [31:0] RegWriteData;		// data to be written to register
  
  wire [31:0] MemDataOut;		// data loaded from memory

//******************************************************************************
// control for memory-mapped I/O
//******************************************************************************
  wire VgaAddr, SegaAddr;	// memory-mapped I/O addresses
  
  assign VgaAddr = (ALUResult[7:0] == 8'hff);		// store data to VGA
  assign VgaWE = MemWrite & VgaAddr;
  
  assign SegaAddr = (ALUResult[7:0] == 8'hfd);	// load data from Sega gamepad

//******************************************************************************
// determine what data to write to register
//******************************************************************************
  reg [31:0] RegWriteData;
  
  always @ (ALUResult or MemDataOut or SegaData or MemToReg or SegaAddr) begin
  	if (MemToReg) begin
      if (SegaAddr)
        RegWriteData = SegaData;
      else
        RegWriteData = MemDataOut;
  	  end
    else
      RegWriteData = ALUResult;
  end

//******************************************************************************
// data memory instantiation
//******************************************************************************

  dataram dmem(.clka(clk), .addra(ALUResult[7:2]), .dina(MemWriteData), .douta(MemDataOut), .wea(MemWrite & ~VgaAddr));

endmodule
