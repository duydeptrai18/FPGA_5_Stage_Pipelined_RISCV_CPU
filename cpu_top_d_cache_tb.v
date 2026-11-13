/*
all passed nov 11
*/


`timescale 1ns/1ps
module cpu_top_d_cache_tb;
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

task check_d_memory_slot_data;
    input [9:0] address;
    input [127:0] expected_memory_data;

    reg [127:0] actual_memory_data;
    begin
        actual_memory_data = {
            cpu_top_dut.slow_data_memory_unit.memory[{address[9:4], 2'b11}],
            cpu_top_dut.slow_data_memory_unit.memory[{address[9:4], 2'b10}],
            cpu_top_dut.slow_data_memory_unit.memory[{address[9:4], 2'b01}],
            cpu_top_dut.slow_data_memory_unit.memory[{address[9:4], 2'b00}]
        };

        if (actual_memory_data !== expected_memory_data) begin
            errors = errors + 1;
            $display("FAIL address=%h data=%h expected=%h",
                     address, actual_memory_data,
                     expected_memory_data);
        end
        else
            $display("PASS address=%h data=%h",
                     address, actual_memory_data);
    end
endtask

task check_d_cache_slot_data;
    input [1:0] slot_index;
    input [127:0] expected_slot_data;

    reg [127:0] actual_slot_data;
    begin
        actual_slot_data = {
            cpu_top_dut.d_cache_unit.memory[slot_index][3],
            cpu_top_dut.d_cache_unit.memory[slot_index][2],
            cpu_top_dut.d_cache_unit.memory[slot_index][1],
            cpu_top_dut.d_cache_unit.memory[slot_index][0]
        };

        if (actual_slot_data !== expected_slot_data) begin
            errors = errors + 1;
            $display("FAIL slot=%0d data=%h expected=%h",
                     slot_index, actual_slot_data, expected_slot_data);
        end
        else
            $display("PASS slot=%0d data=%h", slot_index, actual_slot_data);
    end
endtask

initial begin
	clock = 1'b0;
	forever #5 clock = ~clock;
end

initial begin
    #10000; // 10 us with `timescale 1ns/1ps
    $fatal(1, "TIMEOUT: Simulation did not finish");
end

initial begin

    reset_n = 1'b0;
    errors = 0;


    #1;
	 reset_n = 1'b1;
    // Fill unused locations with NOPs.
// Fill unused instruction memory with NOPs before loading the test.
for (i = 0; i < 256; i = i + 1)
    cpu_top_dut.slow_instruction_memory_unit.memory[i] = 32'h00000013;

// Test 1: Load into four invalid cache slots.
cpu_top_dut.slow_instruction_memory_unit.memory[0] =
    {12'd0,  5'd0, 3'b010, 5'd1, LOAD}; // lw x1, 0(x0)  -> 0

cpu_top_dut.slow_instruction_memory_unit.memory[1] =
    {12'd20, 5'd0, 3'b010, 5'd2, LOAD}; // lw x2, 20(x0) -> 5

cpu_top_dut.slow_instruction_memory_unit.memory[2] =
    {12'd40, 5'd0, 3'b010, 5'd3, LOAD}; // lw x3, 40(x0) -> 10

cpu_top_dut.slow_instruction_memory_unit.memory[3] =
    {12'd60, 5'd0, 3'b010, 5'd4, LOAD}; // lw x4, 60(x0) -> 15

// Test 2: Load a different word from each cached line.
cpu_top_dut.slow_instruction_memory_unit.memory[4] =
    {12'd4,  5'd0, 3'b010, 5'd5, LOAD}; // lw x5, 4(x0)  -> 1

cpu_top_dut.slow_instruction_memory_unit.memory[5] =
    {12'd24, 5'd0, 3'b010, 5'd6, LOAD}; // lw x6, 24(x0) -> 6

cpu_top_dut.slow_instruction_memory_unit.memory[6] =
    {12'd44, 5'd0, 3'b010, 5'd7, LOAD}; // lw x7, 44(x0) -> 11

cpu_top_dut.slow_instruction_memory_unit.memory[7] =
    {12'd48, 5'd0, 3'b010, 5'd8, LOAD}; // lw x8, 48(x0) -> 12
	 
// Test 3: Load a different tag into each valid, clean cache slot.
cpu_top_dut.slow_instruction_memory_unit.memory[8] =
    {12'd64,  5'd0, 3'b010, 5'd9,  LOAD}; // lw x9,  64(x0)  -> 16
cpu_top_dut.slow_instruction_memory_unit.memory[9] =
    {12'd84,  5'd0, 3'b010, 5'd10, LOAD}; // lw x10, 84(x0)  -> 21
cpu_top_dut.slow_instruction_memory_unit.memory[10] =
    {12'd104, 5'd0, 3'b010, 5'd11, LOAD}; // lw x11, 104(x0) -> 26
cpu_top_dut.slow_instruction_memory_unit.memory[11] =
    {12'd124, 5'd0, 3'b010, 5'd12, LOAD}; // lw x12, 124(x0) -> 31

// Test 4: Store hits make all four slots dirty.
cpu_top_dut.slow_instruction_memory_unit.memory[12] =
    {12'd100, 5'd0, 3'b000, 5'd13, I_TYPE}; // addi x13, x0, 100
cpu_top_dut.slow_instruction_memory_unit.memory[13] =
    {7'd2, 5'd13, 5'd0, 3'b010, 5'd0, STORE}; // sw x13, 64(x0)

cpu_top_dut.slow_instruction_memory_unit.memory[14] =
    {12'd101, 5'd0, 3'b000, 5'd14, I_TYPE}; // addi x14, x0, 101
cpu_top_dut.slow_instruction_memory_unit.memory[15] =
    {7'd2, 5'd14, 5'd0, 3'b010, 5'd20, STORE}; // sw x14, 84(x0)

cpu_top_dut.slow_instruction_memory_unit.memory[16] =
    {12'd102, 5'd0, 3'b000, 5'd15, I_TYPE}; // addi x15, x0, 102
cpu_top_dut.slow_instruction_memory_unit.memory[17] =
    {7'd3, 5'd15, 5'd0, 3'b010, 5'd8, STORE}; // sw x15, 104(x0)

cpu_top_dut.slow_instruction_memory_unit.memory[18] =
    {12'd103, 5'd0, 3'b000, 5'd16, I_TYPE}; // addi x16, x0, 103
cpu_top_dut.slow_instruction_memory_unit.memory[19] =
    {7'd3, 5'd16, 5'd0, 3'b010, 5'd28, STORE}; // sw x16, 124(x0)		  
	
// Test 5: Load tag 0 again, forcing all four dirty tag 1 lines to write back.
cpu_top_dut.slow_instruction_memory_unit.memory[20] =
    {12'd0,  5'd0, 3'b010, 5'd17, LOAD}; // lw x17, 0(x0)  -> 0
cpu_top_dut.slow_instruction_memory_unit.memory[21] =
    {12'd20, 5'd0, 3'b010, 5'd18, LOAD}; // lw x18, 20(x0) -> 5
cpu_top_dut.slow_instruction_memory_unit.memory[22] =
    {12'd40, 5'd0, 3'b010, 5'd19, LOAD}; // lw x19, 40(x0) -> 10
cpu_top_dut.slow_instruction_memory_unit.memory[23] =
    {12'd60, 5'd0, 3'b010, 5'd20, LOAD}; // lw x20, 60(x0) -> 15

// Test 6: Store to a different tag while all four slots are clean.
cpu_top_dut.slow_instruction_memory_unit.memory[24] =
    {12'd110, 5'd0, 3'b000, 5'd21, I_TYPE}; // addi x21, x0, 110
cpu_top_dut.slow_instruction_memory_unit.memory[25] =
    {7'd2, 5'd21, 5'd0, 3'b010, 5'd4, STORE}; // sw x21, 68(x0)

cpu_top_dut.slow_instruction_memory_unit.memory[26] =
    {12'd120, 5'd0, 3'b000, 5'd22, I_TYPE}; // addi x22, x0, 120
cpu_top_dut.slow_instruction_memory_unit.memory[27] =
    {7'd2, 5'd22, 5'd0, 3'b010, 5'd24, STORE}; // sw x22, 88(x0)

cpu_top_dut.slow_instruction_memory_unit.memory[28] =
    {12'd130, 5'd0, 3'b000, 5'd23, I_TYPE}; // addi x23, x0, 130
cpu_top_dut.slow_instruction_memory_unit.memory[29] =
    {7'd3, 5'd23, 5'd0, 3'b010, 5'd12, STORE}; // sw x23, 108(x0)

cpu_top_dut.slow_instruction_memory_unit.memory[30] =
    {12'd140, 5'd0, 3'b000, 5'd24, I_TYPE}; // addi x24, x0, 140
cpu_top_dut.slow_instruction_memory_unit.memory[31] =
    {7'd3, 5'd24, 5'd0, 3'b010, 5'd16, STORE}; // sw x24, 112(x0)
	
// Test 7: Store to tag 2, forcing dirty tag 1 lines to write back.
cpu_top_dut.slow_instruction_memory_unit.memory[32] =
    {12'd200, 5'd0, 3'b000, 5'd25, I_TYPE}; // addi x25, x0, 200
cpu_top_dut.slow_instruction_memory_unit.memory[33] =
    {7'd4, 5'd25, 5'd0, 3'b010, 5'd0, STORE}; // sw x25, 128(x0)

cpu_top_dut.slow_instruction_memory_unit.memory[34] =
    {12'd201, 5'd0, 3'b000, 5'd26, I_TYPE}; // addi x26, x0, 201
cpu_top_dut.slow_instruction_memory_unit.memory[35] =
    {7'd4, 5'd26, 5'd0, 3'b010, 5'd20, STORE}; // sw x26, 148(x0)

cpu_top_dut.slow_instruction_memory_unit.memory[36] =
    {12'd202, 5'd0, 3'b000, 5'd27, I_TYPE}; // addi x27, x0, 202
cpu_top_dut.slow_instruction_memory_unit.memory[37] =
    {7'd5, 5'd27, 5'd0, 3'b010, 5'd8, STORE}; // sw x27, 168(x0)

cpu_top_dut.slow_instruction_memory_unit.memory[38] =
    {12'd203, 5'd0, 3'b000, 5'd28, I_TYPE}; // addi x28, x0, 203
cpu_top_dut.slow_instruction_memory_unit.memory[39] =
    {7'd5, 5'd28, 5'd0, 3'b010, 5'd28, STORE}; // sw x28, 188(x0)
	 

	
// Check 
@(posedge clock);
while ((cpu_top_dut.debug_rd !== 5'd8) ||
       (cpu_top_dut.debug_write_register_enable !== 1'b1))
    @(posedge clock);
#1; // Let the register write settle.
//Test 1 and test 2
$display("Test 1 and 2");
check_register(5'd1, 32'd0);
check_register(5'd2, 32'd5);
check_register(5'd3, 32'd10);
check_register(5'd4, 32'd15);
check_d_cache_slot_data(2'd0, {32'd3,  32'd2,  32'd1,  32'd0});
check_d_cache_slot_data(2'd1, {32'd7,  32'd6,  32'd5,  32'd4});
check_d_cache_slot_data(2'd2, {32'd11, 32'd10, 32'd9,  32'd8});
check_d_cache_slot_data(2'd3, {32'd15, 32'd14, 32'd13, 32'd12});

check_register(5'd5, 32'd1);
check_register(5'd6, 32'd6);
check_register(5'd7, 32'd11);
check_register(5'd8, 32'd12);

@(posedge clock);
while ((cpu_top_dut.debug_rd !== 5'd12) ||
       (cpu_top_dut.debug_write_register_enable !== 1'b1))
    @(posedge clock);
#1; // Let the register write settle.
// After Test 3 completes, before Test 4 modifies the slots.
$display("Test 3");
check_d_cache_slot_data(2'd0, {32'd19, 32'd18, 32'd17, 32'd16});
check_d_cache_slot_data(2'd1, {32'd23, 32'd22, 32'd21, 32'd20});
check_d_cache_slot_data(2'd2, {32'd27, 32'd26, 32'd25, 32'd24});
check_d_cache_slot_data(2'd3, {32'd31, 32'd30, 32'd29, 32'd28});

check_register(5'd9,  32'd16);
check_register(5'd10, 32'd21);
check_register(5'd11, 32'd26);
check_register(5'd12, 32'd31);

@(posedge clock);
while ((cpu_top_dut.debug_rd !== 5'd16))
    @(posedge clock);
repeat(5) @(posedge clock);
#1;
// After Test 4 completes.
$display("Test 4");
check_d_cache_slot_data(2'd0, {32'd19,  32'd18,  32'd17,  32'd100});
check_d_cache_slot_data(2'd1, {32'd23,  32'd22,  32'd101, 32'd20});
check_d_cache_slot_data(2'd2, {32'd27,  32'd102, 32'd25,  32'd24});
check_d_cache_slot_data(2'd3, {32'd103, 32'd30,  32'd29,  32'd28});

	


@(posedge clock);
while ((cpu_top_dut.debug_rd !== 5'd20) ||
       (cpu_top_dut.debug_write_register_enable !== 1'b1))
    @(posedge clock);
#1;
// After Test 5 completes.
// Run after x20 has written back, before the next test changes the slots.
$display("Test 5");
check_register(5'd17, 32'd0);
check_register(5'd18, 32'd5);
check_register(5'd19, 32'd10);
check_register(5'd20, 32'd15);

// Check the refilled tag 0 lines.
check_d_cache_slot_data(2'd0, {32'd3,  32'd2,  32'd1,  32'd0});
check_d_cache_slot_data(2'd1, {32'd7,  32'd6,  32'd5,  32'd4});
check_d_cache_slot_data(2'd2, {32'd11, 32'd10, 32'd9,  32'd8});
check_d_cache_slot_data(2'd3, {32'd15, 32'd14, 32'd13, 32'd12});

// Check that the evicted tag 1 lines reached backing memory.
// The first argument is the line's base byte address.
check_d_memory_slot_data(10'd64,  {32'd19,  32'd18,  32'd17, 32'd100});
check_d_memory_slot_data(10'd80,  {32'd23,  32'd22, 32'd101,  32'd20});
check_d_memory_slot_data(10'd96,  {32'd27, 32'd102,  32'd25,  32'd24});
check_d_memory_slot_data(10'd112, {32'd103, 32'd30,  32'd29,  32'd28});	


@(posedge clock);
while ((cpu_top_dut.debug_rd !== 5'd24) ||
       (cpu_top_dut.debug_write_register_enable !== 1'b1))
    @(posedge clock);
repeat(5) @(posedge clock);
#1;
$display("Test 6");
check_d_cache_slot_data(2'd0, {32'd19,  32'd18,  32'd110, 32'd100});
check_d_cache_slot_data(2'd1, {32'd23,  32'd120, 32'd101, 32'd20});
check_d_cache_slot_data(2'd2, {32'd130, 32'd102, 32'd25,  32'd24});
check_d_cache_slot_data(2'd3, {32'd103, 32'd30,  32'd29,  32'd140});

@(posedge clock);
while ((cpu_top_dut.debug_rd !== 5'd28) ||
       (cpu_top_dut.debug_write_register_enable !== 1'b1))
    @(posedge clock);
repeat(12) @(posedge clock);
#1;
$display("Test 7");
// After the final store completes, before the next test changes the slots.
// Check the new tag 2 lines in the cache.
check_d_cache_slot_data(2'd0, {32'd35,  32'd34,  32'd33, 32'd200});
check_d_cache_slot_data(2'd1, {32'd39,  32'd38, 32'd201,  32'd36});
check_d_cache_slot_data(2'd2, {32'd43, 32'd202,  32'd41,  32'd40});
check_d_cache_slot_data(2'd3, {32'd203, 32'd46,  32'd45,  32'd44});

// Check that the evicted tag 1 lines reached backing memory.
// The first argument is the line's base byte address.
check_d_memory_slot_data(10'd64,  {32'd19,  32'd18, 32'd110, 32'd100});
check_d_memory_slot_data(10'd80,  {32'd23, 32'd120, 32'd101,  32'd20});
check_d_memory_slot_data(10'd96,  {32'd130, 32'd102, 32'd25,  32'd24});
check_d_memory_slot_data(10'd112, {32'd103,  32'd30, 32'd29, 32'd140});



//Reset here
reset_n = 1'b0;
#1;
reset_n = 1'b1;
    // Fill unused locations with NOPs.
// Fill unused instruction memory with NOPs before loading the test.
for (i = 0; i < 256; i = i + 1)
    cpu_top_dut.slow_instruction_memory_unit.memory[i] = 32'h00000013;
	 
// After warm reset: store into four invalid cache slots.
cpu_top_dut.slow_instruction_memory_unit.memory[0] =
    {12'd210, 5'd0, 3'b000, 5'd1, I_TYPE}; // addi x1, x0, 210
cpu_top_dut.slow_instruction_memory_unit.memory[1] =
    {7'd4, 5'd1, 5'd0, 3'b010, 5'd4, STORE}; // sw x1, 132(x0)

cpu_top_dut.slow_instruction_memory_unit.memory[2] =
    {12'd211, 5'd0, 3'b000, 5'd2, I_TYPE}; // addi x2, x0, 211
cpu_top_dut.slow_instruction_memory_unit.memory[3] =
    {7'd4, 5'd2, 5'd0, 3'b010, 5'd24, STORE}; // sw x2, 152(x0)

cpu_top_dut.slow_instruction_memory_unit.memory[4] =
    {12'd212, 5'd0, 3'b000, 5'd3, I_TYPE}; // addi x3, x0, 212
cpu_top_dut.slow_instruction_memory_unit.memory[5] =
    {7'd5, 5'd3, 5'd0, 3'b010, 5'd12, STORE}; // sw x3, 172(x0)

cpu_top_dut.slow_instruction_memory_unit.memory[6] =
    {12'd213, 5'd0, 3'b000, 5'd4, I_TYPE}; // addi x4, x0, 213
cpu_top_dut.slow_instruction_memory_unit.memory[7] =
    {7'd5, 5'd4, 5'd0, 3'b010, 5'd16, STORE}; // sw x4, 176(x0)

// No memory operations: all four cache slots should stay unchanged.
cpu_top_dut.slow_instruction_memory_unit.memory[8]  = 32'h00000013;
cpu_top_dut.slow_instruction_memory_unit.memory[9]  = 32'h00000013;
cpu_top_dut.slow_instruction_memory_unit.memory[10] = 32'h00000013;
cpu_top_dut.slow_instruction_memory_unit.memory[11] = 32'h00000013;
	 
	 

while( cpu_top_dut.d_cache_unit.still_after_reset === 1'b1) @(posedge clock);
#1;
$display("Test 8, write after reset");
// Run after the D-cache finishes its warm-reset writeback.
check_d_memory_slot_data(10'd128, {32'd35,  32'd34,  32'd33, 32'd200});
check_d_memory_slot_data(10'd144, {32'd39,  32'd38, 32'd201,  32'd36});
check_d_memory_slot_data(10'd160, {32'd43, 32'd202,  32'd41,  32'd40});
check_d_memory_slot_data(10'd176, {32'd203, 32'd46,  32'd45,  32'd44});


@(posedge clock);
while ((cpu_top_dut.debug_rd !== 5'd4) ||
       (cpu_top_dut.debug_write_register_enable !== 1'b1))
    @(posedge clock);
repeat(12) @(posedge clock);
#1;
$display("Test 9");
check_d_cache_slot_data(2'd0, {32'd35,  32'd34,  32'd210, 32'd200});
check_d_cache_slot_data(2'd1, {32'd39,  32'd211, 32'd201, 32'd36});
check_d_cache_slot_data(2'd2, {32'd212, 32'd202, 32'd41,  32'd40});
check_d_cache_slot_data(2'd3, {32'd203, 32'd46,  32'd45,  32'd213});

	 if (errors == 0)
        $display("ALL cpu_top_d_cache_tb TESTS PASSED");
    else
        $display("%0d cpu_top_d_cache_tb TESTS FAILED", errors);

    $finish;

end
endmodule