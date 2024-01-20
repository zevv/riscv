
// https://github.com/jameslzhu/riscv-card/blob/master/riscv-card.pdf
// https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf

/* verilator lint_off DECLFILENAME */


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
      LUI = 8,
      ALU = 9,
      STORE = 10,
      STORE2 = 11,
      JAL = 12,
      FAIL = 15;


   reg [7:0] pc = 0;
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
            case (inst[6:0])

               7'b0010011: begin // ALU, I-type
                  imm <= inst[31:20];
                  rs1 <= inst[19:15];
                  funct3 <= inst[14:12];
                  rd <= inst[11:7];
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
            case (funct3)
               3'b000: begin // ADDI
                  //$display("  addi x%d, x%d, %d", rd, rs1, imm);
                  x[rd] <= x[rs1] + imm;
                  state <= FETCH;
               end
               default:
                  state <= FAIL;
            endcase
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




module machine(
   input clk,
   output debug
);

   reg ram_rd_en = 0;
   reg [15:0] ram_rd_addr;
   wire [31:0] ram_rd_data;
   wire ram_rd_valid;
   reg ram_wr_en = 0;
   reg [15:0] ram_wr_addr = 0;
   reg [31:0] ram_wr_data = 0;

   ram ram0(
      .clk(clk),
      .rd_en(ram_rd_en), .rd_addr(ram_rd_addr), .rd_data(ram_rd_data), .rd_valid(ram_rd_valid),
      .wr_en(ram_wr_en), .wr_addr(ram_wr_addr), .wr_data(ram_wr_data)
   );


   reg led_rd_en = 0;
   reg [15:0] led_rd_addr;
   wire [31:0] led_rd_data;
   wire led_rd_valid;
   reg led_wr_en = 0;
   reg [15:0] led_wr_addr = 0;
   reg [31:0] led_wr_data = 0;

   led led0(
      .clk(clk),
      .rd_en(led_rd_en), .rd_addr(led_rd_addr), .rd_data(led_rd_data), .rd_valid(led_rd_valid),
      .wr_en(led_wr_en), .wr_addr(led_wr_addr), .wr_data(led_wr_data), .led(debug)
   );


   wire cpu_rd_en;
   wire [15:0] cpu_rd_addr;
   reg [31:0] cpu_rd_data;
   reg cpu_rd_valid;
   wire cpu_wr_en;
   wire [15:0] cpu_wr_addr;
   wire [31:0] cpu_wr_data;

   cpu cpu0(
      .clk(clk),
      .rd_en(cpu_rd_en), .rd_addr(cpu_rd_addr), .rd_data(cpu_rd_data), .rd_valid(cpu_rd_valid),
      .wr_en(cpu_wr_en), .wr_addr(cpu_wr_addr), .wr_data(cpu_wr_data)
   );


   // Bus arbiter

   always @(*) begin
      
      cpu_rd_valid = 0;
      cpu_rd_data = 0;

      ram_rd_en = 0;
      ram_rd_addr = 0;
      ram_wr_en = 0;
      ram_wr_addr = 0;
      ram_wr_data = 0;

      led_rd_en = 0;
      led_wr_en = 0;
      led_rd_addr = 0;
      led_wr_addr = 0;
      led_wr_data = 0;

      if (cpu_rd_en) begin

         if (cpu_rd_addr[15:12] == 4'h0) begin
            ram_rd_en = cpu_rd_en;
            ram_rd_addr = cpu_rd_addr[11:0];
         end 
      
         if (cpu_rd_addr[15:12] == 4'b1) begin
            led_rd_en = cpu_rd_en;
            led_rd_addr = cpu_rd_addr[11:0];
         end 
      end

      if (cpu_wr_en) begin

         if(cpu_wr_addr[15:12] == 4'h0) begin
            ram_wr_en = cpu_wr_en;
            ram_wr_addr = cpu_wr_addr[11:0];
            ram_wr_data = cpu_wr_data;
         end
         
         if (cpu_wr_addr[15:12] == 4'b1) begin
            led_wr_en = cpu_wr_en;
            led_wr_addr = cpu_wr_addr[11:0];
            led_wr_data = cpu_wr_data;
         end
      end

      if(ram_rd_valid) begin
         cpu_rd_data = ram_rd_data;
         cpu_rd_valid = ram_rd_valid;
      end

      if(led_rd_valid) begin
         cpu_rd_data = led_rd_data;
         cpu_rd_valid = led_rd_valid;
      end

   end

endmodule


module ram(
   input wire clk,
   input wire rd_en, input wire [15:0] rd_addr, output reg [31:0] rd_data, output reg rd_valid,
   input wire wr_en, input wire [15:0] wr_addr, input wire [31:0] wr_data
);

   localparam SIZE = 256;

   reg [31:0] memory [0:SIZE-1];

   initial begin
      $readmemh("../src/t.mem", memory);
   end

   always @(posedge clk)
   begin
      rd_valid <= 0;
      if (rd_en && (rd_addr < SIZE*4)) begin
         rd_data <= memory[rd_addr>>2];
         rd_valid <= 1;
      end
      if(wr_en) begin
         memory[wr_addr>>2] <= wr_data;
      end
   end

endmodule


module led(
   input wire clk,
   input wire rd_en, input wire [15:0] rd_addr, output reg [31:0] rd_data, output reg rd_valid,
   input wire wr_en, input wire [15:0] wr_addr, input wire [31:0] wr_data,
   output led
);

   reg [31:0] val = 0;

   always @(posedge clk)
   begin
      rd_valid <= 0;
      if(rd_en) begin
         if (rd_addr == 0) begin
            //$display("LED rd %d", val);
            rd_data <= val;
            rd_valid <= 1;
         end
      end
      if(wr_en) begin
         if (wr_addr == 0) begin
            //$display("LED wr %d", wr_data);
            val <= wr_data;
         end
      end
   end

   assign led = val[20];

endmodule


// vi: ft=verilog ts=3 sw=3 et
