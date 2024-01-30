`default_nettype none

module led(
   input wire clk,
   input wire rd_en, input wire [4:0] addr, output reg [7:0] rd_data, output reg rd_valid,
   input wire wr_en, input wire [7:0] wr_data,
   output reg led1, output reg led2, output reg led3
);

   reg [7:0] n = 0;
   reg [7:0] val1 = 0;
   reg [7:0] val2 = 0;
   reg [7:0] val3 = 0;

   always @(posedge clk)
   begin
      rd_valid <= 0;
      if(rd_en) begin
         case (addr)
            0: rd_data <= val1;
            4: rd_data <= val2;
            8: rd_data <= val3;
         endcase
         rd_valid <= 1;
      end
      if(wr_en) begin
         case (addr)
            0: val1 <= wr_data;
            4: val2 <= wr_data;
            8: val3 <= wr_data;
         endcase
      end
   end
   
   always @(posedge clk)
   begin
      n <= n + 1;
      if (n == val1) led1 <= 0;
      if (n == val2) led2 <= 0;
      if (n == val3) led3 <= 0;
      if (n == 0) begin
         led1 <= 1;
         led2 <= 1;
         led3 <= 1;
      end
   end

endmodule


// vi: ft=verilog ts=3 sw=3 et
