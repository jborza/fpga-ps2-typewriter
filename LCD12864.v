//let's have a module that displays data off 64-byte RAM
// connected to a [7:0] ram[63:0]
	module LCD12864 (clk, rs, rw, en, dat, address_out, data_in);  
 input clk;  
 output rs,rw,en;
 output [7:0] dat; 
 output reg [5:0] address_out; //goes to the RAM
 input [7:0] data_in;      //comes from the RAM
 
 reg [7:0] dat; 
 reg rs;   
 reg [3:0] current,next;
 wire clk_display; 

 //x coordinate on the current line (column)
 reg [3:0] x;
 
 // state machine states
 localparam  set0=4'h0; 
 localparam  set1=4'h1; 
 localparam  set2=4'h2; 
 localparam  set3=4'h3; 
 localparam  move_to_row1=4'h4; 
 localparam  move_to_row2=4'h5;
 localparam  move_to_row3=4'h6;  

 localparam  row0=4'h7; 
 localparam  row1=4'h8; 
 localparam  row2=4'h9; 
 localparam  row3=4'hA;    
  
 localparam  loop=4'hF; 
 // end of state machine states
 
 // line offsets
 localparam line0=8'h80;
 localparam line1=8'h90;
 localparam line2=8'h88;
 localparam line3=8'h98;
 
 // ST7920 display instructions
 localparam SET_8BIT_BASIC_INSTR = 8'b00110000;
 localparam SET_DISP_ON_CURSOR_OFF_BLINK_OFF = 8'b00001100;
 localparam SET_CURSOR_POS = 8'b00000110;
 localparam CLEAR = 8'h1;
 localparam STANDBY = 8'b00000000;
 localparam HOME = 8'b00000010;
 
 task write_characters_row;
	input [2:0] y;
	input [3:0] next_state;

	begin
		rs <= 1;
		dat <= data_in;//
		address_out <= y*16 + x + 1;
		x <= x + 4'h1;
		if(x == 15) begin
			next <= next_state;
		end
	end
 endtask
 
 task command;
	input [7:0] data;
	input [3:0] next_state;
	
	begin
		rs <= 0;
		dat <= data;
		next <= next_state;
	end
 endtask
 
  lcd_clock_divider divider(
	.clk(clk),
	.clk_div(clk_display)
 );


always @(posedge clk_display) 
begin 
 current=next; 
  case(current) 
    //initialize display mode
    set0: begin command(SET_8BIT_BASIC_INSTR, set1); end
    set1: begin command(SET_DISP_ON_CURSOR_OFF_BLINK_OFF, set2); end  
    set2: begin command(SET_CURSOR_POS, set3); end  
    set3: begin command(SET_8BIT_BASIC_INSTR, row0); x <= 0; address_out <= 0; end
	 
	 row0: begin
		write_characters_row(0, move_to_row1);
	 end

    move_to_row1:   begin command(line1, row1); x <= 0; address_out <= 16; end 
	 
	 row1: begin
		write_characters_row(1, move_to_row2);
	 end

    move_to_row2:   begin command(line2, row2); x <= 0; address_out <= 32; end 
	 
	 row2: begin
		write_characters_row(2, move_to_row3);
	 end

    move_to_row3:   begin command(line3, row3); x <= 0; address_out <= 48; end
	 
	 row3: begin
		write_characters_row(3, loop);
	 end
	 
	 loop: begin command(HOME, set0);
	  end
   default:   next=set0; 
    endcase 
 end 
assign en=clk_display; 
assign rw=0; 
endmodule  