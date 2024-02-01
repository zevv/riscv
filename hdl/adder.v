`ifdef FORMAL
`include "cells_sim.v"
`endif


module adder
(
   input [31:0] x,
   input [31:0] y,
   input addsub,
   output [31:0] out,
   output carry_out
);

   // ICE40 MAC_16 DSP configured as a 32 but adder/subtractor
   SB_MAC16 #(
      .C_REG(1'b0), .A_REG(1'b0), .B_REG(1'b0), .D_REG(1'b0),
      .TOP_8x8_MULT_REG(1'b0), .BOT_8x8_MULT_REG(1'b0),
      .PIPELINE_16x16_MULT_REG1(1'b0), .PIPELINE_16x16_MULT_REG2(1'b0),
      .TOPOUTPUT_SELECT(2'b00), .TOPADDSUB_LOWERINPUT(2'b00), .TOPADDSUB_UPPERINPUT(1'b1), .TOPADDSUB_CARRYSELECT(2'b10),
      .BOTOUTPUT_SELECT(2'b00), .BOTADDSUB_LOWERINPUT(2'b00), .BOTADDSUB_UPPERINPUT(1'b1), .BOTADDSUB_CARRYSELECT(2'b00),
      .MODE_8x8(1),
      .A_SIGNED(1'b0), .B_SIGNED(1'b0))
      SB_MAC16_inst(
         .CLK(1'b0), .CE(1'b0),
         .B(y[15:0]), .A(y[31:16]), .D(x[15:0]), .C(x[31:16]),
         .IRSTTOP(1'b0), .IRSTBOT(1'b0), .ORSTTOP(1'b0), .ORSTBOT(1'b0),
         .AHOLD(1'b0), .BHOLD(1'b0), .CHOLD(1'b0), .DHOLD(1'b0),
         .OHOLDTOP(1'b0), .OHOLDBOT(1'b0),
         .ADDSUBTOP(addsub), .ADDSUBBOT(addsub),
         .OLOADTOP(1'b0), .OLOADBOT(1'b0),
         .CI(1'b0), .ACCUMCI(1'b0),
         .SIGNEXTIN(1'b0),
         .O(out), .CO(carry_out)
      );

endmodule

// vi: ft=verilog ts=3 sw=3 et
