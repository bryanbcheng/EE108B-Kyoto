module dataram(clka, wea, addra, dina, douta);

  input clka, wea;
  input [5 : 0] addra;
  input [31 : 0] dina;
  output reg [31 : 0] douta;

  reg [31:0] memory [0:63];

  always @(posedge clka) begin
    douta <= memory[addra];
    if (wea)
      memory[addra] <= dina;
  end

endmodule

