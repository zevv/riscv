
`default_nettype none

/* verilator lint_off DECLFILENAME */

module machine(
   input clk,
   output debug,
   output led,
   output uart_tx
);


   wire cpu_rd_en;
   wire [15:0] addr;
   reg [31:0] cpu_rd_data;
   reg cpu_rd_valid;
   wire cpu_wr_en;
   wire [31:0] cpu_wr_data;

   cpu cpu0(
      .clk(clk),
      .o_addr(addr),
      .rd_en(cpu_rd_en), .rd_data(cpu_rd_data), .rd_valid(cpu_rd_valid),
      .wr_en(cpu_wr_en), .wr_data(cpu_wr_data),
      .debug(debug)
   );


   reg bram_rd_en = 0;
   wire [31:0] bram_rd_data;
   wire bram_rd_valid;
   reg bram_wr_en = 0;
   reg [12:0] bram_addr = 0;
   reg [31:0] bram_wr_data = 0;

   bram bram0(
      .clk(clk),
      .addr(bram_addr),
      .rd_en(bram_rd_en), .rd_data(bram_rd_data), .rd_valid(bram_rd_valid),
      .wr_en(bram_wr_en), .wr_data(bram_wr_data)
   );


   reg spram_rd_en = 0;
   wire [31:0] spram_rd_data;
   wire spram_rd_valid;
   reg spram_wr_en = 0;
   reg [14:0] spram_addr = 0;
   reg [31:0] spram_wr_data = 0;

   spram spram0(
      .clk(clk),
      .addr(spram_addr),
      .rd_en(spram_rd_en), .rd_data(spram_rd_data), .rd_valid(spram_rd_valid),
      .wr_en(spram_wr_en), .wr_data(spram_wr_data)
   );


   reg led_rd_en = 0;
   wire [31:0] led_rd_data;
   wire led_rd_valid;
   reg led_wr_en = 0;
   reg [15:0] led_addr = 0;
   reg [31:0] led_wr_data = 0;

   led led0(
      .clk(clk),
      .addr(led_addr),
      .rd_en(led_rd_en), .rd_data(led_rd_data), .rd_valid(led_rd_valid),
      .wr_en(led_wr_en), .wr_data(led_wr_data), .led(led)
   );

   reg uart_rd_en = 0;
   wire [7:0] uart_rd_data;
   wire uart_rd_valid;
   reg uart_wr_en = 0;
   reg [1:0] uart_addr = 0;
   reg [7:0] uart_wr_data = 0;

   uart uart0(
      .clk(clk),
      .addr(uart_addr),
      .rd_en(uart_rd_en), .rd_data(uart_rd_data), .rd_valid(uart_rd_valid),
      .wr_en(uart_wr_en), .wr_data(uart_wr_data), .tx(uart_tx)
   );

   // Bus connections / address mapping
   
   reg bram_sel;
   reg spram_sel;
   reg led_sel;
   reg uart_sel;

   always @(*) begin
      
      bram_sel  = (addr[15:12] == 4'b0000);
      led_sel   = (addr[15:12] == 4'b0100);
      uart_sel  = (addr[15:12] == 4'b0101);
      spram_sel = (addr[15:15] == 1'b1);

      bram_addr = addr[11:0];
      bram_rd_en = bram_sel && cpu_rd_en;
      bram_wr_en = bram_sel && cpu_wr_en;
      bram_wr_data = cpu_wr_data;
      
      spram_addr = addr[14:0];
      spram_rd_en = spram_sel && cpu_rd_en;
      spram_wr_en = spram_sel && cpu_wr_en;
      spram_wr_data = cpu_wr_data;

      led_addr = addr[11:0];
      led_wr_data = cpu_wr_data;
      led_rd_en = led_sel && cpu_rd_en;
      led_wr_en = led_sel && cpu_wr_en;

      uart_addr = addr[2:0];
      uart_wr_data = cpu_wr_data;
      uart_rd_en = uart_sel && cpu_rd_en;
      uart_wr_en = uart_sel && cpu_wr_en;

      cpu_rd_valid = bram_rd_valid || spram_rd_valid || led_rd_valid || uart_rd_valid;

      if (bram_sel) 
         case (addr[1:0])
            2'h0: cpu_rd_data = bram_rd_data[31:0];
            2'h1: cpu_rd_data = bram_rd_data[31:8];
            2'h2: cpu_rd_data = bram_rd_data[31:16];
            2'h3: cpu_rd_data = bram_rd_data[31:24];
         endcase
      else if (spram_sel)
         cpu_rd_data = spram_rd_data;
      else if (led_sel) 
         cpu_rd_data = led_rd_data;
      else if (uart_sel) 
         cpu_rd_data = uart_rd_data;
      else
         cpu_rd_data = 0;

   end

endmodule



module bram(
   input wire clk,
   input wire rd_en, input wire [12:0] addr, output reg [31:0] rd_data, output reg rd_valid,
   input wire wr_en, input wire [31:0] wr_data
);

   localparam SIZE = 2048;

   reg [31:0] mem [0:SIZE-1];

   wire [31:0] zero = mem[0];
   wire [31:0] ra = mem[1];
   wire [31:0] sp = mem[2];
   wire [31:0] x8 = mem[8];
   wire [31:0] a0 = mem[10];
   wire [31:0] a1 = mem[11];
   wire [31:0] a2 = mem[12];
   wire [31:0] a3 = mem[13];
   wire [31:0] a4 = mem[14];

   initial begin
      $readmemh("../src/t.mem", mem);
   end

   always @(posedge clk)
   begin
      if (rd_en) begin
         rd_data = mem[addr >> 2];
         rd_valid <= 1;
      end else begin
         rd_valid <= 0;
      end
      if(wr_en) begin
         mem[addr>>2] <= wr_data;
      end
   end

endmodule


module spram(
   input wire clk,
   input wire rd_en, input wire [14:0] addr, output [31:0] rd_data, output reg rd_valid,
   input wire wr_en, input wire [31:0] wr_data
);

   wire [13:0] spram_addr = addr >> 2;

   SB_SPRAM256KA spram_l (
      .ADDRESS(spram_addr),
      .DATAIN(wr_data[15: 0]),
      .MASKWREN(4'b1111),
      .WREN(wr_en),
      .CHIPSELECT(1'b1),
      .CLOCK(clk),
      .STANDBY(1'b0),
      .SLEEP(1'b0),
      .POWEROFF(1'b1),
      .DATAOUT(rd_data[15:0])
   );

   SB_SPRAM256KA spram_h (
      .ADDRESS(spram_addr),
      .DATAIN(wr_data[31:16]),
      .MASKWREN(4'b1111),
      .WREN(wr_en),
      .CHIPSELECT(1'b1),
      .CLOCK(clk),
      .STANDBY(1'b0),
      .SLEEP(1'b0),
      .POWEROFF(1'b1),
      .DATAOUT(rd_data[31:16])
   );

   always @(posedge clk)
   begin
      if (rd_en) begin
         rd_valid <= 1;
      end else begin
         rd_valid <= 0;
      end
   end

endmodule


module SB_SPRAM256KA (
	input [13:0] ADDRESS,
	input [15:0] DATAIN,
	input [3:0] MASKWREN,
	input WREN, CHIPSELECT, CLOCK, STANDBY, SLEEP, POWEROFF,
	output reg [15:0] DATAOUT
);
	reg [15:0] mem [0:16383];
	wire off = SLEEP || !POWEROFF;
	integer i;

	always @(negedge POWEROFF) begin
		for (i = 0; i <= 16383; i = i+1)
			mem[i] = 16'bx;
	end

	always @(posedge CLOCK, posedge off) begin
		if (off) begin
			DATAOUT <= 0;
		end else
		if (STANDBY) begin
			DATAOUT <= 16'bx;
		end else
		if (CHIPSELECT) begin
			if (!WREN) begin
				DATAOUT <= mem[ADDRESS];
			end else begin
				if (MASKWREN[0]) mem[ADDRESS][ 3: 0] <= DATAIN[ 3: 0];
				if (MASKWREN[1]) mem[ADDRESS][ 7: 4] <= DATAIN[ 7: 4];
				if (MASKWREN[2]) mem[ADDRESS][11: 8] <= DATAIN[11: 8];
				if (MASKWREN[3]) mem[ADDRESS][15:12] <= DATAIN[15:12];
				DATAOUT <= 16'bx;
			end
		end
	end
endmodule

// vi: ft=verilog ts=3 sw=3 et
