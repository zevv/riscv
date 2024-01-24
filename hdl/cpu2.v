
// https://github.com/jameslzhu/riscv-card/blob/master/riscv-card.pdf
// https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf

module cpu(
   input clk,
   output reg rd_en, output reg [15:0] rd_addr, input [31:0] rd_data, input rd_valid,
   output reg wr_en, output reg [15:0] wr_addr, output reg [31:0] wr_data
);

   initial begin
      rd_en = 0;
      wr_en = 0;
   end

   reg [3:0] state = 0;
   localparam
      IDLE = 0,
      FETCH = 1,
      FETCH2 = 2,
      DECODE = 4,
      LOAD = 5,
      LOAD2 = 6,
      BRANCH = 7,
      LUI = 8,
      ALU = 9,
      STORE = 10,
      STORE2 = 11,
      JAL = 12,
      FAIL = 15;


   reg [7:0] pc = 32;
   reg [31:0] inst = 0;

   reg fail = 0;

   reg [31:0] x [0:31];
   wire [31:0] a0 = x[0];
   wire [31:0] a1 = x[1];

   initial begin
      x[0] = 0;
   end

   reg [4:0] rd;
   reg [4:0] rs1;
   reg [4:0] rs2;
   reg [4:0] rs3;
   reg [4:0] funct5;
   reg [2:0] funct3;
   reg [9:0] funct10;
   reg signed [31:0] imm;

   reg [31:0] alu_in1;
   reg [31:0] alu_in2;
   wire [31:0] alu_result;
   reg [2:0] alu_funct = 0;
   wire alu_zero;
   wire alu_overflow;
   wire alu_negative;

   alu alu(
      .v1(alu_in1),
      .v2(alu_in2),
      .funct(alu_funct),
      .result(alu_result),
      .zero(alu_zero),
      .overflow(alu_overflow),
      .negative(alu_negative)
   );

   wire [6:0] opcode = inst[6:0];

   always @(posedge clk) begin

      case (state)

         IDLE: begin
            fail <= 0;
            state <= FETCH;
         end

         FETCH: begin
            //$display("%x", pc);
            rd_addr <= pc;
            rd_en <= 1;
            state <= FETCH2;
         end

         FETCH2: begin
            if (rd_valid) begin
               inst <= rd_data;
               rd_en <= 0;
               pc <= pc + 4;
               state <= DECODE;
            end
         end

         DECODE: begin
            case (opcode)

               7'b0110011: begin // ALU, R-type
                  rs1 <= inst[19:15];
                  rs2 <= inst[24:20];
                  rd <= inst[11:7];
                  funct3 <= inst[14:12];
                  alu_in1 <= x[inst[19:15]];
                  alu_in2 <= x[inst[24:20]];
                  alu_funct <= inst[14:12];
                  state <= ALU;
               end

               7'b0010011: begin // ALU, I-type
                  imm <= inst[31:20];
                  rs1 <= inst[19:15];
                  rs2 <= inst[24:20];
                  funct3 <= inst[14:12];
                  rd <= inst[11:7];
                  alu_in1 <= x[inst[19:15]];
                  alu_in2 <= inst[31:20];
                  alu_funct <= inst[14:12];
                  state <= ALU;
               end

               7'b0000011: begin // LOAD, I-type
                  imm <= inst[31:20];
                  rs1 <= inst[19:15];
                  funct3 <= inst[14:12];
                  rd <= inst[11:7];
                  state <= LOAD;
               end

               7'b0100011: begin // STORE, S-type
                  imm <= { inst[31:25], inst[11:7] };
                  rs1 <= inst[19:15];
                  rs2 <= inst[24:20];
                  funct3 <= inst[14:12];
                  state <= STORE;
               end

               7'b0110111: begin // LUI, U-type
                  imm <= { inst[31:12], 12'b0 };
                  rd <= inst[11:7];
                  state <= LUI;
               end

               7'b1101111: begin // JAL, J-type
                  imm <= {11'b0, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
                  rd <= inst[11:7];
                  state <= JAL;
               end

               7'b1100011: begin // BRANCH, B-type
                  imm <= { inst[31], inst[7], inst[30:25], inst[11:8], 1'b0 };
                  rs1 <= inst[19:15];
                  rs2 <= inst[24:20];
                  funct3 <= inst[14:12];
                  if (inst[14:12] == 3'h0 || inst[14:12] == 3'h1)
                     alu_funct <= 3'h0; // SUB
                  else
                     alu_funct <= 3'h3; // SLTU
                  state <= BRANCH;
               end

               default: begin
                  state <= FAIL;
               end

            endcase
         end

         LOAD: begin
            case (funct3)
               3'b010: begin
                  //$display("  lw x%d, %d(x%d)", rd, imm, rs1);
                  rd_addr <= (x[rs1] + imm);
                  rd_en <= 1;
                  state <= LOAD2;
               end
               default:
                  state <= FAIL;
            endcase
         end

         LOAD2: begin
            if (rd_valid) begin
               x[rd] <= rd_data;
               rd_en <= 0;
               state <= FETCH;
            end
         end

         BRANCH: begin
            state <= FETCH;
            case (funct3)
               3'h0: // BEQ
                  if (alu_zero) pc <= (pc - 4) + imm;
               3'h4: // BLT
                  if (alu_result[0]) pc <= (pc - 4) + imm;
               3'h5: // BGE
                  if (!alu_result[0]) pc <= (pc - 4) + imm;
               default:
                  state <= FAIL;
            endcase
         end

         STORE: begin
            case (funct3)
               3'b010: begin
                  //$display("  sw x%d, %d(x%d)", rs2, imm, rs1);
                  wr_addr <= x[rs1] + imm;
                  wr_data <= x[rs2];
                  wr_en <= 1;
                  state <= STORE2;
               end
               default:
                  state <= FAIL;
            endcase
         end

         STORE2: begin
            wr_en <= 0;
            state <= FETCH;
         end

         LUI: begin
            //$display("  lui x%d, x%d", rd, imm);
            x[rd] <= imm;
            state <= FETCH;
         end

         ALU: begin
            x[rd] <= alu_result;
            state <= FETCH;
         end

         JAL: begin
            //$display("%d", imm);
            //$display("  jal x%d, %d", rd, pc + imm - 4);
            x[rd] <= pc;
            pc <= (pc - 4) + imm;
            state <= FETCH;
         end

         default: begin
            fail <= 1;
         end
      endcase
   end

endmodule



module alu(
   input [31:0] v1,
   input [31:0] v2,
   input [2:0] funct,
   output reg [31:0] result,
   output reg zero,
   output reg overflow,
   output reg negative
);

   always @(*)
   begin

      case (funct)
         3'h0: begin // ADD
            result = v1 + v2;
         end

         3'h4: begin // XOR
            result = v1 ^ v2;
         end

         3'h6: begin // OR
            result = v1 | v2;
         end

         3'h7: begin // AND
            result = v1 & v2;
         end

         3'h1: begin // SLL
            result = v1 << v2[4:0];
         end

         3'h5: begin // SRL
            result = v1 >> v2[4:0];
         end

         3'h2: begin // SLT
            result = (v1 < v2) ? 1 : 0;
         end

         3'h3: begin // SLTU
            result = (v1 < v2) ? 1 : 0;
         end

         default: begin
            result = 0;
         end

      endcase

      zero = (result == 0) ? 1 : 0;
      overflow = 0;
      negative = result[31];

   end

endmodule

   





// vi: ft=verilog ts=3 sw=3 et
