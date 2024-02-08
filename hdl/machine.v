
`default_nettype none

`include "cpu.v"
`include "led.v"
`include "uart.v"
`include "bram.v"
`include "spram.v"

/* verilator lint_off DECLFILENAME */

module machine
#(
   parameter W = 32
)
(
   input clk,
   output debug,
   output led1, output led2, output led3,
   output uart_tx,
   input uart_rx
);


   wire cpu_ren;
   wire [15:0] addr;
   reg [31:0] cpu_rdata;
   reg cpu_rd_valid;
   wire cpu_wen;
   wire [W-1:0] cpu_wdata;
   wire [3:0] cpu_wmask;

   cpu #(.W(W)) cpu0(
      .clk(clk),
      .addr(addr),
      .ren(cpu_ren), .rdata(cpu_rdata), .rd_valid(cpu_rd_valid),
      .wen(cpu_wen), .wdata(cpu_wdata), .wmask(cpu_wmask),
      .debug(debug)
   );


   reg bram_ren = 0;
   wire [31:0] bram_rdata;
   wire bram_rd_valid;
   reg bram_wen = 0;
   reg [12:0] bram_addr = 0;
   reg [W-1:0] bram_wdata = 0;

   bram #(.W(W)) bram0(
      .clk(clk),
      .addr(bram_addr),
      .ren(bram_ren), .rdata(bram_rdata), .rd_valid(bram_rd_valid),
      .wen(bram_wen), .wdata(bram_wdata), .wmask(cpu_wmask)
   );


   reg spram_ren = 0;
   wire [W-1:0] spram_rdata;
   wire spram_rd_valid;
   reg spram_wen = 0;
   reg [14:0] spram_addr = 0;
   reg [W-1:0] spram_wdata = 0;

   spram #(.W(W)) spram0(
      .clk(clk),
      .addr(spram_addr),
      .ren(spram_ren), .rdata(spram_rdata), .rd_valid(spram_rd_valid),
      .wen(spram_wen), .wdata(spram_wdata)
   );


   reg led_ren = 0;
   wire [7:0] led_rdata;
   wire led_rd_valid;
   reg led_wen = 0;
   reg [4:0] led_addr = 0;
   reg [7:0] led_wdata = 0;

   led led0(
      .clk(clk),
      .addr(led_addr),
      .ren(led_ren), .rdata(led_rdata), .rd_valid(led_rd_valid),
      .wen(led_wen), .wdata(led_wdata), .led1(led1), .led2(led2), .led3(led3)
   );

   reg uart_ren = 0;
   wire [7:0] uart_rdata;
   wire uart_rd_valid;
   reg uart_wen = 0;
   reg [4:0] uart_addr = 0;
   reg [7:0] uart_wdata = 0;

   uart uart0(
      .clk(clk),
      .addr(uart_addr),
      .ren(uart_ren), .rdata(uart_rdata), .rd_valid(uart_rd_valid),
      .wen(uart_wen), .wdata(uart_wdata),
      .tx(uart_tx), .rx(uart_rx)
   );

   // Bus connections / address mapping
   
   reg bram_sel;
   reg spram_sel;
   reg led_sel;
   reg uart_sel;

   always @(*) begin
      
      bram_sel  = (addr[15:14] == 2'b00);
      led_sel   = (addr[15:12] == 4'b0100);
      uart_sel  = (addr[15:12] == 4'b0101);
      spram_sel = (addr[15:15] == 1'b1);
      
      bram_ren = bram_sel && cpu_ren;
      spram_ren = spram_sel && cpu_ren;
      led_ren = led_sel && cpu_ren;
      uart_ren = uart_sel && cpu_ren;

      bram_wen = bram_sel && cpu_wen;
      spram_wen = spram_sel && cpu_wen;
      led_wen = led_sel && cpu_wen;
      uart_wen = uart_sel && cpu_wen;
      
      bram_addr = addr[11:0];
      spram_addr = addr[14:0];
      led_addr = addr[4:0];
      uart_addr = addr[2:0];

      bram_wdata = cpu_wdata;
      spram_wdata = cpu_wdata;
      led_wdata = cpu_wdata;
      uart_wdata = cpu_wdata;

      cpu_rd_valid = bram_rd_valid || spram_rd_valid || led_rd_valid || uart_rd_valid;

      case(1'b1)
         bram_sel:  cpu_rdata = bram_rdata;
         spram_sel: cpu_rdata = spram_rdata;
         led_sel:   cpu_rdata = led_rdata;
         uart_sel:  cpu_rdata = uart_rdata;
         default:   cpu_rdata = 0;
      endcase

   end

endmodule


// vi: ft=verilog ts=3 sw=3 et
