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
   output reg wen, output reg [W-1:0] wdata, output reg[3:0] wmask,
   output reg debug
);

   // Instruction decoding
   reg [6:0] opcode = 0;
   reg [4:0] rd = `REG_SP;
   reg [6:0] funct7 = 0;
   reg [2:0] funct3 = 0;
   reg [4:0] rs1 = 0;
   reg [4:0] rs2 = 0;
   reg [W-1:0] imm = 0;

   always @(posedge clk)
   begin
      if(state == `ST_DECODE) begin
         opcode <= rdata[6:0];
         rd <= rdata[11:7];
         funct7 <= rdata[31:25];
         funct3 <= rdata[14:12];
         rs1 <= rdata[19:15];
         rs2 <= rdata[24:20];
         case (rdata[6:0])
            `OP_ALU_I:  imm <= { {20{rdata[31]}}, rdata[31:20] };
            `OP_LOAD:   imm <= { {20{rdata[31]}}, rdata[31:20] };
            `OP_STORE:  imm <= { {20{rdata[31]}}, rdata[31:25], rdata[11:7] };
            `OP_BRANCH: imm <= { {19{rdata[31]}}, rdata[31], rdata[7], rdata[30:25], rdata[11:8], 1'b0};
            `OP_JAL:    imm <= { rdata[31], rdata[31], rdata[19:12], rdata[20], rdata[30:21], 1'b0};
            `OP_JALR:   imm <= { {20{rdata[31]}}, rdata[31:20] };
            `OP_LUI:    imm <= { rdata[31:12], 12'b0 };
            `OP_AUIPC:  imm <= { rdata[31:12], 12'b0 };
         endcase
      end
   end

   // Register file
   reg reg_ren = 0;
   reg reg_wen = 0;
   wire [W-1:0] rs1_val;
   wire [W-1:0] rs2_val;
   reg [W-1:0] rd_val;
   regs #(W) regs(clk, reg_ren, rs1, rs2, rs1_val, rs2_val, reg_wen, rd, rd_val);

   // ALU
   reg [W-1:0] alu_x;
   reg [W-1:0] alu_y;
   reg [3:0] alu_fn;
   wire [W-1:0] alu_out;
   wire alu_zero;
   alu #(W) alu(alu_x, alu_y, alu_fn, alu_out, alu_zero);

   // ALU control
   reg [1:0] alu_x_sel;
   reg [1:0] alu_y_sel;
   always @(*) begin
      alu_fn = `ALU_FN_ADD;
      alu_x_sel = `ALU_X_RS1;
      alu_y_sel = `ALU_Y_IMM;

      case (opcode)
         `OP_ALU_R: begin
            alu_fn = { funct7[5], funct3 };
            alu_y_sel = `ALU_Y_RS2;
         end
         `OP_ALU_I:
            alu_fn = { (funct3 == 3'h1 || funct3 == 3'h5) ? imm[10] : 1'b0, funct3 };
         `OP_BRANCH: begin
            case (funct3)
               `BR_BEQ,  `BR_BNE:  alu_fn = `ALU_FN_SUB;
               `BR_BLT,  `BR_BGE:  alu_fn = `ALU_FN_LT;
               `BR_BLTU, `BR_BGEU: alu_fn = `ALU_FN_LTU;
            endcase
            alu_y_sel = `ALU_Y_RS2;
         end
         `OP_JAL, `OP_AUIPC: 
            alu_x_sel = `ALU_X_PC;
         `OP_LUI:
            alu_x_sel = `ALU_X_ZERO;
      endcase

      case (alu_x_sel)
         `ALU_X_RS1: alu_x = rs1_val;
         `ALU_X_PC: alu_x = pc;
         `ALU_X_ZERO: alu_x = 32'd0;
         default: alu_x = 32'd0;
      endcase

      case (alu_y_sel)
         `ALU_Y_IMM: alu_y = imm;
         `ALU_Y_RS2: alu_y = rs2_val;
         `ALU_Y_FOUR: alu_y = 32'd4;
         default: alu_y = imm;
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

   // Register read/write control
   always @(*) begin
      reg_ren = 0;
      reg_wen = 0;
      case (state)
         `ST_RD_REG: 
            reg_ren = 1;
         `ST_S_SP, `ST_X_LOAD_2, `ST_WB_REG, `ST_X_JAL, `ST_X_JALR:
            reg_wen = (rd != 0);
      endcase
   end
   
   always @(*) begin
      rd_val = 0;
      case (state)
         `ST_S_SP: rd_val = rdata;
         `ST_X_LOAD_2: rd_val = load_val;
         `ST_WB_REG: rd_val = alu_out;
         `ST_X_JAL, `ST_X_JALR: rd_val = pc_plus_4;
      endcase
   end

   // Memory read/write control
   reg [W-1:0] load_val;
   always @(*) begin
      ren = 0;
      wen = 0;
      addr = 0;
      wdata = 0;
      wmask = 4'b1111;
      load_val = 0;
      case (state)
         `ST_BOOT: begin
            addr = `VEC_RESET;
            ren = 1;
         end
         `ST_F_PC: begin
            addr = `VEC_RESET;
            ren = 1;
         end
         `ST_F_SP: begin
            addr = `VEC_SP;
            ren = 1;
         end
         `ST_F_INST: begin
            addr = pc;
            ren = 1;
         end
         `ST_X_STORE: begin
            addr = alu_out;
            case ({funct3[1:0], addr[1:0]})
               4'b00_00: wmask = 4'b1000;
               4'b00_01: wmask = 4'b0100;
               4'b00_10: wmask = 4'b0010;
               4'b00_11: wmask = 4'b0001;
               4'b01_00: wmask = 4'b1100;
               4'b01_10: wmask = 4'b0011;
               4'b10_00: wmask = 4'b1111;
            endcase
            wdata = rs2_val << (addr[1:0] * 8);
            wen = 1;
         end
         `ST_X_LOAD_1: begin
            addr = alu_out;
            ren = 1;
         end
         `ST_X_LOAD_2: begin
            addr = alu_out;
            case ({funct3[2:0], addr[1:0]})
               5'b000_00: load_val = { {24{rdata[7]}}, rdata[7:0] };
               5'b000_01: load_val = { {24{rdata[15]}}, rdata[15:8] };
               5'b000_10: load_val = { {24{rdata[23]}}, rdata[23:16] };
               5'b000_11: load_val = { {24{rdata[31]}}, rdata[31:24] };
               5'b001_00: load_val = { {16{rdata[15]}}, rdata[15:0] };
               5'b001_10: load_val = { {16{rdata[31]}}, rdata[31:16] };
               5'b010_00: load_val = rdata;
               5'b100_00: load_val = { 24'b0, rdata[7:0] };
               5'b100_01: load_val = { 24'b0, rdata[15:8] };
               5'b100_10: load_val = { 24'b0, rdata[23:16] };
               5'b100_11: load_val = { 24'b0, rdata[31:24] };
               5'b101_00: load_val = { 16'b0, rdata[15:0] };
               5'b101_10: load_val = { 16'b0, rdata[31:16] };
               default: load_val = 0;
            endcase
         end
      endcase

   end

   always @(*) begin
      debug = (ren || wen);
   end

   // PC control
   reg [15:0] pc = 0;
   always @(posedge clk)
   begin
      case (state)
         `ST_BOOT: pc <= (pc == 64) ? `VEC_RESET : pc_plus_4;
         `ST_F_PC: if (rd_valid) pc <= rdata;
         `ST_WB_REG, `ST_X_STORE, `ST_X_LOAD_2: pc <= pc_plus_4;
         `ST_X_BRANCH: pc <= branch ? pc_plus_imm : pc_plus_4;
         `ST_X_JAL, `ST_X_JALR: pc <= alu_out;
      endcase
   end
  
   // CPU state machine
   reg [3:0] state_next;
   always @(*)
   begin
      state_next = state;
      case (state)
         `ST_BOOT: if (pc == 64) state_next = `ST_F_PC;
         `ST_F_PC: state_next = `ST_F_SP;
         `ST_F_SP: state_next = `ST_S_SP;
         `ST_S_SP: state_next = `ST_F_INST;
         `ST_F_INST: state_next = `ST_DECODE;
         `ST_DECODE:
            case (rdata[6:0])
               `OP_ALU_R,
               `OP_ALU_I,
               `OP_STORE,
               `OP_LOAD,
               `OP_BRANCH,
               `OP_JALR: state_next = `ST_RD_REG;
               `OP_LUI,
               `OP_AUIPC: state_next = `ST_WB_REG;
               `OP_JAL: state_next = `ST_X_JAL;
               default: state_next = `ST_FAULT;
            endcase
         `ST_RD_REG:
            case (opcode)
               `OP_ALU_I,
               `OP_ALU_R: state_next = `ST_WB_REG;
               `OP_LOAD: state_next = `ST_X_LOAD_1;
               `OP_JALR: state_next = `ST_X_JALR;
               `OP_STORE: state_next = `ST_X_STORE;
               `OP_BRANCH: state_next = `ST_X_BRANCH;
            endcase
         `ST_X_LOAD_1: if(rd_valid) state_next = `ST_X_LOAD_2;
         `ST_X_LOAD_2: state_next = `ST_F_INST;
         `ST_WB_REG, `ST_X_STORE, `ST_X_BRANCH,
         `ST_X_JAL, `ST_X_JALR: state_next = `ST_F_INST;
      endcase
   end
   
   reg [3:0] state = `ST_BOOT;
   always @(posedge clk)
   begin
      state <= state_next;
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
   end

`endif

endmodule

// vi: ft=verilog ts=3 sw=3 et
