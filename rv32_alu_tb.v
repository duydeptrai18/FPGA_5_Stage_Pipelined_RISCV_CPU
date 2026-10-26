/*
- Test every function and edge cases

*/

`timescale 1ns/1ps
module rv32_alu_tb;

	reg [31:0] a;
	reg [31:0] b;
	reg [3:0] alu_control;

	wire [31:0] result;
	wire zero;
   integer errors;
	
rv32_alu rv32_alu_dut(
	.a(a),
	.b(b),
	.alu_control(alu_control),
	.result (result),
	.zero (zero)
);

task test_rv32_alu;
	input [31:0] test_a;
	input [31:0] test_b;
	input [3:0] test_alu_control;
	input [31:0] expected_result;
	input expected_zero;
	
	begin
		a = test_a;
		b = test_b;
		alu_control = test_alu_control;
		#1;
		
		if( (result !== expected_result) || (zero !==expected_zero)) begin
			$display("Failed!! control:%b, a:%h, b:%h, result: %h, expected result: %h, zero:%b, expectedzero: %b",
			alu_control,a,b, result,expected_result,zero,expected_zero);
			
			errors = errors + 1;
		end
		
		else 
			$display("Passed!! control:%b, a:%h, b:%h, result: %h , zero:%b",alu_control, a,b,result,zero);
			
	end

endtask

initial begin
	errors = 0;

	// ADD: 
	test_rv32_alu( 32'd10, 32'd20, 4'b0000,32'd30, 1'b0);

	// ADD producing zero
	test_rv32_alu( 32'd0, 32'd0, 4'b0000, 32'd0, 1'b1);
 
	// Addition overflow wraps around to zero
	test_rv32_alu( 32'hFFFFFFFF, 32'd1, 4'b0000,32'd0, 1'b1 );
	
	// SUB: control 0001
	test_rv32_alu( 32'd10, 32'd3, 4'b0001, 32'd7, 1'b0 );
		
   // 2 - 6 = -4 = FFFFFFFC
   test_rv32_alu(32'd2, 32'd6, 4'b0001,32'hFFFFFFFC, 1'b0);	
    
	// AND: F0F0 & 0FF0 = 00F0
   test_rv32_alu(32'h0000F0F0, 32'h00000FF0, 4'b0010, 32'h000000F0, 1'b0);	
	
   // OR: F0F0 | 0FF0 = FFF0
   test_rv32_alu(32'h0000F0F0, 32'h00000FF0, 4'b0011,32'h0000FFF0, 1'b0);
    
	// XOR: AA55 ^ FF00 = 5555
   test_rv32_alu(32'h0000AA55, 32'h0000FF00, 4'b0100,32'h00005555, 1'b0);

   // SLL: 1 << 4 = 16
   test_rv32_alu(32'd1, 32'd4, 4'b0101,32'd16, 1'b0);	
	
   // SRL: logical shift inserts zero
   test_rv32_alu(32'h80000000, 32'd1, 4'b0110,32'h40000000, 1'b0);	

   // SRA: arithmetic shift preserves sign
   test_rv32_alu(32'h80000000, 32'd1, 4'b0111,32'hC0000000, 1'b0);

   // Signed SLT: -1 < 1 is true
   test_rv32_alu(32'hFFFFFFFF, 32'd1, 4'b1000,32'd1, 1'b0);	
	
   // Signed SLT: 1 < -1 is false
   test_rv32_alu(32'd1, 32'hFFFFFFFF, 4'b1000,32'd0, 1'b1);	
	
	// Unsigned SLTU: FFFFFFFF < 1 is false
   test_rv32_alu(32'hFFFFFFFF, 32'd1, 4'b1001,32'd0, 1'b1);
	
   // Unsigned SLTU: 1 < FFFFFFFF is true
   test_rv32_alu(32'd1, 32'hFFFFFFFF, 4'b1001,32'd1, 1'b0);
	
   // Invalid control should select default result zero
   test_rv32_alu(32'd50, 32'd20, 4'b1111,32'd0, 1'b1);
    
	if (errors == 0)
        $display("ALL RV32 ALU TESTS PASSED");
   else
        $display("%0d RV32 ALU TESTS FAILED", errors);

   $finish;
end

endmodule