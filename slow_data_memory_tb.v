/*
Test cases:
1: Send read request and retrieve correct data after processing_cycles, and see that the valid and ready flag operate as wanted.
2: Send no request and confirm that the memory holds old data.
3: Write then read to check write works properly.
4: Reset then check memory still holds the write modification.
*/
`timescale 1ns/1ps
module slow_data_memory_tb;
	
	reg clock;
	reg reset_n;
	reg [9:0] address;
	reg [127:0] write_data;
	reg request_valid;
	reg [1:0] request;

	wire ready;
	wire valid;
	wire [127:0] read_data;
	wire [1:0] debug_state;
	integer errors;
	integer i;

slow_data_memory slow_data_memory_dut (
    .clock(clock),
    .reset_n(reset_n),
    .address(address),
    .write_data(write_data),
    .request_valid(request_valid),
    .request(request),
    .ready(ready),
    .valid(valid),
    .read_data(read_data),
    .debug_state(debug_state)
);	
	

//state
localparam IDLE             = 2'b00;
localparam READ_PROCESSING  = 2'b01;
localparam WRITE_PROCESSING = 2'b10;
localparam FINISH           = 2'b11;

//request
localparam REQUEST_NOTHING = 2'b00;
localparam READ = 2'b01;
localparam WRITE = 2'b10;

localparam PROCESSING_CYCLES = 3'd3;
localparam DEFAULT_VALUE = 128'd0;
task check_ready;
    input expected_ready;

    begin
        if (ready !== expected_ready) begin
            errors = errors + 1;
            $display("FAIL ready=%b expected=%b", ready, expected_ready);
        end
        else begin
            $display("PASS ready=%b", ready);
        end
    end
endtask

task check_valid;
    input expected_valid;

    begin
        if (valid !== expected_valid) begin
            errors = errors + 1;
            $display("FAIL valid=%b expected=%b", valid, expected_valid);
        end
        else begin
            $display("PASS valid=%b", valid);
        end
    end
endtask

task check_read_data;
    input [127:0] expected_read_data;

    begin
        if (read_data !== expected_read_data) begin
            errors = errors + 1;
            $display("FAIL read_data=%h expected=%h",
                     read_data, expected_read_data);
        end
        else begin
            $display("PASS read_data=%h", read_data);
        end
    end
endtask

task check_debug_state;
    input [1:0] expected_debug_state;

    begin
        if (debug_state !== expected_debug_state) begin
            errors = errors + 1;
            $display("FAIL debug_state=%b expected=%b",
                     debug_state, expected_debug_state);
        end
        else begin
            $display("PASS debug_state=%b", debug_state);
        end
    end
endtask

task request_and_check; //only check for read and request_nothing, if request is write, we request read to check

	input [9:0] test_address;
	input [1:0] test_request;
	input [127:0] test_write_data;
	input [127:0] expected_read_data;

	begin
		@(negedge clock);
		#1;
		$display("Begin the task. In idle state, setting up the request");
		request_valid = 1'b1;
		address = test_address;
		request = test_request;
		write_data= test_write_data;	
		check_debug_state(IDLE);
		
	
		@(posedge clock);
		#1;
		request_valid = 1'b0;
		
		if(test_request == READ) begin
			$display("In first cycle of read_processing state");
			check_ready(1'b0);
			check_valid(1'b0);
			check_debug_state(READ_PROCESSING);
			
			for (i = 0; i < PROCESSING_CYCLES; i = i +1 ) begin
				check_valid(1'b0);
				check_debug_state(READ_PROCESSING);
				@(posedge clock);
				#1;
			end

			$display("In first cycle of FINISH state, when data is present");
			check_read_data(expected_read_data);
			check_valid(1'b1);
			check_ready(1'b0);
			check_debug_state(FINISH);
				
			
			@(posedge clock);
			#1;
			$display("In first cycle of IDLE state after getting back");
			check_read_data(expected_read_data);
			check_ready(1'b1);
			check_valid(1'b0);	
			check_debug_state(IDLE);	
		
		end

		else if(test_request == WRITE) begin
			$display("In first cycle of write_processing state");
			check_ready(1'b0);
			check_valid(1'b0);
			check_debug_state(WRITE_PROCESSING);
			
			for (i = 0; i < PROCESSING_CYCLES; i = i +1 ) begin
				check_valid(1'b0);
				check_debug_state(WRITE_PROCESSING);
				@(posedge clock);
				#1;
			end

			$display("In first cycle of FINISH state, when data is present");
			check_valid(1'b1);
			check_ready(1'b0);
			check_debug_state(FINISH);
				
			
			@(posedge clock);
			#1;
			$display("In first cycle of IDLE state after getting back");
			check_ready(1'b1);
			check_valid(1'b0);	
			check_debug_state(IDLE);		


		end
		
		else if(test_request == REQUEST_NOTHING) begin
				$display("In request_nothing");
			
				for (i = 0; i < 7; i = i +1 ) begin
					check_read_data(expected_read_data);
					check_debug_state(IDLE);
					@(posedge clock);
					#1;
				end

		end	
	end

endtask

initial begin
    #10000; // 10 us with `timescale 1ns/1ps
    $fatal(1, "TIMEOUT: Simulation did not finish");
end

initial begin
	clock = 1'b0;
	
	forever begin
	#5; clock = ~clock;
	end

end

initial begin
	address = 10'd0;
	request_valid = 1'b0;
	request = REQUEST_NOTHING;
	reset_n = 1'b0;
	write_data = 128'd0;
	errors = 0;
	
	#1;
	
	//check after reset
	reset_n = 1'b1;
	check_read_data(DEFAULT_VALUE);
	check_debug_state(IDLE);
	check_ready(1'b1);
	check_valid(1'b0);
	
	//([9:0] test_address, [1:0] test_request,[127:0] test_write_data, [127:0] expected_read_data  )
	//check read then check memory still holds data
	request_and_check(10'd0, READ, DEFAULT_VALUE ,{32'd3,32'd2,32'd1,32'd0} );
	
	repeat (2) @(posedge clock);
	check_read_data({32'd3,32'd2,32'd1,32'd0}); // check memory still holds old data

	//Block 0 (memory[0] to memory[3]) contains all 32'd1
	//Block 1 (memory[4] to memory[7]) contains all 32'd2, and so on until block 3.
	//All the other blocks after block 3 contain 0.
	request_and_check({6'd1,2'b01,2'b00}, READ, DEFAULT_VALUE, {32'd7,32'd6,32'd5,32'd4} ); //Read slot 1
	request_and_check({6'd2,2'b10,2'b00}, READ, DEFAULT_VALUE,{32'd11,32'd10,32'd9,32'd8} ); //Read slot 2
	request_and_check({6'd3,2'b11,2'b00}, READ, DEFAULT_VALUE,{32'd15,32'd14,32'd13,32'd12} ); //Read slot 3
	request_and_check(10'd0, REQUEST_NOTHING, DEFAULT_VALUE,{32'd15,32'd14,32'd13,32'd12} ); //Test request_nothing, it should hold old value which is in slot 3
	
	
	request_and_check({6'd4,2'b00,2'b00}, WRITE, {32'd44, 32'd33, 32'd22, 32'd11},{32'd44, 32'd33, 32'd22, 32'd11} ); //Write to slot 4
	request_and_check({6'd4,2'b00,2'b00}, READ, DEFAULT_VALUE,{32'd44, 32'd33, 32'd22, 32'd11} ); //Read slot 4

	reset_n = 1'b0;
	#1;
	reset_n = 1'b1;
	request_and_check({6'd4,2'b00,2'b00}, READ, DEFAULT_VALUE,{32'd44, 32'd33, 32'd22, 32'd11} ); //Check reading slot 4 after reset to see it if the modified data change is still there.

		
	if (errors == 0)
        $display("ALL slow_data_memory TESTS PASSED");
   else
        $display("%0d slow_data_memory TESTS FAILED", errors);

   $finish;	

end

endmodule
