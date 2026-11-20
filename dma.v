module dma(
    input clock,
    input reset_n,

    // From CPU
    input cpu_request_valid,
    input [9:0] cpu_source_start_address,
    input [9:0] cpu_destination_start_address,
    input [3:0] cpu_beat_count, // CPU must request at least one beat

    // From memory
    input [31:0] memory_dma_read_data,
    input memory_dma_ready,
    input memory_dma_valid,
    input memory_dma_write_ready,

    // To memory
    output reg dma_memory_request_valid,
    output reg [1:0] dma_memory_request,
    output reg [9:0] dma_memory_start_address,
    output reg [3:0] dma_memory_beat_count,
    output reg [31:0] dma_memory_write_data,
    output reg dma_memory_write_data_valid,
    output reg dma_memory_write_ready, // Ready to accept write completion

    // To CPU and memory
    output reg dma_cpu_command_ready,
    output reg dma_memory_read_data_ready
);

reg [3:0] counter_beat;
reg [31:0] memory [0:15]; // DMA buffer

reg [9:0] cpu_source_start_address_temp;
reg [9:0] cpu_destination_start_address_temp;
reg [3:0] cpu_beat_count_temp;

localparam REQUEST_NOTHING = 2'b00;
localparam READ            = 2'b01;
localparam WRITE           = 2'b10;

reg [2:0] dma_state;
localparam IDLE              = 3'd0;
localparam START_READ        = 3'd1;
localparam WAIT_MEMORY_READ  = 3'd2;
localparam START_WRITE       = 3'd3;
localparam WAIT_MEMORY_WRITE = 3'd4;
localparam FINISH            = 3'd5;

localparam DEFAULT_VALUE = 32'hFFFFFFFF;



always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        dma_state<= IDLE;
        cpu_source_start_address_temp<= 10'd0;
        cpu_destination_start_address_temp<= 10'd0;
        cpu_beat_count_temp<= 4'd0;
        counter_beat<= 4'd0;
        dma_memory_request_valid<= 1'b0;
        dma_memory_request<= REQUEST_NOTHING;
        dma_memory_start_address<= 10'd0;
        dma_memory_beat_count<= 4'd0;
        dma_memory_write_data<= DEFAULT_VALUE;
        dma_memory_write_data_valid<= 1'b0;
        dma_cpu_command_ready<= 1'b1;
        dma_memory_read_data_ready<= 1'b0;
        dma_memory_write_ready<= 1'b0;
    end 
	 else begin
        case (dma_state)
            IDLE: begin
                if (cpu_request_valid) begin
                    cpu_source_start_address_temp<= cpu_source_start_address;
                    cpu_destination_start_address_temp<= cpu_destination_start_address;
                    cpu_beat_count_temp<= cpu_beat_count;
                    dma_memory_request_valid<= 1'b1;
                    dma_memory_request<= READ;
                    dma_memory_start_address<= cpu_source_start_address;
                    dma_memory_beat_count<= cpu_beat_count;
                    dma_cpu_command_ready<= 1'b0;
                    dma_state<= START_READ;
                end
            end

            START_READ: begin
                if (dma_memory_request_valid && memory_dma_ready) begin
                    counter_beat<= 4'd0;
                    dma_memory_request_valid<= 1'b0;
                    dma_memory_read_data_ready<= 1'b1;
                    dma_state<= WAIT_MEMORY_READ;
                end
            end

            WAIT_MEMORY_READ: begin
                if (dma_memory_read_data_ready && memory_dma_valid) begin
                    memory[counter_beat]<= memory_dma_read_data;
                    counter_beat<= counter_beat + 4'd1;

                    if (counter_beat == cpu_beat_count_temp - 4'd1) begin
                        dma_memory_read_data_ready<= 1'b0;
                        counter_beat<= 4'd0;
                        dma_state<= START_WRITE;
                    end
                end
            end

            START_WRITE: begin
                dma_memory_request_valid<= 1'b1;
                dma_memory_request<= WRITE;
                dma_memory_start_address<= cpu_destination_start_address_temp;
                dma_memory_beat_count<= cpu_beat_count_temp;
                dma_memory_write_data<= memory[counter_beat];
                dma_memory_write_data_valid<= 1'b0;//only applicable for beat 1 and up

                if (dma_memory_request_valid && memory_dma_ready) begin
                    counter_beat<= 4'd0;
                    dma_memory_request_valid<= 1'b0;
                    dma_state<= WAIT_MEMORY_WRITE;
                    dma_memory_write_ready<= 1'b1;
                end
            end

            WAIT_MEMORY_WRITE: begin
                if (dma_memory_write_data_valid && memory_dma_write_ready) begin
                    dma_memory_write_data_valid<= 1'b0;
                end 
					 
					 else if (memory_dma_valid && dma_memory_write_ready) begin
                    counter_beat<= counter_beat + 4'd1;

                    if (counter_beat < cpu_beat_count_temp - 4'd1) begin
                        dma_memory_write_data<= memory[counter_beat + 4'd1];
                        dma_memory_write_data_valid<= 1'b1;
                    end 
						  else if (counter_beat == cpu_beat_count_temp - 4'd1) begin
                        dma_memory_write_ready<= 1'b0;
                        dma_memory_write_data<= 32'd0;
                        dma_memory_write_data_valid<= 1'b0;
								cpu_destination_start_address_temp<= 10'd0;
                        counter_beat<= 4'd0;
                        dma_state<= FINISH;
                    end
                end
            end

            FINISH: begin
				  dma_state<= IDLE;
				  cpu_source_start_address_temp<= 10'd0;
				  cpu_destination_start_address_temp<= 10'd0;
				  cpu_beat_count_temp<= 4'd0;
				  counter_beat<= 4'd0;
				  dma_memory_request_valid<= 1'b0;
				  dma_memory_request<= REQUEST_NOTHING;
				  dma_memory_start_address<= 10'd0;
				  dma_memory_beat_count<= 4'd0;
				  dma_memory_write_data<= DEFAULT_VALUE;
				  dma_memory_write_data_valid<= 1'b0;
				  dma_cpu_command_ready<= 1'b1;
				  dma_memory_read_data_ready<= 1'b0;
				  dma_memory_write_ready<= 1'b0;
            end
        endcase
    end
end

endmodule