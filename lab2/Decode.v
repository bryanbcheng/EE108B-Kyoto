//******************************************************************************
// EE108b MIPS verilog model
//
// Decode.v
//
// - Decodes the instructions
// - branch instruction condition are also determined and whether
//   the branch PC should be used 
// - ALU instructions are decoded and sent to the ALU
// - decode whether the instruction uses the Immediate field
//
// verilog written by Daniel L. Rosenband, MIT 10/4/99
// modified by John Kim, 3/26/03
// modified by Neil Achtman, 8/15/03
//
//******************************************************************************

module Decode(   
  // Outputs
  RegWriteAddr, JumpBranch, JumpTarget, JumpReg, ALUOp, ALUOpX, ALUOpY, MemWrite, MemToReg, RegWriteEn,
  // Inputs
  instr, ALUZero, ALUNeg, RsData, RtData, pc
);

  input [31:0] instr;               // current instruction
  input [31:0] pc;                  // current pc
  input [31:0] RsData, RtData;      // data from read registers
  input ALUZero, ALUNeg;            // whether result of ALU operation is 0 or negative
  
  output reg [4:0] RegWriteAddr;    // which register to write back data to
  output wire RegWriteEn;           // enable writing back to the register
  
  output wire MemToReg;             // use memory output as data to write into register
  output wire MemWrite;             // write to memory
  
  output wire JumpBranch;           // branch taken, address offset specified in instruction
  output wire JumpTarget;           // jump address specified in instruction
  output wire JumpReg;              // jump address specified in register
  
  output reg [3:0] ALUOp;           // ALU operation select
  output reg [31:0] ALUOpX, ALUOpY; // ALU operands

//******************************************************************************
// instruction field
//******************************************************************************

  `define opfield 31:26	// 6-bit operation code
  `define rs 25:21	// 5-bit source register specifier
  `define rt 20:16	// 5-bit source/dest register specifier 
  `define immediate 15:0	// 16-bit immediate, branch or address disp
  `define rd 15:11	// 5-bit destination register specifier
  `define safield 10:6	// 5-bit shift amount
  `define function 5:0		// 6-bit function field
  
  wire [5:0] op;
  wire [4:0] RtAddr, RdAddr, RsAddr;
  wire [4:0] sa;
  wire [5:0] funct;
  wire [15:0] immediate;
  
  assign op = instr[`opfield];
  assign sa = instr[`safield];
  assign RtAddr = instr[`rt];
  assign RdAddr = instr[`rd];
  assign RsAddr = instr[`rs];
  assign funct = instr[`function];
  assign immediate = instr[`immediate];

//******************************************************************************
// branch instructions decode
//******************************************************************************

  `define BLTZ_GEZ 6'b000001
  `define BEQ      6'b000100
  `define BNE      6'b000101
  `define BLEZ     6'b000110
  `define BGTZ     6'b000111
  `define BLTZ     5'b00000
  `define BGEZ     5'b00001
  `define BLTZAL   5'h10
  `define BGEZAL   5'h11
  
  wire isBEQ  = (op == `BEQ);
  wire isBGEZ = (op == `BLTZ_GEZ) & ((RtAddr == `BGEZ) | (RtAddr == `BGEZAL));
  wire isBGTZ = (op == `BGTZ) & (RtAddr == 5'b00000);
  wire isBLEZ = (op == `BLEZ) & (RtAddr == 5'b00000);
  wire isBLTZ = (op == `BLTZ_GEZ) & ((RtAddr == `BLTZ) | (RtAddr == `BLTZAL));
  wire isBNE  = (op == `BNE);

  // determine if branch is taken
  
  wire RsDataZero = RsData == 32'b0;
  wire RsDataNeg = RsData[31];

  assign JumpBranch = |{isBEQ & ALUZero,
                        isBNE & ~ALUZero, // make sure the ALU gives a zero output when appropriate
                        isBGTZ & ~(ALUZero | ALUNeg),
                        isBLEZ & (ALUZero | ALUNeg),
                        isBGEZ & ~ALUNeg,
                        isBLTZ & ALUNeg};

//******************************************************************************
// jump instructions decode
//******************************************************************************

  `define SPECIAL         6'b000000
  `define J               6'b000010
  `define JAL             6'b000011
  `define JR              6'b001000
  `define JALR            6'b001001
  
  wire isJ    = (op == `J);
  wire isJAL  = (op == `JAL);
  wire isJALR = (op == `SPECIAL) & (funct == `JALR);  
  wire isJR   = (op == `SPECIAL) & (funct == `JR);
  
  assign JumpTarget = isJ | isJAL;
  assign JumpReg = isJALR | isJR;
  
  // determine if the next pc will need to be stored
  wire isLink = isJALR | isJAL;


//******************************************************************************
// shift instruction decode
//******************************************************************************
  	
  `define SLL   6'b000000
  `define SRL   6'b000010
  `define SRA   6'b000011
  `define SLLV  6'b000100
  `define SRLV  6'b000110
  `define SRAV  6'b000111
  
  wire isSLL = (op == `SPECIAL) & (funct == `SLL);
  wire isSRA = (op == `SPECIAL) & (funct == `SRA);
  wire isSRL = (op == `SPECIAL) & (funct == `SRL);
  wire isSLLV = (op == `SPECIAL) & (funct == `SLLV);
  wire isSRAV = (op == `SPECIAL) & (funct == `SRAV);
  wire isSRLV = (op == `SPECIAL) & (funct == `SRLV);
  
  wire isShiftImm = isSLL | isSRA | isSRL;
  wire isShift = isShiftImm | isSLLV | isSRAV | isSRLV;
		
//******************************************************************************
// ALU instructions decode / control signal for ALU datapath
//******************************************************************************
	
  // OPCODES
  `define ADDI  6'b001000
  `define ADDIU 6'b001001
  `define SLTI  6'b001010
  `define SLTIU 6'b001011
  `define ANDI  6'b001100
  `define ORI   6'b001101
  `define XORI  6'b001110
  `define LUI   6'b001111
  `define LW    6'b100011
  `define SW    6'b101011

  // FUNCTION CODES (more are above for shifts)
  `define ADD   6'b100000
  `define ADDU  6'b100001
  `define SUB   6'b100010
  `define SUBU  6'b100011
  `define AND   6'b100100
  `define OR    6'b100101
  `define XOR   6'b100110
  `define NOR   6'b100111
  `define SLT   6'b101010
  `define SLTU  6'b101011
  
  // ALU OPCODES
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
  
  `define dc6 6'bxxxxxx
  
  always @(op or funct) begin
    casex({op, funct})
      // DETERMINE THE ALU OPERATION TO PERFORM FOR EACH OP/FUNCTION CODE
 	
      {`SPECIAL, `ADD}:	    ALUOp = `select_alu_add;
      {`SPECIAL, `ADDU}:    ALUOp = `select_alu_addu;
      {`ADDI, `dc6}:        ALUOp = `select_alu_add;
      {`ADDIU, `dc6}:       ALUOp = `select_alu_addu;

      {`SPECIAL, `SUB}:	    ALUOp = `select_alu_sub;
      {`SPECIAL, `SUBU}:    ALUOp = `select_alu_subu;

      {`SPECIAL, `SLT}:	    ALUOp = `select_alu_slt;
      {`SPECIAL, `SLTU}:    ALUOp = `select_alu_sltu;
      {`SLTI, `dc6}:	    ALUOp = `select_alu_slt;
      {`SLTIU, `dc6}:	    ALUOp = `select_alu_sltu;

      {`SPECIAL, `AND}:	    ALUOp = `select_alu_and;
      {`ANDI, `dc6}:	    ALUOp = `select_alu_and;

      {`SPECIAL, `OR}:	    ALUOp = `select_alu_or;
      {`ORI, `dc6}:	    ALUOp = `select_alu_or;

      {`SPECIAL, `XOR}:	    ALUOp = `select_alu_xor;
      {`XORI, `dc6}:	    ALUOp = `select_alu_xor;

      {`SPECIAL, `NOR}:	    ALUOp = `select_alu_nor;

      {`SPECIAL, `SRL}:	    ALUOp = `select_alu_srl;
      {`SPECIAL, `SRA}:	    ALUOp = `select_alu_sra;
      {`SPECIAL, `SLL}:	    ALUOp = `select_alu_sll;
      {`SPECIAL, `SRLV}:    ALUOp = `select_alu_srl;
      {`SPECIAL, `SRAV}:    ALUOp = `select_alu_sra;
      {`SPECIAL, `SLLV}:    ALUOp = `select_alu_sll;

      // add offset to address
      {`SPECIAL, `LW}:	    ALUOp = `select_alu_addu;
      {`SPECIAL, `SW}:	    ALUOp = `select_alu_addu;

      {`BEQ, `dc6}:         ALUOp = `select_alu_xor;
      {`BNE, `dc6}:	    ALUOp = `select_alu_xor;

      // compare rs data to 0, only care about 1 operand
      {`BGTZ, `dc6}:        ALUOp = `select_alu_passx;
      {`BLEZ, `dc6}:        ALUOp = `select_alu_passx;
      {`BLTZ_GEZ, `dc6}:    ALUOp = `select_alu_passx;
      
      // pass link address to be stored in $ra
      {`JAL, `dc6}:         ALUOp = `select_alu_passy;
      {`SPECIAL, `JALR}:    ALUOp = `select_alu_passy;
      
      // or immediate with 0
      {`LUI, `dc6}:         ALUOp = `select_alu_or;
      
      default:              ALUOp = `select_alu_passx;
    endcase
  end

//******************************************************************************
// Compute value for 32 bit immediate data
//******************************************************************************

  // SET THE VALUE OF "Imm" HERE
  reg [31:0] Imm;
  wire ALUSrc;	// where to get 2nd ALU operand from: 0 for RtData, 1 for Immediate
  always @(op or immediate) begin
    casex(op)
      // DETERMINE WHAT THE IMMEDIATE VALUE SHOULD BE FOR RELEVANT INSTRUCTIONS
      `ADDI : 	   Imm = immediate;
      `ADDIU :	   Imm = immediate;
      `SLTI :      Imm = immediate;
      `SLTIU :     Imm = immediate;
      `ANDI :      Imm = immediate;
      `ORI :	   Imm = immediate;
      `XORI :  	   Imm = immediate;
      `LW : 	   Imm = immediate;
      `SW :	   Imm = immediate;
      `LUI :       Imm = 32'b0;
      default :    Imm = 32'b0;
    endcase
    casex(op)
      `ADDI :      ALUSrc = 1'b1;
      `ADDIU :     ALUSrc = 1'b1;
      `SLTI :      ALUSrc = 1'b1;
      `SLTIU :     ALUSrc = 1'b1;
      `ANDI :      ALUSrc = 1'b1;
      `ORI :       ALUSrc = 1'b1;
      `XORI :      ALUSrc = 1'b1;
      `LW : 	   ALUSrc = 1'b1;
      `SW :	   ALUSrc = 1'b1;
      `LUI :       ALUSrc = 1'b1;
      default :    ALUSrc = 1'b0;
    endcase
  end
  
  // MAKE ASSIGNMENT TO ALUSrc SO IMMEDIATE VALUE IS USED FOR APPROPRIATE INSTRUCTIONS

//******************************************************************************
// Determine ALU inputs and register writeback address
//******************************************************************************
  
  // for shift operations, use either shamt field or lower 5 bits of rs
  // otherwise use rs
  		
  always @(RsData or sa or isShift or isShiftImm) begin
    if (isShift)
      ALUOpX = {27'b0, (isShiftImm) ? sa : RsData[4:0]};
    else
      ALUOpX = RsData;
  end
  
  // for link operations, use next pc (current pc + 4)
  // for immediate operations, use Imm
  // otherwise use rt
  
  always @(isLink or pc or isJALR or RdAddr or ALUSrc or Imm or RtAddr or RtData) begin
    if (isLink) begin
      ALUOpY = pc + 3'h4;
      RegWriteAddr = isJALR ? RdAddr : 5'd31; // write to return address
    end
    else if (ALUSrc) begin
      ALUOpY = Imm;
      RegWriteAddr = RtAddr;
    end
    else begin
      ALUOpY = RtData;
      RegWriteAddr = RdAddr;
    end
  end
  
  // determine when to write back to a register (any operation that isn't a branch, jump, or store)
  assign RegWriteEn = ~|{op == `SW, isJ, isJR, isBGEZ, isBGTZ, isBLEZ, isBLTZ, isBNE, isBEQ};

//******************************************************************************
// Memory control
//******************************************************************************

  assign MemWrite = (op == `SW);    // write to memory
  assign MemToReg = (op == `LW);    // use memory data for writing to register

endmodule
