/*
This file test all forwarding and stall and flush cases
Create normal test cases later without forwarding or stall
*/


`timescale 1ns/1ps
module cpu_top_tb;
    reg clock;
    reg reset_n;
	 wire [31:0] debug_pc;
    integer errors;
	 integer i;

cpu_top cpu_top_dut(
  .clock(clock),
  .reset_n(reset_n),
  .debug_pc(debug_pc)
);

localparam R_TYPE = 7'b0110011;
localparam I_TYPE = 7'b0010011;
localparam LOAD   = 7'b0000011;
localparam STORE  = 7'b0100011;
localparam BRANCH = 7'b1100011;
localparam JAL    = 7'b1101111;
localparam JALR   = 7'b1100111;
localparam LUI    = 7'b0110111;
localparam AUIPC  = 7'b0010111;

task check_register;
	input [4:0] read_address;
	input [31:0] expected_read_data;
	begin
	  if (cpu_top_dut.registers_unit.registers[read_address] !== expected_read_data) begin
			errors = errors + 1;
			$display("FAILED! Register x%0d: actual=%h expected=%h",read_address, cpu_top_dut.registers_unit.registers[read_address],
						expected_read_data);
	  end
	  else begin
			$display("PASSED! Register x%0d: data=%h",read_address,
						cpu_top_dut.registers_unit.registers[read_address]);
	  end
	end
endtask

task check_data_memory;
	input [31:0] read_address;
	input [31:0] expected_read_data;
	begin
	  if (cpu_top_dut.data_memory_unit.memory[read_address[9:2]] !== expected_read_data) begin
			errors = errors + 1;
			$display("FAILED! Data memory address=%h: actual=%h expected=%h",read_address, cpu_top_dut.data_memory_unit.memory[read_address[9:2]],
						expected_read_data);
	  end
	  else begin
			$display("PASSED! Data memory address=%h: data=%h",read_address,
						cpu_top_dut.data_memory_unit.memory[read_address[9:2]]);
	  end
	end
endtask

task check_pc;
	input [31:0] expected_pc;
	begin
	  if (cpu_top_dut.program_counter_unit.pc !== expected_pc) begin
			errors = errors + 1;
			$display("FAILED! PC: actual=%h expected=%h",cpu_top_dut.program_counter_unit.pc,
						expected_pc);
	  end
	  else begin
			$display("PASSED! PC: %h",
						cpu_top_dut.program_counter_unit.pc);
	  end
	end
endtask

task check_if_id_pc;
	input [31:0] expected_pc;
	begin
	  if (cpu_top_dut.if_id_pc !== expected_pc) begin
			errors = errors + 1;
			$display("FAILED! if_id_pc: actual=%h expected=%h",cpu_top_dut.if_id_pc,
						expected_pc);
	  end
	  else begin
			$display("PASSED! if_id_pc: %h",
						cpu_top_dut.if_id_pc);
	  end
	end
endtask


task check_immediate;
	input [31:0] expected_immediate;
	begin
	  if (cpu_top_dut.immediate_generator_unit.immediate !== expected_immediate) begin
			errors = errors + 1;
			$display("FAILED! Immediate: actual=%h expected=%h",cpu_top_dut.immediate_generator_unit.immediate,
						expected_immediate);
	  end
	  else begin
			$display("PASSED! Immediate: %h",
						cpu_top_dut.immediate_generator_unit.immediate);
	  end
	end
endtask

initial begin
	clock = 1'b0;
	forever #5 clock = ~clock;
end

initial begin

    reset_n = 1'b0;
    errors = 0;


    #1;

    // Fill unused locations with NOPs.
    for (i = 0; i < 256; i = i + 1)
        cpu_top_dut.instruction_memory_unit.memory[i] = 32'h00000013;
		  
		  
	/*
	memoery0 = addi x1,x0,5
	m1 = addi x2,x0,0
	m2 = addi x2,x2,1
	m3 = bne x1,x2, -4
	m4 = jal x0, 0


	*/
		  
		  
	/*cpu_top_dut.instruction_memory_unit.memory[0] =
    {12'd2, 5'd0, 3'b000, 5'd1, I_TYPE}; // addi x1, x0, 2

cpu_top_dut.instruction_memory_unit.memory[1] =
    {12'd2, 5'd0, 3'b000, 5'd2, I_TYPE}; // addi x2, x0, 2

cpu_top_dut.instruction_memory_unit.memory[2] =
    {7'd0, 5'd2, 5'd1, 3'b000, 4'd6, 1'b0, BRANCH}; // beq x1, x2, +12 -> memory[5]

// Wrong path: both instructions must be flushed.
cpu_top_dut.instruction_memory_unit.memory[3] =
    {12'd99, 5'd0, 3'b000, 5'd3, I_TYPE}; // addi x3, x0, 99

cpu_top_dut.instruction_memory_unit.memory[4] =
    {12'd88, 5'd0, 3'b000, 5'd4, I_TYPE}; // addi x4, x0, 88

// Correct branch target.
cpu_top_dut.instruction_memory_unit.memory[5] =
    {12'd42, 5'd0, 3'b000, 5'd5, I_TYPE}; // addi x5, x0, 42
	 
	 #1;
	 reset_n=1'b1;
	 
	 
	 repeat (15) @(posedge clock);
	 #1;
	 
    check_register(5'd3,  32'dX);
    check_register(5'd4,  32'dX);	 
    check_register(5'd5,  32'd42);	 
	 
	 
	 */
	 
	 

	 
    // Shared operand: x1 = 4.
    // Entries 1–3 remain NOPs so x1 is ready before test 1.
    cpu_top_dut.instruction_memory_unit.memory[0] =
        {12'd4, 5'd0, 3'b000, 5'd1, I_TYPE};


    // Test 1: Immediate dependency on rs1.
    cpu_top_dut.instruction_memory_unit.memory[4] =
        {12'd4, 5'd0, 3'b000, 5'd2, I_TYPE}; // addi x2, x0, 4

    cpu_top_dut.instruction_memory_unit.memory[5] =
        {7'd0, 5'd1, 5'd2, 3'b000, 5'd3, R_TYPE}; // add x3, x2, x1 -> 8

	 
    // Test 2: Immediate dependency on rs2.
    cpu_top_dut.instruction_memory_unit.memory[12] =
        {12'd5, 5'd0, 3'b000, 5'd4, I_TYPE}; // addi x4, x0, 5

    cpu_top_dut.instruction_memory_unit.memory[13] =
        {7'd0, 5'd4, 5'd1, 3'b000, 5'd5, R_TYPE}; // add x5, x1, x4 -> 9


    // Test 3: Both operands need the same new value.
    cpu_top_dut.instruction_memory_unit.memory[20] =
        {12'd6, 5'd0, 3'b000, 5'd6, I_TYPE}; // addi x6, x0, 6

    cpu_top_dut.instruction_memory_unit.memory[21] =
        {7'd0, 5'd6, 5'd6, 3'b000, 5'd7, R_TYPE}; // add x7, x6, x6 -> 12


    // Test 4: Operands need results from different instructions.
    cpu_top_dut.instruction_memory_unit.memory[28] =
        {12'd7, 5'd0, 3'b000, 5'd8, I_TYPE}; // addi x8, x0, 7

    cpu_top_dut.instruction_memory_unit.memory[29] =
        {12'd8, 5'd0, 3'b000, 5'd9, I_TYPE}; // addi x9, x0, 8

    cpu_top_dut.instruction_memory_unit.memory[30] =
        {7'd0, 5'd9, 5'd8, 3'b000, 5'd10, R_TYPE}; // add x10, x8, x9 -> 15
	 

    // Test 5a: One unrelated instruction between producer and consumer.
    cpu_top_dut.instruction_memory_unit.memory[36] =
        {12'd9, 5'd0, 3'b000, 5'd11, I_TYPE}; // addi x11, x0, 9

    cpu_top_dut.instruction_memory_unit.memory[37] =
        {12'd99, 5'd0, 3'b000, 5'd12, I_TYPE}; // addi x12, x0, 99

    cpu_top_dut.instruction_memory_unit.memory[38] =
        {7'd0, 5'd1, 5'd11, 3'b000, 5'd13, R_TYPE}; // add x13, x11, x1 -> 13


    // Test 5b: Two unrelated instructions between producer and consumer.
    cpu_top_dut.instruction_memory_unit.memory[44] =
        {12'd10, 5'd0, 3'b000, 5'd14, I_TYPE}; // addi x14, x0, 10

    cpu_top_dut.instruction_memory_unit.memory[45] =
        {12'd21, 5'd0, 3'b000, 5'd15, I_TYPE}; // addi x15, x0, 21

    cpu_top_dut.instruction_memory_unit.memory[46] =
        {12'd22, 5'd0, 3'b000, 5'd16, I_TYPE}; // addi x16, x0, 22

    cpu_top_dut.instruction_memory_unit.memory[47] =
        {7'd0, 5'd1, 5'd14, 3'b000, 5'd17, R_TYPE}; // add x17, x14, x1 -> 14


    // Test 6: Two pending writes to the same register; newest wins.
    cpu_top_dut.instruction_memory_unit.memory[52] =
        {12'd11, 5'd0, 3'b000, 5'd18, I_TYPE}; // addi x18, x0, 11

    cpu_top_dut.instruction_memory_unit.memory[53] =
        {12'd12, 5'd0, 3'b000, 5'd18, I_TYPE}; // addi x18, x0, 12

    cpu_top_dut.instruction_memory_unit.memory[54] =
        {7'd0, 5'd1, 5'd18, 3'b000, 5'd19, R_TYPE}; // add x19, x18, x1 -> 16


    // Test 7: Chain of dependent updates.
    cpu_top_dut.instruction_memory_unit.memory[60] =
        {12'd4, 5'd0, 3'b000, 5'd20, I_TYPE}; // addi x20, x0, 4

    cpu_top_dut.instruction_memory_unit.memory[61] =
        {12'd1, 5'd20, 3'b000, 5'd20, I_TYPE}; // addi x20, x20, 1 -> 5

    cpu_top_dut.instruction_memory_unit.memory[62] =
        {12'd2, 5'd20, 3'b000, 5'd20, I_TYPE}; // addi x20, x20, 2 -> 7

	 // Test 8a: Store-address forwarding.
	 cpu_top_dut.instruction_memory_unit.memory[63] =
		  {12'd16, 5'd0, 3'b000, 5'd21, I_TYPE}; // addi x21, x0, 16

	 cpu_top_dut.instruction_memory_unit.memory[64] =
		  {7'd0, 5'd1, 5'd21, 3'b010, 5'd0, STORE}; // sw x1, 0(x21) -> memory[4] = 4

	 // Test 8b: Load-address forwarding, immediately after test 8a.
	 cpu_top_dut.instruction_memory_unit.memory[65] =
		  {12'd16, 5'd0, 3'b000, 5'd22, I_TYPE}; // addi x22, x0, 16

	 cpu_top_dut.instruction_memory_unit.memory[66] =
		  {12'd0, 5'd22, 3'b010, 5'd23, LOAD}; // lw x23, 0(x22) -> 4
	 
	
	 // Test 9: Store-data forwarding.
	 cpu_top_dut.instruction_memory_unit.memory[67] =
		  {12'd42, 5'd0, 3'b000, 5'd24, I_TYPE}; // addi x24, x0, 42

	 cpu_top_dut.instruction_memory_unit.memory[68] =
		  {7'd0, 5'd24, 5'd2, 3'b010, 5'd0, STORE}; // sw x24, 0(x2)	
		  
	
	 // Test 10: Forward both store address and store data.
	 cpu_top_dut.instruction_memory_unit.memory[69] =
		  {12'd32, 5'd0, 3'b000, 5'd25, I_TYPE}; // addi x25, x0, 32

	 cpu_top_dut.instruction_memory_unit.memory[70] =
		  {12'd42, 5'd0, 3'b000, 5'd26, I_TYPE}; // addi x26, x0, 42

	 cpu_top_dut.instruction_memory_unit.memory[71] =
		  {7'd0, 5'd26, 5'd25, 3'b010, 5'd0, STORE}; // sw x26, 0(x25)


	 // Test 11a: Forward BEQ operand; condition is false.
	 cpu_top_dut.instruction_memory_unit.memory[72] =
	  	  {12'd4, 5'd0, 3'b000, 5'd27, I_TYPE}; // addi x27, x0, 4

	 cpu_top_dut.instruction_memory_unit.memory[73] =
		  {7'd9, 5'd0, 5'd27, 3'b000, 4'd10, 1'b0, BRANCH};
	 // beq x27, x0, +308 -> memory[150] if taken.
	 // x27 = 4, so branch is not taken.


	 // Test 11b: Forward BLT operands; condition is false.
	 cpu_top_dut.instruction_memory_unit.memory[74] =
		  {12'd8, 5'd0, 3'b000, 5'd28, I_TYPE}; // addi x28, x0, 8

	 cpu_top_dut.instruction_memory_unit.memory[75] =
		  {12'd4, 5'd0, 3'b000, 5'd29, I_TYPE}; // addi x29, x0, 4

	 cpu_top_dut.instruction_memory_unit.memory[76] =
		  {7'd9, 5'd29, 5'd28, 3'b100, 4'd4, 1'b0, BRANCH};
	 // blt x28, x29, +296 -> memory[150] if taken.
	 // 8 < 4 is false, so branch is not taken.
	 
	 //Reset registers here
	 
	 // Test 12: Forward results from LUI and AUIPC.
	 cpu_top_dut.instruction_memory_unit.memory[85] =
		  {20'd4, 5'd5, LUI}; // lui x5, 4 -> x5 = 32'h00004000

	 cpu_top_dut.instruction_memory_unit.memory[86] =
		  {12'd1, 5'd5, 3'b000, 5'd6, I_TYPE}; // addi x6, x5, 1 -> x6 = 32'h00004001

	 cpu_top_dut.instruction_memory_unit.memory[87] =
		  {20'd0, 5'd7, AUIPC}; // auipc x7, 0 -> x7 = 348

	 cpu_top_dut.instruction_memory_unit.memory[88] =
		  {12'd4, 5'd7, 3'b000, 5'd8, I_TYPE}; // addi x8, x7, 4 -> x8 = 352
		  
		  
	 // Test 13: Load-use dependency requiring a stall.
	 // Load 42 from byte address 32, then immediately use it in ADD.
	 cpu_top_dut.instruction_memory_unit.memory[89] =
		  {12'd0, 5'd25, 3'b010, 5'd31, LOAD}; // lw x31, 0(x25) -> 42

	 cpu_top_dut.instruction_memory_unit.memory[90] =
		  {7'd0, 5'd2, 5'd31, 3'b000, 5'd9, R_TYPE}; // add x9, x31, x2 -> 46

	 // Test 14: Load-use dependency requiring a stall.
	 // Load 42 from byte address 32, then immediately use it in STORE.		  
	 cpu_top_dut.instruction_memory_unit.memory[91] =		  
		  {12'd0, 5'd25, 3'b010, 5'd10, LOAD}; // lw x10, 0(x25)

	 cpu_top_dut.instruction_memory_unit.memory[92] =
		  {7'd0, 5'd10, 5'd2, 3'b010, 5'd4, STORE}; // sw x10, 4(x2)		  
		  
	 //Test 15: x0 must remain 0
	 cpu_top_dut.instruction_memory_unit.memory[93] =
		  {12'd7, 5'd0, 3'b000, 5'd0, I_TYPE}; // addi x0, x0, 7 -> x0 remains 0

	 cpu_top_dut.instruction_memory_unit.memory[94] =
		  {7'b0000000, 5'd2, 5'd0, 3'b000, 5'd11, R_TYPE}; // add x11, x0, x2 -> x10 = x2

	 
	 
	 //Test 16: Test flush when branch is taken	
	 cpu_top_dut.instruction_memory_unit.memory[95] =
		  {7'd0, 5'd2, 5'd1, 3'b000, 4'd6, 1'b0, BRANCH};
	 // beq x1, x2, +12 -> memory[98] if equal

	 cpu_top_dut.instruction_memory_unit.memory[96] =
		  {12'd5, 5'd0, 3'b000, 5'd12, I_TYPE}; // addi x12, x0, 5

	 cpu_top_dut.instruction_memory_unit.memory[97] =
		  {12'd6, 5'd0, 3'b000, 5'd13, I_TYPE}; // addi x13, x0, 6

	 //Test 17: Forward to jalr	  
	 cpu_top_dut.instruction_memory_unit.memory[98] =
		  {12'd408, 5'd0, 3'b000, 5'd14, I_TYPE}; // addi x14, x0, 408

	 cpu_top_dut.instruction_memory_unit.memory[99] =
		  {12'd0, 5'd14, 3'b000, 5'd15, JALR};
	 // jalr x15, 0(x14) -> memory[102], x15 = 400

		 
	 
	 cpu_top_dut.instruction_memory_unit.memory[100] =
		  {12'd1, 5'd0, 3'b000, 5'd16, I_TYPE}; // addi x16, x0, 1

	 cpu_top_dut.instruction_memory_unit.memory[101] =
		  {12'd2, 5'd0, 3'b000, 5'd17, I_TYPE}; // addi x17, x0, 2

	 cpu_top_dut.instruction_memory_unit.memory[102] =
		  {12'd0, 5'd15, 3'b000, 5'd18, I_TYPE}; // addi x18, x15, 0 -> x18 = 400

	 //Test 18: Jal
	 cpu_top_dut.instruction_memory_unit.memory[103] =
		  {1'b0, 10'd34, 1'b0, 8'd0, 5'd19, JAL};
	 // jal x19, +68 -> memory[120], x19 = 416


	 
	 cpu_top_dut.instruction_memory_unit.memory[104] =
		  {12'd1, 5'd0, 3'b000, 5'd20, I_TYPE}; // addi x20, x0, 1

	 cpu_top_dut.instruction_memory_unit.memory[105] =
		  {12'd2, 5'd0, 3'b000, 5'd21, I_TYPE}; // addi x21, x0, 2
		  
		  
		  
	// Test 19: Load-use dependency in branch operands.
	// The load must provide x23 = 42 before BNE compares x22 and x23.
	// Since both equal 42, the branch is not taken.
	cpu_top_dut.instruction_memory_unit.memory[120] =
		 {12'd42, 5'd0, 3'b000, 5'd22, I_TYPE}; // addi x22, x0, 42

	cpu_top_dut.instruction_memory_unit.memory[121] =
		 {12'd4, 5'd1, 3'b010, 5'd23, LOAD}; // lw x23, 4(x1) -> 42

	cpu_top_dut.instruction_memory_unit.memory[122] =
		 {7'd0, 5'd23, 5'd22, 3'b001, 4'd6, 1'b0, BRANCH};
	// bne x22, x23, +12 -> memory[125] if taken; expected: not taken.


	// Test 20: Load-use dependency in the next load's base address.
	// x24 = 42, so the second load accesses byte address 42 - 34 = 8.
	cpu_top_dut.instruction_memory_unit.memory[123] =
		 {12'd4, 5'd1, 3'b010, 5'd24, LOAD}; // lw x24, 4(x1) -> 42

	cpu_top_dut.instruction_memory_unit.memory[124] =
		 {-12'd34, 5'd24, 3'b010, 5'd25, LOAD}; // lw x25, -34(x24) -> 42


	// Test 21: Load-use dependency in JALR's base register.
	// Use the loaded x25 = 42: target = (42 + 470) & ~1 = 512.
	// Save the return address PC + 4 = 504 into x26.
	cpu_top_dut.instruction_memory_unit.memory[125] =
		 {12'd470, 5'd25, 3'b000, 5'd26, JALR};
	// jalr x26, 470(x25) -> memory[128]; x26 = 504.


	// Test 22: Flush wrong-path register and memory writes after JALR.
	// Neither instruction may change architectural state.
	cpu_top_dut.instruction_memory_unit.memory[126] =
		 {12'd100, 5'd0, 3'b000, 5'd27, I_TYPE}; // Must NOT write x27.

	cpu_top_dut.instruction_memory_unit.memory[127] =
		 {7'd0, 5'd27, 5'd1, 3'b010, 5'd8, STORE}; // Must NOT write byte address 12.


	// Test 23: Branch immediate bits must NOT be treated as a destination register.
	// BLT writes no register, although instruction[11:7] resembles rd = x8.
	// With x28 = 8 and x29 = 4, the branch must NOT be taken.
	// The following ADD must use the existing x8 = 352.
	cpu_top_dut.instruction_memory_unit.memory[128] =
		 {7'd9, 5'd29, 5'd28, 3'b100, 4'd4, 1'b0, BRANCH};
	// blt x28, x29, +296 -> memory[202] if taken; expected: not taken.

	cpu_top_dut.instruction_memory_unit.memory[129] =
		 {7'd0, 5'd8, 5'd0, 3'b000, 5'd30, R_TYPE}; // add x30, x0, x8 -> 352
		 

	
	 cpu_top_dut.instruction_memory_unit.memory[150] =
		  {12'd99, 5'd0, 3'b000, 5'd30, I_TYPE}; // addi x30, x0, 99	  
    
	 #1;
    reset_n = 1'b1;

	 
	 
	 repeat (83) @(posedge clock);
	 #1;
	 
    check_register(5'd3,  32'd8); // Test 1
    check_register(5'd5, 32'd9); // Test 2	 
    check_register(5'd7,  32'd12); // Test 3
    check_register(5'd10, 32'd15); // Test 4	 
    check_register(5'd13, 32'd13); // Test 5a
    check_register(5'd17, 32'd14); // Test 5b
    check_register(5'd19, 32'd16); // Test 6
    check_register(5'd20, 32'd7);  // Test 7
	 check_data_memory(32'd16, 32'd4); // Test 8a
	 check_register(5'd22, 32'd16);     // Test 8b	 
	 check_register(5'd23, 32'd4);     // Test 8b
	 check_data_memory(32'd4, 32'd42); // Test 9	
	 check_data_memory(32'd32, 32'd42); //Test 10
	 check_register(32'd28, 32'd8); //Test 11a	 
	 check_register(5'd30, 32'dX); // Test 11b Must remain 0: branch not taken 
	 //reset register
	 repeat (60) @(posedge clock);
	 #1;
	 
	 check_register(5'd6,32'h00004001);// Test 12a: Forward results from LUI and AUIPC.
	 check_register(5'd8,32'd352); //test 12b
	 check_register(5'd31,32'd42); //test 13	  
	 check_register(5'd9,32'd46); //test 13
	 check_register(5'd10,32'd42); //test 14	  
	 check_data_memory(32'd8, 32'd42); //Test 14	 
	 check_register(5'd11,32'd4); //test 15 

	 check_register(5'd12,32'd99); //test 16, old value
	 check_register(5'd13,32'd13); //test 16, old value	 
	 check_register(5'd16,32'd22); //test 17, old value
	 check_register(5'd17,32'd14); //test 17, old value	 
	 check_register(5'd18,32'd400); //test 17, return address	 
	 check_register(5'd20,32'd7); //test 18, old value
	 check_register(5'd21,32'd16); //test 18, old value
	 check_register(5'd19,32'd416); //test 18, return address 
	 //oct18-2026, test 1-11b, 14(stall), 15 passed
	 
	 check_register(5'd23, 32'd42);
	 check_register(5'd24,32'd42);
	 check_register(5'd25,32'd42);
	 check_data_memory(5'd12,32'dX);
	 check_register(5'd30,32'd352);
	 
	 if (errors == 0)
        $display("ALL FORWARDING TESTS PASSED");
    else
        $display("%0d FORWARDING TESTS FAILED", errors);

    $finish;

end
endmodule