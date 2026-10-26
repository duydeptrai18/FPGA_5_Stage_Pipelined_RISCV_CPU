/*
- Read is asynchronous
- Write to x0 is not possible
- xo always give 0.
*/

module registers_file(
	input clock,
	input write_enable,
	input [4:0] read_address_1,
	input [4:0] read_address_2,
	input [4:0] write_address,
	input [31:0] write_data,
	
	output  [31:0] read_data_1,
	output  [31:0] read_data_2
	
);

reg [31:0] registers [0:31];

assign read_data_1 = (read_address_1 ==0) ? 32'd0 : registers[read_address_1];
assign read_data_2 = (read_address_2 ==0) ? 32'd0 : registers[read_address_2];

always @(posedge clock) begin
	if(write_enable == 1'd1 && (write_address != 5'd0)) registers[write_address] <= write_data;
	
end

endmodule