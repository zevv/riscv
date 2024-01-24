
// https://github.com/jameslzhu/riscv-card/blob/master/riscv-card.pdf
// https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf

`include "alu.v"

module cpu(
   input clk,
   output reg rd_en = 0, output reg [15:0] o_addr = 0, input [31:0] rd_data, input rd_valid,
   output reg wr_en = 0, output reg [31:0] wr_data = 0,
   output reg debug
);
   
   localparam
      OP_ALU_R = 7'b0110011,
      OP_ALU_I = 7'b0010011,
      OP_LOAD = 7'b0000011,
      OP_STORE = 7'b0100011,
      OP_BRANCH = 7'b1100011,
      OP_JAL = 7'b1101111,
      OP_JALR = 7'b1100111,
      OP_LUI = 7'b0110111;

   localparam
      BOOT = 0,
      FETCH = 1,
      EXECUTE = 3,
      ST = 4,
      LD_RS1 = 5,
      LD_RS2 = 6,
      LD_RD = 7,
      LD_INST = 8,
      LD_PC = 9,
      LD_SP = 10,
      FAULT = 15;

   localparam
      BR_BEQ = 3'h0,
      BR_BNE = 3'h1,
      BR_BLT = 3'h4,
      BR_BGE = 3'h5,
      BR_BLTU = 3'h6,
      BR_BGEU = 3'h7;

   localparam
      VEC_RESET = 15'h0080,
      VEC_SP    = 15'h0084;


   initial begin
      rd_en = 0;
      wr_en = 0;
   end

   // CPU state
   reg [3:0] state = 0;
   reg [15:0] pc = 0;
   reg need_rs1;
   reg need_rs2;
   reg [31:0] reg_s1_data = 0;
   reg reg_s1_valid = 0;
   reg [31:0] reg_s2_data = 0;
   reg reg_s2_valid = 0;
   reg alu_in2_rs2;
   wire fetch = (state == FETCH);

   // Decoded instruction
   reg [6:0] opcode = 0;
   reg [4:0] rd = 0;
   reg [6:0] funct7 = 0;
   reg [3:0] funct3 = 0;
   reg [4:0] rs1 = 0;
   reg [4:0] rs2 = 0;
   reg signed [31:0] imm = 0;
  
   // ALU
   wire [31:0] alu_in1 = reg_s1_data;;
   reg [31:0] alu_in2;
   wire [31:0] alu_out;
   wire alu_zero;
   wire alu_negative;
   
   reg [3:0] alu_fn;

   always @(*) begin

      alu_in2 = (alu_in2_rs2) ? reg_s2_data : imm;

   end

   alu alu(
      .v1(alu_in1),
      .v2(alu_in2),
      .fn(alu_fn),
      .out(alu_out),
      .zero(alu_zero),
      .negative(alu_negative)
   );


   // CPU state machine

   always @(posedge clk) begin

      case (state)

         BOOT: begin
            pc <= pc + 1;
            if (pc == 16) begin
               pc <= 0;
               o_addr <= VEC_RESET;
               rd_en <= 1;
               state = LD_PC;
            end
         end

         FETCH: begin
            reg_s1_valid <= 0;
            reg_s2_valid <= 0;
            o_addr <= pc;
            rd_en <= 1;
            pc <= pc + 4;
            state <= LD_INST;
         end

         EXECUTE: begin

            if(need_rs1 && !reg_s1_valid) begin

               o_addr <= rs1 << 2;
               rd_en <= 1;
               state <= LD_RS1;

            end else if(need_rs2 && !reg_s2_valid) begin

               o_addr <= rs2 << 2;
               rd_en <= 1;
               state <= LD_RS2;

            end else begin

               case (opcode)
                  OP_ALU_R: begin
                     o_addr <= rd << 2;
                     wr_data <= alu_out;
                     wr_en <= 1;
                     state <= ST;
                  end

                  OP_ALU_I: begin
                     o_addr <= rd << 2;
                     wr_data <= alu_out;
                     wr_en <= 1;
                     state <= ST;
                  end

                  OP_LOAD: begin
                     o_addr = alu_out;
                     rd_en <= 1;
                     state <= LD_RD;
                  end

                  OP_STORE: begin
                     o_addr = alu_out;
                     wr_data = reg_s2_data;
                     wr_en <= 1;
                     state <= ST;
                  end

                  OP_BRANCH: begin
                     state <= FETCH;
                     case (funct3)
                        BR_BEQ: if (alu_zero) pc <= pc - 4 + imm;
                        BR_BNE: if (!alu_zero) pc <= pc - 4 + imm;
                        BR_BLT: if (alu_out) pc <= pc - 4 + imm;
                        BR_BGE: if (!alu_out) pc <= pc - 4 + imm;
                        BR_BLTU: if (alu_out) pc <= pc - 4 + imm;
                        BR_BGEU: if (!alu_out) pc <= pc - 4 + imm;
                        default: state <= FAULT;
                     endcase
                  end

                  OP_JAL: begin
                     pc <= pc + imm - 4;
                     if (rd != 0) begin
                        o_addr <= rd << 2;
                        wr_data <= pc + 4;
                        wr_en <= 1;
                        state <= ST;
                     end else begin
                        state <= FETCH;
                     end
                  end

                  OP_JALR: begin
                     pc <= reg_s1_data + imm - 4;
                     if (rd != 0) begin
                        o_addr <= rd << 2;
                        wr_data <= pc;
                        wr_en <= 1;
                        state <= ST;
                     end else begin
                        state <= FETCH;
                     end
                  end
                  
                  OP_LUI: begin
                     o_addr <= rd << 2;
                     wr_data <= imm;
                     wr_en <= 1;
                     state <= ST;
                  end
                  
                  default: begin
                     state <= FAULT;
                  end

               endcase
            end
         end

         LD_INST: begin
            rd_en <= 0;
            if (rd_valid) begin

               opcode <= rd_data[6:0];
               rd <= rd_data[11:7];
               funct7 <= rd_data[31:25];
               funct3 <= rd_data[14:12];
               rs1 <= rd_data[19:15];
               rs2 <= rd_data[24:20];
               need_rs1 <= 0;
               need_rs2 <= 0;
               alu_in2_rs2 <= 0;
               case (rd_data[6:0])
                  OP_ALU_R: begin
                     need_rs1 <= 1;
                     need_rs2 <= 1;
                     alu_in2_rs2 <= 1;
                     alu_fn <= { funct7[4], funct3 };
                  end
                  OP_ALU_I: begin
                     imm <= { {20{rd_data[31]}}, rd_data[31:20] };
                     need_rs1 <= 1;
                     alu_fn <= { funct7[4], funct3 };
                  end
                  OP_LOAD: begin
                     imm <= { {20{rd_data[31]}}, rd_data[31:20] };
                     need_rs1 <= 1;
                     alu_fn <= 4'h0; // ADD
                  end
                  OP_STORE: begin
                     imm <= { {20{rd_data[31]}}, rd_data[31:25], rd_data[11:7] };
                     need_rs1 <= 1;
                     need_rs2 <= 1;
                     alu_fn <= 4'h0; // ADD
                  end
                  OP_BRANCH: begin
                     imm <= { {19{rd_data[31]}}, rd_data[31], rd_data[7], rd_data[30:25], rd_data[11:8], 1'b0};
                     need_rs1 <= 1;
                     need_rs2 <= 1;
                     alu_in2_rs2 <= 1;
                     alu_fn <= (funct3 == 3'h0 || funct3 == 3'h1) ? 'h0 : 'h2; // ADD or BLT
                  end
                  OP_JAL: begin
                     imm <= { rd_data[31], rd_data[31], rd_data[19:12], rd_data[20], rd_data[30:21], 1'b0};
                  end
                  OP_JALR: begin
                     imm <= { {20{rd_data[31]}}, rd_data[31:20] };
                     need_rs1 <= 1;
                  end
                  OP_LUI: begin
                     imm <= { rd_data[31:12], 12'b0 };
                  end
                  default: imm <= 0;
               endcase

               state <= EXECUTE;
            end
         end

         LD_RS1: begin
            rd_en <= 0;
            if (rd_valid) begin
               reg_s1_data <= rd_data;
               reg_s1_valid <= 1;
               state <= EXECUTE;
            end
         end

         LD_RS2: begin
            rd_en <= 0;
            if (rd_valid) begin
               reg_s2_data <= rd_data;
               reg_s2_valid <= 1;
               state <= EXECUTE;
            end
         end

         LD_RD: begin
            rd_en <= 0;
            if (rd_valid) begin
               o_addr <= rd << 2;
               if (funct3 == 3'b000 || funct3 == 3'b100)
                  wr_data <= rd_data[7:0];
               else if(funct3 == 3'b001 || funct3 == 3'b101) 
                  wr_data <= rd_data[15:0];
               else
                  wr_data <= rd_data;
               wr_en <= 1;
               state <= ST;
            end
         end

         LD_PC: begin
            rd_en <= 0;
            if(rd_valid) begin
               pc <= rd_data;
               o_addr = VEC_SP;
               state <= LD_SP;
               rd_en <= 1;
            end
         end

         LD_SP: begin
            rd_en <= 0;
            if(rd_valid) begin
               o_addr = 2 << 2;
               wr_data = rd_data;
               state <= ST;
            end
         end

         ST: begin
            wr_en <= 0;
            state <= FETCH;
         end

         default: begin
            state <= FAULT;
         end
      endcase
   end

endmodule

// vi: ft=verilog ts=3 sw=3 et
