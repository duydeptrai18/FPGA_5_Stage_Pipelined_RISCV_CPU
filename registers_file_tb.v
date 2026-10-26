/* TEST CASES:
1. Read x0 through both read ports; expect zero.
2. Write then read that register and confirm the result. 
3. Attempt to write 20 into x0; verify x0 remains 0.
*/

`timescale 1ns/1ps
module registers_file_tb;
	
	reg clock;
	reg write_enable;
	reg [4:0] read_address_1;
	reg [4:0] read_address_2;
	reg [4:0] write_address;
	reg [31:0] write_data;
	
	wire  [31:0] read_data_1;
	wire  [31:0] read_data_2;
	
	integer errors;
registers_file registers_dut(
	.clock (clock),
	.write_enable (write_enable),
	.read_address_1 (read_address_1),
	.read_address_2 (read_address_2),
	.write_address (write_address),
	.write_data (write_data),
	.read_data_1(read_data_1),
	.read_data_2(read_data_2)
	
);

task write_registers;
	input [4:0] address;
	input [31:0] data;
	
	begin
	
		@(negedge clock);
		write_enable = 1'd1;
		write_address = address;
		write_data = data;
		
		@(posedge clock);
		#1;
		write_enable = 1'b0;
		$display("Write: %0d into address %0d", write_data, write_address);
		
		
	end
endtask
		
task read_registers;
	input [4:0] address1;
	input [31:0] expected_result_1;
	
	input [4:0] address2;
	input [31:0] expected_result_2;
	
	begin
		read_address_1 = address1;
		read_address_2 = address2;
		#1;
	
		if( (read_data_1 !== expected_result_1 ) ||(read_data_2!== expected_result_2 )) begin
			errors = errors + 1;
			
			$display("Error!!! address1:%0d , Result1:%0d , expected1:%0d , address2:%0d  , Result2:%0d  , expected2:%0d  ", 
			address1, read_data_1, expected_result_1 , address2, read_data_2, expected_result_2 );
		
		end
		else begin
			$display("PASSED!, address1:%0d, result1:%0d, address2:%0d, result2:%0d",
						address1, read_data_1,address2, read_data_2);

		end
			
	end
		
endtask


initial begin
	clock = 1'd0;
	forever #5 clock = ~clock;
	
end

initial begin
    errors = 0;
    write_enable   = 1'b0;
    write_address  = 5'd0;
    write_data     = 32'd0;
    read_address_1 = 5'd0;
    read_address_2 = 5'd0;

    // 1: Both read ports return zero when reading x0.
    read_registers(5'd0, 32'd0, 5'd0, 32'd0);

    // 2: Write 123 into x5, then read it.
    write_registers(5'd5, 32'd123);
    read_registers(5'd5, 32'd123, 5'd0, 32'd0);

    // Write 110 into x7.
    // Read x5 and x7 simultaneously
    write_registers(5'd7, 32'd110);
    read_registers(5'd5, 32'd123, 5'd7, 32'd110);

    // Test 3: Write 20 into x0.
    // x0 must still read as zero
    write_registers(5'd0, 32'd20);
    read_registers(5'd0, 32'd0, 5'd7, 32'd110);

    if (errors == 0)
        $display("All registers tests PASSED");
    else
        $display("%0d registers tests FAILED", errors);

    $finish;
end
endmodule
	
	
	
	
	
	
	
	
	
	