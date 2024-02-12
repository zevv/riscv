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

   reg [31:0] data_out = 0;
   reg start_stb = 0;
   
   always @(posedge clk) begin
      start_stb <= 0;
      if (ren && state == IDLE) begin
         start_stb <= 1;
         data_out <= { CMD_READ, addr + 24'h100000 };
      end
   end

   initial begin
      rdata = 0;
      mosi = 1'b0;
      sck = 1'b1;
      ss = 1'b1;
   end
  
   reg [31:0] shift_in = 0;
   reg [31:0] shift_out = 0;
   reg [2:0] state = IDLE;
   reg [4:0] bitno = 0;
   
   always @(*) begin
      ss = (state == IDLE);
      rd_valid = (state == DONE);
   end

   always @(posedge clk) begin

      case (state)
         IDLE: begin
            sck <= 1;
            if (start_stb) begin
               state <= START;
               shift_out <= data_out << 1;
               mosi <= data_out[31];
            end
         end
         START: begin
            sck <= 0;
            state <= TX;
            bitno <= 32;
            mosi <= shift_out[31];
            shift_in <= 0;
         end
         TX: begin
            sck <= ~sck;
            if (sck) begin
               if (bitno == 1) begin
                  state <= RX;
               end
               mosi <= shift_out[31];
               bitno <= bitno - 1;
               shift_out <= shift_out << 1;
            end
         end
         RX: begin
            sck <= ~sck;
            if (sck) begin
               if (bitno == 1) begin
                  state <= DONE;
               end
               bitno <= bitno - 1;
               shift_in <= (shift_in << 1) | miso;
            end
         end
         DONE: begin
            rdata <= shift_in;
            state <= IDLE;
         end

      endcase
   end

endmodule


// vi: ft=verilog ts=3 sw=3 et
