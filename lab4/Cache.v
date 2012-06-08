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
  
  output cache_busy;
  output reg [31:0] dout;
  output mainmem_access;
    
  wire cache_hit;

//******************************************************************************
// Control signals
//******************************************************************************
  
  reg [1:0] state_write;
  reg [2:0] state_read;

  reg cache_busy_write;
  reg cache_busy_read;

  reg mainmem_access_write;
  reg mainmem_access_read;
  
  assign cache_busy = (we && cache_busy_write) || (re && cache_busy_read);
  assign mainmem_access = (we && mainmem_access_write) || (re && mainmem_access_read);
  
  // cache_busy and mainmem_access signals for MemWrite
  always @ (posedge clk)
    case ({rst, state_write})
      3'b000: begin
        state_write <= we ? 2'b01 : 2'b00;
	cache_busy_write <= we;
	mainmem_access_write <= we;
      end
      3'b001: begin
        state_write <= 2'b10;
	cache_busy_write <= 1'b1;
	mainmem_access_write <=	1'b1;
      end
      3'b010: begin
        state_write <= mainmem_busy ? 2'b10 : 2'b11;
        cache_busy_write <= mainmem_busy;
        mainmem_access_write <= mainmem_busy;
      end
      3'b011: begin
      	state_write <= we ? 2'b11 : 2'b00;
	cache_busy_write <= 1'b0;
	mainmem_access_write <= 1'b0;
      end
      default: begin
        state_write <= 2'b00;
	cache_busy_write <= 1'b0;
	mainmem_access_write <= 1'b0;
      end
    endcase

  // cache_busy and mainmem_access signals for MemRead
  always @ (posedge clk)
    case ({rst, state_read})
      4'b0000: begin
        state_read <= re ? 3'b001 : 3'b000;
        cache_busy_read <= 1'b0;
        mainmem_access_read <= 1'b0;
      end
      4'b0001: begin
        if (cache_hit) begin
	  state_read <= 3'b100;
	  cache_busy_read <= 1'b0;
	  mainmem_access_read <= 1'b0;
	end
	else begin
	  state_read <= 3'b010;
	  cache_busy_read <= 1'b1;
	  mainmem_access_read <= 1'b1;
	end
      end
      // cache miss
      4'b0010: begin
        state_read <= 3'b011;
	cache_busy_read <= 1'b1;
	mainmem_access_read <= 1'b1;
      end
      4'b0011: begin
        state_read <= mainmem_busy ? 3'b011 : 3'b100;
        cache_busy_read <= mainmem_busy;
        mainmem_access_read <= mainmem_busy;
      end
      // same as cache hit, but need for storing in cache
      4'b0100: begin
        state_read <= re ? 3'b101: 3'b000;
        cache_busy_read <= 1'b0;
        mainmem_access_read <= 1'b0;
      end
      // cache hit
      4'b0101: begin
        state_read <= re ? 3'b101: 3'b000;
        cache_busy_read <= 1'b0;
        mainmem_access_read <= 1'b0;
      end
      default: begin
        state_read <= 3'b000;
        cache_busy_read <= 1'b0;
        mainmem_access_read <= 1'b0;
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

  `define addr_tag	31:9
  `define addr_index	8:2

  reg [`CACHE_WIDTH-1:0] cache1 [`NUM_CACHE-1:0];
  reg [`CACHE_WIDTH-1:0] cache2 [`NUM_CACHE-1:0];

  reg [55:0] cache_line1;
  reg [55:0] cache_line2;

  always @(posedge clk) begin
    cache_line1 = cache1[addr[`addr_index]];
    cache_line2 = cache2[addr[`addr_index]];
  end

  wire valid1 = cache_line1[`valid];
  wire valid2 = cache_line2[`valid];
  wire [22:0] cache_tag1 = cache_line1[`tag];
  wire [22:0] cache_tag2 = cache_line2[`tag];
  
  wire [22:0] input_tag = addr[`addr_tag];
  
  wire read_hit1 = re & valid1 & (input_tag == cache_tag1);
  wire read_hit2 = re & valid2 & (input_tag == cache_tag2);

  wire [31:0] cache_data1 = cache_line1[`data];
  wire [31:0] cache_data2 = cache_line2[`data];

  reg [31:0] cache_data;

  always @(posedge clk) begin
    if (read_hit1)
      cache_data = cache_data1;
      //dout <= cache_data1;
    else if (read_hit2)
      cache_data = cache_data2;
      //dout <= cache_data2;
    else
      cache_data = 32'b0;
      //dout <= 32'b0;
  end
  
  assign cache_hit = read_hit1 || read_hit2;

  // 128 bit to track LRU

//******************************************************************************
// Cache write
//******************************************************************************

  wire [55:0] cache_entry;

  assign cache_entry = {1'b1, input_tag, reg_data};

  always @(posedge clk) begin
    if (we)
      cache1[addr[`addr_index]] <= cache_entry;
  end
    

//******************************************************************************
// Data output
//******************************************************************************

  always @ (posedge clk) begin
    if (cache_hit)
      dout <= cache_data;
    else if ()

  end

endmodule
