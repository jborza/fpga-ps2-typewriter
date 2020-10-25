module ps2_top (
	input wire clk, reset,
	input wire ps2d, //PS2 data
	input wire ps2c, //PS2 clock	
	output wire led,
	output wire rs, rw, en, //LCD control pins
	output wire [7:0] dat //LCD data
);

// signals
reg [1:0] state_reg, state_next;
wire [7:0] scan_data;
wire scan_done_tick;

reg we; //ram write enable
reg [5:0] write_address;
wire [5:0] read_address;
reg [7:0] ram_in;
wire [7:0] ram_out;
wire [7:0] ascii_scan_data;

// states
localparam [1:0]
	idle = 2'b00,
	send1 = 2'b01,
	send0 = 2'b10,
	done = 2'b11;

// PS2 receiver
ps2_rx ps2_rx_unit(
	.clk(clk),
	.reset(reset),
	.ps2d(ps2d),
	.ps2c(ps2c),
	.rx_done_tick(scan_done_tick),
	.dout(scan_data)
);

// character buffer
ram ram(
   .clk(clk),
	.q(ram_out), 
	.d(ram_in), 
	.write_address(write_address), 
	.read_address(read_address), 
	.we(we)
);

// display controller
LCD12864 lcd(
		.clk(clk),
		.rs(rs), 
		.rw(rw), 
		.en(en), 
		.dat(dat),
		.address_out(read_address),
		.data_in(ram_out)
);

key2ascii key2ascii(
	.key_code(scan_data),
	.ascii_code(ascii_scan_data)
);




always @(posedge clk, posedge reset)
	if(reset)
		state_reg <= idle; //todo also clear the memory?
	else
		state_reg <= state_next;

always @*
begin
	case(state_reg)
	idle:
		if(scan_done_tick) //scan code received, push to display
		begin
			state_next = send1;	
		end
	send1: //higher hex character
		begin
			write_address = 5'h0;
			ram_in = scan_data;
			we = 1'b1;
			state_next = send0;
		end
	send0:
		begin
			ram_in = ascii_scan_data;
			write_address = 5'h1;
			we = 1'b1;
			state_next = done;
		end
	done:
		state_next = idle;
	endcase
end

assign led = scan_done_tick;

endmodule