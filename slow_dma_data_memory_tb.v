module slow_dma_data_memory_tb;

	// Testbench drives these inputs
	reg        clock;
	reg        reset_n;

	reg        dma_memory_request_valid;
	reg [1:0]  dma_memory_request;
	reg [9:0]  dma_memory_start_address;
	reg [3:0]  dma_memory_beat_count;
	reg [31:0] dma_memory_write_data;
	reg        dma_memory_write_data_valid;
	reg        dma_memory_read_data_ready;
	reg        dma_memory_write_ready;

	// Memory DUT drives these outputs
	wire        memory_dma_ready;
	wire        memory_dma_valid;
	wire        memory_dma_write_ready;
	wire [31:0] memory_dma_read_data;
	integer errors;

slow_dma_data_memory slow_dma_data_memory_dut (
    .clock(clock),
    .reset_n(reset_n),

    // From DMA
    .dma_memory_request_valid(dma_memory_request_valid),
    .dma_memory_request(dma_memory_request),
    .dma_memory_start_address(dma_memory_start_address),
    .dma_memory_beat_count(dma_memory_beat_count),
    .dma_memory_write_data(dma_memory_write_data),
    .dma_memory_write_data_valid(dma_memory_write_data_valid),
    .dma_memory_read_data_ready(dma_memory_read_data_ready),
    .dma_memory_write_ready(dma_memory_write_ready),

    // To DMA
    .memory_dma_ready(memory_dma_ready),
    .memory_dma_valid(memory_dma_valid),
    .memory_dma_write_ready(memory_dma_write_ready),
    .memory_dma_read_data(memory_dma_read_data)
);	

`include "slow_dma_data_memory_tasks.vh"

localparam IDLE             = 2'b00;
localparam READ_PROCESSING  = 2'b01;
localparam WRITE_PROCESSING = 2'b10;
localparam FINISH           = 2'b11;

localparam REQUEST_NOTHING = 2'b00;
localparam READ = 2'b01;
localparam WRITE = 2'b10;

localparam MEMORY_PROCESSING_CYCLES = 3'd3;

task request_and_check;

	input        test_dma_memory_request_valid;
	input [1:0]  test_dma_memory_request;
	input [9:0]  test_dma_memory_start_address;
	input [3:0]  test_dma_memory_beat_count;

	input  [1:0]  test_dma_memory_write_data_valid_not_ready_cyles;
	input  [1:0]  test_dma_memory_read_data_ready_not_ready_cyles;
	input  [1:0]  test_dma_memory_write_ready_not_ready_cyles;
	
	input [95:0] expected_read_data; //max 3 beats
	
	integer i,j,k;

	begin
		dma_memory_request_valid = test_dma_memory_request_valid;
		dma_memory_request = test_dma_memory_request;
		dma_memory_start_address = test_dma_memory_start_address;
		dma_memory_beat_count = test_dma_memory_beat_count;
			
		dma_memory_write_data = 32'd0;
		dma_memory_write_data_valid = 1'b0;
		dma_memory_read_data_ready = 1'b0;
		dma_memory_write_ready = 1'b0;
		
		$display("Memory in idle, dma setting up request");
	   check_memory_counter_beat(4'd0);
		check_memory_state(IDLE);
		check_memory_dma_ready(1'b1);
		check_memory_dma_valid(1'b0);
		check_memory_dma_write_ready(1'b0);
		check_memory_dma_read_data(32'd0);
		check_temp_address(10'd0);
		check_temp_write_data(32'd0);			
	
		@(posedge clock);
		#1;
		$display("memory still in idle because no request, or read or write processing");
		if(test_dma_memory_request_valid) begin
			
			if(test_dma_memory_request==READ) begin
				for(j=0;j<test_dma_memory_beat_count;j=j+1) begin
				
					for(i=0;i<test_dma_memory_beat_count;i=i+1) begin
						$display("memory processing the read request");
						check_memory_counter_beat(i);
						check_memory_state(READ_PROCESSING);
						check_memory_dma_ready(1'b0);
						check_memory_dma_valid(1'b0);
						check_memory_dma_write_ready(1'b0);
						check_memory_dma_read_data(32'd0);
						check_temp_address(test_dma_memory_start_address);
						check_temp_write_data(32'd0);				
				
						@(posedge clock);
						#1;
						if(i== MEMORY_PROCESSING_CYCLES-1) begin
							$display("Memory display read data first this cycle");
							check_counter(MEMORY_PROCESSING_CYCLES);
							check_memory_counter_beat(i);
							check_memory_state(READ_PROCESSING);
							check_memory_dma_ready(1'b0);
							check_memory_dma_valid(1'b1);
							check_memory_dma_write_ready(1'b0);
							check_memory_dma_read_data(expected_read_data[(32*i) +: 32]);
							check_temp_address(test_dma_memory_start_address);
							check_temp_write_data(32'd0);			
			
							for(k=0;k<test_dma_memory_read_data_ready_not_ready_cyles;k=k+1)begin
								@(posedge clock);
								#1;
								$display("Memory waiting for dma to accept read data");
								check_counter(MEMORY_PROCESSING_CYCLES);
								check_memory_counter_beat(j);
								check_memory_state(READ_PROCESSING);
								check_memory_dma_ready(1'b0);
								check_memory_dma_valid(1'b1);
								check_memory_dma_write_ready(1'b0);
								check_memory_dma_read_data(expected_read_data[(32*i) +: 32]);
								check_temp_address(test_dma_memory_start_address);
								check_temp_write_data(32'd0);	
							
							end
							
							@(posedge clock);
							#1;
							$display("Memory transfer read daata to dma this cycle");
							dma_memory_read_data_ready =1'b1;
							check_memory_dma_valid(1'b1);
							
							@(posedge clock);
							#1;
							
							if(j==test_dma_memory_beat_count) begin
								$display("Memory is in first cycle of finish after read processing");
								check_counter(4'd0);
								check_memory_counter_beat(4'd0);
								check_memory_state(FINISH);
								check_memory_dma_ready(1'b0);
								check_memory_dma_valid(1'b0);
								check_memory_dma_write_ready(1'b0);
								check_memory_dma_read_data(expected_read_data[(32*i) +: 32]);
								check_temp_address(10'd0);
								check_temp_write_data(32'd0);
							end
							else if(j==test_dma_memory_beat_count) begin
								$display("Memory starts new read cycle");
								check_counter(4'd0);
								check_memory_counter_beat(j+1);
								check_memory_state(READ_PROCESSING);
								check_memory_dma_ready(1'b0);
								check_memory_dma_valid(1'b0);
								check_memory_dma_write_ready(1'b0);
								check_memory_dma_read_data(expected_read_data[(32*i) +: 32]);
								check_temp_address(test_dma_memory_start_address + 4*(i+1));
								check_temp_write_data(32'd0);
							end
							
						end
						else if(i< MEMORY_PROCESSING_CYCLES-1) begin
						
						
						end
				
				
				
					end
					
					
				end
			
			
		
	
	
			end
			else if(test_dma_memory_request==WRITE) begin
		
		
		
		
		
			end
			
			@(posedge clock);
			#1;
			$display("Memory in first cycle of Idle after getting back from finish");
			check_counter(4'd0);
			check_memory_counter_beat(4'd0);
			check_memory_state(IDLE);
			check_memory_dma_ready(1'd1);
			check_memory_dma_valid(1'b0);
			check_memory_dma_write_ready(1'b0);
			check_memory_dma_read_data(32'd0);
			check_temp_address(10'd0);
			check_temp_write_data(32'd0);			
		
		

		end
		
		
		
		
		else begin
			
		end
		
	
	
	
	
	end





endtask


initial begin
	clock = 1'b0;
	forever #5 clock = ~clock;
end

initial begin
    #10000; // 10 us with `timescale 1ns/1ps
    $fatal(1, "TIMEOUT: Simulation did not finish");
end




initial begin
	errors = 0;
	reset_n = 1'b0;
	dma_memory_request_valid = 1'b0;
	dma_memory_request = REQUEST_NOTHING;
	dma_memory_start_address = 10'd0;
	dma_memory_beat_count= 4'd0;
	dma_memory_write_data=32'd0;
	dma_memory_write_data_valid=1'b0;
	dma_memory_read_data_ready=1'b0;
	dma_memory_write_ready=1'b0;
	
	@(posedge clock);
	#1;	
	reset_n = 1'd1;
	


// test_dma_memory_request_valid (1 bit), test_dma_memory_request (2 bits), test_dma_memory_start_address (10 bits), test_dma_memory_beat_count (4 bits), test_dma_memory_write_data_valid_not_ready_cyles (2 bits), test_dma_memory_read_data_ready_not_ready_cyles (2 bits), 
//test_dma_memory_write_ready_not_ready_cyles (2 bits), expected_read_data (96 bits, up to three 32-bit beats)
	
	request_and_check(1'b1,READ,10'd4,4'd3,2'd1,2'd1,2'd1,{32'd3,32'd2,32'd1});






	if (errors == 0)
        $display("ALL dma_tb TESTS PASSED");
   else
        $display("%0d dma_tb TESTS FAILED", errors);

   $finish;	



















end
endmodule
