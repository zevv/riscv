
`default_nettype none

/* verilator lint_off DECLFILENAME */

module machine(
   input clk,
   output debug,
   output led
);

   reg ram_rd_en = 0;
   reg [15:0] ram_rd_addr;
   wire [31:0] ram_rd_data;
   wire ram_rd_valid;
   reg ram_wr_en = 0;
   reg [15:0] ram_wr_addr = 0;
   reg [31:0] ram_wr_data = 0;

   ram ram0(
      .clk(clk),
      .rd_en(ram_rd_en), .rd_addr(ram_rd_addr), .rd_data(ram_rd_data), .rd_valid(ram_rd_valid),
      .wr_en(ram_wr_en), .wr_addr(ram_wr_addr), .wr_data(ram_wr_data)
   );


   reg led_rd_en = 0;
   reg [15:0] led_rd_addr;
   wire [31:0] led_rd_data;
   wire led_rd_valid;
   reg led_wr_en = 0;
   reg [15:0] led_wr_addr = 0;
   reg [31:0] led_wr_data = 0;

   led led0(
      .clk(clk),
      .rd_en(led_rd_en), .rd_addr(led_rd_addr), .rd_data(led_rd_data), .rd_valid(led_rd_valid),
      .wr_en(led_wr_en), .wr_addr(led_wr_addr), .wr_data(led_wr_data), .led(led)
   );


   wire cpu_rd_en;
   wire [15:0] cpu_rd_addr;
   reg [31:0] cpu_rd_data;
   reg cpu_rd_valid;
   wire cpu_wr_en;
   wire [15:0] cpu_wr_addr;
   wire [31:0] cpu_wr_data;

   cpu cpu0(
      .clk(clk),
      .rd_en(cpu_rd_en), .rd_addr(cpu_rd_addr), .rd_data(cpu_rd_data), .rd_valid(cpu_rd_valid),
      .wr_en(cpu_wr_en), .wr_addr(cpu_wr_addr), .wr_data(cpu_wr_data), .debug(debug)
   );


   // Bus connections / address mapping

   always @(*) begin
      
      cpu_rd_valid = 0;
      cpu_rd_data = 0;

      ram_rd_en = 0;
      ram_rd_addr = 0;
      ram_wr_en = 0;
      ram_wr_addr = 0;
      ram_wr_data = 0;

      led_rd_en = 0;
      led_wr_en = 0;
      led_rd_addr = 0;
      led_wr_addr = 0;
      led_wr_data = 0;

      if (cpu_rd_en) begin

         if (cpu_rd_addr[15:12] == 4'h0) begin
            ram_rd_en = cpu_rd_en;
            ram_rd_addr = cpu_rd_addr[11:0];
         end 
      
         if (cpu_rd_addr[15:12] == 4'b1) begin
            led_rd_en = cpu_rd_en;
            led_rd_addr = cpu_rd_addr[11:0];
         end 
      end

      if (cpu_wr_en) begin

         if(cpu_wr_addr[15:12] == 4'h0) begin
            ram_wr_en = cpu_wr_en;
            ram_wr_addr = cpu_wr_addr[11:0];
            ram_wr_data = cpu_wr_data;
         end
         
         if (cpu_wr_addr[15:12] == 4'b1) begin
            led_wr_en = cpu_wr_en;
            led_wr_addr = cpu_wr_addr[11:0];
            led_wr_data = cpu_wr_data;
         end
      end

      if(ram_rd_valid) begin
         cpu_rd_data = ram_rd_data;
         cpu_rd_valid = ram_rd_valid;
      end

      if(led_rd_valid) begin
         cpu_rd_data = led_rd_data;
         cpu_rd_valid = led_rd_valid;
      end

   end

endmodule



module ram(
   input wire clk,
   input wire rd_en, input wire [15:0] rd_addr, output reg [31:0] rd_data, output reg rd_valid,
   input wire wr_en, input wire [15:0] wr_addr, input wire [31:0] wr_data
);

   localparam SIZE = 512;

   reg [7:0] mem0 [0:SIZE-1];
   reg [7:0] mem1 [0:SIZE-1];
   reg [7:0] mem2 [0:SIZE-1];
   reg [7:0] mem3 [0:SIZE-1];

   initial begin
      $readmemh("../src/t.mem.0", mem0);
      $readmemh("../src/t.mem.1", mem1);
      $readmemh("../src/t.mem.2", mem2);
      $readmemh("../src/t.mem.3", mem3);
   end

   always @(posedge clk)
   begin
      if (rd_en && (rd_addr < SIZE*4)) begin
         rd_data <= { mem3[rd_addr>>2], mem2[rd_addr>>2], mem1[rd_addr>>2], mem0[rd_addr>>2] };
         rd_valid <= 1;
      end else begin
         rd_valid <= 0;
      end
      if(wr_en) begin
         { mem3[wr_addr>>2], mem2[wr_addr>>2], mem1[wr_addr>>2], mem0[wr_addr>>2] } <= wr_data;
      end
   end

endmodule


module led(
   input wire clk,
   input wire rd_en, input wire [15:0] rd_addr, output reg [31:0] rd_data, output reg rd_valid,
   input wire wr_en, input wire [15:0] wr_addr, input wire [31:0] wr_data,
   output led
);

   reg [31:0] val = 0;

   always @(posedge clk)
   begin
      rd_valid <= 0;
      if(rd_en) begin
         if (rd_addr == 0) begin
            //$display("LED rd %x", val);
            rd_data <= val;
            rd_valid <= 1;
         end
      end
      if(wr_en) begin
         if (wr_addr == 0) begin
            //$display("LED wr %x", wr_data);
            val <= wr_data;
         end
      end
   end

   assign led = val[16];

endmodule


// vi: ft=verilog ts=3 sw=3 et
