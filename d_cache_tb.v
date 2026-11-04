module d_cache_tb;

reg clock;
reg reset_n;

reg cpu_request_valid;
reg [1:0] cpu_request;
reg [31:0] cpu_write_data;
reg [31:0] cpu_address;

reg [127:0] memory_data;
reg memory_data_valid;
reg memory_ready;

wire memory_request_valid;
wire [1:0] memory_request;
wire [9:0] memory_address;
wire [127:0] memory_write_data;

wire [31:0] d_cache_data;
wire d_cache_stall;

integer errors;
integer test_number;
integer i;


//state
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

//cpu_request
localparam LOAD = 2'b01;
localparam STORE = 2'b10;

localparam DEFAULT_CACHE_VALUE = 32'hFFFFFFFF;
localparam MEMORY_PROCESSING_CYCLES = 3'd3;

//request tag
localparam DO_NOTHING = 3'd0;
localparam LOAD_INVALID = 3'd1;
localparam LOAD_VALID_MISS_CLEAN = 3'd2;
localparam LOAD_VALID_MISS_DIRTY = 3'd3;
localparam STORE_INVALID = 3'd4;
localparam STORE_VALID_MISS_CLEAN = 3'd5;
localparam STORE_VALID_MISS_DIRTY= 3'd6;
localparam WRITE_AFTER_RESET = 3'd7;

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

task check_memory_request_valid;
    input expected_memory_request_valid;
    begin
        if (memory_request_valid !== expected_memory_request_valid) begin
            errors = errors + 1;
            $display("FAIL memory_request_valid=%b expected=%b",
                     memory_request_valid, expected_memory_request_valid);
        end
        else
            $display("PASS memory_request_valid=%b", memory_request_valid);
    end
endtask

task check_memory_request;
    input [1:0] expected_memory_request;
    begin
        if (memory_request !== expected_memory_request) begin
            errors = errors + 1;
            $display("FAIL memory_request=%b expected=%b",
                     memory_request, expected_memory_request);
        end
        else
            $display("PASS memory_request=%b", memory_request);
    end
endtask

task check_memory_address;
    input [9:0] expected_memory_address;
    begin
        if (memory_address !== expected_memory_address) begin
            errors = errors + 1;
            $display("FAIL memory_address=%h expected=%h",
                     memory_address, expected_memory_address);
        end
        else
            $display("PASS memory_address=%h", memory_address);
    end
endtask

task check_memory_write_data;
    input [127:0] expected_memory_write_data;
    begin
        if (memory_write_data !== expected_memory_write_data) begin
            errors = errors + 1;
            $display("FAIL memory_write_data=%h expected=%h",
                     memory_write_data, expected_memory_write_data);
        end
        else
            $display("PASS memory_write_data=%h", memory_write_data);
    end
endtask

task check_d_cache_data;
    input [31:0] expected_d_cache_data;
    begin
        if (d_cache_data !== expected_d_cache_data) begin
            errors = errors + 1;
            $display("FAIL d_cache_data=%h expected=%h",
                     d_cache_data, expected_d_cache_data);
        end
        else
            $display("PASS d_cache_data=%h", d_cache_data);
    end
endtask

task check_d_cache_stall;
    input expected_d_cache_stall;
    begin
        if (d_cache_stall !== expected_d_cache_stall) begin
            errors = errors + 1;
            $display("FAIL d_cache_stall=%b expected=%b",
                     d_cache_stall, expected_d_cache_stall);
        end
        else
            $display("PASS d_cache_stall=%b", d_cache_stall);
    end
endtask

task check_slot_data;
    input [1:0] slot_index;
    input [127:0] expected_slot_data;

    reg [127:0] actual_slot_data;
    begin
        actual_slot_data = {
            d_cache_dut.memory[slot_index][3],
            d_cache_dut.memory[slot_index][2],
            d_cache_dut.memory[slot_index][1],
            d_cache_dut.memory[slot_index][0]
        };

        if (actual_slot_data !== expected_slot_data) begin
            errors = errors + 1;
            $display("FAIL slot=%0d data=%h expected=%h",
                     slot_index, actual_slot_data, expected_slot_data);
        end
        else
            $display("PASS slot=%0d data=%h",
                     slot_index, actual_slot_data);
    end
endtask

task check_slot_valid;
    input [3:0] expected_slot_valid;
    begin
        if (d_cache_dut.slot_valid !== expected_slot_valid) begin
            errors = errors + 1;
            $display("FAIL slot_valid=%b expected=%b",
                     d_cache_dut.slot_valid, expected_slot_valid);
        end
        else
            $display("PASS slot_valid=%b", d_cache_dut.slot_valid);
    end
endtask

task check_slot_clean;
    input [3:0] expected_slot_clean;
    begin
        if (d_cache_dut.slot_clean !== expected_slot_clean) begin
            errors = errors + 1;
            $display("FAIL slot_clean=%b expected=%b",
                     d_cache_dut.slot_clean, expected_slot_clean);
        end
        else
            $display("PASS slot_clean=%b", d_cache_dut.slot_clean);
    end
endtask

task check_request_tag;
    input [2:0] expected_request_tag;
    begin
        if (d_cache_dut.request_tag !== expected_request_tag) begin
            errors = errors + 1;
            $display("FAIL request_tag=%b expected=%b",
                     d_cache_dut.request_tag, expected_request_tag);
        end
        else
            $display("PASS request_tag=%b", d_cache_dut.request_tag);
    end
endtask

task check_state;
    input [2:0] expected_state;
    begin
        if (d_cache_dut.state !== expected_state) begin
            errors = errors + 1;
            $display("FAIL state=%b expected=%b",
                     d_cache_dut.state, expected_state);
        end
        else
            $display("PASS state=%b", d_cache_dut.state);
    end
endtask

task check_still_after_reset;
    input expected_still_after_reset;
    begin
        if (d_cache_dut.still_after_reset !== expected_still_after_reset) begin
            errors = errors + 1;
            $display("FAIL still_after_reset=%b expected=%b",
                     d_cache_dut.still_after_reset, expected_still_after_reset);
        end
        else
            $display("PASS still_after_reset=%b", d_cache_dut.still_after_reset);
    end
endtask

task check_cache_data_valid;
    input expected_cache_data_valid;
    begin
        if (d_cache_dut.cache_data_valid !== expected_cache_data_valid) begin
            errors = errors + 1;
            $display("FAIL cache_data_valid=%b expected=%b",
                     d_cache_dut.cache_data_valid, expected_cache_data_valid);
        end
        else
            $display("PASS cache_data_valid=%b", d_cache_dut.cache_data_valid);
    end
endtask

task check_slot_tag;
    input [1:0] slot_index;
    input [3:0] expected_slot_tag;

    begin
        if (d_cache_dut.slot_tag[slot_index] !== expected_slot_tag) begin
            errors = errors + 1;
            $display("FAIL slot=%0d tag=%b expected=%b",
                     slot_index, d_cache_dut.slot_tag[slot_index],
                     expected_slot_tag);
        end
        else
            $display("PASS slot=%0d tag=%b",
                     slot_index, d_cache_dut.slot_tag[slot_index]);
    end
endtask

task check_expected_slot_data;
    input [1:0] slot_index;
    input [127:0] expected_slot_data;

    reg [127:0] actual_slot_data;
    begin
        actual_slot_data = {
            d_cache_dut.memory[slot_index][3],
            d_cache_dut.memory[slot_index][2],
            d_cache_dut.memory[slot_index][1],
            d_cache_dut.memory[slot_index][0]
        };

        if (actual_slot_data !== expected_slot_data) begin
            errors = errors + 1;
            $display("FAIL slot=%0d data=%h expected=%h",
                     slot_index, actual_slot_data, expected_slot_data);
        end
        else
            $display("PASS slot=%0d data=%h",
                     slot_index, actual_slot_data);
    end
endtask

task check_expected_slot_valid;
    input [3:0] expected_slot_valid;
    begin
        if (d_cache_dut.slot_valid !== expected_slot_valid) begin
            errors = errors + 1;
            $display("FAIL slot_valid=%b expected=%b",
                     d_cache_dut.slot_valid, expected_slot_valid);
        end
        else
            $display("PASS slot_valid=%b", d_cache_dut.slot_valid);
    end
endtask

task check_expected_slot_clean;
    input [3:0] expected_slot_clean;
    begin
        if (d_cache_dut.slot_clean !== expected_slot_clean) begin
            errors = errors + 1;
            $display("FAIL slot_clean=%b expected=%b",
                     d_cache_dut.slot_clean, expected_slot_clean);
        end
        else
            $display("PASS slot_clean=%b", d_cache_dut.slot_clean);
    end
endtask

task check_expected_d_cache_data;
    input [31:0] expected_d_cache_data;

    begin
        if (d_cache_data !== expected_d_cache_data) begin
            errors = errors + 1;
            $display("FAIL d_cache_data=%h expected=%h",
                     d_cache_data, expected_d_cache_data);
        end
        else
            $display("PASS d_cache_data=%h", d_cache_data);
    end
endtask

task check_write_back_index;
    input [2:0] expected_write_back_index;

    begin
        if (d_cache_dut.write_back_index !== expected_write_back_index) begin
            errors = errors + 1;
            $display("FAIL write_back_index=%0d expected=%0d",
                     d_cache_dut.write_back_index, expected_write_back_index);
        end
        else
            $display("PASS write_back_index=%0d",
                     d_cache_dut.write_back_index);
    end
endtask

task writeback_and_check;
	input [9:0] expected_writeback_address;
	input [127:0] 	expected_memory_write_data;
	input expected_d_cache_stall;
	input [2:0] expected_request_tag;


	integer i;
	begin
			if(expected_request_tag == LOAD_VALID_MISS_DIRTY) begin
			$display("i_cache In START cycle, when expected_request_tag == LOAD_VALID_MISS_DIRTY");
			check_request_tag(LOAD_VALID_MISS_DIRTY);
			end
			else if(expected_request_tag == STORE_VALID_MISS_DIRTY) begin
			$display("i_cache In START cycle, when expected_request_tag == LOAD_VALID_MISS_DIRTY");
			check_request_tag(STORE_VALID_MISS_DIRTY);
			end
			else if(expected_request_tag == WRITE_AFTER_RESET) begin
			$display("i_cache In START cycle, when expected_request_tag == WRITE_AFTER_RESET");
			check_request_tag(WRITE_AFTER_RESET);	
			check_still_after_reset(1'b1);		
			end


			check_state(START);
			check_memory_request_valid(1'b1);
			check_memory_request(WRITE);
			check_memory_address(expected_writeback_address);
			check_memory_write_data(expected_memory_write_data);
			check_d_cache_stall(expected_d_cache_stall);	

			$display("i_cache In first WAIT_MEMORY_WRITE cycle, when expected_request_tag == LOAD_VALID_MISS_DIRTY or expected_request_tag == STORE_VALID_MISS_DIRTY");
			
			for (i = 0; i < MEMORY_PROCESSING_CYCLES; i = i + 1) begin
				@(posedge clock);
				#1;
				if(expected_request_tag == WRITE_AFTER_RESET) check_still_after_reset(1'b1);
				memory_ready = 1'b0;
				$display("i_cache In WAIT_MEMORY_WRITE state, when expected_request_tag == LOAD_VALID_MISS_DIRTY or expected_request_tag == STORE_VALID_MISS_DIRTY");
				check_state(WAIT_MEMORY_WRITE);
				check_memory_request_valid(1'b0);
				check_memory_request(WRITE);
				check_memory_address(expected_writeback_address);
				check_memory_write_data(expected_memory_write_data);
				check_d_cache_stall(expected_d_cache_stall);
			end

			@(posedge clock);
			#1;	
			$display("Memory done writing data this cycle in its FINISH state");
			memory_data_valid = 1'b1;
			memory_ready = 1'b0;
			@(posedge clock);
			#1;
			memory_data_valid = 1'b0;
			memory_ready = 1'b1;
			$display("i_cache in first cycle of START state or getting back to WRITE_AFTER_RESET STATE, after just finished writing, when expected_request_tag == LOAD_VALID_MISS_DIRTY or expected_request_tag == STORE_VALID_MISS_DIRTY");

	end


endtask


task request_and_check;

	//from cpu
	input test_cpu_request_valid;//pulse from cpu that request to store or load data
	input [1:0] test_cpu_request; //request = 00 nothing, 01:load, 10: store
	input [31:0] test_cpu_write_data;
	input [31:0] test_cpu_address;// address of the loaded or stored data
	
	//to memory
	input [9:0] expected_writeback_address;
	
	//from memory
	input [127:0] test_memory_data;

	//to memory
	input [127:0] expected_memory_write_data;

	input [31:0] expected_d_cache_data;
	input expected_d_cache_stall;

	//expected debug variables
	input [127:0] expected_slot_data;
	input [3:0] expected_slot_valid;
	input [3:0] expected_slot_clean;
	input [2:0] expected_request_tag;
	
	reg [1:0] slot_index;
	reg [3:0] tag;
	
	begin
	test_number = test_number + 1;
	$display("TEST %0d", test_number);
	
	slot_index = test_cpu_address[5:4];
	tag = test_cpu_address[9:6];

	@(negedge clock);
	$display("Setting up the request");
	cpu_request_valid = test_cpu_request_valid;
	cpu_request = test_cpu_request;
	cpu_write_data = test_cpu_write_data;
	cpu_address = test_cpu_address;
	
	memory_ready = 1'b1;
	memory_data_valid = 1'b0;

	#1;
	$display("i_cache In IDLE state, Setting up the request");
	check_state(IDLE);
	check_memory_request_valid(1'b0);
	check_memory_request(REQUEST_NOTHING);
	check_memory_address(10'd0);
	check_request_tag(DO_NOTHING);
	check_memory_write_data({4{DEFAULT_CACHE_VALUE }});
	check_d_cache_stall(expected_d_cache_stall);

	@(posedge clock);
	#1;
	cpu_request_valid = 1'b0;

	
	if(test_cpu_request_valid) begin

		if(expected_request_tag == DO_NOTHING) begin
			for (i = 0; i < MEMORY_PROCESSING_CYCLES; i = i + 1) begin
			$display("expected_request_tag == DO_NOTHING, checking");
			check_state(IDLE);
			check_memory_request_valid(1'b0);
			check_memory_request(REQUEST_NOTHING);
			check_memory_address(10'd0);
			check_request_tag(DO_NOTHING);
			check_memory_write_data({4{DEFAULT_CACHE_VALUE }});
			check_d_cache_stall(expected_d_cache_stall);

			check_slot_tag(slot_index,tag);
			check_expected_slot_data(slot_index,expected_slot_data);
			check_expected_slot_valid(expected_slot_valid);
			check_expected_slot_clean(expected_slot_clean);
			@(posedge clock);
			#1;

			end
		end

		else if(expected_request_tag == LOAD_VALID_MISS_DIRTY || expected_request_tag == STORE_VALID_MISS_DIRTY) begin
			writeback_and_check(expected_writeback_address,expected_memory_write_data,expected_d_cache_stall,expected_request_tag);

		end


		if(expected_request_tag == LOAD_INVALID || expected_request_tag == LOAD_VALID_MISS_CLEAN || expected_request_tag == STORE_INVALID || expected_request_tag == STORE_VALID_MISS_CLEAN || expected_request_tag == LOAD_VALID_MISS_DIRTY || expected_request_tag == STORE_VALID_MISS_DIRTY ) begin
			$display("i_cache In START cycle, when expected_request_tag == LOAD_INVALID or expected_request_tag == LOAD_VALID_!MATCH_CLEAN or expected_request_tag == STORE_INVALID or expected_request_tag == STORE_VALID_!MATCH_CLEAN");
			check_state(START);
			check_memory_request_valid(1'b1);
			check_memory_request(READ);
			check_memory_address(test_cpu_address[9:0]);
			if(expected_request_tag == LOAD_INVALID) check_request_tag(LOAD_INVALID);
			else if(expected_request_tag == LOAD_VALID_MISS_CLEAN) check_request_tag(LOAD_VALID_MISS_CLEAN);
			else if(expected_request_tag == STORE_INVALID) check_request_tag(STORE_INVALID);
			else if(expected_request_tag == STORE_VALID_MISS_CLEAN) check_request_tag(STORE_VALID_MISS_CLEAN);
			check_memory_write_data({4{DEFAULT_CACHE_VALUE }});
			check_d_cache_stall(expected_d_cache_stall);	

			$display("i_cache In first WAIT_MEMORY_READ cycle, when expected_request_tag == LOAD_INVALID or expected_request_tag == LOAD_VALID_!MATCH_CLEAN or expected_request_tag == STORE_INVALID or expected_request_tag == STORE_VALID_!MATCH_CLEAN");
			
			for (i = 0; i < MEMORY_PROCESSING_CYCLES; i = i + 1) begin
				@(posedge clock);
				#1;
				memory_ready = 1'b0;
				$display("i_cache In WAIT_MEMORY_READ state, when expected_request_tag == LOAD_INVALID or expected_request_tag == LOAD_VALID_!MATCH_CLEAN or expected_request_tag == STORE_INVALID or expected_request_tag == STORE_VALID_!MATCH_CLEAN, waiting for data");
				check_state(WAIT_MEMORY_READ);
				check_memory_request_valid(1'b0);
				check_memory_request(READ);
				check_memory_address(test_cpu_address[9:0]);
				check_memory_write_data({4{DEFAULT_CACHE_VALUE }});
				check_d_cache_stall(expected_d_cache_stall);
			end

			@(posedge clock);
			#1;	
			$display("Memory presents valid data this cycle");
			memory_data = test_memory_data;
			memory_data_valid = 1'b1;
	
			@(posedge clock);
			#1;
			memory_data_valid = 1'b0;
			memory_ready = 1'b1;
			$display("i_cache in first cycle of FINISH state, when expected_request_tag == LOAD_INVALID or expected_request_tag == LOAD_VALID_!MATCH_CLEAN or expected_request_tag == STORE_INVALID or expected_request_tag == STORE_VALID_!MATCH_CLEAN");
			check_state(FINISH);
			check_memory_request_valid(1'b0);
			check_memory_request(READ);
			check_memory_address(test_cpu_address[9:0]);
			check_memory_write_data({4{DEFAULT_CACHE_VALUE }});
			check_expected_d_cache_data(expected_d_cache_data);
			check_d_cache_stall(1'b0);
			check_cache_data_valid(1'b1);

			check_slot_tag(slot_index,tag);
			check_expected_slot_data(slot_index,expected_slot_data);
			check_expected_slot_valid(expected_slot_valid);
			check_expected_slot_clean(expected_slot_clean);

			@(posedge clock);
			#1;
			$display("i_cache in first cycle of IDLE state after getting back from FINISH, when expected_request_tag == LOAD_INVALID or expected_request_tag == LOAD_VALID_!MATCH_CLEAN or expected_request_tag == STORE_INVALID or expected_request_tag == STORE_VALID_!MATCH_CLEAN");
			check_state(IDLE);
			check_memory_request_valid(1'b0);
			check_memory_request(REQUEST_NOTHING);
			check_memory_address(10'd0);
			check_memory_write_data({4{DEFAULT_CACHE_VALUE }});
			check_expected_d_cache_data(expected_d_cache_data);
			check_d_cache_stall(1'b0);
			check_cache_data_valid(1'b0);

			check_slot_tag(slot_index,tag);
			check_expected_slot_data(slot_index,expected_slot_data);
			check_expected_slot_valid(expected_slot_valid);
			check_expected_slot_clean(expected_slot_clean);
						

		end

	end


	end


endtask

task check_writeback_reset;
	input [3:0] expected_slot_valid;
	input [3:0] expected_slot_clean;
	input [9:0] expected_memory_write_address_slot_0;
	input [9:0] expected_memory_write_address_slot_1;
	input [9:0] expected_memory_write_address_slot_2;
	input [9:0] expected_memory_write_address_slot_3;
	input [127:0] expected_memory_write_data_slot_0;
	input [127:0] expected_memory_write_data_slot_1;
	input [127:0] expected_memory_write_data_slot_2;
	input [127:0] expected_memory_write_data_slot_3;

	begin
	test_number = test_number + 1;
	$display("TEST %0d", test_number);
	$display("Starting the writeback process after reset");
	#1;
	check_still_after_reset(1'b1);
	check_state(WRITE_BACK_AFTER_RESET);
	check_write_back_index(3'd0);
	check_request_tag(WRITE_AFTER_RESET);

	for (i = 0; i<4; i= i +1) begin
		@(posedge clock);
		#1;
		if(i ==0) begin
			if(expected_slot_valid[0] && !expected_slot_clean[0]) begin
				$display("Writing back slot 0");
				writeback_and_check(expected_memory_write_address_slot_0, expected_memory_write_data_slot_0, 1'b1, WRITE_AFTER_RESET);
				
			end

			else begin
				$display("Not Writing back slot 0");
				check_state(WRITE_BACK_AFTER_RESET);
				check_memory_request_valid(1'b0);
				check_memory_request(REQUEST_NOTHING);
				check_memory_address(10'd0);
				check_memory_write_data({4{DEFAULT_CACHE_VALUE}});

			end	
			check_d_cache_stall(1'b1);
			check_still_after_reset(1'b1);
			check_slot_tag(2'd0,4'd0);
			check_expected_slot_valid({expected_slot_valid[3:1],1'b0});
			check_expected_slot_clean({expected_slot_clean[3:1],1'b1});

		end
		else if(i==1) begin
			if(expected_slot_valid[1] && !expected_slot_clean[1]) begin
				$display("Writing back slot 1");
				writeback_and_check(expected_memory_write_address_slot_1, expected_memory_write_data_slot_1, 1'b1, WRITE_AFTER_RESET);
			end

			else begin
				$display("Not Writing back slot 1");
								check_state(WRITE_BACK_AFTER_RESET);
				check_memory_request_valid(1'b0);
				check_memory_request(REQUEST_NOTHING);
				check_memory_address(10'd0);
				check_memory_write_data({4{DEFAULT_CACHE_VALUE}});

			end
			check_d_cache_stall(1'b1);
			check_still_after_reset(1'b1);
			check_slot_tag(2'd1,4'd0);
			check_expected_slot_valid({expected_slot_valid[3:2],2'b00});
			check_expected_slot_clean({expected_slot_clean[3:2],2'b11});
		end
		
		else if(i==2) begin
			if(expected_slot_valid[2] && !expected_slot_clean[2]) begin
				$display("Writing back slot 2");
				writeback_and_check(expected_memory_write_address_slot_2, expected_memory_write_data_slot_2, 1'b1, WRITE_AFTER_RESET);
			end

			else begin
				$display("Not Writing back slot 2");
				check_state(WRITE_BACK_AFTER_RESET);
				check_memory_request_valid(1'b0);
				check_memory_request(REQUEST_NOTHING);
				check_memory_address(10'd0);
				check_memory_write_data({4{DEFAULT_CACHE_VALUE}});
			end
			check_d_cache_stall(1'b1);
			check_still_after_reset(1'b1);
			check_slot_tag(2'd2,4'd0);
			check_expected_slot_valid({expected_slot_valid[3],3'b000});
			check_expected_slot_clean({expected_slot_clean[3],3'b111});

		end
		else if(i==3) begin
			if(expected_slot_valid[3] && !expected_slot_clean[3]) begin
				$display("Writing back slot 3");
				writeback_and_check(expected_memory_write_address_slot_3, expected_memory_write_data_slot_3, 1'b1, WRITE_AFTER_RESET);
			end

			else begin
				$display("Not Writing back slot 3");
				check_state(WRITE_BACK_AFTER_RESET);
				check_memory_request_valid(1'b0);
				check_memory_request(REQUEST_NOTHING);
				check_memory_address(10'd0);
				check_memory_write_data({4{DEFAULT_CACHE_VALUE}});
			end
			check_d_cache_stall(1'b1);
			check_still_after_reset(1'b1);
			check_slot_tag(2'd3,4'd0);
			check_expected_slot_valid(4'b0000);
			check_expected_slot_clean(4'b1111);


		end


	end

	@(posedge clock);
	#1;
				$display("Done writing back, in first cycle of IDLE now");
				check_d_cache_stall(1'b0);
				check_still_after_reset(1'b0);
				check_state(IDLE);
				check_memory_request_valid(1'b0);
				check_memory_request(REQUEST_NOTHING);
				check_memory_address(10'd0);
				check_memory_write_data({4{DEFAULT_CACHE_VALUE}});

	end


endtask


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
	memory_data = 128'd0;
	memory_ready = 1'b1;
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
	check_state(IDLE);
	check_still_after_reset(1'b0);
	
	
// request_and_check(test_cpu_request_valid[1], test_cpu_request[2], test_cpu_write_data[32], test_cpu_address[32],  expected_writeback_address[10], test_memory_data[128] ,expected_memory_write_data[128],
//                   expected_d_cache_data[32], expected_d_cache_stall[1], expected_slot_data[128], expected_slot_valid[4], expected_slot_clean[4], expected_request_tag[3]);

	//Test order: LOAD_INVALID, LOAD_HIT, LOAD_VALID_MISS_CLEAN, STORE_HIT, LOAD_VALID_MISS_DIRTY, STORE_VALID_MISS_CLEAN , 	

	//Load data into invalid slots.
	//next_pc = {22'd0, tag, slot, data_index, 2'b00}
	request_and_check(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd0,2'd0, 2'b00 } ,  10'd0, {32'd3, 32'd2,32'd1, 32'd0 }, {4{DEFAULT_CACHE_VALUE}},
	32'd0, 1'b1,  {32'd3, 32'd2,32'd1, 32'd0 }, 4'b0001, 4'b1111, LOAD_INVALID );

	request_and_check(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd1,2'd1, 2'b00 }, 10'd0 ,{32'd7, 32'd6,32'd5, 32'd4 }, {4{DEFAULT_CACHE_VALUE}},
	32'd5, 1'b1,  {32'd7, 32'd6,32'd5, 32'd4 }, 4'b0011, 4'b1111, LOAD_INVALID   );

	request_and_check(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd2,2'd2, 2'b00 }, 10'd0 ,{32'd11, 32'd10,32'd9, 32'd8 }, {4{DEFAULT_CACHE_VALUE}},
	32'd10, 1'b1,  {32'd11, 32'd10,32'd9, 32'd8 }, 4'b0111, 4'b1111, LOAD_INVALID   );

	request_and_check(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd3,2'd3, 2'b00 }, 10'd0 ,{32'd15, 32'd14,32'd13, 32'd12 }, {4{DEFAULT_CACHE_VALUE}},
	32'd15, 1'b1,  {32'd15, 32'd14,32'd13, 32'd12 }, 4'b1111, 4'b1111, LOAD_INVALID   );

	
	
	//Tag hit. load data that is already in cache slots.
	request_and_check(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd0,2'd1, 2'b00 }, 10'd0 ,{32'd3, 32'd2,32'd1, 32'd0 }, {4{DEFAULT_CACHE_VALUE}},
	32'd1, 1'b0,  {32'd3, 32'd2,32'd1, 32'd0 }, 4'b1111, 4'b1111, DO_NOTHING );

	request_and_check(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd1,2'd2, 2'b00 }, 10'd0 ,{32'd7, 32'd6,32'd5, 32'd4 }, {4{DEFAULT_CACHE_VALUE}},
	32'd6, 1'b0,  {32'd7, 32'd6,32'd5, 32'd4 }, 4'b1111, 4'b1111, DO_NOTHING   );

	request_and_check(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd2,2'd3, 2'b00 }, 10'd0 ,{32'd11, 32'd10,32'd9, 32'd8 }, {4{DEFAULT_CACHE_VALUE}},
	32'd11, 1'b0,  {32'd11, 32'd10,32'd9, 32'd8 }, 4'b1111, 4'b1111, DO_NOTHING   );

	request_and_check(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd3,2'd0, 2'b00 }, 10'd0 ,{32'd15, 32'd14,32'd13, 32'd12 }, {4{DEFAULT_CACHE_VALUE}},
	32'd12, 1'b0,  {32'd15, 32'd14,32'd13, 32'd12 }, 4'b1111, 4'b1111, DO_NOTHING   );	

	
	
	//lOAD slots with different tags.
	request_and_check(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd1,2'd0,2'd0, 2'b00 }, 10'd0 ,{32'd19, 32'd18,32'd17, 32'd16 }, {4{DEFAULT_CACHE_VALUE}},
	32'd16, 1'b1,  {32'd19, 32'd18,32'd17, 32'd16 }, 4'b1111, 4'b1111, LOAD_VALID_MISS_CLEAN );

	request_and_check(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd1,2'd1,2'd1, 2'b00 }, 10'd0 ,{32'd23, 32'd22,32'd21, 32'd20 }, {4{DEFAULT_CACHE_VALUE}},
	32'd21, 1'b1,  {32'd23, 32'd22,32'd21, 32'd20 }, 4'b1111, 4'b1111, LOAD_VALID_MISS_CLEAN   );

	request_and_check(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd1,2'd2,2'd2, 2'b00 }, 10'd0 ,{32'd27, 32'd26,32'd25, 32'd24 }, {4{DEFAULT_CACHE_VALUE}},
	32'd26, 1'b1,  {32'd27, 32'd26,32'd25, 32'd24 }, 4'b1111, 4'b1111, LOAD_VALID_MISS_CLEAN  );

	request_and_check(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd1,2'd3,2'd3, 2'b00 }, 10'd0 ,{32'd31, 32'd30,32'd29, 32'd28 }, {4{DEFAULT_CACHE_VALUE}},
	32'd31, 1'b1,  {32'd31, 32'd30,32'd29, 32'd28 }, 4'b1111, 4'b1111, LOAD_VALID_MISS_CLEAN  );

	
	
	//Store hit now to make the slot dirty
	request_and_check(1'b1, STORE, 32'd100, {22'd0,4'd1,2'd0,2'd0, 2'b00 }, 10'd0 ,{32'd19, 32'd18,32'd17, 32'd16 }, {4{DEFAULT_CACHE_VALUE}},
	32'd100, 1'b0,  {32'd19, 32'd18,32'd17, 32'd100 }, 4'b1111, 4'b1110, DO_NOTHING );

	request_and_check(1'b1, STORE, 32'd101, {22'd0,4'd1,2'd1,2'd1, 2'b00 }, 10'd0 ,{32'd23, 32'd22,32'd21, 32'd20 }, {4{DEFAULT_CACHE_VALUE}},
	32'd101, 1'b0,  {32'd23, 32'd22,32'd101, 32'd20 }, 4'b1111, 4'b1100, DO_NOTHING   );

	request_and_check(1'b1, STORE, 32'd102, {22'd0,4'd1,2'd2,2'd2, 2'b00 }, 10'd0 ,{32'd27, 32'd26,32'd25, 32'd24 }, {4{DEFAULT_CACHE_VALUE}},
	32'd102, 1'b0,  {32'd27, 32'd102 ,32'd25, 32'd24 }, 4'b1111, 4'b1000, DO_NOTHING  );

	request_and_check(1'b1, STORE, 32'd103, {22'd0,4'd1,2'd3,2'd3, 2'b00 }, 10'd0 ,{32'd31, 32'd30,32'd29, 32'd28 }, {4{DEFAULT_CACHE_VALUE}},
	32'd103, 1'b0,  {32'd103, 32'd30,32'd29, 32'd28 }, 4'b1111, 4'b0000, DO_NOTHING  );

	
	//load now with different tag while the slots are dirty, have to writeback the old slots.
	request_and_check(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd0,2'd0, 2'b00 }, {4'd1,2'd0,4'd0} ,{32'd3, 32'd2,32'd1, 32'd0 }, {32'd19, 32'd18,32'd17, 32'd100 },
	32'd0, 1'b1,  {32'd3, 32'd2,32'd1, 32'd0 }, 4'b1111, 4'b0001, LOAD_VALID_MISS_DIRTY );

	request_and_check(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd1,2'd1, 2'b00 }, {4'd1,2'd1,4'd0} ,{32'd7, 32'd6,32'd5, 32'd4 }, {32'd23, 32'd22,32'd101, 32'd20 },
	32'd5, 1'b1,  {32'd7, 32'd6,32'd5, 32'd4 }, 4'b1111, 4'b011, LOAD_VALID_MISS_DIRTY   );

	request_and_check(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd2,2'd2, 2'b00 }, {4'd1,2'd2,4'd0} ,{32'd11, 32'd10,32'd9, 32'd8 }, {32'd27, 32'd102 ,32'd25, 32'd24 },
	32'd10, 1'b1,  {32'd11, 32'd10,32'd9, 32'd8 }, 4'b1111, 4'b0111, LOAD_VALID_MISS_DIRTY   );

	request_and_check(1'b1, LOAD, DEFAULT_CACHE_VALUE, {22'd0,4'd0,2'd3,2'd3, 2'b00 }, {4'd1,2'd3,4'd0} ,{32'd15, 32'd14,32'd13, 32'd12 }, {32'd103, 32'd30,32'd29, 32'd28 },
	32'd15, 1'b1,  {32'd15, 32'd14,32'd13, 32'd12 }, 4'b1111, 4'b1111, LOAD_VALID_MISS_DIRTY   );

	
	//Store now with different tag while the slots are clean.
	request_and_check(1'b1, STORE, 32'd110, {22'd0,4'd1,2'd0,2'd1, 2'b00 }, 10'd0 ,{32'd19, 32'd18,32'd17, 32'd100 }, {4{DEFAULT_CACHE_VALUE}},
	32'd110, 1'b1,  {32'd19, 32'd18,32'd110, 32'd100 }, 4'b1111, 4'b1110, STORE_VALID_MISS_CLEAN );

	request_and_check(1'b1, STORE, 32'd120, {22'd0,4'd1,2'd1,2'd2, 2'b00 }, 10'd0 ,{32'd23, 32'd22,32'd101, 32'd20 }, {4{DEFAULT_CACHE_VALUE}},
	32'd120, 1'b1,  {32'd23, 32'd120,32'd101, 32'd20 }, 4'b1111, 4'b1100, STORE_VALID_MISS_CLEAN   );

	request_and_check(1'b1, STORE, 32'd130, {22'd0,4'd1,2'd2,2'd3, 2'b00 }, 10'd0 ,{32'd27, 32'd102,32'd25, 32'd24 }, {4{DEFAULT_CACHE_VALUE}},
	32'd130, 1'b1,  {32'd130, 32'd102 ,32'd25, 32'd24 }, 4'b1111, 4'b1000, STORE_VALID_MISS_CLEAN  );

	request_and_check(1'b1, STORE, 32'd140, {22'd0,4'd1,2'd3,2'd0, 2'b00 }, 10'd0 ,{32'd103, 32'd30,32'd29, 32'd28 }, {4{DEFAULT_CACHE_VALUE}},
	32'd140, 1'b1,  {32'd103, 32'd30,32'd29, 32'd140 }, 4'b1111, 4'b0000, STORE_VALID_MISS_CLEAN  );

	
	//store now with different tag while the slots are dirty, have to write back the old slots.
	request_and_check(1'b1, STORE, 32'd200, {22'd0,4'd2,2'd0,2'd0, 2'b00 }, {4'd1,2'd0,4'd0} ,{32'd35, 32'd34,32'd33, 32'd32 }, {32'd19, 32'd18,32'd110, 32'd100 },
	32'd200, 1'b1,  {32'd35, 32'd34,32'd33, 32'd200 }, 4'b1111, 4'b0000, STORE_VALID_MISS_DIRTY );

	request_and_check(1'b1, STORE, 32'd201, {22'd0,4'd2,2'd1,2'd1, 2'b00 }, {4'd1,2'd1,4'd0} ,{32'd39, 32'd38,32'd37, 32'd36 }, {32'd23, 32'd120,32'd101, 32'd20 },
	32'd201, 1'b1,  {32'd39, 32'd38,32'd201, 32'd36 }, 4'b1111, 4'b0000, STORE_VALID_MISS_DIRTY   );

	request_and_check(1'b1, STORE, 32'd202, {22'd0,4'd2,2'd2,2'd2, 2'b00 }, {4'd1,2'd2,4'd0} ,{32'd43, 32'd42,32'd41, 32'd40 }, {32'd130, 32'd102 ,32'd25, 32'd24 },
	32'd202, 1'b1,  {32'd43, 32'd202,32'd41, 32'd40 }, 4'b1111, 4'b0000, STORE_VALID_MISS_DIRTY  );

	request_and_check(1'b1, STORE, 32'd203, {22'd0,4'd2,2'd3,2'd3, 2'b00 }, {4'd1,2'd3,4'd0} ,{32'd47, 32'd46,32'd45, 32'd44 }, {32'd103, 32'd30,32'd29, 32'd140 },
	32'd203, 1'b1,  {32'd203, 32'd46,32'd45, 32'd44 }, 4'b1111, 4'b0000, STORE_VALID_MISS_DIRTY  );
	/*	
	//reset now and check after reset operation.
	reset_n = 1'b0;
	cpu_request_valid = 1'b0;
	cpu_request = REQUEST_NOTHING;
	cpu_write_data = DEFAULT_CACHE_VALUE;
	cpu_address = 32'd0;
	memory_data = 128'd0;
	memory_ready = 1'b1;
	errors = 0;
	test_number = 0;
	
	#1;
	reset_n = 1'b1;
	
// check_writeback_reset(expected_slot_valid[4], expected_slot_clean[4], expected_memory_write_address_slot_0[10], expected_memory_write_address_slot_1[10], expected_memory_write_address_slot_2[10], expected_memory_write_address_slot_3[10],
//                       expected_memory_write_data_slot_0[128], expected_memory_write_data_slot_1[128], expected_memory_write_data_slot_2[128], expected_memory_write_data_slot_3[128]);
	check_writeback_reset(4'b1111,4'b0000, {4'd2,2'd0,4'b0000},{4'd2,2'd1,4'b0000},{4'd2,2'd2,4'b0000},{4'd2,2'd3,4'b0000},
			   {32'd35, 32'd34,32'd33, 32'd200 }, {32'd39, 32'd38,32'd201, 32'd36 }, {32'd43, 32'd202,32'd41, 32'd40 }, {32'd203, 32'd46,32'd45, 32'd44 } );
				
	//store invalid slots now.
	request_and_check(1'b1, STORE, 32'd210, {22'd0,4'd2,2'd0,2'd1, 2'b00 }, 10'd0 ,{32'd35, 32'd34,32'd33, 32'd200 }, {4{DEFAULT_CACHE_VALUE}},
	32'd210, 1'b1,  {32'd35, 32'd34,32'd210, 32'd200 }, 4'b0001, 4'b1110, STORE_INVALID );

	request_and_check(1'b1, STORE, 32'd211, {22'd0,4'd2,2'd1,2'd2, 2'b00 }, 10'd0 ,{32'd39, 32'd38,32'd201, 32'd36 }, {4{DEFAULT_CACHE_VALUE}},
	32'd211, 1'b1,  {32'd39, 32'd211,32'd201, 32'd36 }, 4'b0011, 4'b1100, STORE_INVALID   );

	request_and_check(1'b1, STORE, 32'd212, {22'd0,4'd2,2'd2,2'd3, 2'b00 }, 10'd0 ,{32'd43, 32'd202,32'd41, 32'd40 }, {4{DEFAULT_CACHE_VALUE}},
	32'd212, 1'b1,  {32'd212, 32'd202,32'd41, 32'd40 }, 4'b0111, 4'b1000, STORE_INVALID );

	request_and_check(1'b1, STORE, 32'd213, {22'd0,4'd2,2'd3,2'd0, 2'b00 }, 10'd0 ,{32'd203, 32'd46,32'd45, 32'd44 }, {4{DEFAULT_CACHE_VALUE}},
	32'd213, 1'b1,  {32'd203, 32'd46,32'd45, 32'd213}, 4'b1111, 4'b0000, STORE_INVALID  );
	
	*/

	if (errors == 0)
        $display("ALL D_cache TESTS PASSED");
   else
        $display("%0d D_cache TESTS FAILED", errors);

   $finish;	

end

endmodule

