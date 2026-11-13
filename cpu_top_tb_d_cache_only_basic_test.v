/*
This file test all forwarding and stall and flush cases
Create normal test cases later without forwarding or stall
*/


`timescale 1ns/1ps
module cpu_top_tb_d_cache_only_basic_test;
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


initial begin
	clock = 1'b0;
	forever #5 clock = ~clock;
end

initial begin

    reset_n = 1'b0;
    errors = 0;


    #1;
    reset_n = 1'b1;
	
	 repeat(1000)@(posedge clock);
	 #1;
	 
	 check_register(5'd10,32'd0); //check whether it goes to pass
	 //passed

	 
	 if (errors == 0)
        $display("ALL d_cache only integration basic test TESTS PASSED");
    else
        $display("%0d d_cache only integration basic test TESTS FAILED", errors);

    $finish;

end
endmodule