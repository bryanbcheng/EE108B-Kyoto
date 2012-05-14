//******************************************************************************
// EE108b MIPS verilog model
//
// ALU.v
//
// The ALU performs all the arithmetic/logical integer operations 
// specified by the ALUsel from the decoder. 
// 
// verilog written by Daniel L. Rosenband, MIT 10/4/99
// modified by John Kim 3/26/03
// modified by Neil Achtman 8/15/03
//
//******************************************************************************

module ALU (
  // Outputs
  ALUResult,
  // Inputs
  ALUOp, ALUOpX, ALUOpY
);

  input [3:0] ALUOp;                // Operation select
  input [31:0] ALUOpX, ALUOpY;      // operands

  output reg [31:0] ALUResult;     // result of operation

//******************************************************************************
// Shift operation: ">>>" will perform an arithmetic shift, but the operand
// must be reg signed, also useful for signed vs. unsigned comparison.
//******************************************************************************
  wire signed [31:0] signedALUOpX = ALUOpX;
  wire signed [31:0] signedALUOpY = ALUOpY;
  
//******************************************************************************
// ALU datapath
//******************************************************************************
		
  // Decoded ALU operation select (ALUsel) signals
  `define select_alu_addu 4'd0
  `define select_alu_and 4'd1
  `define select_alu_xor 4'd2
  `define select_alu_or 4'd3
  `define select_alu_nor 4'd4
  `define select_alu_subu 4'd5
  `define select_alu_sltu 4'd6
  `define select_alu_slt 4'd7
  `define select_alu_srl 4'd8
  `define select_alu_sra 4'd9
  `define select_alu_sll 4'd10
  `define select_alu_passx 4'd11
  `define select_alu_passy 4'd12
  `define select_alu_add 4'd13
  `define select_alu_sub 4'd14

  
  always @(ALUOpX or ALUOpY or ALUOp or signedALUOpX or signedALUOpY) begin
    case (ALUOp)
      // PERFORM ALU OPERATIONS DEFINED ABOVE
      `select_alu_add:
        ALUResult = ALUOpX + ALUOpY;
      `select_alu_addu:
        ALUResult = ALUOpX + ALUOpY;
      `select_alu_and:
        ALUResult = ALUOpX & ALUOpY;
      `select_alu_xor:
        ALUResult = ALUOpX ^ ALUOpY;
      `select_alu_or:
        ALUResult = ALUOpX | ALUOpY;
      `select_alu_nor:
        ALUResult = ~(ALUOpX | ALUOpY);
      `select_alu_sub:
        ALUResult = ALUOpX - ALUOpY;
      `select_alu_subu:
        ALUResult = ALUOpX - ALUOpY;
      `select_alu_sltu:
        ALUResult = ALUOpX < ALUOpY;
      `select_alu_slt:
        ALUResult = signedALUOpX < signedALUOpY;
      `select_alu_srl:
        ALUResult = ALUOpY >> ALUOpX; // shift operations are Y >> X
      `select_alu_sra:
        ALUResult = signedALUOpY >>> ALUOpX;
      `select_alu_sll:
        ALUResult = ALUOpY << ALUOpX;
      `select_alu_passx:
        ALUResult = ALUOpX;
      `select_alu_passy:
        ALUResult = ALUOpY;
      default:
        ALUResult = 32'hxxxxxxxx;   // Undefined
    endcase
  end
  
endmodule
