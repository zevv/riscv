
// https://github.com/jameslzhu/riscv-card/blob/master/riscv-card.pdf
// https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf

`include "alu.v"

module cpu(
   input clk,
   output reg rd_en, output reg [15:0] o_addr, input [31:0] rd_data, input rd_valid,
   output reg wr_en, output reg [31:0] wr_data, output reg[3:0] wr_mask,
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
      OP_LUI = 7'b0110111,
      OP_AUIPC = 7'b0010111;

   localparam
      BOOT = 0,
      FETCH = 1,
      BRANCH = 2,
      LOAD_WAIT = 3,
      ST_AUIPC = 4,
      LD_RS1 = 5,
      LD_RS2_STORE = 6,
      LOAD = 7,
      LD_INST = 8,
      LD_PC = 9,
      LD_SP = 10,
      ST_SP = 11,
      ST_JAL = 12,
      ST_JALR = 13,
      ST_ALU = 14,
      ST_LOAD = 15,
      ST_LUI = 16,
      ST_STORE = 17,
      FAULT = 31;

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
   reg [4:0] state = 0;
   reg [15:0] pc = 0;
   reg [31:0] rd_val = 0;
   reg [31:0] rs1_val = 0;
   reg [31:0] rs2_val = 0;
   reg alu_in2_rs2;
   wire fetch = (state == FETCH);

   // Decoded instruction
   reg [6:0] opcode;
   reg [4:0] rd;
   reg [6:0] funct7;
   reg [2:0] funct3;
   reg [4:0] rs1;
   reg [4:0] rs2;
   reg signed [31:0] imm = 0;
  
   // ALU
   wire [31:0] alu_in1 = rs1_val;
   reg [31:0] alu_in2;
   reg [3:0] alu_fn;
   wire [31:0] alu_out;
   wire alu_zero;

   always @(*) begin
      alu_in2 = (alu_in2_rs2) ? rd_data : imm;
   end

   alu alu(
      .x(alu_in1),
      .y(alu_in2),
      .fn(alu_fn),
      .out(alu_out),
      .zero(alu_zero)
   );

   reg [31:0] inst = 0;

   always @(*) begin
      opcode = inst[6:0];
      rd = inst[11:7];
      funct7 = inst[31:25];
      funct3 = inst[14:12];
      rs1 = state == LD_INST ? rd_data[19:15] : inst[19:15];
      rs2 = inst[24:20];
   end

   always @(*) begin
      alu_in2_rs2 = 0;
      alu_fn = 0;
      case (inst[6:0])
         OP_ALU_R: begin
            alu_in2_rs2 = 1;
            alu_fn = { funct7[5], funct3 };
         end
         OP_ALU_I: begin
            alu_fn = { (funct3 == 3'h1 || funct3 == 3'h5) ? imm[10] : 1'b0, funct3 };
         end
         OP_LOAD: begin
            alu_fn = 4'h0; // ADD
         end
         OP_STORE: begin
            alu_fn = 4'h0; // ADD
         end
         OP_BRANCH: begin
            alu_in2_rs2 = 1;
            case (funct3)
               BR_BEQ: alu_fn = 4'h8;
               BR_BNE: alu_fn = 4'h8;
               BR_BLT: alu_fn = 4'h2;
               BR_BGE: alu_fn = 4'h2;
               BR_BLTU: alu_fn = 4'h3;
               BR_BGEU: alu_fn = 4'h3;
            endcase
         end
      endcase
   end

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
         OP_AUIPC: imm = { inst[31:12], 12'b0 };
      endcase
   end
 
   reg branch;

   always @(*) begin
      branch = 0;
      case (funct3)
         BR_BEQ: if (alu_zero) branch = 1;
         BR_BNE: if (!alu_zero) branch = 1;
         BR_BLT,
         BR_BLTU: if (alu_out) branch = 1;
         BR_BGE,
         BR_BGEU: if (!alu_out) branch = 1;
      endcase
   end

   // Memory load, handle unaligned and B/H/W

   reg [31:0] rd_data_shifted;
   reg [31:0] load_cooked;

   always @(*) begin
      case (o_addr[1:0])
         2'h0: rd_data_shifted = rd_data[31:0];
         2'h1: rd_data_shifted = rd_data[31:8];
         2'h2: rd_data_shifted = rd_data[31:16];
         2'h3: rd_data_shifted = rd_data[31:24];
      endcase
      load_cooked = 0;
      case (funct3)
         3'h0: load_cooked = { {24{rd_data_shifted[7]}}, rd_data_shifted[7:0] };
         3'h1: load_cooked = { {16{rd_data_shifted[15]}}, rd_data_shifted[15:0] };
         3'h2: load_cooked = rd_data_shifted;
         3'h4: load_cooked = { 24'b0, rd_data_shifted[7:0] };
         3'h5: load_cooked = { 16'b0, rd_data_shifted[15:0] };
      endcase
   end

   // Memory control

   always @(*) begin
      rd_en = 0;
      wr_en = 0;
      o_addr = -1;
      wr_data = 0;
      wr_mask = 4'b1111;

      case (state)
         LD_PC: begin
            o_addr = (!rd_valid) ? VEC_RESET : VEC_SP;
            rd_en = 1;
         end
         LD_SP: begin
            o_addr = pc;
            rd_en = 1;
         end
         ST_SP: begin
            o_addr = (2 << 2);
            wr_data = rd_val;
            wr_en = 1;
         end
         FETCH: begin
            o_addr = pc;
            rd_en = 1;
         end
         LD_INST: begin
            o_addr = (!rd_valid) ? pc : (rs1 << 2);
            rd_en = 1;
         end
         LD_RS1: begin
            o_addr = (rs2 << 2);
            rd_en = 1;
         end
         LD_RS2_STORE: begin
            o_addr = (rs2 << 2);
         end
         BRANCH: begin
            o_addr = (rs2 << 2);
            rd_en = 1;
         end
         ST_STORE: begin
            o_addr = alu_out;
            case (funct3)
               3'h0: wr_mask = 4'b1000;
               3'h1: wr_mask = 4'b1100;
               3'h2: wr_mask = 4'b1111;
            endcase
            case (o_addr[1:0])
               2'h0: begin
                  wr_data = rs2_val;
               end
               2'h1: begin
                  wr_data = rs2_val << 8;
                  wr_mask = wr_mask >> 1;
               end
               2'h2: begin
                  wr_data = rs2_val << 16;
                  wr_mask = wr_mask >> 2;
               end
               2'h3: begin
                  wr_data = rs2_val << 24;
                  wr_mask = wr_mask >> 3;
               end
            endcase
            wr_en = 1;
         end
         ST_LUI: begin
            o_addr = (rd << 2);
            wr_data = imm;
            wr_en = 1;
         end
         ST_LOAD: begin
            o_addr = (rd << 2);
            wr_data = rd_val;
            wr_en = 1;
         end
         ST_ALU: begin
            o_addr = (rd << 2);
            wr_data = alu_out;
            wr_en = 1;
         end
         ST_JAL,
            ST_JALR: begin
            o_addr = (rd << 2);
            wr_data = pc + 4;
            wr_en = 1;
         end
         ST_AUIPC: begin
            o_addr = (rd << 2);
            wr_data = pc + imm;
            wr_en = 1;
         end
         LOAD: begin
            o_addr = rs1_val + imm;
            rd_en = 1;
         end

      endcase

      // Do not allow writes to address 0, the zero register
      wr_en = (wr_en && o_addr != 0);

      debug = (!(rd_en || wr_en));
   end

   // CPU state machine

   always @(posedge clk) begin

      case (state)

         BOOT: begin
            pc <= pc + 4;
            if (pc == 64) begin
               pc <= 0;
               state = LD_PC;
            end
         end

         FETCH: begin
            state <= LD_INST;
         end

         LD_INST: begin
            if (rd_valid) begin
               inst <= rd_data;
               case (rd_data[6:0])
                  OP_ALU_R: state <= LD_RS1;
                  OP_ALU_I: state <= LD_RS1;
                  OP_LOAD: state <= LD_RS1;
                  OP_STORE: state <= LD_RS1;
                  OP_BRANCH: state <= LD_RS1;
                  OP_JAL: state <= ST_JAL;
                  OP_JALR: state <= LD_RS1;
                  OP_LUI: state <= ST_LUI;
                  OP_AUIPC: state <= ST_AUIPC;
                  default: state <= FAULT;
               endcase
            end
         end

         LD_RS1: begin
            if (rd_valid) begin
               rs1_val <= rd_data;
               state <= FAULT;
               case (opcode)
                  OP_ALU_R,
                  OP_ALU_I: state <= ST_ALU;
                  OP_STORE: state <= LD_RS2_STORE;
                  OP_BRANCH: state <= BRANCH;
                  OP_JALR: state <= ST_JALR;
                  OP_LOAD: state <= LOAD_WAIT;
               endcase
            end
         end

         LD_RS2_STORE: begin
            if (rd_valid) begin
               rs2_val <= rd_data;
               state <= ST_STORE;
            end
         end
         
         LOAD_WAIT: begin
            state <= LOAD;
         end

         BRANCH: begin
            if (branch)
               pc <= pc + imm;
            else
               pc <= pc + 4;
            state <= FETCH;
         end

         LOAD: begin
            if (rd_valid) begin
               rd_val = load_cooked;
               state <= ST_LOAD;
            end
         end

         LD_PC: begin
            if(rd_valid) begin
               pc <= rd_data;
               state <= LD_SP;
            end
         end

         LD_SP: begin
            if(rd_valid) begin
               rd_val <= rd_data;
               state <= ST_SP;
            end
         end

         ST_ALU, ST_STORE, ST_LUI, ST_LOAD: begin
            pc <= pc + 4;
            state <= FETCH;
         end

         ST_SP: begin
            state <= FETCH;
         end

         ST_AUIPC: begin
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
