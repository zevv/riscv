
`default_nettype none

`include "machine.v"

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

   reg [31:0] cycle = 0;

   always @(posedge clk) begin
      if (machine.cpu0.state == 1) begin
         cycle <= cycle + 1;
         $display("%d pc:%08x ra:%08x sp:%08x a1:%08x a2:%08x a3:%08x a4:%08x a5:%08x",
            cycle,
            machine.cpu0.pc, machine.bram0.ra, machine.bram0.sp,
            machine.bram0.a1, machine.bram0.a2, machine.bram0.a3,
            machine.bram0.a4, machine.bram0.a5);
      end
   end


   wire debug;
   wire led1, led2, led3;
   wire uart_tx;

   machine machine(
      .clk(clk),
      .debug(debug),
      .led1(led1), .led2(led2), .led3(led3),
      .uart_tx(uart_tx)
   );

endmodule


// vi: ft=verilog ts=3 sw=3 et
