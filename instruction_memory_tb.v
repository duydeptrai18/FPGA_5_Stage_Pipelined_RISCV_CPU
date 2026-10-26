/*
- Test by putting instructions into memory first then check.
*/

`timescale 1ns/1ps

module instruction_memory_tb;

reg  [31:0] address;
wire [31:0] data;

integer errors;

instruction_memory instruction_memory_dut(
    .address(address),
    .data(data)
);

task test_instruction_memory;
    input [31:0] test_address;
    input [31:0] expected_data;

    begin
        address = test_address;

        // Allow combinational output to update
        #1;

        if (data !== expected_data) begin
            errors = errors + 1;

            $display(
                "FAILED: address=%h data=%h expected=%h",
                address, data, expected_data
            );
        end
        else begin
            $display(
                "PASSED: address=%h data=%h expected=%h",
                address, data, expected_data
            );
        end
    end
endtask

initial begin
    errors  = 0;
    address = 32'd0;
	 
	 /*Test by putting these instructions into memory first then check.
    test_instruction_memory(
        32'd0,
        32'h11111111
    );

    test_instruction_memory(
        32'd4,
        32'h22222222
    );

    test_instruction_memory(
        32'd8,
        32'h33333333
    );

    test_instruction_memory(
        32'd12,
        32'h44444444
    );
	 */
	
    if (errors == 0)
        $display("ALL INSTRUCTION MEMORY TESTS PASSED");
    else
        $display("%0d INSTRUCTION MEMORY TESTS FAILED", errors);

    $finish;
end

endmodule