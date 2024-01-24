
`include "adder.v"

module alu(
   input [31:0] x,
   input [31:0] y,
   input [3:0] fn,
   output reg [31:0] out,
   output reg zero
);


   adder adder_inst(
      .x(x),
      .y(y),
      .addsub(addsub),
      .out(mac_out)
   );

   wire [31:0] mac_out;
   wire addsub = (fn == 4'h8 || fn == 4'h2 || fn == 4'h3) ? 1 : 0;
   wire [31:0] lt = mac_out ^ ((x ^ y) & (mac_out ^ x));

   always @(*)
   begin

      case (fn)
         4'h0: out = mac_out; // x + y;
         4'h1: out = x << y[4:0];
         4'h2: out = lt[31];
         4'h3: out = lt[31];
         4'h4: out = x ^ y;
         4'h5: out = x >> y[4:0];
         4'h6: out = x | y;
         4'h7: out = x & y;
         4'h8: out = mac_out; // x - y;
         default: out= 0;
      endcase

      zero = (out == 0) ? 1 : 0;

   end

endmodule

// vi: ft=verilog ts=3 sw=3 et
