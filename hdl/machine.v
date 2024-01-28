
`default_nettype none

`include "cpu.v"
`include "led.v"
`include "uart.v"
`include "bram.v"
`include "spram.v"

/* verilator lint_off DECLFILENAME */

module machine(
   input clk,
   output debug,
   output led1, output led2, output led3,
   output uart_tx
);


   wire cpu_rd_en;
   wire [15:0] addr;
   reg [31:0] cpu_rd_data;
   reg cpu_rd_valid;
   wire cpu_wr_en;
   wire [31:0] cpu_wr_data;
   wire [3:0] cpu_wr_mask;

   cpu cpu0(
      .clk(clk),
      .o_addr(addr),
      .rd_en(cpu_rd_en), .rd_data(cpu_rd_data), .rd_valid(cpu_rd_valid),
      .wr_en(cpu_wr_en), .wr_data(cpu_wr_data), .wr_mask(cpu_wr_mask),
      .debug(debug)
   );


   reg bram_rd_en = 0;
   wire [31:0] bram_rd_data;
   wire bram_rd_valid;
   reg bram_wr_en = 0;
   reg [12:0] bram_addr = 0;
   reg [31:0] bram_wr_data = 0;

   bram bram0(
      .clk(clk),
      .addr(bram_addr),
      .rd_en(bram_rd_en), .rd_data(bram_rd_data), .rd_valid(bram_rd_valid),
      .wr_en(bram_wr_en), .wr_data(bram_wr_data), .wr_mask(cpu_wr_mask)
   );


   reg spram_rd_en = 0;
   wire [31:0] spram_rd_data;
   wire spram_rd_valid;
   reg spram_wr_en = 0;
   reg [14:0] spram_addr = 0;
   reg [31:0] spram_wr_data = 0;

   spram spram0(
      .clk(clk),
      .addr(spram_addr),
      .rd_en(spram_rd_en), .rd_data(spram_rd_data), .rd_valid(spram_rd_valid),
      .wr_en(spram_wr_en), .wr_data(spram_wr_data)
   );


   reg led_rd_en = 0;
   wire [7:0] led_rd_data;
   wire led_rd_valid;
   reg led_wr_en = 0;
   reg [1:0] led_addr = 0;
   reg [7:0] led_wr_data = 0;

   led led0(
      .clk(clk),
      .addr(led_addr),
      .rd_en(led_rd_en), .rd_data(led_rd_data), .rd_valid(led_rd_valid),
      .wr_en(led_wr_en), .wr_data(led_wr_data), .led1(led1), .led2(led2), .led3(led3)
   );

   reg uart_rd_en = 0;
   wire [7:0] uart_rd_data;
   wire uart_rd_valid;
   reg uart_wr_en = 0;
   reg [1:0] uart_addr = 0;
   reg [7:0] uart_wr_data = 0;

   uart uart0(
      .clk(clk),
      .addr(uart_addr),
      .rd_en(uart_rd_en), .rd_data(uart_rd_data), .rd_valid(uart_rd_valid),
      .wr_en(uart_wr_en), .wr_data(uart_wr_data), .tx(uart_tx)
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
      
      bram_rd_en = bram_sel && cpu_rd_en;
      spram_rd_en = spram_sel && cpu_rd_en;
      led_rd_en = led_sel && cpu_rd_en;
      uart_rd_en = uart_sel && cpu_rd_en;

      bram_wr_en = bram_sel && cpu_wr_en;
      spram_wr_en = spram_sel && cpu_wr_en;
      led_wr_en = led_sel && cpu_wr_en;
      uart_wr_en = uart_sel && cpu_wr_en;
      
      bram_addr = addr[11:0];
      spram_addr = addr[14:0];
      led_addr = addr[1:0];
      uart_addr = addr[2:0];

      bram_wr_data = cpu_wr_data;
      spram_wr_data = cpu_wr_data;
      led_wr_data = cpu_wr_data;
      uart_wr_data = cpu_wr_data;

      cpu_rd_valid = bram_rd_valid || spram_rd_valid || led_rd_valid || uart_rd_valid;

      if (bram_sel) 
         cpu_rd_data = bram_rd_data;
      else if (spram_sel)
         cpu_rd_data = spram_rd_data;
      else if (led_sel) 
         cpu_rd_data = led_rd_data;
      else if (uart_sel) 
         cpu_rd_data = uart_rd_data;
      else
         cpu_rd_data = 0;

   end

endmodule


// vi: ft=verilog ts=3 sw=3 et
