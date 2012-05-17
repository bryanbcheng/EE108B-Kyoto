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
// modified by Yi Gu, 5/16/05
//
//******************************************************************************

module Decode(   
  // Outputs
  JumpBranch, JumpTarget, JumpReg, Stall, ALUOp, ALUOpX, ALUOpY, MemWrite, MemToReg,
  RegWriteEn, RegWriteAddr, MemWriteData,
  
  // Inputs
  instr, RsDataIn, RtDataIn, pc, 

  // Forwarding
  RegWriteAddr_ex, RegWriteAddr_mem, RegWriteEn_ex, RegWriteEn_mem, RegWriteData_ex, RegWriteData_mem,

  // Stalling
  MemToReg_ex // ,
);

  // current instruction data
  input [31:0] instr;
  input [31:0] pc;
  input [31:0] RsDataIn, RtDataIn;

  // register writeback data	
  output [4:0] RegWriteAddr;		// which register to store pc in
  output wire RegWriteEn;
  
  // stall logic
  output wire Stall;
  
  // memory control
  output MemToReg;              // use memory output as data to write into register
  output MemWrite;              // write to memory
  output [31:0] MemWriteData;   // memory write data
  
  // next instruction select
  output JumpBranch;        // branch taken, address offset specified in instruction
  output JumpTarget;        // jump address specified in instruction
  output JumpReg;           // jump address specified in register
  
  // ALU control and data
  output [3:0] ALUOp;			// ALU operation select
  output [31:0] ALUOpX, ALUOpY;	// ALU operands

  // forwarding
  input [4:0] RegWriteAddr_ex;
  input [4:0] RegWriteAddr_mem;
  input RegWriteEn_ex;
  input RegWriteEn_mem;
  input [31:0] RegWriteData_ex;
  input [31:0] RegWriteData_mem;

  // stalling
  input MemToReg_ex;

//******************************************************************************
// instruction field
//******************************************************************************

  `define opfield   31:26   // 6-bit operation code
  `define rs        25:21   // 5-bit source register specifier
  `define rt        20:16   // 5-bit source/dest register specifier 
  `define immediate 15:0    // 16-bit immediate, branch or address disp
  `define rd        15:11   // 5-bit destination register specifier
  `define safield   10:6    // 5-bit shift amount
  `define function  5:0     // 6-bit function field
  
  wire [5:0] op = instr[`opfield];
  wire [4:0] sa = instr[`safield];
  wire [4:0] RtAddr = instr[`rt];
  wire [4:0] RdAddr = instr[`rd];
  wire [4:0] RsAddr = instr[`rs];
  wire [5:0] funct = instr[`function];
  wire [15:0] immediate = instr[`immediate];

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
  
  wire isBEQ = (op == `BEQ);
  wire isBGEZ = (op == `BLTZ_GEZ) && (RtAddr == `BGEZ);
  wire isBGTZ = (op == `BGTZ) && (RtAddr == 5'b00000);
  wire isBLEZ = (op == `BLEZ) && (RtAddr == 5'b00000);
  wire isBLTZ = (op == `BLTZ_GEZ) && (RtAddr == `BLTZ);
  wire isBNE = (op == `BNE);
  
  wire isBranch = isBEQ | isBGEZ | isBGTZ | isBLEZ | isBLTZ | isBNE;
	

//******************************************************************************
// jump instructions decode
//******************************************************************************
	
  `define SPECIAL 6'b000000
  `define J       6'b000010
  `define JAL     6'b000011
  `define JR      6'b001000
  `define JALR    6'b001001
  
  wire isJ    = (op == `J);
  wire isJAL  = (op == `JAL);
  wire isJALR = (op == `SPECIAL) && (funct == `JALR);  
  wire isJR   = (op == `SPECIAL) && (funct == `JR);
  
  wire isLink = isJALR | isJAL;

//******************************************************************************
// shift instruction decode
//******************************************************************************
  
  `define SLL  6'b000000
  `define SRL  6'b000010
  `define SRA  6'b000011
  `define SLLV 6'b000100
  `define SRLV 6'b000110
  `define SRAV 6'b000111
  
  wire isSLL = (op == `SPECIAL) & (funct == `SLL);
  wire isSRA = (op == `SPECIAL) & (funct == `SRA);
  wire isSRL = (op == `SPECIAL) & (funct == `SRL);
  wire isSLLV	= (op == `SPECIAL) & (funct == `SLLV);
  wire isSRAV	= (op == `SPECIAL) & (funct == `SRAV);
  wire isSRLV	= (op == `SPECIAL) & (funct == `SRLV);
  
  wire isShiftImm = isSLL | isSRA | isSRL;
  wire isShift = isShiftImm | isSLLV | isSRAV | isSRLV;
  	
//******************************************************************************
// ALU instructions decode / control signal for ALU datapath
//******************************************************************************
  
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
  
  `define select_alu_addu  4'd0
  `define select_alu_and   4'd1
  `define select_alu_xor   4'd2
  `define select_alu_or    4'd3
  `define select_alu_nor   4'd4
  `define select_alu_subu  4'd5
  `define select_alu_sltu  4'd6
  `define select_alu_slt   4'd7
  `define select_alu_srl   4'd8
  `define select_alu_sra   4'd9
  `define select_alu_sll   4'd10
  `define select_alu_passa 4'd11
  `define select_alu_passb 4'd12
  `define select_alu_add   4'd13
  `define select_alu_sub   4'd14
  
  `define dc6 6'bxxxxxx
  
  reg [3:0] ALUOp;
  
  always @(op or funct) begin
    casex({op, funct})
      {`SPECIAL, `ADD}:  ALUOp = `select_alu_add;
      {`SPECIAL, `ADDU}: ALUOp = `select_alu_addu;
      {`SPECIAL, `SUB}:  ALUOp = `select_alu_sub;
      {`SPECIAL, `SUBU}: ALUOp = `select_alu_subu;
      {`SPECIAL, `SLT}:  ALUOp = `select_alu_slt;
      {`SPECIAL, `SLTU}: ALUOp = `select_alu_sltu;
      {`SPECIAL, `AND}:  ALUOp = `select_alu_and;
      {`SPECIAL, `OR}:   ALUOp = `select_alu_or;
      {`SPECIAL, `XOR}:  ALUOp = `select_alu_xor;
      {`SPECIAL, `NOR}:  ALUOp = `select_alu_nor;
      {`SPECIAL, `SRL}:  ALUOp = `select_alu_srl;
      {`SPECIAL, `SRA}:  ALUOp = `select_alu_sra;
      {`SPECIAL, `SLL}:  ALUOp = `select_alu_sll;
      {`SPECIAL, `SRLV}: ALUOp = `select_alu_srl;
      {`SPECIAL, `SRAV}: ALUOp = `select_alu_sra;
      {`SPECIAL, `SLLV}: ALUOp = `select_alu_sll;
    
      {`ADDI, `dc6}:     ALUOp = `select_alu_add;
      {`ADDIU, `dc6}:    ALUOp = `select_alu_addu;
      {`SLTI, `dc6}:     ALUOp = `select_alu_slt;
      {`SLTIU, `dc6}:    ALUOp = `select_alu_sltu;
      {`ANDI, `dc6}:     ALUOp = `select_alu_and;
      {`ORI, `dc6}:      ALUOp = `select_alu_or;
      {`XORI, `dc6}:     ALUOp = `select_alu_xor;
      
      {`BEQ, `dc6}:      ALUOp = `select_alu_subu;
      {`BNE, `dc6}:      ALUOp = `select_alu_subu;
      {`BLTZ_GEZ, `dc6}: ALUOp = `select_alu_passa;
      {`BLEZ, `dc6}:     ALUOp = `select_alu_passa;
      {`BGTZ, `dc6}:     ALUOp = `select_alu_passa;
    
      {`J, `dc6}:        ALUOp = `select_alu_passa;
      {`SPECIAL, `JR}:   ALUOp = `select_alu_passa;
      {`JAL, `dc6}:      ALUOp = `select_alu_passb;
      {`SPECIAL, `JALR}: ALUOp = `select_alu_passb;
    
      {`LUI, `dc6}:      ALUOp = `select_alu_passb;
    
      {`LW, `dc6}:       ALUOp = `select_alu_addu;
      {`SW, `dc6}:       ALUOp = `select_alu_addu;
    
      default:           ALUOp = `select_alu_passa;
    endcase
  end

//******************************************************************************
// Compute value for 32 bit immediate data
//******************************************************************************
  reg [31:0] Imm;
  wire isImm;
  
  wire [31:0] sign_extend_imm = {{16{immediate[15]}}, immediate[15:0]};
  wire [31:0] zero_extend_imm = {16'b0, immediate[15:0]};
  
  always @(op or immediate) begin
    casex(op)
      // Sign extend for memory access operations
      `LW:     Imm = sign_extend_imm;                 
      `SW:     Imm = sign_extend_imm;
      
      // ALU Operations that sign extend immediate
      `ADDI:   Imm = sign_extend_imm;                 
      `ADDIU:  Imm = sign_extend_imm;
      `SLTI:   Imm = sign_extend_imm;
      
      // ALU Operations that zero extend immediate
      `ANDI:   Imm = zero_extend_imm;                                
      `ORI:    Imm = zero_extend_imm;
      `XORI:   Imm = zero_extend_imm;
      `SLTIU:  Imm = zero_extend_imm;
      
      // LUI fills low order bits with zeros
      `LUI:    Imm = {immediate[15:0], 16'b0};                                
      
      default: Imm = 32'b0;
    endcase
  end
  
  assign isImm = op != `SPECIAL;

//******************************************************************************
// PUT YOUR FORWARDING AND STALLING LOGIC HERE
//******************************************************************************

  reg [31:0] RsData, RtData;

  always @* begin
    if (RegWriteEn_ex && RegWriteAddr_ex != 5'b0 && RegWriteAddr_ex == RsAddr) begin
      RsData = RegWriteData_ex;
    end else if (RegWriteEn_mem && RegWriteAddr_mem != 5'b0 && RegWriteAddr_mem == RsAddr) begin
      RsData = RegWriteData_mem;
    end else begin
      RsData = RsDataIn;
    end

    if (RegWriteEn_ex && RegWriteAddr_ex != 5'b0 && RegWriteAddr_ex == RtAddr) begin
      RtData = RegWriteData_ex;
    end	else if	(RegWriteEn_mem && RegWriteAddr_mem != 5'b0 && RegWriteAddr_mem == RtAddr) begin
      RtData = RegWriteData_mem;
    end else begin
      RtData = RtDataIn;
    end
    
    // set RsData and RtData here according to forwarding rules
//    RsData = RsDataIn; // this assumes no forwarding
//    RtData = RtDataIn;
  end

  // assign the Stall signal according to the rules you determine
  // you should avoid stalling when it is not necessary (this is nontrivial)
  //assign Stall = 1'b0; // this assumes no stalling

  assign Stall = MemToReg_ex && (RegWriteAddr_ex == RsAddr || RegWriteAddr_ex == RtAddr);

  assign MemWriteData = RtData; // we may write forwarded data to memory



//******************************************************************************
// Determine ALU inputs and register writeback address
//******************************************************************************

  reg [31:0] ALUOpX, ALUOpY;
  reg [4:0] RegWriteAddr;
  
  always @(RsData or sa or isShift or isShiftImm) begin
    if (isShift)
      ALUOpX = {27'b0, (isShiftImm) ? sa : RsData[4:0]};
    else
      ALUOpX = RsData;
  end
  
  always @(isLink or pc or isJALR or RdAddr or isImm or Imm or RtData or RtAddr) begin
    if (isLink) begin
      ALUOpY = pc + 3'h4;
      RegWriteAddr = (isJALR) ? RdAddr : 5'b11111;
    end else if (isImm) begin
      ALUOpY = Imm;
      RegWriteAddr = RtAddr;
    end else begin
      ALUOpY = RtData;
      RegWriteAddr = RdAddr;
    end
  end
  
  assign RegWriteEn = ~((op == `SW) | isJ | isJR | isBranch);

//******************************************************************************
// Next instruction select
//******************************************************************************
  
  wire isEqual = (RsData == RtData);
  wire isZero = (RsData == 32'b0);
  wire isNeg = RsData[31];
  wire isPos = ~(isZero | isNeg);
  
  assign JumpBranch = |{isBEQ & isEqual, isBNE & ~isEqual, isBGEZ & ~isNeg, isBGTZ & isPos, isBLEZ & ~isPos, isBLTZ & isNeg};

  assign JumpTarget = isJ | isJAL;
  assign JumpReg = isJALR | isJR;

//******************************************************************************
// Memory control
//******************************************************************************

  assign MemWrite = (op == `SW);		// write to memory
  assign MemToReg = (op == `LW);		// use memory data for writing to register

endmodule
