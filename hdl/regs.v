module regs
#(
   parameter W = 32
)
(
   input clk,
   input rd_en,
   input [4:0] rs1, input [4:0] rs2, output reg [31:0] rs1_val, output reg [31:0] rs2_val,
   input wr_en, input [4:0] rd, input [W-1:0] rd_val
);
   reg [31:0] mem1 [0:31];
   reg [31:0] mem2 [0:31];

   integer i;
   initial begin
      for (i = 0; i < 32; i = i + 1) begin
         mem1[i] = 32'd0;
         mem2[i] = 32'd0;
      end
   end

   wire [31:0] x0_zero   = mem1['h00];
   wire [31:0] x1_ra     = mem1['h01];
   wire [31:0] x2_sp     = mem1['h02];
   wire [31:0] x3_gp     = mem1['h03];
   wire [31:0] x4_tp     = mem1['h04];
   wire [31:0] x5_t0     = mem1['h05];
   wire [31:0] x6_t1     = mem1['h06];
   wire [31:0] x7_t2     = mem1['h07];
   wire [31:0] x8_s0     = mem1['h08];
   wire [31:0] x9_s1     = mem1['h09];
   wire [31:0] x10_a0     = mem1['h0a];
   wire [31:0] x11_a1     = mem1['h0b];
   wire [31:0] x12_a2     = mem1['h0c];
   wire [31:0] x13_a3     = mem1['h0d];
   wire [31:0] x14_a4     = mem1['h0e];
   wire [31:0] x15_a5     = mem1['h0f];
   wire [31:0] x16_a6     = mem1['h10];
   wire [31:0] x17_a7     = mem1['h11];
   wire [31:0] x18_s2     = mem1['h12];
   wire [31:0] x19_s3     = mem1['h13];
   wire [31:0] x20_s4     = mem1['h14];
   wire [31:0] x21_s5     = mem1['h15];
   wire [31:0] x22_s6     = mem1['h16];
   wire [31:0] x23_s7     = mem1['h17];
   wire [31:0] x24_s8     = mem1['h18];
   wire [31:0] x25_s9     = mem1['h19];
   wire [31:0] x26_s10    = mem1['h1a];
   wire [31:0] x27_s11    = mem1['h1b];
   wire [31:0] x28_t3     = mem1['h1c];
   wire [31:0] x29_t4     = mem1['h1d];
   wire [31:0] x30_t5     = mem1['h1e];
   wire [31:0] x31_t6     = mem1['h1f];

   always @(posedge clk)
   begin
      if (rd_en) begin
         rs1_val = mem1[rs1];
         rs2_val = mem2[rs2];
      end
      if(wr_en && rd != 0) begin
         mem1[rd] <= rd_val;
         mem2[rd] <= rd_val;
      end
   end

endmodule

// vi: ft=verilog ts=3 sw=3 et