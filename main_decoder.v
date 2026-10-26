/*
- This module will output the control signals to other modules based on the opcode of each instruction.
-	output reg write_register: whether to write to a register
	output reg write_memory: whether to write to memory
	output reg [1:0] jump: whether to jump
	output reg branch: whether to consider branching
	output reg [2:0] immediate_type
	output reg alu_input_1: register value or pc
	output reg alu_input_2: register value or immediate
	output reg [1:0] writeback_source
	output reg main_valid_instruction
*/


module main_decoder(
	input [31:0] instruction,
	output reg write_register,
	output reg write_memory,
	output reg [1:0] jump,
	output reg branch,
	output reg [2:0] immediate_type,
	output reg alu_input_1,
	output reg alu_input_2,
	output reg [1:0] writeback_source,
	output reg main_valid_instruction
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
localparam ALU_IMMEDIATE = 1'b1;

always @(*) begin
	 write_register        = 1'b0;
    write_memory          = 1'b0;
    jump                  = JUMP_NONE;  // no jump
    branch                = BRANCH_NONE;   // no branch
    immediate_type        = IMM_I; // I-type; ignored unless needed
    alu_input_1           = ALU_RS1 ;   // rs1
    alu_input_2           = ALU_RS2 ;   // rs2
    writeback_source      = WB_ALU;  // ignored when write_register=0
    main_valid_instruction = 1'b0;  // unknown opcode
	 
	 case(instruction[6:0])// opcode
	 
	 R_TYPE: begin
		 write_register         = 1'b1;
		 write_memory           = 1'b0;
		 jump                   = JUMP_NONE;
		 branch                 = BRANCH_NONE;
		 immediate_type         = IMM_I; 
		 alu_input_1            = ALU_RS1;
		 alu_input_2            = ALU_RS2;   
		 writeback_source       = WB_ALU;
		 main_valid_instruction = 1'b1;
	 end
	 
	 I_TYPE: begin
		 write_register         = 1'b1;
		 write_memory           = 1'b0;
		 jump                   = JUMP_NONE;
		 branch                 = BRANCH_NONE;
		 immediate_type         = IMM_I; 
		 alu_input_1            = ALU_RS1;   
		 alu_input_2            = ALU_IMMEDIATE;   
		 writeback_source       = WB_ALU;
		 main_valid_instruction = 1'b1;
	 end		
	 
	 LOAD: begin
		 write_register         = 1'b1;
		 write_memory           = 1'b0;
		 jump                   = JUMP_NONE;
		 branch                 = BRANCH_NONE;
		 immediate_type         = IMM_I; 
		 alu_input_1            = ALU_RS1;   
		 alu_input_2            = ALU_IMMEDIATE;   
		 writeback_source       = WB_MEMORY;
		 main_valid_instruction = 1'b1;
	 end		 
	 
	 STORE: begin
		 write_register         = 1'b0;
		 write_memory           = 1'b1;
		 jump                   = JUMP_NONE;
		 branch                 = BRANCH_NONE;
		 immediate_type         = IMM_S; 
		 alu_input_1            = ALU_RS1;   
		 alu_input_2            = ALU_IMMEDIATE;   
		 writeback_source       = WB_ALU;
		 main_valid_instruction = 1'b1;
	 end	 
	 
	 BRANCH: begin
		 write_register         = 1'b0;
		 write_memory           = 1'b0;
		 jump                   = JUMP_NONE;
		 branch                 = BRANCH_ON;
		 immediate_type         = IMM_B; 
		 alu_input_1            = ALU_RS1;   
		 alu_input_2            = ALU_RS2;   
		 writeback_source       = WB_ALU;
		 main_valid_instruction = 1'b1;
	 end	
	 
	 JAL: begin
		 write_register         = 1'b1;
		 write_memory           = 1'b0;
		 jump                   = JUMP_JAL;
		 branch                 = BRANCH_NONE;
		 immediate_type         = IMM_J; 
		 alu_input_1            = ALU_RS1;   
		 alu_input_2            = ALU_RS2;   
		 writeback_source       = WB_PC4;
		 main_valid_instruction = 1'b1;
	 end		 
	 
	 JALR: begin
		 write_register         = 1'b1;
		 write_memory           = 1'b0;
		 jump                   = JUMP_JALR;
		 branch                 = BRANCH_NONE;
		 immediate_type         = IMM_I; 
		 alu_input_1            = ALU_RS1;   
		 alu_input_2            = ALU_RS2;   
		 writeback_source       = WB_PC4;
		 main_valid_instruction = 1'b1;
	 end		 
	 
	 
	 LUI: begin
		 write_register         = 1'b1;
		 write_memory           = 1'b0;
		 jump                   = JUMP_NONE;
		 branch                 = BRANCH_NONE;
		 immediate_type         = IMM_U; 
		 alu_input_1            = ALU_RS1;   
		 alu_input_2            = ALU_RS2;   
		 writeback_source       = WB_IMMEDIATE;
		 main_valid_instruction = 1'b1;
	 end		 
	 

	 AUIPC: begin
		 write_register         = 1'b1;
		 write_memory           = 1'b0;
		 jump                   = JUMP_NONE;
		 branch                 = BRANCH_NONE;
		 immediate_type         = IMM_U; 
		 alu_input_1            = ALU_PC;   
		 alu_input_2            = ALU_IMMEDIATE;   
		 writeback_source       = WB_ALU;
		 main_valid_instruction = 1'b1;
	 end		 
	 
	 endcase
end
endmodule
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 