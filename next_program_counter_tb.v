/*
1. Test normal operations of branch, jal and jalr
2. Test no branch or jump or invalid funct3 

*/

module next_program_counter_tb;
	reg [31:0] pc;
	reg branch;
	reg [1:0] jump;
	reg alu_zero;
	reg alu_bit_0;
	reg [31:0] immediate;
	reg [2:0] funct3;
	reg [31:0] register_data;
	
	wire [31:0] next_pc;
	integer errors;


next_program_counter next_program_counter_dut(
    .pc(pc),
    .branch(branch),
    .jump(jump),
    .alu_zero(alu_zero),
    .alu_bit_0(alu_bit_0),
    .immediate(immediate),
    .funct3(funct3),
    .register_data(register_data),
    .next_pc(next_pc)
);

// Branch funct3 values
localparam F3_BEQ  = 3'b000;
localparam F3_BNE  = 3'b001;
localparam F3_BLT  = 3'b100;
localparam F3_BGE  = 3'b101;
localparam F3_BLTU = 3'b110;
localparam F3_BGEU = 3'b111;

//jump
localparam JUMP_NONE = 2'b00;
localparam JUMP_JAL = 2'b01;
localparam JUMP_JALR = 2'b10;

task next_program_counter_test;
	input [31:0] test_pc;
	input test_branch;
	input [1:0] test_jump;
	input test_alu_zero;
	input test_alu_bit_0;
	input [31:0] test_immediate;
	input [2:0] test_funct3;
	input [31:0] test_register_data;
	input [31:0] expected_next_pc;
	
	begin
		pc            = test_pc;
		branch        = test_branch;
		jump          = test_jump;
		alu_zero      = test_alu_zero;
		alu_bit_0     = test_alu_bit_0;
		immediate     = test_immediate;
		funct3        = test_funct3;
		register_data = test_register_data;
		#1;
	if(next_pc !== expected_next_pc) begin
		errors = errors + 1;
        $display(
            "FAIL pc=%h branch=%b jump=%b funct3=%b immediate=%h | next_pc=%h expected=%h",
            pc, branch, jump, funct3, immediate, next_pc, expected_next_pc);
	end
	else
        $display(
            "PASS pc=%h branch=%b jump=%b funct3=%b | next_pc=%h",
            pc, branch, jump, funct3, next_pc);
	end
endtask


initial begin
		errors = 0;
		pc            = 32'd0;
		branch        = 1'b0;
		jump          = JUMP_NONE;
		alu_zero      = 1'b0;
		alu_bit_0     = 1'b0;
		immediate     = 1'b0;
		funct3        = 3'b000;
		register_data = 32'd0;
		
		//1. Test normal operations of branch, jal and jalr
		//{pc,branch,jump,alu_zero,alu_bit_0,immediate,funct3,register_data,expected_register_data)
		next_program_counter_test(32'd0,1'b1,JUMP_NONE,1'b1,1'b0,32'd12,F3_BEQ,32'd0,32'd12);
		next_program_counter_test(32'd20, 1'b1, JUMP_NONE, 1'b0, 1'b0, 32'd12, F3_BEQ, 32'd0, 32'd24); // BEQ is false: continue to PC + 4.
		next_program_counter_test(32'd0,1'b1,JUMP_NONE,1'b0,1'b0,32'd12,F3_BNE,32'd0,32'd12);
		next_program_counter_test(32'd0,1'b1,JUMP_NONE,1'b0,1'b1,32'd12,F3_BLT,32'd0,32'd12);
		next_program_counter_test(32'd0,1'b1,JUMP_NONE,1'b0,1'b0,32'd12,F3_BGE,32'd0,32'd12);
		next_program_counter_test(32'd0,1'b1,JUMP_NONE,1'b0,1'b1,32'd12,F3_BLTU,32'd0,32'd12);
		next_program_counter_test(32'd0,1'b1,JUMP_NONE,1'b0,1'b0,32'd12,F3_BGEU,32'd0,32'd12);

		next_program_counter_test(32'd0,1'b0,JUMP_JAL,1'b0,1'b0,32'd12,3'b000,32'd0,32'd12);//jal
		
		next_program_counter_test(32'd0,1'b0,JUMP_JALR,1'b0,1'b0,32'd12,3'b000,32'd4,32'd16);//jalr
		next_program_counter_test(32'd0,1'b0,JUMP_JALR,1'b0,1'b0,32'd12,3'b000,32'd3,32'd14);//jalr but next_pc = 32'd15, -> 32'd14		
		
		
		//2. Test no branch or jump or invalid funct3 
		next_program_counter_test(32'd0,1'b0,JUMP_NONE,1'b1,1'b0,32'd12,F3_BEQ,32'd0,32'd4);// no branch or jump
		next_program_counter_test(32'd0,1'b1,JUMP_NONE,1'b1,1'b0,32'd12,3'b010,32'd0,32'd4);//branch but invalid funct3
		
	if(errors == 0)
		$display("All next_program_counter_tb tests passed");
	else
		$display("%0d next_program_counter_tb tests failed",errors);
	$finish;
end
endmodule		
		
		
		