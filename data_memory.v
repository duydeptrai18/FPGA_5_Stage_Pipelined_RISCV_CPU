/*
- The CPU supplies a byte address.
- This memory contains 256 entries, each storing one 32-bit word (4 bytes).
- Aligned word addresses are 0, 4, 8, ... , 1020.
- address[9:2] converts the byte address into a word index:
  address 0 -> memory[0], address 4 -> memory[1], etc.
- Bits [1:0] are ignored, so addresses 0–3 select the same word.
- This module supports aligned word accesses only.
- Reads are combinational; writes occur on the rising clock edge.
*/

module data_memory(
	input clock,
	input [31:0] address,
	input write_enable,
	input [31:0] write_data,
	
	output [31:0] read_data
);
reg [31:0] memory [0:255];

assign read_data = memory[address[9:2]];

always @(posedge clock) begin
	if(write_enable)
		memory[address[9:2]] <= write_data;
	
end
endmodule