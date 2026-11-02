`timescale 1ns/1ps
module i_cache_slow_instruction_memory_tb;

reg clock;
reg reset_n;

reg [31:0] cpu_next_pc;

wire [127:0] memory_data;
wire memory_ready;
wire memory_data_valid;

wire memory_request_valid;
wire memory_request;
wire [9:0] memory_next_pc;

wire [31:0] next_instruction;
wire i_cache_stall;
wire [1:0] i_cache_debug_state;

wire [1:0] memory_debug_state;
integer errors;
integer i;
integer test_number;

localparam MEMORY_PROCESSING_CYCLES = 3'd3;

//memory_request
localparam REQUEST_NOTHING = 1'b0;
localparam READ = 1'b1;

//I_CACHE state
localparam I_CACHE_IDLE = 2'd0;//State for waiting to take load or store request from CPU
localparam I_CACHE_START = 2'd1;//State to indicate the start of a new request
localparam I_CACHE_WAIT_MEMORY_READ = 2'd2;//State to wait for memory to present the requested data
localparam I_CACHE_FINISH = 2'd3;//State to indicate the finish of a request

//MEMORY state
localparam MEMORY_IDLE             = 2'b00;
localparam MEMORY_READ_PROCESSING  = 2'b01;
localparam MEMORY_FINISH           = 2'b10;

i_cache i_cache_dut (
    .clock(clock),
    .reset_n(reset_n),
    .cpu_next_pc(cpu_next_pc),
    .memory_data(memory_data),
    .memory_ready(memory_ready),
    .memory_data_valid(memory_data_valid),
    .memory_request_valid(memory_request_valid),
    .memory_request(memory_request),
    .memory_next_pc(memory_next_pc),
    .next_instruction(next_instruction),
    .i_cache_stall(i_cache_stall), 
    .debug_state(i_cache_debug_state)
);	


slow_instruction_memory slow_instruction_memory_dut (
    .clock(clock),
    .reset_n(reset_n),
    .address(memory_next_pc),
    .request_valid(memory_request_valid),
    .request(memory_request),
    .ready(memory_ready),
    .valid(memory_data_valid),
    .read_data(memory_data),
	 .debug_state(memory_debug_state)
);

task check_memory_data;
    input [127:0] expected_memory_data;
    begin
        if (memory_data !== expected_memory_data) begin
            errors = errors + 1;
            $display("FAIL memory_data=%h expected=%h",
                     memory_data, expected_memory_data);
        end
        else
            $display("PASS memory_data=%h", memory_data);
    end
endtask

task check_memory_ready;
    input expected_memory_ready;
    begin
        if (memory_ready !== expected_memory_ready) begin
            errors = errors + 1;
            $display("FAIL memory_ready=%b expected=%b",
                     memory_ready, expected_memory_ready);
        end
        else
            $display("PASS memory_ready=%b", memory_ready);
    end
endtask

task check_memory_data_valid;
    input expected_memory_data_valid;
    begin
        if (memory_data_valid !== expected_memory_data_valid) begin
            errors = errors + 1;
            $display("FAIL memory_data_valid=%b expected=%b",
                     memory_data_valid, expected_memory_data_valid);
        end
        else
            $display("PASS memory_data_valid=%b", memory_data_valid);
    end
endtask

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

task check_i_cache_debug_state;
    input [1:0] expected_i_cache_debug_state;
    begin
        if (i_cache_debug_state !== expected_i_cache_debug_state) begin
            errors = errors + 1;
            $display("FAIL i_cache_debug_state=%b expected=%b",
                     i_cache_debug_state, expected_i_cache_debug_state);
        end
        else
            $display("PASS i_cache_debug_state=%b", i_cache_debug_state);
    end
endtask

task check_memory_debug_state;
    input [1:0] expected_memory_debug_state;
    begin
        if (memory_debug_state !== expected_memory_debug_state) begin
            errors = errors + 1;
            $display("FAIL memory_debug_state=%b expected=%b",
                     memory_debug_state, expected_memory_debug_state);
        end
        else
            $display("PASS memory_debug_state=%b", memory_debug_state);
    end
endtask

task request_and_check;

	input [31:0] test_cpu_next_pc;
	input [31:0] expected_next_instruction;
	input [127:0] expected_memory_read_data;
	input expected_i_cache_stall;

	begin

	test_number = test_number + 1;
	$display("TEST %0d", test_number);
	
	@(negedge clock);
	cpu_next_pc = test_cpu_next_pc;
	
	#1;
	$display("Setting up the request");
	$display("Check i_cache variables");
	check_i_cache_debug_state(I_CACHE_IDLE);
	check_memory_request(REQUEST_NOTHING);
	check_memory_request_valid(1'b0);
	check_i_cache_stall(expected_i_cache_stall);
	
	$display("Check slow_instruction_memory variables");
	check_memory_debug_state(MEMORY_IDLE);
	check_memory_ready(1'b1);
	check_memory_data_valid(1'b0);
	
	
	if(expected_i_cache_stall) begin
	
		@(posedge clock);
		#1;
		$display("Tag misses, i_cache in START state right now, memory sees the request this cycle");
		$display("Check i_cache variables");
		check_i_cache_debug_state(I_CACHE_START);
		check_memory_request(READ);
		check_memory_request_valid(1'b1);
		check_memory_next_pc(test_cpu_next_pc[9:0]);
		check_i_cache_stall(expected_i_cache_stall);		
		
		$display("Check slow_instruction_memory variables");
		check_memory_debug_state(MEMORY_IDLE);
		check_memory_ready(1'b1);
		check_memory_data_valid(1'b0);	
		
		@(posedge clock);
		#1;
			
		$display("Tag misses, i_cache in wait_memory state right now, memory in first cycle of read_processing state ");
		$display("Check i_cache variables");
		check_i_cache_debug_state(I_CACHE_WAIT_MEMORY_READ);
		check_memory_request(READ);
		check_memory_request_valid(1'b0);
		check_i_cache_stall(expected_i_cache_stall);		

		$display("Check slow_instruction_memory variables");
		check_memory_debug_state(MEMORY_READ_PROCESSING);
		check_memory_ready(1'b0);
		check_memory_data_valid(1'b0);			
		
		$display("Waiting for memory to finish");
		for (i = 0; i < MEMORY_PROCESSING_CYCLES - 1; i = i +1 ) begin
			@(posedge clock);
			#1;
			
			$display("Check i_cache variables");
			check_i_cache_debug_state(I_CACHE_WAIT_MEMORY_READ);
			check_memory_request(READ);
			check_memory_request_valid(1'b0);
			check_i_cache_stall(expected_i_cache_stall);		

			$display("Check slow_instruction_memory variables");
			check_memory_debug_state(MEMORY_READ_PROCESSING);
			check_memory_ready(1'b0);
			check_memory_data_valid(1'b0);			

		end		
		
		@(posedge clock);
		#1;
		$display("Memory in first cycle of FINISH state, when data is present, now i_cache sees valid data flag");
		$display("Check i_cache variables");
		check_i_cache_debug_state(I_CACHE_WAIT_MEMORY_READ);
		check_memory_request(READ);
		check_memory_request_valid(1'b0);
		check_i_cache_stall(expected_i_cache_stall);		
	
		$display("Check slow_instruction_memory variables");
		check_memory_debug_state(MEMORY_FINISH);
		check_memory_ready(1'b0);
		check_memory_data_valid(1'b1);
		check_memory_data(expected_memory_read_data);
		
		
		@(posedge clock);
		#1;
		$display("Memory in first cycle of IDLE state after getting back, i_cache in FINISH state right now, received data ");
		$display("Check i_cache variables");
		check_i_cache_debug_state(I_CACHE_FINISH);
		check_memory_request(READ);
		check_memory_request_valid(1'b0);
		check_i_cache_stall(1'b0);
		check_next_instruction(expected_next_instruction);		
		
		$display("Check slow_instruction_memory variables");
		check_memory_debug_state(MEMORY_IDLE);
		check_memory_ready(1'b1);
		check_memory_data_valid(1'b0);		
		check_memory_data(expected_memory_read_data);
		
		@(posedge clock);
		#1;
		$display("Memory in IDLE, i_cache in first cycle IDLE state after going back from FINISH state ");
		$display("Check i_cache variables");
		check_i_cache_debug_state(I_CACHE_IDLE);
		check_memory_request(REQUEST_NOTHING);
		check_memory_request_valid(1'b0);
		check_i_cache_stall(1'b0);
		check_next_instruction(expected_next_instruction);		
		
		$display("Check slow_instruction_memory variables");
		check_memory_debug_state(MEMORY_IDLE);
		check_memory_ready(1'b1);
		check_memory_data_valid(1'b0);		
		check_memory_data(expected_memory_read_data);		
		
	end
	
	else if (!expected_i_cache_stall) begin
		#1;
		$display("Tag hit, i_cache in IDLE state right now");
		$display("Check i_cache variables");
		check_i_cache_debug_state(I_CACHE_IDLE);
		check_memory_request(REQUEST_NOTHING);
		check_memory_request_valid(1'b0);
		check_i_cache_stall(expected_i_cache_stall);	
		check_next_instruction(expected_next_instruction);
		
		$display("Check slow_instruction_memory variables");
		check_memory_debug_state(MEMORY_IDLE);
		check_memory_ready(1'b1);
		check_memory_data_valid(1'b0);		

			
			for (i = 0; i < MEMORY_PROCESSING_CYCLES; i = i + 1) begin
			@(posedge clock);
			#1;
			$display("Tag hit, i_cache in IDLE state right now, checking in the loop");
			check_i_cache_debug_state(I_CACHE_IDLE);
			check_memory_request(REQUEST_NOTHING);
			check_memory_request_valid(1'b0);
			check_i_cache_stall(expected_i_cache_stall);		
			check_next_instruction(expected_next_instruction);	
			
			
			$display("Check slow_instruction_memory variables");
			check_memory_debug_state(MEMORY_IDLE);
			check_memory_ready(1'b1);
			check_memory_data_valid(1'b0);

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
	cpu_next_pc = 32'd0;
	reset_n = 1'b0;
	errors = 0;
	test_number = 0;
	
	@(posedge clock);
	#1;
	reset_n = 1'b1;
	
	
//request_and_check([31:0] test_cpu_next_pc,[31:0] expected_next_instruction,[127:0] expected_memory_read_data,expected_i_cache_stall);
//test_cpu_next_pc = {22'd0, tag, slot, data_index, 2'b00}	
	request_and_check({22'd0, 4'd0, 2'd0, 2'd0 ,2'b00}, 32'd0, {32'd3,32'd2,32'd1,32'd0}, 1'b1);
	request_and_check({22'd0, 4'd0, 2'd1, 2'd1 ,2'b00}, 32'd5, {32'd7,32'd6,32'd5,32'd4}, 1'b1);
	request_and_check({22'd0, 4'd0, 2'd2, 2'd2 ,2'b00}, 32'd10, {32'd11,32'd10,32'd9,32'd8}, 1'b1);
	request_and_check({22'd0, 4'd0, 2'd3, 2'd3 ,2'b00}, 32'd15, {32'd15,32'd14,32'd13,32'd12}, 1'b1);
	
//Slot 3 is valid, try reading the slot at different data_index:
 	request_and_check({22'd0,4'd0,2'd3,2'd2, 2'b00 }, 32'd14 ,{32'd15,32'd14,32'd13,32'd12} , 1'b0  ); 
 	request_and_check({22'd0,4'd0,2'd3,2'd1, 2'b00 }, 32'd13 ,{32'd15,32'd14,32'd13,32'd12} , 1'b0  ); 
 	request_and_check({22'd0,4'd0,2'd3,2'd0, 2'b00 }, 32'd12 ,{32'd15,32'd14,32'd13,32'd12} , 1'b0  ); 
	
//Load in slot 0 with different tag to see if it overwrites the old slot.
 	request_and_check({22'd0,4'd1,2'd0,2'd0, 2'b00 }, 32'd16 ,{32'd19,32'd18,32'd17,32'd16} , 1'b1  ); 
	
//Reset invalidates previously cached slots, try refill it again with the same address to confirm the tag will miss.
	cpu_next_pc = 32'd0;
	reset_n = 1'b0;
	@(posedge clock);
	#1;
	reset_n = 1'b1;

	request_and_check({22'd0, 4'd0, 2'd0, 2'd0 ,2'b00}, 32'd0, {32'd3,32'd2,32'd1,32'd0}, 1'b1);
	
	if (errors == 0)
        $display("ALL i_cache_slow_instruction_memory TESTS PASSED");
   else
        $display("%0d i_cache_slow_instruction_memory TESTS FAILED", errors);
	$finish;
end


endmodule


