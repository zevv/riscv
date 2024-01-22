
`default_nettype none

module uart(
   input wire clk,
   input wire rd_en, input wire [1:0] addr, output reg [7:0] rd_data, output reg rd_valid,
   input wire wr_en, input wire [7:0] wr_data,
   output reg tx
);

	initial begin
		rd_valid <= 0;
		tx <= 1;
	end

	localparam DIVIDER = 104;

	reg [8:0] shift;
	reg [7:0] status = 0;
	reg [4:0] n;
	reg [5:0] div;

	always @(*) begin
		status[0] = (n != 0);
	end

	always @(posedge clk)
	begin

		if (wr_en) begin
			case (addr)
				'h0: begin
					shift <= { 1'b1, wr_data };
					n <= 9;
					div <= DIVIDER;
					tx <= 0;
				end
			endcase
		end

		if (rd_en) begin
			case (addr)
				'h1: begin
					rd_data <= 'h42;
					rd_valid <= 1;
				end
			endcase
		end
	end

	always @(posedge clk)
	begin

		if (n > 0) begin
			div <= div - 1;

			if(div == 0) begin
				div <= DIVIDER;
				n <= n - 1;
				tx <= shift[0];
				shift <= shift >> 1;
			end

		end else begin
			tx <= 1;
		end

	end


endmodule

