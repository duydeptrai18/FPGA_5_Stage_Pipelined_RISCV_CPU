/*
- Default next pc is pc + 4;
- If branch or Jal: next_pc = pc + immediate
- If Jalr: next_pc = (register_data + immediate) & 32'hFFFFFFFE because the last bit must be 0.

*/

module next_program_counter(
	input [31:0] pc,
	input [31:0] branch_jump_pc,
	input stall,
	input branch,
	input [1:0] jump,
	input alu_zero,
	input alu_bit_0,
	input [31:0] immediate,
	input [2:0] funct3,
	input [31:0] register_data,
	
	
	output reg take_branch,
	output reg [31:0] next_pc
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

always @(*) begin
	 take_branch = 1'b0;
    if (stall)
      next_pc = pc;
    else begin
      next_pc = pc + 32'd4;
		
		if(branch) begin
			case(funct3)  
					 F3_BEQ: begin
						  if(alu_zero) begin
								next_pc = branch_jump_pc + immediate;
								take_branch = 1'b1;
						  end
					 end
					 
					 F3_BNE: begin
						  if(!alu_zero) begin
								next_pc = branch_jump_pc + immediate;	
								take_branch = 1'b1;	
					     end			
					 end
					 
					 F3_BLT, F3_BLTU: begin
						  if(alu_bit_0) begin
								next_pc = branch_jump_pc + immediate;
								take_branch = 1'b1;
						  end
					 end
					 
					 F3_BGE, F3_BGEU: begin
						  if(!alu_bit_0) begin
								next_pc = branch_jump_pc + immediate;	
								take_branch = 1'b1;
						  end
					 end		 

			 endcase	
		
		end
		
		else if(jump==JUMP_JAL) 
			next_pc = branch_jump_pc + immediate;	
			
		else if(jump==JUMP_JALR) 
			next_pc = (register_data + immediate) & 32'hFFFFFFFE;	
			
	end
end
endmodule