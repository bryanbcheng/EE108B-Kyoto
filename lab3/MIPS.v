//******************************************************************************
// EE108b MIPS verilog model
//
// MIPS.v
//
// top-level verilog module for MIPS simulation
//
// verilog written by Daniel L. Rosenband, MIT 10/4/99
// modified by John Kim, 3/26/03
// modified by Neil Achtman, 8/15/03
//
//******************************************************************************


module MIPS (
  clk, rst,
  run_mode, step
);

  input clk;				// 50 MHz
  input rst;				// active low reset

  input run_mode;                       // whether to step through 1 stage at a time
  input step;                           // step through 1 stage
  
  // Clock signals
  wire clk_50mhz;                       // 50 MHz clock
  wire mipsclk, memclk;                 // clock for processor, memory
  wire step_pulse;                      // one cycle pulse from step button
  
  // Instruction and PC
  wire [31:0] instr_if, instr_id;
  wire [31:0] pc_if, pc_id;
  
  // Control
  wire JumpBranch_id, JumpTarget_id, JumpReg_id;
  wire MemToReg_id, MemToReg_ex, MemToReg_mem;
  wire MemWrite_id, MemWrite_ex, MemWrite_mem;
  wire [3:0] ALUOp_id, ALUOp_ex;
  wire SegaAddr_mem, VgaAddr_mem, VgaWE_mem;
  	
  // Register writeback
  wire [4:0] RegWriteAddr_id, RegWriteAddr_ex, RegWriteAddr_mem, RegWriteAddr_wb;
  wire RegWriteEn_id, RegWriteEn_ex, RegWriteEn_mem, RegWriteEn_wb;
  
  // Datapath
  wire [31:0] RsData_id, RtData_id, RtData_ex, RtData_mem;         // register read
  wire [31:0] ALUOpX_id, ALUOpY_id, ALUOpX_ex, ALUOpY_ex;          // ALU operands
  wire [31:0] ALUResult_ex, ALUResult_mem;                         // ALU result
  wire [31:0] MemWriteData_id, MemWriteData_ex, MemWriteData_mem;  // memory write
  wire [31:0] RegWriteData_mem, RegWriteData_wb;                   // register write
  wire [31:0] SegaData_mem;                                        // Sega read
  
  // Pipeline control
  // You will need to make assignments to the following signals, determining
  // when each stage should be enabled or reset. Pressing the reset button
  // should reset all of the stages.
  
  wire en_if, en_id, en_ex, en_mem, en_wb;
  wire res_if, res_id, res_ex, res_mem, res_wb;	// remember that reset button is active low

  wire stall; // stall pipeline, set in Decode
  
//******************************************************************************
// IF stage
//******************************************************************************
  assign en_if = ~stall & (run_mode | step_pulse);
  assign res_if = ~rst;
  
  IF IF (
    // Outputs
    .pc_out(pc_if),
    .instr_out(instr_if),        
    
    // Inputs
    .clk(memclk),
    .mipsclk(mipsclk),
    .rst(res_if),
    .en(en_if),
    .JumpBranch(JumpBranch_id), 
    .JumpTarget(JumpTarget_id),
    .JumpReg(JumpReg_id),
    .instr_in(instr_id),
    .pc_in(pc_id),
    .RsData(ALUOpX_id)
  );

//******************************************************************************
// IF -> ID
//******************************************************************************
  assign en_id = ~stall & (run_mode | step_pulse);
  assign res_id = ~rst;
  
  // need until ID stage
  dffar #(32) instr_if2id (.clk(mipsclk), .en(en_id), .r(res_id), .d(instr_if), .q(instr_id));
  dffar #(32) pc_if2id (.clk(mipsclk), .en(en_id), .r(res_id), .d(pc_if), .q(pc_id));

//******************************************************************************
// ID stage
//******************************************************************************

  // You may add inputs and outputs to the Decode and Regfile modules in order
  // to implement forwarding. Branches should be resolved in this stage, and all
  // data should be forwarded to this stage. The only things you should need to
  // modify are these two modules.

  Decode Decode(
    // Outputs
    .JumpBranch(JumpBranch_id), 
    .JumpTarget(JumpTarget_id),
    .JumpReg(JumpReg_id),
    .ALUOp(ALUOp_id),
    .ALUOpX(ALUOpX_id),
    .ALUOpY(ALUOpY_id),
    .MemToReg(MemToReg_id),
    .MemWrite(MemWrite_id),
    .MemWriteData(MemWriteData_id),
    .RegWriteAddr(RegWriteAddr_id),
    .RegWriteEn(RegWriteEn_id),
    .Stall(stall),
    
    // Inputs
    .instr(instr_id),
    .pc(pc_id),
    .RsDataIn(RsData_id),
    .RtDataIn(RtData_id),

    // Forwarding
    .RegWriteAddr_ex(RegWriteAddr_ex),
    .RegWriteAddr_mem(RegWriteAddr_mem),
    .RegWriteEn_ex(RegWriteEn_ex),
    .RegWriteEn_mem(RegWriteEn_mem),
    .RegWriteData_ex(ALUResult_ex),
    .RegWriteData_mem(RegWriteData_mem),

    // Stalling
    .MemToReg_ex(MemTo_Reg_ex)    
  );
  
  `define rs 25:21	// 5-bit source register specifier
  `define rt 20:16	// 5-bit source/dest register specifier
  
  RegFile RegFile (
    // Outputs
    .RsData(RsData_id),
    .RtData(RtData_id),
  
    // Inputs
    .clk(mipsclk),
    .RegWriteData(RegWriteData_wb),
    .RegWriteAddr(RegWriteAddr_wb),
    .RegWriteEn(RegWriteEn_wb),
    .RsAddr(instr_id[`rs]),
    .RtAddr(instr_id[`rt])
  );

//******************************************************************************
// ID -> EX
//******************************************************************************
  assign en_ex = run_mode | step_pulse;
  assign res_ex = (stall & (run_mode | step_pulse)) | ~rst;
  
  // need until EX stage
  dffar #(32) ALUOpX_id2ex (.clk(mipsclk), .en(en_ex), .r(res_ex), .d(ALUOpX_id), .q(ALUOpX_ex));
  dffar #(32) ALUOpY_id2ex (.clk(mipsclk), .en(en_ex), .r(res_ex), .d(ALUOpY_id), .q(ALUOpY_ex));
  dffar #(4) ALUOp_id2ex (.clk(mipsclk), .en(en_ex), .r(res_ex), .d(ALUOp_id), .q(ALUOp_ex));
  
  // need until MEM stage
  dffar #(32) MemWriteData_id2ex (.clk(mipsclk), .en(en_ex), .r(res_ex), .d(MemWriteData_id), .q(MemWriteData_ex));
  dffar MemToReg_id2ex (.clk(mipsclk), .en(en_ex), .r(res_ex), .d(MemToReg_id), .q(MemToReg_ex));
  dffar MemWrite_id2ex (.clk(mipsclk), .en(en_ex), .r(res_ex), .d(MemWrite_id), .q(MemWrite_ex));
  
  // need until WB stage
  dffar #(5) RegWriteAddr_id2ex (.clk(mipsclk), .en(en_ex), .r(res_ex), .d(RegWriteAddr_id), .q(RegWriteAddr_ex));
  dffar RegWriteEn_id2ex (.clk(mipsclk), .en(en_ex), .r(res_ex), .d(RegWriteEn_id), .q(RegWriteEn_ex));

//******************************************************************************
// EX stage
//******************************************************************************

  ALU ALU (
    // Outputs
    .ALUResult(ALUResult_ex),
    
    // Inputs
    .ALUOp(ALUOp_ex),
    .ALUOpX(ALUOpX_ex),
    .ALUOpY(ALUOpY_ex)
  );

//******************************************************************************
// EX -> MEM
//******************************************************************************
  assign en_mem = run_mode | step_pulse;
  assign res_mem = ~rst;
  
  // need until MEM stage
  dffar #(32) MemWriteData_ex2mem (.clk(mipsclk), .en(en_mem), .r(res_mem), .d(MemWriteData_ex), .q(MemWriteData_mem));
  dffar #(32) ALUResult_ex2mem (.clk(mipsclk), .en(en_mem), .r(res_mem), .d(ALUResult_ex), .q(ALUResult_mem));
  dffar MemToReg_ex2mem (.clk(mipsclk), .en(en_mem), .r(res_mem), .d(MemToReg_ex), .q(MemToReg_mem));
  dffar MemWrite_ex2mem (.clk(mipsclk), .en(en_mem), .r(res_mem), .d(MemWrite_ex), .q(MemWrite_mem));
  
  // need until WB stage
  dffar #(5) RegWriteAddr_ex2mem (.clk(mipsclk), .en(en_mem), .r(res_mem), .d(RegWriteAddr_ex), .q(RegWriteAddr_mem));
  dffar RegWriteEn_ex2mem (.clk(mipsclk), .en(en_mem), .r(res_mem), .d(RegWriteEn_ex), .q(RegWriteEn_mem));

//******************************************************************************
// MEM stage
//******************************************************************************

  MemStage memstage (
    // Outputs
    .VgaWE(VgaWE_mem),
    .RegWriteData(RegWriteData_mem),
    
    // Inputs
    .clk(memclk),
    .MemToReg(MemToReg_mem),
    .MemWrite(MemWrite_mem),
    .ALUResult(ALUResult_mem),
    .MemWriteData(MemWriteData_mem),
    .SegaData(SegaData_mem)
  );

//******************************************************************************
// MEM -> WB
//******************************************************************************
  assign en_wb = run_mode | step_pulse;
  assign res_wb = ~rst;
  
  // need until WB stage
  dffar #(32) RegWriteData_mem2wb (.clk(mipsclk), .en(en_wb), .r(res_wb), .d(RegWriteData_mem), .q(RegWriteData_wb));
  dffar #(5) RegWriteAddr_mem2wb (.clk(mipsclk), .en(en_wb), .r(res_wb), .d(RegWriteAddr_mem), .q(RegWriteAddr_wb));
  dffar RegWriteEn_mem2wb (.clk(mipsclk), .en(en_wb), .r(res_wb), .d(RegWriteEn_mem), .q(RegWriteEn_wb));

//******************************************************************************
// WB stage
//******************************************************************************

  // WB stage consists of write port from register file

//******************************************************************************
// Clock generator
//******************************************************************************

  CLKgen  CLKgen (
    // Outputs
    .mipsclk(mipsclk),
    .memclk(memclk),
    .step_pulse(step_pulse),
    .clk_out(clk_50mhz),
    
    // Inputs
    .clk_in(clk), 
    .rst(~rst),
    .step(step)
  );

endmodule
