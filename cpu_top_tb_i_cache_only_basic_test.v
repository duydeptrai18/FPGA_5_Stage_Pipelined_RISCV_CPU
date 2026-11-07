/*
This file test all forwarding and stall and flush cases
Create normal test cases later without forwarding or stall
*/


`timescale 1ns/1ps
module cpu_top_tb_i_cache_only_basic_test;
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
    reset_n = 1'b1;
	
	 repeat(500)@(posedge clock);
	 #1;
	 
	 check_register(5'd10,32'd0); //check whether it goes to pass
	 //passed

	 
	 if (errors == 0)
        $display("ALL i_cache only integration basic test TESTS PASSED");
    else
        $display("%0d i_cache only integration basic test TESTS FAILED", errors);

    $finish;

end
endmodule