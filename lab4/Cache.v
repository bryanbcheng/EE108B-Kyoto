module Cache(
  //Inputs
  rst,            // reset
  clk,            // memclk
  addr,           // read/write address
  dram_data,      // data returned from main memory
  reg_data,       // data to be written to cache
  re,             // read enable
  we,             // write enable
  mainmem_busy,   // main memory busy signal

  //Outputs
  dout,           // data retrieved from cache
  cache_busy,     // cache busy signal
  mainmem_access, // main memory access request
);

  input rst;
  input clk;
  input mainmem_busy;
  input re;
  input we;
  input [31:0] addr;
  input [31:0] dram_data;
  input [31:0] reg_data;
  
  output reg cache_busy;
  output reg [31:0] dout;
  output reg mainmem_access;
    
  wire cache_hit;

//******************************************************************************
// Control signals
//******************************************************************************
  
  reg state_write;
  reg [1:0] state_read;

  reg cache_busy_write;
  reg cache_busy_read;

  reg mainmem_access_write;
  reg mainmem_access_read;

  // cache_busy and mainmem_access signals for MemWrite
  always @ (posedge clk)
    case ({reset, state_write})
      2'b00: begin
        state_write <= we ? 1'b1 : 1'b0;
	cache_busy_write <= we ? 1'b1 : 1'b0;
	mainmem_access_write <= we ? 1'b1 : 1'b0;
      end
      2'b01: begin
        state_write <= mainmem_busy ? 1'b1 : 1'b0;
	cache_busy_write <= mainmem_busy ? 1'b1 : 1'b0;
	mainmem_access_write <=	mainmem_busy ? 1'b1 : 1'b0;
      end
      default: begin
        state_write <= 1'b0;
	cache_busy_write <= 1'b0;
	mainmem_access_write <= 1'b0;
      end
    endcase

  // cache_busy and mainmem_access signals for MemRead
  always @ (posedge clk)
    case ({reset, state_read})
      3'b000: begin
        state_read <= re ? 2'b01 : 2'b00;
        cache_busy_read <= 1'b0;
        mainmem_access_read <= 1'b0;
      end
      3'b001: begin
        state_read <= cache_hit ? 2'b11 : 2'b10;
        cache_busy_read <= cache_hit ? 1'b1 : 1'b0;
        mainmem_access_read <= cache_hit ? 1'b1 : 1'b0;
      end
      // cache miss
      3'b010: begin
        state_read <= mainmem_busy ? 2'b10 : 2'b00;
        cache_busy_read <= mainmem_busy ? 1'b1 : 1'b0;
        mainmem_access_read <= mainmem_busy ? 1'b1 : 1'b0;
      end
      // cache hit
      3'b011: begin
        state_read <= 2'b00;
        cache_busy_read <= 1'b0;
        mainmem_access_read <= 1'b0;
      end
      default: begin
        state_write <= 2'b00;
        cache_busy_write <= 1'b0;
        mainmem_access_write <= 1'b0;
      end
    endcase

//******************************************************************************
// Cache logic
//******************************************************************************

  `define CACHE_WIDTH	56
  `define NUM_CACHE	128

  `define valid		55
  `define tag		54:32
  `define data		31:0

  wire [`CACHE_WIDTH-1:0] cache1 [`NUM_CACHE-1:0];
  wire [`CACHE_WIDTH-1:0] cache2 [`NUM_CACHE-1:0];

  // WHAT IS THIS FOOR??????
  reg [31:0] cache_data_in;

  reg [55:0] cache_line1;
  reg [55:0] cache_line2;

  always @(posedge clk) begin
    cache_line1 = cache1[addr];
    cache_line2 = cache2[addr];
  end

  wire valid1 = cache_line1[`valid];
  wire valid2 = cache_line2[`valid];
  wire [22:0] cache_tag1 = cache_line1[`tag];
  wire [22:0] cache_tag2 = cache_line2[`tag];
  
  wire [22:0] input_tag = addr[31:9];
  
  wire read_hit1 = re & valid1 & (input_tag == cache_tag1);
  wire read_hit2 = re & valid2 & (input_tag == cache_tag2);

  wire [31:0] cache_data1 = cache_line[`data];
  wire [31:0] cache_data2 = cache_line[`data];

  reg [31:0] cache_data;

  always @(posedge clk) begin
    if (read_hit1)
      cache_data = cache_data1;
    else if (read_hit2)
      cache_data = cache_data2;
    else
      cache_data = 32'b0;
  end
  
  assign cache_hit = read_hit1 || read_hit2;

  // 128 bit to track LRU

//******************************************************************************
// Cache write
//******************************************************************************

  

endmodule
