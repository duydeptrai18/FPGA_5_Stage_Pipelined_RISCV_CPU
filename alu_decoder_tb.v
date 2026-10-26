/*
- 1. Test and output alu operation based on opcode, funct3, and funct7 if needed.
- 2. Test instructions with invalid opcode, or invalid funct3, or invalid funct7.

*/

`timescale 1ns/1ps
module alu_decoder_tb;
	reg [31:0] instruction;
	wire [3:0] alu_operation;
	wire alu_valid;
	integer errors;
alu_decoder alu_decoder_dut(
	.instruction(instruction),
	.alu_operation(alu_operation),
	.alu_valid(alu_valid)
);

// Instruction groups
localparam R_TYPE = 7'b0110011;
localparam I_TYPE = 7'b0010011;
localparam LOAD   = 7'b0000011;
localparam STORE  = 7'b0100011;
localparam BRANCH = 7'b1100011;
localparam JAL    = 7'b1101111;
localparam JALR   = 7'b1100111;
localparam LUI    = 7'b0110111;
localparam AUIPC  = 7'b0010111;

// ALU operations
localparam ALU_ADD  = 4'b0000;
localparam ALU_SUB  = 4'b0001;
localparam ALU_AND  = 4'b0010;
localparam ALU_OR   = 4'b0011;
localparam ALU_XOR  = 4'b0100;
localparam ALU_SLL  = 4'b0101;
localparam ALU_SRL  = 4'b0110;
localparam ALU_SRA  = 4'b0111;
localparam ALU_SLT  = 4'b1000;
localparam ALU_SLTU = 4'b1001;


// Branch funct3 values
localparam F3_BEQ  = 3'b000;
localparam F3_BNE  = 3'b001;
localparam F3_BLT  = 3'b100;
localparam F3_BGE  = 3'b101;
localparam F3_BLTU = 3'b110;
localparam F3_BGEU = 3'b111;

// Arithmetic funct3 values
localparam F3_ADD_SUB = 3'b000;
localparam F3_SLL     = 3'b001;
localparam F3_SLT     = 3'b010;
localparam F3_SLTU    = 3'b011;
localparam F3_XOR     = 3'b100;
localparam F3_SRL_SRA = 3'b101;
localparam F3_OR      = 3'b110;
localparam F3_AND     = 3'b111;

// R-type funct7 values; also used to check I-type shift encodings
localparam F7_NORMAL  = 7'b0000000;
localparam F7_SUB_SRA = 7'b0100000;
task alu_decoder_test;
    input [31:0] test_instruction;
    input [3:0] expected_alu_operation;
    input expected_alu_valid;

    begin
        instruction = test_instruction;
        #1;

        if ((alu_operation !== expected_alu_operation) ||
            (alu_valid !== expected_alu_valid)) begin
            errors = errors + 1;
            $display(
                "FAIL instruction=%h opcode=%b funct3=%b bits31_25=%b | op=%b valid=%b | expected op=%b expected valid=%b",
                instruction, instruction[6:0], instruction[14:12],
                instruction[31:25], alu_operation, alu_valid,
                expected_alu_operation, expected_alu_valid
            );
        end
        else begin
            $display(
                "PASS instruction=%h opcode=%b funct3=%b bits31_25=%b | op=%b valid=%b",
                instruction, instruction[6:0], instruction[14:12],
                instruction[31:25], alu_operation, alu_valid
            );
        end
    end
endtask

initial begin	
	errors = 0;

	// 1. Test and output alu operation, alu valid based on opcode, funct3, and funct7 if needed.
	// R-type format: {funct7, rs2, rs1, funct3, rd, opcode}
	alu_decoder_test( {F7_NORMAL,5'd2,5'd1,F3_ADD_SUB,5'd3, R_TYPE}, ALU_ADD, 1'b1 );
	alu_decoder_test( {F7_SUB_SRA,5'd2,5'd1,F3_ADD_SUB,5'd3, R_TYPE}, ALU_SUB, 1'b1 );
	alu_decoder_test( {F7_NORMAL,5'd2,5'd1,F3_AND,5'd3, R_TYPE}, ALU_AND, 1'b1 );
	alu_decoder_test( {F7_NORMAL,5'd2,5'd1,F3_OR,5'd3, R_TYPE}, ALU_OR, 1'b1 );	
	alu_decoder_test( {F7_NORMAL,5'd2,5'd1,F3_XOR,5'd3, R_TYPE}, ALU_XOR, 1'b1 );	
	alu_decoder_test( {F7_NORMAL,5'd2,5'd1,F3_SLL,5'd3, R_TYPE}, ALU_SLL, 1'b1 );	
	alu_decoder_test( {F7_NORMAL,5'd2,5'd1,F3_SRL_SRA,5'd3, R_TYPE}, ALU_SRL, 1'b1 );
	alu_decoder_test( {F7_SUB_SRA,5'd2,5'd1,F3_SRL_SRA,5'd3, R_TYPE}, ALU_SRA, 1'b1 );	
	alu_decoder_test( {F7_NORMAL,5'd2,5'd1,F3_SLT,5'd3, R_TYPE}, ALU_SLT, 1'b1 );	
	alu_decoder_test( {F7_NORMAL,5'd2,5'd1,F3_SLTU,5'd3, R_TYPE}, ALU_SLTU, 1'b1 );	
	
   // I-type arithmetic format: {12-bit immediate, rs1, funct3, rd, opcode}
	alu_decoder_test( {12'hFFF,5'd2,F3_ADD_SUB,5'd3, I_TYPE}, ALU_ADD, 1'b1 );		
	alu_decoder_test( {12'h404,5'd2,F3_SRL_SRA,5'd3, I_TYPE}, ALU_SRA, 1'b1 );		
	alu_decoder_test( {12'h004,5'd2,F3_SRL_SRA,5'd3, I_TYPE}, ALU_SRL, 1'b1 );	
	alu_decoder_test( {12'h004,5'd2,F3_SLL,5'd3, I_TYPE}, ALU_SLL, 1'b1 );
	alu_decoder_test( {12'hFFF,5'd1,F3_AND,5'd3, I_TYPE}, ALU_AND, 1'b1 );
	alu_decoder_test( {12'hFFF,5'd1,F3_OR,5'd3, I_TYPE}, ALU_OR, 1'b1 );	
	alu_decoder_test( {12'hFFF,5'd1,F3_XOR,5'd3, I_TYPE}, ALU_XOR, 1'b1 );
	alu_decoder_test( {12'hFFF,5'd1,F3_SLT,5'd3, I_TYPE}, ALU_SLT, 1'b1 );	
	alu_decoder_test( {12'hFFF,5'd1,F3_SLTU,5'd3, I_TYPE}, ALU_SLTU, 1'b1 );

	//Branches:{7-bit immediate part 1, rs2, rs1, funct3, 5-bit immediate part 2, opcode} 
	alu_decoder_test( {7'd0,5'd2,5'd1,F3_BEQ ,5'd1, BRANCH}, ALU_SUB, 1'b1 );
	alu_decoder_test( {7'd0,5'd2,5'd1,F3_BNE ,5'd1, BRANCH}, ALU_SUB, 1'b1 );	
	alu_decoder_test( {7'd0,5'd2,5'd1,F3_BLT ,5'd1, BRANCH}, ALU_SLT, 1'b1 );
	alu_decoder_test( {7'd0,5'd2,5'd1,F3_BGE ,5'd1, BRANCH}, ALU_SLT, 1'b1 );	
	alu_decoder_test( {7'd0,5'd2,5'd1,F3_BLTU ,5'd1, BRANCH}, ALU_SLTU, 1'b1 );
	alu_decoder_test( {7'd0,5'd2,5'd1,F3_BGEU ,5'd1, BRANCH}, ALU_SLTU, 1'b1 );	
	
	//JAL:{20-bit immediate part, rd, opcode}
	alu_decoder_test( {20'd4,5'd3, JAL}, ALU_ADD, 1'b1 );	
	
	//JALR:{12-bit immediate, rs1, funct3, rd, opcode}
	alu_decoder_test( {12'd4,5'd1,3'b000,5'd3,JALR}, ALU_ADD, 1'b1 );
	
	//Load:{12-bit immediate, rs1, funct3, rd, opcode}
	alu_decoder_test( {12'h004,5'd1, 3'b010,5'd3, LOAD}, ALU_ADD, 1'b1 );
	
	//Store:{7-bit immediate part 1, rs2, rs1, funct3, 5-bit immediate part 2, opcode} 
	alu_decoder_test( {7'd0,5'd1,5'd2 ,3'b010,5'd4, STORE}, ALU_ADD, 1'b1 );	
	
	//LUI:{20-bit immediate part, rd, opcode}
	alu_decoder_test( {20'd2, 5'd3, LUI}, ALU_ADD, 1'b1 );
	
	//AUIPC:{20-bit immediate part, rd, opcode}
	alu_decoder_test( {20'd2, 5'd3, AUIPC}, ALU_ADD, 1'b1 );	
	
	//2. Test instructions with invalid opcode, or invalid funct3, or invalid funct7.
	//Invalid:
	alu_decoder_test( {20'd4,5'd3, 7'b1111111}, ALU_ADD, 1'b0 ); //invalid opcode	
	alu_decoder_test( {7'd0,5'd2,5'd1,3'b010,5'd1, BRANCH}, ALU_ADD, 1'b0 ); //valid opcode but invalid funct3
	alu_decoder_test( {7'b1111111,5'd2,5'd1,F3_ADD_SUB,5'd3, R_TYPE}, ALU_ADD, 1'b0 ); //valid opcode & funct3 but invalid funct7	
	
	
	if(errors == 0)
		$display("All alu_decoder tests passed");
	else
		$display("%0d alu_decoder tests failed",errors);
	$finish;
end
endmodule
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	