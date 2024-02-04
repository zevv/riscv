
module spram
#(
   parameter W = 32
)
(
   input wire clk,
   input wire ren, input wire [14:0] addr, output [W-1:0] rdata, output reg rd_valid,
   input wire wen, input wire [W-1:0] wdata
);

   wire [13:0] spram_addr = addr >> 2;

   SB_SPRAM256KA spram_l (
      .ADDRESS(spram_addr),
      .DATAIN(wdata[15: 0]),
      .MASKWREN(4'b1111),
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
            .MASKWREN(4'b1111),
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
