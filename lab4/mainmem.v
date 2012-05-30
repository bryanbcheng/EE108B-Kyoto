module mainmem (
	addr,
	clk,
	din,
	dout,
	we);    // synthesis black_box

input [15 : 0] addr;
input clk;
input [31 : 0] din;
output reg [31 : 0] dout;
input we;

reg [31:0] memory [0:63];

always @(posedge clk) begin
  dout <= memory[addr[5:0]];
  if (we)
    memory[addr[5:0]] <= din;
end

endmodule

