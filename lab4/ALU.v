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
	ALUResult, ALUZero, ALUNeg,

	// Inputs
	ALUOp, ALUOpX, ALUOpY
);

	input [3:0]	ALUOp;				// Operation select
	input [31:0]	ALUOpX, ALUOpY;		// operands

	output [31:0]	ALUResult;			// result of operation
	output		ALUZero, ALUNeg;		// result is 0 or negative

//******************************************************************************
// Shift operation: ">>>" will perform an arithmetic shift, but the operand
// must be reg signed
//******************************************************************************
	reg signed [31:0] signedALUOpY;
	
	always @(ALUOpY) begin
		signedALUOpY = ALUOpY;
	end

//******************************************************************************
// Set operation
//******************************************************************************
	wire			aNbP, aPbN, sameSign;
	wire [31:0]	subRes;
	wire			isSLT, isSLTU;
	
	// if 2 operands are of the same sign, subtraction will not overflow
	assign sameSign = ~(ALUOpX[31] ^ ALUOpY[31]);
	assign aNbP = ALUOpX[31] & ~ALUOpY[31];
	assign aPbN = ~ALUOpX[31] & ALUOpY[31];
	assign subRes  = ALUOpX - ALUOpY;

	// determine if set
	assign isSLT = aNbP | (sameSign & subRes[31]);
	assign isSLTU = aPbN | (sameSign & subRes[31]);
	
//******************************************************************************
// ALU datapath
//******************************************************************************
	
	// Decoded ALU operation select (ALUsel) signals
	`define	select_alu_add		4'b0000
	`define	select_alu_and		4'b0001
	`define	select_alu_xor		4'b0010
	`define	select_alu_or		4'b0011
	`define	select_alu_nor		4'b0100
	`define	select_alu_sub		4'b0101
	`define	select_alu_sltu		4'b0110
	`define	select_alu_slt		4'b0111
	`define	select_alu_srl		4'b1000
	`define	select_alu_sra		4'b1001
	`define	select_alu_sll		4'b1010
	`define select_alu_passa	4'b1011
	`define	select_alu_passb	4'b1100

	reg [31:0]		ALUResult;
	
	always @(ALUOpX or ALUOpY or ALUOp or isSLTU or isSLT or signedALUOpY) begin

		case (ALUOp)

			`select_alu_add:	ALUResult = ALUOpX + ALUOpY;	 		// ADD, ADDI, ADDU, ADDIU
			`select_alu_and:	ALUResult = ALUOpX & ALUOpY;			// AND, ANDI
			`select_alu_xor:	ALUResult = ALUOpX ^ ALUOpY;			// XOR, XORI
			`select_alu_or:	ALUResult = ALUOpX | ALUOpY;			// OR, ORI
			`select_alu_nor:	ALUResult = ~(ALUOpX | ALUOpY);		// NOR
			`select_alu_sub:	ALUResult = ALUOpX - ALUOpY;			// SUB, SUBU, BEQ, BNE
			`select_alu_sltu:	ALUResult = {31'b0, isSLTU};			// SLTU, SLTIU
			`select_alu_slt:	ALUResult = {31'b0, isSLT};			// SLT, SLTI
			`select_alu_sra:	ALUResult = signedALUOpY >>> ALUOpX;	// SRA
			`select_alu_srl:	ALUResult = ALUOpY >> ALUOpX;			// SRL
			`select_alu_sll:	ALUResult = ALUOpY << ALUOpX;			// SLL
			`select_alu_passa:	ALUResult = ALUOpX;					// BGEZ, BGTZ, BLEZ, BLTZ
			`select_alu_passb:	ALUResult = ALUOpY;					// JAL, JALR

			default:			ALUResult = 32'bxxxxxxxx;			// Undefined
		endcase
	end

	assign ALUZero = (ALUResult[30:0] == 31'b0);
	assign ALUNeg = ALUResult[31];
	
endmodule