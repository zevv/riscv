
`include "adder.v"
`include "common.v"

module alu
#(
   parameter W = 32
)
(
   input [W-1:0] x,
   input [W-1:0] y,
   input [3:0] fn,
   output reg [W-1:0] out,
   output reg zero
);

   adder #(W) adder0(
      .x(x),
      .y(y),
      .addsub(fn == 4'h8 || fn == 4'h2 || fn == 4'h3),
      .out(add_out),
      .carry_out(carry_out)
   );

   wire [W-1:0] add_out;
   wire carry_out;

   always @(*)
   begin

      out = 0;

      case (fn)
         `ALU_FN_ADD : out = add_out; // x + y;
         `ALU_FN_SUB : out = add_out; // x - y;
         `ALU_FN_SLL : out = x << y[4:0];
         `ALU_FN_LT  : out = !carry_out ^ x[W-1] ^ y[W-1]; // Hacker's Delight, p23
         `ALU_FN_LTU : out = !carry_out;
         `ALU_FN_XOR : out = x ^ y;
         `ALU_FN_SRL : out = x >> y[4:0];
         `ALU_FN_OR  : out = x | y;
         `ALU_FN_AND : out = x & y;
         `ALU_FN_SRA : out = $signed(x) >>> y[4:0];
      endcase

      zero = (out == 0) ? 1 : 0;

   end

`ifdef FORMAL
   
   always @(*)
   begin
      if (fn == 4'h0)
         assert (out == x + y);
      if (fn == 4'h8)
         assert (out == x - y);
      if (fn == 4'h2)
         assert (out == ($signed(x) < $signed(y)));
      if (fn == 4'h3)
         assert (out == (x < y));
   end
`endif


endmodule

// vi: ft=verilog ts=3 sw=3 et
