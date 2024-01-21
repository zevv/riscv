
// https://github.com/jameslzhu/riscv-card/blob/master/riscv-card.pdf
// https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf

module cpu(
   input clk,
   output reg rd_en = 0, output reg [15:0] rd_addr = 0, input [31:0] rd_data, input rd_valid,
   output reg wr_en = 0, output reg [15:0] wr_addr = 0, output reg [31:0] wr_data = 0,
   output reg debug
);

   initial begin
      rd_en = 0;
      wr_en = 0;
   end

   reg [3:0] state = 0;

   reg [7:0] pc = 8'h80;

   reg [31:0] inst = 0;
   wire [6:0] opcode = inst[6:0];
   wire [4:0] rd = inst[11:7];
   wire [3:0] funct3 = inst[14:12];
   wire [4:0] rs1 = inst[19:15];
   wire [4:0] rs2 = inst[24:20];
   wire signed [11:0] imm_I = inst[31:20];
   wire        [11:0] imm_S = {inst[31:25], inst[11:7]};
   wire signed [31:0] imm_U = {inst[31:12], 12'b0};
   wire signed [30:0] imm_J = {inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};

   reg [31:0] reg_s1_data = 0;
   reg reg_s1_valid = 0;

   reg [31:0] reg_s2_data = 0;
   reg reg_s2_valid = 0;
   
   wire alu_imm = !opcode[5];
   wire [31:0] alu_in1 = reg_s1_data;;
   reg [31:0] alu_in2;
   wire [31:0] alu_out;
   reg [3:0] alu_fn;
   wire alu_zero;
   wire alu_overflow;
   wire alu_negative;

   always @(*) begin
      if (opcode[5])
         alu_in2 = reg_s2_data;
      else
         alu_in2 = imm_I;
      if (opcode[6] == 0)
         alu_fn = { inst[30], funct3 };
      else
         if(funct3 == 3'h0 || funct3 == 3'h1)
            alu_fn = 4'h8; // SUB
         else
            alu_fn = 4'h4; // BLT
   end

   alu alu(
      .v1(alu_in1),
      .v2(alu_in2),
      .fn(alu_fn),
      .out(alu_out),
      .zero(alu_zero),
      .overflow(alu_overflow),
      .negative(alu_negative)
   );


   localparam
      BOOT = 0,
      FETCH = 1,
      DECODE = 2,
      RAM_WR = 3,
      RAM_RD = 4,
      RAM_RD2 = 5,
      BRANCH = 6,
      FAIL = 15;

   reg [1:0] ram_rd_target = 0;

   always @(*) begin
      //debug = (inst[0] == 0);
   end
   
   always @(posedge clk) begin

      case (state)

         BOOT: begin
            inst <= inst + 1;
            if(inst == 64) begin
               state <= FETCH;
            end
         end

         FETCH: begin
            // $display("%x:", pc);

            reg_s1_valid <= 0;
            reg_s2_valid <= 0;
            
            pc <= pc + 4;
            
            rd_addr <= pc;
            rd_en <= 1;
            ram_rd_target <= 0;
            state <= RAM_RD;
         end

         DECODE: begin

            case (opcode)

               7'b0010011: begin // alu, I-type
                  if(!reg_s1_valid) begin
                     // $display("alu%d x%d, x%d, %d", funct3, rd, rs1, imm_I);
                     rd_addr <= rs1 << 2;
                     rd_en <= 1;
                     ram_rd_target <= 1;
                     state <= RAM_RD;
                  end else begin
                     //alu_fn <= funct3;
                     wr_addr <= rd << 2;
                     wr_data <= alu_out;
                     wr_en <= 1;
                     state <= RAM_WR;
                  end
               end

               7'b0000011: begin // load, I-type
                  if(!reg_s1_valid) begin
                     // $display("lw x%d, %d(x%d)", rd, imm_I, rs1);
                     rd_addr <= rs1 << 2;
                     rd_en <= 1;
                     ram_rd_target = 1;
                     state <= RAM_RD;
                  end else begin
                     rd_addr = reg_s1_data + imm_I;
                     rd_en <= 1;
                     ram_rd_target <= 3;
                     state <= RAM_RD;
                  end
               end

               7'b0100011: begin // store, S-type
                  if(!reg_s1_valid) begin
                     // $display("sw x%d, %d(x%d)", rs2, imm_I, rs1);
                     rd_addr <= rs1 << 2;
                     rd_en <= 1;
                     ram_rd_target <= 1;
                     state <= RAM_RD;
                  end else if(!reg_s2_valid) begin
                     rd_addr <= rs2 << 2;
                     rd_en <= 1;
                     ram_rd_target <= 2;
                     state <= RAM_RD;
                  end else begin
                     wr_addr = reg_s1_data + imm_S;
                     wr_data = reg_s2_data;
                     wr_en <= 1;
                     state <= RAM_WR;
                  end
               end

               7'b0110111: begin // lui, U-type
                  // $display("lui x%d, %x", rd, imm_U);
                  wr_addr <= rd << 2;
                  wr_data <= {inst[31:12], 12'b0};
                  wr_en <= 1;
                  state <= RAM_WR;
               end

               7'b1100011: begin // branch, B-type
                  if(!reg_s1_valid) begin
                     // $display("beq x%d, x%d, %d", rs1, rs2, imm_I);
                     rd_addr <= rs1 << 2;
                     rd_en <= 1;
                     ram_rd_target <= 1;
                     state <= RAM_RD;
                  end else if(!reg_s2_valid) begin
                     rd_addr <= rs2 << 2;
                     rd_en <= 1;
                     ram_rd_target <= 2;
                     state <= RAM_RD;
                  end else begin
                     state <= BRANCH;
                  end
               end

               7'b1101111: begin // jal, J-type
                  // $display("jal x%d, %x", rd, imm_J);
                  pc <= pc - 4 + imm_J;
                  wr_addr <= rd << 2;
                  wr_data <= pc;
                  wr_en <= 1;
                  state <= RAM_WR;
               end

               default: begin
                  state <= FAIL;
               end

            endcase
         end

         RAM_RD: begin
            state <= RAM_RD2;
         end

         BRANCH: begin
            case (funct3)
               3'h0: if ( alu_zero) begin
                  $display("beq x%d, x%d, %d", rs1, rs2, imm_I);
                  pc <= pc - 4 + imm_I;
               end
               3'h1: if (!alu_zero) begin
                  $display("bne x%d, x%d, %d", rs1, rs2, imm_I);
                  pc <= pc - 4 + imm_I;
               end
            endcase
            state <= FETCH;
         end

         RAM_RD2: begin
            debug <= (rd_data[7:0] == 'h0);
            
            if (rd_valid) begin
               rd_en <= 0;
               case (ram_rd_target)
                  2'd0: begin
                     inst <= rd_data;
                     state <= DECODE;
                  end
                  2'd1: begin
                     reg_s1_data <= rd_data;
                     reg_s1_valid <= 1;
                     state <= DECODE;
                  end
                  2'd2: begin
                     reg_s2_data <= rd_data;
                     reg_s2_valid <= 1;
                     state <= DECODE;
                  end
                  2'd3: begin
                     wr_addr <= rd << 2;
                     wr_data <= rd_data;
                     wr_en <= 1;
                     state <= RAM_WR;
                  end
                  default: begin
                     state <= FAIL;
                  end
               endcase
            end
         end

         RAM_WR: begin
            wr_en <= 0;
            state <= FETCH;
         end

         default: begin
            state <= FAIL;
         end
      endcase
   end

endmodule



module alu(
   input [31:0] v1,
   input [31:0] v2,
   input [3:0] fn,
   output reg [31:0] out,
   output reg zero,
   output reg overflow,
   output reg negative
);

   always @(*)
   begin

      case (fn)
         4'h0: out = v1 + v2;
         4'h4: out = v1 ^ v2;
         4'h6: out = v1 | v2;
         4'h7: out = v1 & v2;
         4'h1: out = v1 << v2[4:0];
         4'h5: out = v1 >> v2[4:0];
         4'h2: out = (v1 < v2) ? 1 : 0;
         4'h3: out = (v1 < v2) ? 1 : 0;
         4'h8: out = v1 - v2;
         default: out= 0;
      endcase

      zero = (out == 0) ? 1 : 0;
      overflow = 0;
      negative = out[31];

   end

endmodule

   





// vi: ft=verilog ts=3 sw=3 et
