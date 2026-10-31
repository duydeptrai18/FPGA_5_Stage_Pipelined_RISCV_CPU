
module d_cache(
	input clock,
	input reset_n,

	//from cpu
	input cpu_request_valid,//pulse from cpu that request to store or load data
	input [1:0] cpu_request, //request = 00 nothing, 01:load, 10: store
	input [31:0] cpu_write_data,
	input [31:0] cpu_address,// address of the loaded or stored data
	
	//from memory
	input [127:0] memory_data, 
	//The sent back data is a 128-bit value that is composed of 4 32-bit values in the block that contains the requested data location. For example, if memory[1] is requested, the block that contains memory[0] to memory[3] will be sent back.
	
	input memory_ready,// flag indicating that the memory is ready to take new request

	//to memory
	output memory_request_valid, //request flag for memory, pulse up when cache requests memory.
	output reg [1:0] memory_request, //request = 2'b00 means request_nothing, request = 2'b01 means read, request = 2'b10 means write
	output [9:0] memory_address, 
	output [127:0] memory_write_data,

	//to cpu
	output [31:0] cache_data, //requested loaded data
	output reg cache_stall //stall flag for the cpu to stall while the cache is retrieving the data, this will stay on as long as the data is not available yet.
);
//4 cache slots, each slot has 4 spaces, each space stores 32-bit value.
reg [31:0] memory [0:3][0:3]; // memory[slot_index][data_index];
reg [3:0] slot_valid; //slot_valid[0] belongs to slot 0. 
//A valid slot indicates that the values in the slot are valid. A invalid slot indicates that the slots just come out of reset, and the values aren't valid.

reg [3:0] slot_clean; //slot_clean[0] belongs to slot 0.
//A clean slot indicates that the memory and cache contain the same data in the same address.
//A not clean slot (dirty slot) indicates that the cache contains the newer data in the same address compared with the memory. //Therefore, the slot will be written back later.

reg [3:0] slot_tag [0:3]; //slot_tag[0] belongs to slot 0.
//Contains the tag or address of each slot.

reg still_after_reset; //=1 indicates that the cache is still writing back dirty and valid slots to memory after reset.
reg [2:0] write_back_index; //Represents the current slot that is being written back to memory after reset.
reg cache_data_valid; //Internal valid flag that indicates the request is finished, this will be used to unstall the cache in the //always combination block that controls the stall logic.

//state
reg [2:0] state;
localparam WRITE_BACK_AFTER_RESET = 3'd0; //State to write back the dirty valid slot into memory
localparam IDLE = 3'd1;//State for waiting to take load or store request from CPU
localparam START = 3'd2;//State to indicate the start of a new request
localparam WAIT_MEMORY_READ = 3'd3;//State to wait for memory to present the requested data
localparam WAIT_MEMORY_WRITE = 3'd4;//State to wait for memory to complete the write
localparam FINISH = 3'd5;//State to indicate the finish of a request

//request values for memory_request
localparam REQUEST_NOTHING = 2'b00;
localparam READ = 2'b01;
localparam WRITE = 2'b10;

//Because cpu_address is byte_addressed, cpu_address[1:0] is ignored because they represent the byte location in a 32-bit value.
wire [3:0] tag = cpu_address[9:6]; //tag or address for each slot
wire [1:0] slot_index = cpu_address[5:4]; //the slot that will contain the needed data
wire [1:0] data_index = cpu_address[3:2]; //the location of a 32-bit value in a slot
wire hit_tag = (tag == slot_tag[slot_index]); 
wire bit_valid = slot_valid[slot_index];//The valid bit of the requested slot
wire bit_clean = slot_clean[slot_index];//The clean bit of the requested slot

localparam DEFAULT_CACHE_VALUE = 32'hFFFFFFFF;
assign cache_data = bit_valid ? memory[slot_index][data_index] : DEFAULT_CACHE_VALUE;

localparam LOAD = 2'b01;
localparam STORE = 2'b10;
wire load_request = (cpu_request==LOAD);
wire store_request = (cpu_request==STORE);

reg [2:0] request_tag; //the tag for store or load scenarios.
localparam DO_NOTHING = 3'd0;
localparam LOAD_INVALID = 3'd1;
localparam LOAD_VALID_!MATCH_CLEAN = 3'd1;
localparam LOAD_VALID_!MATCH_!CLEAN = 3'd2;
localparam STORE_INVALID = 3'd3;
localparam STORE_VALID_!MATCH_CLEAN = 3'd4;
localparam STORE_VALID_!MATCH_!CLEAN = 3'd5;


-----------------------------------
//The always combinational logic that determines when to stall the cpu.
// In reset, the cpu is not stalled.
//After reset, the cpu is stalled to wait for the cache to write back dirty valid slot to memory.
//cache_data_valid = 1, indicates that the cpu_request is finished and cpu can continue operating.
//If the slot is invalid, stall is required to retrieve the data.
//If the slot is valid and the tag doesn't match, stall is required to retrieve the data, and write back if applicable.
always @(*) begin
	cache_stall = 1'b0;

	if(!reset_n) cache_stall = 1'b0;
	
	else if(still_after_reset) cache_stall = 1'b1;

	else if(cache_data_valid) cache_stall = 1'b0;

	else if(!slot_valid[slot_index]) cache_stall = 1'b1;

	else if(!hit_tag) cache_stall = 1'b1;
	
end


always @(posedge clock or negedge reset_n) begin
	if(!reset_n) begin 
		state <= WRITE_BACK_AFTER_RESET; // go in this state after reset to write back.
		cache_data_valid <= 1'b0;
		still_after_reset <= 1'b1;// go in this state after reset to write back.
		write_back_index<=3'b00;
		request_tag<= DO_NOTHING;
		
	end

	else begin
		case(state):
		
		WRITE_BACK_AFTER_RESET: begin
		write_back_index<= write_back_index + 3'b1;//go to the next slot

		//Reset each slot's variables after reset:
		slot_valid[write_back_index] <= 1'b0;
		slot_tag[write_back_index] <= 1'b0;
		slot_clean[write_back_index] <= 1'b0;
		//--

		//no request to memory for invalid slot or clean valid slot.
		state<=WRITE_BACK_AFTER_RESET;
		memory_request_valid <= 1'b0;
		memory_request <= REQUEST_NOTHING;
		memory_address <= 10'd0; 
		memory_write_data[31:0] <= DEFAULT_CACHE_VALUE;
		memory_write_data[63:32] <= DEFAULT_CACHE_VALUE;
		memory_write_data[95:64] <= DEFAULT_CACHE_VALUE;
		memory_write_data[127:96] <= DEFAULT_CACHE_VALUE;
		
		if(write_back_index == 3'd4) begin//if it has gone through all 4 slots.
			state<= IDLING;
			still_after_reset<=1'b0;
		end

		//write_back_index indicates the current slot location
		else if(slot_valid[write_back_index] && !slot_clean[write_back_index]) begin //if slot is valid and slot is dirty, we write back.
			memory_request_valid <= 1'b1;
			memory_request <= WRITE;
			memory_address <= {slot_tag[write_back_index], write_back_index,4'b0000}; //{tag, slot_index, 4'b0000} = 10-bit value, 
			memory_write_data[31:0] <= memory[write_back_index][0];
			memory_write_data[63:32] <= memory[write_back_index][1];
			memory_write_data[95:64] <= memory[write_back_index][2];
			memory_write_data[127:96] <= memory[write_back_index][3];
			state<= START; 
		
		end		
	
		end
			

		IDLE: begin

		//while waiting for new request
		memory_request_valid <= 1'b0;
		memory_request <= REQUEST_NOTHING;
		memory_address <= 10'd0;
		memory_write_data[31:0] <= DEFAULT_CACHE_VALUE;
		memory_write_data[63:32] <= DEFAULT_CACHE_VALUE;
		memory_write_data[95:64] <= DEFAULT_CACHE_VALUE;
		memory_write_data[127:96] <= DEFAULT_CACHE_VALUE;
		request_tag<= DO_NOTHING;

		if(cpu_request_valid && load_request && memory_ready) begin //when a load_request comes
			if(!bit_valid) begin //if the slot is invalid, we read from memory the new data, and mark the slot valid.
				//Read from memory
				state<= START;
				request_tag<= LOAD_INVALID;
				memory_request_valid <= 1'b1;
				memory_request <= READ;
				memory_address <= cpu_address[9:0]; 
			end

			else if(bit_valid) begin//if the slot is valid
				if(hit_tag) begin
					//data is already in cache, do nothing

				end

				else if(!hit_tag) begin //if the tag misses
					state<= START;
					if(bit_clean) begin //if the slot is clean, just need to read from memory the new data.
						
						request_tag<= LOAD_VALID_!MATCH_CLEAN;
						memory_request_valid <= 1'b1;
						memory_request <= READ;
						memory_address <= cpu_address[9:0];
					end

					else if(!bit_clean) begin //if the slot is dirty, write back to memory the old data, then read from memory the new data.
						request_tag <= LOAD_VALID_!MATCH_!CLEAN;
						memory_request_valid <= 1'b1;
						memory_request <= WRITE;
						memory_address <= cpu_address[9:0]; 
						memory_write_data[31:0] <= memory[slot_index][0];
						memory_write_data[63:32] <= memory[slot_index][1];
						memory_write_data[95:64] <= memory[slot_index][2];
						memory_write_data[127:96] <= memory[slot_index][3];
					end
				end

			end		
		end


		else if(cpu_request_valid && store_request && memory_ready) begin //when a store_request comes
			if(!bit_valid) begin //if the slot is invalid, read from memory the new data, then modify the store location, then mark dirty = 1, valid = 1.
				
				state <= START;
				request_tag <= STORE_INVALID;
				memory_request_valid <= 1'b1;
				memory_request <= READ;
				memory_address <= cpu_address[9:0];				
				
			end

			else if(bit_valid) begin//if slot is valid
				if(hit_tag) begin //if the tag hits, modify the store location, then mark the slot dirty.
					
					memory[slot_index][data_index] <= cpu_write_data;
					slot_clean[slot_index] <= 1'b0;

				end

				else if(!hit_tag) begin //if the tag misses
					state<= START;
					if(bit_clean) begin //if the slot is clean, read from memory the new data, then modify store location, then mark dirty = 1.
						
						request_tag <= STORE_VALID_!MATCH_CLEAN;
						memory_request_valid <= 1'b1;
						memory_request <= READ;
						memory_address <= cpu_address[9:0];						
					end

					else if(!bit_clean) begin //if the slot is dirty, write back to memory the old data, then read from memory the new data, then modify store location, then mark dirty = 1.

						request_tag <= STORE_VALID_!MATCH_!CLEAN;
						memory_request_valid <= 1'b1;
						memory_request <= WRITE;
						memory_address <= cpu_address[9:0];
						memory_write_data[31:0] <= memory[slot_index][0];
						memory_write_data[63:32] <= memory[slot_index][1];
						memory_write_data[95:64] <= memory[slot_index][2];
						memory_write_data[127:96] <= memory[slot_index][3];
		
					end
				end
			end			
		end
		end

		START: begin
			request_valid <= 1'b0;	
			if(memory_request == READ) state<= WAIT_MEMORY_READ;
			else if(memory_request == WRITE) state<=WAIT_MEMORY_WRITE;
			else state<= IDLING;


		end



		WAIT_MEMORY_READ: begin
			

			if(memory_data_valid) begin //when the memory presents the new data
		
				//store it into cache and mark valid = 1, then go to state FINISH.
				memory[slot_index][0] <= memory_data[31:0];
				memory[slot_index][1] <= memory_data[63:32];
				memory[slot_index][2] <= memory_data[95:64];
				memory[slot_index][3] <= memory_data[127:96];
				slot_valid[slot_index] <= 1'b1;
				state <= FINISH;
				cache_data_valid <= 1'b1;
				
//if the request is the load scenarios showed below, keep the slot clean.				
if(request_tag == LOAD_INVALID or request_tag == LOAD_VALID_!MATCH_CLEAN or request_tag == LOAD_VALID_!MATCH_!CLEAN) begin

					slot_clean[slot_index] <= 1'b1;

				end

//if the request is the store scenarios showed below, make the slot dirty.				
else if (request_tag == STORE_INVALID or request_tag == STORE_VALID_!MATCH_CLEAN or request_tag == STORE_VALID_!MATCH_!CLEAN) begin

					memory[slot_index][data_index] <= cpu_write_data;//This will modify the store location when the old data from memory comes back
					slot_clean[slot_index] <= 1'b0;
					
				end
			end
		end

		WAIT_MEMORY_WRITE: begin

			if(memory_ready) begin //when memory finishes writing

				//if the request_tag are the ones below, go back to state START and finishes the process with READ.
				if(request_tag == LOAD_VALID_!MATCH_!CLEAN or request_tag == STORE_VALID_!MATCH_!CLEAN) begin
					state <= START;
					memory_request_valid <= 1'b1;
					memory_request <= READ;
				end		

				//if it's still in the writing back process after reset.
				else if (still_after_reset) begin
					state<= WRITE_BACK_AFTER_RESET;			
				end
	
			end
		end
		
		FINISH: begin

		//reset back and go back to IDLE state
		state<= IDLE;
		cache_data_valid <= 1'b0;
		memory_request_valid <= 1'b0;
		memory_request <= REQUEST_NOTHING;
		memory_address <= 10'd0; //{tag, slot_index, 4'b00}
		memory_write_data[31:0] <= DEFAULT_CACHE_VALUE;
		memory_write_data[63:32] <= DEFAULT_CACHE_VALUE;
		memory_write_data[95:64] <= DEFAULT_CACHE_VALUE;
		memory_write_data[127:96] <= DEFAULT_CACHE_VALUE;
		request_tag<= DO_NOTHING;
		

		end

	end	

end
endmodule