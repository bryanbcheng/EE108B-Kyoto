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
// modified by Yi Gu & Nicolas Kokkalis, 2/28/05
//
//******************************************************************************

module MemStage (
	// Outputs
	VgaWE,
	RegWriteData,
	stall,
	mainmem_access,

	// Inputs
	clk,
	memclk,
	mipsclk,
	instr,
	pc,
	MemToReg,
	MemRead,
	MemWrite,
	ALUResult,
	RtData,
	SegaData,
	dram_data,
	dram_busy,
	start_read,
	counter_en,
	reset,
	total_cycles,
	total_instr,
 	total_writes,
	total_reads
);

	input		clk;
	input		memclk;
	input		mipsclk;
	input [31:0]	instr;
	input [31:0]	pc;
	input		MemToReg;		// Register writeback data: 1 for memory load result, 0 for ALU result
	input		MemRead;		// Read operation
	input		MemWrite;		// Store operation: enable writing to memory
	input [31:0]	ALUResult;	// Output of ALU, memory address for load/store ops
	input [31:0]	RtData;		// Data for store instructions
	input [31:0]	SegaData;		// Data from Sega gamepad
	input [31:0]	dram_data;	// Data from BRAM
	input		dram_busy;	// BRAM busy signal
	input		start_read;	// Indicate to cache to start reading
	input		counter_en;	// Counter enable for performance counter
	input		reset;		// Reset from top-level

	output		VgaWE;		// store data to VGA instead of data memory
	output [31:0]	RegWriteData;	// Data to be written to register
	output		stall;		// Stall pc
	output		mainmem_access;// Access main memory
   	
	// Performance counters
	output [18:0] 	total_cycles;
	output [18:0] 	total_instr;
 	output [18:0] 	total_writes;
	output [18:0] 	total_reads;

	wire	   cache_busy;
	wire	   [31:0] MemDataOut;
	reg			stall_write;
	reg			stall_read;

//******************************************************************************
// control for memory-mapped I/O--
//******************************************************************************
	wire			VgaAddr, SegaAddr;			// memory-mapped I/O addresses
	
	assign VgaAddr = (ALUResult[7:0] == 8'hff);	// store data to VGA
	assign VgaWE = MemWrite & VgaAddr;
	
	assign SegaAddr = (ALUResult[7:0] == 8'hfd);	// load data from Sega gamepad

//******************************************************************************
// determine what data to write to register
//******************************************************************************
	reg [31:0]		RegWriteData;
	
	always @ (ALUResult or MemDataOut or SegaData or MemToReg or SegaAddr) begin
		if (MemToReg) begin
			if (SegaAddr)
				RegWriteData = SegaData;
			else
				RegWriteData = MemDataOut;
		end else
			RegWriteData = ALUResult;
	end

//******************************************************************************
// Data Cache Implementation below
//******************************************************************************

Cache Cache(
		//Inputs
		.rst(reset),			// reset
		.clk(memclk),			// memclk
		.addr(ALUResult), 		// read/write address
		.dram_data(dram_data), 	// data returned from main memory
		.reg_data(RtData),		// register data to be written to cache
		.re(MemRead & ~SegaAddr),// read indicate
		.we(MemWrite & ~VgaAddr),// write indicate
		.mainmem_busy(dram_busy),// main memory busy signal

		//Outfputs
		.dout(MemDataOut), 		// data retrieved from cache
		.cache_busy(cache_busy),	// cache busy signal
		.mainmem_access(mainmem_access)
);

//******************************************************************************
// FSM to implement stall signal control
//******************************************************************************
	reg state_write;
	reg [2:0] state_read;
	reg [31:0] pc_delayed;
	reg new_instr;
	wire [31:0] pc_delay_memclk;

	dff #32 dff_pc_delay_memclk(.d(pc), .clk(memclk), .q(pc_delay_memclk));
	
	assign stall = ((instr[31:26] == 6'h2b) && stall_write) || ((instr[31:26] == 6'h23) && stall_read);

	// The stall signal is set high whenever MemWrite or cache_busy
	// are set high and is set low when cache_busy goes low
	always @ (pc_delay_memclk or cache_busy or reset)
		case ({reset, state_write})
			2'b00: begin
				state_write <= ((instr[31:26] == 6'h2b) | cache_busy)? 1'b1:1'b0;
				stall_write <= ((instr[31:26] == 6'h2b) | cache_busy)? 1'b1:1'b0;
			end
			2'b01: begin
				state_write <= cache_busy? 1'b1:1'b0;
				stall_write <= cache_busy? 1'b1:1'b0;
			end
			default: begin
				state_write <= 1'b0;
				stall_write <= 1'b0;
			end
		endcase
	
	// The stall signal is set high whenever MemRead or cache_busy
	// are set high and is set low when cache_busy goes low or when
	// cache_busy stays low after one memclk cycle after MemRead
	// goes high
	always @ (posedge clk)
		case	({reset, state_read})
			4'b0000: begin
				state_read = MemRead ? 3'b001:3'b000;
				stall_read = MemRead ? 1'b1:1'b0;
			end
			4'b0001: state_read = 3'b010;
			4'b0010: state_read = 3'b011;
			4'b0011: state_read = 3'b100;
			4'b0100: begin
				state_read = cache_busy ? 3'b100:3'b101;
				stall_read = cache_busy ? 1'b1:1'b0;
			end
			4'b0101: state_read = new_instr ? 3'b000:3'b101;
			default: begin
				state_read = 3'b000;
				stall_read = 1'b0;
			end
		endcase

	always @ (posedge clk) begin
		pc_delayed <= pc;
		new_instr <= ~(pc == pc_delayed);
	end

//******************************************************************************
// Performance Counters
//******************************************************************************
	//wire write_count_en;
	//wire read_count_en;

	//assign counter_en = ~(ALUResult[7:0] == 8'hfe);

	//Total Cycles counter
	counter_ar #(19) total_cyc_counter(.clk(mipsclk), .rst(reset), .en(counter_en), .count(total_cycles));

	// Total Instructions Counter
	counter_ar #(19) total_instr_counter(.clk(new_instr), .rst(reset), .en(1'b1), .count(total_instr));

	// Writes Counters (here are 2 possibilities, you are free to do whatever works)
	//one_pulse pulse_writes (.clk(mipsclk), .in(MemWrite & ~VgaAddr & counter_en & ~stall), .out(write_count_en));
	counter_ar #(19) total_wr_counter(.clk(new_instr && MemWrite), .rst(reset), .en(1'b1), .count(total_writes));

 	// Reads Counter (here are 2 possibilities, you are free to do whatever works)
	//one_pulse pulse_reads (.clk(mipsclk), .in(MemToReg & ~SegaAddr & counter_en & ~stall), .out(read_count_en));
	counter_ar #(19) total_rd_counter(.clk(new_instr && MemRead), .rst(reset), .en(1'b1), .count(total_reads));

endmodule
