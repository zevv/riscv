module regs
#(
   parameter W = 32
)
(
   input clk,
   input ren,
   input [4:0] rs1, input [4:0] rs2, output reg [31:0] rs1_val, output reg [31:0] rs2_val,
   input wen, input [4:0] rd, input [W-1:0] rd_val
);
   reg [W*2:0] mem [0:31];

   integer i;
   initial begin
      for (i = 0; i < 32; i = i + 1) begin
         mem[i] = (W+W)'d0;
      end
   end

   always @(posedge clk)
   begin
      if (ren) begin
         rs1_val = mem[rs1][W+W-1+32:W];
         rs2_val = mem[rs2][W-1:0];
      end
      if(wen && rd != 0) begin
         mem[rd] <= { rd_val, rd_val };
      end
   end
   
   wire [31:0] x0_zero = mem['h00][W-1:0];
   wire [31:0] x1_ra   = mem['h01][W-1:0];
   wire [31:0] x2_sp   = mem['h02][W-1:0];
   wire [31:0] x3_gp   = mem['h03][W-1:0];
   wire [31:0] x4_tp   = mem['h04][W-1:0];
   wire [31:0] x5_t0   = mem['h05][W-1:0];
   wire [31:0] x6_t1   = mem['h06][W-1:0];
   wire [31:0] x7_t2   = mem['h07][W-1:0];
   wire [31:0] x8_s0   = mem['h08][W-1:0];
   wire [31:0] x9_s1   = mem['h09][W-1:0];
   wire [31:0] x10_a0  = mem['h0a][W-1:0];
   wire [31:0] x11_a1  = mem['h0b][W-1:0];
   wire [31:0] x12_a2  = mem['h0c][W-1:0];
   wire [31:0] x13_a3  = mem['h0d][W-1:0];
   wire [31:0] x14_a4  = mem['h0e][W-1:0];
   wire [31:0] x15_a5  = mem['h0f][W-1:0];
   wire [31:0] x16_a6  = mem['h10][W-1:0];
   wire [31:0] x17_a7  = mem['h11][W-1:0];
   wire [31:0] x18_s2  = mem['h12][W-1:0];
   wire [31:0] x19_s3  = mem['h13][W-1:0];
   wire [31:0] x20_s4  = mem['h14][W-1:0];
   wire [31:0] x21_s5  = mem['h15][W-1:0];
   wire [31:0] x22_s6  = mem['h16][W-1:0];
   wire [31:0] x23_s7  = mem['h17][W-1:0];
   wire [31:0] x24_s8  = mem['h18][W-1:0];
   wire [31:0] x25_s9  = mem['h19][W-1:0];
   wire [31:0] x26_s10 = mem['h1a][W-1:0];
   wire [31:0] x27_s11 = mem['h1b][W-1:0];
   wire [31:0] x28_t3  = mem['h1c][W-1:0];
   wire [31:0] x29_t4  = mem['h1d][W-1:0];
   wire [31:0] x30_t5  = mem['h1e][W-1:0];
   wire [31:0] x31_t6  = mem['h1f][W-1:0];

   endmodule

// vi: ft=verilog ts=3 sw=3 et
