

module bram
#(
   parameter W = 32
)
(
   input wire clk,
   input wire ren, input wire [12:0] addr, output reg [31:0] rdata, output reg rd_valid,
   input wire wen, input wire [W-1:0] wdata, input [3:0] wmask
);

   localparam SIZE = 2048;

   reg [31:0] mem [0:SIZE-1];
   wire [10:0] addr32 = (addr >> 2);

   initial begin
      $readmemh("bram.mem", mem);
   end

   always @(posedge clk)
   begin
      if (ren) begin
         rdata = mem[addr32];
         rd_valid <= 1;
      end else begin
         rd_valid <= 0;
      end
      if(wen) begin
         if (W >  0 && wmask[3]) mem[addr32][7:0] <= wdata[7:0];
         if (W >  8 && wmask[2]) mem[addr32][15:8] <= wdata[15:8];
         if (W > 16)
            if(wmask[1]) mem[addr32][23:16] <= wdata[23:16];
         if (W > 24)
            if( wmask[0]) mem[addr32][31:24] <= wdata[31:24];
      end
   end

endmodule


// vi: ft=verilog ts=3 sw=3 et
