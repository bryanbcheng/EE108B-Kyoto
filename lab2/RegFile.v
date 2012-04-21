//******************************************************************************
// EE108b MIPS verilog model
//
// RegFile.v
//
// Contains the 1W2R register file
//
// written by Daniel L. Rosenband, MIT 10/4/99
// modified by John Kim, 3/26/03
// modified by Neil Achtman, 8/15/03
//
//******************************************************************************

module RegFile (
  // Outputs
  RsData, RtData,  
  // Inputs
  clk, clken, RegWriteData, RegWriteAddr, RegWriteEn, RsAddr, RtAddr
);

  input clk;
  input clken;

  // Info for register write port
  input [31:0] RegWriteData;
  input [4:0] RegWriteAddr;
  input RegWriteEn;

  input [4:0] RsAddr, RtAddr;

  // Data from register read ports
  output [31:0] RsData;  // data output for read port A
  output [31:0] RtData;  // data output for read port B

  // 32-register memory declaration
  reg [31:0] regs [0:31];

//******************************************************************************
// get data from read registers
//******************************************************************************

  assign RsData = (RsAddr == 5'b0) ? 32'b0 : regs[RsAddr];
  assign RtData = (RtAddr == 5'b0) ? 32'b0 : regs[RtAddr];

//******************************************************************************
// write to register if necessary 
//******************************************************************************

  always @ (posedge clk)
    if (RegWriteEn & clken)
      regs[RegWriteAddr] <= RegWriteData;

endmodule
