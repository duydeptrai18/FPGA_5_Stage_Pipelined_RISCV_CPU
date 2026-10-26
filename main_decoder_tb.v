/*
1. Test normal insutrctions based on their opcodes.
2. Test invalid opcode
*/

`timescale 1ns/1ps
module main_decoder_tb;

	reg [31:0] instruction;
	wire write_register;
	wire write_memory;
	wire [1:0] jump;
	wire branch;
	wire [2:0] immediate_type;
	wire alu_input_1;
	wire alu_input_2;
	wire [1:0] writeback_source;
	wire main_valid_instruction;
	integer errors; 

main_decoder main_decoder_dut(
    .instruction(instruction),
    .write_register(write_register),
    .write_memory(write_memory),
    .jump(jump),
    .branch(branch),
    .immediate_type(immediate_type),
    .alu_input_1(alu_input_1),
    .alu_input_2(alu_input_2),
    .writeback_source(writeback_source),
    .main_valid_instruction(main_valid_instruction)
);

//instruction groups
localparam R_TYPE = 7'b0110011;
localparam I_TYPE = 7'b0010011;
localparam LOAD   = 7'b0000011;
localparam STORE  = 7'b0100011;
localparam BRANCH = 7'b1100011;
localparam JAL    = 7'b1101111;
localparam JALR   = 7'b1100111;
localparam LUI    = 7'b0110111;
localparam AUIPC  = 7'b0010111;

//immediate_type
localparam IMM_I = 3'b000;
localparam IMM_S = 3'b001;
localparam IMM_B = 3'b010;
localparam IMM_U = 3'b011;
localparam IMM_J = 3'b100;

//writeback_source
localparam WB_ALU       = 2'b00; //also when writeback is not needed. 
localparam WB_MEMORY    = 2'b01;
localparam WB_IMMEDIATE = 2'b10;
localparam WB_PC4       = 2'b11;

	
//jump
localparam JUMP_NONE = 2'b00;
localparam JUMP_JAL = 2'b01;
localparam JUMP_JALR = 2'b10;

//branch
localparam BRANCH_NONE = 1'b0;
localparam BRANCH_ON = 1'b1;

//alu_input_1
localparam ALU_RS1 = 1'b0;
localparam ALU_PC  = 1'b1;

//alu_input_2
localparam ALU_RS2 = 1'b0;
localparam  ALU_IMMEDIATE = 1'b1;


task main_decoder_test;
    input [31:0] test_instruction;
    input expected_write_register;
    input expected_write_memory;
    input [1:0] expected_jump;
    input expected_branch;
    input [2:0] expected_immediate_type;
    input expected_alu_input_1;
    input expected_alu_input_2;
    input [1:0] expected_writeback_source;
    input expected_main_valid_instruction;

    begin
        instruction = test_instruction;
        #1;

        if ((write_register !== expected_write_register) ||
            (write_memory !== expected_write_memory) ||
            (jump !== expected_jump) ||
            (branch !== expected_branch) ||
            (immediate_type !== expected_immediate_type) ||
            (alu_input_1 !== expected_alu_input_1) ||
            (alu_input_2 !== expected_alu_input_2) ||
            (writeback_source !== expected_writeback_source) ||
            (main_valid_instruction !== expected_main_valid_instruction)) begin

            errors = errors + 1;
            $display("FAIL opcode=%b instruction=%h", instruction[6:0], instruction);
        end
        else begin
            $display("PASS opcode=%b instruction=%h", instruction[6:0], instruction);
        end
    end
endtask

initial begin
    errors = 0;
	 
	 //1. Test normal insutrctions based on their opcodes.
    // instruction, write_register, write_memory, jump, branch,
    // immediate_type, alu_input_1, alu_input_2, writeback_source, valid
    main_decoder_test({25'd0, R_TYPE}, 1'b1, 1'b0, JUMP_NONE, BRANCH_NONE, IMM_I,
                      ALU_RS1, ALU_RS2, WB_ALU, 1'b1);

    main_decoder_test({25'd0, I_TYPE}, 1'b1, 1'b0, JUMP_NONE, BRANCH_NONE, IMM_I,
                      ALU_RS1, ALU_IMMEDIATE, WB_ALU, 1'b1);

    main_decoder_test({25'd0, LOAD}, 1'b1, 1'b0, JUMP_NONE, BRANCH_NONE, IMM_I,
                      ALU_RS1, ALU_IMMEDIATE, WB_MEMORY, 1'b1);

    main_decoder_test({25'd0, STORE}, 1'b0, 1'b1, JUMP_NONE, BRANCH_NONE, IMM_S,
                      ALU_RS1, ALU_IMMEDIATE, WB_ALU, 1'b1);

    main_decoder_test({25'd0, BRANCH}, 1'b0, 1'b0, JUMP_NONE, BRANCH_ON, IMM_B,
                      ALU_RS1, ALU_RS2, WB_ALU, 1'b1);

    main_decoder_test({25'd0, JAL}, 1'b1, 1'b0, JUMP_JAL, BRANCH_NONE, IMM_J,
                      ALU_RS1, ALU_RS2, WB_PC4, 1'b1);

    main_decoder_test({25'd0, JALR}, 1'b1, 1'b0, JUMP_JALR, BRANCH_NONE, IMM_I,
                      ALU_RS1, ALU_RS2, WB_PC4, 1'b1);

    main_decoder_test({25'd0, LUI}, 1'b1, 1'b0, JUMP_NONE, BRANCH_NONE, IMM_U,
                      ALU_RS1, ALU_RS2, WB_IMMEDIATE, 1'b1);

    main_decoder_test({25'd0, AUIPC}, 1'b1, 1'b0, JUMP_NONE, BRANCH_NONE, IMM_U,
                      ALU_PC, ALU_IMMEDIATE, WB_ALU, 1'b1);

	 //2. Test invalid opcode
    // Unknown opcode: all outputs should stay at their defaults.
    main_decoder_test(32'h0000007F, 1'b0, 1'b0, JUMP_NONE, BRANCH_NONE, IMM_I,
                      ALU_RS1, ALU_RS2, WB_ALU, 1'b0);

    if (errors == 0)
        $display("ALL MAIN DECODER TESTS PASSED");
    else
        $display("%0d MAIN DECODER TESTS FAILED", errors);

    $finish;
end

endmodule
