

module bram
#(
   parameter W = 32
)
(
   input wire clk,
   input wire rd_en, input wire [12:0] addr, output reg [31:0] rd_data, output reg rd_valid,
   input wire wr_en, input wire [W-1:0] wr_data, input [3:0] wr_mask
);

   localparam SIZE = 2048;

   reg [31:0] mem [0:SIZE-1];
   wire [10:0] addr32 = (addr >> 2);

   initial begin
      $readmemh("bram.mem", mem);
   end

   always @(posedge clk)
   begin
      if (rd_en) begin
         rd_data = mem[addr32];
         rd_valid <= 1;
      end else begin
         rd_valid <= 0;
      end
      if(wr_en) begin
         if (W >  0 && wr_mask[3]) mem[addr32][7:0] <= wr_data[7:0];
         if (W >  8 && wr_mask[2]) mem[addr32][15:8] <= wr_data[15:8];
         if (W > 16)
            if(wr_mask[1]) mem[addr32][23:16] <= wr_data[23:16];
         if (W > 24)
            if( wr_mask[0]) mem[addr32][31:24] <= wr_data[31:24];
      end
   end

endmodule


// vi: ft=verilog ts=3 sw=3 et
