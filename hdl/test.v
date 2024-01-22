
`include "machine.v"
`include "cpu.v"
`include "uart.v"

module test();

   integer i;
   initial begin
      $dumpfile("test.vcd");
      $dumpvars(0, test);
      for (i = 0; i < 32; i++) begin
         //$dumpvars(0, machine, machine.ram0.mem[i]);
      end
      #20000
      $finish;
   end


	reg clk = 0;

   always #1 begin
      clk = !clk;
   end

   wire debug;
   wire led;
   wire uart_tx;

   machine machine(
      .clk(clk),
      .debug(debug),
      .led(led),
      .uart_tx(uart_tx)
   );

endmodule


// vi: ft=verilog ts=3 sw=3 et
