

module bram(
   input wire clk,
   input wire rd_en, input wire [12:0] addr, output reg [31:0] rd_data, output reg rd_valid,
   input wire wr_en, input wire [31:0] wr_data
);

   localparam SIZE = 2048;

   reg [31:0] mem [0:SIZE-1];

   wire [31:0] zero = mem[0];
   wire [31:0] ra = mem[1];
   wire [31:0] sp = mem[2];
   wire [31:0] s0 = mem[8];
   wire [31:0] s1 = mem[9];
   wire [31:0] a0 = mem[10];
   wire [31:0] a1 = mem[11];
   wire [31:0] a2 = mem[12];
   wire [31:0] a3 = mem[13];
   wire [31:0] a4 = mem[14];
   wire [31:0] a5 = mem[15];

   initial begin
      $readmemh("../src/t.mem", mem);
   end

   always @(posedge clk)
   begin
      if (rd_en) begin
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


// vi: ft=verilog ts=3 sw=3 et
