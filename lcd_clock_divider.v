module lcd_clock_divider(
	clk,
	clk_div);
	
input clk;
output reg clk_div;

localparam clk_div_ticks = 8192 - 1;

reg  [12:0] counter; 

//we want to hit 72 us per display instruction. 
always @(posedge clk) begin
	counter <= counter+1; 
	//11-bit: clk_display inverted on every overflow of 13-bit counter -> is toggled every 50,000,000 / (2^11*2) = 12 khz -> 82 us
	//13-bit: clk_display inverted on every overflow of 13-bit counter -> is toggled every 50,000,000 / (2^13*2) = 3 khz ~= 327 us
	if(counter == clk_div_ticks) begin										
		clk_div <= ~clk_div; 
	end
end
endmodule