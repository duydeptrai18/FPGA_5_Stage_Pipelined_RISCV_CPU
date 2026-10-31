/*
- This data memory module has 256 spaces where each space holds a 32-bit value.
- In reset, it will pulse up the 'ready' flag so that it can start working right after reset, and pulse down the 'valid' flag indicating the 'read_data' is not valid yet.
- After reset, it will go to IDLE state and stay there until a request comes and the module itself is ready.
- When the request comes, the address of the memory and the write data will be stored into temporary spots.
- The module will mimic the processing time of an external memory by taking PROCESSING_CYCLES cycles following the edge when a request is accepted (when request_valid = ready = 1).
- If a read is requested, at the next cycle after the processing is finished, when going from state READ_PROCESSING to FINISH, it will output the 'read_data' and pulse up the 'valid' flag and hold the flag for 1 cycle.
- If a write is requested, at the next cycle after the processing is finished, when going from state WRITE_PROCESSING to FINISH, it will pulse up the 'valid' flag and hold the flag for 1 cycle.
- At the next cycle, when going back from state FINISH to IDLE, the 'valid' flag is pulsed down, the 'read_data' is still held and the 'ready' flag is pulsed up indicating it's ready to take new request.
- When a 32-bit value of an address is requested, the block that contains that location will be sent back.
- The sent back data is a 128-bit value that is composed of 4 32-bit values.
*/
module slow_data_memory(
	input clock,
	input reset_n,
	input [9:0] address,
	input [127:0] write_data,
	input request_valid,
	input [1:0] request,

	output reg ready,
	output reg valid,
	output reg [127:0] read_data
);
//state
localparam IDLE             = 2'b00;
localparam READ_PROCESSING  = 2'b01;
localparam WRITE_PROCESSING = 2'b10;
localparam FINISH           = 2'b11;

//request
localparam READ = 2'b01;
localparam WRITE = 2'b10;

localparam PROCESSING_CYCLES = 3'd5;

//use these temp so input can change
reg [9:0] temp_address;
reg [127:0] temp_write_data;

reg [2:0] counter;
reg [1:0] state;
reg [31:0] memory [0:255]; // 2^8-1;

always @(posedge clock or negedge reset_n) begin
	if(!reset_n) begin
		counter<=3'd0;
		state<=IDLE;
		ready <= 1'b1;
		valid <= 1'b0;
		read_data <= 128'd0;		
		temp_address <=10'd0;
		temp_write_data <=128'd0;

	end
	
	else begin
		case(state) 
		
		IDLE: begin
			counter<=3'd0;
			if(request_valid && ready) begin // when a request comes
				temp_address<=address;
				if(request == READ) begin //read
					state<=READ_PROCESSING;
					ready<=1'b0;				
				
				
				end
	
				else if(request == WRITE) begin //write
					temp_write_data<=write_data;
					state<=WRITE_PROCESSING;
					ready<=1'b0;
				end
			
			end
		
		end
		
		READ_PROCESSING: begin
			counter<=counter+3'b1;
			
			if(counter == PROCESSING_CYCLES-3'd1) begin //when the reading process is finished, read_data is present and valid is pulsed up.
				state<=FINISH;
				//temp_address[1:0] indicates the byte location of the 32-bit value, therefore it doesn't matter.
				//temp_address[3:2] indicates the 32-bit value location in a slot that contains 4 32-bit values.
				//Because the block that contains that value will be sent back. Therefore, 2'b00 - 2'b11 are used instead of temp_address[3:2] to cover every 32-bit value in that block.

				read_data[31:0] <= memory[{temp_address[9:4], 2'b00}];
				read_data[63:32] <= memory[{temp_address[9:4], 2'b01}]; 
				read_data[95:64] <= memory[{temp_address[9:4], 2'b10}];
				read_data[127:96] <= memory[{temp_address[9:4], 2'b11}];		
				valid <= 1'b1;
			end
		end
		
		WRITE_PROCESSING: begin
			counter<= counter +3'b1;
			
			if(counter == PROCESSING_CYCLES-3'd1) begin // when the writing process is finished, valid is pulsed up.
				state<=FINISH;
				memory[{temp_address[9:4], 2'b00}] <= temp_write_data[31:0];
				memory[{temp_address[9:4], 2'b01}] <= temp_write_data[63:32];
				memory[{temp_address[9:4], 2'b10}] <= temp_write_data[95:64];
				memory[{temp_address[9:4], 2'b11}] <= temp_write_data[127:96];		
				valid <= 1'b1;
			end
		end		
		
		FINISH: begin

			// go back to state IDLE and ready to take on new request.
			counter<=3'd0;
			valid <= 1'b0;
			ready <= 1'b1;
			state <= IDLE;
		end
				
		endcase
	end
end
endmodule. dont say anything , saved in this chat, DONT SAY AYNTHING OK