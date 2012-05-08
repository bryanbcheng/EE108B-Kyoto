// Custom IROM for testing purposes

`define ADDR_WIDTH 9
`define INSTR_WIDTH 32
`define NUM_INSTR 512

// OPCODES
`define SPECIAL  6'b000000 // operation determined by function code
`define BLTZ_GEZ 6'b000001
`define J        6'b000010
`define JAL      6'b000011
`define BEQ      6'b000100
`define BNE      6'b000101
`define BLEZ     6'b000110
`define BGTZ     6'b000111
`define ADDI     6'b001000
`define ADDIU    6'b001001
`define SLTI     6'b001010
`define SLTIU    6'b001011
`define ANDI     6'b001100
`define ORI      6'b001101
`define XORI     6'b001110
`define LUI      6'b001111
`define LW       6'b100011
`define SW       6'b101011

// the secret codes put in Rt to indicate the branch type for BLTZ_GEZ
`define BLTZ     5'b00000
`define BGEZ     5'b00001
`define BLTZAL   5'h10
`define BGEZAL   5'h11

// FUNCTION CODES
`define SLL   6'b000000
`define SRL   6'b000010
`define SRA   6'b000011
`define SLLV  6'b000100
`define SRLV  6'b000110
`define SRAV  6'b000111
`define JR    6'b001000
`define JALR  6'b001001
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

// Register names
`define ZERO 5'd0
`define AT   5'd1
`define V0   5'd2
`define V1   5'd3
`define A0   5'd4
`define A1   5'd5
`define A2   5'd6
`define A3   5'd7
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

`define NULL 5'd0 // same as ZERO, but indicates that the field is unused

`define NOP 32'b0 // the astute will notice that this is actually the following
                  // sll $zero, $zero, 0
                  // which is of course equivalent to a nop, but don't
                  // be confused when your ALU is doing a shift during a nop

module irom(clka, addra, douta);
  input clka;
  input [`ADDR_WIDTH-1:0] addra;
  output reg [`INSTR_WIDTH-1:0] douta;

  wire [`INSTR_WIDTH-1:0] memory [`NUM_INSTR-1:0];

  always @(posedge clka)
    douta = memory[addra];

  // two examples:

  // ori $t0, $zero, 1
  assign memory[  0] = {`ORI, `ZERO, `T0, 16'd1};
  // add $t0, $t1, $t2
  assign memory[  1] = {`NOP};

  // add $t1, $t0, $t0 t1 = 2
  assign memory[  2] = {`SPECIAL, `T0, `T0, `T1, `NULL, `ADD};
  // addu $t2, $t0, $t1 t2 = 3
  assign memory[  3] = {`SPECIAL, `T0, `T1, `T2, `NULL, `ADDU};
  // addi $t0, $t0, 9999 t0 = 10000
  assign memory[  4] = {`ADDI, `T0, `T0, 16'd9999};
  // addi $t1, $t0, -10001 t1 = -1
  assign memory[  5] = {`ADDI, `T0, `T1, -16'd10001};
  // addiu $t0, $t0, 2 t0 = 10002
  assign memory[  6] = {`ADDIU, `T0, `T0, 16'd2};
  // addiu $t1, $t1, 2 t1 = 1
  assign memory[  7] = {`ADDIU, `T1, `T1, 16'd2};
  
  // sub $t0, $t0, $t2 t0 = 9999
  assign memory[  8] = {`SPECIAL, `T0, `T2, `T0, `NULL, `SUB};
  // sub $t3, $zero, $t2 t3 = -3
  assign memory[  9] = {`SPECIAL, `ZERO, `T2, `T3, `NULL, `SUB};
  // sub $t0, $t0, $t3 t0 = 10002
  assign memory[ 10] = {`SPECIAL, `T0, `T3, `T0, `NULL, `SUB};
  // subu $t0, $t0, $t2 t0 = 9999
  assign memory[ 11] = {`SPECIAL, `T0, `T2, `T0, `NULL, `SUBU};
  
  // slt $t0, $t2, $t3  t0 = 0 3 < -3 false
  assign memory[ 12] = {`SPECIAL, `T2, `T3, `T0, `NULL, `SLT};
  // slt $t0, $t3, $t2 t0 = 1 -3 < 3 false
  assign memory[ 13] = {`SPECIAL, `T3, `T2, `T0, `NULL, `SLT};
  // slt $t0, $zero, $zero t0 = 0 0 < 0 false
  assign memory[ 14] = {`SPECIAL, `ZERO, `ZERO, `T0, `NULL, `SLT};
  // sltu $t0, $t2, $t3 t0 = 1 3 < -3(unsigned) true
  assign memory[ 15] = {`SPECIAL, `T2, `T3, `T0, `NULL, `SLTU};
  // sltu $t0, $t3, $t2 t0 = 0 -3(unsigned) < 3 false
  assign memory[ 16] = {`SPECIAL, `T3, `T2, `T0, `NULL, `SLTU};
  // slti $t0, $t2, 0 t0 = 0 3 < 0 false
  assign memory[ 17] = {`SLTI, `T2, `T0, 16'd0};
  // slti $t0, $t3, 0 t0 = 1 -3 < 0 true
  assign memory[ 18] = {`SLTI, `T3, `T0, 16'd0};
  // slti $t0, $zero, 0 t0 = 0 0 < 0 false
  assign memory[ 19] = {`SLTI, `ZERO, `T0, 16'd0};
  // sltiu $t0, $t2, 0 t0 = 0 3 < 0 false
  assign memory[ 20] = {`SLTIU, `T2, `T0, 16'd0};
  // sltiu $t0, $t3, 0 t0 = 0 -3(unsigned) < 0 false
  assign memory[ 21] = {`SLTIU, `T3, `T0, 16'd0};
  
  // and $t0, $t2, $t3 t0 = 1 00000000000000000000000000000011 & 11111111111111111111111111111101
  assign memory[ 22] = {`SPECIAL, `T2, `T3, `T0, `NULL, `AND};
  // and $t0, $t3, $zero t0 = 0 
  assign memory[ 23] = {`SPECIAL, `T3, `ZERO, `T0, `NULL, `AND};
  // andi $t0, $zero, 1023 t0 = 0
  assign memory[ 24] = {`ANDI, `ZERO, `T0, 16'd1023};
  // andi $t0, $t2, 23 t0 = 3
  assign memory[ 25] = {`ANDI, `T2, `T0, 16'd23};
  // andi $t0, $t2, 21 t0 = 1
  assign memory[ 26] = {`ANDI, `T2, `T0, 16'd21};
  
  // or $t0, $t2, $t3 t0 = -1
  assign memory[ 27] = {`SPECIAL, `T2, `T3, `T0, `NULL, `OR};
  // or $t0, $t3, $zero t0 = t3 = -3
  assign memory[ 28] = {`SPECIAL, `T3, `ZERO, `T0, `NULL, `OR};
  // ori $t0, $zero, 1023 t0 = 1023
  assign memory[ 29] = {`ORI, `ZERO, `T0, 16'd1023};
  // ori $t0, $t2, 23 t0 = 23
  assign memory[ 30] = {`ORI, `T2, `T0, 16'd23};
  // ori $t0, $t2, 21 t0 = 23
  assign memory[ 31] = {`ORI, `T2, `T0, 16'd21};

  // xor $t0, $t2, $t3 t0 = -2
  assign memory[ 32] = {`SPECIAL, `T2, `T3, `T0, `NULL, `XOR};
  // xor $t0, $t3, $zero t0 = t3 = -3
  assign memory[ 33] = {`SPECIAL, `T3, `ZERO, `T0, `NULL, `XOR};
  // xori $t0, $zero, 1023 t0 = 1023
  assign memory[ 34] = {`XORI, `ZERO, `T0, 16'd1023};
  // xori $t0, $t2, 23 t0 = 20
  assign memory[ 35] = {`XORI, `T2, `T0, 16'd23};
  // xori $t0, $t2, 21 t0 = 22
  assign memory[ 36] = {`XORI, `T2, `T0, 16'd21};

  // nor $t0, $t2, $t3 t0 = 0
  assign memory[ 37] = {`SPECIAL, `T2, `T3, `T0, `NULL, `NOR};
  // nor $t0, $t3, $zero t0 = 2
  assign memory[ 38] = {`SPECIAL, `T3, `ZERO, `T0, `NULL, `NOR};
  
  // srl $t0, $t2, 2 t0 = 0
  assign memory[ 39] = {`SPECIAL, `NULL, `T2, `T0, 5'd2, `SRL};
  // srl $t0, $t2, -2 t0 = 0
  assign memory[ 40] = {`SPECIAL, `NULL, `T2, `T0, -5'd2, `SRL};
  // srl $t0, $t3, 2 t0 = t0 = 1073741823
  assign memory[ 41] = {`SPECIAL, `NULL, `T3, `T0, 5'd2, `SRL};
  // srl $t0, $t3, -2 t0 = 3
  assign memory[ 42] = {`SPECIAL, `NULL, `T3, `T0, -5'd2, `SRL};

  // sra $t0, $t2, 2 t0 = 0
  assign memory[ 43] = {`SPECIAL, `NULL, `T2, `T0, 5'd2, `SRA};
  // sra $t0, $t2, -2 t0 = 0
  assign memory[ 44] = {`SPECIAL, `NULL, `T2, `T0, -5'd2, `SRA};
  // sra $t0, $t3, 2 t0 = -1
  assign memory[ 45] = {`SPECIAL, `NULL, `T3, `T0, 5'd2, `SRA};
  // sra $t0, $t3, -2 t0 = -1
  assign memory[ 46] = {`SPECIAL, `NULL, `T3, `T0, -5'd2, `SRA};

  // sll $t0, $t2, 2 t0 = 12
  assign memory[ 47] = {`SPECIAL, `NULL, `T2, `T0, 5'd2, `SLL};
  // sll $t0, $t2, -2 t0 = 3489660927 / -1073741824
  assign memory[ 48] = {`SPECIAL, `NULL, `T2, `T0, -5'd2, `SLL};
  // sll $t0, $t3, 2 t0 = -12
  assign memory[ 49] = {`SPECIAL, `NULL, `T3, `T0, 5'd2, `SLL};
  // sll $t0, $t3, -2 t0 = 10737411824
  assign memory[ 50] = {`SPECIAL, `NULL, `T3, `T0, -5'd2, `SLL};

  // addi $t4, $zero, 1 t4 = 0
  assign memory[ 51] = {`ADDI, `ZERO, `T4, 16'd1};
  // srlv $t0, $t2, $t4 t0 = 1
  assign memory[ 52] = {`SPECIAL, `T4, `T2, `T0, `NULL, `SRLV};
  // srlv $t0, $t3, $t4 t0 = 214783646
  assign memory[ 53] = {`SPECIAL, `T4, `T3, `T0, `NULL, `SRLV};
  // srav $t0, $t2, $t4 t0 = 1
  assign memory[ 54] = {`SPECIAL, `T4, `T2, `T0, `NULL, `SRAV};
  // srav $t0, $t3, $t4 t0 = -2
  assign memory[ 55] = {`SPECIAL, `T4, `T3, `T0, `NULL, `SRAV};
  // sllv $t0, $t2, $t4 t0 = 6
  assign memory[ 56] = {`SPECIAL, `T4, `T2, `T0, `NULL, `SLLV};
  // sllv $t0, $t3, $t4 t0 = -6
  assign memory[ 57] = {`SPECIAL, `T4, `T3, `T0, `NULL, `SLLV}; 
  assign memory[ 58] = {`NOP};
  
  // use ALUOp reads to make sure ADDI instructions are never called
  // beq $t2, $t2, 1 branch to 61
  assign memory[ 59] = {`BEQ, `T2, `T2, 16'd1};
  assign memory[ 60] = {`ADDI, `T0, `T0, 16'd2000};
  // bne $t3, $t2, 1 branch to 63
  assign memory[ 61] = {`BNE, `T2, `T3, 16'd1};
  assign memory[ 62] = {`ADDI, `T0, `T0, 16'd500};
  // bltz $t3, 1 branch to 65
  assign memory[ 63] = {`BLTZ, `NULL, `T3, 16'd1};
  assign memory[ 64] = {`ADDI, `T0, `T0, 16'd600};
  // blez $t3, 1 branch to 67
  assign memory[ 65] = {`BLEZ, `NULL, `T3, 16'd1};
  assign memory[ 66] = {`ADDI, `T0, `T0, 16'd700};
  // bgtz $t2, 1 branch to 69
  assign memory[ 67] = {`BGTZ, `NULL, `T2, 16'd1};
  assign memory[ 68] = {`ADDI, `T0, `T0, 16'd800};
  // bgez $t2, 1 branch to 70
  assign memory[ 69] = {`BGEZ, `NULL, `T2, 16'd0};
  assign memory[ 70] = {`ADDI, `T0, `T0, 16'd1000};
  assign memory[ 71] = {`LUI, `NULL, `T0, 16'd50};
  
  // load and save word
  // sw $t1, 0(gp)
  assign memory[ 72] = {`ADDI, `ZERO, `T1, 16'd1337};
  assign memory[ 73] = {`SW, `GP, `T1, 16'd0};
  // lw $t0, 0(gp)
  assign memory[ 74] = {`LW, `GP, `T0, 16'd0};
  // sw $t1, 24(gp)
  assign memory[ 75] = {`SW, `GP, `T1, 16'd24};
  // lw $t0, 24(gp)
  assign memory[ 76] = {`LW, `GP, `T0, 16'd24};
  assign memory[ 77] = {`NOP};
  assign memory[ 78] = {`NOP};
  assign memory[ 79] = {`NOP};
  assign memory[ 80] = {`NOP};
  assign memory[ 81] = {`NOP};
  assign memory[ 82] = {`NOP};
  assign memory[ 83] = {`NOP};
  assign memory[ 84] = {`NOP};
  assign memory[ 85] = {`NOP};
  assign memory[ 86] = {`NOP};
  assign memory[ 87] = {`NOP};
  assign memory[ 88] = {`NOP};
  assign memory[ 89] = {`NOP};
  assign memory[ 90] = {`NOP};
  assign memory[ 91] = {`NOP};
  assign memory[ 92] = {`NOP};
  assign memory[ 93] = {`NOP};
  // beq $t2, $t2, offset
  assign memory[ 94] = {`NOP};
  // bne $t3, $t2, offset
  assign memory[ 95] = {`NOP};
  // bltz $t3, offset
  assign memory[ 96] = {`NOP};
  // blez $t3, offset
  assign memory[ 97] = {`NOP};
  // bgtz $t2, offset
  assign memory[ 98] = {`NOP};
  // bgez $t2, offset
  assign memory[ 99] = {`NOP};
  // lui $t0, 50
  assign memory[100] = {`NOP};
  assign memory[103] = {`NOP};
  assign memory[104] = {`NOP};
  assign memory[105] = {`NOP};
  assign memory[106] = {`NOP};
  assign memory[107] = {`NOP};
  assign memory[108] = {`NOP};
  assign memory[109] = {`NOP};
  assign memory[110] = {`NOP};
  assign memory[111] = {`NOP};
  assign memory[112] = {`NOP};
  assign memory[113] = {`NOP};
  assign memory[114] = {`NOP};
  assign memory[115] = {`NOP};
  assign memory[116] = {`NOP};
  assign memory[117] = {`NOP};
  assign memory[118] = {`NOP};
  assign memory[119] = {`NOP};
  assign memory[120] = {`NOP};
  assign memory[121] = {`NOP};
  assign memory[122] = {`NOP};
  assign memory[123] = {`NOP};
  assign memory[124] = {`NOP};
  assign memory[125] = {`NOP};
  assign memory[126] = {`NOP};
  assign memory[127] = {`NOP};
  assign memory[128] = {`NOP};
  assign memory[129] = {`NOP};
  assign memory[130] = {`NOP};
  assign memory[131] = {`NOP};
  assign memory[132] = {`NOP};
  assign memory[133] = {`NOP};
  assign memory[134] = {`NOP};
  assign memory[135] = {`NOP};
  assign memory[136] = {`NOP};
  assign memory[137] = {`NOP};
  assign memory[138] = {`NOP};
  assign memory[139] = {`NOP};
  assign memory[140] = {`NOP};
  assign memory[141] = {`NOP};
  assign memory[142] = {`NOP};
  assign memory[143] = {`NOP};
  assign memory[144] = {`NOP};
  assign memory[145] = {`NOP};
  assign memory[146] = {`NOP};
  assign memory[147] = {`NOP};
  assign memory[148] = {`NOP};
  assign memory[149] = {`NOP};
  assign memory[150] = {`NOP};
  assign memory[151] = {`NOP};
  assign memory[152] = {`NOP};
  assign memory[153] = {`NOP};
  assign memory[154] = {`NOP};
  assign memory[155] = {`NOP};
  assign memory[156] = {`NOP};
  assign memory[157] = {`NOP};
  assign memory[158] = {`NOP};
  assign memory[159] = {`NOP};
  assign memory[160] = {`NOP};
  assign memory[161] = {`NOP};
  assign memory[162] = {`NOP};
  assign memory[163] = {`NOP};
  assign memory[164] = {`NOP};
  assign memory[165] = {`NOP};
  assign memory[166] = {`NOP};
  assign memory[167] = {`NOP};
  assign memory[168] = {`NOP};
  assign memory[169] = {`NOP};
  assign memory[170] = {`NOP};
  assign memory[171] = {`NOP};
  assign memory[172] = {`NOP};
  assign memory[173] = {`NOP};
  assign memory[174] = {`NOP};
  assign memory[175] = {`NOP};
  assign memory[176] = {`NOP};
  assign memory[177] = {`NOP};
  assign memory[178] = {`NOP};
  assign memory[179] = {`NOP};
  assign memory[180] = {`NOP};
  assign memory[181] = {`NOP};
  assign memory[182] = {`NOP};
  assign memory[183] = {`NOP};
  assign memory[184] = {`NOP};
  assign memory[185] = {`NOP};
  assign memory[186] = {`NOP};
  assign memory[187] = {`NOP};
  assign memory[188] = {`NOP};
  assign memory[189] = {`NOP};
  assign memory[190] = {`NOP};
  assign memory[191] = {`NOP};
  assign memory[192] = {`NOP};
  assign memory[193] = {`NOP};
  assign memory[194] = {`NOP};
  assign memory[195] = {`NOP};
  assign memory[196] = {`NOP};
  assign memory[197] = {`NOP};
  assign memory[198] = {`NOP};
  assign memory[199] = {`NOP};
  assign memory[200] = {`NOP};
  assign memory[201] = {`NOP};
  assign memory[202] = {`NOP};
  assign memory[203] = {`NOP};
  assign memory[204] = {`NOP};
  assign memory[205] = {`NOP};
  assign memory[206] = {`NOP};
  assign memory[207] = {`NOP};
  assign memory[208] = {`NOP};
  assign memory[209] = {`NOP};
  assign memory[210] = {`NOP};
  assign memory[211] = {`NOP};
  assign memory[212] = {`NOP};
  assign memory[213] = {`NOP};
  assign memory[214] = {`NOP};
  assign memory[215] = {`NOP};
  assign memory[216] = {`NOP};
  assign memory[217] = {`NOP};
  assign memory[218] = {`NOP};
  assign memory[219] = {`NOP};
  assign memory[220] = {`NOP};
  assign memory[221] = {`NOP};
  assign memory[222] = {`NOP};
  assign memory[223] = {`NOP};
  assign memory[224] = {`NOP};
  assign memory[225] = {`NOP};
  assign memory[226] = {`NOP};
  assign memory[227] = {`NOP};
  assign memory[228] = {`NOP};
  assign memory[229] = {`NOP};
  assign memory[230] = {`NOP};
  assign memory[231] = {`NOP};
  assign memory[232] = {`NOP};
  assign memory[233] = {`NOP};
  assign memory[234] = {`NOP};
  assign memory[235] = {`NOP};
  assign memory[236] = {`NOP};
  assign memory[237] = {`NOP};
  assign memory[238] = {`NOP};
  assign memory[239] = {`NOP};
  assign memory[240] = {`NOP};
  assign memory[241] = {`NOP};
  assign memory[242] = {`NOP};
  assign memory[243] = {`NOP};
  assign memory[244] = {`NOP};
  assign memory[245] = {`NOP};
  assign memory[246] = {`NOP};
  assign memory[247] = {`NOP};
  assign memory[248] = {`NOP};
  assign memory[249] = {`NOP};
  assign memory[250] = {`NOP};
  assign memory[251] = {`NOP};
  assign memory[252] = {`NOP};
  assign memory[253] = {`NOP};
  assign memory[254] = {`NOP};
  assign memory[255] = {`NOP};
  assign memory[256] = {`NOP};
  assign memory[257] = {`NOP};
  assign memory[258] = {`NOP};
  assign memory[259] = {`NOP};
  assign memory[260] = {`NOP};
  assign memory[261] = {`NOP};
  assign memory[262] = {`NOP};
  assign memory[263] = {`NOP};
  assign memory[264] = {`NOP};
  assign memory[265] = {`NOP};
  assign memory[266] = {`NOP};
  assign memory[267] = {`NOP};
  assign memory[268] = {`NOP};
  assign memory[269] = {`NOP};
  assign memory[270] = {`NOP};
  assign memory[271] = {`NOP};
  assign memory[272] = {`NOP};
  assign memory[273] = {`NOP};
  assign memory[274] = {`NOP};
  assign memory[275] = {`NOP};
  assign memory[276] = {`NOP};
  assign memory[277] = {`NOP};
  assign memory[278] = {`NOP};
  assign memory[279] = {`NOP};
  assign memory[280] = {`NOP};
  assign memory[281] = {`NOP};
  assign memory[282] = {`NOP};
  assign memory[283] = {`NOP};
  assign memory[284] = {`NOP};
  assign memory[285] = {`NOP};
  assign memory[286] = {`NOP};
  assign memory[287] = {`NOP};
  assign memory[288] = {`NOP};
  assign memory[289] = {`NOP};
  assign memory[290] = {`NOP};
  assign memory[291] = {`NOP};
  assign memory[292] = {`NOP};
  assign memory[293] = {`NOP};
  assign memory[294] = {`NOP};
  assign memory[295] = {`NOP};
  assign memory[296] = {`NOP};
  assign memory[297] = {`NOP};
  assign memory[298] = {`NOP};
  assign memory[299] = {`NOP};
  assign memory[300] = {`NOP};
  assign memory[301] = {`NOP};
  assign memory[302] = {`NOP};
  assign memory[303] = {`NOP};
  assign memory[304] = {`NOP};
  assign memory[305] = {`NOP};
  assign memory[306] = {`NOP};
  assign memory[307] = {`NOP};
  assign memory[308] = {`NOP};
  assign memory[309] = {`NOP};
  assign memory[310] = {`NOP};
  assign memory[311] = {`NOP};
  assign memory[312] = {`NOP};
  assign memory[313] = {`NOP};
  assign memory[314] = {`NOP};
  assign memory[315] = {`NOP};
  assign memory[316] = {`NOP};
  assign memory[317] = {`NOP};
  assign memory[318] = {`NOP};
  assign memory[319] = {`NOP};
  assign memory[320] = {`NOP};
  assign memory[321] = {`NOP};
  assign memory[322] = {`NOP};
  assign memory[323] = {`NOP};
  assign memory[324] = {`NOP};
  assign memory[325] = {`NOP};
  assign memory[326] = {`NOP};
  assign memory[327] = {`NOP};
  assign memory[328] = {`NOP};
  assign memory[329] = {`NOP};
  assign memory[330] = {`NOP};
  assign memory[331] = {`NOP};
  assign memory[332] = {`NOP};
  assign memory[333] = {`NOP};
  assign memory[334] = {`NOP};
  assign memory[335] = {`NOP};
  assign memory[336] = {`NOP};
  assign memory[337] = {`NOP};
  assign memory[338] = {`NOP};
  assign memory[339] = {`NOP};
  assign memory[340] = {`NOP};
  assign memory[341] = {`NOP};
  assign memory[342] = {`NOP};
  assign memory[343] = {`NOP};
  assign memory[344] = {`NOP};
  assign memory[345] = {`NOP};
  assign memory[346] = {`NOP};
  assign memory[347] = {`NOP};
  assign memory[348] = {`NOP};
  assign memory[349] = {`NOP};
  assign memory[350] = {`NOP};
  assign memory[351] = {`NOP};
  assign memory[352] = {`NOP};
  assign memory[353] = {`NOP};
  assign memory[354] = {`NOP};
  assign memory[355] = {`NOP};
  assign memory[356] = {`NOP};
  assign memory[357] = {`NOP};
  assign memory[358] = {`NOP};
  assign memory[359] = {`NOP};
  assign memory[360] = {`NOP};
  assign memory[361] = {`NOP};
  assign memory[362] = {`NOP};
  assign memory[363] = {`NOP};
  assign memory[364] = {`NOP};
  assign memory[365] = {`NOP};
  assign memory[366] = {`NOP};
  assign memory[367] = {`NOP};
  assign memory[368] = {`NOP};
  assign memory[369] = {`NOP};
  assign memory[370] = {`NOP};
  assign memory[371] = {`NOP};
  assign memory[372] = {`NOP};
  assign memory[373] = {`NOP};
  assign memory[374] = {`NOP};
  assign memory[375] = {`NOP};
  assign memory[376] = {`NOP};
  assign memory[377] = {`NOP};
  assign memory[378] = {`NOP};
  assign memory[379] = {`NOP};
  assign memory[380] = {`NOP};
  assign memory[381] = {`NOP};
  assign memory[382] = {`NOP};
  assign memory[383] = {`NOP};
  assign memory[384] = {`NOP};
  assign memory[385] = {`NOP};
  assign memory[386] = {`NOP};
  assign memory[387] = {`NOP};
  assign memory[388] = {`NOP};
  assign memory[389] = {`NOP};
  assign memory[390] = {`NOP};
  assign memory[391] = {`NOP};
  assign memory[392] = {`NOP};
  assign memory[393] = {`NOP};
  assign memory[394] = {`NOP};
  assign memory[395] = {`NOP};
  assign memory[396] = {`NOP};
  assign memory[397] = {`NOP};
  assign memory[398] = {`NOP};
  assign memory[399] = {`NOP};
  assign memory[400] = {`NOP};
  assign memory[401] = {`NOP};
  assign memory[402] = {`NOP};
  assign memory[403] = {`NOP};
  assign memory[404] = {`NOP};
  assign memory[405] = {`NOP};
  assign memory[406] = {`NOP};
  assign memory[407] = {`NOP};
  assign memory[408] = {`NOP};
  assign memory[409] = {`NOP};
  assign memory[410] = {`NOP};
  assign memory[411] = {`NOP};
  assign memory[412] = {`NOP};
  assign memory[413] = {`NOP};
  assign memory[414] = {`NOP};
  assign memory[415] = {`NOP};
  assign memory[416] = {`NOP};
  assign memory[417] = {`NOP};
  assign memory[418] = {`NOP};
  assign memory[419] = {`NOP};
  assign memory[420] = {`NOP};
  assign memory[421] = {`NOP};
  assign memory[422] = {`NOP};
  assign memory[423] = {`NOP};
  assign memory[424] = {`NOP};
  assign memory[425] = {`NOP};
  assign memory[426] = {`NOP};
  assign memory[427] = {`NOP};
  assign memory[428] = {`NOP};
  assign memory[429] = {`NOP};
  assign memory[430] = {`NOP};
  assign memory[431] = {`NOP};
  assign memory[432] = {`NOP};
  assign memory[433] = {`NOP};
  assign memory[434] = {`NOP};
  assign memory[435] = {`NOP};
  assign memory[436] = {`NOP};
  assign memory[437] = {`NOP};
  assign memory[438] = {`NOP};
  assign memory[439] = {`NOP};
  assign memory[440] = {`NOP};
  assign memory[441] = {`NOP};
  assign memory[442] = {`NOP};
  assign memory[443] = {`NOP};
  assign memory[444] = {`NOP};
  assign memory[445] = {`NOP};
  assign memory[446] = {`NOP};
  assign memory[447] = {`NOP};
  assign memory[448] = {`NOP};
  assign memory[449] = {`NOP};
  assign memory[450] = {`NOP};
  assign memory[451] = {`NOP};
  assign memory[452] = {`NOP};
  assign memory[453] = {`NOP};
  assign memory[454] = {`NOP};
  assign memory[455] = {`NOP};
  assign memory[456] = {`NOP};
  assign memory[457] = {`NOP};
  assign memory[458] = {`NOP};
  assign memory[459] = {`NOP};
  assign memory[460] = {`NOP};
  assign memory[461] = {`NOP};
  assign memory[462] = {`NOP};
  assign memory[463] = {`NOP};
  assign memory[464] = {`NOP};
  assign memory[465] = {`NOP};
  assign memory[466] = {`NOP};
  assign memory[467] = {`NOP};
  assign memory[468] = {`NOP};
  assign memory[469] = {`NOP};
  assign memory[470] = {`NOP};
  assign memory[471] = {`NOP};
  assign memory[472] = {`NOP};
  assign memory[473] = {`NOP};
  assign memory[474] = {`NOP};
  assign memory[475] = {`NOP};
  assign memory[476] = {`NOP};
  assign memory[477] = {`NOP};
  assign memory[478] = {`NOP};
  assign memory[479] = {`NOP};
  assign memory[480] = {`NOP};
  assign memory[481] = {`NOP};
  assign memory[482] = {`NOP};
  assign memory[483] = {`NOP};
  assign memory[484] = {`NOP};
  assign memory[485] = {`NOP};
  assign memory[486] = {`NOP};
  assign memory[487] = {`NOP};
  assign memory[488] = {`NOP};
  assign memory[489] = {`NOP};
  assign memory[490] = {`NOP};
  assign memory[491] = {`NOP};
  assign memory[492] = {`NOP};
  assign memory[493] = {`NOP};
  assign memory[494] = {`NOP};
  assign memory[495] = {`NOP};
  assign memory[496] = {`NOP};
  assign memory[497] = {`NOP};
  assign memory[498] = {`NOP};
  assign memory[499] = {`NOP};
  assign memory[500] = {`NOP};
  assign memory[501] = {`NOP};
  assign memory[502] = {`NOP};
  assign memory[503] = {`NOP};
  assign memory[504] = {`NOP};
  assign memory[505] = {`NOP};
  assign memory[506] = {`NOP};
  assign memory[507] = {`NOP};
  assign memory[508] = {`NOP};
  assign memory[509] = {`NOP};
  assign memory[510] = {`NOP};
  assign memory[511] = {`NOP};

endmodule
