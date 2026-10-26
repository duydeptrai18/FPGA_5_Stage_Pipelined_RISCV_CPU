/*
This module takes 5 cycles to process (+1 edge when request_valid = ready = 1) and pulse a valid flag when done,
then the next following edge, it brings the valid flag down and bring the ready flag up indicating it's ready to take new request.
*/
module slow_memory(
	input clock,
	input reset_n,
	input [31:0] address,
	input [127:0] write_data,
	input request_valid,
	input request,

	output reg ready,
	output reg valid,
	output reg [127:0] read_data
);
//localparam state
localparam IDLE             = 2'b00;
localparam READ_PROCESSING  = 2'b01;
localparam WRITE_PROCESSING = 2'b10;
localparam FINISH           = 2'b11;

localparam PROCESSING_CYCLES = 3'd5;

//use these temp so input can change
reg [31:0] temp_address;
reg [127:0] temp_write_data;

reg [2:0] counter;
reg [1:0] state;
reg [31:0] memory [0:65535]; // 2^16-1;

always @(posedge clock or negedge reset_n) begin
	if(!reset_n) begin
		counter<=3'd0;
		state<=IDLE;
		ready <= 1'b1;
		valid <= 1'b0;
		read_data <= 128'd0;		
		temp_address <=32'd0;
		temp_write_data <=128'd0;

	end
	
	else begin
		case(state) 
		
		IDLE: begin
			counter<=3'd0;
			if(request_valid && ready) begin
				temp_address<=address;
				if(!request) begin //read
					state<=READ_PROCESSING;
					ready<=1'b0;				
				
				
				end
	
				else if(request) begin
					temp_write_data<=write_data;
					state<=WRITE_PROCESSING;
					ready<=1'b0;
				end
			
			end
		
		end
		
		READ_PROCESSING: begin
			counter<=counter+3'b1;
			
			if(counter == PROCESSING_CYCLES-3'd1) begin
				state<=FINISH;
				read_data[31:0] <= memory[{temp_address[17:4], 2'b00}];
				read_data[63:32] <= memory[{temp_address[17:4], 2'b01}]; 
				read_data[95:64] <= memory[{temp_address[17:4], 2'b10}];
				read_data[127:96] <= memory[{temp_address[17:4], 2'b11}];		
				valid <= 1'b1;
			end
		end
		
		WRITE_PROCESSING: begin
			counter<= counter +3'b1;
			
			if(counter == PROCESSING_CYCLES-3'd1) begin
				state<=FINISH;
				memory[{temp_address[17:4], 2'b00}] <= temp_write_data[31:0];
				memory[{temp_address[17:4], 2'b01}] <= temp_write_data[63:32];
				memory[{temp_address[17:4], 2'b10}] <= temp_write_data[95:64];
				memory[{temp_address[17:4], 2'b11}] <= temp_write_data[127:96];		
				valid <= 1'b1;
			end
		end		
		
		FINISH: begin
			counter<=3'd0;
			valid <= 1'b0;
			ready <= 1'b1;
			state <= IDLE;
		end
				
		endcase
	end

	
end
endmodule