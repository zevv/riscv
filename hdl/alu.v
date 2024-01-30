
`ifndef FORMAL
`include "adder.v"
`endif

module alu(
   input [31:0] x,
   input [31:0] y,
   input [3:0] fn,
   output reg [31:0] out,
   output reg zero
);


`ifndef FORMAL
   adder adder0(
      .x(x),
      .y(y),
      .addsub(fn == 4'h8),
      .out(add_out)
   );

   wire [31:0] add_out;
`endif

   always @(*)
   begin

      out = 0;

      case (fn)
`ifdef FORMAL
         4'h0: out = x + y;
         4'h8: out = x - y;
`else
         4'h0: out = add_out; // x + y;
         4'h8: out = add_out; // x - y;
`endif
         4'h1: out = x << y[4:0];
         4'h2: out = $signed(x) < $signed(y);
         4'h3: out = x < y;
         4'h4: out = x ^ y;
         4'h5: out = x >> y[4:0];
         4'h6: out = x | y;
         4'h7: out = x & y;
         4'hd: out = $signed(x) >>> y[4:0];
      endcase

      zero = (out == 0) ? 1 : 0;

   end

endmodule

// vi: ft=verilog ts=3 sw=3 et
