module dma(
	input clock,
	input reset_n,

	//from cpu
	input cpu_request_valid,

	input [9:0] cpu_source_start_address,
	input [9:0] cpu_destination_start_address,
	input [3:0] cpu_beat_count, // assume this is never 0 when cpu request, that will be taken cared of by cpu

	//from memory
	input [31:0] memory_read_data,
	input memory_ready,
	input memory_dma_valid,

	//to memory
	output reg memory_request_valid,
	output reg [1:0] memory_request,
	output reg [9:0] memory_start_address,
	output reg [3:0] memory_beat_count,
	output reg [31:0] memory_write_data,
	output reg memory_write_data_valid, //for write burst

	//to memory and cpu
	output reg dma_cpu_command_ready,
	output reg dma_memory_read_data_ready

);
reg [3:0] counter_beat;

reg [31:0] memory [0:15];//dma buffer

reg [9:0] cpu_source_start_address_temp;
reg [9:0] cpu_destination_start_address_temp;
reg [3:0] cpu_beat_count_temp;

//memory_request
localparam REQUEST_NOTHING = 2'b00;
localparam READ = 2'b01;
localparam WRITE = 2'b10;

//dma dma_state
reg [2:0] dma_state;
localparam IDLE = 3'd0;//dma_state for waiting to take load or store request from CPU
localparam START_READ = 3'd1;//dma_state to indicate the start of a new request
localparam WAIT_MEMORY_READ = 3'd2;//dma_state to wait for memory to present the requested data
localparam START_WRITE = 3'd3;
localparam WAIT_MEMORY_WRITE = 3'd4;
localparam FINISH = 3'd5;//dma_state to indicate the finish of a request

localparam DEFAULT_VALUE = 32'hFFFFFFFF;


always @(posedge clock or negedge reset_n) begin

	if(!reset_n) begin
		dma_state<= IDLE;
		cpu_source_start_address_temp <= 10'd0;
		cpu_destination_start_address_temp <= 10'd0;
		cpu_beat_count_temp <= 4'd0;
		counter_beat <= 4'd0;
		memory_request_valid <= 1'b0;
		memory_request <= REQUEST_NOTHING;
		memory_start_address <= 10'd0;
		memory_beat_count <= 4'd0;
	 	memory_write_data <= DEFAULT_VALUE;
		memory_write_data_valid<=1'b0;
		dma_cpu_command_ready<=1'b1;
		dma_memory_read_data_ready<=1'b0;
	end

	else begin
		case(dma_state)

		IDLE: begin
			if(cpu_request_valid) begin //if do and memory_ready here, it means dma dont request until seeing memoery ready, then cpu must keep the request there for dma to see -> waste time. 
				cpu_source_start_address_temp<=cpu_source_start_address;
				cpu_destination_start_address_temp<=cpu_destination_start_address;
				cpu_beat_count_temp<= cpu_beat_count;
				memory_request_valid <= 1'b1;
				memory_request <= READ;
				memory_start_address<=cpu_source_start_address;
				memory_beat_count<=cpu_beat_count;
				dma_cpu_command_ready<=1'b0;
				dma_state<= START_READ;

			end

		end

	
		START_READ: begin
			if(memory_ready) begin
				counter_beat <= 4'd0;
				memory_request_valid <= 1'b0;
				dma_memory_read_data_ready<=1'b1;
				dma_state <= WAIT_MEMORY_READ;
				
			end
		end

		WAIT_MEMORY_READ: begin
			if(memory_dma_valid) begin
				memory[counter_beat] <= memory_read_data;				
				counter_beat <= counter_beat + 4'd1;
	
				if(counter_beat == cpu_beat_count_temp - 4'd1) begin
					dma_memory_read_data_ready<=1'b0;//stop accepting read
					counter_beat <= 4'd0;
					dma_state<= START_WRITE;
				end
			end
		end

		START_WRITE: begin
			memory_request_valid <= 1'b1;
			memory_request <= WRITE;
			memory_start_address <= cpu_destination_start_address_temp;
			memory_beat_count <= cpu_beat_count_temp;
			memory_write_data <= memory[counter_beat];
			memory_write_data_valid<=1'b1;
			
			if(memory_ready) begin
				counter_beat <= 4'd0;
				memory_request_valid <= 1'b0;
				dma_state <= WAIT_MEMORY_WRITE;
			
			end

		end

	
		WAIT_MEMORY_WRITE: begin
			
			if(memory_dma_valid) begin
				counter_beat <= counter_beat + 4'd1;
								
				if(counter_beat < cpu_beat_count_temp - 4'd1) memory_write_data <= memory[counter_beat+4'd1];//change write data to memory as soon as it accepts the current write data
				else if(counter_beat == cpu_beat_count_temp - 4'd1) begin
					memory_write_data <= 32'd0;
					memory_write_data_valid<=1'b0;
					counter_beat <= 4'd0;
					dma_state<= FINISH;
				end
			end
		end

		FINISH: begin
			dma_state <= IDLE;
			counter_beat <= 4'd0;
			memory_request_valid<=1'b0;
			memory_request <= REQUEST_NOTHING;
			memory_start_address <= 10'd0;
			memory_beat_count <= 4'd0;
			memory_write_data <= DEFAULT_VALUE;
			memory_write_data_valid <=1'd0; 
			dma_cpu_command_ready <= 1'b1;
			dma_memory_read_data_ready<= 1'b0;

		end
		endcase

	end

end

endmodule