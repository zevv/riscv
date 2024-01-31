
// https://github.com/jameslzhu/riscv-card/blob/master/riscv-card.pdf
// https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf

`include "alu.v"
`include "common.v"


module cpu
#(
   parameter W = 32
)
(
   input clk,
   output reg rd_en, output reg [15:0] o_addr, input [31:0] rd_data, input rd_valid,
   output reg wr_en, output reg [31:0] wr_data, output reg[3:0] wr_mask,
   output reg debug
);
   
   localparam
      VEC_RESET = 16'h0080,
      VEC_SP    = 16'h0084;

   // CPU state
   reg [4:0] state = 0;
   reg [15:0] pc = 0;
   reg [W-1:0] rd_val = 0;
   reg [W-1:0] rs1_val = 0;
   reg [W-1:0] rs2_val = 0;
   
   // Decoded instruction
   reg [31:0] inst = 0;
   reg [6:0] opcode;
   reg [4:0] rd;
   reg [6:0] funct7;
   reg [2:0] funct3;
   reg [4:0] rs1;
   reg [4:0] rs2;
   reg signed [W-1:0] imm = 0;
   
   // Instruction decoding
   always @(*) begin
      opcode = inst[6:0];
      rd = inst[11:7];
      funct7 = inst[31:25];
      funct3 = inst[14:12];
      rs1 = inst[19:15];
      rs2 = inst[24:20];
      imm = 0;
      case (inst[6:0])
         `OP_ALU_I:  imm = { {20{inst[31]}}, inst[31:20] };
         `OP_LOAD:   imm = { {20{inst[31]}}, inst[31:20] };
         `OP_STORE:  imm = { {20{inst[31]}}, inst[31:25], inst[11:7] };
         `OP_BRANCH: imm = { {19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
         `OP_JAL:    imm = { {12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
         `OP_JALR:   imm = { {20{inst[31]}}, inst[31:20] };
         `OP_LUI:    imm = { inst[31:12], 12'b0 };
         `OP_AUIPC:  imm = { inst[31:12], 12'b0 };
      endcase
   end

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
      alu_fn = 0;
      alu_x = rs1_val;
      alu_y = imm;
      case (inst[6:0])
         `OP_ALU_R: begin
            alu_fn = { funct7[5], funct3 };
            alu_y = rs2_val;
         end
         `OP_ALU_I: begin
            alu_fn = { (funct3 == 3'h1 || funct3 == 3'h5) ? imm[10] : 1'b0, funct3 };
         end
         `OP_LOAD: begin
            alu_fn = 4'h0; // ADD
         end
         `OP_STORE: begin
            alu_fn = 4'h0; // ADD
         end
         `OP_BRANCH: begin
            case (funct3)
               `BR_BEQ: alu_fn = 4'h8;
               `BR_BNE: alu_fn = 4'h8;
               `BR_BLT: alu_fn = 4'h2;
               `BR_BGE: alu_fn = 4'h2;
               `BR_BLTU: alu_fn = 4'h3;
               `BR_BGEU: alu_fn = 4'h3;
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
            alu_fn = 4'h0; // ADD
            alu_x = pc;
         end
      endcase
   end

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

   reg [31:0] rd_data_shifted;
   always @(*) begin
      case (o_addr[1:0])
         2'h0: rd_data_shifted = rd_data[31:0];
         2'h1: rd_data_shifted = rd_data[31:8];
         2'h2: rd_data_shifted = rd_data[31:16];
         2'h3: rd_data_shifted = rd_data[31:24];
      endcase
   end

   // Memory read/write control
   always @(*) begin
      rd_en = 0;
      wr_en = 0;
      o_addr = 0;
      wr_data = 0;
      wr_mask = 4'b1111;

      case (state)
         `ST_BOOT: begin
            o_addr = VEC_SP;
            rd_en = 1;
         end
         `ST_F_SP:  begin
            o_addr = (2 << 2);
            wr_data = rd_data;
            wr_en = 1;
         end
         `ST_F_PC: begin
            o_addr = VEC_RESET;
            rd_en = 1;
         end
         `ST_L_INST: begin
            o_addr = pc;
            rd_en = 1;
         end
         `ST_F_INST: begin
         end
         `ST_F_RS1: begin
            o_addr = (rs1 << 2);
            rd_en = 1;
         end
         `ST_F_RS2: begin
            o_addr = (rs2 << 2);
            rd_en = 1;
         end
         `ST_X_ALU_I_2: begin
            o_addr = (rd << 2);
            wr_data = alu_out;
            wr_en = 1;
         end
         `ST_X_STORE_1: begin
         end
         `ST_X_STORE_2: begin
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
         end
         `ST_X_LOAD_2: begin
            o_addr = alu_out;
            rd_en = 1;
         end
         `ST_X_LOAD_3: begin
            o_addr = alu_out;
         end
         `ST_X_LOAD_4: begin
            o_addr = (rd << 2);
            wr_data = rd_val;
            wr_en = 1;
         end
         `ST_X_JAL_1: begin
            o_addr = (rd << 2);
            wr_data = pc + 4;
            wr_en = 1;
         end
         `ST_X_ALU_R_2: begin
            o_addr = (rd << 2);
            wr_data = alu_out;
            wr_en = 1;
         end
         `ST_X_LUI: begin
            o_addr = (rd << 2);
            wr_data = imm;
            wr_en = 1;
         end
         `ST_X_AUIPC: begin
            o_addr = (rd << 2);
            wr_data = alu_out;
            wr_en = 1;
         end
         `ST_X_JALR_2: begin
            o_addr = (rd << 2);
            wr_data = alu_out;
            wr_en = 1;
         end
      endcase
      if (o_addr == 0) wr_en = 0;
   end

   always @(*) begin
      debug = (opcode == `OP_JAL);
   end

   // CPU state machine
   always @(posedge clk)
   begin
      case (state)
         `ST_BOOT: begin
            pc <= pc + 4;
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
               state <= `ST_L_INST;
            end
         end
         `ST_L_INST: begin
            state <= `ST_F_INST;
         end
         `ST_F_INST: begin
            inst <= rd_data;
            case (rd_data[6:0])
               `OP_ALU_R: state <= `ST_F_RS1;
               `OP_ALU_I: state <= `ST_F_RS1;
               `OP_STORE: state <= `ST_F_RS1;
               `OP_LOAD: state <= `ST_F_RS1;
               `OP_JAL: state <= `ST_X_JAL_1;
               `OP_BRANCH: state <= `ST_F_RS1;
               `OP_LUI: state <= `ST_X_LUI;
               `OP_AUIPC: state <= `ST_X_AUIPC;
               `OP_JALR: state <= `ST_F_RS1;
               default: state <= `ST_FAULT;
            endcase
         end
         `ST_F_RS1: begin
            case (opcode)
               `OP_ALU_R: state <= `ST_F_RS2;
               `OP_ALU_I: state <= `ST_X_ALU_I_1;
               `OP_STORE: state <= `ST_F_RS2;
               `OP_LOAD: state <= `ST_X_LOAD_1;
               `OP_BRANCH: state <= `ST_F_RS2;
               `OP_JALR: state <= `ST_X_JALR_1;
            endcase
         end
         `ST_F_RS2: begin
            rs1_val <= rd_data;
            case (opcode)
               `OP_ALU_R: state <= `ST_X_ALU_R_1;
               `OP_STORE: state <= `ST_X_STORE_1;
               `OP_BRANCH: state <= `ST_X_BRANCH_1;
            endcase
         end
         `ST_X_ALU_I_1: begin
            rs1_val <= rd_data;
            state <= `ST_X_ALU_I_2;
         end
         `ST_X_ALU_I_2: begin
            state <= `ST_L_INST;
            pc <= pc + 4;
         end
         `ST_X_STORE_1: begin
            rs2_val <= rd_data;
            state <= `ST_X_STORE_2;
         end
         `ST_X_STORE_2: begin
            pc <= pc + 4;
            state <= `ST_L_INST;
         end
         `ST_X_LOAD_1: begin
            rs1_val <= rd_data;
            state <= `ST_X_LOAD_2;
         end
         `ST_X_LOAD_2: begin
            state <= `ST_X_LOAD_3;
         end
         `ST_X_LOAD_3: begin
            case (funct3)
               3'h0: rd_val = { {24{rd_data_shifted[7]}}, rd_data_shifted[7:0] };
               3'h1: rd_val = { {16{rd_data_shifted[15]}}, rd_data_shifted[15:0] };
               3'h2: rd_val = rd_data_shifted;
               3'h4: rd_val = { 24'b0, rd_data_shifted[7:0] };
               3'h5: rd_val = { 16'b0, rd_data_shifted[15:0] };
            endcase
            state <= `ST_X_LOAD_4;
         end
         `ST_X_LOAD_4: begin
            pc <= pc + 4;
            state <= `ST_L_INST;
         end
         `ST_X_JAL_1: begin
            pc <= alu_out;
            state <= `ST_L_INST;
         end
         `ST_X_BRANCH_1: begin
            rs2_val <= rd_data;
            state <= `ST_X_BRANCH_2;
         end
         `ST_X_BRANCH_2: begin
            if (branch)
               pc <= pc + imm; // TODO ALU
            else
               pc <= pc + 4;
            state <= `ST_L_INST;
         end
         `ST_X_ALU_R_1: begin
            rs2_val = rd_data;
            state <= `ST_X_ALU_R_2;
         end
         `ST_X_ALU_R_2: begin
            pc <= pc + 4;
            state <= `ST_L_INST;
         end
         `ST_X_LUI: begin
            pc <= pc + 4;
            state <= `ST_L_INST;
         end
         `ST_X_AUIPC: begin
            pc <= pc + 4;
            state <= `ST_L_INST;
         end
         `ST_X_JALR_1: begin
            rs1_val <= rd_data;
            state <= `ST_X_JALR_2;
         end
         `ST_X_JALR_2: begin
            pc <= alu_out;
            state <= `ST_L_INST;
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
         assert(state <= `ST_X_LOAD_4 || state == `ST_FAULT);
   end

`endif

endmodule

// vi: ft=verilog ts=3 sw=3 et
