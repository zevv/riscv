
`default_nettype none

module uart(
   input wire clk,
   input wire [1:0] addr, 
   input wire rd_en, output reg [7:0] rd_data, output reg rd_valid,
   input wire wr_en, input wire [7:0] wr_data,
   output reg tx
);

	initial begin
		rd_valid <= 0;
		tx <= 1;
	end

	localparam DIVIDER = 8;

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

		if (wr_en) begin
			case (addr)
				'h0: begin
               last_data <= wr_data;
					shift <= { 1'b1, wr_data, 1'b0 };
					n <= 10;
					div <= DIVIDER;
					tx <= 0;
				end
			endcase
		end

		if (rd_en) begin
			case (addr)
				'h1: begin
					rd_data <= status;
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
