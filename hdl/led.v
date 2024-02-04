`default_nettype none

module led(
   input wire clk,
   input wire ren, input wire [4:0] addr, output reg [7:0] rdata, output reg rd_valid,
   input wire wen, input wire [7:0] wdata,
   output reg led1, output reg led2, output reg led3
);

   reg [7:0] n = 0;
   reg [7:0] val1 = 0;
   reg [7:0] val2 = 0;
   reg [7:0] val3 = 0;

   always @(posedge clk)
   begin
      rd_valid <= 0;
      if(ren) begin
         case (addr)
            0: rdata <= val1;
            4: rdata <= val2;
            8: rdata <= val3;
         endcase
         rd_valid <= 1;
      end
      if(wen) begin
         case (addr)
            0: val1 <= wdata;
            4: val2 <= wdata;
            8: val3 <= wdata;
         endcase
      end
   end
   
   always @(posedge clk)
   begin
      n <= n + 1;
      if (n == val1) led1 <= 1;
      if (n == val2) led2 <= 1;
      if (n == val3) led3 <= 1;
      if (n == 0) begin
         led1 <= 0;
         led2 <= 0;
         led3 <= 0;
      end
   end

endmodule


// vi: ft=verilog ts=3 sw=3 et
