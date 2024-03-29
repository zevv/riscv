
`default_nettype none

`include "machine.v"
`include "/usr/share/yosys/ice40/cells_sim.v"

module test();

   integer i;
   initial begin
      $dumpfile("test.vcd");
      $dumpvars(0, test);
      for (i = 0; i < 32; i++) begin
         //$dumpvars(0, machine, machine.ram0.mem[i]);
      end
      #100000
      if (machine.cpu0.state == `ST_FAULT) begin
         for (i = 'h0; i < 'h800; i++) begin
            $display("mem %04x %08x", i * 'd4, machine.bram0.mem[i]);
         end
         //$display("FAULT at %08x: %08x", machine.cpu0.pc, machine.cpu0.inst);
      end

      $finish;
   end


	reg clk = 0;

   always #1 begin
      clk = !clk;
   end

   reg [31:0] cycle = 0;

   always @(posedge clk) begin
      if (0 && machine.cpu0.state == 1) begin
         cycle <= cycle + 1;
         $display("%d pc:%08x ra:%08x sp:%08x a1:%08x a2:%08x a3:%08x a4:%08x a5:%08x",
            cycle,
            machine.cpu0.pc, machine.bram0.reg_ra, machine.bram0.reg_sp,
            machine.bram0.reg_a1, machine.bram0.reg_a2, machine.bram0.reg_a3,
            machine.bram0.reg_a4, machine.bram0.reg_a5);
      end
   end


   wire debug;
   wire led1, led2, led3;
   wire uart_tx;
   reg uart_rx;

   machine machine(
      .clk(clk),
      .debug(debug),
      .led1(led1), .led2(led2), .led3(led3),
      .uart_tx(uart_tx),
      .uart_rx(uart_rx)
   );

//   initial begin
//      uart_rx = 1;
//      #200000
//      // send out ascii 'h', one stop bit, 8 data bits, no parity, idle high.
//      // ascii 'h' is binary 01101000, so we send 0001101000
//      #16 uart_rx = 0;
//      #16 uart_rx = 0;
//      #16 uart_rx = 1;
//      #16 uart_rx = 1;
//      #16 uart_rx = 1;
//      #16 uart_rx = 1;
//      #16 uart_rx = 0;
//      #16 uart_rx = 1;
//      #16 uart_rx = 0;
//      #16 uart_rx = 1;
//   end
//
endmodule


// vi: ft=verilog ts=3 sw=3 et
