
// https://github.com/jameslzhu/riscv-card/blob/master/riscv-card.pdf
// https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf

module cpu(
   input clk,
   output reg rd_en = 0, output reg [15:0] o_addr = 0, input [31:0] rd_data, input rd_valid,
   output reg wr_en = 0, output reg [31:0] wr_data = 0,
   output reg debug
);

   initial begin
      rd_en = 0;
      wr_en = 0;
   end

   reg [3:0] state = 0;
   reg [15:0] pc = 0;

   reg [6:0] opcode = 0;
   reg [4:0] rd = 0;
   reg [6:0] funct7 = 0;
   reg [3:0] funct3 = 0;
   reg [4:0] rs1 = 0;
   reg [4:0] rs2 = 0;
   reg signed [31:0] imm = 0;

   reg [31:0] reg_s1_data = 0;
   reg reg_s1_valid = 0;

   reg [31:0] reg_s2_data = 0;
   reg reg_s2_valid = 0;
   
   wire alu_imm = !opcode[5];
   wire [31:0] alu_in1 = reg_s1_data;;
   reg [31:0] alu_in2;
   wire [31:0] alu_out;
   wire alu_zero;
   wire alu_overflow;
   wire alu_negative;
   
   reg [3:0] alu_fn;

   always @(*) begin
      if (opcode == 7'b0110011 || opcode == 7'b1100011)
         alu_in2 = reg_s2_data;
      else
         alu_in2 = imm;

      if (opcode == 7'b0110011 || opcode == 7'b0010011)
         alu_fn = { funct7[4], funct3 };
      else if (opcode == 7'b0000011 || opcode == 7'b0100011)
         alu_fn = 4'h0; // ADD
      else
         if(funct3 == 3'h0 || funct3 == 3'h1)
            alu_fn = 4'h8; // SUB
         else
            alu_fn = 4'h2; // BLT
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
      EXECUTE = 3,
      RAM_ST = 4,
      RAM_LD_RS1 = 5,
      RAM_LD_RS2 = 6,
      RAM_LD_RD = 7,
      RAM_LD_INST = 8,
      FAULT = 15;

   localparam
      LD_TARGET_INST = 0,
      LD_TARGET_RS1 = 1,
      LD_TARGET_RS2 = 2,
      LD_TARGET_RD = 3;

   always @(*) begin
      //debug = (state == FETCH);
   end

   reg need_rs1;
   reg need_rs2;

   always @(*) begin
      need_rs1 = !(opcode == 7'b1101111 || opcode == 7'b0110111 || opcode == 7'b0010111);
      need_rs2 =  (opcode == 7'b0110011 || opcode == 7'b0100011 || opcode == 7'b1100011);
   end


   always @(posedge clk) begin

      case (state)

         BOOT: begin
            pc <= pc + 1;
            if(pc == 16) begin
               pc <= 'h80;
               state <= FETCH;
            end
         end

         FETCH: begin
            reg_s1_valid <= 0;
            reg_s2_valid <= 0;

            pc <= pc + 4;

            o_addr <= pc;
            rd_en <= 1;
            state <= RAM_LD_INST;
         end

         EXECUTE: begin

            if(need_rs1 && !reg_s1_valid) begin

               o_addr <= rs1 << 2;
               rd_en <= 1;
               state <= RAM_LD_RS1;

            end else if(need_rs2 && !reg_s2_valid) begin

               o_addr <= rs2 << 2;
               rd_en <= 1;
               state <= RAM_LD_RS2;

            end else begin

               case (opcode)
                  7'b0110011: begin // alu, R-type
                     o_addr <= rd << 2;
                     wr_data <= alu_out;
                     wr_en <= 1;
                     state <= RAM_ST;
                  end

                  7'b0010011: begin // alu, I-type
                     o_addr <= rd << 2;
                     wr_data <= alu_out;
                     wr_en <= 1;
                     state <= RAM_ST;
                  end

                  7'b0000011: begin // load, I-type
                     o_addr = alu_out;
                     rd_en <= 1;
                     state <= RAM_LD_RD;
                  end

                  7'b0100011: begin // store, S-type
                     debug <= 1;
                     o_addr = alu_out;
                     wr_data = reg_s2_data;
                     wr_en <= 1;
                     state <= RAM_ST;
                  end

                  7'b1100011: begin // branch, B-type
                     state <= FETCH;
                     case (funct3)
                        3'h0: if (alu_zero) begin // beq
                           pc <= pc - 4 + imm;
                        end
                        3'h1: if (!alu_zero) begin // bne
                           pc <= pc - 4 + imm;
                        end
                        3'h4: if (alu_out) begin // blt
                           pc <= pc - 4 + imm;
                        end
                        default: begin
                           state <= FAULT;
                        end
                     endcase
                  end

                  7'b1101111: begin // jal, J-type
                     pc <= pc + imm - 4;
                     if (rd != 0) begin
                        o_addr <= rd << 2;
                        wr_data <= pc + 4;
                        wr_en <= 1;
                        state <= RAM_ST;
                     end else begin
                        state <= FETCH;
                     end
                  end

                  7'b1100111: begin // jalr, I-type
                     pc <= reg_s1_data + imm - 4;
                     if (rd != 0) begin
                        o_addr <= rd << 2;
                        wr_data <= pc;
                        wr_en <= 1;
                        state <= RAM_ST;
                     end else begin
                        state <= FETCH;
                     end
                  end
                  
                  7'b0110111: begin // lui, U-type
                     o_addr <= rd << 2;
                     wr_data <= imm;
                     wr_en <= 1;
                     state <= RAM_ST;
                  end
                  
                  default: begin
                     state <= FAULT;
                  end

               endcase
            end
         end

         RAM_LD_INST: begin
            if (rd_valid) begin
               rd_en <= 0;

               opcode <= rd_data[6:0];
               rd <= rd_data[11:7];
               funct7 <= rd_data[31:25];
               funct3 <= rd_data[14:12];
               rs1 <= rd_data[19:15];
               rs2 <= rd_data[24:20];
               case (rd_data[6:0])
                  7'b0010011: imm <= { {20{rd_data[31]}}, rd_data[31:20] }; // I
                  7'b0000011: imm <= { {20{rd_data[31]}}, rd_data[31:20] }; // I
                  7'b0100011: imm <= { {20{rd_data[31]}}, rd_data[31:25], rd_data[11:7] }; // S
                  7'b1100011: imm <= { {19{rd_data[31]}}, rd_data[31], rd_data[7], rd_data[30:25], rd_data[11:8], 1'b0}; // B
                  7'b1101111: imm <= { rd_data[31], rd_data[31], rd_data[19:12], rd_data[20], rd_data[30:21], 1'b0}; // J
                  7'b1100111: imm <= { {20{rd_data[31]}}, rd_data[31:20] }; // I
                  7'b0110111: imm <= { rd_data[31:12], 12'b0 }; // U
                  default: imm <= 0;
               endcase

               state <= EXECUTE;
            end
         end

         RAM_LD_RS1: begin
            if (rd_valid) begin
               rd_en <= 0;
               reg_s1_data <= rd_data;
               reg_s1_valid <= 1;
               state <= EXECUTE;
            end
         end

         RAM_LD_RS2: begin
            if (rd_valid) begin
               rd_en <= 0;
               reg_s2_data <= rd_data;
               reg_s2_valid <= 1;
               state <= EXECUTE;
            end
         end

         RAM_LD_RD: begin
            if (rd_valid) begin
               rd_en <= 0;
               o_addr <= rd << 2;
               wr_data <= rd_data;
               wr_en <= 1;
               state <= RAM_ST;
            end
         end

         RAM_ST: begin
            wr_en <= 0;
            state <= FETCH;
         end

         default: begin
            state <= FAULT;
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
