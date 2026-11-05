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

task check_memory_ready;
    input expected_memory_ready;
    begin
        if (memory_ready !== expected_memory_ready) begin
            errors = errors + 1;
            $display("FAIL memory_ready=%b expected=%b",
                     memory_ready, expected_memory_ready);
        end
        else
            $display("PASS memory_ready=%b", memory_ready);
    end
endtask

task check_memory_data_valid;
    input expected_memory_data_valid;
    begin
        if (memory_data_valid !== expected_memory_data_valid) begin
            errors = errors + 1;
            $display("FAIL memory_data_valid=%b expected=%b",
                     memory_data_valid, expected_memory_data_valid);
        end
        else
            $display("PASS memory_data_valid=%b", memory_data_valid);
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

task check_d_cache_state;
    input [2:0] expected_d_cache_state;
    begin
        if (d_cache_dut.state !== expected_d_cache_state) begin
            errors = errors + 1;
            $display("FAIL d_cache_state=%b expected=%b",
                     d_cache_dut.state, expected_d_cache_state);
        end
        else
            $display("PASS d_cache_state=%b", d_cache_dut.state);
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

task check_cache_ready;
    input expected_cache_ready;
    begin
        if (d_cache_dut.cache_ready !== expected_cache_ready) begin
            errors = errors + 1;
            $display("FAIL cache_ready=%b expected=%b",
                     d_cache_dut.cache_ready, expected_cache_ready);
        end
        else
            $display("PASS cache_ready=%b", d_cache_dut.cache_ready);
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


task check_memory_state;
    input [1:0] expected_memory_state;
    begin
        if (slow_data_memory_dut.state !== expected_memory_state) begin
            errors = errors + 1;
            $display("FAIL memory_state=%b expected=%b",
                     slow_data_memory_dut.state, expected_memory_state);
        end
        else
            $display("PASS memory_state=%b", slow_data_memory_dut.state);
    end
endtask

task check_expected_memory_slot_data;
    input [9:0] expected_writeback_address;
    input [127:0] expected_memory_write_data;

    reg [127:0] actual_memory_data;
    begin
        actual_memory_data = {
            slow_data_memory_dut.memory[{expected_writeback_address[9:4], 2'b11}],
            slow_data_memory_dut.memory[{expected_writeback_address[9:4], 2'b10}],
            slow_data_memory_dut.memory[{expected_writeback_address[9:4], 2'b01}],
            slow_data_memory_dut.memory[{expected_writeback_address[9:4], 2'b00}]
        };

        if (actual_memory_data !== expected_memory_write_data) begin
            errors = errors + 1;
            $display("FAIL writeback_address=%h data=%h expected=%h",
                     expected_writeback_address, actual_memory_data,
                     expected_memory_write_data);
        end
        else
            $display("PASS writeback_address=%h data=%h",
                     expected_writeback_address, actual_memory_data);
    end
endtask

task check_memory_data;
    input [127:0] expected_memory_data;

    begin
        if (slow_data_memory_dut.read_data !== expected_memory_data) begin
            errors = errors + 1;
            $display("FAIL read_data=%h expected=%h",
                     slow_data_memory_dut.read_data, expected_memory_data);
        end
        else
            $display("PASS read_data=%h", slow_data_memory_dut.read_data);
    end
endtask


//for d_cache_slow_data_memory_tb specifically -------------------------------------
task check_writeback_reset_d_cache_system;
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
	$display("Check d_cache");
	check_still_after_reset(1'b1);
	check_d_cache_state(D_CACHE_WRITE_BACK_AFTER_RESET);
	check_write_back_index(3'd0);
	check_request_tag(WRITE_AFTER_RESET);

	$display("Check memory");
	check_memory_state(MEMORY_IDLE);
	check_memory_ready(1'b1);
	check_memory_data_valid(1'b0);

	for (i = 0; i<4; i= i +1) begin
		@(posedge clock);
		#1;
		if(i ==0) begin
			if(expected_slot_valid[0] && !expected_slot_clean[0]) begin
				$display("Writing back slot 0");
				writeback_and_check_d_cache_system(expected_memory_write_address_slot_0, expected_memory_write_data_slot_0, 1'b1, WRITE_AFTER_RESET);
				
			end

			else begin
				$display("Not Writing back slot 0, check d_cache");
				check_d_cache_state(D_CACHE_WRITE_BACK_AFTER_RESET);
				check_memory_request_valid(1'b0);
				check_memory_request(REQUEST_NOTHING);
				check_memory_address(10'd0);
				check_memory_write_data({4{DEFAULT_CACHE_VALUE}});

				$display("Check memory slot 0 not write");
				check_expected_memory_slot_data(expected_memory_write_address_slot_0, expected_memory_write_data_slot_0);
				check_memory_state(MEMORY_IDLE);
				check_memory_ready(1'b1);
				check_memory_data_valid(1'b0);

			end	
			check_cache_ready(1'b0);
			check_d_cache_stall(1'b1);
			check_still_after_reset(1'b1);
			check_slot_tag(2'd0,4'd0);
			check_expected_slot_valid({expected_slot_valid[3:1],1'b0});
			check_expected_slot_clean({expected_slot_clean[3:1],1'b1});

		end
		else if(i==1) begin
			if(expected_slot_valid[1] && !expected_slot_clean[1]) begin
				$display("Writing back slot 1");
				writeback_and_check_d_cache_system(expected_memory_write_address_slot_1, expected_memory_write_data_slot_1, 1'b1, WRITE_AFTER_RESET);
			end

			else begin
				$display("Not Writing back slot 1, check d_cache");
				check_d_cache_state(D_CACHE_WRITE_BACK_AFTER_RESET);
				check_memory_request_valid(1'b0);
				check_memory_request(REQUEST_NOTHING);
				check_memory_address(10'd0);
				check_memory_write_data({4{DEFAULT_CACHE_VALUE}});

				$display("Check memory slot 1 not write");
				check_expected_memory_slot_data(expected_memory_write_address_slot_1, expected_memory_write_data_slot_1);
				check_memory_state(MEMORY_IDLE);
				check_memory_ready(1'b1);
				check_memory_data_valid(1'b0);

			end
			check_cache_ready(1'b0);
			check_d_cache_stall(1'b1);
			check_still_after_reset(1'b1);
			check_slot_tag(2'd1,4'd0);
			check_expected_slot_valid({expected_slot_valid[3:2],2'b00});
			check_expected_slot_clean({expected_slot_clean[3:2],2'b11});
		end
		
		else if(i==2) begin
			if(expected_slot_valid[2] && !expected_slot_clean[2]) begin
				$display("Writing back slot 2");
				writeback_and_check_d_cache_system(expected_memory_write_address_slot_2, expected_memory_write_data_slot_2, 1'b1, WRITE_AFTER_RESET);
			end

			else begin
				$display("Not Writing back slot 2, check d_cache");
				check_d_cache_state(D_CACHE_WRITE_BACK_AFTER_RESET);
				check_memory_request_valid(1'b0);
				check_memory_request(REQUEST_NOTHING);
				check_memory_address(10'd0);
				check_memory_write_data({4{DEFAULT_CACHE_VALUE}});

				$display("Check memory slot 2 not write");
				check_expected_memory_slot_data(expected_memory_write_address_slot_2, expected_memory_write_data_slot_2);
				check_memory_state(MEMORY_IDLE);
				check_memory_ready(1'b1);
				check_memory_data_valid(1'b0);
			end
			check_cache_ready(1'b0);
			check_d_cache_stall(1'b1);
			check_still_after_reset(1'b1);
			check_slot_tag(2'd2,4'd0);
			check_expected_slot_valid({expected_slot_valid[3],3'b000});
			check_expected_slot_clean({expected_slot_clean[3],3'b111});

		end
		else if(i==3) begin
			if(expected_slot_valid[3] && !expected_slot_clean[3]) begin
				$display("Writing back slot 3");
				writeback_and_check_d_cache_system(expected_memory_write_address_slot_3, expected_memory_write_data_slot_3, 1'b1, WRITE_AFTER_RESET);
			end

			else begin
				$display("Not Writing back slot 3, check d_cache");
				check_d_cache_state(D_CACHE_WRITE_BACK_AFTER_RESET);
				check_memory_request_valid(1'b0);
				check_memory_request(REQUEST_NOTHING);
				check_memory_address(10'd0);
				check_memory_write_data({4{DEFAULT_CACHE_VALUE}});

				$display("Check memory slot 3 not write");
				check_expected_memory_slot_data(expected_memory_write_address_slot_3, expected_memory_write_data_slot_3);
				check_memory_state(MEMORY_IDLE);
				check_memory_ready(1'b1);
				check_memory_data_valid(1'b0);
			end
			check_cache_ready(1'b0);
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
				check_d_cache_state(D_CACHE_IDLE);
				check_memory_request_valid(1'b0);
				check_memory_request(REQUEST_NOTHING);
				check_memory_address(10'd0);
				check_memory_write_data({4{DEFAULT_CACHE_VALUE}});
				check_cache_ready(1'b1);

				$display("Memory done writing back");
				check_memory_state(MEMORY_IDLE);
				check_memory_ready(1'b1);
				check_memory_data_valid(1'b0);

	end


endtask

task writeback_and_check_d_cache_system;
	input [9:0] expected_writeback_address;
	input [127:0] 	expected_memory_write_data;
	input expected_d_cache_stall;
	input [2:0] expected_request_tag;


	integer i;
	begin
			if(expected_request_tag == LOAD_VALID_MISS_DIRTY) begin
			$display("d_cache In START cycle, when expected_request_tag == LOAD_VALID_MISS_DIRTY");
			check_request_tag(LOAD_VALID_MISS_DIRTY);
			end
			else if(expected_request_tag == STORE_VALID_MISS_DIRTY) begin
			$display("d_cache In START cycle, when expected_request_tag == LOAD_VALID_MISS_DIRTY");
			check_request_tag(STORE_VALID_MISS_DIRTY);
			end
			else if(expected_request_tag == WRITE_AFTER_RESET) begin
			$display("d_cache In START cycle, when expected_request_tag == WRITE_AFTER_RESET");
			check_request_tag(WRITE_AFTER_RESET);	
			check_still_after_reset(1'b1);		
			end

			check_d_cache_state(D_CACHE_START);
			check_memory_request_valid(1'b1);
			check_memory_request(WRITE);
			check_memory_address(expected_writeback_address);
			check_memory_write_data(expected_memory_write_data);
			check_d_cache_stall(expected_d_cache_stall);	
			check_cache_ready(1'b0);

			$display("Memory see request valid = 1 this cycle");
			check_memory_state(MEMORY_IDLE);
			check_memory_ready(1'b1);
			check_memory_data_valid(1'b0);

			$display("D_cache In first WAIT_MEMORY_WRITE cycle, when expected_request_tag == LOAD_VALID_MISS_DIRTY or expected_request_tag == STORE_VALID_MISS_DIRTY");
			
			for (i = 0; i < MEMORY_PROCESSING_CYCLES; i = i + 1) begin
				@(posedge clock);
				#1;
				if(expected_request_tag == WRITE_AFTER_RESET) check_still_after_reset(1'b1);
				$display("Memory in first cycle of MEMORY_WRITE_PROCESSING");
				check_memory_state(MEMORY_WRITE_PROCESSING);
				check_memory_ready(1'b0);
				check_memory_data_valid(1'b0);
				$display("d_cache In WAIT_MEMORY_WRITE state, when expected_request_tag == LOAD_VALID_MISS_DIRTY or expected_request_tag == STORE_VALID_MISS_DIRTY");
				check_d_cache_state(D_CACHE_WAIT_MEMORY_WRITE);
				check_memory_request_valid(1'b0);
				check_memory_request(WRITE);
				check_memory_address(expected_writeback_address);
				check_memory_write_data(expected_memory_write_data);
				check_d_cache_stall(expected_d_cache_stall);
				check_cache_ready(1'b0);
			end

			@(posedge clock);
			#1;	
			$display("Memory done writing data this cycle in its FINISH state");
			check_expected_memory_slot_data(expected_writeback_address, expected_memory_write_data);
			check_memory_state(MEMORY_FINISH);
			check_memory_ready(1'b0);
			check_memory_data_valid(1'b1);

			@(posedge clock);
			#1;
			$display("Memory go back to IDLE after FINISH state");
			check_expected_memory_slot_data(expected_writeback_address, expected_memory_write_data);
			check_memory_state(MEMORY_IDLE);
			check_memory_ready(1'b1);
			check_memory_data_valid(1'b0);

			$display("d_cache in first cycle of START state or getting back to WRITE_AFTER_RESET STATE, after just finished writing, when expected_request_tag == LOAD_VALID_MISS_DIRTY or expected_request_tag == STORE_VALID_MISS_DIRTY");

	end


endtask

task request_and_check_d_cache_system;
	
	//from cpu
	input test_cpu_request_valid;//pulse from cpu that request to store or load data
	input [1:0] test_cpu_request; //request = 00 nothing, 01:load, 10: store
	input [31:0] test_cpu_write_data;
	input [31:0] test_cpu_address;// address of the loaded or stored data
	
	//from memory
	input [9:0] expected_writeback_address;
	input [127:0] expected_memory_data;
	input [127:0] expected_memory_write_data;

	//to cpu
	input [31:0] expected_d_cache_data;
	input expected_d_cache_stall;

	//expected d_cache debug variables
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
	$display("Setting up the request, memory should be ready here");
	cpu_request_valid = test_cpu_request_valid;
	cpu_request = test_cpu_request;
	cpu_write_data = test_cpu_write_data;
	cpu_address = test_cpu_address;

	#1;
	$display("d_cache In IDLE state, Setting up the request");
	check_d_cache_state(D_CACHE_IDLE);
	check_memory_request_valid(1'b0);
	check_memory_request(REQUEST_NOTHING);
	check_memory_address(10'd0);
	check_request_tag(DO_NOTHING);
	check_memory_write_data({4{DEFAULT_CACHE_VALUE }});
	check_d_cache_stall(expected_d_cache_stall);
	check_cache_ready(1'b1);

	$display("memory In IDLE state, Setting up the request");
	check_memory_state(MEMORY_IDLE);
	check_memory_ready(1'b1);
	check_memory_data_valid(1'b0);

	@(posedge clock);
	#1;
	cpu_request_valid = 1'b0;

	if(test_cpu_request_valid) begin

		if(expected_request_tag == DO_NOTHING) begin
			for (i = 0; i < MEMORY_PROCESSING_CYCLES; i = i + 1) begin
			check_cache_ready(1'b1);
			$display("expected_request_tag == DO_NOTHING, D_CACHE checking");
			check_d_cache_state(D_CACHE_IDLE);
			check_memory_request_valid(1'b0);
			check_memory_request(REQUEST_NOTHING);
			check_memory_address(10'd0);
			check_request_tag(DO_NOTHING);
			check_memory_write_data({4{DEFAULT_CACHE_VALUE }});
			check_d_cache_stall(expected_d_cache_stall);
			check_expected_d_cache_data(expected_d_cache_data);
			check_slot_tag(slot_index,tag);
			check_expected_slot_data(slot_index,expected_slot_data);
			check_expected_slot_valid(expected_slot_valid);
			check_expected_slot_clean(expected_slot_clean);

			$display("expected_request_tag == DO_NOTHING, memory checking");
			check_memory_state(MEMORY_IDLE);
			check_memory_ready(1'b1);
			check_memory_data_valid(1'b0);
			@(posedge clock);
			#1;

			end
		end

		else if(expected_request_tag == LOAD_VALID_MISS_DIRTY || expected_request_tag == STORE_VALID_MISS_DIRTY) begin
			writeback_and_check_d_cache_system(expected_writeback_address,expected_memory_write_data,expected_d_cache_stall,expected_request_tag);

		end

		if(expected_request_tag == LOAD_INVALID || expected_request_tag == LOAD_VALID_MISS_CLEAN || expected_request_tag == STORE_INVALID || expected_request_tag == STORE_VALID_MISS_CLEAN || expected_request_tag == LOAD_VALID_MISS_DIRTY || expected_request_tag == STORE_VALID_MISS_DIRTY ) begin
			$display("d_cache In START cycle, when expected_request_tag == LOAD_INVALID or expected_request_tag == LOAD_VALID_!MATCH_CLEAN or expected_request_tag == STORE_INVALID or expected_request_tag == STORE_VALID_!MATCH_CLEAN");
			check_d_cache_state(D_CACHE_START);
			check_memory_request_valid(1'b1);
			check_memory_request(READ);
			check_memory_address(test_cpu_address[9:0]);
			check_cache_ready(1'b0);
			if(expected_request_tag == LOAD_INVALID) check_request_tag(LOAD_INVALID);
			else if(expected_request_tag == LOAD_VALID_MISS_CLEAN) check_request_tag(LOAD_VALID_MISS_CLEAN);
			else if(expected_request_tag == STORE_INVALID) check_request_tag(STORE_INVALID);
			else if(expected_request_tag == STORE_VALID_MISS_CLEAN) check_request_tag(STORE_VALID_MISS_CLEAN);
			check_memory_write_data({4{DEFAULT_CACHE_VALUE }});
			check_d_cache_stall(expected_d_cache_stall);	
			
			$display("Memory see request this cycle, when expected_request_tag == LOAD_INVALID or expected_request_tag == LOAD_VALID_!MATCH_CLEAN or expected_request_tag == STORE_INVALID or expected_request_tag == STORE_VALID_!MATCH_CLEAN");
			check_memory_state(MEMORY_IDLE);
			check_memory_ready(1'b1);
			check_memory_data_valid(1'b0);


			$display("d_cache In first WAIT_MEMORY_READ cycle, when expected_request_tag == LOAD_INVALID or expected_request_tag == LOAD_VALID_!MATCH_CLEAN or expected_request_tag == STORE_INVALID or expected_request_tag == STORE_VALID_!MATCH_CLEAN");
			
			for (i = 0; i < MEMORY_PROCESSING_CYCLES; i = i + 1) begin
				@(posedge clock);
				#1;
				$display("Memory checking, when expected_request_tag == LOAD_INVALID or expected_request_tag == LOAD_VALID_!MATCH_CLEAN or expected_request_tag == STORE_INVALID or expected_request_tag == STORE_VALID_!MATCH_CLEAN");
				check_memory_state(MEMORY_READ_PROCESSING);
				check_memory_ready(1'b0);
				check_memory_data_valid(1'b0);

				$display("d_cache In WAIT_MEMORY_READ state, when expected_request_tag == LOAD_INVALID or expected_request_tag == LOAD_VALID_!MATCH_CLEAN or expected_request_tag == STORE_INVALID or expected_request_tag == STORE_VALID_!MATCH_CLEAN, waiting for data");
				check_d_cache_state(D_CACHE_WAIT_MEMORY_READ);
				check_memory_request_valid(1'b0);
				check_memory_request(READ);
				check_memory_address(test_cpu_address[9:0]);
				check_memory_write_data({4{DEFAULT_CACHE_VALUE }});
				check_d_cache_stall(expected_d_cache_stall);
				check_cache_ready(1'b0);
			end

			@(posedge clock);
			#1;	
			$display("Memory presents valid data this cycle, IN FINISH");

			check_memory_data(expected_memory_data);
			check_memory_state(MEMORY_FINISH);
			check_memory_ready(1'b0);
			check_memory_data_valid(1'b1);
	
			@(posedge clock);
			#1;
			$display("d_cache in first cycle of FINISH state, when expected_request_tag == LOAD_INVALID or expected_request_tag == LOAD_VALID_!MATCH_CLEAN or expected_request_tag == STORE_INVALID or expected_request_tag == STORE_VALID_!MATCH_CLEAN");
			check_d_cache_state(D_CACHE_FINISH);
			check_memory_request_valid(1'b0);
			check_memory_request(READ);
			check_memory_address(test_cpu_address[9:0]);
			check_memory_write_data({4{DEFAULT_CACHE_VALUE }});
			check_expected_d_cache_data(expected_d_cache_data);
			check_d_cache_stall(1'b0);
			check_cache_ready(1'b1);

			check_slot_tag(slot_index,tag);
			check_expected_slot_data(slot_index,expected_slot_data);
			check_expected_slot_valid(expected_slot_valid);
			check_expected_slot_clean(expected_slot_clean);

			$display("Memory go back to IDLE from FINISH");
			check_memory_data(expected_memory_data);
			check_memory_state(MEMORY_IDLE);
			check_memory_ready(1'b1);
			check_memory_data_valid(1'b0);

			@(posedge clock);
			#1;
			$display("d_cache in first cycle of IDLE state after getting back from FINISH, when expected_request_tag == LOAD_INVALID or expected_request_tag == LOAD_VALID_!MATCH_CLEAN or expected_request_tag == STORE_INVALID or expected_request_tag == STORE_VALID_!MATCH_CLEAN");
			check_d_cache_state(D_CACHE_IDLE);
			check_memory_request_valid(1'b0);
			check_memory_request(REQUEST_NOTHING);
			check_memory_address(10'd0);
			check_memory_write_data({4{DEFAULT_CACHE_VALUE }});
			check_expected_d_cache_data(expected_d_cache_data);
			check_d_cache_stall(1'b0);
			check_cache_ready(1'b1);

			check_slot_tag(slot_index,tag);
			check_expected_slot_data(slot_index,expected_slot_data);
			check_expected_slot_valid(expected_slot_valid);
			check_expected_slot_clean(expected_slot_clean);

			$display("Memory in IDLE second cycle");
			check_memory_data(expected_memory_data);
			check_memory_state(MEMORY_IDLE);
			check_memory_ready(1'b1);
			check_memory_data_valid(1'b0);
						

		end

	end

	end
endtask







