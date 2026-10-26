/* TEST CASES:
1. Write 100 to byte address 8; verify reading returns 100.
2. Write 55 to byte address 4; verify reading returns 55.
3. Verify byte address 8 still contains 100 after writing to address 4.
4. Attempt to write 200 to byte address 8 with write_enable = 0;
   verify the stored value remains 100.
*/
`timescale 1ns/1ps
module data_memory_tb;
	reg clock;
	reg [31:0] address;
	reg write_enable;
	reg [31:0] write_data;
	
	wire [31:0] read_data;
	integer errors;
	
data_memory data_memory_dut(
    .clock(clock),
    .address(address),
    .write_enable(write_enable),
    .write_data(write_data),
    .read_data(read_data)
);

initial begin
	clock = 1'b0;
	
	forever begin
		#5; 
		clock = ~clock;
	end
		
end

task data_memory_write;
	input [31:0] test_address;
	input test_write_enable;
	input [31:0] test_write_data;
	
	begin
	@(negedge clock);
	address = test_address;
	write_enable = test_write_enable;
	write_data = test_write_data;
	
	@(posedge clock);
	#1;
	write_enable = 1'b0;
	
	end
endtask

task data_memory_read;
	input [31:0] test_address;

	input [31:0] expected_read_data;
	
	begin
	address = test_address;

	#1;

	if(read_data !== expected_read_data) begin
		errors = errors + 1 ;
		$display("Failed! Address: %h, read_data:%0d, expected_read_data:%0d",test_address,read_data, expected_read_data);
	end
	else
		$display("PASSED! Address: %h, read_data:%0d, expected_read_data:%0d",test_address,read_data, expected_read_data);	
	
	end
endtask


initial begin
	 errors = 0;
	 address = 32'd0;

	 write_enable = 1'b0;
	 write_data = 32'd0;
	 
	 //1:
	 data_memory_write(32'd8, 1'b1, 32'd100);
	 data_memory_read (32'd8, 32'd100);

	 //2:
	 data_memory_write(32'd4, 1'b1, 32'd55);
	 data_memory_read (32'd4, 32'd55);
	 
	 //3:
	 data_memory_read (32'd8, 32'd100); // Check the other word was preserved.	 
	 
	 //4:
	 data_memory_write(32'd8, 1'b0, 32'd200);
	 data_memory_read (32'd8, 32'd100);

    if (errors == 0)
        $display("ALL DATA MEMORY TESTS PASSED");
    else
        $display("%0d DATA MEMORY TESTS FAILED", errors);

	$finish;
end
endmodule