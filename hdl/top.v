
`default_nettype none

`include "machine.v"


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

   SB_PLL40_CORE #(
      .FEEDBACK_PATH("SIMPLE"),
		.DIVR(4'b0010),		// DIVR =  2
		.DIVF(7'b0111111),	// DIVF = 63
		.DIVQ(3'b110),		// DIVQ =  6
		.FILTER_RANGE(3'b001)	// FILTER_RANGE = 1
	) uut (
		.LOCK(locked),
		.RESETB(1'b1),
		.BYPASS(1'b0),
		.REFERENCECLK(clk_48),
		.PLLOUTCORE(clk)
   );

   machine machine(
      .clk(clk),
      .debug(IOT_37A),
      .led1(RGB0), .led2(RGB1), .led3(RGB2),
      .uart_tx(IOB_13B)
   );


endmodule


// vi: ft=verilog ts=3 sw=3 et
