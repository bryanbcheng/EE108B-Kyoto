//******************************************************************************
// EE108b MIPS verilog model
//
// Decode.v
//
// - Decodes the instructions
// - branch instruction condition are also determined and whether
//   the branch PC should be used 
// - ALU instructions are decoded and sent to the ALU
//
// verilog written by Daniel L. Rosenband, MIT 10/4/99
// modified by John Kim, 3/26/03
// modified by Neil Achtman, 8/15/03
//
//******************************************************************************

module Decode(   
	// Outputs
	RegWriteAddr, JumpBranch, JumpTarget, JumpReg, ALUOp, ALUOpX, ALUOpY, MemRead, MemWrite, MemToReg, RegWriteEn,

	// Inputs
	instr, ALUZero, ALUNeg, RsData, RtData, pc
);

	input [31:0]	instr;			// current instruction
	input [31:0]	pc;				// current pc
	input [31:0]	RsData, RtData;	// data from read registers
	input		ALUZero, ALUNeg;	// whether result of ALU operation is 0 or negative

	output [4:0]	RegWriteAddr;		// which register to write back data to
	output		RegWriteEn;		// enable writing back to the register

	output		MemToReg;			// use memory output as data to write into register
	output		MemRead;			// read from memory
	output		MemWrite;			// write to memory

	output 		JumpBranch;		// branch taken, address offset specified in instruction
	output 		JumpTarget;		// jump address specified in instruction
	output 		JumpReg;			// jump address specified in register

	output [3:0]	ALUOp;			// ALU operation select
	output [31:0]	ALUOpX, ALUOpY;	// ALU operands

//******************************************************************************
// instruction field
//******************************************************************************

	`define	opfield		31:26	// 6-bit operation code
	`define	rs			25:21	// 5-bit source register specifier
	`define	rt			20:16	// 5-bit source/dest register specifier 
	`define	immediate	15:0	// 16-bit immediate, branch or address disp
	`define	rd			15:11	// 5-bit destination register specifier
	`define	safield		10:6	// 5-bit shift amount
	`define	function	5:0		// 6-bit function field

	wire [5:0]		op;
	wire [4:0]		RtAddr, RdAddr, RsAddr;
	wire [4:0]		sa;
	wire [5:0]		funct;
	wire [15:0]		immediate;
   
	assign op			= instr[`opfield];
	assign sa			= instr[`safield];
	assign RtAddr		= instr[`rt];
	assign RdAddr		= instr[`rd];
	assign RsAddr		= instr[`rs];
	assign funct		= instr[`function];
	assign immediate	= instr[`immediate];

//******************************************************************************
// branch instructions decode
//******************************************************************************

	`define BLTZ_GEZ        6'b000001
	`define BEQ             6'b000100
	`define BNE             6'b000101
	`define BLEZ            6'b000110
	`define BGTZ            6'b000111
	`define BLTZ            5'b00000
	`define BGEZ            5'b00001

	wire isBEQ, isBGEZ, isBGTZ, isBLEZ, isBLTZ, isBNE;
	
	assign isBEQ     = (op == `BEQ);
	assign isBGEZ    = (op == `BLTZ_GEZ) && (RtAddr == `BGEZ);
	assign isBGTZ    = (op == `BGTZ) && (RtAddr == 5'b00000);
	assign isBLEZ    = (op == `BLEZ) && (RtAddr == 5'b00000);
	assign isBLTZ    = (op == `BLTZ_GEZ) && (RtAddr == `BLTZ);
	assign isBNE     = (op == `BNE);

	// determine if branch is taken
	assign JumpBranch = (isBEQ & ALUZero) |
					(isBNE & ~ALUZero) |
					(isBGEZ & (ALUZero | ~ALUNeg)) |
					(isBGTZ & ~(ALUZero | ALUNeg)) |
					(isBLEZ & (ALUZero | ALUNeg)) |
					(isBLTZ & (~ALUZero & ALUNeg));

//******************************************************************************
// jump instructions decode
//******************************************************************************
	
	`define SPECIAL         6'b000000
	`define J               6'b000010
	`define JAL             6'b000011
	`define JR              6'b001000
	`define JALR            6'b001001
	
	wire isJ, isJAL, isJALR, isJR;
	wire isLink;

	assign isJ       = (op == `J);
	assign isJAL     = (op == `JAL);
	assign isJALR    = (op == `SPECIAL) && (funct == `JALR);  
	assign isJR      = (op == `SPECIAL) && (funct == `JR);

	assign JumpTarget = (isJ || isJAL);
	assign JumpReg = (isJALR || isJR);

	// determine if the next pc will need to be stored
	assign isLink = isJALR || isJAL;


//******************************************************************************
// shift instruction decode
//******************************************************************************
	
	`define SLL             6'b000000
	`define SRL             6'b000010
	`define SRA             6'b000011
	`define SLLV            6'b000100
	`define SRLV            6'b000110
	`define SRAV            6'b000111
	
	wire isSLL, isSRA, isSRL, isSLLV, isSRAV, isSRLV;
	wire isShiftImm, isShift;

	assign isSLL    = (op == `SPECIAL) && (funct == `SLL);
	assign isSRA    = (op == `SPECIAL) && (funct == `SRA);
	assign isSRL    = (op == `SPECIAL) && (funct == `SRL);
	assign isSLLV	= (op == `SPECIAL) && (funct == `SLLV);
	assign isSRAV	= (op == `SPECIAL) && (funct == `SRAV);
	assign isSRLV	= (op == `SPECIAL) && (funct == `SRLV);
	
	assign isShiftImm = isSLL || isSRA || isSRL;
	assign isShift = isShiftImm || isSLLV || isSRAV || isSRLV;
		
//******************************************************************************
// ALU instructions decode / control signal for ALU datapath
//******************************************************************************
	
	`define ADDI            6'b001000
	`define ADDIU           6'b001001
	`define SLTI            6'b001010
	`define SLTIU           6'b001011
	`define ANDI            6'b001100
	`define ORI             6'b001101
	`define XORI            6'b001110
	`define LUI             6'b001111
	`define LW              6'b100011
	`define SW              6'b101011
	`define ADD             6'b100000
	`define ADDU            6'b100001
	`define SUB             6'b100010
	`define SUBU            6'b100011
	`define AND             6'b100100
	`define OR              6'b100101
	`define XOR             6'b100110
	`define NOR             6'b100111
	`define SLT             6'b101010
	`define SLTU            6'b101011
	
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

	`define	dc6		6'bxxxxxx
	
	reg [3:0] ALUOp;
	
	always @(op or funct) begin
		casex({op, funct})
			{`SPECIAL,	`ADD	}:	ALUOp = `select_alu_add;
			{`SPECIAL,	`ADDU}:	ALUOp = `select_alu_add;
			{`SPECIAL,	`SUB	}:	ALUOp = `select_alu_sub;
			{`SPECIAL,	`SUBU}:	ALUOp = `select_alu_sub;
			{`SPECIAL,	`SLT	}:	ALUOp = `select_alu_slt;
			{`SPECIAL,	`SLTU}:	ALUOp = `select_alu_sltu;
			{`SPECIAL,	`AND	}:	ALUOp = `select_alu_and;
			{`SPECIAL,	`OR	}:	ALUOp = `select_alu_or;
			{`SPECIAL,	`XOR	}:	ALUOp = `select_alu_xor;
			{`SPECIAL,	`NOR	}:	ALUOp = `select_alu_nor;
			{`SPECIAL,	`SRL	}:	ALUOp = `select_alu_srl;
			{`SPECIAL,	`SRA	}:	ALUOp = `select_alu_sra;
			{`SPECIAL,	`SLL	}:	ALUOp = `select_alu_sll;
			{`SPECIAL,	`SRLV}:	ALUOp = `select_alu_srl;
			{`SPECIAL,	`SRAV}:	ALUOp = `select_alu_sra;
			{`SPECIAL,	`SLLV}:	ALUOp = `select_alu_sll;

			{`ADDI,		`dc6	}:	ALUOp = `select_alu_add;
			{`ADDIU,		`dc6	}:	ALUOp = `select_alu_add;
			{`SLTI,		`dc6	}:	ALUOp = `select_alu_slt;
			{`SLTIU,		`dc6	}:	ALUOp = `select_alu_sltu;
			{`ANDI,		`dc6	}:	ALUOp = `select_alu_and;
			{`ORI,		`dc6	}:	ALUOp = `select_alu_or;
			{`XORI,		`dc6	}:	ALUOp = `select_alu_xor;
			
			// compare rs data to 0, only care about 1 operand
			{`BGTZ,		`dc6	}:	ALUOp = `select_alu_passa;
			{`BLEZ,		`dc6	}:	ALUOp = `select_alu_passa;
			{`BLTZ_GEZ,	`dc6	}:	ALUOp = `select_alu_passa;

			// compare rs to rt, find the difference
			{`BNE,		`dc6	}:	ALUOp = `select_alu_sub;
			{`BEQ,		`dc6	}:	ALUOp = `select_alu_sub;

			// pass link address to be stored in $ra
			{`JAL,		`dc6	}:	ALUOp = `select_alu_passb;
			{`SPECIAL,	`JALR}:	ALUOp = `select_alu_passb;

			// or immediate with 0
			{`LUI,		`dc6	}:	ALUOp = `select_alu_or;

			// add rs, offset to get memory address
			{`LW,		`dc6	}:	ALUOp = `select_alu_add;
			{`SW,		`dc6	}:	ALUOp = `select_alu_add;

			default:				ALUOp = `select_alu_passa;
		endcase
	end

//******************************************************************************
// Compute value for 32 bit immediate data
//******************************************************************************
	reg [31:0] Imm;
	
	always @(op or immediate) begin
		casex(op)
			// Sign extend for memory access operations
			`LW     : Imm = {{16{immediate[15]}}, immediate[15:0]};                 
			`SW     : Imm = {{16{immediate[15]}}, immediate[15:0]};

			// ALU Operations that sign extend immediate
			`ADDI   : Imm = {{16{immediate[15]}}, immediate[15:0]};                 
			`ADDIU  : Imm = {{16{immediate[15]}}, immediate[15:0]};
			`SLTI   : Imm = {{16{immediate[15]}}, immediate[15:0]};
			`SLTIU  : Imm = {{16{immediate[15]}}, immediate[15:0]};

			// ALU Operations that zero extend immediate
			`ANDI   : Imm = {16'b0, immediate[15:0]};                                
			`ORI    : Imm = {16'b0, immediate[15:0]};
			`XORI   : Imm = {16'b0, immediate[15:0]};

			// LUI fills low order bits with zeros
			`LUI    : Imm = {immediate[15:0], 16'b0};                                
 
			default : Imm = 32'b0;
		endcase
	end

//******************************************************************************
// Determine ALU inputs and register writeback address
//******************************************************************************
	reg [31:0]	ALUOpX, ALUOpY;
	reg [4:0]		RegWriteAddr;

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
	
	always @(isLink or pc or isJALR or RdAddr or op or isBNE or isBEQ or RtData or Imm or RtAddr) begin
		if (isLink) begin
			ALUOpY = pc + 3'h4;
			RegWriteAddr = (isJALR) ? RdAddr : 5'b11111;
		end else if ((op == `SPECIAL) || isBNE || isBEQ) begin
			ALUOpY = RtData;
			RegWriteAddr = RdAddr;
		end else begin
			ALUOpY = Imm;
			RegWriteAddr = RtAddr;
		end
	end

	// determine when to write back to a register (any operation that isn't a branch, jump, or store)
	
	assign RegWriteEn = ~((op == `SW) || isJ || isJR || isBGEZ ||
					isBGTZ || isBLEZ || isBLTZ || isBNE || isBEQ);
	
//******************************************************************************
// Memory control
//******************************************************************************

	assign MemWrite = (op == `SW);		// write to memory
	assign MemRead = (instr[31:26] == 6'h23);// read from memory
	assign MemToReg = (op == `LW);		// use memory data for writing to register

endmodule