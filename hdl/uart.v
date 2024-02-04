
`default_nettype none

module uart(
   input wire clk,
   input wire [4:0] addr, 
   input wire ren, output reg [7:0] rdata, output reg rd_valid,
   input wire wen, input wire [7:0] wdata,
   output reg tx
);

	initial begin
		rd_valid <= 0;
		tx <= 1;
	end

	localparam DIVIDER = 7;

   reg [8:0] last_data = 0;
	reg [9:0] shift = 0;
	reg [7:0] status = 0;
	reg [4:0] n = 0;
	reg [12:0] div = 0;

	always @(*) begin
		status[0] = (n != 0);
	end

	always @(posedge clk)
	begin
		rd_valid <= 0;

		if (wen) begin
			case (addr)
				'h0: begin
               last_data <= wdata;
					shift <= { 1'b1, wdata, 1'b0 };
					n <= 10;
					div <= DIVIDER;
					tx <= 0;
				end
			endcase
		end

		if (ren) begin
			case (addr)
				'h4: begin
					rdata <= status;
					rd_valid <= 1;
				end
			endcase
		end


		if (n > 0) begin
			div <= div - 1;

			if (div == 0) begin
				div <= DIVIDER;
				n <= n - 1;
				tx <= shift[0];
				shift <= shift >> 1;
			end

		end else begin
			tx <= 1;
		end
	end

//	always @(posedge clk)
//	begin
//
//
//	end


endmodule

// vi: ft=verilog ts=3 sw=3 et
