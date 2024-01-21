
`include "machine.v"
`include "cpu.v"

module test();

   integer i;
   initial begin
      $dumpfile("test.vcd");
      $dumpvars(0, test);
      for (i = 0; i < 32; i++) begin
         //$dumpvars(0, machine, machine.ram0.memory[i]);
      end
      #2000
      $finish;
   end


	reg clk = 0;

   always #1 begin
      clk = !clk;
   end

   wire debug;
   wire led;

   machine machine(
      .clk(clk),
      .debug(debug),
      .led(led)
   );

endmodule


// vi: ft=verilog ts=3 sw=3 et
