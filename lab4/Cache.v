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
  
  reg [31:0] cache_data_in;
  
  wire [55:0] cache_line;
  
  wire valid = cache_line[55];
  wire [22:0] cache_tag = cache_line[54:32]; 
  wire [22:0] input_tag = addr[31:9];
  wire read_hit = re & (input_tag == cache_tag);

  wire [31:0] cache_data = cache_line[31:0];
  
  
endmodule
