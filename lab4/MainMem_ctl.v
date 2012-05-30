module MainMem_ctl(
	// Outputs
	dout,			// data output to $D
	busy,			// Busy signal to caches
	start_read,		// Indicate to cache to start reading

	// Inputs		
	clk,
	reset,			// Reset
	access,			// Memory access request
	write,			// $D write (1 if write access, 0 if read access)
	din,				// Data in from $D
	addr			// Address from $D
);

	// Inputs from toplevel
	input clk;
	input reset;		// Reset
	input access;		// Memory access request
	input write;		// $D write (1 if write access, 0 if read access)
	input [31:0]din;	// Data in from $D
	input [31:0]addr;	// Address from $D

	// Outputs
	output	[31:0]dout;
	output 	busy;	// Mem controller is busy processing request
	output	start_read;// Indicate to cache to start reading
	
	wire [31:0] dout_temp;
	reg  [31:0] dout;
	reg  write_l, busy, start_read;
	reg  [2:0] state;
	reg  [31:0] din_l;
	reg  [31:0] addr_l;
	
	mainmem mainmem (.addr(addr_l[17:2]), .clk(clk), .din(din_l), .dout(dout_temp), .we(write_l && access));
	
	// Main memory access latency block
	always @ (posedge clk) begin
		case ({reset, access, state})
		// Wait cycle 1
		5'b01000:	begin
			state <= 3'b001;
			busy <= 1'b1;
			start_read <= 1'b1;
			dout <= dout;
			din_l <= din;
			addr_l <= addr;
			write_l <= write;
		end
		// Wait cycle 2
		5'b01001:	begin
			state <= 3'b010;
			busy <= 1'b1;
			start_read <= 1'b1;
			dout <= dout;
			din_l <= din_l;
			addr_l <= addr_l;
			write_l <= write_l;
		end
		// Wait cycle 3
		5'b01010:	begin
			state <= 3'b011;
			busy <= 1'b1;
			start_read <= 1'b1;
			dout <= dout;
			din_l <= din_l;
			addr_l <= ~write_l ? addr_l + 4 : addr_l;
			write_l <= write_l;
		end
		// Wait cycle 4
		5'b01011:	begin
			dout <= write_l ? dout:dout_temp;
			din_l <= din_l;
			start_read <= 1'b0;
			// If the read is for 4 words
			if (~write_l) begin
				// Go to next state
				state <= 3'b100;
				// Keep busy signal high
				busy <= 1'b1;
				// Increment address
				addr_l <= addr_l + 4;
				// Hold write_l value (low)
				write_l <= write_l;
				end
			else	begin
				state <= 3'b111;
				busy <= 1'b0;
				addr_l <= addr_l;
				write_l <= 1'b0;
				end
			end
	  	// Wait cycle 5
		5'b01100:	begin
			state <= 3'b101;
			start_read <= 1'b0;
			busy <= 1'b1;
			dout <= dout_temp;
			din_l <= din_l;
			addr_l <= addr_l + 4;
			write_l <= write_l;
		end
		// Wait cycle 6
		5'b01101:	begin
			state <= 3'b110;
			start_read <= 1'b0;
			busy <= 1'b1;
			dout <= dout_temp;
			din_l <= din_l;
			addr_l <= addr_l;
			write_l <= write_l;
		end
		// Wait cycle 7
		5'b01110:	begin
			state <= 3'b111;
			start_read <= 1'b0;
			busy <= 1'b0;
			dout <= dout_temp;
			din_l <= din_l;
			addr_l <= addr_l;
			write_l <= 1'b0;
		end
		// Restore state to 0
		5'b01111: begin
			state <= 3'b000;
			start_read <= 1'b0;
			busy <= 1'b0;
			dout <= dout;
			din_l <= din_l;
			addr_l <= addr_l;
			write_l <= 1'b0;
		end
		default: begin
			state <= 1'b0;
			start_read <= 1'b0;
			busy <= 1'b0;
			dout <= dout;
			din_l <= din_l;
			addr_l <= addr_l;
			write_l <= 1'b0;
		end
		endcase		
	end
endmodule
