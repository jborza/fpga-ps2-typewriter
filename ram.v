module ram(
	clk, 
	read_address,
	d,
	write_address,
	q,
	we
);
	//inputs, outputs
	input wire clk;
	input [5:0] read_address;
	input [7:0] d; //input data
	input [5:0] write_address;
	output reg [7:0] q; //output data
	input  we;

	reg [7:0] mem [63:0];
	
	always @(posedge clk) begin
		if(we) begin
			mem[write_address] <= d;
		end
		q <= mem[read_address];
	end

endmodule