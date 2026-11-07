module cpu_top(
	input clock,
	input reset_n,

	output debug_write_register_enable,
	output [4:0] debug_rd,
	output [31:0] debug_register_write_data,
	output debug_write_memory_enable,
	output [31:0] debug_memory_address,
	output [31:0] debug_memory_write_data,
	output [31:0] debug_pc
);


//declaration:-----------------------
//5 stages registers:

assign debug_write_register_enable = mem_wb_safe_write_register;
assign debug_rd                    = mem_wb_rd;
assign debug_register_write_data   = register_write_data;
assign debug_write_memory_enable   = ex_mem_safe_write_memory;
assign debug_memory_address        = ex_mem_alu_result;
assign debug_memory_write_data     = ex_mem_register_read_data_2;
assign debug_pc                    = pc;


//1.if/id:
reg [31:0] if_id_instruction;
reg [31:0] if_id_pc;

//2.id/ex:
reg [31:0] id_ex_alu_input_1;
reg [31:0] id_ex_alu_input_2;
reg [3:0]  id_ex_alu_operation;
reg        id_ex_safe_write_register;
reg        id_ex_safe_write_memory;
reg [1:0]  id_ex_safe_jump;
reg        id_ex_safe_branch;
reg [1:0]  id_ex_writeback_source;
reg [4:0]  id_ex_rd;
reg [31:0] id_ex_pc;
reg [31:0] id_ex_immediate;
reg [31:0] id_ex_register_read_data_2;
reg [6:0]  id_ex_opcode;
reg [2:0] id_ex_funct3;

//3. ex/mem:
reg [31:0] ex_mem_alu_result;
reg        ex_mem_alu_zero;
reg        ex_mem_safe_write_register;
reg        ex_mem_safe_write_memory;
reg [1:0]  ex_mem_writeback_source;
reg [4:0]  ex_mem_rd;
reg [31:0] ex_mem_pc;
reg [31:0] ex_mem_immediate;
reg [31:0] ex_mem_register_read_data_2;
reg [6:0]  ex_mem_opcode;

//4. mem/wb:
reg        mem_wb_safe_write_register;
reg [31:0] mem_wb_alu_result;
reg [31:0] mem_wb_data_memory_read_data;
reg [1:0]  mem_wb_writeback_source;
reg [4:0]  mem_wb_rd;
reg [31:0] mem_wb_pc;
reg [31:0] mem_wb_immediate;
reg [6:0]  mem_wb_opcode;

//program_counter
wire [31:0] next_pc;
wire [31:0] pc;
wire take_branch;

assign debug_pc = pc; 
//instruction_memory
wire [31:0] instruction;
wire [6:0] opcode = if_id_instruction[6:0];
wire [2:0] funct3 = if_id_instruction[14:12];
wire [6:0] funct7 = if_id_instruction[31:25];
wire [4:0] rd = if_id_instruction[11:7];

//main decoder
wire write_register;
wire write_memory;
wire [1:0] jump;
wire branch;
wire [2:0] immediate_type;
wire alu_input_1_control;
wire alu_input_2_control;
wire [1:0] writeback_source;
wire main_valid_instruction;

//alu decoder
wire [3:0] alu_operation;
wire alu_valid;

//immediate generator
wire [31:0] immediate;

//data memory
wire [31:0] data_memory_read_data;

//register
reg [31:0] register_write_data;
wire [31:0] register_read_data_1;
wire [31:0] register_read_data_2;
wire [4:0] rs1_address = if_id_instruction[19:15];
wire [4:0] rs2_address = if_id_instruction[24:20];
wire [4:0] rd_address  = if_id_instruction[11:7];

//alu
wire [31:0] alu_result;
wire alu_zero;

//control flags
wire instruction_valid = main_valid_instruction && alu_valid;
wire safe_write_register = write_register && instruction_valid && reset_n;
wire safe_write_memory = write_memory && instruction_valid && reset_n ;
wire [1:0] safe_jump = instruction_valid ? jump: 2'b00;
wire safe_branch = branch && instruction_valid;

//write back MUX
localparam WB_ALU       = 2'b00; //also when writeback is not needed. 
localparam WB_MEMORY    = 2'b01;
localparam WB_IMMEDIATE = 2'b10;
localparam WB_PC4       = 2'b11;

//opcode types
localparam R_TYPE = 7'b0110011;
localparam I_TYPE = 7'b0010011;
localparam LOAD   = 7'b0000011;
localparam STORE  = 7'b0100011;
localparam BRANCH = 7'b1100011;
localparam JAL    = 7'b1101111;
localparam JALR   = 7'b1100111;
localparam LUI    = 7'b0110111;
localparam AUIPC  = 7'b0010111;


//forwarding

//stall 
reg stall;

wire flush = id_ex_safe_jump || take_branch; 



//MAIN MODULES:-------------------------
program_counter program_counter_unit(//
   .clock(clock),
   .reset_n(reset_n),
   .next_pc(next_pc),
   .pc(pc)
);

next_program_counter next_program_counter_unit(//
    .pc(pc),
	 .branch_jump_pc(id_ex_pc),
	 .stall(stall),
    .branch(id_ex_safe_branch),
    .jump(id_ex_safe_jump),
    .alu_zero(alu_zero),
    .alu_bit_0(alu_result[0]),
    .immediate(id_ex_immediate),
    .funct3(id_ex_funct3),
    .register_data(id_ex_alu_input_1),
	 .take_branch(take_branch),
    .next_pc(next_pc)
);

instruction_memory instruction_memory_unit(//
	.address(pc),
	.data(instruction)
);

always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
		  if_id_instruction <= 32'd0;
        if_id_pc <= 32'd0;
	 end
	 
	 else if(flush) begin
		  if_id_instruction <= 32'd0;
        if_id_pc <= 32'd0;
	 end
	 
    else if(!stall) begin
		  if_id_instruction <= instruction;
        if_id_pc <= pc;
	 end
end



main_decoder main_decoder_unit(//
    .instruction(if_id_instruction),
    .write_register(write_register),
    .write_memory(write_memory),
    .jump(jump),
    .branch(branch),
    .immediate_type(immediate_type),
    .alu_input_1(alu_input_1_control),
    .alu_input_2(alu_input_2_control),
    .writeback_source(writeback_source),
    .main_valid_instruction(main_valid_instruction)
);

alu_decoder alu_decoder_unit(//
	.instruction(if_id_instruction),
	.alu_operation(alu_operation),
	.alu_valid(alu_valid)
);

immediate_generator immediate_generator_unit(//
    .instruction    (if_id_instruction),
    .immediate_type (immediate_type),
    .immediate      (immediate)
);


localparam ALU_ADD  = 4'b0000;
always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
		  id_ex_alu_operation <= ALU_ADD;
		  id_ex_safe_write_register <= 1'b0;
		  id_ex_safe_write_memory <= 1'b0;
		  id_ex_safe_jump <= 2'b00;
		  id_ex_safe_branch <= 1'b0;
		  id_ex_writeback_source <= WB_ALU;
		  id_ex_rd <= 5'd0;
        id_ex_pc <= 32'd0;		
		  id_ex_immediate <= 32'd0;  
		  id_ex_opcode <= 7'd0;
		  id_ex_funct3 <=3'd0;
	 end	 
	 
	 else if(stall) begin //insert a bubble
		  id_ex_alu_operation <= ALU_ADD;
		  id_ex_safe_write_register <= 1'b0;
		  id_ex_safe_write_memory <= 1'b0;
		  id_ex_safe_jump <= 2'b00;
		  id_ex_safe_branch <= 1'b0;
		  id_ex_writeback_source <= WB_ALU;
		  id_ex_rd <= 5'd0;
        id_ex_pc <= 32'd0;		
		  id_ex_immediate <= 32'd0;  
		  id_ex_opcode <= 7'd0; 
		  id_ex_funct3 <=3'd0;
	 end
	 
	 else if(flush) begin //insert a bubble
		  id_ex_alu_operation <= ALU_ADD;
		  id_ex_safe_write_register <= 1'b0;
		  id_ex_safe_write_memory <= 1'b0;
		  id_ex_safe_jump <= 2'b00;
		  id_ex_safe_branch <= 1'b0;
		  id_ex_writeback_source <= WB_ALU;
		  id_ex_rd <= 5'd0;
        id_ex_pc <= 32'd0;		
		  id_ex_immediate <= 32'd0;  
		  id_ex_opcode <= 7'd0;
		  id_ex_funct3 <=3'd0;	 
	 	 
	 
	 end
	 
    else if(!stall) begin
		  id_ex_alu_operation <= alu_operation;
		  id_ex_safe_write_register <= safe_write_register;
		  id_ex_safe_write_memory <= safe_write_memory;
		  id_ex_safe_jump <= safe_jump;
		  id_ex_safe_branch <= safe_branch;	
		  id_ex_writeback_source <= writeback_source;
		  id_ex_rd <= rd;	
        id_ex_pc <= if_id_pc;	
		  id_ex_immediate <= immediate;	
		  id_ex_opcode <= opcode;
		  id_ex_funct3 <=funct3;
	 end  
end

//stall
always @(*) begin
	stall = 1'b0;
	
	if(id_ex_opcode == LOAD && id_ex_rd != 5'd0 ) begin
		case (opcode)	
			I_TYPE, LOAD, JALR: begin //these are the ones that may need forwarding in alu input 1
				if(id_ex_rd == rs1_address) stall = 1'b1;
			
			end
						  
			R_TYPE, STORE, BRANCH: begin //these are the ones that may need forwarding in both alu input 1 and/or 2
				if(id_ex_rd == rs1_address) stall = 1'b1;
				else if(id_ex_rd == rs2_address) stall = 1'b1; 
			
			end
	
		endcase
	end

end


always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
	 	  id_ex_register_read_data_2 <= 32'd0;

	 end
	 else if(stall) 	  
		  id_ex_register_read_data_2 <= 32'd0;
		  
	 else if(flush) 	  
		  id_ex_register_read_data_2 <= 32'd0;	 
	 
	 else begin
		  if (opcode == STORE && rs2_address != 5'd0) begin
						id_ex_register_read_data_2 <= register_read_data_2;
						case (mem_wb_opcode)

						R_TYPE, I_TYPE, AUIPC, LUI, LOAD, JAL, JALR: begin //R_TYPE, I_TYPE, AUIPC, LUI, load, jal, jalr
							if(mem_wb_rd == rs2_address) id_ex_register_read_data_2 <= register_write_data;
						
						end

						
						default: begin // store, branch
							
						end					
					
					endcase
					
					case (ex_mem_opcode)
					
						R_TYPE, I_TYPE, AUIPC: begin 
							if(ex_mem_rd == rs2_address) id_ex_register_read_data_2 <= ex_mem_alu_result;
							
						end
						
						LUI: begin
							if(ex_mem_rd == rs2_address) id_ex_register_read_data_2 <= ex_mem_immediate;
													
						
						end
						
						LOAD: begin
							if(ex_mem_rd == rs2_address) id_ex_register_read_data_2 <= data_memory_read_data;
						end
						
						default: begin // JAL, JALR, store, branch
						end					
					
					
					endcase
			
					
					case (id_ex_opcode) //opcode's instruction in EX stage
						R_TYPE, I_TYPE, AUIPC: begin
							if(id_ex_rd == rs2_address) id_ex_register_read_data_2 <= alu_result;
						
						end
						
						LUI: begin
							if(id_ex_rd == rs2_address) id_ex_register_read_data_2 <= id_ex_immediate;
						
						end
					
						
						default: begin //jal, jalr, load, store, branch
						end
			  
					endcase
		  
		  end
		  
		  else id_ex_register_read_data_2 <= 32'd0;
	 
	 
	 end
	 	
	
end

//alu_input_1&2 MUX
//alu_input_control_1
localparam ALU_RS1 = 1'b0;
localparam ALU_PC  = 1'b1;
always @(posedge clock or negedge reset_n) begin
    if (!reset_n)
        id_ex_alu_input_1 <= 32'd0;
	 else if(stall) 	  
		  id_ex_alu_input_1 <= 32'd0;
	 else if(flush) 	  
		  id_ex_alu_input_1 <= 32'd0;	
    else if(alu_input_1_control == ALU_PC)
        id_ex_alu_input_1 <= if_id_pc;		  
	 else if( rs1_address!= 5'd0 ) begin
		  case (opcode)//opcode's instruction in ID stage
		  
			  R_TYPE, I_TYPE, LOAD, STORE, BRANCH, JALR: begin //these are the ones that may need forwarding
					id_ex_alu_input_1 <= register_read_data_1;
					case (mem_wb_opcode)

						R_TYPE, I_TYPE, AUIPC, LUI, LOAD, JAL, JALR: begin //R_TYPE, I_TYPE, AUIPC, LUI, load, jal, jalr
							if(mem_wb_rd == rs1_address) id_ex_alu_input_1 <= register_write_data;
							//else id_ex_alu_input_1 <= register_read_data_1;
						end

						
						default: begin // store, branch
							//id_ex_alu_input_1 <= register_read_data_1;
						end					
					
					endcase
					
					case (ex_mem_opcode)
					
						R_TYPE, I_TYPE, AUIPC: begin 
							if(ex_mem_rd == rs1_address) id_ex_alu_input_1 <= ex_mem_alu_result;
							//else id_ex_alu_input_1 <= register_read_data_1;
						end
						
						LUI: begin
							if(ex_mem_rd == rs1_address) id_ex_alu_input_1 <= ex_mem_immediate;
							//else id_ex_alu_input_1 <= register_read_data_1;						
						
						end
						
						LOAD: begin
							if(ex_mem_rd == rs1_address) id_ex_alu_input_1 <= data_memory_read_data;
							//else id_ex_alu_input_1 <= register_read_data_1;
						end
						
						default: begin // JAL, JALR, store, branch
							//id_ex_alu_input_1 <= register_read_data_1;
						end					
					
					
					endcase
			
					
					case (id_ex_opcode) //opcode's instruction in EX stage
						R_TYPE, I_TYPE, AUIPC: begin
							if(id_ex_rd == rs1_address) id_ex_alu_input_1 <= alu_result;
							//else id_ex_alu_input_1 <= register_read_data_1;
						
						end
						
						LUI: begin
							if(id_ex_rd == rs1_address) id_ex_alu_input_1 <= id_ex_immediate;
							//else id_ex_alu_input_1 <= register_read_data_1;
						
						end
					
						
						default: begin //jal, jalr, load, store, branch
							//id_ex_alu_input_1 <= register_read_data_1;
						end
			  
					endcase
			  end

			  default: begin //jal, lui, auipc don't need forwarding
					id_ex_alu_input_1 <= 32'd0;	  
			  end
			  
		  endcase
	 end
	 
	 else id_ex_alu_input_1 <= 32'd0; //when rs1_address == 0.
end


//alu_input_control_2
localparam ALU_RS2 = 1'b0;
localparam ALU_IMMEDIATE = 1'b1;
always @(posedge clock or negedge reset_n) begin
    if (!reset_n)
        id_ex_alu_input_2 <= 32'd0;
	 else if(stall) 	  
		  id_ex_alu_input_2 <= 32'd0;
	 else if(flush) 	  
		  id_ex_alu_input_2 <= 32'd0;
	 else if(alu_input_2_control == ALU_IMMEDIATE)
        id_ex_alu_input_2 <= immediate;
	 else if(rs2_address != 5'd0) begin
		  case (opcode)//opcode's instruction in ID stage
		  
			  R_TYPE, BRANCH: begin //these are the ones that may need forwarding
					id_ex_alu_input_2 <= register_read_data_2;
					case (mem_wb_opcode)

						R_TYPE, I_TYPE, AUIPC, LUI, LOAD, JAL, JALR: begin //R_TYPE, I_TYPE, AUIPC, LUI, load, jal, jalr
							if(mem_wb_rd == rs2_address) id_ex_alu_input_2 <= register_write_data;
						
						end

						
						default: begin // store, branch
							
						end					
					
					endcase
					
					case (ex_mem_opcode)
					
						R_TYPE, I_TYPE, AUIPC: begin 
							if(ex_mem_rd == rs2_address) id_ex_alu_input_2 <= ex_mem_alu_result;
							
						end
						
						LUI: begin
							if(ex_mem_rd == rs2_address) id_ex_alu_input_2 <= ex_mem_immediate;
													
						
						end
						
						LOAD: begin
							if(ex_mem_rd == rs2_address) id_ex_alu_input_2 <= data_memory_read_data;
						end
						
						default: begin // JAL, JALR, store, branch
						end					
					
					
					endcase
			
					
					case (id_ex_opcode) //opcode's instruction in EX stage
						R_TYPE, I_TYPE, AUIPC: begin
							if(id_ex_rd == rs2_address) id_ex_alu_input_2 <= alu_result;
						
						end
						
						LUI: begin
							if(id_ex_rd == rs2_address) id_ex_alu_input_2 <= id_ex_immediate;
						
						end
					
						
						default: begin //jal, jalr, load, store, branch
						end
			  
					endcase
			  end

			  default: begin //STORE, I_TYPE,LOAD,JALR,jal, lui, auipc don't need forwarding
					id_ex_alu_input_2 <= 32'd0;	  
			  end
			  
		  endcase
	 end		 
	 else id_ex_alu_input_2 <= 32'd0; //when rs2_address == 0.
end



//EX stage---------------------------------------------
rv32_alu rv32_alu_unit(//
	.a(id_ex_alu_input_1),
	.b(id_ex_alu_input_2),
	.alu_control(id_ex_alu_operation),
	.result (alu_result),
	.zero (alu_zero)
);


always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
		  ex_mem_alu_result <= 32'd0;
		  ex_mem_alu_zero <= 1'b0;
		  ex_mem_safe_write_register <= 1'b0;
		  ex_mem_safe_write_memory <= 1'b0;	
		  ex_mem_writeback_source <= WB_ALU;
		  ex_mem_rd <= 5'd0;
        ex_mem_pc <= 32'd0;	
		  ex_mem_immediate <= 32'd0;	
		  ex_mem_register_read_data_2 <= 32'd0;
		  ex_mem_opcode <= 7'd0;
	 end	  
    else begin
		  ex_mem_alu_result <= alu_result;
		  ex_mem_alu_zero <= alu_zero;	
		  ex_mem_safe_write_register <= id_ex_safe_write_register;
		  ex_mem_safe_write_memory <= id_ex_safe_write_memory;	
		  ex_mem_writeback_source <= id_ex_writeback_source;
		  ex_mem_rd <= id_ex_rd;
        ex_mem_pc <= id_ex_pc;	
		  ex_mem_immediate <= id_ex_immediate;	
		  ex_mem_register_read_data_2 <= id_ex_register_read_data_2;
		  ex_mem_opcode <= id_ex_opcode;
	 end	  
end


//MEM stage----------------------------------------------
data_memory data_memory_unit(//
    .clock(clock),
    .address(ex_mem_alu_result),
    .write_enable(ex_mem_safe_write_memory),
    .write_data(ex_mem_register_read_data_2),
    .read_data(data_memory_read_data)
);

always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
		  mem_wb_safe_write_register <= 1'b0;
		  mem_wb_alu_result <= 32'd0;
		  mem_wb_data_memory_read_data <= 32'd0;		  
		  mem_wb_writeback_source <= WB_ALU;
		  mem_wb_rd <= 5'd0;
        mem_wb_pc <= 32'd0;	
		  mem_wb_immediate <= 32'd0;	
		  mem_wb_opcode <= 7'd0;
	 end	 
    else begin
		  mem_wb_safe_write_register <= ex_mem_safe_write_register;
		  mem_wb_alu_result <= ex_mem_alu_result;
		  mem_wb_data_memory_read_data <= data_memory_read_data;		  	
		  mem_wb_writeback_source <= ex_mem_writeback_source;
		  mem_wb_rd <= ex_mem_rd;
        mem_wb_pc <= ex_mem_pc;	
		  mem_wb_immediate <= ex_mem_immediate;
		  mem_wb_opcode <= ex_mem_opcode;  
	 end
	
end


//WB stage-----------------------------------------------
registers_file registers_unit(//
	.clock (clock),
	.write_enable (mem_wb_safe_write_register),
	.read_address_1 (rs1_address),
	.read_address_2 (rs2_address),
	.write_address (mem_wb_rd),
	.write_data (register_write_data),
	.read_data_1(register_read_data_1),
	.read_data_2(register_read_data_2)
	
);


always @(*) begin 
   register_write_data = 32'hXXXXXXXX;
	case(mem_wb_writeback_source)
	
	WB_ALU: register_write_data = mem_wb_alu_result;
	WB_MEMORY: register_write_data = mem_wb_data_memory_read_data;
	WB_IMMEDIATE: register_write_data = mem_wb_immediate;
	WB_PC4: register_write_data = mem_wb_pc + 32'd4;
	
	endcase	

end

endmodule