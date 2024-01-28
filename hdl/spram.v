
module spram(
   input wire clk,
   input wire rd_en, input wire [14:0] addr, output [31:0] rd_data, output reg rd_valid,
   input wire wr_en, input wire [31:0] wr_data
);

   wire [13:0] spram_addr = addr >> 2;

   SB_SPRAM256KA spram_l (
      .ADDRESS(spram_addr),
      .DATAIN(wr_data[15: 0]),
      .MASKWREN(4'b1111),
      .WREN(wr_en),
      .CHIPSELECT(1'b1),
      .CLOCK(clk),
      .STANDBY(1'b0),
      .SLEEP(1'b0),
      .POWEROFF(1'b1),
      .DATAOUT(rd_data[15:0])
   );

   SB_SPRAM256KA spram_h (
      .ADDRESS(spram_addr),
      .DATAIN(wr_data[31:16]),
      .MASKWREN(4'b1111),
      .WREN(wr_en),
      .CHIPSELECT(1'b1),
      .CLOCK(clk),
      .STANDBY(1'b0),
      .SLEEP(1'b0),
      .POWEROFF(1'b1),
      .DATAOUT(rd_data[31:16])
   );

   always @(posedge clk)
   begin
      if (rd_en) begin
         rd_valid <= 1;
      end else begin
         rd_valid <= 0;
      end
   end

endmodule


// vi: ft=verilog ts=3 sw=3 et
