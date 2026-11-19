// Include inside the DMA testbench module, after its signal declarations.
// Each task samples immediately. Call it after the DUT's outputs settle.
// Declare and initialize an integer errors in the testbench.
// Every check prints its result. A mismatch increments errors.

task check_dma_memory_request_valid;
    input expected;
    begin
        if (dma_dut.dma_memory_request_valid !== expected) begin
            errors = errors + 1;
            $display("FAIL %m: dma_memory_request_valid expected %b, got %b",
                     expected, dma_dut.dma_memory_request_valid);
        end else begin
            $display("PASS %m: dma_memory_request_valid = %b",
                     dma_dut.dma_memory_request_valid);
        end
    end
endtask

task check_dma_memory_request;
    input [1:0] expected;
    begin
        if (dma_dut.dma_memory_request !== expected) begin
            errors = errors + 1;
            $display("FAIL %m: dma_memory_request expected 0x%0h, got 0x%0h",
                     expected, dma_dut.dma_memory_request);
        end else begin
            $display("PASS %m: dma_memory_request = 0x%0h",
                     dma_dut.dma_memory_request);
        end
    end
endtask

task check_dma_memory_start_address;
    input [9:0] expected;
    begin
        if (dma_dut.dma_memory_start_address !== expected) begin
            errors = errors + 1;
            $display("FAIL %m: dma_memory_start_address expected 0x%0h, got 0x%0h",
                     expected, dma_dut.dma_memory_start_address);
        end else begin
            $display("PASS %m: dma_memory_start_address = 0x%0h",
                     dma_dut.dma_memory_start_address);
        end
    end
endtask

task check_dma_memory_beat_count;
    input [3:0] expected;
    begin
        if (dma_dut.dma_memory_beat_count !== expected) begin
            errors = errors + 1;
            $display("FAIL %m: dma_memory_beat_count expected 0x%0h, got 0x%0h",
                     expected, dma_dut.dma_memory_beat_count);
        end else begin
            $display("PASS %m: dma_memory_beat_count = 0x%0h",
                     dma_dut.dma_memory_beat_count);
        end
    end
endtask

task check_dma_memory_write_data;
    input [31:0] expected;
    begin
        if (dma_dut.dma_memory_write_data !== expected) begin
            errors = errors + 1;
            $display("FAIL %m: dma_memory_write_data expected 0x%0h, got 0x%0h",
                     expected, dma_dut.dma_memory_write_data);
        end else begin
            $display("PASS %m: dma_memory_write_data = 0x%0h",
                     dma_dut.dma_memory_write_data);
        end
    end
endtask

task check_dma_memory_write_data_valid;
    input expected;
    begin
        if (dma_dut.dma_memory_write_data_valid !== expected) begin
            errors = errors + 1;
            $display("FAIL %m: dma_memory_write_data_valid expected %b, got %b",
                     expected, dma_dut.dma_memory_write_data_valid);
        end else begin
            $display("PASS %m: dma_memory_write_data_valid = %b",
                     dma_dut.dma_memory_write_data_valid);
        end
    end
endtask

task check_dma_memory_write_ready;
    input expected;
    begin
        if (dma_memory_write_ready !== expected) begin
            errors = errors + 1;
            $display("FAIL %m: dma_memory_write_ready expected %b, got %b",
                     expected, dma_memory_write_ready);
        end else begin
            $display("PASS %m: dma_memory_write_ready = %b",
                     dma_memory_write_ready);
        end
    end
endtask

task check_dma_cpu_command_ready;
    input expected;
    begin
        if (dma_cpu_command_ready !== expected) begin
            errors = errors + 1;
            $display("FAIL %m: dma_cpu_command_ready expected 0x%0h, got 0x%0h",
                     expected, dma_cpu_command_ready);
        end else begin
            $display("PASS %m: dma_cpu_command_ready = 0x%0h", dma_cpu_command_ready);
        end
    end
endtask

task check_dma_memory_read_data_ready;
    input expected;
    begin
        if (dma_memory_read_data_ready !== expected) begin
            errors = errors + 1;
            $display("FAIL %m: dma_memory_read_data_ready expected 0x%0h, got 0x%0h",
                     expected, dma_memory_read_data_ready);
        end else begin
            $display("PASS %m: dma_memory_read_data_ready = 0x%0h", dma_memory_read_data_ready);
        end
    end
endtask

task check_counter_beat;
    input [3:0] expected;
    begin
        if (dma_dut.counter_beat !== expected) begin
            errors = errors + 1;
            $display("FAIL %m: counter_beat expected 0x%0h, got 0x%0h",
                     expected, dma_dut.counter_beat);
        end else begin
            $display("PASS %m: counter_beat = 0x%0h", dma_dut.counter_beat);
        end
    end
endtask

task check_dma_state;
    input [2:0] expected;
    begin
        if (dma_dut.dma_state !== expected) begin
            errors = errors + 1;
            $display("FAIL %m: dma_state expected 0x%0h, got 0x%0h",
                     expected, dma_dut.dma_state);
        end else begin
            $display("PASS %m: dma_state = 0x%0h", dma_dut.dma_state);
        end
    end
endtask

task check_memory;
    input [3:0]  memory_index;
    input [31:0] expected;
    begin
        if (dma_dut.memory[memory_index] !== expected) begin
            errors = errors + 1;
            $display("FAIL %m: memory[%0d] expected 0x%08h, got 0x%08h",
                     memory_index, expected, dma_dut.memory[memory_index]);
        end else begin
            $display("PASS %m: memory[%0d] = 0x%08h",
                     memory_index, dma_dut.memory[memory_index]);
        end
    end
endtask