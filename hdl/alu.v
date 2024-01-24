

module alu(
   input [31:0] v1,
   input [31:0] v2,
   input [3:0] fn,
   output reg [31:0] out,
   output reg zero,
   output reg negative
);

   always @(*)
   begin

      case (fn)
         4'h0: out = v1 + v2;
         4'h1: out = v1 << v2[4:0];
         4'h2: out = (v1 < v2) ? 1 : 0;
         4'h3: out = (v1 < v2) ? 1 : 0;
         4'h4: out = v1 ^ v2;
         4'h5: out = v1 >> v2[4:0];
         4'h6: out = v1 | v2;
         4'h7: out = v1 & v2;
         4'h8: out = v1 - v2;
         default: out= 0;
      endcase

      zero = (out == 0) ? 1 : 0;
      negative = out[31];

   end

endmodule

// vi: ft=verilog ts=3 sw=3 et
