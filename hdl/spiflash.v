`default_nettype none


module spiflash(
   input wire clk,
   input wire [4:0] addr, 
   input wire ren, output reg [31:0] rdata, output reg rd_valid,
   input wire wen, input wire [7:0] wdata,
   output reg ss, input miso, output reg mosi, output reg sck
);

   localparam CMD_READ = 8'h03;

   localparam IDLE = 0, START = 1, TX = 2, RX = 3, DONE = 4;

   reg [23:0] read_addr;
   reg start_stb = 0;
   
   always @(posedge clk) begin
      start_stb <= 0;
      if (ren && state == IDLE) begin
         start_stb <= 1;
         read_addr <= addr + 'd1024 * 'd1024;
      end
   end

   initial begin
      mosi = 1'b0;
      sck = 1'b1;
      ss = 1'b1;
   end
  
   reg [31:0] shift_in = 0;
   reg [31:0] shift_out = 0;
   reg [1:0] state = IDLE;
   reg [5:0] bitno = 0;
   
   always @(*) begin
      ss = (state == IDLE);
   end

   always @(posedge clk) begin
      rd_valid <= 0;

      case (state)
         IDLE: begin
            sck <= 1;
            if (start_stb) begin
               state <= START;
            end
            shift_out <= { CMD_READ, read_addr };
         end
         START: begin
            sck <= 1'b1;
            state <= TX;
            bitno <= 32;
            mosi <= shift_out[31];
         end
         TX: begin
            sck <= ~sck;
            if (bitno == 0) begin
               bitno <= 32;
               state <= RX;
            end
            if (sck) begin
               mosi <= shift_out[31];
               bitno <= bitno - 1;
               shift_out <= shift_out << 1;
            end
         end
         RX: begin
            sck <= ~sck;
            if (bitno == 0) begin
               state <= DONE;
               rdata <= shift_in;
               rd_valid <= 1;
            end
            if (sck) begin
               shift_in = (shift_in << 1) | miso;
               bitno <= bitno - 1;
               shift_out <= shift_out << 1;
            end
         end
         DONE: 
            if (!ren) state <= IDLE;

      endcase
   end

endmodule


// vi: ft=verilog ts=3 sw=3 et
