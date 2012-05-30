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
// modified by Yi Gu, 02/26/2005
//******************************************************************************


module MIPS (
	clk, rst,
	display_mode, run_mode, step
);


	input		clk;				// 100 MHz
	input		rst;				// active low reset

	// Mode control
	input		display_mode;		// toggle between debug and run
	input		run_mode;			// whether to step through 1 instruction at a time
	input		step;			// step through 1 instruction

	// Clock signals
	wire			clk_50mhz;		// clock for VGA
	wire 		mipsclk;			// clock for processor (25 MHz)
	wire			memclk;			// clock for BRAM (50 MHz)
	wire			step_pulse;		// one cycle pulse from step button

	// IF input
	wire 		JumpBranch;		// use the branch offset for next pc
	wire	  		JumpTarget;		// use the target field for next pc
	wire	  		JumpReg;			// use data in Rs for next pc
	
	// IF output
	wire [31:0]	instr;			// current instruction
	wire [31:0]	pc;				// current pc
	
	// Regfile input
	wire [31:0]	RegWriteData;		// data to be written to register file
	wire [4:0] 	RegWriteAddr;		// address of register to be written to
	wire 	 	RegWriteEn;		// whether to write to a register
	
	// Regfile output
	wire [31:0]	RsData;
	wire [31:0]	RtData;

	// ALU input
	wire [31:0]	ALUOpX, ALUOpY;	// ALU operands
	wire [3:0]	ALUOp;			// ALU operation to perform
	
	// ALU output
	wire ALUZero, ALUNeg;	// whether ALU result is 0 or negative
	wire [31:0]	ALUResult;		// ALU result

	// Data memory interface
	wire			MemRead;
	wire			MemWrite;
        wire                    MemToReg;
	wire			VgaWE;			// whether to write to VGA interface
	wire [31:0]	SegaData;			// data from Sega gamepad
	wire			stall;			// Stalls the processor
	wire			mainmem_access;	// Main memory access request
	wire			read_block;		// Indicator to main memory if read block size is 1 or 4
	wire			start_read;		// Indicate to cache to start reading
	wire	[31:0]	dram_data;
	wire 		dram_busy;
	wire [18:0] 	total_cycles;
	wire [18:0] 	total_instr;
 	wire [18:0] 	total_writes;
	wire [18:0] 	total_reads;

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
		.clken((run_mode | step_pulse) & ~stall),
		.rst(~rst),
		.JumpBranch(JumpBranch), 
		.JumpTarget(JumpTarget),
		.JumpReg(JumpReg),
		.RsData(RsData),
		.dram_busy(dram_busy)
	);

//******************************************************************************
// Instruction Decode unit
//******************************************************************************
	Decode Decode(
		// Outputs
   		.JumpBranch		(JumpBranch), 
		.JumpTarget 		(JumpTarget),
		.JumpReg			(JumpReg),
		.ALUOp			(ALUOp),
		.ALUOpX			(ALUOpX),
		.ALUOpY			(ALUOpY),
		.MemToReg			(MemToReg),
		.MemWrite			(MemWrite),
		.MemRead			(MemRead),
		.RegWriteAddr		(RegWriteAddr),
		.RegWriteEn		(RegWriteEn),
	
		// Inputs
		.instr			(instr),
		.pc				(pc),
		.RsData			(RsData),
		.RtData			(RtData),
		.ALUZero			(ALUZero),
		.ALUNeg			(ALUNeg)
	);

//******************************************************************************
// Register File
//******************************************************************************

	`define	rs			25:21	// 5-bit source register specifier
	`define	rt			20:16	// 5-bit source/dest register specifier

	RegFile RegFile (
		// Outputs
		.RsData			(RsData),
		.RtData			(RtData),

		// Inputs
		.clk				(mipsclk),
		.clken((run_mode | step_pulse) & ~stall),
		.RegWriteData		(RegWriteData),
		.RegWriteAddr		(RegWriteAddr),
		.RegWriteEn		(RegWriteEn),
		.RsAddr			(instr[`rs]),
		.RtAddr			(instr[`rt])
	);

//******************************************************************************
// ALU (Execution Unit)
//******************************************************************************

	ALU ALU (
		// Outputs
		.ALUResult		(ALUResult),
		.ALUZero			(ALUZero),
		.ALUNeg			(ALUNeg),
		
		// Inputs
		.ALUOp			(ALUOp),
		.ALUOpX			(ALUOpX),
		.ALUOpY			(ALUOpY)
	);

//******************************************************************************
// Interface with Data Memory
//******************************************************************************

	MemStage MemStage (
		// Outputs
		.VgaWE			(VgaWE),
		.RegWriteData		(RegWriteData),
		.stall			(stall),
		.mainmem_access	(mainmem_access),
		.total_cycles		(total_cycles),
		.total_instr		(total_instr),
 		.total_writes		(total_writes),
		.total_reads		(total_reads),

		// Inputs
		.clk				(clk_50mhz),
		.memclk			(memclk),
		.mipsclk			(mipsclk),
		.instr			(instr),
		.pc				(pc),
		.MemToReg			(MemToReg),
		.MemRead			(MemRead),
		.MemWrite			(MemWrite),
		.ALUResult		(ALUResult),
		.RtData			(RtData),
		.SegaData			(SegaData),
		.dram_data		(dram_data),
		.dram_busy		(dram_busy),
		.start_read		(start_read),
		.counter_en		((run_mode || step_pulse)),
		.reset			(~rst)
	);

//******************************************************************************
// Clock generator
//******************************************************************************

	CLKgen  CLKgen (
		// Outputs
		.mipsclk			(mipsclk),
		.memclk			(memclk),
		.step_pulse		(step_pulse),
		.clk_out			(clk_50mhz),
				
		// Inputs
		.clk				(clk), 
		.rst				(~rst),
		.step			(~step)
	);


//******************************************************************************
// BRAM Controller
//******************************************************************************
	wire	  VgaAddr;

	assign VgaAddr = (ALUResult[7:0] == 8'hff);	// store data to VGA	

	MainMem_ctl MainMem_ctl(										 
		// Outputs
		.dout				(dram_data),
		.busy				(dram_busy),	
		.start_read			(start_read),
	
		// Inputs		
		.clk 				(memclk),  
		.reset				(~rst),
		.access				(mainmem_access),
		.write				(MemWrite & ~VgaAddr),
		.din					(RtData),
		.addr				(ALUResult)
	);

endmodule
