`timescale 1ns/1ps
module dma_tb;

	// Testbench drives the DUT inputs
	reg        clock;
	reg        reset_n;

	reg        cpu_request_valid;
	reg [9:0]  cpu_source_start_address;
	reg [9:0]  cpu_destination_start_address;
	reg [3:0]  cpu_beat_count;

	reg [31:0] memory_read_data;
	reg        memory_ready;
	reg        memory_dma_valid;

	// DUT drives these signals
	wire        memory_request_valid;
	wire [1:0]  memory_request;
	wire [9:0]  memory_start_address;
	wire [3:0]  memory_beat_count;
	wire [31:0] memory_write_data;
	wire        memory_write_data_valid;

	wire        dma_cpu_command_ready;
	wire        dma_memory_read_data_ready;
	integer errors;
	

dma dma_dut (
    .clock                      (clock),
    .reset_n                    (reset_n),

    .cpu_request_valid          (cpu_request_valid),
    .cpu_source_start_address   (cpu_source_start_address),
    .cpu_destination_start_address(cpu_destination_start_address),
    .cpu_beat_count             (cpu_beat_count),

    .memory_read_data           (memory_read_data),
    .memory_ready               (memory_ready),
    .memory_dma_valid               (memory_dma_valid),

    .memory_request_valid       (memory_request_valid),
    .memory_request             (memory_request),
    .memory_start_address       (memory_start_address),
    .memory_beat_count          (memory_beat_count),
    .memory_write_data          (memory_write_data),
    .memory_write_data_valid    (memory_write_data_valid),

    .dma_cpu_command_ready      (dma_cpu_command_ready),
    .dma_memory_read_data_ready (dma_memory_read_data_ready)
);	
`include "dma_tasks.vh"	
	
//memory_request
localparam REQUEST_NOTHING = 2'b00;
localparam READ = 2'b01;
localparam WRITE = 2'b10;

//dma state
localparam IDLE = 3'd0;//State for waiting to take load or store request from CPU
localparam START_READ = 3'd1;//State to indicate the start of a new request
localparam WAIT_MEMORY_READ = 3'd2;//State to wait for memory to present the requested data
localparam START_WRITE = 3'd3;
localparam WAIT_MEMORY_WRITE = 3'd4;
localparam FINISH = 3'd5;//State to indicate the finish of a request

localparam MEMORY_PROCESSING_CYCLES = 3'd3;
localparam DEFAULT_VALUE = 32'hFFFFFFFF;

//do simulate.do dma dma_tb

initial begin
	clock = 1'b0;
	forever #5 clock = ~clock;
end

initial begin
    #10000; // 10 us with `timescale 1ns/1ps
    $fatal(1, "TIMEOUT: Simulation did not finish");
end

task request_and_check;
	//from cpu
	input test_cpu_request_valid;
	input [9:0] test_cpu_source_start_address;
	input [9:0] test_cpu_destination_start_address;
	input [3:0] test_cpu_beat_count;
	input [1:0] test_memory_not_ready_cycle;
	integer i;
	integer j;
		
	begin
	
		@(negedge clock);
		#1;
		cpu_request_valid = test_cpu_request_valid;
		cpu_source_start_address = test_cpu_source_start_address;
		cpu_destination_start_address = test_cpu_destination_start_address;
		cpu_beat_count = test_cpu_beat_count;
		
		
		$display("dma In idle state, cpu setting request right now");
		check_dma_state(IDLE);
		check_memory_request_valid(1'd0);
		check_memory_request(REQUEST_NOTHING);
		check_memory_start_address(10'd0);
		check_memory_beat_count(4'd0);
		check_memory_write_data(DEFAULT_VALUE);
		check_memory_write_data_valid(1'd0);
		check_dma_cpu_command_ready(1'd1);
		check_dma_memory_read_data_ready(1'd0);
		check_counter_beat(4'd0);
		
		
		@(posedge clock);
		#1;
		cpu_request_valid = 1'd0;
		if(test_cpu_request_valid == 1'd1) begin
			
				$display("dma in first cycle of START_READ now");
				check_dma_state(START_READ);
				check_memory_request_valid(1'd1);
				check_memory_request(READ);
				check_memory_start_address(test_cpu_source_start_address);
				check_memory_beat_count(test_cpu_beat_count);
				check_memory_write_data(DEFAULT_VALUE);
				check_memory_write_data_valid(1'd0);
				check_dma_cpu_command_ready(1'd0);
				check_dma_memory_read_data_ready(1'd0);
				check_counter_beat(4'd0);
				for( i =0; i< test_memory_not_ready_cycle; i = i+1) begin
					@(posedge clock);
					#1;
					$display("dma in START_READ now waiting for memory to be ready");
					check_dma_state(START_READ);
					check_memory_request_valid(1'd1);
					check_memory_request(READ);
					check_memory_start_address(test_cpu_source_start_address);
					check_memory_beat_count(test_cpu_beat_count);
					check_memory_write_data(DEFAULT_VALUE);
					check_memory_write_data_valid(1'd0);
					check_dma_cpu_command_ready(1'd0);
					check_dma_memory_read_data_ready(1'd0);
					check_counter_beat(4'd0);
				end
				
				memory_ready = 1'd1;
				@(posedge clock);
				#1;
				memory_ready = 1'd0;
				$display("dma in first cycle of WAIT_MEMORY_READ now");			
				check_dma_state(WAIT_MEMORY_READ);
				check_memory_request_valid(1'd0);
				check_memory_request(READ);
				check_memory_start_address(test_cpu_source_start_address);
				check_memory_beat_count(test_cpu_beat_count);
				check_memory_write_data(DEFAULT_VALUE);
				check_memory_write_data_valid(1'd0);
				check_dma_cpu_command_ready(1'd0);
				check_dma_memory_read_data_ready(1'd1);
				check_counter_beat(4'd0);			
			
			
				@(posedge clock);
				#1;
				for( j = 0; j<test_cpu_beat_count; j=j+1) begin
				//1 cycle since memory accept request
					for( i =0; i< MEMORY_PROCESSING_CYCLES; i = i+1) begin
							$display("dma in WAIT_MEMORY_READ now waiting for memory to send back data");
							check_dma_state(WAIT_MEMORY_READ);
							check_memory_request_valid(1'd0);
							check_memory_request(READ);
							check_memory_start_address(test_cpu_source_start_address);
							check_memory_beat_count(test_cpu_beat_count);
							check_memory_write_data(DEFAULT_VALUE);
							check_memory_write_data_valid(1'd0);
							check_dma_cpu_command_ready(1'd0);
							check_dma_memory_read_data_ready(1'd1);
							check_counter_beat(j);	
					
						if(i == MEMORY_PROCESSING_CYCLES - 1) begin
							memory_dma_valid = 1'd1;
							memory_read_data = j;
							@(posedge clock);
							#1;
							
							if(j < test_cpu_beat_count - 1) begin
								$display("dma in WAIT_MEMORY_READ just receive data this cycle");
								check_dma_state(WAIT_MEMORY_READ);
								check_memory_request_valid(1'd0);
								check_memory_request(READ);
								check_memory_start_address(test_cpu_source_start_address);
								check_memory_beat_count(test_cpu_beat_count);
								check_memory_write_data(DEFAULT_VALUE);
								check_memory_write_data_valid(1'd0);
								check_dma_cpu_command_ready(1'd0);
								check_dma_memory_read_data_ready(1'd1);
								check_memory(j,j);
								check_counter_beat(j+1);	
							end
							
							else if(j ==test_cpu_beat_count - 1) begin//after last beat
								$display("dma in first cycle of START_WRITE after receiving last beat in WAIT_MEMORY_READ");
								check_dma_state(START_WRITE);
								check_memory_request_valid(1'd0);
								check_memory_request(READ);
								check_memory_start_address(test_cpu_source_start_address);
								check_memory_beat_count(test_cpu_beat_count);
								check_memory_write_data(DEFAULT_VALUE);
								check_memory_write_data_valid(1'd0);
								check_dma_cpu_command_ready(1'd0);
								check_dma_memory_read_data_ready(1'd0);
								check_memory(j,j);
								check_counter_beat(0);								

							end
						end
						
						else begin
							memory_dma_valid = 1'd0;
							memory_read_data = DEFAULT_VALUE;							
							@(posedge clock);
							#1;						
						end
					end							
				end
				memory_dma_valid = 1'd0;
				
				for( i =0; i< test_memory_not_ready_cycle; i = i+1) begin
					@(posedge clock);
					#1;
					$display("dma in START_WRITE now waiting for memory to be ready");
					check_dma_state(START_WRITE);
					check_memory_request_valid(1'd1);
					check_memory_request(WRITE);
					check_memory_start_address(test_cpu_destination_start_address);
					check_memory_beat_count(test_cpu_beat_count);
					check_memory_write_data(32'd0);// because first j = 0
					check_memory_write_data_valid(1'd1);
					check_dma_cpu_command_ready(1'd0);
					check_dma_memory_read_data_ready(1'd0);
					check_counter_beat(4'd0);
				end
				
				memory_ready = 1'd1;
				@(posedge clock);
				#1;
				memory_ready = 1'd0;
				
				$display("dma in first cycle of WAIT_MEMORY_WRITE,memory in first cycle after accepting request");
				check_dma_state(WAIT_MEMORY_WRITE);
				check_memory_request_valid(1'd0);
				check_memory_request(WRITE);
				check_memory_start_address(test_cpu_destination_start_address);
				check_memory_beat_count(test_cpu_beat_count);
				check_memory_write_data(32'd0);// because first j = 0
				check_memory_write_data_valid(1'd1);
				check_dma_cpu_command_ready(1'd0);
				check_dma_memory_read_data_ready(1'd0);
				check_counter_beat(4'd0);
				
				
				@(posedge clock);
				#1;
				for( j = 0; j<test_cpu_beat_count; j=j+1) begin
				//1 cycle since memory accept request
					for( i =0; i< MEMORY_PROCESSING_CYCLES; i = i+1) begin
							$display("dma in WAIT_MEMORY_WRITE now waiting for memory to finishing writing data");
							check_dma_state(WAIT_MEMORY_WRITE);
							check_memory_request_valid(1'd0);
							check_memory_request(WRITE);
							check_memory_start_address(test_cpu_destination_start_address);
							check_memory_beat_count(test_cpu_beat_count);
							check_memory_write_data(j);
							check_memory_write_data_valid(1'd1);
							check_dma_cpu_command_ready(1'd0);
							check_dma_memory_read_data_ready(1'd0);
							check_counter_beat(j);	
					
						if(i == MEMORY_PROCESSING_CYCLES - 1) begin
							memory_dma_valid = 1'd1;
							@(posedge clock);
							#1;
							
							if(j < test_cpu_beat_count - 1) begin
								$display("dma in WAIT_MEMORY_WRITE just finishing write this cycle");
								check_dma_state(WAIT_MEMORY_WRITE);
								check_memory_request_valid(1'd0);
								check_memory_request(WRITE);
								check_memory_start_address(test_cpu_destination_start_address);
								check_memory_beat_count(test_cpu_beat_count);
								check_memory_write_data(j+1);
								check_memory_write_data_valid(1'd1);
								check_dma_cpu_command_ready(1'd0);
								check_dma_memory_read_data_ready(1'd0);
								check_counter_beat(j+1);	
							end
							
							else if(j == test_cpu_beat_count - 1) begin//after last beat
								$display("dma in first cycle of FINISH after memory write last beat");
								check_dma_state(FINISH);
								check_memory_request_valid(1'd0);
								check_memory_request(WRITE);
								check_memory_start_address(test_cpu_destination_start_address);
								check_memory_beat_count(test_cpu_beat_count);
								check_memory_write_data(32'd0);
								check_memory_write_data_valid(1'd0);
								check_dma_cpu_command_ready(1'd0);
								check_dma_memory_read_data_ready(1'd0);
								check_counter_beat(4'd0);								

							end
						end
						
						else begin
							memory_dma_valid = 1'd0;							
							@(posedge clock);
							#1;						
						end
					end							
				end			
			
				memory_dma_valid = 1'd0;
				
				@(posedge clock);
				#1;
				$display("dma in first cycle of Idle after coming back from FINISH now");
				check_dma_state(IDLE);
				check_memory_request_valid(1'd0);
				check_memory_request(REQUEST_NOTHING);
				check_memory_start_address(10'd0);
				check_memory_beat_count(4'd0);
				check_memory_write_data(DEFAULT_VALUE);
				check_memory_write_data_valid(1'd0);
				check_dma_cpu_command_ready(1'd1);
				check_dma_memory_read_data_ready(1'd0);
				check_counter_beat(4'd0);					
			
		
		end
		
		
		
		else begin
		
		
		
		
		end
		
	
	
	
	
	end






endtask

initial begin
	#10000;
	$fatal(1,"Timed out");

end

initial begin
	reset_n = 1'd0;
	cpu_request_valid=1'd0;
	cpu_source_start_address=10'd0;
	cpu_destination_start_address=10'd0;
	cpu_beat_count=4'd0;
	memory_read_data=32'd0;
	memory_ready=1'd0;
	memory_dma_valid=1'd0;
	errors = 0;
	
	#1;
	reset_n = 1'd1;
	
// test_cpu_request_valid (1 bit), test_cpu_source_start_address (10 bits), 
// test_cpu_destination_start_address (10 bits), test_cpu_beat_count (4 bits), test_memory_not_ready_cycle (2 bits)
	
	request_and_check(1'd1, 10'd0, 10'd24,4'd3,2'd1);

	
	
	if (errors == 0)
        $display("ALL dma_tb TESTS PASSED");
   else
        $display("%0d dma_tbTESTS FAILED", errors);

   $finish;	


end




endmodule











