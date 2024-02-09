
`default_nettype none

module uart(
   input wire clk,
   input wire [4:0] addr, 
   input wire ren, output reg [7:0] rdata, output reg rd_valid,
   input wire wen, input wire [7:0] wdata,
   output reg tx, input rx
);

	initial begin
		rd_valid <= 0;
	end

   localparam BAUDRATE = 1000000;
	localparam DIVIDER = (16000000 / BAUDRATE) - 1;
   localparam IDLE = 0;
   localparam BUSY = 1;

	reg [7:0] status = 0;

	always @(*) begin
		status[0] = (tx_state == BUSY);
      status[1] = rx_avail;
	end

   // Memory mapped UART
	always @(posedge clk)
	begin
		rd_valid <= 0;
      tx_start <= 0;
      rx_clear <= 0;

		if (wen) begin
			case (addr)
				'h0: begin
               tx_data <= wdata;
               tx_start <= 1;
				end
			endcase
		end

		if (ren) begin
         rd_valid <= 1;
			case (addr)
            'h0: begin
               rdata <= rx_data;
               rx_clear <= 1;
            end
				'h4: rdata <= status;
			endcase
		end
   end

   // Receive
   reg rx_state = IDLE;
   reg [4:0] rx_bit = 0;
   reg [12:0] rx_cnt = 0;
   reg [9:0] rx_shift = 0;
   reg [7:0] rx_data = 0;
   reg rx_avail = 0;
   reg rx_clear = 0;

   always @(posedge clk)
   begin

      if(rx_clear)
         rx_avail <= 0;

      case(rx_state)
         IDLE: begin
            if(!rx) begin
               rx_cnt <= DIVIDER >> 1;
               rx_bit <= 9;
               rx_shift <= 0;
               rx_state <= BUSY;
            end
         end
         BUSY: begin
            rx_cnt <= rx_cnt - 1;
            if (rx_cnt == 0) begin
               rx_cnt <= DIVIDER;
               rx_bit <= rx_bit - 1;
               rx_shift <= {rx, rx_shift[9:1] };
               if (rx_bit == 0) begin
                  rx_data <= rx_shift >> 2;
                  rx_avail <= 1;
                  rx_state <= IDLE;
               end
            end
         end
      endcase
   end
  
   // Transmit
   reg tx_start = 0;
   reg [7:0] tx_data = 0;
   reg tx_avail = 0;
   reg [0:0] tx_state = IDLE;
	reg [4:0] tx_bit = 0;
	reg [12:0] tx_cnt = 0;
	reg [9:0] tx_shift = 0;

   always @(*)
   begin
      tx = (tx_state == BUSY) ? tx_shift[0] : 1'b1;
   end

   always @(posedge clk)
   begin
      case (tx_state)
         IDLE: begin
            if(tx_start) begin
					tx_shift <= { 1'b1, tx_data, 1'b0 };
					tx_bit <= 9;
					tx_cnt <= DIVIDER;
               tx_state <= BUSY;
               `ifdef __ICARUS__
               $write("%c", tx_data);
               `endif
            end
         end
         BUSY: begin
            tx_cnt <= tx_cnt - 1;
            if (tx_cnt == 0) begin
               tx_cnt <= DIVIDER;
               tx_bit <= tx_bit - 1;
               tx_shift <= tx_shift >> 1;
               tx_state <= (tx_bit == 0) ? IDLE : BUSY;
            end
         end
      endcase
   end

endmodule

// vi: ft=verilog ts=3 sw=3 et
