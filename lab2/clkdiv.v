module clkdiv (reset, source_clk, destclk, destclk_n);
  input source_clk, reset;
  output destclk, destclk_n;
  
  wire [1:0] counter;
  
  assign destclk = counter[1];
  assign destclk_n = ~destclk;
  
  dffre #(2) div_ff (.clk(source_clk), .r(reset), .en(1'b1), .d(counter + 1'd1), .q(counter));
  
endmodule 
  
