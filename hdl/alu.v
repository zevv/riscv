
`include "adder.v"

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

   adder adder0(
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
         4'h0: out = add_out; // x + y;
         4'h8: out = add_out; // x - y;
         4'h1: out = x << y[4:0];
         4'h2: out = !carry_out ^ x[W-1] ^ y[W-1]; // Hacker's Delight, p23
         4'h3: out = !carry_out;
         4'h4: out = x ^ y;
         4'h5: out = x >> y[4:0];
         4'h6: out = x | y;
         4'h7: out = x & y;
         4'hd: out = $signed(x) >>> y[4:0];
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
