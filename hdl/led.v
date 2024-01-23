`default_nettype none

module led(
   input wire clk,
   input wire rd_en, input wire [15:0] addr, output reg [31:0] rd_data, output reg rd_valid,
   input wire wr_en, input wire [31:0] wr_data,
   output led
);

   reg [31:0] val = 0;

   always @(posedge clk)
   begin
      rd_valid <= 0;
      if(rd_en) begin
         if (addr == 0) begin
            //$display("LED rd %x", val);
            rd_data <= val;
            rd_valid <= 1;
         end
      end
      if(wr_en) begin
         if (addr == 0) begin
            //$display("LED wr %x", wr_data);
            val <= wr_data;
         end
      end
   end

   assign led = val[0];

endmodule


// vi: ft=verilog ts=3 sw=3 et
