task check_memory_dma_ready;
    input expected;
    begin
        if (memory_dma_ready !== expected) begin
            errors = errors + 1;
            $display("FAIL %m: memory_dma_ready expected %b, got %b",
                     expected, memory_dma_ready);
        end else begin
            $display("PASS %m: memory_dma_ready = %b", memory_dma_ready);
        end
    end
endtask

task check_memory_dma_valid;
    input expected;
    begin
        if (memory_dma_valid !== expected) begin
            errors = errors + 1;
            $display("FAIL %m: memory_dma_valid expected %b, got %b",
                     expected, memory_dma_valid);
        end else begin
            $display("PASS %m: memory_dma_valid = %b", memory_dma_valid);
        end
    end
endtask

task check_memory_dma_write_ready;
    input expected;
    begin
        if (memory_dma_write_ready !== expected) begin
            errors = errors + 1;
            $display("FAIL %m: memory_dma_write_ready expected %b, got %b",
                     expected, memory_dma_write_ready);
        end else begin
            $display("PASS %m: memory_dma_write_ready = %b", memory_dma_write_ready);
        end
    end
endtask

task check_memory_dma_read_data;
    input [31:0] expected;
    begin
        if (memory_dma_read_data !== expected) begin
            errors = errors + 1;
            $display("FAIL %m: memory_dma_read_data expected 0x%08h, got 0x%08h",
                     expected, memory_dma_read_data);
        end else begin
            $display("PASS %m: memory_dma_read_data = 0x%08h", memory_dma_read_data);
        end
    end
endtask

task check_temp_write_data;
    input [31:0] expected;
    begin
        if (slow_dma_data_memory_dut.temp_write_data !== expected) begin
            errors = errors + 1;
            $display("FAIL %m: temp_write_data expected 0x%08h, got 0x%08h",
                     expected, slow_dma_data_memory_dut.temp_write_data);
        end else begin
            $display("PASS %m: temp_write_data = 0x%08h",
                     slow_dma_data_memory_dut.temp_write_data);
        end
    end
endtask

task check_memory_counter_beat;
    input [3:0] expected;
    begin
        if (slow_dma_data_memory_dut.memory_counter_beat !== expected) begin
            errors = errors + 1;
            $display("FAIL %m: memory_counter_beat expected %0d, got %0d",
                     expected, slow_dma_data_memory_dut.memory_counter_beat);
        end else begin
            $display("PASS %m: memory_counter_beat = %0d",
                     slow_dma_data_memory_dut.memory_counter_beat);
        end
    end
endtask

task check_memory_state;
    input [1:0] expected;
    begin
        if (slow_dma_data_memory_dut.memory_state !== expected) begin
            errors = errors + 1;
            $display("FAIL %m: memory_state expected %b, got %b",
                     expected, slow_dma_data_memory_dut.memory_state);
        end else begin
            $display("PASS %m: memory_state = %b",
                     slow_dma_data_memory_dut.memory_state);
        end
    end
endtask

task check_temp_address;
    input [9:0] expected;
    begin
        if (slow_dma_data_memory_dut.temp_address !== expected) begin
            errors = errors + 1;
            $display("FAIL %m: temp_address expected 0x%03h, got 0x%03h",
                     expected, slow_dma_data_memory_dut.temp_address);
        end else begin
            $display("PASS %m: temp_address = 0x%03h",
                     slow_dma_data_memory_dut.temp_address);
        end
    end
endtask

task check_counter;
    input [2:0] expected;
    begin
        if (slow_dma_data_memory_dut.counter !== expected) begin
            errors = errors + 1;
            $display("FAIL %m: counter expected %0d, got %0d",
                     expected, slow_dma_data_memory_dut.counter);
        end else begin
            $display("PASS %m: counter = %0d",
                     slow_dma_data_memory_dut.counter);
        end
    end
endtask
