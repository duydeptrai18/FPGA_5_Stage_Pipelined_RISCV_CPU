module slow_dma_data_memory(
	input clock,
	input reset_n,
	
	//from dma
	input dma_request_valid,
	input [1:0] dma_request,
	input [9:0] dma_start_address,
	input [3:0] dma_beat_count,
	input [31:0] dma_write_data,
	input dma_memory_write_data_valid, //to indicate when a new write data is valid	
	input dma_memory_read_data_ready, //to show when dma is ready to accept the read data
	input dma_memory_write_ready,//to show when dma is ready to acknowledge the write

	//to dma
	output reg memory_ready,//let dma knows it cannot request anymore
	output reg memory_dma_valid,//let dma knows when a write or read is finished
	output reg memory_dma_write_ready,//let dma knows when memory will accept the write data in a write burst
	output reg [31:0] memory_read_data
		
);

//memory state
localparam IDLE             = 2'b00;
localparam READ_PROCESSING  = 2'b01;
localparam WRITE_PROCESSING = 2'b10;
localparam FINISH           = 2'b11;

//memory request
localparam REQUEST_NOTHING = 2'b00;
localparam READ = 2'b01;
localparam WRITE = 2'b10;

localparam MEMORY_PROCESSING_CYCLES = 3'd3;

//use these temp so input can change
reg [9:0] temp_address;
reg [31:0] temp_write_data;

reg [3:0] memory_counter_beat;
reg [2:0] counter;
reg [1:0] memory_state;

reg [31:0] memory [0:255];


always @(posedge clock or negedge reset_n) begin
	if(!reset_n) begin
		memory_counter_beat<=4'd0;
		counter<=3'd0;
		memory_state<=IDLE;
		memory_ready <= 1'b1;
		memory_dma_valid <= 1'b0;
		memory_dma_write_ready<=1'b0;
		memory_read_data <= 32'd0;		
		temp_address <=10'd0;
		temp_write_data <=32'd0;

	end


	else begin
		case(memory_state) 
		
		IDLE: begin
			if(dma_request_valid) begin // when a request comes
				temp_address<=dma_start_address;
				if(dma_request == READ) begin //read
					memory_state<=READ_PROCESSING;
					memory_ready<=1'b0;				
				
				
				end
	
				else if(dma_request == WRITE) begin //write
					temp_write_data<=write_data;
					memory_state<=WRITE_PROCESSING;
					memory_ready<=1'b0;
				end
			
			end
		
		end

		READ_PROCESSING: begin
			if(counter < MEMORY_PROCESSING_CYCLES-3'd1) counter<=counter+3'b1;
			
			if(memory_dma_valid) begin
				if(dma_memory_read_data_ready) begin
					counter<= 3'd0;
					if(memory_counter_beat == dma_beat_count -4'd1) begin
						temp_address<= 10'd0;
						memory_dma_valid <= 1'b0;
						memory_counter_beat<=4'd0;
						state<= FINISH;
								
					end
					else if (memory_counter_beat < dma_beat_count - 4'd1) begin										
						temp_address<= temp_address + 10'd4;
						memory_dma_valid <= 1'b0;
						memory_counter_beat<= memory_counter_beat + 4'd1;
						state<= READ_PROCESSING;
					end
				end
			end
			
			
			else if(counter == MEMORY_PROCESSING_CYCLES-3'd1) begin //when the reading process is finished, read_data is present and valid is pulsed up.
				read_data[31:0] <= memory[temp_address[9:2]];		
				memory_dma_valid <= 1'b1;
							
			end
		end

		WRITE_PROCESSING: begin
			if(counter < MEMORY_PROCESSING_CYCLES-3'd1) counter<=counter+3'b1;

			if(dma_memory_write_data_valid && memory_dma_write_ready) begin//when dma present new write data and memory is ready to accept it, start new write cycle.
				counter<= 3'd0;
				memory_dma_write_ready<=1'b0;
				if(memory_counter_beat == dma_beat_count -4'd1) begin
					temp_data<=32'd0;
					temp_address<= 10'd0;
					memory_dma_valid <= 1'b0;
					memory_counter_beat<=4'd0;
					state<= FINISH;
								
				end
				else if (memory_counter_beat < dma_beat_count - 4'd1) begin										
					temp_data<= dma_write_data;
					temp_address<= temp_address + 10'd4;
					memory_dma_valid <= 1'b0;
					memory_counter_beat<= memory_counter_beat + 4'd1;
					state<= WRITE_PROCESSING;
				end
			end
			
			else if(memory_dma_valid && dma_memory_write_ready) begin //when memory finishes writing and dma acknowledge that, we deassert memory_dma_valid because we dont want dma to keep seeing that we have finished writing
				memory_dma_valid <= 1'b0;
				memory_dma_write_ready<=1'b1;
			end
			
			else if(counter == MEMORY_PROCESSING_CYCLES-3'd1) begin //when the writing is completed, set counter like below so it can not keep writing 
				counter <= MEMORY_PROCESSING_CYCLES;
				memory[temp_address[9:2]] <= temp_data;
				memory_dma_valid <= 1'b1;
			end			

		end
		
		
		FINISH: begin

			// go back to state IDLE and ready to take on new request.
			memory_counter_beat<=4'd0;
			counter<=3'd0;
			memory_state<=IDLE;
			memory_ready <= 1'b1;
			memory_dma_valid <= 1'b0;
			memory_read_data <= 32'd0;		
			temp_address <=10'd0;
			temp_write_data <=32'd0;
		end
end

endmodule. saved dont say anything