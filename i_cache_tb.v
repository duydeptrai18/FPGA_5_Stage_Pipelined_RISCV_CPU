/*
Test cases:
1: Load all 4 cache slots after reset with next_pc at different data_index.
2: Read the slot at different data index.
3: Overwrite valid slot with different tag.
4: Read after reset to see if it holds the modification.
*/
`timescale 1ns/1ps
module i_cache_tb;
	
reg clock;
reg reset_n;

reg cpu_request;
reg [31:0] cpu_next_pc;

reg [127:0] memory_data;
reg memory_ready;
reg memory_data_valid;

wire memory_request_valid;
wire memory_request;
wire [9:0] memory_next_pc;

wire [31:0] next_instruction;
wire i_cache_stall;
wire [1:0] debug_state;
integer i;
integer errors;
integer test_number;

i_cache i_cache_dut (
    .clock(clock),
    .reset_n(reset_n),
	 .cpu_request(cpu_request),
    .cpu_next_pc(cpu_next_pc),
    .memory_data(memory_data),
    .memory_ready(memory_ready),
    .memory_data_valid(memory_data_valid),
    .memory_request_valid(memory_request_valid),
    .memory_request(memory_request),
    .memory_next_pc(memory_next_pc),
    .next_instruction(next_instruction),
    .i_cache_stall(i_cache_stall), 
    .debug_state(debug_state)
);	


//memory_request
localparam REQUEST_NOTHING = 1'b0;
localparam READ = 1'b1;

//state
localparam IDLE = 2'd0;//State for waiting to take load or store request from CPU
localparam START = 2'd1;//State to indicate the start of a new request
localparam WAIT_MEMORY_READ = 2'd2;//State to wait for memory to present the requested data
localparam FINISH = 2'd3;//State to indicate the finish of a request

localparam DEFAULT_CACHE_VALUE = 32'hFFFFFFFF;
localparam PROCESSING_CYCLES = 3'd3;

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

task check_memory_request_valid;
    input expected_memory_request_valid;

    begin
        if (memory_request_valid !== expected_memory_request_valid) begin
            errors = errors + 1;
            $display("FAIL memory_request_valid=%b expected=%b",
                     memory_request_valid, expected_memory_request_valid);
        end
        else
            $display("PASS memory_request_valid=%b", memory_request_valid);
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
        else
            $display("PASS debug_state=%b", debug_state);
    end
endtask

task check_memory_request;
    input expected_memory_request;

    begin
        if (memory_request !== expected_memory_request) begin
            errors = errors + 1;
            $display("FAIL memory_request=%b expected=%b",
                     memory_request, expected_memory_request);
        end
        else
            $display("PASS memory_request=%b", memory_request);
    end
endtask

task check_i_cache_ready;
    input expected_i_cache_ready;
    begin
        if (i_cache_dut.i_cache_ready !== expected_i_cache_ready) begin
            errors = errors + 1;
            $display("FAIL i_cache_ready=%b expected=%b",
                     i_cache_dut.i_cache_ready, expected_i_cache_ready);
        end
        else
            $display("PASS i_cache_ready=%b", i_cache_dut.i_cache_ready);
    end
endtask

task check_memory_next_pc;
    input [9:0] expected_memory_next_pc;

    begin
        if (memory_next_pc !== expected_memory_next_pc) begin
            errors = errors + 1;
            $display("FAIL memory_next_pc=%h expected=%h",
                     memory_next_pc, expected_memory_next_pc);
        end
        else
            $display("PASS memory_next_pc=%h", memory_next_pc);
    end
endtask

task check_next_instruction;
    input [31:0] expected_next_instruction;

    begin
        if (next_instruction !== expected_next_instruction) begin
            errors = errors + 1;
            $display("FAIL next_instruction=%h expected=%h",
                     next_instruction, expected_next_instruction);
        end
        else
            $display("PASS next_instruction=%h", next_instruction);
    end
endtask

task check_i_cache_stall;
    input expected_i_cache_stall;

    begin
        if (i_cache_stall !== expected_i_cache_stall) begin
            errors = errors + 1;
            $display("FAIL i_cache_stall=%b expected=%b",
                     i_cache_stall, expected_i_cache_stall);
        end
        else
            $display("PASS i_cache_stall=%b", i_cache_stall);
    end
endtask

task request_and_check;
	input test_cpu_request;
	input [31:0] test_cpu_next_pc;
	input [31:0] expected_before_next_instruction;
	input [31:0] expected_after_next_instruction;
	input [127:0] expected_memory_data;	
	input expected_i_cache_stall;
	begin

	test_number = test_number + 1;
	$display("TEST %0d", test_number);
	
	$display("Setting up the request in IDLE state");
	@(negedge clock);
	cpu_request=test_cpu_request;
	cpu_next_pc = test_cpu_next_pc;
	memory_ready = 1'b1;
	#1;
	check_i_cache_ready(1'b1);
	check_debug_state(IDLE);
	check_memory_request(REQUEST_NOTHING);
	check_memory_request_valid(1'b0);
	$display("Check before next_instruction");
	check_next_instruction(expected_before_next_instruction);
	check_i_cache_stall(expected_i_cache_stall);

	if(expected_i_cache_stall) begin
		@(posedge clock);
		#1;
		cpu_request = 1'b0;
		$display("Tag misses, in START state right now");
		check_i_cache_ready(1'b0);
		check_debug_state(START);
		check_memory_request(READ);
		check_memory_request_valid(1'b1);
		check_memory_next_pc(test_cpu_next_pc[9:0]);
		$display("Check before next_instruction");
		check_next_instruction(expected_before_next_instruction);	
		check_i_cache_stall(expected_i_cache_stall);	

		for (i = 0; i < PROCESSING_CYCLES; i = i + 1) begin
			@(posedge clock);
			#1;
			$display("Tag misses, in wait_memory state right now");
			check_i_cache_ready(1'b0);
			memory_ready = 1'b0;
			check_debug_state(WAIT_MEMORY_READ);
			check_memory_request(READ);
			check_memory_request_valid(1'b0);
			$display("Check before next_instruction");
			check_next_instruction(expected_before_next_instruction);	
			check_i_cache_stall(expected_i_cache_stall);			

		end

		@(posedge clock);
		#1;
		
		memory_data_valid = 1'b1;
		memory_data = expected_memory_data;

		@(posedge clock);
		#1;
		memory_data_valid = 1'b0;
		memory_ready = 1'b1;
		$display("Tag misses, in FINISH state right now, received data");
		check_i_cache_ready(1'b1);
		check_debug_state(FINISH);
		check_memory_request(READ);
		check_memory_request_valid(1'b0);
		$display("Check after next_instruction");
		check_next_instruction(expected_after_next_instruction);	
		check_i_cache_stall(1'b0);	

		@(posedge clock);
		#1;
		$display("Tag misses, in IDLE state right now after going back from FINISH state");
		check_i_cache_ready(1'b1);
		check_debug_state(IDLE);
		check_memory_request(REQUEST_NOTHING);
		check_memory_request_valid(1'b0);
		$display("Check after next_instruction");
		check_next_instruction(expected_after_next_instruction);	
		check_i_cache_stall(1'b0);
	end


	else if(!expected_i_cache_stall) begin
		$display("Tag hit, in IDLE state right now");
		check_i_cache_ready(1'b1);
		check_debug_state(IDLE);
		check_memory_request(REQUEST_NOTHING);
		check_memory_request_valid(1'b0);
		$display("Check before next_instruction");
		check_next_instruction(expected_before_next_instruction);
		check_i_cache_stall(expected_i_cache_stall);

			for (i = 0; i < PROCESSING_CYCLES; i = i + 1) begin
			@(posedge clock);
			#1;
			$display("Tag hit, in IDLE state right now, checking in the loop");
			check_i_cache_ready(1'b1);
			check_debug_state(IDLE);
			check_memory_request(REQUEST_NOTHING);
			check_memory_request_valid(1'b0);
			$display("Check before next_instruction");
			check_next_instruction(expected_before_next_instruction);
			check_i_cache_stall(expected_i_cache_stall);			

		end	

	end


	end

endtask

initial begin
   test_number = 0;
	cpu_request = 1'b0;
	cpu_next_pc = 32'd0;
	memory_data = 128'd0;
	memory_ready = 1'b1;
	memory_data_valid = 1'b0;
	reset_n = 1'b0;
	errors = 0;

	@(posedge clock);
	#1;
	reset_n = 1'b1;
//next_pc = {22'd0, tag, slot, data_index, 2'b00}
	
//([31:0] test_next_pc, [31:0] expected_before_next_instruction, [31:0] expected_after_next_instruction, [127:0] expected_memory_data, expected_i_cache_stall)
//All 4 slots are invalid, now we load data into them.
 	request_and_check(1'b1,{22'd0,4'd0,2'd0,2'd0, 2'b00 }, DEFAULT_CACHE_VALUE, 32'd10 ,{32'd40,32'd30,32'd20,32'd10} , 1'b1  ); 
//Load in slot 0 after reset
 	request_and_check(1'b1,{22'd0,4'd0,2'd1,2'd1, 2'b00 }, DEFAULT_CACHE_VALUE, 32'd21 ,{32'd41,32'd31,32'd21, 32'd11} , 1'b1  ); 
	//Load in slot 1 after reset 
 	request_and_check(1'b1,{22'd0,4'd0,2'd2,2'd2, 2'b00 }, DEFAULT_CACHE_VALUE, 32'd32 ,{32'd42,32'd32,32'd22,32'd12} , 1'b1  ); 
//Load in slot 2 after reset
 	request_and_check(1'b1,{22'd0,4'd0,2'd3,2'd3, 2'b00 }, DEFAULT_CACHE_VALUE, 32'd43 ,{32'd43,32'd33,32'd23,32'd13} , 1'b1  ); 
//Load in slot 3 after reset

//Slot 3 is valid, try reading the slot at different data_index:
 	request_and_check(1'b1,{22'd0,4'd0,2'd3,2'd2, 2'b00 }, 32'd33, 32'd33 ,{32'd43,32'd33,32'd23,32'd13} , 1'b0  ); 
//Reading slot 3 at different data_index
 	request_and_check(1'b1,{22'd0,4'd0,2'd3,2'd1, 2'b00 }, 32'd23, 32'd23,{32'd43,32'd33,32'd23,32'd13} , 1'b0  ); 
//Reading slot 3 at different data_index
 	request_and_check(1'b1,{22'd0,4'd0,2'd3,2'd0, 2'b00 }, 32'd13, 32'd13 ,{32'd43,32'd33,32'd23,32'd13} , 1'b0  ); 
//Reading slot 3 at different data_index

//Load in slot 0 with different tag to see if it overwrites the old slot, 32'd10 is the old data at same location.
 	request_and_check(1'b1,{22'd0,4'd1,2'd0,2'd0, 2'b00 }, 32'd10, 32'd100 ,{32'd400,32'd300,32'd200,32'd100} , 1'b1  ); 

	//Reset invalidates previously cached slots, try refill it again with the same address to confirm the tag will miss.
	cpu_request = 1'b0;
	cpu_next_pc = 32'd0;
	memory_data = 128'd0;
	memory_ready = 1'b1;
	memory_data_valid = 1'b0;
	reset_n = 1'b0;
	@(posedge clock);
	#1;
	reset_n = 1'b1;

	request_and_check(1'b1,{22'd0,4'd0,2'd0,2'd0, 2'b00 }, DEFAULT_CACHE_VALUE, 32'd10 ,{32'd40,32'd30,32'd20,32'd10} , 1'b1  );
	request_and_check(1'b0,{22'd0,4'd0,2'd0,2'd0, 2'b00 }, 32'd10, 32'd10 ,{32'd40,32'd30,32'd20,32'd10} , 1'b0  ); 

	
	if (errors == 0)
        $display("ALL i_cache TESTS PASSED");
   else
        $display("%0d i_cache TESTS FAILED", errors);

   $finish;	



end

endmodule
