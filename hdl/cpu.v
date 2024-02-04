// https://github.com/jameslzhu/riscv-card/blob/master/riscv-card.pdf
// https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf

`include "alu.v"
`include "common.v"
`include "regs.v"

module cpu
#(
   parameter W = 32
)
(
   input clk,
   output reg rd_en, output reg [15:0] o_addr, input [31:0] rd_data, input rd_valid,
   output reg wr_en, output reg [W-1:0] wr_data, output reg[3:0] wr_mask,
   output reg debug
);
   
   localparam
      VEC_RESET = 16'h0000,
      VEC_SP    = 16'h0004;

   // CPU state
   reg [4:0] state = 0;
   reg [15:0] pc = 0;
   reg [W-1:0] rd_val;
   
   // Decoded instruction
   reg [6:0] opcode;
   reg [4:0] rd;
   reg [6:0] funct7;
   reg [2:0] funct3;
   reg [4:0] rs1;
   reg [4:0] rs2;
   reg [W-1:0] imm;

   // Instruction decoding
   always @(posedge clk)
   begin
      if(state == `ST_F_SP) begin
         rd = 2;
      end
      if(state == `ST_DECODE) begin
         opcode <= rd_data[6:0];
         rd <= rd_data[11:7];
         funct7 <= rd_data[31:25];
         funct3 <= rd_data[14:12];
         rs1 <= rd_data[19:15];
         rs2 <= rd_data[24:20];
         case (rd_data[6:0])
            `OP_ALU_I: imm <= { {20{rd_data[31]}}, rd_data[31:20] };
            `OP_LOAD: imm <= { {20{rd_data[31]}}, rd_data[31:20] };
            `OP_STORE: imm <= { {20{rd_data[31]}}, rd_data[31:25], rd_data[11:7] };
            `OP_BRANCH: imm <= { {19{rd_data[31]}}, rd_data[31], rd_data[7], rd_data[30:25], rd_data[11:8], 1'b0};
            `OP_JAL: imm <= { rd_data[31], rd_data[31], rd_data[19:12], rd_data[20], rd_data[30:21], 1'b0};
            `OP_JALR: imm <= { {20{rd_data[31]}}, rd_data[31:20] };
            `OP_LUI: imm <= { rd_data[31:12], 12'b0 };
            `OP_AUIPC: imm <= { rd_data[31:12], 12'b0 };
         endcase
      end
   end

   reg reg_rd_en = 0;
   reg reg_wr_en = 0;
   wire [W-1:0] rs1_val;
   wire [W-1:0] rs2_val;

   regs #(.W(W)) regs(
      .clk(clk),
      .rd_en(reg_rd_en),
      .rs1(rs1), .rs2(rs2), .rs1_val(rs1_val), .rs2_val(rs2_val),
      .wr_en(reg_wr_en), .rd(rd), .rd_val(rd_val)
   );

   // ALU
   reg [W-1:0] alu_x;
   reg [W-1:0] alu_y;
   reg [3:0] alu_fn;
   wire [W-1:0] alu_out;
   wire alu_zero;
   alu #(.W(W)) alu(
      .x(alu_x),
      .y(alu_y),
      .fn(alu_fn),
      .out(alu_out),
      .zero(alu_zero)
   );

   // ALU control
   always @(*) begin
      alu_fn = `ALU_FN_ADD;
      alu_x = rs1_val;
      alu_y = imm;
      case (opcode)
         `OP_ALU_R: begin
            alu_fn = { funct7[5], funct3 };
            alu_y = rs2_val;
         end
         `OP_ALU_I: begin
            alu_fn = { (funct3 == 3'h1 || funct3 == 3'h5) ? imm[10] : 1'b0, funct3 };
         end
         `OP_BRANCH: begin
            case (funct3)
               `BR_BEQ:  alu_fn = `ALU_FN_SUB;
               `BR_BNE:  alu_fn = `ALU_FN_SUB;
               `BR_BLT:  alu_fn = `ALU_FN_LT;
               `BR_BGE:  alu_fn = `ALU_FN_LT;
               `BR_BLTU: alu_fn = `ALU_FN_LTU;
               `BR_BGEU: alu_fn = `ALU_FN_LTU;
            endcase
            alu_y = rs2_val;
         end
         `OP_JAL: begin
            alu_x = pc;
         end
         `OP_JAL: begin
            alu_x = pc;
            alu_y = 32'd4;
         end
         `OP_AUIPC: begin
            alu_x = pc;
         end
      endcase
   end

   // pc + imm
   wire [15:0] pc_plus_imm;
   wire pc_plus_imm_carry;
   adder #(16) add_pc_imm(pc, imm, 1'b0, pc_plus_imm, pc_plus_imm_carry);

   // pc + 4
   wire [15:0] pc_plus_4;
   wire pc_plus_4_carry;
   adder #(16) add_pc_4(pc, 32'd4, 1'b0, pc_plus_4, pc_plus_4_carry);

   // Branch control
   reg branch;
   always @(*) begin
      branch = 0;
      case (funct3)
         `BR_BEQ: if (alu_zero) branch = 1;
         `BR_BNE: if (!alu_zero) branch = 1;
         `BR_BLT,
         `BR_BLTU: if (alu_out) branch = 1;
         `BR_BGE,
         `BR_BGEU: if (!alu_out) branch = 1;
      endcase
   end

   reg [W-1:0] rd_data_shifted;

   // Memory read/write control
   always @(*) begin
      rd_en = 0;
      wr_en = 0;
      o_addr = 0;
      wr_data = 0;
      wr_mask = 4'b1111;
      reg_rd_en = 0;
      reg_wr_en = 0;
      rd_val = 0;
      case (state)
         `ST_BOOT: begin
            o_addr = VEC_SP;
            rd_en = 1;
         end
         `ST_F_SP:  begin
            rd_val = rd_data;
            reg_wr_en = 1;
         end
         `ST_F_PC: begin
            o_addr = VEC_RESET;
            rd_en = 1;
         end
         `ST_F_INST: begin
            o_addr = pc;
            rd_en = 1;
         end
         `ST_F_REG: begin
            reg_rd_en = 1;
         end
         `ST_X_ALU_I: begin
            reg_wr_en = 1;
            rd_val = alu_out;
         end
         `ST_X_STORE: begin
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
         `ST_X_LOAD_1: begin
            o_addr = alu_out;
            rd_en = 1;
         end
         `ST_X_LOAD_2: begin
            o_addr = alu_out;
            rd_data_shifted = rd_data;
            if(W >  0 && o_addr[1:0] == 2'h0) rd_data_shifted = rd_data[W-1:0];
            if(W >  8 && o_addr[1:0] == 2'h1) rd_data_shifted = rd_data[W-1:8];
            if(W > 16 && o_addr[1:0] == 2'h2) rd_data_shifted = rd_data[W-1:16];
            if(W > 24 && o_addr[1:0] == 2'h3) rd_data_shifted = rd_data[W-1:24];
            case (funct3)
               3'h0: rd_val = { {24{rd_data_shifted[7]}}, rd_data_shifted[7:0] };
               3'h1: rd_val = { {16{rd_data_shifted[15]}}, rd_data_shifted[15:0] };
               3'h2: rd_val = rd_data_shifted;
               3'h4: rd_val = { 24'b0, rd_data_shifted[7:0] };
               3'h5: rd_val = { 16'b0, rd_data_shifted[15:0] };
            endcase
            reg_wr_en = 1;
         end
         `ST_X_JAL: begin
            rd_val = pc_plus_4;
            reg_wr_en = 1;
         end
         `ST_X_ALU_R: begin
            rd_val = alu_out;
            reg_wr_en = 1;
         end
         `ST_X_LUI: begin
            rd_val = imm;
            reg_wr_en = 1;
         end
         `ST_X_AUIPC: begin
            rd_val = alu_out;
            reg_wr_en = 1;
         end
         `ST_X_JALR: begin
            rd_val = alu_out;
            reg_wr_en = 1;
         end
      endcase
      if (o_addr == 0) wr_en = 0;
   end

   always @(*) begin
      debug = (rd_en || wr_en);
   end

   // CPU state machine
   always @(posedge clk)
   begin
      case (state)
         `ST_BOOT: begin
            pc <= pc_plus_4;
            if (pc == 64) begin
               pc <= 0;
               state <= `ST_F_SP;
            end
         end
         `ST_F_SP: begin
            state <= `ST_S_SP;
         end
         `ST_S_SP: begin
            state <= `ST_F_PC;
         end
         `ST_F_PC: begin
            if (rd_valid) begin
               pc <= rd_data;
               state <= `ST_F_INST;
            end
         end
         `ST_F_INST: begin
            state <= `ST_DECODE;
         end
         `ST_DECODE: begin
            case (rd_data[6:0])
               `OP_ALU_R: state <= `ST_F_REG;
               `OP_ALU_I: state <= `ST_F_REG;
               `OP_STORE: state <= `ST_F_REG;
               `OP_LOAD: state <= `ST_F_REG;
               `OP_JAL: state <= `ST_X_JAL;
               `OP_BRANCH: state <= `ST_F_REG;
               `OP_LUI: state <= `ST_X_LUI;
               `OP_AUIPC: state <= `ST_X_AUIPC;
               `OP_JALR: state <= `ST_F_REG;
               default: state <= `ST_FAULT;
            endcase
         end
         `ST_F_REG: begin
            case (opcode)
               `OP_ALU_I: state <= `ST_X_ALU_I;
               `OP_LOAD: state <= `ST_X_LOAD_1;
               `OP_JALR: state <= `ST_X_JALR;
               `OP_ALU_R: state <= `ST_X_ALU_R;
               `OP_STORE: state <= `ST_X_STORE;
               `OP_BRANCH: state <= `ST_X_BRANCH;
            endcase
         end
         `ST_X_LOAD_1: begin
            state <= `ST_X_LOAD_2;
         end
         `ST_X_STORE,
         `ST_X_ALU_R,
         `ST_X_ALU_I,
         `ST_X_LOAD_2,
         `ST_X_LUI,
         `ST_X_AUIPC: begin
            pc <= pc_plus_4;
            state <= `ST_F_INST;
         end
         `ST_X_JAL: begin
            pc <= alu_out;
            state <= `ST_F_INST;
         end
         `ST_X_BRANCH: begin
            if (branch)
               pc <= pc_plus_imm;
            else
               pc <= pc_plus_4;
            state <= `ST_F_INST;
         end
         `ST_X_JALR: begin
            pc <= alu_out;
            state <= `ST_F_INST;
         end
      endcase
   end

`ifdef FORMAL

   always @($global_clock)
   begin
      restrict(i_clk == !f_last_clk);
      f_last_clk <= i_clk;
   end


   always @(*)
   begin
      on_rd_en_wr_en:
         assert(!(rd_en && wr_en));

      no_zero_write:
         assert(!(o_addr == 0 && wr_en));

      valid_state:
         assert(state <= `ST_X_LOAD_2 || state == `ST_FAULT);
   end

`endif

endmodule

// vi: ft=verilog ts=3 sw=3 et
