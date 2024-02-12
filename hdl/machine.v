
`default_nettype none

`include "cpu.v"
`include "led.v"
`include "uart.v"
`include "bram.v"
`include "spram.v"
`include "spiflash.v"

/* verilator lint_off DECLFILENAME */

module machine
#(
   parameter W = 32
)
(
   input clk,
   output debug,
   output led1, output led2, output led3,
   output uart_tx, input uart_rx,
   output spi_ss, input spi_miso, output spi_mosi, output spi_sck
);


   wire ren;
   wire [15:0] addr;
   reg [31:0] rdata;
   reg rd_valid;
   wire wen;
   wire [W-1:0] wdata;
   wire [3:0] wmask;

   cpu #(.W(W)) cpu0(
      .clk(clk),
      .addr(addr),
      .ren(ren), .rdata(rdata), .rd_valid(rd_valid),
      .wen(wen), .wdata(wdata), .wmask(wmask),
      .debug(debug)
   );

   wire [31:0] bram_rdata;
   wire bram_rd_valid;

   bram #(.W(W)) bram0(
      .clk(clk),
      .addr(addr[12:0]),
      .ren(bram_sel && ren), .rdata(bram_rdata), .rd_valid(bram_rd_valid),
      .wen(bram_sel && wen), .wdata(wdata), .wmask(wmask)
   );

   wire [W-1:0] spram_rdata;
   wire spram_rd_valid;

   spram #(.W(W)) spram0(
      .clk(clk),
      .addr(addr[14:0]),
      .ren(spram_sel && ren), .rdata(spram_rdata), .rd_valid(spram_rd_valid),
      .wen(spram_sel && wen), .wdata(wdata), .wmask(wmask)
   );

   wire [7:0] led_rdata;
   wire led_rd_valid;

   led led0(
      .clk(clk),
      .addr(addr[4:0]),
      .ren(led_sel && ren), .rdata(led_rdata), .rd_valid(led_rd_valid),
      .wen(led_sel && wen), .wdata(wdata[7:0]),
      .led1(led1), .led2(led2), .led3(led3)
   );

   wire [7:0] uart_rdata;
   wire uart_rd_valid;

   uart uart0(
      .clk(clk),
      .addr(addr[4:0]),
      .ren(uart_sel && ren), .rdata(uart_rdata), .rd_valid(uart_rd_valid),
      .wen(uart_sel && wen), .wdata(wdata[7:0]),
      .tx(uart_tx), .rx(uart_rx)
   );

   wire [31:0] spiflash_rdata;
   wire spiflash_rd_valid;

   spiflash spiflash0(
      .clk(clk),
      .addr(addr),
      .ren(spiflash_sel && ren), .rdata(spiflash_rdata), .rd_valid(spiflash_rd_valid),
      .wen(spiflash_sel && wen), .wdata(wdata), 
      .ss(spi_ss), .miso(spi_miso), .mosi(spi_mosi), .sck(spi_sck)
   );

   // Bus connections / address mapping

   reg bram_sel;
   reg spram_sel;
   reg led_sel;
   reg uart_sel;
   reg spiflash_sel;

   always @(*) begin

      bram_sel     = (addr[15:14] == 2'b00);
      led_sel      = (addr[15:12] == 4'b0100);
      uart_sel     = (addr[15:12] == 4'b0101);
      spram_sel    = (addr[15:15] == 1'b1);
      spiflash_sel = (addr[15:12] == 4'b0110);

      rd_valid = bram_rd_valid || spram_rd_valid || led_rd_valid || uart_rd_valid || spiflash_rd_valid;

      case(1'b1)
         bram_sel:     rdata = bram_rdata;
         spram_sel:    rdata = spram_rdata;
         led_sel:      rdata = led_rdata;
         uart_sel:     rdata = uart_rdata;
         spiflash_sel: rdata = spiflash_rdata;
         default:      rdata = 0;
      endcase

   end

endmodule


// vi: ft=verilog ts=3 sw=3 et
