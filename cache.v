module cache(
	input clock,
	input reset_n,
	input request, //request = 00 nothing, 01:load, 10: store
	input [31:0] write_data,
	input [31:0] cpu_address,
	input memory_ready, 

	output request_valid, //request flag for memory
	output request, //request = 0 means read, 1 means write
	output [31:0] memory_address,
	output [127:0] cache_data,
	output reg cache_stall
);
//4 cache slots, each slot has 4 spaces, each space stores 32-bit value.

reg [31:0] temp_write_data;
reg [31:0] temp_cpu_address;

reg cache_data_valid; 
reg [31:0] memory [0:3][0:3];
reg [3:0] slot_valid; //slot_valid[0] belongs to slot 0.
reg [3:0] slot_clean; //slot_clean[0] belongs to slot 0.
reg [11:0] slot_tag [0:3]; //slot_tag[0] belongs to slot 0. 
wire tag = address[17:6];
wire slot_index = address[5:4];
wire data_index = address[3:2];
wire hit = valid_slot[slot_index] && (tag == slot_tag[slot_index]);
wire bit_clean = slot_clean[slot_index];


assign cache_data = hit ? memory[slot_index][data_index] : 32'd0;

wire load_request = (request==2'b01);
wire store_request = (request==2'b10);

wire load_hit = load_request && hit;
wire store_hit = store_request && hit;
wire load_miss = load_request && !hit;
wire store_miss = store_request && !hit;

wire load_miss_clean  = load_miss && slot_clean[slot_index];
wire load_miss_dirty  = load_miss && !slot_clean[slot_index];
wire store_miss_clean = store_miss && slot_clean[slot_index];
wire store_miss_dirty = store_miss && !slot_clean[slot_index];
-----------------------------------
always @(*) begin
	if(!reset_n) cache_stall = 1'b0;

	else if(cache_data_valid) cache_stall = 1'b0;

	else if(load_hit) cache_stall = 1'b0;	

	else if (store_hit) begin
		modify the slot that contains the data
		cache_stall = 1'b0;
		bit_dirty_thatslot = 1;

	end

	else if (load_miss) cache_stall = 1'b1;


	else if (store_miss) cache_stall = 1'b1;
	
end



always @(posedge clock or reset) begin
	if(!reset_n) begin 
		state <= IDLING;
		slot_valid <= 4'b0000;
		slot_clean <= 4'b0000;
		slot_tag[0] <= 26'd0;
		slot_tag[1] <= 26'd0;
		slot_tag[2] <= 26'd0;
		slot_tag[3] <= 26'd0;
		cache_data_valid <= 1'b0;
	end

	else begin
		case(state):
		IDLING: begin
		
		if(!cache_stall && memory_ready) begin
			if(load_request || store_request) begin
				temp_write_data<=write_data;
				temp_cpu_address<=cpu_address;
				state<=START;
			end
		
		end
		
		if(load_request && memory_ready) begin
			if(load_hit) begin
				//do nothing
			end
			
			else if (load_miss) begin //load miss
			request_valid <= 1'b1;
			state<=START;
			address<=request_address;	
				if(bit_clean) begin
					request <= 1'b0;// 0 is read, 1 is write
				end
				else if(!bit_clean) begin
					request <= 1'b1;// 0 is read, 1 is write					
					write_data <= cache_old_data;
				end
			
			end			

		end


		else if(store_request && memory_ready) begin
			if(store_hit) begin
				//only modify cache location
			end

			else if(store_miss) begin
			request_valid <= 1'b1;
			state<=START;
			address<=request_address;	
				if(bit_clean) begin
					request <= 1'b0;// 0 is read, 1 is write
				end
				else if(!bit_clean) begin
					request <= 1'b1;// 0 is read, 1 is write					
					write_data <= cache_old_data;
				end
			end		
		end

		end


		START: begin
			request_valid <= 1'b0;	
			if(request == 1'b0) state<= WAIT_MEMORY_READ;
			else if(request == 1'b1) state<=WAIT_MEMORY_WRITE;


		end



		WAIT_MEMORY_READ: begin
			

			if(memory_data_valid) begin
				if(store_miss_clean) begin
					cache_slot <= memory_data;
					cache_slot_clean <= 1'b0;
					state <= finish;
					cache_data_valid <= 1'b1;
				end

				else if (store_miss_dirty) begin
					cache_slot <= memory_data;
					cache_slot_clean <= 1'b0;
					state <= finish;
					cache_data_valid <= 1'b1;					
				end

				else if (load_miss_clean) begin
					cache_slot <= memory_data;
					cache_slot_clean <= 1'b1;
					state <= finish;
					cache_data_valid <= 1'b1;
				end

				else if (load_miss_dirty) begin
					cache_slot <= memory_data;
					cache_slot_clean <= 1'b1;
					state <= finish;
					cache_data_valid <= 1'b1;
				end
			

			end


		end

		WAIT_MEMORY_WRITE: begin

			if(memory_ready) begin
				if(load_miss_dirty) begin
					state <= START;
					request_valid <= 1'b0;
				end

				else if (store_miss_dirty) begin
					state <= START;
					request<= 1'b0;
				end
			

			end

		end
		
		FINISH: begin
		state<= IDLING;
		cache_data_valid <= 1'b0;
		


		end

	end	


end