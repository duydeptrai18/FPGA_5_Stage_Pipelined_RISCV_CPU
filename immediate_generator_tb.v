/*
- 1. Test and check output immediate value based on immediate_type and instruction.
- 2. Test and check positive and negative immediate.
- 3. Test invalid instructions.
*/

`timescale 1ns/1ps

module immediate_generator_tb;

reg  [31:0] instruction;
reg  [2:0]  immediate_type;
wire [31:0] immediate;

integer errors;

localparam IMM_I = 3'b000;
localparam IMM_S = 3'b001;
localparam IMM_B = 3'b010;
localparam IMM_U = 3'b011;
localparam IMM_J = 3'b100;

immediate_generator immediate_generator_dut(
    .instruction    (instruction),
    .immediate_type (immediate_type),
    .immediate      (immediate)
);

task test_immediate_generator;
    input [2:0]  test_immediate_type;
    input [31:0] test_instruction;
    input [31:0] expected_immediate;

    begin
        instruction  = test_instruction;
        immediate_type = test_immediate_type;

        #1;

        if (immediate !== expected_immediate) begin
            errors = errors + 1;

            $display(
                "FAILED: type=%b instruction=%h immediate=%h expected=%h",
                immediate_type,instruction,immediate,expected_immediate);
        end
        else begin
            $display(
                "PASSED: type=%b instruction=%h immediate=%h expected=%h",
                immediate_type,instruction,immediate,expected_immediate);
        end
    end
endtask

initial begin
    instruction    = 32'd0;
    immediate_type = IMM_I;
    errors         = 0;

    // I-type: immediate = +10
    test_immediate_generator(IMM_I,32'h00A00000,32'd10);

    // I-type: immediate = -1
    test_immediate_generator(IMM_I,32'hFFF00000,32'hFFFFFFFF);

    // S-type: immediate = +12
    test_immediate_generator(IMM_S,32'h00000600,32'd12);

    // S-type: immediate = -1
    test_immediate_generator(IMM_S,32'hFE000F80,32'hFFFFFFFF);

    // B-type: branch offset = +8
    test_immediate_generator(IMM_B, 32'h00000400,32'd8);

    // B-type: branch offset = -4
    test_immediate_generator(IMM_B,32'hFE000E80,32'hFFFFFFFC);

    // U-type: upper immediate
    test_immediate_generator(IMM_U,32'h12345000,32'h12345000);

    // J-type: jump offset = +16
    test_immediate_generator(IMM_J,32'h01000000,32'd16);

    // J-type: jump offset = -4
    test_immediate_generator(IMM_J,32'hFFDFF000,32'hFFFFFFFC);

    // Invalid immediate type: default output = 0
    test_immediate_generator(3'b111,32'hFFFFFFFF,32'd0);

    if (errors == 0)
        $display("ALL IMMEDIATE GENERATOR TESTS PASSED");
    else
        $display("%0d IMMEDIATE GENERATOR TESTS FAILED", errors);

    $finish;
end

endmodule