// Custom IROM for testing purposes

`define ADDR_WIDTH 8
`define INSTR_WIDTH 32
`define NUM_INSTR 256

`define BLTZ_GEZ 6'b000001
`define BEQ      6'b000100
`define BNE      6'b000101
`define BLEZ     6'b000110
`define BGTZ     6'b000111
`define BLTZ     5'b00000
`define BGEZ     5'b00001
`define BLTZAL   5'h10
`define BGEZAL   5'h11

`define SPECIAL 6'b000000
`define J       6'b000010
`define JAL     6'b000011
`define JR      6'b001000
`define JALR    6'b001001

`define SLL  6'b000000
`define SRL  6'b000010
`define SRA  6'b000011
`define SLLV 6'b000100
`define SRLV 6'b000110
`define SRAV 6'b000111

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
`define ADD  6'b100000
`define ADDU 6'b100001
`define SUB  6'b100010
`define SUBU 6'b100011
`define AND  6'b100100
`define OR   6'b100101
`define XOR  6'b100110
`define NOR  6'b100111
`define SLT  6'b101010
`define SLTU 6'b101011

// Register names
`define ZERO 5'd0
`define AT   5'd1
`define V0   5'd2
`define V1   5'd3
`define A1   5'd4
`define A2   5'd5
`define A3   5'd6
`define A4   5'd7
`define T0   5'd8
`define T1   5'd9
`define T2   5'd10
`define T3   5'd11
`define T4   5'd12
`define T5   5'd13
`define T6   5'd14
`define T7   5'd15
`define S0   5'd16
`define S1   5'd17
`define S2   5'd18
`define S3   5'd19
`define S4   5'd20
`define S5   5'd21
`define S6   5'd22
`define S7   5'd23
`define T8   5'd24
`define T9   5'd25
`define K0   5'd26
`define K1   5'd27
`define GP   5'd28
`define SP   5'd29
`define FP   5'd30
`define RA   5'd31

`define NULL 5'b0 // same as ZERO, but indicate that it's not used
`define NOOP 32'b0

module irom(clk, addr, dout);
  input clk;
  input [`ADDR_WIDTH-1:0] addr;
  output reg [`INSTR_WIDTH-1:0] dout;

  wire [`INSTR_WIDTH-1:0] memory [`NUM_INSTR-1:0];

  always @(posedge clk)
    dout = memory[addr];

  assign memory[  0] = {`NOOP}; // first instr must be a noop according to handout

  assign memory[  1] = {`ORI, `ZERO, `T0, 16'd4}; // T0 = 4
  assign memory[  2] = {`ORI, `ZERO, `T1, 16'd100}; //T1 = 100

  // store 100 at address 8, then load from this address to test read hits
  // this is a write miss followed by a read hit
  assign memory[  3] = {`SW, `T0, `T1, 16'd4}; // store 100 at address 8
  assign memory[  4] = {`LW,`T0, `T2, 16'd4}; // load it into $t2
  // use an address with the same index but different tag to demonstrate write misses
  // this is a write miss followed by a read miss
  assign memory[  5] = {`ADDI, `T2, `T1, 16'd420}; //make T1 = 520  
  assign memory[  6] = {`SW, `T1, `T0, 16'd0}; //store 4 at address 520 (should store in 2nd cache)
  
  assign memory[  7] = {`ADDI, `ZERO, `T2, 16'd264}; //make T2 = 264  
  assign memory[  8] = {`SW, `T1, `T0, 16'd0}; //store 4 at address 264 (should overwrite cache1)
  

 // loading from address 8 again will incur a read miss because we replaced the entry
  assign memory[  9] = {`ORI, `ZERO, `T0, 16'd8}; //get address 8 of the cache
  assign memory[  10] = {`LW, `T0, `T3, 16'd0}; // load from this address

  // verify that the data we got was correct (i.e., read from memory, not the cache.)
  assign memory[  11] = {`SPECIAL, `T3, `T0, `T4, `NULL, `ADD};

  // now testing what happens when we write hit
  assign memory[ 12] = {`SW, `ZERO, `T4, 16'd8};

  // check 2nd cache still there, address 520 which contains 4
  assign memory[ 13] = {`ORI, `ZERO, `T5, 16'd520};
  assign memory[ 14] = {`LW, `T5, `T2, 16'd0};

  // read word at 264, read miss, and then read hit should replace cache 1 again because 
  // just read from cache 2
  assign memory[ 15] = {`ORI, `ZERO, `T5, 16'd264};
  assign memory[ 16] = {`LW, `T5, `T2, 16'd0};
  assign memory[ 17] = {`LW, `T5, `T3, 16'd0};


  // and read hit on the same address
  assign memory[ 18] = {`NOOP}; 

  // nothing to see here
  assign memory[ 19] = {`NOOP};
  assign memory[ 16] = {`NOOP};
  assign memory[ 17] = {`NOOP};
  assign memory[ 18] = {`NOOP};
  assign memory[ 19] = {`NOOP};
  assign memory[ 20] = {`NOOP};
  assign memory[ 21] = {`NOOP};
  assign memory[ 22] = {`NOOP};
  assign memory[ 23] = {`NOOP};
  assign memory[ 24] = {`NOOP};
  assign memory[ 25] = {`NOOP};
  assign memory[ 26] = {`NOOP};
  assign memory[ 27] = {`NOOP};
  assign memory[ 28] = {`NOOP};
  assign memory[ 29] = {`NOOP};
  assign memory[ 30] = {`NOOP};
  assign memory[ 31] = {`NOOP};
  assign memory[ 32] = {`NOOP};
  assign memory[ 33] = {`NOOP};
  assign memory[ 34] = {`NOOP};
  assign memory[ 35] = {`NOOP};
  assign memory[ 36] = {`NOOP};
  assign memory[ 37] = {`NOOP};
  assign memory[ 38] = {`NOOP};
  assign memory[ 39] = {`NOOP};
  assign memory[ 40] = {`NOOP};
  assign memory[ 41] = {`NOOP};
  assign memory[ 42] = {`NOOP};
  assign memory[ 43] = {`NOOP};
  assign memory[ 44] = {`NOOP};
  assign memory[ 45] = {`NOOP};
  assign memory[ 46] = {`NOOP};
  assign memory[ 47] = {`NOOP};
  assign memory[ 48] = {`NOOP};
  assign memory[ 49] = {`NOOP};
  assign memory[ 50] = {`NOOP};
  assign memory[ 51] = {`NOOP};
  assign memory[ 52] = {`NOOP};
  assign memory[ 53] = {`NOOP};
  assign memory[ 54] = {`NOOP};
  assign memory[ 55] = {`NOOP};
  assign memory[ 56] = {`NOOP};
  assign memory[ 57] = {`NOOP};
  assign memory[ 58] = {`NOOP};
  assign memory[ 59] = {`NOOP};
  assign memory[ 60] = {`NOOP};
  assign memory[ 61] = {`NOOP};
  assign memory[ 62] = {`NOOP};
  assign memory[ 63] = {`NOOP};
  assign memory[ 64] = {`NOOP};
  assign memory[ 65] = {`NOOP};
  assign memory[ 66] = {`NOOP};
  assign memory[ 67] = {`NOOP};
  assign memory[ 68] = {`NOOP};
  assign memory[ 69] = {`NOOP};
  assign memory[ 70] = {`NOOP};
  assign memory[ 71] = {`NOOP};
  assign memory[ 72] = {`NOOP};
  assign memory[ 73] = {`NOOP};
  assign memory[ 74] = {`NOOP};
  assign memory[ 75] = {`NOOP};
  assign memory[ 76] = {`NOOP};
  assign memory[ 77] = {`NOOP};
  assign memory[ 78] = {`NOOP};
  assign memory[ 79] = {`NOOP};
  assign memory[ 80] = {`NOOP};
  assign memory[ 81] = {`NOOP};
  assign memory[ 82] = {`NOOP};
  assign memory[ 83] = {`NOOP};
  assign memory[ 84] = {`NOOP};
  assign memory[ 85] = {`NOOP};
  assign memory[ 86] = {`NOOP};
  assign memory[ 87] = {`NOOP};
  assign memory[ 88] = {`NOOP};
  assign memory[ 89] = {`NOOP};
  assign memory[ 90] = {`NOOP};
  assign memory[ 91] = {`NOOP};
  assign memory[ 92] = {`NOOP};
  assign memory[ 93] = {`NOOP};
  assign memory[ 94] = {`NOOP};
  assign memory[ 95] = {`NOOP};
  assign memory[ 96] = {`NOOP};
  assign memory[ 97] = {`NOOP};
  assign memory[ 98] = {`NOOP};
  assign memory[ 99] = {`NOOP};
  assign memory[100] = {`NOOP};
  assign memory[101] = {`NOOP};
  assign memory[102] = {`NOOP};
  assign memory[103] = {`NOOP};
  assign memory[104] = {`NOOP};
  assign memory[105] = {`NOOP};
  assign memory[106] = {`NOOP};
  assign memory[107] = {`NOOP};
  assign memory[108] = {`NOOP};
  assign memory[109] = {`NOOP};
  assign memory[110] = {`NOOP};
  assign memory[111] = {`NOOP};
  assign memory[112] = {`NOOP};
  assign memory[113] = {`NOOP};
  assign memory[114] = {`NOOP};
  assign memory[115] = {`NOOP};
  assign memory[116] = {`NOOP};
  assign memory[117] = {`NOOP};
  assign memory[118] = {`NOOP};
  assign memory[119] = {`NOOP};
  assign memory[120] = {`NOOP};
  assign memory[121] = {`NOOP};
  assign memory[122] = {`NOOP};
  assign memory[123] = {`NOOP};
  assign memory[124] = {`NOOP};
  assign memory[125] = {`NOOP};
  assign memory[126] = {`NOOP};
  assign memory[127] = {`NOOP};
  assign memory[128] = {`NOOP};
  assign memory[129] = {`NOOP};
  assign memory[130] = {`NOOP};
  assign memory[131] = {`NOOP};
  assign memory[132] = {`NOOP};
  assign memory[133] = {`NOOP};
  assign memory[134] = {`NOOP};
  assign memory[135] = {`NOOP};
  assign memory[136] = {`NOOP};
  assign memory[137] = {`NOOP};
  assign memory[138] = {`NOOP};
  assign memory[139] = {`NOOP};
  assign memory[140] = {`NOOP};
  assign memory[141] = {`NOOP};
  assign memory[142] = {`NOOP};
  assign memory[143] = {`NOOP};
  assign memory[144] = {`NOOP};
  assign memory[145] = {`NOOP};
  assign memory[146] = {`NOOP};
  assign memory[147] = {`NOOP};
  assign memory[148] = {`NOOP};
  assign memory[149] = {`NOOP};
  assign memory[150] = {`NOOP};
  assign memory[151] = {`NOOP};
  assign memory[152] = {`NOOP};
  assign memory[153] = {`NOOP};
  assign memory[154] = {`NOOP};
  assign memory[155] = {`NOOP};
  assign memory[156] = {`NOOP};
  assign memory[157] = {`NOOP};
  assign memory[158] = {`NOOP};
  assign memory[159] = {`NOOP};
  assign memory[160] = {`NOOP};
  assign memory[161] = {`NOOP};
  assign memory[162] = {`NOOP};
  assign memory[163] = {`NOOP};
  assign memory[164] = {`NOOP};
  assign memory[165] = {`NOOP};
  assign memory[166] = {`NOOP};
  assign memory[167] = {`NOOP};
  assign memory[168] = {`NOOP};
  assign memory[169] = {`NOOP};
  assign memory[170] = {`NOOP};
  assign memory[171] = {`NOOP};
  assign memory[172] = {`NOOP};
  assign memory[173] = {`NOOP};
  assign memory[174] = {`NOOP};
  assign memory[175] = {`NOOP};
  assign memory[176] = {`NOOP};
  assign memory[177] = {`NOOP};
  assign memory[178] = {`NOOP};
  assign memory[179] = {`NOOP};
  assign memory[180] = {`NOOP};
  assign memory[181] = {`NOOP};
  assign memory[182] = {`NOOP};
  assign memory[183] = {`NOOP};
  assign memory[184] = {`NOOP};
  assign memory[185] = {`NOOP};
  assign memory[186] = {`NOOP};
  assign memory[187] = {`NOOP};
  assign memory[188] = {`NOOP};
  assign memory[189] = {`NOOP};
  assign memory[190] = {`NOOP};
  assign memory[191] = {`NOOP};
  assign memory[192] = {`NOOP};
  assign memory[193] = {`NOOP};
  assign memory[194] = {`NOOP};
  assign memory[195] = {`NOOP};
  assign memory[196] = {`NOOP};
  assign memory[197] = {`NOOP};
  assign memory[198] = {`NOOP};
  assign memory[199] = {`NOOP};
  assign memory[200] = {`NOOP};
  assign memory[201] = {`NOOP};
  assign memory[202] = {`NOOP};
  assign memory[203] = {`NOOP};
  assign memory[204] = {`NOOP};
  assign memory[205] = {`NOOP};
  assign memory[206] = {`NOOP};
  assign memory[207] = {`NOOP};
  assign memory[208] = {`NOOP};
  assign memory[209] = {`NOOP};
  assign memory[210] = {`NOOP};
  assign memory[211] = {`NOOP};
  assign memory[212] = {`NOOP};
  assign memory[213] = {`NOOP};
  assign memory[214] = {`NOOP};
  assign memory[215] = {`NOOP};
  assign memory[216] = {`NOOP};
  assign memory[217] = {`NOOP};
  assign memory[218] = {`NOOP};
  assign memory[219] = {`NOOP};
  assign memory[220] = {`NOOP};
  assign memory[221] = {`NOOP};
  assign memory[222] = {`NOOP};
  assign memory[223] = {`NOOP};
  assign memory[224] = {`NOOP};
  assign memory[225] = {`NOOP};
  assign memory[226] = {`NOOP};
  assign memory[227] = {`NOOP};
  assign memory[228] = {`NOOP};
  assign memory[229] = {`NOOP};
  assign memory[230] = {`NOOP};
  assign memory[231] = {`NOOP};
  assign memory[232] = {`NOOP};
  assign memory[233] = {`NOOP};
  assign memory[234] = {`NOOP};
  assign memory[235] = {`NOOP};
  assign memory[236] = {`NOOP};
  assign memory[237] = {`NOOP};
  assign memory[238] = {`NOOP};
  assign memory[239] = {`NOOP};
  assign memory[240] = {`NOOP};
  assign memory[241] = {`NOOP};
  assign memory[242] = {`NOOP};
  assign memory[243] = {`NOOP};
  assign memory[244] = {`NOOP};
  assign memory[245] = {`NOOP};
  assign memory[246] = {`NOOP};
  assign memory[247] = {`NOOP};
  assign memory[248] = {`NOOP};
  assign memory[249] = {`NOOP};
  assign memory[250] = {`NOOP};
  assign memory[251] = {`NOOP};
  assign memory[252] = {`NOOP};
  assign memory[253] = {`NOOP};
  assign memory[254] = {`NOOP};
  assign memory[255] = {`NOOP};

endmodule
