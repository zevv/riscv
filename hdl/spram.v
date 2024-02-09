
module spram
#(
   parameter W = 32
)
(
   input wire clk,
   input wire ren, input wire [14:0] addr, output [W-1:0] rdata, output reg rd_valid,
   input wire wen, input wire [W-1:0] wdata, input wire[3:0] wmask
);

   wire [13:0] spram_addr = addr >> 2;
   wire [3:0] wmask_l = { wmask[2], wmask[2], wmask[3], wmask[3] };
   wire [3:0] wmask_h = { wmask[0], wmask[0], wmask[1], wmask[1] };

   SB_SPRAM256KA spram_l (
      .ADDRESS(spram_addr),
      .DATAIN(wdata[15: 0]),
      .MASKWREN(wmask_l),
      .WREN(wen),
      .CHIPSELECT(1'b1),
      .CLOCK(clk),
      .STANDBY(1'b0),
      .SLEEP(1'b0),
      .POWEROFF(1'b1),
      .DATAOUT(rdata[15:0])
   );

   generate
      if (W > 16) begin
         SB_SPRAM256KA spram_h (
            .ADDRESS(spram_addr),
            .DATAIN(wdata[31:16]),
            .MASKWREN(wmask_h),
            .WREN(wen),
            .CHIPSELECT(1'b1),
            .CLOCK(clk),
            .STANDBY(1'b0),
            .SLEEP(1'b0),
            .POWEROFF(1'b1),
            .DATAOUT(rdata[W-1:16])
         );
      end
   endgenerate


   always @(posedge clk)
   begin
      if (ren) begin
         rd_valid <= 1;
      end else begin
         rd_valid <= 0;
      end
   end

endmodule


// vi: ft=verilog ts=3 sw=3 et
