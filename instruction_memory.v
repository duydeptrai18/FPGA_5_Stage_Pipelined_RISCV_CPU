/*
- Each instruction is 32 bits.
- Pc moves from 0, to 4, to 8,..., or to branch offset.
- Aligned word addresses are 0, 4, 8, ... , 1020.
- address[9:2] converts the byte address into a word index:
  address 0 -> memory[0], address 4 -> memory[1], etc.

*/
module instruction_memory(
    input  [31:0] address,
    output [31:0] data
);

reg [31:0] memory [0:255];

initial begin
    //$readmemh("forwarding_test.mem", memory);
	 $readmemh("basic_isa_selftest.mem", memory);
end

// Convert byte address to word index
assign data = memory[address[9:2]];

endmodule