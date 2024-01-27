
`include "adder.v"

module alu(
   input [31:0] x,
   input [31:0] y,
   input [3:0] fn,
   output reg [31:0] out,
   output reg zero
);


   adder add(
      .x(x),
      .y(y),
      .addsub(1'b0),
      .out(add_out)
   );

   adder sub(
      .x(x),
      .y(y),
      .addsub(1'b1),
      .out(sub_out)
   );

   wire [31:0] add_out;
   wire [31:0] sub_out;
   wire [31:0] lt = sub_out ^ ((x ^ y) & (sub_out ^ x));

   always @(*)
   begin

      case (fn)
         4'h0: out = add_out; // x + y;
         4'h1: out = x << y[4:0];
         4'h2: out = lt[31];
         4'h3: out = lt[31];
         4'h4: out = x ^ y;
         4'h5: out = x >> y[4:0];
         4'h6: out = x | y;
         4'h7: out = x & y;
         4'h8: out = sub_out; // x - y;
         default: out= 0;
      endcase

      zero = (out == 0) ? 1 : 0;

   end

endmodule

// vi: ft=verilog ts=3 sw=3 et
