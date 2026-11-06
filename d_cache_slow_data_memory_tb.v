module d_cache_slow_data_memory_tb;

reg clock;
reg reset_n;

//from cpu
reg cpu_request_valid;
reg [1:0] cpu_request;
reg [31:0] cpu_write_data;
reg [31:0] cpu_address;

//from memory
wire [127:0] memory_data;
wire memory_data_valid;
wire memory_ready;

//to memory
wire memory_request_valid;
wire [1:0] memory_request;
wire [9:0] memory_address;
wire [127:0] memory_write_data;

//to cpu
wire [31:0] d_cache_data;
wire d_cache_stall;

wire [1:0] memory_debug_state;

integer errors;
integer test_number;
integer i;

//D_CACHE_state
localparam D_CACHE_WRITE_BACK_AFTER_RESET = 3'd0; //State to write back the dirty valid slot into memory
localparam D_CACHE_IDLE = 3'd1;//State for waiting to take load or store request from CPU
localparam D_CACHE_START = 3'd2;//State to indicate the start of a new request
localparam D_CACHE_WAIT_MEMORY_READ = 3'd3;//State to wait for memory to present the requested data
localparam D_CACHE_WAIT_MEMORY_WRITE = 3'd4;//State to wait for memory to complete the write
localparam D_CACHE_FINISH = 3'd5;//State to indicate the finish of a request

//request values for memory_request from D_CACHE
localparam REQUEST_NOTHING = 2'b00;
localparam READ = 2'b01;
localparam WRITE = 2'b10;

//cpu_request
localparam LOAD = 2'b01;
localparam STORE = 2'b10;


//request tag of D_CACHE
localparam DO_NOTHING = 3'd0;
localparam LOAD_INVALID = 3'd1;
localparam LOAD_VALID_MISS_CLEAN = 3'd2;
localparam LOAD_VALID_MISS_DIRTY = 3'd3;
localparam STORE_INVALID = 3'd4;
localparam STORE_VALID_MISS_CLEAN = 3'd5;
localparam STORE_VALID_MISS_DIRTY= 3'd6;
localparam WRITE_AFTER_RESET = 3'd7;

//memory state
localparam MEMORY_IDLE             = 2'b00;
localparam MEMORY_READ_PROCESSING  = 2'b01;
localparam MEMORY_WRITE_PROCESSING = 2'b10;
localparam MEMORY_FINISH           = 2'b11;


localparam MEMORY_PROCESSING_CYCLES = 3'd3;
localparam MEMORY_DEFAULT_VALUE = 128'd0;
localparam DEFAULT_CACHE_VALUE = 32'hFFFFFFFF;

d_cache d_cache_dut (
    .clock(clock),
    .reset_n(reset_n),
    .cpu_request_valid(cpu_request_valid),
    .cpu_request(cpu_request),
    .cpu_write_data(cpu_write_data),
    .cpu_address(cpu_address),
    .memory_data(memory_data),
    .memory_data_valid(memory_data_valid),
    .memory_ready(memory_ready),
    .memory_request_valid(memory_request_valid),
    .memory_request(memory_request),
    .memory_address(memory_address),
    .memory_write_data(memory_write_data),
    .d_cache_data(d_cache_data),
    .d_cache_stall(d_cache_stall)
);

slow_data_memory slow_data_memory_dut (
    .clock(clock),
    .reset_n(reset_n),
    .address(memory_address),
    .write_data(memory_write_data),
    .request_valid(memory_request_valid),
    .request(memory_request),
    .ready(memory_ready),
    .valid(memory_data_valid),
    .read_data(memory_data),
    .debug_state(memory_debug_state)
);	
	
`include "d_cache_tasks.vh"



initial begin
	clock = 1'b0;
	
	forever begin
	#5; clock = ~clock;
	end

end

initial begin
    #10000; // 10 us with `timescale 1ns/1ps
    $fatal(1, "TIMEOUT: Simulation did not finish");
end

initial begin

	reset_n = 1'b0;
	cpu_request_valid = 1'b0;
	cpu_request = REQUEST_NOTHING;
	cpu_write_data = DEFAULT_CACHE_VALUE;
	cpu_address = 32'd0;
	errors = 0;
	test_number = 0;
	
	#1;
	reset_n = 1'b1;
	check_still_after_reset(1'b1);
	
	for(i = 0; i < 4 ; i = i +1) begin
		@(posedge clock);
		#1;
		check_still_after_reset(1'b1);
	
	end

	@(posedge clock);
	#1;
	check_d_cache_state(D_CACHE_IDLE);
	check_memory_state(MEMORY_IDLE);
	check_still_after_reset(1'b0);
	
	
// request_and_check_d_cache_system(test_cpu_request_valid[1], test_cpu_request[2], test_cpu_write_data[32], test_cpu_address[32],  expected_writeback_address[10], test_memory_data[128] ,expected_memory_write_data[128],
//                   expected_d_cache_data[32], expected_d_cache_stall[1], expected_slot_data[128], expected_slot_valid[4], expected_slot_clean[4], expected_request_tag[3]);

	//Test order: LOAD_INVALID, LOAD_HIT, LOAD_VALID_MISS_CLEAN, STORE_HIT, LOAD_VALID_MISS_DIRTY, STORE_VALID_MISS_CLEAN , 	

	//Load data into invalid slots.
	//next_pc = {22'd0, tag, slot, data_index, 2'b00}
	request_and_check_d_cache_system(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd0,2'd0, 2'b00 } ,  10'd0, {32'd3, 32'd2,32'd1, 32'd0 }, {4{DEFAULT_CACHE_VALUE}},
	32'd0, 1'b1,  {32'd3, 32'd2,32'd1, 32'd0 }, 4'b0001, 4'b1111, LOAD_INVALID );

	request_and_check_d_cache_system(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd1,2'd1, 2'b00 }, 10'd0 ,{32'd7, 32'd6,32'd5, 32'd4 }, {4{DEFAULT_CACHE_VALUE}},
	32'd5, 1'b1,  {32'd7, 32'd6,32'd5, 32'd4 }, 4'b0011, 4'b1111, LOAD_INVALID   );

	request_and_check_d_cache_system(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd2,2'd2, 2'b00 }, 10'd0 ,{32'd11, 32'd10,32'd9, 32'd8 }, {4{DEFAULT_CACHE_VALUE}},
	32'd10, 1'b1,  {32'd11, 32'd10,32'd9, 32'd8 }, 4'b0111, 4'b1111, LOAD_INVALID   );

	request_and_check_d_cache_system(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd3,2'd3, 2'b00 }, 10'd0 ,{32'd15, 32'd14,32'd13, 32'd12 }, {4{DEFAULT_CACHE_VALUE}},
	32'd15, 1'b1,  {32'd15, 32'd14,32'd13, 32'd12 }, 4'b1111, 4'b1111, LOAD_INVALID   );

	
	
	//Tag hit. load data that is already in cache slots.
	request_and_check_d_cache_system(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd0,2'd1, 2'b00 }, 10'd0 ,{32'd3, 32'd2,32'd1, 32'd0 }, {4{DEFAULT_CACHE_VALUE}},
	32'd1, 1'b0,  {32'd3, 32'd2,32'd1, 32'd0 }, 4'b1111, 4'b1111, DO_NOTHING );

	request_and_check_d_cache_system(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd1,2'd2, 2'b00 }, 10'd0 ,{32'd7, 32'd6,32'd5, 32'd4 }, {4{DEFAULT_CACHE_VALUE}},
	32'd6, 1'b0,  {32'd7, 32'd6,32'd5, 32'd4 }, 4'b1111, 4'b1111, DO_NOTHING   );

	request_and_check_d_cache_system(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd2,2'd3, 2'b00 }, 10'd0 ,{32'd11, 32'd10,32'd9, 32'd8 }, {4{DEFAULT_CACHE_VALUE}},
	32'd11, 1'b0,  {32'd11, 32'd10,32'd9, 32'd8 }, 4'b1111, 4'b1111, DO_NOTHING   );

	request_and_check_d_cache_system(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd3,2'd0, 2'b00 }, 10'd0 ,{32'd15, 32'd14,32'd13, 32'd12 }, {4{DEFAULT_CACHE_VALUE}},
	32'd12, 1'b0,  {32'd15, 32'd14,32'd13, 32'd12 }, 4'b1111, 4'b1111, DO_NOTHING   );	

	
	
	//lOAD slots with different tags.
	request_and_check_d_cache_system(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd1,2'd0,2'd0, 2'b00 }, 10'd0 ,{32'd19, 32'd18,32'd17, 32'd16 }, {4{DEFAULT_CACHE_VALUE}},
	32'd16, 1'b1,  {32'd19, 32'd18,32'd17, 32'd16 }, 4'b1111, 4'b1111, LOAD_VALID_MISS_CLEAN );

	request_and_check_d_cache_system(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd1,2'd1,2'd1, 2'b00 }, 10'd0 ,{32'd23, 32'd22,32'd21, 32'd20 }, {4{DEFAULT_CACHE_VALUE}},
	32'd21, 1'b1,  {32'd23, 32'd22,32'd21, 32'd20 }, 4'b1111, 4'b1111, LOAD_VALID_MISS_CLEAN   );

	request_and_check_d_cache_system(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd1,2'd2,2'd2, 2'b00 }, 10'd0 ,{32'd27, 32'd26,32'd25, 32'd24 }, {4{DEFAULT_CACHE_VALUE}},
	32'd26, 1'b1,  {32'd27, 32'd26,32'd25, 32'd24 }, 4'b1111, 4'b1111, LOAD_VALID_MISS_CLEAN  );

	request_and_check_d_cache_system(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd1,2'd3,2'd3, 2'b00 }, 10'd0 ,{32'd31, 32'd30,32'd29, 32'd28 }, {4{DEFAULT_CACHE_VALUE}},
	32'd31, 1'b1,  {32'd31, 32'd30,32'd29, 32'd28 }, 4'b1111, 4'b1111, LOAD_VALID_MISS_CLEAN  );

	
	
	//Store hit now to make the slot dirty
	request_and_check_d_cache_system(1'b1, STORE, 32'd100, {22'd0,4'd1,2'd0,2'd0, 2'b00 }, 10'd0 ,{32'd19, 32'd18,32'd17, 32'd16 }, {4{DEFAULT_CACHE_VALUE}},
	32'd100, 1'b0,  {32'd19, 32'd18,32'd17, 32'd100 }, 4'b1111, 4'b1110, DO_NOTHING );

	request_and_check_d_cache_system(1'b1, STORE, 32'd101, {22'd0,4'd1,2'd1,2'd1, 2'b00 }, 10'd0 ,{32'd23, 32'd22,32'd21, 32'd20 }, {4{DEFAULT_CACHE_VALUE}},
	32'd101, 1'b0,  {32'd23, 32'd22,32'd101, 32'd20 }, 4'b1111, 4'b1100, DO_NOTHING   );

	request_and_check_d_cache_system(1'b1, STORE, 32'd102, {22'd0,4'd1,2'd2,2'd2, 2'b00 }, 10'd0 ,{32'd27, 32'd26,32'd25, 32'd24 }, {4{DEFAULT_CACHE_VALUE}},
	32'd102, 1'b0,  {32'd27, 32'd102 ,32'd25, 32'd24 }, 4'b1111, 4'b1000, DO_NOTHING  );

	request_and_check_d_cache_system(1'b1, STORE, 32'd103, {22'd0,4'd1,2'd3,2'd3, 2'b00 }, 10'd0 ,{32'd31, 32'd30,32'd29, 32'd28 }, {4{DEFAULT_CACHE_VALUE}},
	32'd103, 1'b0,  {32'd103, 32'd30,32'd29, 32'd28 }, 4'b1111, 4'b0000, DO_NOTHING  );

	
	//load now with different tag while the slots are dirty, have to writeback the old slots.
	request_and_check_d_cache_system(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd0,2'd0, 2'b00 }, {4'd1,2'd0,4'd0} ,{32'd3, 32'd2,32'd1, 32'd0 }, {32'd19, 32'd18,32'd17, 32'd100 },
	32'd0, 1'b1,  {32'd3, 32'd2,32'd1, 32'd0 }, 4'b1111, 4'b0001, LOAD_VALID_MISS_DIRTY );

	request_and_check_d_cache_system(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd1,2'd1, 2'b00 }, {4'd1,2'd1,4'd0} ,{32'd7, 32'd6,32'd5, 32'd4 }, {32'd23, 32'd22,32'd101, 32'd20 },
	32'd5, 1'b1,  {32'd7, 32'd6,32'd5, 32'd4 }, 4'b1111, 4'b011, LOAD_VALID_MISS_DIRTY   );

	request_and_check_d_cache_system(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd2,2'd2, 2'b00 }, {4'd1,2'd2,4'd0} ,{32'd11, 32'd10,32'd9, 32'd8 }, {32'd27, 32'd102 ,32'd25, 32'd24 },
	32'd10, 1'b1,  {32'd11, 32'd10,32'd9, 32'd8 }, 4'b1111, 4'b0111, LOAD_VALID_MISS_DIRTY   );

	request_and_check_d_cache_system(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd3,2'd3, 2'b00 }, {4'd1,2'd3,4'd0} ,{32'd15, 32'd14,32'd13, 32'd12 }, {32'd103, 32'd30,32'd29, 32'd28 },
	32'd15, 1'b1,  {32'd15, 32'd14,32'd13, 32'd12 }, 4'b1111, 4'b1111, LOAD_VALID_MISS_DIRTY   );

	
	//Store now with different tag while the slots are clean.
	request_and_check_d_cache_system(1'b1, STORE, 32'd110, {22'd0,4'd1,2'd0,2'd1, 2'b00 }, 10'd0 ,{32'd19, 32'd18,32'd17, 32'd100 }, {4{DEFAULT_CACHE_VALUE}},
	32'd110, 1'b1,  {32'd19, 32'd18,32'd110, 32'd100 }, 4'b1111, 4'b1110, STORE_VALID_MISS_CLEAN );

	request_and_check_d_cache_system(1'b1, STORE, 32'd120, {22'd0,4'd1,2'd1,2'd2, 2'b00 }, 10'd0 ,{32'd23, 32'd22,32'd101, 32'd20 }, {4{DEFAULT_CACHE_VALUE}},
	32'd120, 1'b1,  {32'd23, 32'd120,32'd101, 32'd20 }, 4'b1111, 4'b1100, STORE_VALID_MISS_CLEAN   );

	request_and_check_d_cache_system(1'b1, STORE, 32'd130, {22'd0,4'd1,2'd2,2'd3, 2'b00 }, 10'd0 ,{32'd27, 32'd102,32'd25, 32'd24 }, {4{DEFAULT_CACHE_VALUE}},
	32'd130, 1'b1,  {32'd130, 32'd102 ,32'd25, 32'd24 }, 4'b1111, 4'b1000, STORE_VALID_MISS_CLEAN  );

	request_and_check_d_cache_system(1'b1, STORE, 32'd140, {22'd0,4'd1,2'd3,2'd0, 2'b00 }, 10'd0 ,{32'd103, 32'd30,32'd29, 32'd28 }, {4{DEFAULT_CACHE_VALUE}},
	32'd140, 1'b1,  {32'd103, 32'd30,32'd29, 32'd140 }, 4'b1111, 4'b0000, STORE_VALID_MISS_CLEAN  );

	
	//store now with different tag while the slots are dirty, have to write back the old slots.
	request_and_check_d_cache_system(1'b1, STORE, 32'd200, {22'd0,4'd2,2'd0,2'd0, 2'b00 }, {4'd1,2'd0,4'd0} ,{32'd35, 32'd34,32'd33, 32'd32 }, {32'd19, 32'd18,32'd110, 32'd100 },
	32'd200, 1'b1,  {32'd35, 32'd34,32'd33, 32'd200 }, 4'b1111, 4'b0000, STORE_VALID_MISS_DIRTY );

	request_and_check_d_cache_system(1'b1, STORE, 32'd201, {22'd0,4'd2,2'd1,2'd1, 2'b00 }, {4'd1,2'd1,4'd0} ,{32'd39, 32'd38,32'd37, 32'd36 }, {32'd23, 32'd120,32'd101, 32'd20 },
	32'd201, 1'b1,  {32'd39, 32'd38,32'd201, 32'd36 }, 4'b1111, 4'b0000, STORE_VALID_MISS_DIRTY   );

	request_and_check_d_cache_system(1'b1, STORE, 32'd202, {22'd0,4'd2,2'd2,2'd2, 2'b00 }, {4'd1,2'd2,4'd0} ,{32'd43, 32'd42,32'd41, 32'd40 }, {32'd130, 32'd102 ,32'd25, 32'd24 },
	32'd202, 1'b1,  {32'd43, 32'd202,32'd41, 32'd40 }, 4'b1111, 4'b0000, STORE_VALID_MISS_DIRTY  );

	request_and_check_d_cache_system(1'b1, STORE, 32'd203, {22'd0,4'd2,2'd3,2'd3, 2'b00 }, {4'd1,2'd3,4'd0} ,{32'd47, 32'd46,32'd45, 32'd44 }, {32'd103, 32'd30,32'd29, 32'd140 },
	32'd203, 1'b1,  {32'd203, 32'd46,32'd45, 32'd44 }, 4'b1111, 4'b0000, STORE_VALID_MISS_DIRTY  );
		
		
	//reset now and check after reset operation.
	reset_n = 1'b0;
	cpu_request_valid = 1'b0;
	cpu_request = REQUEST_NOTHING;
	cpu_write_data = DEFAULT_CACHE_VALUE;
	cpu_address = 32'd0;

	
	#1;
	reset_n = 1'b1;
	
// check_writeback_reset_d_cache_system(expected_slot_valid[4], expected_slot_clean[4], expected_memory_write_address_slot_0[10], expected_memory_write_address_slot_1[10], expected_memory_write_address_slot_2[10], expected_memory_write_address_slot_3[10],
//                       expected_memory_write_data_slot_0[128], expected_memory_write_data_slot_1[128], expected_memory_write_data_slot_2[128], expected_memory_write_data_slot_3[128]);
	check_writeback_reset_d_cache_system(4'b1111,4'b0000, {4'd2,2'd0,4'b0000},{4'd2,2'd1,4'b0000},{4'd2,2'd2,4'b0000},{4'd2,2'd3,4'b0000},
			   {32'd35, 32'd34,32'd33, 32'd200 }, {32'd39, 32'd38,32'd201, 32'd36 }, {32'd43, 32'd202,32'd41, 32'd40 }, {32'd203, 32'd46,32'd45, 32'd44 } );
			
	//store invalid slots now.
	request_and_check_d_cache_system(1'b1, STORE, 32'd210, {22'd0,4'd2,2'd0,2'd1, 2'b00 }, 10'd0 ,{32'd35, 32'd34,32'd33, 32'd200 }, {4{DEFAULT_CACHE_VALUE}},
	32'd210, 1'b1,  {32'd35, 32'd34,32'd210, 32'd200 }, 4'b0001, 4'b1110, STORE_INVALID );

	request_and_check_d_cache_system(1'b1, STORE, 32'd211, {22'd0,4'd2,2'd1,2'd2, 2'b00 }, 10'd0 ,{32'd39, 32'd38,32'd201, 32'd36 }, {4{DEFAULT_CACHE_VALUE}},
	32'd211, 1'b1,  {32'd39, 32'd211,32'd201, 32'd36 }, 4'b0011, 4'b1100, STORE_INVALID   );

	request_and_check_d_cache_system(1'b1, STORE, 32'd212, {22'd0,4'd2,2'd2,2'd3, 2'b00 }, 10'd0 ,{32'd43, 32'd202,32'd41, 32'd40 }, {4{DEFAULT_CACHE_VALUE}},
	32'd212, 1'b1,  {32'd212, 32'd202,32'd41, 32'd40 }, 4'b0111, 4'b1000, STORE_INVALID );

	request_and_check_d_cache_system(1'b1, STORE, 32'd213, {22'd0,4'd2,2'd3,2'd0, 2'b00 }, 10'd0 ,{32'd203, 32'd46,32'd45, 32'd44 }, {4{DEFAULT_CACHE_VALUE}},
	32'd213, 1'b1,  {32'd203, 32'd46,32'd45, 32'd213}, 4'b1111, 4'b0000, STORE_INVALID  );
	
// request_and_check_d_cache_system(test_cpu_request_valid[1], test_cpu_request[2], test_cpu_write_data[32], test_cpu_address[32],  expected_writeback_address[10], test_memory_data[128] ,expected_memory_write_data[128],
//                   expected_d_cache_data[32], expected_d_cache_stall[1], expected_slot_data[128], expected_slot_valid[4], expected_slot_clean[4], expected_request_tag[3]);

	
	//cpu request = 0, cache should hold the last load/store data.
	request_and_check_d_cache_system(1'b0, REQUEST_NOTHING, DEFAULT_CACHE_VALUE, {22'd0,4'd2,2'd0,2'd1, 2'b00 }, 10'd0 ,{32'd35, 32'd34,32'd33, 32'd200 }, {4{DEFAULT_CACHE_VALUE}},
	32'd210, 1'b0,  {32'd35, 32'd34,32'd210, 32'd200 }, 4'b1111, 4'b0000, DO_NOTHING );

	request_and_check_d_cache_system(1'b0, REQUEST_NOTHING, DEFAULT_CACHE_VALUE, {22'd0,4'd2,2'd1,2'd2, 2'b00 }, 10'd0 ,{32'd39, 32'd38,32'd201, 32'd36 }, {4{DEFAULT_CACHE_VALUE}},
	32'd211, 1'b0,  {32'd39, 32'd211,32'd201, 32'd36 }, 4'b1111, 4'b0000, DO_NOTHING   );

	request_and_check_d_cache_system(1'b0, REQUEST_NOTHING, DEFAULT_CACHE_VALUE, {22'd0,4'd2,2'd2,2'd3, 2'b00 }, 10'd0 ,{32'd43, 32'd202,32'd41, 32'd40 }, {4{DEFAULT_CACHE_VALUE}},
	32'd212, 1'b0,  {32'd212, 32'd202,32'd41, 32'd40 }, 4'b1111, 4'b0000, DO_NOTHING );

	request_and_check_d_cache_system(1'b0, REQUEST_NOTHING, DEFAULT_CACHE_VALUE, {22'd0,4'd2,2'd3,2'd0, 2'b00 }, 10'd0 ,{32'd203, 32'd46,32'd45, 32'd44 }, {4{DEFAULT_CACHE_VALUE}},
	32'd213, 1'b0,  {32'd203, 32'd46,32'd45, 32'd213}, 4'b1111, 4'b0000, DO_NOTHING  );	

	//cpu request = 1 but REQUEST_NOTHING, cache should hold the last load/store data.
	request_and_check_d_cache_system(1'b1, REQUEST_NOTHING, DEFAULT_CACHE_VALUE, {22'd0,4'd2,2'd0,2'd1, 2'b00 }, 10'd0 ,{32'd35, 32'd34,32'd33, 32'd200 }, {4{DEFAULT_CACHE_VALUE}},
	32'd210, 1'b0,  {32'd35, 32'd34,32'd210, 32'd200 }, 4'b1111, 4'b0000, DO_NOTHING );

	request_and_check_d_cache_system(1'b1, REQUEST_NOTHING, DEFAULT_CACHE_VALUE, {22'd0,4'd2,2'd1,2'd2, 2'b00 }, 10'd0 ,{32'd39, 32'd38,32'd201, 32'd36 }, {4{DEFAULT_CACHE_VALUE}},
	32'd211, 1'b0,  {32'd39, 32'd211,32'd201, 32'd36 }, 4'b1111, 4'b0000, DO_NOTHING   );

	request_and_check_d_cache_system(1'b1, REQUEST_NOTHING, DEFAULT_CACHE_VALUE, {22'd0,4'd2,2'd2,2'd3, 2'b00 }, 10'd0 ,{32'd43, 32'd202,32'd41, 32'd40 }, {4{DEFAULT_CACHE_VALUE}},
	32'd212, 1'b0,  {32'd212, 32'd202,32'd41, 32'd40 }, 4'b1111, 4'b0000, DO_NOTHING );

	request_and_check_d_cache_system(1'b1, REQUEST_NOTHING, DEFAULT_CACHE_VALUE, {22'd0,4'd2,2'd3,2'd0, 2'b00 }, 10'd0 ,{32'd203, 32'd46,32'd45, 32'd44 }, {4{DEFAULT_CACHE_VALUE}},
	32'd213, 1'b0,  {32'd203, 32'd46,32'd45, 32'd213}, 4'b1111, 4'b0000, DO_NOTHING  );
	

	if (errors == 0)
        $display("ALL D_cache_SYSTEM TESTS PASSED");
   else
        $display("%0d D_cache_SYSTEM TESTS FAILED", errors);

   $finish;	

end
endmodule