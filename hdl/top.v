
`default_nettype none

`include "machine.v"
`include "pll.v"


module top(
   output RGB0, RGB1, RGB2,
   output IOB_13B,
   output IOT_37A,
);
   
   wire clk_48;
   
   SB_HFOSC SB_HFOSC_inst(
      .CLKHFEN(1'b1),
      .CLKHFPU(1'b1),
      .CLKHF(clk_48)
   );

   wire clk;
   wire locked;

   pll pll0(
      .clock_in(clk_48),
      .clock_out(clk),
      .locked(locked)
   );

   wire dummy;

   reg clk2 = 0;
   always @(posedge clk)
      clk2 <= ~clk2;

   machine machine(
      .clk(clk2),
      .debug(IOT_37A),
      .led1(RGB0), .led2(RGB1), .led3(RGB2),
      .uart_tx(IOB_13B)
   );


endmodule


// vi: ft=verilog ts=3 sw=3 et
