module ps2_keypress_driver (
	input wire clk, reset,
	input wire ps2d, //PS2 data
	input wire ps2c, //PS2 clock
	input wire rx_en, //receiver enable
	output reg rx_done_tick,
	output reg make_break, //1 when make, 0 when break
	output reg [7:0] dout //PS2 scancode of the last byte
);

//signals
wire scan_done_tick;
wire [7:0] scan_data;
reg [2:0] state_reg, state_next;
reg break_toggled;

localparam [7:0] break_code = 8'hF0;
localparam [7:0] extend_code = 8'hE0;
localparam [7:0] extend_code_1 = 8'hE1;

//wire in ps2 receiver
ps2_rx ps2_rx_unit(
	.clk(clk),
	.reset(reset),
	.ps2d(ps2d),
	.ps2c(ps2c),
	.rx_en(rx_en),
	.rx_done_tick(scan_done_tick),
	.dout(scan_data)
);


// or we can just ignore E0, E1, and remember the break code 
// E0 is followed by one scancode, E1 is followed by two codes. Let's think about E1 (pause/printscr) later

always @(posedge clk, posedge reset)
	if(reset) begin
		break_toggled <= 1'b0;
		rx_done_tick <= 1'b0;
	end
	else begin
		if(scan_done_tick) begin
				if(scan_data == extend_code || scan_data == extend_code_1) begin //do nothing for this case
					// 
				end
				else if(scan_data == break_code)
				begin
					break_toggled <= 1'b1;
				end
				else begin //the actual key code, send out the output
					rx_done_tick <= 1'b1;
					make_break <= ~break_toggled;
					break_toggled <= 1'b0; //reset, so we can listen for a new break code
					dout <= scan_data;
				end
		end
		else begin
			rx_done_tick <= 1'b0;
		end
	end

endmodule