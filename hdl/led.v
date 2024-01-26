`default_nettype none

module led(
   input wire clk,
   input wire rd_en, input wire [1:0] addr, output reg [7:0] rd_data, output reg rd_valid,
   input wire wr_en, input wire [7:0] wr_data,
   output reg led1, output reg led2, output reg led3
);

   reg [7:0] val [3:0];
   reg [7:0] n = 0;

   initial begin
      val[0] = 0;
      val[1] = 0;
      val[2] = 0;
   end

   wire [7:0] v1 = val[0];
   wire [7:0] v2 = val[0];
   wire [7:0] v3 = val[0];

   always @(posedge clk)
   begin
      rd_valid <= 0;
      if(rd_en) begin
         rd_data <= val[addr];
         rd_valid <= 1;
      end
      if(wr_en) begin
         val[addr] <= wr_data;
      end
   end
   
   always @(posedge clk)
   begin
      n <= n + 1;
      if (n == val[0]) led1 <= 0;
      if (n == val[1]) led2 <= 0;
      if (n == val[2]) led3 <= 0;
      if (n == 0) begin
         led1 <= 1;
         led2 <= 1;
         led3 <= 1;
      end
   end

endmodule


// vi: ft=verilog ts=3 sw=3 et
