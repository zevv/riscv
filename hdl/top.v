
`default_nettype none

`include "machine.v"
`include "pll.v"


module top(
   output IOB_8A, output IOB_23B,
   output IOB_9B,
   output RGB0, RGB1, RGB2,
   output IOT_37A,
   output IOT_41A,
   output IOB_13B,
   input IOT_50B,
);
   
   wire clk_48;
   
   SB_HFOSC SB_HFOSC_inst(
      .CLKHFEN(1),
      .CLKHFPU(1),
      .CLKHF(clk_48)
   );

   wire clk;
   wire locked;

   pll pll0(
      .clock_in(clk_48),
      .clock_out(clk),
      .locked(locked)
   );

   machine machine(
      .clk(clk),
      .debug(IOT_37A),
      .led1(RGB0), .led2(RGB1), .led3(RGB2),
      .uart_tx(IOB_13B)
   );


endmodule


// vi: ft=verilog ts=3 sw=3 et
