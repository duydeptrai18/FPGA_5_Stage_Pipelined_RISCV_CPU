/*
- This I_Cache module consists of 4 slots where each slot can hold 4 32-bit instructions.
- After reset, it will hold all the instructions but it will mark all slots as invalid slots,
meaning that the slots are marked equally as empty, they need to be loaded in first before getting used.
- After initialization, I_cache will request instructions for the specified slot whenever a tag is missed.
- It will not automatically fill all the slots after initialization, for example by not filling instruction[0] to instruction [15] across 4 slots.

Process:
- When a slot is invalid (empty) or when the tag doesn't match in a valid slot (tag missed), the cache will send pulsed up 'memory_request_valid' flag and 'memory_next_pc' to the 'slow_instruction_memory' to retrieve the needed instruction, and the cache will enter state START then state WAIT_MEMORY_READ.
- When a 32-bit instruction of an address is requested, the block that contains that location will be sent back.
- The sent back data is a 128-bit value that is composed of 4 32-bit instructions in that block.
- After the memory presents the valid instruction by pulsing up 'memory_data_valid', the 4 instructions will be stored into the cache at that edge.
- Following the edge, at the next cycle, in state FINISH, 'i_cache_stall' = 0, and the cpu will start operating normally with the retrieved instructions.
- At the next cycle, i_cache will go back to state IDLE and ready to take on new request.

Stall logic:
- Stall is needed right away in the same cycle if an instruction is missed.
- Stall is not needed in reset and when an instruction is hit.

*/

module i_cache (
	input clock,
	input reset_n,
	
	//from cpu
	input [31:0] cpu_next_pc, //requested next_pc from cpu

	//from memory
	input [127:0] memory_data, //4 instructions sent from memory
	input memory_ready,//flag that shows memory is ready
	input memory_data_valid, // flag that shows the data is valid
	
	//to memory
	output reg memory_request_valid, //request flag for memory
	output reg memory_request,// =0 is request_nothing, =1 is read
	output reg [9:0] memory_next_pc,

	//to cpu
	output [31:0] next_instruction,//returned next_instruction to cpu
	output reg i_cache_stall //stall flag for the cpu to stall while the cache is retrieving the data, this will stay on as long as the data is not available yet.

);
//4 cache slots, each slot has 4 spaces, each space stores 32-bit value.
reg [31:0] memory [0:3][0:3];
reg [3:0] slot_valid; //slot_valid[0] belongs to slot 0.
//A valid slot indicates that the values in the slot are valid. A invalid slot indicates that the slots just come out of reset, and the values aren't valid.

reg [3:0] slot_tag [0:3]; //slot_tag[0] belongs to slot 0.
//Contains the tag or address of each slot.

reg cache_data_valid;//Internal valid flag that indicates the request is finished, this will be used to unstall the cache in the //always combination block that controls the stall logic.

wire [3:0] tag = next_pc[9:6];
wire [1:0] slot_index = next_pc[5:4];
wire [1:0] data_index = next_pc[3:2];
wire hit_tag = (tag == slot_tag[slot_index]); 
wire bit_valid = slot_valid[slot_index];

//memory_request
localparam REQUEST_NOTHING = 1'b0;
localparam READ = 1'b1;

//state
reg [1:0] state;
localparam IDLE = 2'd0;//State for waiting to take load or store request from CPU
localparam START = 2'd1;//State to indicate the start of a new request
localparam WAIT_MEMORY_READ = 2'd2;//State to wait for memory to present the requested data
localparam FINISH = 2'd3;//State to indicate the finish of a request

localparam DEFAULT_CACHE_VALUE = 32'hFFFFFFFF;
assign next_instruction = bit_valid ? memory[slot_index][data_index] : DEFAULT_CACHE_VALUE;

//The always combinational logic that determines when to stall the cpu.
// In reset, the cpu is not stalled.
//cache_data_valid = 1, indicates that the cpu_request is finished and cpu can continue operating.
//If the slot is invalid, stall is required to retrieve the data.
//If the slot is valid and the tag doesn't match, stall is required to retrieve the data.
always @(*) begin
	i_cache_stall = 1'b0;

	if(!reset_n) i_cache_stall = 1'b0;

	else if(cache_data_valid) i_cache_stall = 1'b0;

	else if(!slot_valid[slot_index]) i_cache_stall = 1'b1;

	else if(!hit_tag) i_cache_stall = 1'b1;
	
end

always @(posedge clock or negedge reset_n) begin
	if(!reset_n) begin 
		state <= IDLING;
		cache_data_valid <= 1'b0;
		slot_valid <= 4'b0000;
		
	end

	else begin
		case(state): 

		IDLE: begin
			//when slot is valid and tag hits, do nothing
			
			if(memory_ready) begin 

				if(!bit_valid) begin//if slot is invalid, read from memory the requested instruction.
				
				state<= START;
				memory_request_valid <= 1'b1;
				memory_request <= READ;
				memory_next_pc <= cpu_next_pc[9:0]; 
				end

				else if(bit_valid) begin //if slot is valid
				if(!hit_tag) begin //if tag is missed, read from memory the requested instruction.
				state<= START;
				memory_request_valid <= 1'b1;
				memory_request <= READ;
				memory_next_pc  <= cpu_next_pc[9:0]; 
				end
				end

			end

		end

		START: begin
			request_valid <= 1'b0;	
			if(memory_request == READ) state<= WAIT_MEMORY_READ;
			else state <= IDLING;

		end
		
		WAIT_MEMORY_READ: begin
			if(memory_data_valid) begin // when the memory presents the data

				//store into cache and make slot valid.
				memory[slot_index][0] <= memory_data[31:0];
				memory[slot_index][1] <= memory_data[63:32];
				memory[slot_index][2] <= memory_data[95:64];
				memory[slot_index][3] <= memory_data[127:96];
				slot_valid[slot_index] <= 1'b1;
				state <= FINISH;
				cache_data_valid <= 1'b1;
			end
		end

		FINISH: begin

		//reset back and go back to IDLE state	
		state<= IDLE;
		cache_data_valid <= 1'b0;
		memory_request_valid <= 1'b0;
		memory_request <= REQUEST_NOTHING;

		end

		default: begin
			state<= IDLE;
		end
		endcase
	end

end