
// https://github.com/jameslzhu/riscv-card/blob/master/riscv-card.pdf
// https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf

`include "alu.v"

module branch_unit(
   input [2:0] funct3,
   input alu_zero,
   input alu_out,
   output reg out
);
   always @(*) begin
      out = 0;
      case (funct3)
         3'h0: if ( alu_zero) out = 1; // BEQ
         3'h1: if (!alu_zero) out = 1; // BNE
         3'h4: if ( alu_out ) out = 1; // BLT
         3'h5: if (!alu_out ) out = 1; // BGE
         3'h6: if ( alu_out ) out = 1; // BLTU
         3'h7: if (!alu_out ) out = 1; // BGEU
      endcase
   end
endmodule


module alu_fn_decoder(
   input [6:0] opcode,
   input [31:0] inst,
   output reg [3:0] alu_fn
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

   always @(*) begin
      alu_fn = 4'h0;
      case (opcode)
         OP_ALU_R: alu_fn = { inst[30], inst[14:12] };
         OP_ALU_I: alu_fn = { 1'b0, inst[14:12] };
         OP_BRANCH: alu_fn = (inst[14:12] == 3'h0 || inst[14:12] == 3'h1) ? 'h8 : 'h2; // SUB : BLT
      endcase
   end
endmodule


module imm_decoder(
   input [31:0] inst,
   output reg [31:0] imm
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

   always @(*) begin
      imm = 0;
      case (inst[6:0])
         OP_ALU_I: imm = { {20{inst[31]}}, inst[31:20] };
         OP_LOAD: imm = { {20{inst[31]}}, inst[31:20] };
         OP_STORE: imm = { {20{inst[31]}}, inst[31:25], inst[11:7] };
         OP_BRANCH: imm = { {19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
         OP_JAL: imm = { inst[31], inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
         OP_JALR: imm = { {20{inst[31]}}, inst[31:20] };
         OP_LUI: imm = { inst[31:12], 12'b0 };
      endcase
      imm = imm;
   end
endmodule


module cpu(
   input clk,
   output reg rd_en, output reg [15:0] o_addr, input [31:0] rd_data, input rd_valid,
   output reg wr_en, output reg [31:0] wr_data,
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
      ST_SP = 11,
      ST_JAL = 13,
      ST_JALR = 14,
      FAULT = 15;

   localparam
      VEC_RESET = 15'h0080,
      VEC_SP    = 15'h0084;

   // CPU state
   reg [3:0] state = 0;
   reg [15:0] pc = 0;
   reg [31:0] rs1_val = 0;
   reg [31:0] rs2_val = 0;
   wire fetch = (state == FETCH);

   // Decoded instruction
   wire [4:0] rd = inst[11:7];
   wire [2:0] funct3 = inst[14:12];
   wire [4:0] rs1 = inst[19:15];
   wire [4:0] rs2 = inst[24:20];

   // ALU
   wire [31:0] alu_x = rs1_val;
   wire [31:0] alu_y = (alu_y_rs2) ? rs2_val : imm;
   wire [31:0] alu_out;
   wire alu_zero;

   wire alu_y_rs2 = (opcode == OP_ALU_R || opcode == OP_BRANCH);

   wire branch;
   branch_unit bt(
      .funct3(funct3),
      .alu_zero(alu_zero),
      .alu_out(alu_out[0]),
      .out(branch)
   );

   alu alu(
      .x(alu_x),
      .y(alu_y),
      .fn(alu_fn),
      .out(alu_out),
      .zero(alu_zero)
   );

   reg [31:0] rd_val = 0;
   
   always @(*) begin
      wr_data = rd_val;
      case (opcode)
         OP_ALU_R: wr_data = alu_out;
         OP_ALU_I: wr_data = alu_out;
         OP_LOAD: begin
            if (funct3 == 3'b000 || funct3 == 3'b100)
               wr_data = rd_val[7:0];
            else if(funct3 == 3'b001 || funct3 == 3'b101) 
               wr_data = rd_val[15:0];
            else
               wr_data = rd_val;
         end
         OP_STORE: wr_data = rs2_val;
         OP_JAL: wr_data = pc + 4;
         OP_JALR: wr_data = pc;
         OP_LUI: wr_data = imm;
      endcase
   end

   always @(*) begin
      o_addr = rd << 2;
      case (state)
         FETCH: o_addr = pc;
         LD_RD: o_addr = alu_out;
         LD_RS1: o_addr = rs1 << 2;
         LD_RS2: o_addr = rs2 << 2;
         LD_INST: o_addr = pc;
         LD_PC: o_addr = VEC_RESET;
         LD_SP: o_addr = VEC_SP;
         ST_SP: o_addr = 2 << 2;
         ST: if(opcode == OP_STORE) o_addr = rs1_val + imm;
      endcase
   end

   always @(*) begin
      rd_en = 0;
      case (state)
         LD_PC: rd_en = !rd_valid;
         LD_SP: rd_en = !rd_valid;
         FETCH: rd_en = !rd_valid;
         LD_INST: rd_en = !rd_valid;
         LD_RS1: rd_en = !rd_valid;
         LD_RS2: rd_en = !rd_valid;
         LD_RD: rd_en = !rd_valid;
      endcase
   end

   always @(*) begin
      wr_en = 0;
      case (state)
         ST: wr_en = 1;
         ST_SP: wr_en = 1;
         ST_JAL: if(rd != 0) wr_en = 1;
         ST_JALR: if(rd != 0) wr_en = 1;
      endcase
   end


   alu_fn_decoder alu_fn_decoder(
      .opcode(opcode),
      .inst(inst),
      .alu_fn(alu_fn)
   );

   wire [3:0] alu_fn;

   wire [6:0] opcode = inst[6:0];

   imm_decoder id(
      .inst(inst),
      .imm(imm)
   );

   reg [31:0] inst = 0;
   wire signed [31:0] imm ;

   // CPU state machine

   always @(posedge clk) begin

      case (state)

         BOOT: begin
            pc <= pc + 4;
            if (pc == 64) begin
               pc <= 0;
               state <= LD_SP;
            end
         end

         LD_SP: begin
            if(rd_valid) begin
               rd_val = rd_data;
               state <= ST_SP;
            end
         end

         ST_SP: begin
            state <= LD_PC;
         end

         LD_PC: begin
            if(rd_valid) begin
               pc <= rd_data;
               state <= FETCH;
            end
         end

         FETCH: begin
            state <= LD_INST;
            //$display("%08x", pc);
         end

         EXECUTE: begin
            case (opcode)
               OP_ALU_R: state <= ST;
               OP_ALU_I: state <= ST;
               OP_LOAD: state <= LD_RD;
               OP_STORE: state <= ST;
               OP_BRANCH: begin
                  if (branch)
                     pc <= pc + imm;
                  else
                     pc <= pc + 4;
                  state <= FETCH;
               end
               OP_JAL: state <= ST_JAL;
               OP_JALR: state <= ST_JALR;
               OP_LUI: state <= ST;
               default: state <= FAULT;
            endcase
         end

         LD_INST: begin
            if (rd_valid) begin
               inst <= rd_data;
               state <= LD_RS1;
            end
         end

         LD_RS1: begin
            if (rd_valid) begin
               rs1_val <= rd_data;
               state <= LD_RS2;
            end
         end

         LD_RS2: begin
            if (rd_valid) begin
               rs2_val <= rd_data;
               state <= EXECUTE;
            end
         end

         LD_RD: begin
            if (rd_valid) begin
               rd_val <= rd_data;
               state <= ST;
            end
         end
         
         ST: begin
            pc <= pc + 4;
            state <= FETCH;
         end

         ST_JAL: begin
            pc <= pc + imm;
            state <= FETCH;
         end

         ST_JALR: begin
            pc <= rs1_val + imm;
            state <= FETCH;
         end

         default: begin
            state <= FAULT;
         end
      endcase
   end

endmodule

// vi: ft=verilog ts=3 sw=3 et
