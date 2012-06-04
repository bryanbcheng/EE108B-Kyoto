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
    
//******************************************************************************
// Control signals
//******************************************************************************
  
  wire re_delay;
  wire we_delay;
  wire mainmem_busy_delay;

  dffr #1 dffr_re_delay(.d(re), .r(rst), .clk(clk), .q(re_delay));
  dffr #1 dffr_we_delay(.d(we), .r(rst), .clk(clk), .q(we_delay));
  dffr #1 dffr_mainmem_busy_delay(.d(mainmem_busy), .r(rst), .clk(clk), .q(mainmem_busy_delay));

  always @ (posedge clk)
    case ({re, re_delay, we, we_delay, mainmem_busy, mainmem_busy_delay})
      // MemWrite set high
      6'bxx10xx: begin
        cache_busy <= 1'b1;
	mainmem_access <= 1'b1;
      end
      // mainmem_busy set low
      6'bxxxx01: begin
      　　mainmem_b1'b0;
      end
      default: begin
        cache_busy <= 1'b0;
	mainmem_access <= 1'b0;
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
    cache_line2 = cache2[];
  end

  //wire [55:0] cache_line = ;

  wire valid1 = cache_line1[`valid];
  wire valid2 = cache_line2[`valid];
  wire [22:0] cache_tag1 = cache_line1[`tag];
  wire [22:0] cache_tag2 = cache_line2[`tag];
  
  wire [22:0] input_tag = addr[31:9];
  
  wire read_hit1 = re & (input_tag == cache_tag1);
  wire read_hit2 = re & (input_tag == cache_tag2);

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
  // need to check valid bit, compare to the two??
  // 128 bit to track LRU

endmodule
