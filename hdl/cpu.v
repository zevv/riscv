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
   output reg ren, output reg [15:0] addr, input [31:0] rdata, input rd_valid,
   output reg wen, output reg [W-1:0] wdata, output reg[3:0] wr_mask,
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
         opcode <= rdata[6:0];
         rd <= rdata[11:7];
         funct7 <= rdata[31:25];
         funct3 <= rdata[14:12];
         rs1 <= rdata[19:15];
         rs2 <= rdata[24:20];
         case (rdata[6:0])
            `OP_ALU_I: imm <= { {20{rdata[31]}}, rdata[31:20] };
            `OP_LOAD: imm <= { {20{rdata[31]}}, rdata[31:20] };
            `OP_STORE: imm <= { {20{rdata[31]}}, rdata[31:25], rdata[11:7] };
            `OP_BRANCH: imm <= { {19{rdata[31]}}, rdata[31], rdata[7], rdata[30:25], rdata[11:8], 1'b0};
            `OP_JAL: imm <= { rdata[31], rdata[31], rdata[19:12], rdata[20], rdata[30:21], 1'b0};
            `OP_JALR: imm <= { {20{rdata[31]}}, rdata[31:20] };
            `OP_LUI: imm <= { rdata[31:12], 12'b0 };
            `OP_AUIPC: imm <= { rdata[31:12], 12'b0 };
         endcase
      end
   end

   reg reg_ren = 0;
   reg reg_wen = 0;
   wire [W-1:0] rs1_val;
   wire [W-1:0] rs2_val;

   regs #(.W(W)) regs(
      .clk(clk),
      .ren(reg_ren),
      .rs1(rs1), .rs2(rs2), .rs1_val(rs1_val), .rs2_val(rs2_val),
      .wen(reg_wen), .rd(rd), .rd_val(rd_val)
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

`define ALU_X_RS1 2'h0
`define ALU_X_PC 2'h2
`define ALU_X_IMM 2'h1
`define ALU_X_ZERO 2'h3

`define ALU_Y_IMM 2'h0
`define ALU_Y_RS2 2'h1
`define ALU_Y_FOUR 2'h2

   reg [2:0] alu_x_sel;
   reg [2:0] alu_y_sel;

   // ALU control
   always @(*) begin
      alu_fn = `ALU_FN_ADD;
      alu_x_sel = `ALU_X_RS1;
      alu_y_sel = `ALU_Y_IMM;

      case (opcode)
         `OP_ALU_R: begin
            alu_fn = { funct7[5], funct3 };
            alu_y_sel = `ALU_Y_RS2;
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
            alu_y_sel = `ALU_Y_RS2;
         end
         `OP_JAL: begin
            alu_x_sel = `ALU_X_PC;
            alu_y_sel = `ALU_Y_FOUR;
         end
         `OP_AUIPC: begin
            alu_x_sel = `ALU_X_PC;
         end
         `OP_LUI: begin
            alu_x_sel = `ALU_X_ZERO;
         end
      endcase

      case (alu_x_sel)
         `ALU_X_RS1: alu_x = rs1_val;
         `ALU_X_PC: alu_x = pc;
         `ALU_X_IMM: alu_x = imm;
         `ALU_X_ZERO: alu_x = 32'd0;
      endcase

      case (alu_y_sel)
         `ALU_Y_IMM: alu_y = imm;
         `ALU_Y_RS2: alu_y = rs2_val;
         `ALU_Y_FOUR: alu_y = 32'd4;
         default: alu_y = 32'd0;
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

   reg [W-1:0] rdata_shifted;

   // Memory read/write control
   always @(*) begin
      ren = 0;
      wen = 0;
      addr = 0;
      wdata = 0;
      wr_mask = 4'b1111;
      reg_ren = 0;
      reg_wen = 0;
      rd_val = 0;
      case (state)
         `ST_BOOT: begin
            addr = VEC_SP;
            ren = 1;
         end
         `ST_F_SP:  begin
            rd_val = rdata;
            reg_wen = 1;
         end
         `ST_F_PC: begin
            addr = VEC_RESET;
            ren = 1;
         end
         `ST_F_INST: begin
            addr = pc;
            ren = 1;
         end
         `ST_F_REG: begin
            reg_ren = 1;
         end
         `ST_X_STORE: begin
            addr = alu_out;
            case (funct3)
               3'h0: wr_mask = 4'b1000;
               3'h1: wr_mask = 4'b1100;
               3'h2: wr_mask = 4'b1111;
            endcase
            case (addr[1:0])
               2'h0: begin
                  wdata = rs2_val;
               end
               2'h1: begin
                  wdata = rs2_val << 8;
                  wr_mask = wr_mask >> 1;
               end
               2'h2: begin
                  wdata = rs2_val << 16;
                  wr_mask = wr_mask >> 2;
               end
               2'h3: begin
                  wdata = rs2_val << 24;
                  wr_mask = wr_mask >> 3;
               end
            endcase
            wen = 1;
         end
         `ST_X_LOAD_1: begin
            addr = alu_out;
            ren = 1;
         end
         `ST_X_LOAD_2: begin
            addr = alu_out;
            rdata_shifted = rdata;
            if(W >  0 && addr[1:0] == 2'h0) rdata_shifted = rdata[W-1:0];
            if(W >  8 && addr[1:0] == 2'h1) rdata_shifted = rdata[W-1:8];
            if(W > 16 && addr[1:0] == 2'h2) rdata_shifted = rdata[W-1:16];
            if(W > 24 && addr[1:0] == 2'h3) rdata_shifted = rdata[W-1:24];
            case (funct3)
               3'h0: rd_val = { {24{rdata_shifted[7]}}, rdata_shifted[7:0] };
               3'h1: rd_val = { {16{rdata_shifted[15]}}, rdata_shifted[15:0] };
               3'h2: rd_val = rdata_shifted;
               3'h4: rd_val = { 24'b0, rdata_shifted[7:0] };
               3'h5: rd_val = { 16'b0, rdata_shifted[15:0] };
            endcase
            reg_wen = 1;
         end
         `ST_X_JAL,
         `ST_X_ALU_R,
         `ST_S_REG,
         `ST_X_JALR: begin
            rd_val = alu_out;
            reg_wen = 1;
         end
      endcase
      if (addr == 0) wen = 0;
   end

   always @(*) begin
      debug = (ren || wen);
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
               pc <= rdata;
               state <= `ST_F_INST;
            end
         end
         `ST_F_INST: begin
            state <= `ST_DECODE;
         end
         `ST_DECODE: begin
            case (rdata[6:0])
               `OP_ALU_R,
               `OP_ALU_I,
               `OP_STORE,
               `OP_LOAD,
               `OP_BRANCH,
               `OP_JALR: state <= `ST_F_REG;
               `OP_LUI: state <= `ST_S_REG;
               `OP_AUIPC: state <= `ST_S_REG;
               `OP_JAL: state <= `ST_X_JAL;
               default: state <= `ST_FAULT;
            endcase
         end
         `ST_F_REG: begin
            case (opcode)
               `OP_ALU_I: state <= `ST_S_REG;
               `OP_LOAD: state <= `ST_X_LOAD_1;
               `OP_JALR: state <= `ST_X_JALR;
               `OP_ALU_R: state <= `ST_S_REG;
               `OP_STORE: state <= `ST_X_STORE;
               `OP_BRANCH: state <= `ST_X_BRANCH;
            endcase
         end
         `ST_X_LOAD_1: begin
            state <= `ST_X_LOAD_2;
         end
         `ST_X_STORE,
         `ST_X_LOAD_2: begin
            pc <= pc_plus_4;
            state <= `ST_F_INST;
         end
         `ST_S_REG: begin
            pc <= pc_plus_4;
            state <= `ST_F_INST;
         end
         `ST_X_JAL: begin
            pc <= pc_plus_imm;;
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
      on_ren_wen:
         assert(!(ren && wen));

      no_zero_write:
         assert(!(addr == 0 && wen));

      valid_state:
         assert(state <= `ST_X_LOAD_2 || state == `ST_FAULT);
   end

`endif

endmodule

// vi: ft=verilog ts=3 sw=3 et
