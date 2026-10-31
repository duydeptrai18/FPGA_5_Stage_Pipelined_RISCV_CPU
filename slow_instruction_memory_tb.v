/*
Test cases:
1: Send read request and retrieve correct data after processing_cycles, and see that the valid and ready flag operate as wanted.
2: Send no request and confirm that the memory holds old data.
*/
`timescale 1ns/1ps
module slow_instruction_memory_tb;
	
	reg clock;
	reg reset_n;
	reg [9:0] address;
	reg request_valid;
	reg request;

	wire ready;
	wire valid;
	wire [127:0] read_data;
	wire [1:0] debug_state;
	integer errors;
	integer i;

slow_instruction_memory slow_instruction_memory_dut (
    .clock(clock),
    .reset_n(reset_n),
    .address(address),
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
localparam FINISH           = 2'b10;

//request
localparam REQUEST_NOTHING = 1'b0;
localparam READ = 1'b1;

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

task request_and_check;

	input [9:0] test_address;
	input test_request;
	input [127:0] expected_read_data;

	begin
		@(negedge clock);
		#1;
		$display("Begin the task. In idle state, setting up the request");
		request_valid = 1'b1;
		address = test_address;
		request = test_request;
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
		
		else if(test_request == REQUEST_NOTHING) begin
			repeat (7) @(posedge clock);
			#1;
			check_read_data(expected_read_data);
			check_debug_state(IDLE);
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
	errors = 0;
	
	#1;
	
	//check after reset
	reset_n = 1'b1;
	check_read_data(DEFAULT_VALUE);
	check_debug_state(IDLE);
	check_ready(1'b1);
	check_valid(1'b0);
	
	
	request_and_check(10'd0, READ, {4{32'd1}} );
	
	repeat (2) @(posedge clock);
	check_read_data({4{32'd1}}); // check memory still holds old data

	//Block 0 (memory[0] to memory[3]) contains all 32'd1
	//Block 1 (memory[4] to memory[7]) contains all 32'd2, and so on until block 3.
	//All the other blocks after block 3 contain 0.
	request_and_check({6'd1,2'b01,2'b00}, READ, {4{32'd2}} ); //Test slot 1
	request_and_check({6'd2,2'b10,2'b00}, READ, {4{32'd3}} ); //Test slot 2
	request_and_check({6'd3,2'b11,2'b00}, READ, {4{32'd4}} ); //Test slot 3
	request_and_check(10'd0, REQUEST_NOTHING, {4{32'd4}} ); //Test request_nothing, it should hold old value which is in slot 3
	
	
	request_and_check({6'd4,2'b00,2'b00}, READ, {4{32'd0}} ); //Test slot 4
		
	if (errors == 0)
        $display("ALL slow_instruction_memory TESTS PASSED");
   else
        $display("%0d slow_instruction_memory TESTS FAILED", errors);

   $finish;	

end

endmodule
