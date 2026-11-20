module slow_dma_data_memory(
    input clock,
    input reset_n,

    // From DMA
    input dma_memory_request_valid,
    input [1:0] dma_memory_request,
    input [9:0] dma_memory_start_address,
    input [3:0] dma_memory_beat_count,
    input [31:0] dma_memory_write_data,
    input dma_memory_write_data_valid,
    input dma_memory_read_data_ready,
    input dma_memory_write_ready,

    // To DMA
    output reg memory_dma_ready,
    output reg memory_dma_valid,
    output reg memory_dma_write_ready,
    output reg [31:0] memory_dma_read_data
);

localparam IDLE             = 2'b00;
localparam READ_PROCESSING  = 2'b01;
localparam WRITE_PROCESSING = 2'b10;
localparam FINISH           = 2'b11;

localparam REQUEST_NOTHING = 2'b00;
localparam READ = 2'b01;
localparam WRITE = 2'b10;

localparam MEMORY_PROCESSING_CYCLES = 3'd3;

reg [9:0] temp_address;
reg [31:0] temp_write_data;

reg [3:0] memory_counter_beat;
reg [2:0] counter;
reg [1:0] memory_state;

reg [31:0] memory [0:255];

initial begin
	$readmemh("slow_data_memory_test.mem",memory);

end

always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        memory_counter_beat<= 4'd0;
        counter<= 3'd0;
        memory_state<= IDLE;
        memory_dma_ready<= 1'b1;
        memory_dma_valid<= 1'b0;
        memory_dma_write_ready<= 1'b0;
        memory_dma_read_data<= 32'd0;
        temp_address<= 10'd0;
        temp_write_data<= 32'd0;
    end 
	 
	 else begin
        case (memory_state)
            IDLE: begin
                if (dma_memory_request_valid) begin
                    temp_address<= dma_memory_start_address;

                    if (dma_memory_request == READ) begin
                        memory_state<= READ_PROCESSING;
                        memory_dma_ready<= 1'b0;
                    end 
						  
						  else if (dma_memory_request == WRITE) begin
                        temp_write_data<= dma_memory_write_data;
                        memory_state<= WRITE_PROCESSING;
                        memory_dma_ready<= 1'b0;
                    end
                end
            end

            READ_PROCESSING: begin
                if (counter < MEMORY_PROCESSING_CYCLES - 3'd1)
                    counter<= counter + 3'd1;

                if (memory_dma_valid && dma_memory_read_data_ready) begin
                    counter<= 3'd0;
                    memory_dma_valid<= 1'b0;

                    if (memory_counter_beat == dma_memory_beat_count - 4'd1) begin
                        temp_address<= 10'd0;
                        memory_counter_beat<= 4'd0;
                        memory_state<= FINISH;
                    end 
						  
						  else if (memory_counter_beat < dma_memory_beat_count - 4'd1) begin
                        temp_address<= temp_address + 10'd4;
                        memory_counter_beat<= memory_counter_beat + 4'd1;
                        memory_state<= READ_PROCESSING;
                    end
                end 
					 
					 else if (counter == MEMORY_PROCESSING_CYCLES - 3'd1) begin
                    counter<= MEMORY_PROCESSING_CYCLES;
                    memory_dma_read_data<= memory[temp_address[9:2]];
                    memory_dma_valid<= 1'b1;
                end
            end

            WRITE_PROCESSING: begin
                if (counter < MEMORY_PROCESSING_CYCLES - 3'd1)
                    counter<= counter + 3'd1;

                if (dma_memory_write_data_valid && memory_dma_write_ready) begin
                    counter<= 3'd0;
                    memory_dma_write_ready<= 1'b0;
                    memory_dma_valid<= 1'b0;

                    if (memory_counter_beat == dma_memory_beat_count - 4'd1) begin
                        temp_write_data<= 32'd0;
                        temp_address<= 10'd0;
                        memory_counter_beat<= 4'd0;
                        memory_state<= FINISH;
                    end 
						  
						  else if (memory_counter_beat < dma_memory_beat_count - 4'd1) begin
                        temp_write_data<= dma_memory_write_data;
                        temp_address<= temp_address + 10'd4;
                        memory_counter_beat<= memory_counter_beat + 4'd1;
                        memory_state<= WRITE_PROCESSING;
                    end
                end 
					 
					 else if (memory_dma_valid && dma_memory_write_ready) begin
                    memory_dma_valid<= 1'b0;
                    memory_dma_write_ready<= 1'b1;
                end 
					 
					 else if (counter == MEMORY_PROCESSING_CYCLES - 3'd1) begin
                    counter<= MEMORY_PROCESSING_CYCLES;
                    memory[temp_address[9:2]]<= temp_write_data;
                    memory_dma_valid<= 1'b1;
                end
            end

            FINISH: begin
                memory_counter_beat<= 4'd0;
                counter<= 3'd0;
                memory_state<= IDLE;
                memory_dma_ready<= 1'b1;
                memory_dma_valid<= 1'b0;
                memory_dma_read_data<= 32'd0;
					 memory_dma_write_ready<=1'b0;
                temp_address<= 10'd0;
                temp_write_data<= 32'd0;
            end
        endcase
    end
end

endmodule