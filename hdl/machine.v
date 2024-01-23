
`default_nettype none

/* verilator lint_off DECLFILENAME */

module machine(
   input clk,
   output debug,
   output led,
   output uart_tx
);


   wire cpu_rd_en;
   wire [15:0] addr;
   reg [31:0] cpu_rd_data;
   reg cpu_rd_valid;
   wire cpu_wr_en;
   wire [31:0] cpu_wr_data;

   cpu cpu0(
      .clk(clk),
      .o_addr(addr),
      .rd_en(cpu_rd_en), .rd_data(cpu_rd_data), .rd_valid(cpu_rd_valid),
      .wr_en(cpu_wr_en), .wr_data(cpu_wr_data),
      .debug(debug)
   );

   reg ram_rd_en = 0;
   wire [31:0] ram_rd_data;
   wire ram_rd_valid;
   reg ram_wr_en = 0;
   reg [15:0] ram_addr = 0;
   reg [31:0] ram_wr_data = 0;

   ram ram0(
      .clk(clk),
      .addr(addr),
      .rd_en(ram_rd_en), .rd_data(ram_rd_data), .rd_valid(ram_rd_valid),
      .wr_en(ram_wr_en), .wr_data(ram_wr_data)
   );


   reg led_rd_en = 0;
   wire [31:0] led_rd_data;
   wire led_rd_valid;
   reg led_wr_en = 0;
   reg [15:0] led_addr = 0;
   reg [31:0] led_wr_data = 0;

   led led0(
      .clk(clk),
      .addr(led_addr),
      .rd_en(led_rd_en), .rd_data(led_rd_data), .rd_valid(led_rd_valid),
      .wr_en(led_wr_en), .wr_data(led_wr_data), .led(led)
   );

   reg uart_rd_en = 0;
   wire [7:0] uart_rd_data;
   wire uart_rd_valid;
   reg uart_wr_en = 0;
   reg [1:0] uart_addr = 0;
   reg [7:0] uart_wr_data = 0;

   uart uart0(
      .clk(clk),
      .addr(uart_addr),
      .rd_en(uart_rd_en), .rd_data(uart_rd_data), .rd_valid(uart_rd_valid),
      .wr_en(uart_wr_en), .wr_data(uart_wr_data), .tx(uart_tx)
   );

   // Bus connections / address mapping
   
   reg ram_sel;
   reg led_sel;
   reg uart_sel;

   always @(*) begin
      
      ram_sel = (addr[15:14] == 2'b00);
      led_sel = (addr[15:14] == 2'b01);
      uart_sel = (addr[15:14] == 2'b10);

      ram_addr = addr[11:0];
      ram_rd_en = ram_sel && cpu_rd_en;
      ram_wr_en = ram_sel && cpu_wr_en;
      ram_wr_data = cpu_wr_data;

      led_addr = addr[11:0];
      led_wr_data = cpu_wr_data;
      led_rd_en = led_sel && cpu_rd_en;
      led_wr_en = led_sel && cpu_wr_en;

      uart_addr = addr[2:0];
      uart_wr_data = cpu_wr_data;
      uart_rd_en = uart_sel && cpu_rd_en;
      uart_wr_en = uart_sel && cpu_wr_en;

      cpu_rd_valid = ram_rd_valid || led_rd_valid || uart_rd_valid;

      if (ram_sel) 
         case (addr[1:0])
            2'h0: cpu_rd_data = ram_rd_data[31:0];
            2'h1: cpu_rd_data = ram_rd_data[31:8];
            2'h2: cpu_rd_data = ram_rd_data[31:16];
            2'h3: cpu_rd_data = ram_rd_data[31:24];
         endcase
      else if (led_sel) 
         cpu_rd_data = led_rd_data;
      else if (uart_sel) 
         cpu_rd_data = uart_rd_data;
      else
         cpu_rd_data = 0;

   end

endmodule



module ram(
   input wire clk,
   input wire rd_en, input wire [15:0] addr, output reg [31:0] rd_data, output reg rd_valid,
   input wire wr_en, input wire [31:0] wr_data
);

   localparam SIZE = 2048;

   reg [31:0] mem [0:SIZE-1];

   wire [31:0] zero = mem[0];
   wire [31:0] ra = mem[1];
   wire [31:0] sp = mem[2];
   wire [31:0] x8 = mem[8];
   wire [31:0] a0 = mem[10];
   wire [31:0] a1 = mem[11];
   wire [31:0] a2 = mem[12];
   wire [31:0] a3 = mem[13];
   wire [31:0] a4 = mem[14];

   initial begin
      $readmemh("../src/t.mem", mem);
   end

   always @(posedge clk)
   begin
      if (rd_en && (addr < SIZE*4)) begin
         rd_data = mem[addr >> 2];
         rd_valid <= 1;
      end else begin
         rd_valid <= 0;
      end
      if(wr_en) begin
         mem[addr>>2] <= wr_data;
      end
   end

endmodule


module led(
   input wire clk,
   input wire rd_en, input wire [15:0] addr, output reg [31:0] rd_data, output reg rd_valid,
   input wire wr_en, input wire [31:0] wr_data,
   output led
);

   reg [31:0] val = 0;

   always @(posedge clk)
   begin
      rd_valid <= 0;
      if(rd_en) begin
         if (addr == 0) begin
            //$display("LED rd %x", val);
            rd_data <= val;
            rd_valid <= 1;
         end
      end
      if(wr_en) begin
         if (addr == 0) begin
            //$display("LED wr %x", wr_data);
            val <= wr_data;
         end
      end
   end

   assign led = val[0];

endmodule


// vi: ft=verilog ts=3 sw=3 et
