module cache(
	input clock,
	input reset_n,

	//from cpu
	input [1:0] cpu_request, //request = 00 nothing, 01:load, 10: store
	input [31:0] cpu_write_data,
	input [31:0] cpu_address,
	
	//from memory
	input [127:0] memory_data,
	input memory_ready,

	//to memory
	output memory_request_valid, //request flag for memory
	output [1:0] memory_request, //request = 2'b00 means idling, request = 2'b01 means read, request = 2'b10 means write
	output [17:0] memory_address,
	output [127:0] memory_write_data,

	//to cpu
	output [31:0] cache_data,
	output reg cache_stall
);
//4 cache slots, each slot has 4 spaces, each space stores 32-bit value.
reg still_after_reset;
reg [1:0] write_back_index;
reg cache_data_valid; 

//state
reg [2:0] state;
localparam WRITE_BACK_AFTER_RESET = 3'd0;
localparam IDLING = 3'd1;
localparam START = 3'd2;
localparam WAIT_MEMORY_READ = 3'd3;
localparam WAIT_MEMORY_WRITE = 3'd4;
localparam FINISH = 3'd5;


//request
localparam REQUEST_NOTHING = 2'b00;
localparam READ = 2'b01;
localparam WRITE = 2'b10;

reg [31:0] memory [0:3][0:3]; // memory[slot_index][data_index];
reg [3:0] slot_valid; //slot_valid[0] belongs to slot 0.
reg [3:0] slot_clean; //slot_clean[0] belongs to slot 0.
reg [11:0] slot_tag [0:3]; //slot_tag[0] belongs to slot 0.
 
wire tag = cpu_address[17:6];
wire slot_index = cpu_address[5:4];
wire data_index = cpu_address[3:2];
wire hit_tag = (tag == slot_tag[slot_index]);
wire hit = 
wire bit_valid = slot_valid[slot_index];
wire bit_clean = slot_clean[slot_index];

assign cache_data = hit ? memory[slot_index][data_index] : 32'd0;

wire load_request = (cpu_request==2'b01);
wire store_request = (cpu_request==2'b10);

wire load_hit = load_request && hit;
wire store_hit = store_request && hit;
wire load_miss = load_request && !hit;
wire store_miss = store_request && !hit;

wire load_miss_clean  = load_miss && bit_clean;
wire load_miss_dirty  = load_miss && !bit_clean;
wire store_miss_clean = store_miss && bit_clean;
wire store_miss_dirty = store_miss && !bit_clean;

reg [2:0] request_tag;
localparam DO_NOTHING = 3'd0;
localparam LOAD_INVALID = 3'd1;
localparam LOAD_VALID_!MATCH_CLEAN = 3'd1;
localparam LOAD_VALID_!MATCH_!CLEAN = 3'd2;
localparam STORE_INVALID = 3'd3;
localparam STORE_VALID_!MATCH_CLEAN = 3'd4;
localparam STORE_VALID_!MATCH_!CLEAN = 3'd5;

localparam DEFAULT_CACHE_VALUE = 32'hFFFFFFFF;

-----------------------------------
always @(*) begin
	cache_stall = 1'b0;

	if(!reset_n) cache_stall = 1'b0;
	
	else if(still_after_reset) cache_stall = 1'b1;

	else if(cache_data_valid) cache_stall = 1'b0;

	else if(load_hit) cache_stall = 1'b0;	

	else if (store_hit) cache_stall = 1'b0;
	
	else if (load_miss) cache_stall = 1'b1;

	else if (store_miss) cache_stall = 1'b1;	
end


always @(posedge clock or negedge reset_n) begin
	if(!reset_n) begin 
		state <= WRITE_BACK_AFTER_RESET;
		still_after_reset <= 1'b1;
		write_back_index<=2'b00;
		//slot_valid <= 4'b0000;
		//slot_clean <= 4'b0000;
		slot_tag[0] <= 12'd0;
		slot_tag[1] <= 12'd0;
		slot_tag[2] <= 12'd0;
		slot_tag[3] <= 12'd0;
		cache_data_valid <= 1'b0;
		request_tag<= 3'd0;
		
	end

	else begin
		case(state):
		
		WRITE_BACK_AFTER_RESET: begin
		write_back_index<= write_back_index + 2'b1;
		slot_valid[write_back_index] <= 1'b0;
		state<=WRITE_BACK_AFTER_RESET;
		memory_request_valid <= 1'b0;
		memory_request <= REQUEST_NOTHING;
		memory_address <= 18'd0; //{tag, slot_index, 4'b00}
		memory_write_data[31:0] <= DEFAULT_CACHE_VALUE;
		memory_write_data[63:32] <= DEFAULT_CACHE_VALUE;
		memory_write_data[95:64] <= DEFAULT_CACHE_VALUE;
		memory_write_data[127:96] <= DEFAULT_CACHE_VALUE;		

		if(slot_valid[write_back_index] && !slot_clean[write_back_index]) begin //if slot is valid and slot is dirty, we write back
			memory_request_valid <= 1'b1;
			memory_request <= WRITE;
			memory_address <= {tag, write_back_index,4'b0000}; //{tag, slot_index, 4'b00} = 18-bit value
			memory_write_data[31:0] <= memory[write_back_index][0];
			memory_write_data[63:32] <= memory[write_back_index][1];
			memory_write_data[95:64] <= memory[write_back_index][2];
			memory_write_data[127:96] <= memory[write_back_index][3];
			state<= START; 
		
		end		
		
		else begin
			state<= IDLING;
			still_after_reset<=1'b0;
		end
		
		
		end
			

		IDLING: begin

		if(load_request && memory_ready) begin
			if(!bit_valid) begin 
				//Read from memory
				state<= START;
				request_tag<= LOAD_INVALID;
				memory_request_valid <= 1'b1;
				memory_request <= READ;
				memory_address <= cpu_address; 
			end

			else begin//if slot is valid
				if(hit_tag) begin
					//data is already in cache, do nothing

				end

				else begin
					state<= START;
					if(bit_clean) begin
						//Read from memory
						request_tag<= LOAD_VALID_!MATCH_CLEAN;
						memory_request_valid <= 1'b1;
						memory_request <= READ;
						memory_address <= cpu_address;
					end

					else begin
						//write back to memory, then read from memory
						request_tag <= LOAD_VALID_!MATCH_!CLEAN;
						memory_request_valid <= 1'b1;
						memory_request <= WRITE;
						memory_address <= cpu_address; 
						memory_write_data[31:0] <= memory[slot_index][0];
						memory_write_data[63:32] <= memory[slot_index][1];
						memory_write_data[95:64] <= memory[slot_index][2];
						memory_write_data[127:96] <= memory[slot_index][3];
					end
				end

			end		
		end


		else if(store_request && memory_ready) begin
			if(!bit_valid) begin 
				//read from memory, then modify store location, then mark dirty = 1, valid = 1.
				state <= START;
				request_tag <= STORE_INVALID;
				memory_request_valid <= 1'b1;
				memory_request <= READ;
				memory_address <= cpu_address;				
				
			end

			else begin//if slot is valid
				if(hit_tag) begin
					//data is already in cache
					memory[slot_index][data_index] <= cpu_write_data;
					slot_clean[slot_index] <= 1'b0;

				end

				else begin
					if(bit_clean) begin
						//read from memory, then modify store location, then mark dirty = 1.
						state <= START;
						request_tag <= STORE_VALID_!MATCH_CLEAN;
						memory_request_valid <= 1'b1;
						memory_request <= READ;
						memory_address <= cpu_address;						
					end

					else begin
						//write back to memory, then read from memory, then modify store location, then mark dirty = 1.
						request_tag <= STORE_VALID_!MATCH_!CLEAN;
						memory_request_valid <= 1'b1;
						memory_request <= WRITE;
						memory_address <= cpu_address;
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
			if(request == READ) state<= WAIT_MEMORY_READ;
			else if(request == WRITE) state<=WAIT_MEMORY_WRITE;
			else state<= IDLING;


		end



		WAIT_MEMORY_READ: begin
			

			if(memory_data_valid) begin
				memory[slot_index][0] <= memory_data[31:0];
				memory[slot_index][1] <= memory_data[63:32];
				memory[slot_index][2] <= memory_data[95:64];
				memory[slot_index][3] <= memory_data[127:96];
				slot_valid[slot_index] <= 1'b1;
				state <= FINISH;
				cache_data_valid <= 1'b1;
				
if(request_tag == LOAD_INVALID or request_tag == LOAD_VALID_!MATCH_CLEAN or request_tag == LOAD_VALID_!MATCH_!CLEAN) begin

					slot_clean[slot_index] <= 1'b1;

				end

				
else if (request_tag == STORE_INVALID or request_tag == STORE_VALID_!MATCH_CLEAN or request_tag == STORE_VALID_!MATCH_!CLEAN) begin

					memory[slot_index][data_index] <= cpu_write_data;//This will modify the store location when the old data from memory comes back
					slot_clean[slot_index] <= 1'b0;
					
				end
			end
		end

		WAIT_MEMORY_WRITE: begin

			if(memory_ready) begin
				if(request_tag == LOAD_VALID_!MATCH_!CLEAN or request_tag == STORE_VALID_!MATCH_!CLEAN) begin
					state <= START;
					memory_request_valid <= 1'b1;
					memory_request <= READ;
				end		
				else if (still_after_reset) begin
					state<= WRITE_BACK_AFTER_RESET;			
				end
	
			end
		end
		
		FINISH: begin
		state<= IDLING;
		cache_data_valid <= 1'b0;

		end

	end	


end
endmodule./ saved