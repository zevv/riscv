

module bram(
   input wire clk,
   input wire rd_en, input wire [12:0] addr, output reg [31:0] rd_data, output reg rd_valid,
   input wire wr_en, input wire [31:0] wr_data
);

   localparam SIZE = 2048;

   reg [31:0] mem [0:SIZE-1];

   wire [31:0] reg_zero   = mem['h00];
 	wire [31:0] reg_ra     = mem['h01];
 	wire [31:0] reg_sp     = mem['h02];
 	wire [31:0] reg_gp     = mem['h03];
 	wire [31:0] reg_tp     = mem['h04];
 	wire [31:0] reg_t0     = mem['h05];
 	wire [31:0] reg_t1     = mem['h06];
 	wire [31:0] reg_t2     = mem['h07];
 	wire [31:0] reg_s0     = mem['h08];
 	wire [31:0] reg_s1     = mem['h09];
 	wire [31:0] reg_a0     = mem['h0a];
 	wire [31:0] reg_a1     = mem['h0b];
 	wire [31:0] reg_a2     = mem['h0c];
 	wire [31:0] reg_a3     = mem['h0d];
 	wire [31:0] reg_a4     = mem['h0e];
 	wire [31:0] reg_a5     = mem['h0f];
 	wire [31:0] reg_a6     = mem['h10];
 	wire [31:0] reg_a7     = mem['h11];
 	wire [31:0] reg_s2     = mem['h12];
 	wire [31:0] reg_s3     = mem['h13];
 	wire [31:0] reg_s4     = mem['h14];
 	wire [31:0] reg_s5     = mem['h15];
 	wire [31:0] reg_s6     = mem['h16];
 	wire [31:0] reg_s7     = mem['h17];
 	wire [31:0] reg_s8     = mem['h18];
 	wire [31:0] reg_s9     = mem['h19];
 	wire [31:0] reg_s10    = mem['h1a];
 	wire [31:0] reg_s11    = mem['h1b];
 	wire [31:0] reg_t3     = mem['h1c];
 	wire [31:0] reg_t4     = mem['h1d];
 	wire [31:0] reg_t5     = mem['h1e];
 	wire [31:0] reg_t6     = mem['h1f];

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
