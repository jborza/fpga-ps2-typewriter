module ps2_top (
	input wire clk, 
	input wire reset, //active low
	input wire ps2d, //PS2 data
	input wire ps2c, //PS2 clock	
	output wire led,
	output wire rs, rw, en, //LCD control pins
	output wire [7:0] dat, //LCD data
	output wire [1:0] state_led,
	output wire led_ps2c
);

// signals
reg [1:0] state_reg, state_next;
wire [7:0] scan_data;
wire scan_done_tick;
wire ps2_make_break;

reg we; //ram write enable
reg [5:0] write_address;
wire [5:0] read_address;
reg [7:0] ram_in;
wire [7:0] ram_out;
wire [7:0] ascii_scan_data;
reg [5:0] current_address;
reg [5:0] current_address_next;

// states
localparam [1:0]
	idle = 2'b00,
	write_mem = 2'b01,
	send1 = 2'b10,
	done = 2'b11;

ps2_keypress_driver ps2_keypress_driver_unit(
	.clk(clk),
	.reset(~reset),
	.ps2d(ps2d),
	.ps2c(ps2c),
	.rx_en(1'b1),
	.rx_done_tick(scan_done_tick),
	.make_break(ps2_make_break),
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

//state registers
always @(posedge clk, negedge reset)
	if(~reset) begin
		state_reg <= idle; //todo also clear the memory?
		current_address <= 6'h0;
	end else
	begin
		state_reg <= state_next;
		current_address <= current_address_next;
	end

//next state logic
always @*
begin
	state_next = state_reg;
	we = 1'b0;
	ram_in = 8'h3F;
	write_address = 6'h0;
	current_address_next = current_address;
	
	case(state_reg)
	idle:
		if(scan_done_tick) //scan code received, push to display
		begin
			state_next = write_mem;	
		end
	write_mem: //write scan code
		begin
			write_address = current_address;
			ram_in = ascii_scan_data;
			we = ps2_make_break; //1 only for make codes
			state_next = done;
		end
	done: //extra tick 
		begin
			state_next = idle;
			if(ps2_make_break) begin
				current_address_next = current_address + 1;
			end
		end
	endcase
end

assign led = ~scan_done_tick;
assign state_led = ~state_reg;
assign led_ps2c = ps2c;

endmodule