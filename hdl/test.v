
`include "cpu.v"

module test();

   integer i;
   initial begin
      $dumpfile("test.vcd");
      $dumpvars(0, test);
      for (i = 0; i < 32; i++) begin
         $dumpvars(0, machine, machine.cpu0.x[i]);
      end
      #2000
      $finish;
   end


	reg clk = 0;

   always #1 begin
      clk = !clk;
   end

   wire debug;

   machine machine(
      .clk(clk),
      .debug(debug)
   );

endmodule


// vi: ft=verilog ts=3 sw=3 et
